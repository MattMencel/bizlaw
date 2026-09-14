# frozen_string_literal: true

# A Team commits at most one Offer a Day, so a Day whose Offer is executed takes
# no new draft either — `CONTEXT.md` under *Offer*. `Offers::Stage` refuses it in
# Ruby, which is where the sentence a student reads comes from; this is the half
# that holds under a race, and ADR 0002's rule is that an invariant lives in the
# database wherever it fits in one.
#
# It fits in one here for the same reason the unclosed-Day rule it mirrors does.
# The Ruby check reads `committed_offers` **before** the transaction that
# replaces the draft, so a commit landing in between passes it: the executed
# Offer holds the old terms, the draft is rewritten with new ones, and
# `TermsBoard#ours` prefers the draft — leaving the executed instrument printing
# terms over two countersignatures that never signed them. A re-read inside the
# transaction would close it on SQLite, whose writes serialise, and quietly stop
# closing it on the Postgres ADR 0001 defers rather than rejects.
#
# Three triggers, the same three shapes `..._an_unclosed_day` already uses,
# because a reader comparing the two rules should find one shape rather than two:
#
#   · a fresh draft inserts `staged_offers`
#   · a revision touches no `staged_offers` row an INSERT trigger would see, so
#     the Terms carry the rule too — and `Offers::Stage` replaces the Terms
#     rather than amending them, which is an INSERT
#   · nothing updates a Term row in place today, and the UPDATE guard is what
#     keeps that true of whatever writes one next
#
# The Exhibits need none of their own: an Offer names at least one Term, so a
# Term row is inserted in the same transaction as any Exhibit riding it and the
# abort takes the whole thing down.
class ADraftNeedsAnUnexecutedDay < ActiveRecord::Migration[8.0]
  COMMITTED = <<~SQL
    SELECT 1 FROM committed_offers
    WHERE committed_offers.side_id = %<side>s
      AND committed_offers.day_id = %<day>s
  SQL

  # Reached through the draft the Term hangs off, which is what carries the Side
  # and the Day. `staged_offer_terms` carries neither.
  UNDER_THE_DRAFT = <<~SQL
    SELECT 1 FROM staged_offers
    JOIN committed_offers
      ON committed_offers.side_id = staged_offers.side_id
     AND committed_offers.day_id = staged_offers.day_id
    WHERE staged_offers.id = NEW.staged_offer_id
  SQL

  def up
    execute(<<~SQL)
      CREATE TRIGGER staged_offers_need_an_unexecuted_day
      BEFORE INSERT ON staged_offers
      WHEN EXISTS (
        #{format(COMMITTED, side: "NEW.side_id", day: "NEW.day_id")}
      )
      BEGIN
        SELECT RAISE(ABORT, 'staged_offers_need_an_unexecuted_day');
      END;
    SQL

    execute(<<~SQL)
      CREATE TRIGGER staged_offer_terms_need_an_unexecuted_day
      BEFORE INSERT ON staged_offer_terms
      WHEN EXISTS (
        #{UNDER_THE_DRAFT}
      )
      BEGIN
        SELECT RAISE(ABORT, 'staged_offer_terms_need_an_unexecuted_day');
      END;
    SQL

    execute(<<~SQL)
      CREATE TRIGGER staged_offer_terms_stay_on_an_unexecuted_day
      BEFORE UPDATE ON staged_offer_terms
      WHEN EXISTS (
        #{UNDER_THE_DRAFT}
      )
      BEGIN
        SELECT RAISE(ABORT, 'staged_offer_terms_stay_on_an_unexecuted_day');
      END;
    SQL
  end

  def down
    %w[
      staged_offers_need_an_unexecuted_day
      staged_offer_terms_need_an_unexecuted_day
      staged_offer_terms_stay_on_an_unexecuted_day
    ].each { |trigger| execute "DROP TRIGGER IF EXISTS #{trigger};" }
  end
end
