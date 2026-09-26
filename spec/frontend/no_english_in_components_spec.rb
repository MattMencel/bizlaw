# frozen_string_literal: true

require "rails_helper"

# **No English in a `.svelte` file.** Every word a student or the Instructor
# reads lives under `config/locales/`, so a reviewer checking the voice reads
# one place per surface and a component only arranges what a composer handed
# it. Punctuation and glyphs (" · ", "—") stay in components; authored fiction
# never reaches one except as a prop.
#
# See `SvelteCopy` for what counts as a word and where it looks.
RSpec.describe "the words in a component" do
  let(:components) { Rails.root.glob("app/frontend/**/*.svelte") }

  # Words a component may still hold, by file. It only shrinks: an entry that
  # no longer appears fails below, so a word moved out of a component takes its
  # permission with it.
  let(:allowed) { {} }

  def words_by_file
    components.to_h { |file| [file.relative_path_from(Rails.root).to_s, SvelteCopy.words_in(file.read(encoding: "UTF-8"))] }
  end

  it "sweeps every page" do
    expect(components.map { |file| file.basename.to_s })
      .to include("WorkingDraft.svelte", "ExecutedInstrument.svelte", "Minute.svelte")
  end

  it "finds none outside the allowlist" do
    stray = words_by_file.flat_map { |file, words|
      (words - allowed.fetch(file, [])).map { |word| "#{file}: #{word.inspect}" }
    }

    expect(stray).to be_empty
  end

  it "allows nothing that is no longer there" do
    found = words_by_file

    stale = allowed.flat_map { |file, words|
      (words - found.fetch(file, [])).map { |word| "#{file}: #{word.inspect}" }
    }

    expect(stale).to be_empty
  end

  # The sweep proves nothing unless it can fail. Each of these is a place a
  # word has actually hidden in a component.
  describe "the scanner" do
    def words(source) = SvelteCopy.words_in(source)

    it "finds a word between tags" do
      expect(words("<p>Arrived this morning</p>")).to eq(["Arrived this morning"])
    end

    it "finds a word in each attribute a reader is shown" do
      expect(words(%(<input aria-label="Spend" placeholder="Note" title="Tip" alt="Face" />)))
        .to eq(%w[Spend Note Tip Face])
    end

    it "finds a word in a template literal on a shown attribute" do
      expect(words("<button aria-label={`Spend ${action.label}`}>{x}</button>")).to eq(["Spend"])
    end

    it "finds a single lowercase word on a shown attribute" do
      expect(words(%(<button aria-label={open ? "close" : label}></button>))).to eq(["close"])
    end

    it "finds a sentence in an expression between tags" do
      expect(words(%(<span>{face === "back" ? "You are looking at the back." : x}</span>)))
        .to eq(["You are looking at the back."])
    end

    it "finds a word in a script" do
      source = <<~SVELTE
        <script>
          // Never "Commented out"
          const FIGURE = /^\\$?(\\d{1,3}(?:,\\d{3})*|\\d+)$/
          const withheld = drawn ? null : "An offer names at least one term."
        </script>
      SVELTE

      expect(words(source)).to eq(["An offer names at least one term."])
    end

    it "finds a word in a page title" do
      expect(words("<svelte:head><title>Minute — settled</title></svelte:head>"))
        .to eq(["Minute — settled"])
    end

    it "passes punctuation, identifiers, comments and styles" do
      source = <<~SVELTE
        <!-- The Day, in the grammar #315 settled. -->
        <script>
          import { router } from "@inertiajs/svelte"
          document.getElementById("term-sheet")?.focus()
        </script>
        <span class="meta" id={`spend-${kind}`}>{copy.day} · {i ? " — " : ""}</span>
        <style>
          .doc-sub { text-transform: uppercase; }
        </style>
      SVELTE

      expect(words(source)).to be_empty
    end
  end
end
