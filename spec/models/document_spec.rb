# frozen_string_literal: true

require "rails_helper"

RSpec.describe Document, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:documentable) }
    it { is_expected.to belong_to(:created_by).class_name("User") }
    it { is_expected.to have_one_attached(:file) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:title) }
    it { is_expected.to validate_length_of(:title).is_at_least(3).is_at_most(255) }
    it { is_expected.to validate_presence_of(:document_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_presence_of(:file) }

    describe "file validations" do
      let(:document) { build(:document) }

      it "validates file size" do
        document.file.attach(
          io: StringIO.new("A" * 101.megabytes),
          filename: "large.pdf",
          content_type: "application/pdf"
        )
        expect(document).not_to be_valid
        expect(document.errors[:file]).to include("must be less than 100MB")
      end

      it "validates file content type" do
        document.file.attach(
          io: StringIO.new("Invalid content"),
          filename: "test.exe",
          content_type: "application/x-msdownload"
        )
        expect(document).not_to be_valid
        expect(document.errors[:file]).to include("must be a PDF, Word, Excel, PowerPoint, text, or markdown file")
      end
    end
  end

  describe "scopes" do
    let!(:template) { create(:document, :template) }
    let!(:assignment) { create(:document, document_type: "assignment") }
    let!(:submission) { create(:document, :submission) }
    let!(:draft) { create(:document, status: "draft") }
    let!(:final) { create(:document, :final) }
    let!(:archived) { create(:document, :archived) }

    describe ".by_type" do
      it "returns documents of the specified type" do
        expect(described_class.by_type("template")).to contain_exactly(template)
      end
    end

    describe ".by_status" do
      it "returns documents with the specified status" do
        expect(described_class.by_status("draft")).to contain_exactly(draft)
      end
    end

    describe ".templates" do
      it "returns only template documents" do
        expect(described_class.templates).to contain_exactly(template)
      end
    end

    describe ".active" do
      it "returns non-archived documents" do
        expect(described_class.active).not_to include(archived)
        expect(described_class.active).to include(draft, final)
      end
    end

    describe ".search_by_title" do
      let!(:searchable) { create(:document, title: "Searchable Document") }

      it "returns documents matching the search query" do
        expect(described_class.search_by_title("Searchable")).to contain_exactly(searchable)
      end
    end

    describe ".for_documentable" do
      let(:team) { create(:team) }
      let!(:team_document) { create(:document, documentable: team) }

      it "returns documents for the specified documentable" do
        expect(described_class.for_documentable("Team", team.id)).to contain_exactly(team_document)
      end
    end
  end

  describe "instance methods" do
    let(:document) { create(:document) }

    describe "file methods" do
      it "returns file extension" do
        expect(document.file_extension).to eq("pdf")
      end

      it "returns file size" do
        expect(document.file_size).to be_positive
      end

      it "returns file type" do
        expect(document.file_type).to eq("application/pdf")
      end
    end

    describe "status checks" do
      it "checks if document is a template" do
        expect(create(:document, :template)).to be_template
      end

      it "checks if document is archived" do
        expect(create(:document, :archived)).to be_archived
      end

      it "checks if document can be archived" do
        expect(create(:document, :final)).to be_can_archive
      end

      it "checks if document can be finalized" do
        expect(document).to be_can_finalize
      end
    end
  end

  describe "status transitions" do
    describe "#finalize!" do
      let(:document) { create(:document) }

      it "transitions from draft to final" do
        expect(document.finalize!).to be true
        expect(document.reload).to be_status_final
        expect(document.finalized_at).to be_present
      end

      it "fails if not in draft status" do
        document.update(status: :final)
        expect(document.finalize!).to be false
      end
    end

    describe "#archive!" do
      let(:document) { create(:document, :final) }

      it "transitions from final to archived" do
        expect(document.archive!).to be true
        expect(document.reload).to be_status_archived
        expect(document.archived_at).to be_present
      end

      it "fails if not in final status" do
        document.update(status: :draft)
        expect(document.archive!).to be false
      end
    end
  end

  describe "template functionality" do
    let(:template) { create(:document, :template) }
    let(:user) { create(:user) }
    let(:team) { create(:team) }

    describe "#create_from_template" do
      it "creates a new document from template" do
        new_document = template.create_from_template(
          title: "New Document",
          document_type: "assignment",
          created_by: user,
          documentable: team
        )

        expect(new_document).to be_persisted
        expect(new_document.title).to eq("New Document")
        expect(new_document.document_type).to eq("assignment")
        expect(new_document.status).to eq("draft")
        expect(new_document.created_by).to eq(user)
        expect(new_document.documentable).to eq(team)
        expect(new_document.file).to be_attached
      end

      it "returns nil if source is not a template" do
        non_template = create(:document)
        expect(non_template.create_from_template).to be_nil
      end

      it "uses default values when attributes are not provided" do
        new_document = template.create_from_template
        expect(new_document.title).to start_with("Copy of")
        expect(new_document.document_type).to eq("assignment")
      end
    end
  end
end
