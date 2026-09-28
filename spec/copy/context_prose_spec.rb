# frozen_string_literal: true

require "pathname"

# **Don't lift sentences from `CONTEXT.md`** — rule 3 of `docs/design/voice.md`.
# The glossary explains design decisions to developers; copy takes its
# vocabulary and none of its prose.
#
# This is the deterministic floor under that rule, not the rule itself: a
# sentence of eight words or more, compared after case, punctuation, markdown
# emphasis and whitespace are normalised away, must not appear in the raw text
# of a copy-path file. Raw text means comments too — a lifted comment in a read
# is one edit away from a lifted string. Exact match only; a paraphrase is the
# copy review's to catch.
#
# No Rails boot: it reads files off disk and nothing else.
RSpec.describe "the prose in CONTEXT.md" do
  let(:root) { Pathname(__dir__).join("../..").expand_path }

  let(:copy_paths) do
    %w[
      config/locales/**/*.yml
      app/frontend/**/*.svelte
      app/reads/**/*
      db/cases/reference.yml
      lib/demo/seed.rb
    ]
  end

  # Lifts already on main, by file, as `CONTEXT.md` words them. It only
  # shrinks: an entry that no longer matches fails below, so a rewritten string
  # takes its permission with it.
  let(:allowed) do
    {
      "app/reads/action_board.rb" => [
        "The menu of what a Team could do this Day, each Action with its cost and its lead time.",
        "What we could do — opposite the Case File's what we know and the Docket's what we have done."
      ],
      "app/reads/case_file.rb" => [
        "Some documents also carry an Exhibit — the Case File is a folder that happens to hold " \
        "a few playable things, not a hand."
      ],
      "app/reads/morning_briefing.rb" => [
        "Every section is composed by the engine from objects the Case already authors, " \
        "so a briefing is never authored per Case."
      ],
      "app/reads/terms_board.rb" => [
        "Par is what the grade is measured against, and no rubric-derived number reaches a student before Release.",
        "A composite of the furthest each Term ever reached is a position nobody put on the table."
      ],
      "db/cases/reference.yml" => [
        "So an Exhibit is worth the same share of a Client's travel whether the Section made that Client easy or hard."
      ]
    }
  end

  # Lowercase, and every run of anything that is not a letter or digit becomes
  # one space — which takes markdown emphasis, backticks, quotes, dashes, a
  # comment's `#` and a YAML fold's indentation with it. Padded so a match
  # lands on word boundaries.
  def normalise(text) = " #{text.downcase.gsub(/[^[:alnum:]]+/, " ").strip} "

  # Paragraphs, then sentences within them. Headings are names, not prose.
  def sentences(markdown)
    markdown.lines.grep_v(/\A#/).join.split(/\n\s*\n/).flat_map { |paragraph|
      paragraph.gsub(/\s+/, " ").split(/(?<=[.!?])["'”’*_)]*\s+/)
    }
  end

  def lifted?(sentence) = normalise(sentence).split.size >= 8

  let(:kept) { sentences(root.join("CONTEXT.md").read(encoding: "UTF-8")).select { lifted?(it) }.map { normalise(it) }.uniq }

  let(:copy) do
    copy_paths.flat_map { |pattern| root.glob(pattern) }.select(&:file?).uniq.to_h { |file|
      [file.relative_path_from(root).to_s, normalise(file.read(encoding: "UTF-8"))]
    }
  end

  def lifts_in(copy, sentences)
    copy.flat_map { |file, text| sentences.select { |s| text.include?(s) }.map { |s| [file, s] } }
  end

  it "keeps enough of the glossary to mean something" do
    expect(kept.size).to be > 300
  end

  it "sweeps every copy path" do
    expect(copy.keys).to include(
      "config/locales/en.yml", "db/cases/reference.yml", "lib/demo/seed.rb", "app/reads/docket.rb"
    )
    expect(copy.keys).to include(a_string_matching(%r{\Aapp/frontend/.+\.svelte\z}))
  end

  it "finds no sentence of it in a copy path outside the allowlist" do
    permitted = allowed.flat_map { |file, entries| entries.map { |entry| [file, normalise(entry)] } }

    stray = (lifts_in(copy, kept) - permitted).map { |file, sentence| "#{file}: #{sentence.strip.inspect}" }

    expect(stray).to be_empty
  end

  it "allows nothing that is no longer there" do
    stale = allowed.flat_map { |file, entries|
      entries.reject { |entry|
        kept.include?(normalise(entry)) && copy.fetch(file, "").include?(normalise(entry))
      }.map { |entry| "#{file}: #{entry.inspect}" }
    }

    expect(stale).to be_empty
  end

  describe "the normaliser" do
    it "matches a sentence through emphasis, case and a comment's line breaks" do
      sentence = normalise("A **Day** is a unit of the *Simulation*, not of wall-clock time.")
      comment = "  # a day is a unit of the simulation,\n  # not of wall clock time\n"

      expect(normalise(comment)).to include(sentence)
    end

    it "matches on whole words only" do
      expect(normalise("xa day is a unit")).not_to include(normalise("a day is a unit"))
    end
  end
end
