# frozen_string_literal: true

# The Offer lands, and the exchange half pays for it.
#
# Three things arrive together. The **Exhibit's price** joins the exchange pool
# on the authored Case, because the two are one decision rather than two: at a
# pool of two an Exhibit priced at two means nothing can ever be played. The
# committed Offer gets **its Terms**, so it carries the shape of the deal rather
# than a collapsed number — each Client values the Terms privately and the two
# figures the Offer is worth are read back off these rows. And the other Side
# gets somewhere to **accept** from.
#
# `docket_entries.case_action_id` becomes nullable here. An Offer commit is a
# spend and takes the same ledger row every other spend takes, but it is not an
# Action off the menu: it is a Boardroom act, gated by a Second, and giving it a
# `case_actions` row would put it on the Action Board where anything that can
# quote a kind could buy it past the gate.
class CommitTheOffer < ActiveRecord::Migration[8.0]
  # What an Offer costs to commit, written into the CHECK below. It is engine
  # rather than authored — `CommittedOffer::EXCHANGE_COST` — because the whole
  # arithmetic of the exchange half is one Offer plus the Exhibits riding it,
  # and a Case that priced the Offer itself would be authoring that away.
  OFFER_COST = 1

  # Named rather than left to Rails, which hashes a name this long into
  # something a later migration cannot recognise — and this one is added to a
  # table an earlier migration created, so `down` has to remove it by hand.
  COMMITTED_OFFER_TENANCY_INDEX = "index_committed_offers_on_id_simulation_and_organization"

  def up
    # The Exhibit's price, authored beside the pool it is spent out of. An
    # Exhibit rides a committed Offer, so the pool has to hold both: the pool is
    # already CHECKed at two, and this is the other half of that same rule.
    add_column :case_versions, :exhibit_price, :integer, null: false
    add_check_constraint :case_versions, "exhibit_price >= 1",
      name: "case_versions_exhibit_price_is_a_spend"
    # A ceiling that refuses gets a constraint, per ADR 0002, and this one
    # refuses: an Exhibit that cannot ride an Offer is an Exhibit nothing can
    # ever play, and separation across the joint grid falls from 84 to 10.
    add_check_constraint :case_versions, "#{OFFER_COST} + exhibit_price <= exchange_pool",
      name: "case_versions_exhibit_rides_an_offer"

    relax_the_docket_entry_action

    # The shape of the deal as it landed, copied out of the staged Offer inside
    # the commit's own transaction. It mirrors `staged_offer_terms` down to the
    # composite key, and for the same reasons — see that table.
    #
    # An Offer is worth two numbers, one per Client, because each Client values
    # the Terms privately. That is why the committed Offer carries its Terms
    # rather than a single collapsed figure: these rows are what the two
    # valuations are later read from.
    create_table :committed_offer_terms do |t|
      t.bigint :case_version_id, null: false
      t.bigint :committed_offer_id, null: false
      t.bigint :case_term_id, null: false
      t.integer :amount_cents

      t.timestamps

      t.check_constraint "amount_cents IS NULL OR amount_cents >= 0",
        name: "committed_offer_terms_amount_is_money"
    end
    add_index :committed_offer_terms, [:committed_offer_id, :case_term_id], unique: true
    add_index :committed_offer_terms, :case_term_id
    # The target of the composite key from `offer_acceptances`. Tenancy for a
    # run's own tables is the Simulation as well as the Organization, so the
    # Acceptance cannot point at an Offer committed in another run.
    add_index :committed_offers, [:id, :simulation_id, :organization_id],
      unique: true, name: COMMITTED_OFFER_TENANCY_INDEX
    add_foreign_key :committed_offer_terms, :committed_offers,
      column: [:committed_offer_id, :case_version_id], primary_key: [:id, :case_version_id]
    add_foreign_key :committed_offer_terms, :case_terms,
      column: [:case_term_id, :case_version_id], primary_key: [:id, :case_version_id]

    # The other Side taking the deal. It is gated by a Second exactly as the
    # commit is — an Offer and an Acceptance are the only two acts inside a Team
    # that need one — so it carries the same CHECK, and `seconded_by_user_id` is
    # null only on an Acceptance that landed under an Instructor's waiver.
    #
    # It costs nothing: the exchange half buys an Offer and the Exhibits riding
    # it and nothing else, so this writes no Docket spend row. `day_id` is the
    # Day it was accepted on, which need not be the Day the Offer was committed
    # on.
    create_table :offer_acceptances do |t|
      t.bigint :organization_id, null: false
      t.bigint :simulation_id, null: false
      t.bigint :side_id, null: false
      t.bigint :day_id, null: false
      t.bigint :committed_offer_id, null: false
      t.bigint :accepted_by_user_id, null: false
      t.bigint :seconded_by_user_id

      t.timestamps

      t.check_constraint "seconded_by_user_id != accepted_by_user_id",
        name: "offer_acceptances_second_is_another_member"
    end
    # An Offer is accepted once. A second press by a teammate is the ordinary
    # case, and this is what makes it harmless rather than a second deal.
    add_index :offer_acceptances, :committed_offer_id, unique: true
    add_index :offer_acceptances, [:side_id, :day_id]
    add_index :offer_acceptances, :day_id
    add_foreign_key :offer_acceptances, :sides,
      column: [:side_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :offer_acceptances, :days,
      column: [:day_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :offer_acceptances, :committed_offers,
      column: [:committed_offer_id, :simulation_id, :organization_id],
      primary_key: [:id, :simulation_id, :organization_id]
    add_foreign_key :offer_acceptances, :users,
      column: [:accepted_by_user_id, :organization_id], primary_key: [:id, :organization_id]
    add_foreign_key :offer_acceptances, :users,
      column: [:seconded_by_user_id, :organization_id], primary_key: [:id, :organization_id]

    # The mirror of the guards the Docket, the commitment ledger and the staged
    # Offer already carry. The commit reaches the database through
    # `docket_entries` first and is refused there, so this is the rule where an
    # insert path added later cannot get past it.
    execute <<~SQL
      CREATE TRIGGER committed_offers_need_an_unclosed_day
      BEFORE INSERT ON committed_offers
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'committed_offers_need_an_unclosed_day');
      END;
    SQL

    # An Acceptance on a Day that has ended would be a deal struck after the
    # Day it is recorded against was taken from the Team.
    execute <<~SQL
      CREATE TRIGGER offer_acceptances_need_an_unclosed_day
      BEFORE INSERT ON offer_acceptances
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'offer_acceptances_need_an_unclosed_day');
      END;
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS offer_acceptances_need_an_unclosed_day"
    execute "DROP TRIGGER IF EXISTS committed_offers_need_an_unclosed_day"
    drop_table :offer_acceptances
    drop_table :committed_offer_terms
    # `committed_offers` is an earlier migration's table, so this migration owns
    # only the index it added to it.
    remove_index :committed_offers, name: COMMITTED_OFFER_TENANCY_INDEX
    restore_the_docket_entry_action
    remove_check_constraint :case_versions, name: "case_versions_exhibit_rides_an_offer"
    remove_check_constraint :case_versions, name: "case_versions_exhibit_price_is_a_spend"
    remove_column :case_versions, :exhibit_price
  end

  private

  # SQLite has no `ALTER COLUMN`, so both statements below rebuild the table —
  # and a rebuilt table takes its triggers with it. They are dropped and written
  # back around the change rather than left to survive it.
  def relax_the_docket_entry_action
    drop_docket_entry_triggers
    change_column_null :docket_entries, :case_action_id, true
    # The nullable column is not an invitation. Every spend off the Action menu
    # still names its Action; the one act that names none is the Offer commit,
    # which draws on the exchange half — the half that buys an Offer and the
    # Exhibits riding it and nothing else.
    add_check_constraint :docket_entries, "case_action_id IS NOT NULL OR half = 'exchange'",
      name: "docket_entries_action_or_the_exchange_half"
    write_docket_entry_triggers
  end

  def restore_the_docket_entry_action
    drop_docket_entry_triggers
    remove_check_constraint :docket_entries, name: "docket_entries_action_or_the_exchange_half"
    change_column_null :docket_entries, :case_action_id, false
    write_docket_entry_triggers
  end

  def drop_docket_entry_triggers
    %w[
      docket_entries_need_an_opened_day
      docket_entries_need_an_unclosed_day
      docket_entries_refold_day_budget_spent
    ].each { |trigger| execute "DROP TRIGGER IF EXISTS #{trigger}" }
  end

  # Written back exactly as `CreateDocketAndActionMenu` and `CreateDayCommitments`
  # first wrote them. A rewrite that drifted from those would be a second
  # definition of the same rule.
  def write_docket_entry_triggers
    execute <<~SQL
      CREATE TRIGGER docket_entries_need_an_opened_day
      BEFORE INSERT ON docket_entries
      WHEN NOT EXISTS (
        SELECT 1 FROM day_budgets
        WHERE side_id = NEW.side_id AND day_id = NEW.day_id
      )
      BEGIN
        SELECT RAISE(ABORT, 'docket_entries_need_an_opened_day');
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER docket_entries_need_an_unclosed_day
      BEFORE INSERT ON docket_entries
      WHEN EXISTS (
        SELECT 1 FROM days WHERE id = NEW.day_id AND closed_at IS NOT NULL
      )
      BEGIN
        SELECT RAISE(ABORT, 'docket_entries_need_an_unclosed_day');
      END;
    SQL

    execute <<~SQL
      CREATE TRIGGER docket_entries_refold_day_budget_spent
      AFTER INSERT ON docket_entries
      BEGIN
        UPDATE day_budgets
        SET preparation_spent = (
              SELECT COALESCE(SUM(cost), 0) FROM docket_entries
              WHERE side_id = NEW.side_id AND day_id = NEW.day_id
                AND half = 'preparation'),
            exchange_spent = (
              SELECT COALESCE(SUM(cost), 0) FROM docket_entries
              WHERE side_id = NEW.side_id AND day_id = NEW.day_id
                AND half = 'exchange')
        WHERE side_id = NEW.side_id AND day_id = NEW.day_id;
      END;
    SQL
  end
end
