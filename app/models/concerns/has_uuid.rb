module HasUuid
  extend ActiveSupport::Concern

  included do
    before_create :assign_uuid, if: :uses_uuid?
  end

  private

  def assign_uuid
    self.id = SecureRandom.uuid if id.nil?
  end

  def uses_uuid?
    self.class.primary_key == "id" && self.class.columns_hash["id"].type == :uuid
  end
end
