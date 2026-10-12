# frozen_string_literal: true

# Raised by every act seam when it turns an act down, carrying the rule it was
# turned down by as the symbol a surface renders from `reads.refusals`.
#
# Each seam's `refusal_for` answers from the same list without writing, so the
# control and the write are one rule. One class rather than one per rule or per
# seam, because a caller only ever needs the reason: a controller carries it to
# the page, and the page makes it a sentence.
#
# A caller fault — a Term the Case never authored, an Exhibit the Team cannot
# play, accepting your own Offer — is not a refusal. It stays an `ArgumentError`.
class Refused < StandardError
  attr_reader :reason

  def initialize(reason)
    @reason = reason
    super(reason.to_s)
  end
end
