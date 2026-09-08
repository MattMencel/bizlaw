# frozen_string_literal: true

# Derives the engine's default portrait part set from a checkout of
# `fangpenlin/avataaars`, and writes it under `portraits/default`.
#
# **This is a design-time tool and nothing else.** It is not run at build time,
# not at import and not at runtime — ADR 0008 forbids all three, and the whole
# point of committing the *parts* rather than the renders is that no step of a
# deployed pipeline generates art. What ships is this task's committed output.
# It exists so the derivation is auditable and re-runnable rather than a pile of
# path data of unexplained provenance.
#
#   bundle exec rake "portraits:derive[../avataaars]"
#
# What it does is mechanical. avataaars is React components whose colour comes
# from a palette masked into a silhouette, so for each part the silhouette is
# the shape and the palette is noise. The recipe names the source component, the
# shapes to take from it, the transform chain that puts them in avataaars' own
# 264x280 space, and the **tone level** each shape is authored against. Tone
# levels rather than colours is the decision — see ADR 0008.
#
# The parts stay MIT. `portraits/default/NOTICE` carries the grant, and it is
# copied out of the source checkout's own LICENSE rather than transcribed.
module PortraitDerivation
  # avataaars' own space, and the space every part is written into: the whole
  # composition lives inside 264x280, and every transform below is a chain from
  # one component's local origin to that.
  ORIGINS = {
    body: "translate(32, 36)",
    face: "translate(76, 82)",
    clothes: "translate(0, 170)",
    top: "translate(-1, 0)",
    facial_hair: "translate(49, 72)",
    accessories: "translate(62, 85)"
  }.freeze

  # The head, ears, neck and shoulders, as one silhouette. It is the only part
  # not taken from a part component: avataaars assembles it in `avatar/index.tsx`
  # and masks a skin colour into it, and two inks have no skin colour, so what
  # is left is the silhouette.
  SKIN = {
    source: "avatar/index.tsx",
    # avataaars' own shadow under the jaw is dropped rather than assigned a
    # level. It is a tenth of black over the skin, and the lightest screen here
    # is already heavier than that, so the nearest honest level puts a grey
    # crescent on the throat that reads as a scarf. Five levels is what the
    # register has; a value that does not fit one is not drawn.
    shapes: [{index: 2, tone: "t1", at: ORIGINS[:body]}]
  }.freeze

  # The skull is an **identity** group and has to be: two inks delete skin tone
  # and hair colour, so shape is all that is left to tell two Clients apart.
  # avataaars draws one head, so the four here are that head at four
  # proportions — which is a stand-in and is why ADR 0008 says the commission
  # buys shape. Where the point is and which way the scale runs are both
  # deliberate:
  #
  # - the origin is the **crown** rather than the neck, so the hairline holds
  #   still and every hair part keeps sitting where it was drawn to sit;
  # - no scale is ever above 1, so a wider skull can never push skin out past
  #   the hair silhouette that is drawn over it. A narrower one leaves the hair
  #   slightly proud of the cheek, which reads as hair.
  CROWN = [132, 40].freeze
  SKULLS = {
    "oval" => "1, 1",
    "narrow" => "0.955, 1",
    "round" => "1, 0.965",
    "fine" => "0.955, 0.965"
  }.freeze

  # Every part the default set ships, by group. A group is a directory of SVG
  # fragments; `set.yml` names them and the compositor layers them.
  #
  # Tone is a judgement made once, here: avataaars paints a shirt `#E6E6E6` and
  # a blazer `#3A4C5A` because it has colour to spend, and this register has
  # five levels to put them on instead. Paper is `t0`, ink is `t4`, and the three
  # between are screens.
  PARTS = {
    "eyes" => {
      "held" => {
        source: "avatar/face/eyes/Default.tsx",
        shapes: [{all: true, tone: "t4", at: "#{ORIGINS[:face]} translate(0, 8)"}]
      }
    },
    "nose" => {
      "held" => {
        source: "avatar/face/nose/Default.tsx",
        shapes: [{all: true, tone: "t2", at: "#{ORIGINS[:face]} translate(28, 40)"}]
      }
    },
    # The engine picks a brow and a mouth from the band at a Consult and from
    # the authored settlement expression at a settlement. Three, and there is no
    # fourth: see ADR 0007.
    "brows" => {
      # Level and carried low: willing to keep holding out.
      "firm" => {
        source: "avatar/face/eyebrow/FlatNatural.tsx",
        shapes: [{all: true, tone: "t4", at: ORIGINS[:face]}]
      },
      # The inner ends lift. The only part of the face that opens.
      "ready" => {
        source: "avatar/face/eyebrow/RaisedExcitedNatural.tsx",
        shapes: [{all: true, tone: "t4", at: ORIGINS[:face]}]
      },
      # Neither braced nor asking, and the same at every settlement.
      "settlement" => {
        source: "avatar/face/eyebrow/DefaultNatural.tsx",
        shapes: [{all: true, tone: "t4", at: ORIGINS[:face]}]
      }
    },
    "mouth" => {
      # Closed, corners a shade below centre. Braced.
      "firm" => {
        source: "avatar/face/mouth/Sad.tsx",
        shapes: [{all: true, tone: "t4", at: "#{ORIGINS[:face]} translate(2, 52)"}]
      },
      # The press comes off. Still closed, still not pleased.
      "ready" => {
        source: "avatar/face/mouth/Serious.tsx",
        shapes: [{all: true, tone: "t4", at: "#{ORIGINS[:face]} translate(2, 52)"}]
      },
      # Closed, corners just up. Spent rather than delighted.
      "settlement" => {
        source: "avatar/face/mouth/Twinkle.tsx",
        shapes: [{all: true, tone: "t4", at: "#{ORIGINS[:face]} translate(2, 52)"}]
      }
    },
    # Two inks delete skin tone and hair colour, which is where an ordinary
    # avatar system gets most of its variety, so what is left is shape. Hair is
    # the group to buy deep — eight here, against avataaars' one head and one
    # nose.
    "hair" => {
      "short_flat" => {
        source: "avatar/top/ShortHairShortFlat.tsx",
        shapes: [{index: 0, tone: "t3", at: ORIGINS[:top]}]
      },
      "short_waved" => {
        source: "avatar/top/ShortHairShortWaved.tsx",
        shapes: [{index: 0, tone: "t3", at: ORIGINS[:top]}]
      },
      "frizzle" => {
        source: "avatar/top/ShortHairFrizzle.tsx",
        shapes: [{index: 0, tone: "t3", at: ORIGINS[:top]}]
      },
      "caesar" => {
        source: "avatar/top/ShortHairTheCaesar.tsx",
        shapes: [{index: 0, tone: "t3", at: "#{ORIGINS[:top]} translate(75, 34)"}]
      },
      "sides" => {
        source: "avatar/top/ShortHairSides.tsx",
        shapes: [
          {index: 0, tone: "t3", at: ORIGINS[:top]},
          {index: 1, tone: "t3", at: "#{ORIGINS[:top]} translate(70, 74)"}
        ]
      },
      "bob" => {
        source: "avatar/top/LongHairBob.tsx",
        shapes: [{index: 0, tone: "t3", at: "#{ORIGINS[:top]} translate(39, 19)"}]
      },
      "straight" => {
        source: "avatar/top/LongHairStraight.tsx",
        shapes: [{index: 0, tone: "t3", at: "#{ORIGINS[:top]} translate(59, 18)"}]
      },
      "bun" => {
        source: "avatar/top/LongHairBun.tsx",
        shapes: [{index: 0, tone: "t3", at: ORIGINS[:top]}]
      }
    },
    "garment" => {
      "blazer_shirt" => {
        source: "avatar/clothes/BlazerShirt.tsx",
        shapes: [
          {index: 0, tone: "t0", at: "#{ORIGINS[:clothes]} translate(32, 29)"},
          {id: "Saco", tone: "t3", at: "#{ORIGINS[:clothes]} translate(32, 28)"},
          {id: "Pocket-hanky", tone: "t0", at: "#{ORIGINS[:clothes]} translate(32, 28)"},
          {id: "Wing", every: true, tone: "t4", at: "#{ORIGINS[:clothes]} translate(32, 28)"}
        ]
      },
      "blazer_sweater" => {
        source: "avatar/clothes/BlazerSweater.tsx",
        shapes: [
          {index: 0, tone: "t2", at: ORIGINS[:clothes]},
          {id: "Saco", tone: "t3", at: "#{ORIGINS[:clothes]} translate(32, 28)"},
          {id: "Pocket-hanky", tone: "t0", at: "#{ORIGINS[:clothes]} translate(32, 28)"},
          {id: "Wing", every: true, tone: "t4", at: "#{ORIGINS[:clothes]} translate(32, 28)"},
          {id: "Collar", tone: "t0", at: ORIGINS[:clothes]}
        ]
      },
      "collar_sweater" => {
        source: "avatar/clothes/CollarSweater.tsx",
        shapes: [
          {index: 0, tone: "t2", at: ORIGINS[:clothes]},
          {id: "Collar", tone: "t0", at: ORIGINS[:clothes]}
        ]
      },
      "open_collar" => {
        source: "avatar/clothes/ShirtVNeck.tsx",
        shapes: [{index: 0, tone: "t2", at: ORIGINS[:clothes]}]
      }
    },
    # Absence is a part rather than a nil, so a group is always a draw over a
    # list and the compositor never branches on whether a group is optional.
    "glasses" => {
      "none" => {source: nil, shapes: []},
      "round" => {
        source: "avatar/top/accessories/Round.tsx",
        shapes: [{index: 0, tone: "t4", at: ORIGINS[:accessories]}]
      },
      "rectangular" => {
        source: "avatar/top/accessories/Prescription01.tsx",
        shapes: [{all: true, tone: "t4", at: "#{ORIGINS[:accessories]} translate(8, 8)"}]
      },
      "heavy" => {
        source: "avatar/top/accessories/Prescription02.tsx",
        shapes: [{all: true, tone: "t4", at: "#{ORIGINS[:accessories]} translate(6, 7)"}]
      }
    },
    "facial_hair" => {
      "none" => {source: nil, shapes: []},
      "beard" => {
        source: "avatar/top/facialHair/BeardLight.tsx",
        shapes: [{index: 0, tone: "t3", at: ORIGINS[:facial_hair]}]
      },
      "moustache" => {
        source: "avatar/top/facialHair/MoustacheMagnum.tsx",
        shapes: [{index: 0, tone: "t3", at: ORIGINS[:facial_hair]}]
      }
    }
  }.freeze

  # What the compositor reads: which groups the seed draws, which the engine
  # picks, the order they stack in, and the space they were drawn in. It ships
  # *with* the set rather than in the engine, because a commissioned set is a
  # file swap and its groups are its own to declare.
  #
  # How often a part is drawn against the others in its group. Listing a name
  # twice is the only weighting a set has, so this is where the repeats come
  # from — and the lists are built from what was actually derived, so a part
  # added to `PARTS` and forgotten here still reaches the manifest at weight one
  # rather than being shipped and never drawn.
  WEIGHTS = {"glasses" => {"none" => 3}, "facial_hair" => {"none" => 3}}.freeze

  def self.listing(group, names)
    weights = WEIGHTS.fetch(group, {})
    names.flat_map { |name| [name] * weights.fetch(name, 1) }.join(", ")
  end

  MANIFEST = <<~YAML
    # The default part set: what `rake portraits:derive` produced, and how it
    # stacks. Regenerated with the parts, so an edit here is an edit there.
    #
    # A group is a directory of SVG fragments. Every fragment is authored against
    # tone levels — t0 paper, t4 ink, t1..t3 the screens between — and never
    # against a colour, so the same part prints as a halftone or as a flat wash
    # without being redrawn.
    ---
    # avataaars' own space. Cropped to a bust, and square, because every size the
    # game serves is served square.
    view_box: "24 24 216 216"
    # Drawn once by the Case's seed and never moving again. A name repeated is a
    # name drawn more often.
    identity:
      skull: [#{SKULLS.keys.join(", ")}]
      hair: [#{listing("hair", PARTS.fetch("hair").keys)}]
      garment: [#{listing("garment", PARTS.fetch("garment").keys)}]
      glasses: [#{listing("glasses", PARTS.fetch("glasses").keys)}]
      facial_hair: [#{listing("facial_hair", PARTS.fetch("facial_hair").keys)}]
    # The only groups the engine ever picks: from the Reaction Band at a Consult,
    # and from the authored settlement expression at a settlement.
    expression:
      brows: [firm, ready, settlement]
      mouth: [firm, ready, settlement]
    # One pair of eyes and one nose, for everyone.
    held:
      eyes: held
      nose: held
    # Back to front, and it is avataaars' own order: the face goes under the
    # facial hair, the facial hair under the hair, and the glasses over all of it.
    order: [skull, garment, mouth, nose, eyes, brows, facial_hair, hair, glasses]
  YAML

  # The attributes that carry geometry. Colour, opacity, masks and filters are
  # dropped: an avataaars mask clips a palette rect to a silhouette, so once the
  # palette is gone the silhouette is the whole shape.
  GEOMETRY = %w[id d transform x y width height rx ry cx cy r].freeze

  module_function

  def derive(checkout, root)
    source = checkout.join("src")
    raise "#{source} does not look like a checkout of fangpenlin/avataaars" unless source.directory?

    root.rmtree if root.exist?
    skin = shapes_for(source, SKIN)
    SKULLS.each do |name, scale|
      write_part(root.join("skull", "#{name}.svg"), skin, around: about_the_crown(scale))
    end
    PARTS.each do |group, parts|
      parts.each { |name, recipe| write_part(root.join(group, "#{name}.svg"), shapes_for(source, recipe)) }
    end
    root.join("NOTICE").write(notice_from(checkout))
    root.join("set.yml").write(MANIFEST)
  end

  # Every shape a component draws, in document order. The full-canvas rect every
  # `top/` component carries is dropped: it is the mask avataaars clips the
  # composition to, never art, and leaving it in would make every index in the
  # recipe depend on whether a component happens to have one.
  def shapes_in(file)
    file.read.scan(%r{<(path|rect|circle|ellipse)\b(.*?)/>}m).filter_map do |tag, attributes|
      geometry = attributes.scan(/(\w[\w:-]*)=(?:'([^']*)'|"([^"]*)")/)
        .to_h { |key, single, double| [key, single || double] }
        .slice(*GEOMETRY)
      next if geometry["width"] == "264" && geometry["height"] == "280"

      {tag: tag, attributes: geometry}
    end
  end

  # A recipe's shapes, resolved against the source component and tagged with the
  # tone level and the placement they were authored against.
  def shapes_for(source, recipe)
    return [] if recipe[:source].nil?

    drawn = shapes_in(source.join(recipe.fetch(:source)))
    recipe.fetch(:shapes).flat_map do |wanted|
      select(drawn, wanted).map do |shape|
        shape.merge(tone: wanted.fetch(:tone), at: wanted.fetch(:at))
      end
    end
  end

  def select(drawn, wanted)
    return drawn if wanted[:all]

    if wanted[:id]
      matching = drawn.select { |shape| shape.dig(:attributes, "id") == wanted[:id] }
      raise "no shape carries id #{wanted[:id]}" if matching.empty?

      return wanted[:every] ? matching : matching.take(1)
    end

    [drawn.fetch(wanted.fetch(:index))]
  end

  def about_the_crown(scale)
    x, y = CROWN
    "translate(#{x}, #{y}) scale(#{scale}) translate(#{-x}, #{-y})"
  end

  # One part, as an SVG fragment: `<g>`s carrying the transform chain into
  # avataaars' space, and inside them the shapes with a tone class each.
  # Consecutive shapes sharing a placement share a `<g>`; shapes are never
  # reordered to share one, because the order is the layering.
  #
  # A fragment is not a document — the compositor concatenates these — so it
  # carries no viewBox and no namespace of its own. It is single-rooted all the
  # same, so a part file still parses as XML on its own, and a part that draws
  # nothing is `<g/>` rather than an empty file: that is how *no glasses* is a
  # part rather than a nil.
  def write_part(path, shapes, around: nil)
    path.dirname.mkpath
    return path.write("<g/>\n") if shapes.empty?

    body = shapes.chunk_while { |a, b| a.fetch(:at) == b.fetch(:at) }.map do |run|
      inner = run.map { |shape| element_for(shape) }.join("\n      ")
      %(    <g transform="#{run.first.fetch(:at)}">\n      #{inner}\n    </g>)
    end.join("\n")

    outer = around ? %(<g transform="#{around}">) : "<g>"
    path.write("#{outer}\n#{body}\n</g>\n")
  end

  def element_for(shape)
    rendered = shape.fetch(:attributes).except("id")
      .map { |key, value| %(#{key}="#{value.gsub(/\s+/, " ").strip}") }
      .join(" ")
    %(<#{shape.fetch(:tag)} class="#{shape.fetch(:tone)}" #{rendered}/>)
  end

  # MIT's grant is conditional on carrying its notice, so the notice ships with
  # the art rather than being summarised near it. Copied out of the source
  # checkout so it cannot drift from what was actually granted.
  def notice_from(checkout)
    <<~NOTICE
      The SVG parts in this directory are a derivative of the avatar artwork in
      https://github.com/fangpenlin/avataaars, which is MIT licensed. They are
      NOT covered by this repository's Apache-2.0 licence: the MIT licence and
      the notice below travel with them.

      Derived by `rake portraits:derive`. What the derivation changes: avataaars
      paints each silhouette by masking a palette colour into it, and this
      register has two inks and no palette, so the silhouettes are kept and every
      colour is replaced by a tone level resolved through a CSS custom property.
      No geometry is redrawn.

      Not taken from avataaars.com, whose licence is a line of marketing copy
      behind a certificate that expired in 2021. The grant below is the one that
      actually exists.

      #{checkout.join("LICENSE").read.strip}
    NOTICE
  end
end

namespace :portraits do
  desc "Derive portraits/default from a checkout of fangpenlin/avataaars (design-time only)"
  task :derive, [:checkout] do |_task, args|
    checkout = args[:checkout] or abort %(usage: rake "portraits:derive[path/to/avataaars]")
    root = Rails.root.join("portraits/default")
    PortraitDerivation.derive(Pathname(checkout), root)
    puts "Derived #{Dir[root.join("**/*.svg")].size} parts into #{root}"
  end
end
