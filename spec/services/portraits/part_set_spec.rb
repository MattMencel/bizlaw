# frozen_string_literal: true

require "rails_helper"
require "tmpdir"

# The part set on disk. The engine ships a default one; a commissioned set is
# proprietary, lives with the Cases and drops in at `PORTRAIT_PART_SET` with no
# code change — which only holds if what the engine insists on is exactly what
# its own rules name.
RSpec.describe Portraits::PartSet do
  let(:set) { described_class.default }

  it "loads the set the engine ships" do
    expect(set.root).to eq(Rails.root.join("portraits/default"))
    expect(set.order).to include("skull", "hair", "brows", "mouth")
  end

  it "draws a part for every expression the engine can ask for" do
    Portraits::EXPRESSIONS.each do |expression|
      expect(set.draw("brows", expression)).to be_present
      expect(set.draw("mouth", expression)).to be_present
    end
  end

  # Absence is a part rather than a nil, so nothing downstream branches on
  # whether a group is optional.
  it "draws no glasses as a part that draws nothing, rather than a missing one" do
    expect(set.parts("glasses")).to include("none")
    expect(set.draw("glasses", "none")).to eq("<g/>\n")
  end

  # Not a document — the compositor concatenates them — but single-rooted all
  # the same, so a part file is a thing an XML tool can open. The pre-commit
  # `check-xml` hook is what parses them; what this holds is the property the
  # derivation controls and the hook can only report after the fact.
  it "ships every part as one root element" do
    many = set.root.glob("*/*.svg").reject { |part| part.read.scan(/^<g[ \/>]/).size == 1 }

    expect(many).to be_empty
  end

  # A group is a list and never a set: a name repeated is a name drawn more
  # often, and that is the only weighting a set has.
  it "keeps a repeated name, because repetition is how a group is weighted" do
    expect(set.parts("glasses").count("none")).to be > 1
  end

  # A commissioned set is proprietary and drops in at `PORTRAIT_PART_SET`, which
  # only holds if a malformed one is refused on load rather than surfacing much
  # later as whatever raw exception the render happens to hit — or, worse, as no
  # exception at all. Each of these is built rather than committed, because what
  # is under test is one wrong line in an otherwise sound manifest.
  describe "what it refuses on load" do
    def a_part_set(ships: nil, **manifest)
      root = Pathname(Dir.mktmpdir)
      declared = {
        "view_box" => "24 24 216 216",
        "identity" => {"glasses" => %w[none]},
        "expression" => {"brows" => Portraits::EXPRESSIONS.dup, "mouth" => Portraits::EXPRESSIONS.dup},
        "held" => {"eyes" => "held"},
        "order" => %w[glasses brows mouth eyes]
      }.merge(manifest.transform_keys(&:to_s))

      (ships || parts_named(declared)).each do |part|
        root.join("#{part}.svg").dirname.mkpath
        root.join("#{part}.svg").write("<g/>\n")
      end
      root.join("set.yml").write(declared.to_yaml)
      root
    end

    def parts_named(declared)
      %w[identity expression].flat_map { |kind|
        next [] unless declared[kind].is_a?(Hash)

        declared[kind].flat_map { |group, names| Array(names).map { |name| "#{group}/#{name}" } }
      } + declared.fetch("held").map { |group, name| "#{group}/#{name}" }
    end

    def refusal(**manifest)
      expect { described_class.new(a_part_set(**manifest)) }
        .to raise_error(Portraits::Unrenderable, yield)
    end

    it "refuses a set that draws no part for a group it declares" do
      refusal(order: %w[brows mouth eyes]) { /declares glasses but never draws them/ }
    end

    it "refuses a set missing an expression, rather than failing on the render that needs it" do
      refusal(expression: {"brows" => Portraits::EXPRESSIONS.dup, "mouth" => %w[firm ready]}) do
        /draws no settlement mouth/
      end
    end

    # An identity part is drawn for a fraction of the Clients in a Section, so a
    # part named and never shipped fails on some memos and not others — which is
    # the worst way to learn a set is incomplete.
    it "refuses a set that names a part it never shipped" do
      expect {
        described_class.new(a_part_set(
          identity: {"glasses" => %w[none chignon]},
          ships: %w[glasses/none brows/firm brows/ready brows/settlement
            mouth/firm mouth/ready mouth/settlement eyes/held]
        ))
      }.to raise_error(Portraits::Unrenderable, %r{glasses/chignon})
    end

    # `Identity` draws by modulus, so an empty group is a division by zero on
    # exactly the Clients who drew it and on nobody else.
    it "refuses a group with nothing in it to draw" do
      refusal(identity: {"glasses" => []}) { /lists glasses as \[\], which is not parts/ }
    end

    # The one that raises nothing on its own: the halftone pitch is divided back
    # out by this width, so a frame without one renders every screen at no pitch
    # and hands back a blank silhouette rather than an error.
    it "refuses a frame with no width for the pitch to be divided out by" do
      refusal(view_box: "24 24 0 216") { /is not a viewBox with a width/ }
      refusal(view_box: "the whole page") { /is not a viewBox with a width/ }
    end

    it "refuses a group listed as something other than parts" do
      refusal(identity: {"glasses" => "none"}) { /lists glasses as "none"/ }
      refusal(held: {"eyes" => %w[held]}) { /holds eyes at \["held"\]/ }
    end
  end

  # Two inks. A part authored against a colour cannot be printed as a screen, so
  # the whole set is checked for one rather than the compositor being trusted to
  # notice.
  describe "every part is authored against a tone level and never a colour" do
    it "carries a tone class on every shape it draws" do
      shapes = set.root.glob("*/*.svg").flat_map { |part| part.read.scan(/<(?:path|rect|circle|ellipse)\b[^>]*>/) }

      expect(shapes).not_to be_empty
      expect(shapes.reject { |shape| shape.match?(/class="t[0-4]"/) }).to be_empty
    end

    it "bakes no colour into the art" do
      coloured = set.root.glob("*/*.svg").select { |part| part.read.match?(/fill=|stroke=|#[0-9a-fA-F]{3}/) }

      expect(coloured).to be_empty
    end
  end

  # MIT's grant is conditional on carrying its notice, and the repo is
  # Apache-2.0, so the parts sit inside it under their own terms. That is a live
  # obligation rather than a formality.
  describe "the licence the art actually ships under" do
    let(:notice) { set.root.join("NOTICE").read }

    it "carries the MIT grant and its copyright line beside the art" do
      expect(notice).to include(
        "Copyright (c) 2017 Pablo Stanley, Fang-Pen Lin",
        "Permission is hereby granted, free of charge",
        "https://github.com/fangpenlin/avataaars"
      )
    end

    it "says the art is not covered by this repository's licence" do
      expect(notice).to include("NOT covered by this repository's Apache-2.0 licence")
    end
  end
end
