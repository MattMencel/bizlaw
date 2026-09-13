# frozen_string_literal: true

module Portraits
  # Seed, expression and render size in; one SVG element out.
  #
  # **The render size is an argument and not a CSS concern.** A halftone screen
  # is fixed in ink on the page: a portrait printed small gets *fewer* dots
  # across it, not smaller ones. SVG patterns are the opposite — `userSpaceOnUse`
  # resolves against the viewBox — so one shared screen shrinks with the
  # portrait, and at the 78px the Consult memo serves the cells fall under two
  # pixels and the face collapses into a flat grey wash, losing exactly the
  # register it was drawn for. The pitch is therefore divided back out by the
  # render scale, one screen per size served.
  #
  # That is also why an unserved size is refused rather than rendered: every size
  # the game uses is a size the part set has been looked at in, and a size nobody
  # has looked at is a face nobody has seen.
  class Compose
    # The sizes the game serves, in CSS pixels. The Consult memo's front matter
    # is the 78; the larger two are what the same face is judged at.
    SIZES = [78, 118, 168].freeze

    # The dot pitch, in CSS pixels of finished page, and the dot radii for the
    # three screens between the two inks. Both are page measurements: everything
    # else about a screen follows from them and the render scale.
    PITCH = 5
    SCREENS = {"t1" => 0.85, "t2" => 1.55, "t3" => 2.15}.freeze

    # The screen is a `<pattern>` rather than a filter so that it survives print
    # and forced colours, and the dots are filled with the ink rather than a
    # colour so the portrait follows the page it sits on.
    INK = "var(--portrait-ink, currentColor)"
    PAPER = "var(--portrait-paper, #fff)"

    def self.call(...) = new(...).call

    def initialize(seed:, expression:, size:, part_set: PartSet.default)
      @seed = seed
      @expression = expression
      @size = size
      @part_set = part_set
      validate!
    end

    def call
      <<~SVG
        <svg class="portrait #{scope}" width="#{size}" height="#{size}" viewBox="#{part_set.view_box}"
             xmlns="http://www.w3.org/2000/svg" aria-hidden="true" focusable="false">
        <defs>
        #{screens}
        </defs>
        <style>#{tones}</style>
        #{parts}
        </svg>
      SVG
    end

    private

    attr_reader :seed, :expression, :size, :part_set

    def validate!
      unless SIZES.include?(size)
        raise Unrenderable,
          "a portrait is served at #{SIZES.join(", ")} pixels and not at #{size.inspect}; " \
          "a screen has to be redrawn for a size, so a size nobody has looked at is refused"
      end

      return if EXPRESSIONS.include?(expression)

      raise Unrenderable,
        "#{expression.inspect} is not one of the #{EXPRESSIONS.join(", ")} a Client is drawn in"
    end

    def identity = @identity ||= Identity.for(seed, part_set: part_set)

    # The layering, back to front, as the set declares it.
    def parts
      part_set.order.map { |group| part_set.draw(group, name_for(group)) }.join
    end

    def name_for(group)
      return identity.part(group) if part_set.identity_group?(group)
      return expression if part_set.expression_group?(group)

      part_set.held_part(group)
    end

    # User units per CSS pixel. Every measurement below is a page measurement
    # multiplied by this, which is the whole of what makes the screen a property
    # of the page rather than of the artwork.
    def scale = part_set.width / size

    def screens
      SCREENS.map do |tone, radius|
        cell = round(PITCH * scale)
        <<~PATTERN.strip
          <pattern id="#{tone}-#{scope}" width="#{cell}" height="#{cell}"
                   patternUnits="userSpaceOnUse" patternTransform="rotate(30)">
            <circle cx="#{round(cell / 2)}" cy="#{round(cell / 2)}" r="#{round(radius * scale)}" fill="#{INK}"/>
          </pattern>
        PATTERN
      end.join("\n")
    end

    # The five tone levels, each resolving through a custom property with the
    # screen as its fallback. That is what lets an ancestor swap the whole
    # portrait to a flat wash, or move the ink, without a part being redrawn.
    #
    # An SVG `<style>` inside a document is not scoped to its own element, so
    # every rule is qualified by this render's own class. Two portraits on one
    # page would otherwise share a screen — and the whole point of the size
    # argument is that two sizes must not.
    def tones
      levels = {"t0" => PAPER, "t4" => INK}
      SCREENS.each_key { |tone| levels[tone] = "var(--portrait-#{tone}, url(##{tone}-#{scope}))" }
      levels.sort.map { |tone, fill| ".#{scope} .#{tone}{fill:#{fill}}" }.join
    end

    # Deterministic, so a redeploy does not rewrite every id, and keyed to the
    # three inputs that decide what is drawn, so two portraits differing in any
    # of them cannot collide — which is what the size argument needs, since one
    # page showing one face at two sizes must not share a screen.
    #
    # Two renders of the *same* seed, expression and size therefore carry the
    # same ids by construction, and putting both on one page is duplicate-id
    # invalid HTML. That is a caller's decision rather than something to salt
    # away: the same face twice on one page is the same drawing twice, and a
    # counter here would make the markup differ between two requests that drew
    # the identical thing. `WorkingDraft#portrait` is where the game declines
    # it, by printing the Consult memo's face once.
    def scope
      @scope ||= "portrait-#{Digest::SHA256.hexdigest([seed, expression, size].join("\0"))[0, 8]}"
    end

    def round(value) = value.round(3)
  end
end
