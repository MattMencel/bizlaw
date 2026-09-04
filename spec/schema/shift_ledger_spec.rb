# frozen_string_literal: true

require "rails_helper"

# A CHECK constraint and a unique index are behaviour, so they are written
# against directly. These specs insert underneath the model on purpose: the
# model is where the clip is computed, and the constraint is what holds when
# something skips it.
RSpec.describe "the shift ledger's invariants" do
  let(:simulation) { a_simulation }
  let(:side) { simulation.plaintiff_side }
  let(:day) { simulation.days.first }

  def insert_shift(requested:, applied:, source_ref: 1)
    ActiveRecord::Base.connection.exec_insert(<<~SQL, nil, [
      INSERT INTO client_shifts
        (organization_id, simulation_id, side_id, day_id, source_kind, source_ref,
         requested_fraction, applied_fraction, created_at, updated_at)
      VALUES (?, ?, ?, ?, 'unfavorable_discovery', ?, ?, ?, datetime('now'), datetime('now'))
    SQL
      side.organization_id, side.simulation_id, side.id, day.id, source_ref, requested, applied
    ])
  end

  # The clip is computed rather than constrained, because the bound saturates.
  # This is what makes a forgotten clip loud instead of silent.
  it "refuses an applied fraction larger than the one requested" do
    expect { insert_shift(requested: 0.2, applied: 0.5) }
      .to raise_error(ActiveRecord::StatementInvalid, /client_shifts_applied_within_requested/)
  end

  it "allows an applied fraction clipped below the one requested" do
    expect { insert_shift(requested: 0.5, applied: 0.2) }.not_to raise_error
  end

  # Written over `abs` so that an Event's outward shift — the ratchet's sole
  # exemption — lands under the same rule.
  it "measures the clip by size rather than by sign" do
    expect { insert_shift(requested: -0.5, applied: -0.2) }.not_to raise_error
    expect { insert_shift(requested: -0.2, applied: -0.5, source_ref: 2) }
      .to raise_error(ActiveRecord::StatementInvalid, /client_shifts_applied_within_requested/)
  end

  # A shift is a fraction of the bound and no larger than the whole of it. Its
  # direction is deliberately unconstrained here, because an Event's outward
  # shift shares this table.
  it "refuses a shift that is no fraction of the bound at all" do
    expect { insert_shift(requested: 0, applied: 0) }
      .to raise_error(ActiveRecord::StatementInvalid, /requested_is_a_fraction_of_the_bound/)
  end

  it "refuses a shift larger than the whole of the bound" do
    expect { insert_shift(requested: 2, applied: 2) }
      .to raise_error(ActiveRecord::StatementInvalid, /requested_is_a_fraction_of_the_bound/)
  end

  it "refuses a second shift from the same source against the same Client" do
    insert_shift(requested: 0.2, applied: 0.2)

    expect { insert_shift(requested: 0.2, applied: 0.2) }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "lets one source move each Side's own Client once" do
    insert_shift(requested: 0.2, applied: 0.2)

    other = simulation.defendant_side
    expect {
      ActiveRecord::Base.connection.exec_insert(<<~SQL, nil, [
        INSERT INTO client_shifts
          (organization_id, simulation_id, side_id, day_id, source_kind, source_ref,
           requested_fraction, applied_fraction, created_at, updated_at)
        VALUES (?, ?, ?, ?, 'unfavorable_discovery', 1, 0.2, 0.2,
                datetime('now'), datetime('now'))
      SQL
        other.organization_id, other.simulation_id, other.id, day.id
      ])
    }.not_to raise_error
  end

  it "refuses a shift against a Side of another Simulation's Day" do
    theirs = a_simulation(section: simulation.section, case_version: simulation.case_version)

    expect {
      ClientShift.create!(
        side: side, day: theirs.days.first,
        source_kind: ClientShift::UNFAVORABLE_DISCOVERY, source_ref: 1,
        requested_fraction: 0.2
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end

# The Exhibit is a property some documents carry and most do not, so the schema
# says it is whole or absent — and that a document's shift is inward, because
# player-caused movement is a ratchet.
RSpec.describe "the authored Exhibit property's invariants" do
  let(:version) { a_case_version }
  let(:action) { version.actions.find_by!(kind: CaseAction::MANAGE_PRESS) }

  def insert_document(target:, shift:)
    ActiveRecord::Base.connection.exec_insert(<<~SQL, nil, [
      INSERT INTO case_documents
        (case_version_id, case_action_id, identifier, title, body,
         exhibit_target_role, exhibit_shift_fraction, created_at, updated_at)
      VALUES (?, ?, 'a_leaked_memorandum', 'A leaked memorandum', 'Prose.',
              ?, ?, datetime('now'), datetime('now'))
    SQL
      version.id, action.id, target, shift
    ])
  end

  it "refuses a target with no shift behind it" do
    expect { insert_document(target: "plaintiff", shift: nil) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_exhibit_is_whole_or_absent/)
  end

  it "refuses a shift with no target to point at" do
    expect { insert_document(target: nil, shift: 0.25) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_exhibit_is_whole_or_absent/)
  end

  it "accepts a document carrying neither" do
    expect { insert_document(target: nil, shift: nil) }.not_to raise_error
  end

  it "refuses a shift reaching back outward, because an Exhibit is a ratchet" do
    expect { insert_document(target: "plaintiff", shift: -0.25) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_exhibit_shift_is_inward/)
  end

  it "refuses a shift larger than the whole of the target's bound" do
    expect { insert_document(target: "plaintiff", shift: 1.5) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_exhibit_shift_is_inward/)
  end

  it "refuses an Exhibit pointing at somebody who is not a Client" do
    expect { insert_document(target: "the_judge", shift: 0.25) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_exhibit_target_known/)
  end

  it "refuses a document waiting behind an Action of another Case Version" do
    other = a_case_version(version: "2.0.0")

    expect {
      CaseDocument.create!(
        case_version: version,
        case_action: other.actions.find_by!(kind: CaseAction::MANAGE_PRESS),
        identifier: "a_borrowed_document", title: "A borrowed document", body: "Prose."
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end
end

# A Case File holds documents of the Case its Simulation is playing. The two
# composite keys meet in the middle over `case_version_id`: it must be the
# Version the document belongs to and the Version the Simulation pinned.
RSpec.describe "the Case File's pinning" do
  let(:simulation) { a_simulation }

  it "refuses a document authored for a Case Version this run never pinned" do
    elsewhere = a_case_version(version: "2.0.0")

    expect {
      CaseFileDocument.create!(
        side: simulation.plaintiff_side,
        day: simulation.days.first,
        case_document: elsewhere.documents.find_by!(identifier: "personnel_file")
      )
    }.to raise_error(ActiveRecord::InvalidForeignKey)
  end

  it "accepts a document of the Version the Simulation pinned" do
    filed = CaseFileDocument.create!(
      side: simulation.plaintiff_side,
      day: simulation.days.first,
      case_document: simulation.case_version.documents.find_by!(identifier: "personnel_file")
    )

    expect(filed.case_version_id).to eq(simulation.case_version_id)
  end
end
