# frozen_string_literal: true

class Document < ApplicationRecord
  include HasUuid
  include HasTimestamps
  include SoftDeletable
  include ActiveStorageValidations

  # Associations
  belongs_to :documentable, polymorphic: true
  belongs_to :created_by, class_name: "User"
  has_one_attached :file

  # Enums
  enum :status, {
    draft: "draft",
    final: "final",
    archived: "archived"
  }, prefix: :status

  enum :document_type, {
    assignment: "assignment",
    submission: "submission",
    feedback: "feedback",
    template: "template",
    resource: "resource",
    other: "other"
  }, prefix: true

  # Validations
  validates :title, presence: true,
                   length: { minimum: 3, maximum: 255 }
  validates :document_type, presence: true
  validates :status, presence: true
  validates :file, presence: true,
                  content_type: {
                    in: %w[
                      application/pdf
                      application/msword
                      application/vnd.openxmlformats-officedocument.wordprocessingml.document
                      application/vnd.ms-excel
                      application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
                      application/vnd.ms-powerpoint
                      application/vnd.openxmlformats-officedocument.presentationml.presentation
                      text/plain
                      text/markdown
                    ],
                    message: "must be a PDF, Word, Excel, PowerPoint, text, or markdown file"
                  },
                  size: { less_than: 100.megabytes, message: "must be less than 100MB" }

  # Scopes
  scope :by_type, ->(type) { where(document_type: type) }
  scope :by_status, ->(status) { where(status: status) }
  scope :templates, -> { where(document_type: :template) }
  scope :active, -> { where.not(status: :archived) }
  scope :recent, -> { order(created_at: :desc) }
  scope :search_by_title, ->(query) {
    where("LOWER(title) LIKE :query", query: "%#{query.downcase}%")
  }
  scope :for_documentable, ->(documentable_type, documentable_id) {
    where(documentable_type: documentable_type, documentable_id: documentable_id)
  }
  scope :accessible_by, ->(user) {
    case user.role
    when "admin"
      all
    when "instructor"
      all
    when "student"
      case_ids = user.teams.joins(:case_teams).pluck("case_teams.case_id")
      team_ids = user.team_ids

      where(
        "(documentable_type = 'Case' AND documentable_id IN (?)) OR " \
        "(documentable_type = 'Team' AND documentable_id IN (?)) OR " \
        "created_by_id = ?",
        case_ids, team_ids, user.id
      )
    else
      none
    end
  }

  # Instance methods
  def file_extension
    file.filename.extension if file.attached?
  end

  def file_size
    file.byte_size if file.attached?
  end

  def file_type
    file.content_type if file.attached?
  end

  def template?
    document_type_template?
  end

  def archived?
    status_archived?
  end

  def can_archive?
    status_final?
  end

  def can_finalize?
    status_draft?
  end

  # Status transition methods
  def finalize!
    return false unless can_finalize?
    update(status: :final, finalized_at: Time.current)
  end

  def archive!
    return false unless can_archive?
    update(status: :archived, archived_at: Time.current)
  end

  # Template methods
  def create_from_template(attributes = {})
    return nil unless template?

    new_document = Document.new(
      title: attributes[:title] || "Copy of #{title}",
      document_type: attributes[:document_type] || :assignment,
      status: :draft,
      created_by: attributes[:created_by],
      documentable: attributes[:documentable]
    )

    if new_document.save && file.attached?
      new_document.file.attach(
        io: StringIO.new(file.download),
        filename: file.filename.to_s,
        content_type: file.content_type
      )
    end

    new_document
  end

  private

  def set_default_status
    self.status ||= :draft
  end
end
