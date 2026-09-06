# frozen_string_literal: true

require "rails_helper"

# Provenance is what makes *doors visible, contents hidden* checkable: every
# discoverable document sits behind some Action, and nothing a Team starts with
# can also be something it finds. The NOT NULL on `case_action_id` used to say
# the first half and could not say the second; a CHECK says both.
#
# The rules are asserted against the database rather than against the model,
# because a CHECK is behaviour: the model's validations say the same thing, and
# an insert path added later cannot forget the constraint.
RSpec.describe "Provenance's invariants" do
  let(:version) { a_case_version }
  let(:action) { version.actions.find_by!(kind: CaseAction::MANAGE_PRESS) }

  def insert_document(provenance:, behind: nil, target: nil, shift: nil)
    ActiveRecord::Base.connection.exec_insert(<<~SQL, nil, [
      INSERT INTO case_documents
        (case_version_id, case_action_id, provenance, identifier, title, body,
         exhibit_target_role, exhibit_shift_fraction, created_at, updated_at)
      VALUES (?, ?, ?, 'the_termination_letter', 'The termination letter', 'Prose.',
              ?, ?, datetime('now'), datetime('now'))
    SQL
      version.id, behind&.id, provenance, target, shift
    ])
  end

  it "accepts a discoverable document waiting behind an Action" do
    expect { insert_document(provenance: "discoverable", behind: action) }.not_to raise_error
  end

  it "accepts a document in both Sides' hands at the open, behind nothing" do
    expect { insert_document(provenance: "both_sides") }.not_to raise_error
  end

  it "accepts a document in one Side's hand at the open" do
    expect { insert_document(provenance: "plaintiff") }.not_to raise_error
  end

  it "refuses a Provenance the Case did not author" do
    expect { insert_document(provenance: "leaked_to_the_press", behind: action) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_provenance_known/)
  end

  # The xor, in both directions. A document that is both something a Team starts
  # with and something it finds is the one thing Provenance exists to refuse.
  it "refuses a discoverable document waiting behind nothing" do
    expect { insert_document(provenance: "discoverable") }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_door_or_hand/)
  end

  it "refuses a document in hand at the open that also waits behind an Action" do
    expect { insert_document(provenance: "plaintiff", behind: action) }
      .to raise_error(ActiveRecord::StatementInvalid, /case_documents_door_or_hand/)
  end

  # Ammunition a Team walks in with is a position the Case authored and Par is
  # authored against it.
  it "accepts a favorable Exhibit in hand at the open" do
    expect { insert_document(provenance: "plaintiff", target: "defendant", shift: 0.2) }
      .not_to raise_error
  end

  # Its shift would land before the first Day is played, spending the Client's
  # bound with no Docket line behind it and no beat to read it in.
  it "refuses an unfavorable Exhibit in hand at the open" do
    expect { insert_document(provenance: "plaintiff", target: "plaintiff", shift: 0.2) }
      .to raise_error(
        ActiveRecord::StatementInvalid,
        /case_documents_open_hand_exhibit_is_favorable/
      )
  end

  # A document in both hands is in the hand of whichever Client it would target,
  # so it is unfavorable to somebody however it is pointed. The same constraint
  # says so without a second clause.
  it "refuses any Exhibit on a document in both Sides' hands" do
    expect { insert_document(provenance: "both_sides", target: "defendant", shift: 0.2) }
      .to raise_error(
        ActiveRecord::StatementInvalid,
        /case_documents_open_hand_exhibit_is_favorable/
      )
  end

  # The discoverable case is untouched: an Exhibit found behind an Action may
  # point either way, and one pointing at its finder is the unfavorable
  # discovery that lands the moment it is found.
  it "leaves a discovered Exhibit free to point at its own finder" do
    expect { insert_document(provenance: "discoverable", behind: action, target: "plaintiff", shift: 0.2) }
      .not_to raise_error
  end
end
