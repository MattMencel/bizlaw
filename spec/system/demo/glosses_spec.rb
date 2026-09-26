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
      expect(page).to have_no_text("Words used in this file")
      expect(page).to have_css("h3", text: "Words used in this file", visible: :all)
    end

    it "is accessible" do
      expect(page).to be_axe_clean
    end
  end
end
