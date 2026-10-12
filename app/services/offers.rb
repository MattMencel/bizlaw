# frozen_string_literal: true

# Everything a Team does with an Offer before it lands, and the Instructor's
# release of the gate it lands through.
#
# These sit beside `Days::Command` rather than inside it, for the reason
# `Days::Commit` does: `Command`'s two verbs exist to confirm a spend — a cost,
# a half, what is left today and the Day the result lands — and staging has none
# of them. Staging, revising and discarding cost nothing and write no Docket
# row. Committing an Offer *is* a spend and belongs in `Command` when it is
# built.
module Offers
end
