# frozen_string_literal: true

module Portraits
  # A part set on disk: `set.yml` and a directory of SVG fragments per group.
  #
  # The manifest ships **with the set** rather than in the engine, because a
  # commissioned set is a file swap and its groups, its weighting and its
  # stacking order are its own to declare. What the engine insists on is only
  # what its rules name: the two expression groups, and a part in each of them
  # for every expression the engine can ask for.
  #
  # A name may appear twice in a group's list, and that is how a group is
  # weighted — `none` three times against three frames puts half the Clients in
  # glasses. So a group is a list and never a set, and `parts` returns it with
  # the repeats intact.
  class PartSet
    MANIFEST = "set.yml"

    def self.default = @default ||= new(Portraits.part_set_root)

    def initialize(root)
      @root = Pathname(root)
      @manifest = YAML.safe_load_file(@root.join(MANIFEST))
      validate!
    rescue Psych::Exception, SystemCallError => e
      raise Unrenderable, "#{root} is not readable as a part set: #{e.message}"
    end

    attr_reader :root

    # The frame every part was drawn in, and the frame every render uses. The
    # halftone pitch is divided back out by the ratio between it and the
    # rendered size, which is why the compositor needs it.
    def view_box = @manifest.fetch("view_box")

    def width = view_box.split.fetch(2).to_f

    # Back to front.
    def order = @manifest.fetch("order")

    # Drawn once by the Case's seed. The only groups an identity is composed
    # from, and so the only ones two Clients of one Case can differ in.
    def identity_groups = @manifest.fetch("identity")

    def identity_group?(group) = identity_groups.key?(group)

    def expression_group?(group) = @manifest.fetch("expression").key?(group)

    # One pair of eyes and one nose, for everyone.
    def held_part(group) = @manifest.fetch("held").fetch(group)

    def parts(group) = identity_groups.fetch(group)

    # One part, as the SVG fragment it was committed as. Single-rooted, so a
    # part file parses as XML on its own; a part that draws nothing — *no
    # glasses* — is `<g/>` rather than a nil, so no caller branches on whether a
    # group is optional.
    def draw(group, name)
      @drawn ||= {}
      @drawn[[group, name]] ||= root.join(group, "#{name}.svg").read
    rescue SystemCallError
      raise Unrenderable, "#{root} draws no #{name} for #{group}"
    end

    private

    # The engine's own rules are what a set has to satisfy, and it is checked on
    # load rather than on the render that needs it: a set missing a settlement
    # mouth would otherwise import fine, run fine, and fail on the last screen a
    # Team ever reads.
    def validate!
      %w[view_box identity expression held order].each do |key|
        raise Unrenderable, "#{root}'s #{MANIFEST} declares no #{key}" if @manifest[key].blank?
      end

      declared = @manifest.fetch("identity").keys +
        @manifest.fetch("expression").keys + @manifest.fetch("held").keys
      missing = declared - order
      raise Unrenderable, "#{root} declares #{missing.join(", ")} but never draws them" if missing.any?

      unknown = order - declared
      raise Unrenderable, "#{root} draws #{unknown.join(", ")} but declares no part for them" if unknown.any?

      @manifest.fetch("expression").each do |group, names|
        absent = EXPRESSIONS - names
        next if absent.empty?

        raise Unrenderable, "#{root} draws no #{absent.join(", ")} #{group}"
      end

      # And every part the manifest lists is on disk. Without this a set that
      # names a part it never shipped loads, imports, and then fails on the one
      # render that happens to draw it — which for an identity group is a
      # fraction of the Clients in a Section and for nobody else.
      missing = order.flat_map do |group|
        names_for(group).uniq.reject { |name| root.join(group, "#{name}.svg").file? }
          .map { |name| "#{group}/#{name}" }
      end
      raise Unrenderable, "#{root} lists #{missing.join(", ")} and ships no file for them" if missing.any?
    end

    def names_for(group)
      return identity_groups.fetch(group) if identity_group?(group)
      return @manifest.fetch("expression").fetch(group) if expression_group?(group)

      [held_part(group)]
    end
  end
end
