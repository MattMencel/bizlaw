# frozen_string_literal: true

require "rails_helper"

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

  it "refuses a set that draws no part for a group it declares" do
    expect { described_class.new(Rails.root.join("spec/fixtures/portraits/undeclared")) }
      .to raise_error(Portraits::Unrenderable, /declares glasses but never draws them/)
  end

  it "refuses a set missing an expression, rather than failing on the render that needs it" do
    expect { described_class.new(Rails.root.join("spec/fixtures/portraits/wordless")) }
      .to raise_error(Portraits::Unrenderable, /draws no settlement mouth/)
  end

  # An identity part is drawn for a fraction of the Clients in a Section, so a
  # part named and never shipped fails on some memos and not others — which is
  # the worst way to learn a set is incomplete, and why it is a load-time check.
  it "refuses a set that names a part it never shipped" do
    expect { described_class.new(Rails.root.join("spec/fixtures/portraits/promised")) }
      .to raise_error(Portraits::Unrenderable, %r{glasses/chignon})
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
