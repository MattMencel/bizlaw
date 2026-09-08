# frozen_string_literal: true

# One variant of what a Client says in one band — a Dialogue Node's stored
# wording, and the unit generation writes against. A node is **atomic**: one
# whole utterance rather than slots assembled at runtime, so the bytes a
# professor reviews are the bytes a student reads.
#
# It is authored data whichever way the author produced it. The engine's own
# reference Case writes them by hand; a real Case generates them offline
# against the Client's persona, and never at import and never at runtime.
class CaseClientBandLine < ApplicationRecord
  retention :authored

  belongs_to :band, class_name: "CaseClientBand", foreign_key: :case_client_band_id,
    inverse_of: :lines

  before_validation { self.case_version_id ||= band&.case_version_id }

  validates :body, presence: true
end
