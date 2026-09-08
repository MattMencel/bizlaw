# frozen_string_literal: true

require "rails_helper"

# Seed, expression and render size in; one SVG element out. No Node at build
# time, none at import and none here.
RSpec.describe Portraits::Compose do
  let(:seed) { "greaves-plaintiff" }

  def portrait(expression: Portraits::FIRM, size: 78, seed: self.seed)
    described_class.call(seed: seed, expression: expression, size: size)
  end

  # The pattern cell, in user units, for one of the three screens.
  def cell(svg) = svg[/<pattern id="t1-[^"]+" width="([\d.]+)"/, 1].to_f

  it "composes an SVG at the size it was asked for, in the set's own frame" do
    expect(portrait(size: 118))
      .to include(%(width="118"), %(height="118"), %(viewBox="#{Portraits::PartSet.default.view_box}"))
  end

  it "draws the same bytes for the same seed, expression and size" do
    expect(portrait).to eq(portrait)
  end

  # Emphasis, never the sole carrier: the band is always on the page in words
  # too, so there is nothing truthful for alt text to add that the page does not
  # already say. Decorative, and the first axe-core pass is where that is
  # confirmed rather than assumed.
  it "is decorative, because the words it emphasises are always already there" do
    expect(portrait).to include(%(aria-hidden="true"), %(focusable="false"))
  end

  describe "what the engine picks and what the seed keeps" do
    it "moves the brows and the mouth between expressions" do
      firm = portrait(expression: Portraits::FIRM)
      ready = portrait(expression: Portraits::READY)

      expect(firm).not_to eq(ready)
      %w[brows mouth].each do |group|
        expect(firm).to include(Portraits::PartSet.default.draw(group, Portraits::FIRM))
        expect(ready).to include(Portraits::PartSet.default.draw(group, Portraits::READY))
      end
    end

    # The whole point of an identity group: a Client's face changes expression
    # and stays the same person. Hair, garment, glasses, facial hair and the
    # skull are drawn once by the seed and never move again.
    it "holds every identity group still across all three expressions" do
      set = Portraits::PartSet.default
      identity = Portraits::Identity.for(seed)

      Portraits::EXPRESSIONS.each do |expression|
        drawn = portrait(expression: expression)
        identity.parts.each do |group, name|
          expect(drawn).to include(set.draw(group, name))
        end
      end
    end

    it "gives everyone the same eyes and the same nose" do
      set = Portraits::PartSet.default

      expect(portrait(seed: "greaves-plaintiff")).to include(set.draw("eyes", set.held_part("eyes")))
      expect(portrait(seed: "hollis-defendant")).to include(set.draw("nose", set.held_part("nose")))
    end

    it "refuses an expression the engine has no occasion for" do
      expect { portrait(expression: "delighted") }
        .to raise_error(Portraits::Unrenderable, /firm, ready, settlement/)
    end
  end

  # ADR 0008's sharpest consequence. A halftone screen is fixed in ink on the
  # page: a portrait printed small gets fewer dots across it, not smaller ones.
  # `userSpaceOnUse` is the other way round, so one shared screen shrinks with
  # the portrait and at 78px collapses into a flat grey wash.
  describe "the screen is a property of the page, not of the artwork" do
    it "holds the dot pitch fixed in page pixels at every size served" do
      pitches = described_class::SIZES.map do |size|
        cell(portrait(size: size)) * size / Portraits::PartSet.default.width
      end

      # Within a thousandth, because the emitted cell is rounded to three
      # decimal places of a user unit — well under a pixel at every size served.
      expect(pitches).to all(be_within(0.001).of(described_class::PITCH))
    end

    # The counterfactual, stated as an expectation rather than as a comment: one
    # screen shared across the sizes is exactly a screen whose cell does not
    # change with the size, and that is the build that produced the grey wash.
    it "redraws the screen per size rather than sharing one across them" do
      cells = described_class::SIZES.map { |size| cell(portrait(size: size)) }

      expect(cells.uniq.size).to eq(described_class::SIZES.size)
    end

    it "refuses a size the part set has never been looked at in" do
      expect { portrait(size: 40) }
        .to raise_error(Portraits::Unrenderable, /78, 118, 168/)
    end
  end

  describe "two inks and the screens between them" do
    it "resolves every tone level through a custom property an ancestor can move" do
      drawn = portrait

      (%w[t0 t4] + described_class::SCREENS.keys).each do |tone|
        expect(drawn).to match(/\.#{tone}\{fill:var\(--portrait-[\w-]+,/)
      end
    end

    it "fills the screen's own dots with the ink, so the portrait follows the page" do
      expect(portrait.scan(/<circle [^>]*fill="([^"]+)"/).flatten.uniq)
        .to eq([described_class::INK])
    end

    # An SVG `<style>` in a document is not scoped to its own element. Two
    # portraits on one page would otherwise share a screen — and two *sizes*
    # sharing one is the failure this whole seam exists to prevent.
    it "scopes its screens and its rules to this render, so two on a page cannot collide" do
      ids = [portrait(size: 78), portrait(size: 168)].map { |svg| svg[/id="(t1-[^"]+)"/, 1] }

      expect(ids.uniq.size).to eq(2)
      expect(portrait).to include(".#{portrait[/class="portrait (portrait-\w+)"/, 1]} .t1{")
    end
  end
end
