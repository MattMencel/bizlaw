# frozen_string_literal: true

require "rails_helper"

# A term of art is glossed once per page, at first contact, in the left margin
# level with the word (`docs/design/voice.md` § Where a gloss sits). Where the
# sheet has no margin the notes become a list at the top of the face.
#
# The glosses and where they sit are copy (`glossary.en.yml`,
# `gloss_anchors.en.yml`); what is proved here is that each anchor still finds
# its word, carries exactly one note, and that the note is reachable from the
# word rather than only standing beside it.
RSpec.describe "the glosses", type: :system do
  before { Demo::Seed.call }

  # The word each term is glossed on, keyed by the entry it links to.
  def glossed
    all("a.glossed").to_h { |link| [link[:href].split("#gloss-").last, link.text] }
  end

  def described_by(link) = find(id: link["aria-describedby"], visible: :all).text

  def top(element) = element.evaluate_script("this.getBoundingClientRect().top")

  def left(element) = element.evaluate_script("this.getBoundingClientRect().left")

  describe "on a sheet wide enough for a margin" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    it "notes a term in the left margin, level with its word" do
      word = find("h3 a.glossed", text: /served/i)
      note = find("#gloss-served")

      expect(note).to have_text("served — formally handed to us")
      expect(left(note)).to be < left(find("h2#front-matter"))
      expect(top(note)).to be_within(2).of(top(word))
    end

    it "links the note to its word" do
      word = find("a.glossed", text: /served/i)

      expect(word[:href]).to end_with("#gloss-served")
      expect(described_by(word)).to include("formally handed to us")
    end

    it "keeps the list's heading for a screen reader alone" do
      heading = find("h3", text: /words used in this file/i, visible: :all)

      expect(heading.evaluate_script("this.getBoundingClientRect().width")).to be <= 1
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  # Which word each term is glossed on, as printed. Stamps and small-caps
  # headings print in capitals, so the comparison is on the word, not its case.
  def glossed_words = glossed.transform_values(&:downcase)

  def entries = all(".gloss-words .entry", visible: :all).map { |entry| entry[:id].delete_prefix("gloss-") }

  shared_examples "one note per term" do
    it "glosses each term once, and lists exactly those" do
      links = all("a.glossed")

      expect(links.size).to eq(glossed.size)
      expect(entries).to match_array(glossed.keys)
    end

    it "describes every glossed word by its own gloss" do
      all("a.glossed").each do |link|
        term = link[:href].split("#gloss-").last
        expect(described_by(link)).to eq(I18n.t("reads.glossary.terms.#{term}.gloss"))
      end
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end

  describe "the front of the draft, on the Day the player is handed" do
    before { visit "/demo/#{Demo::Seed::DEMO}" }

    include_examples "one note per term"

    it "glosses each term where it is first met" do
      expect(glossed_words).to eq(
        "served" => "served",
        "offer" => "offer",
        "case_file" => "case file",
        "countersign" => "countersignature",
        "term" => "terms",
        "exhibit" => "exhibit",
        "covering_note" => "covering note",
        "consult" => "consulting",
        "preparation_points" => "preparation",
        "exchange_points" => "exchange"
      )
    end

    it "sits each note on the site that is first met" do
      expect(page).to have_css("h3 a.glossed", text: /served/i)
      expect(page).to have_css("aside p.foot a.glossed", text: "exhibit")
      expect(page).to have_css("h2#term-sheet a.glossed", text: "terms")
      expect(page).to have_css("#memo ~ .empty-state a.glossed", text: "Consulting")
      expect(page).to have_css("h2#slip a.glossed", text: /exchange/i)
    end

    it "leaves every later occurrence alone" do
      expect(find("li.slip", text: "Consult the Client")).to have_no_css("a.glossed")
      expect(find("h2#slip")).to have_no_css("a.glossed", text: /preparation/i)
      expect(find("li", text: "Deposition of the plant supervisor")).to have_no_css("a.glossed")
    end

    it "notes nothing in the reading order out of place" do
      notes = entries.map { |term| top(find("#gloss-#{term}")) }

      expect(notes).to eq(notes.sort)
    end
  end

  # Day 1: the empty states are the tutorial, and they are met first.
  describe "the front of the draft at the cold open" do
    before { visit "/demo/#{Demo::Seed::COLD_OPEN}" }

    include_examples "one note per term"

    it "glosses the Exhibit and the Offer in the empty state that names them" do
      within(".empty-state", text: "any exhibit riding it") do
        expect(page).to have_css("a.glossed", text: "exhibit")
        expect(page).to have_css("a.glossed", text: "offer")
      end
    end
  end

  describe "the front of the draft once the Client has been consulted" do
    before do
      visit "/demo/#{Demo::Seed::DEMO}"
      find("li.slip", text: "Consult the Client").click_button("Spend")
      click_button "Confirm"
      expect(page).to have_css(".beat")
    end

    include_examples "one note per term"

    it "glosses the band the Client reads, and moves the rest down to the slip" do
      expect(find(".beat", match: :first)).to have_css("strong a.glossed", text: /\A(firm|ready)\z/i)
      expect(find("li.slip", text: "Consult the Client")).to have_css("a.glossed", text: "Consult")
      expect(find("h2#slip")).to have_css("a.glossed", text: /preparation/i)
    end
  end

  describe "the front of the draft with a position on the table" do
    before do
      simulation = Demo::Seed.simulation(Demo::Seed::DEMO)
      side = simulation.plaintiff_side
      Offers::Stage.call(side: side, day: simulation.days.find_by!(ordinal: Demo::Seed::DEMO_DAY),
        by: side.members.sole, terms: {"money" => 180_000_00, "apology" => nil})
      visit "/demo/#{Demo::Seed::DEMO}"
    end

    include_examples "one note per term"

    it "glosses exchange points on the price of executing it" do
      expect(page).to have_css(".execution .price a.glossed", text: "exchange")
      expect(find("h2#slip")).to have_no_css("a.glossed", text: /exchange/i)
    end
  end

  # No margin to put a note in, so the notes are a list at the top of the face,
  # and each glossed word links up to its entry.
  describe "on a narrow sheet" do
    before do
      page.driver.browser.manage.window.resize_to(760, 1200)
      visit "/demo/#{Demo::Seed::DEMO}"
    end

    after { page.driver.browser.manage.window.resize_to(1400, 1400) }

    def words_used = find("h3", text: /words used in this file/i).find(:xpath, "..")

    it "lists the words used in this file at the top of the front matter" do
      heading = find("h3", text: /words used in this file/i)

      expect(top(heading)).to be < top(find("h3", text: /landed today/i))
      expect(words_used).to have_text("served — formally handed to us")
    end

    it "prints no note in a margin" do
      note = find("#gloss-served")

      expect(left(note)).to be >= left(find("h2#front-matter"))
    end

    it "links each glossed word up to its entry" do
      glossed.each_key do |term|
        expect(words_used).to have_css("#gloss-#{term}")
      end

      find("a.glossed", text: /served/i).click

      expect(page).to have_current_path(/#gloss-served\z/, url: true)
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end
end
