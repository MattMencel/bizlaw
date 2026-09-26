# frozen_string_literal: true

# The register's own typesetting: the marks every surface in the game makes the
# same way, in one place.
#
# A read answers in domain objects — a `Day`, a `User`, a Term's key, an amount
# in cents, a symbol the engine names a rule by — and a page cannot render one.
# Each page composer is where that conversion happens, and #367 made there be
# two of them: the front of a live Day (`WorkingDraft`) and the front of a
# settled run (`ExecutedFile`). They print different instruments and they print
# them in the same hand.
#
# So this is not a base class and not a split for size. It holds the decisions
# that are *the register's* rather than either page's — how a figure is
# formatted, what a Docket line reads as, what a document is on the page — and
# the reason to hold them once is that two copies are two decisions. The
# currency is the clearest case: `WorkingDraft` has always said there is one
# currency decision, and a second composer formatting money its own way would
# make that sentence false without either file changing.
#
# What stays with a page is what only that page knows: its own layout, its own
# refusals, and which of these marks it makes at all.
#
# It is also where copy leaves Ruby. A page carries no words of its own, so a
# surface's fixed labels go over as a subtree (`copy`) and every sentence that
# carries a value is composed here or in the composer, with interpolation.
module Typeset
  # The one size a Client's face is served at, of the three the part set has
  # been looked at in. A passport photograph clipped to a file is the register's
  # idiom for a face on a legal document, and it is the size #325 checked the
  # stock set survives the halftone at.
  #
  # It is shared rather than chosen per surface because the Client speaks on
  # exactly two occasions — a Consult and the settlement — and reading them as
  # the same person is the whole point of the part set. A halftone screen is
  # fixed in ink on the page, so two sizes would be two faces.
  PORTRAIT_SIZE = 78

  private

  # A surface's fixed labels, as the subtree its page reads. The templates that
  # carry a value stay behind: a page handed `Day %{day}` would print it.
  def copy(scope) = fixed(I18n.t(scope))

  def fixed(tree)
    case tree
    when Hash then tree.reject { |_key, value| value.is_a?(String) && value.include?("%{") }
      .transform_values { |value| fixed(value) }
    else tree
    end
  end

  # Every date in the fiction reads the same way, on every surface.
  def in_fiction(date) = I18n.l(date, format: :in_fiction)

  def role_label(role) = I18n.t("reads.roles.#{role}")

  def day_label(ordinal) = I18n.t("reads.day", day: ordinal)

  def day_of(ordinal, count) = I18n.t("reads.day_of", day: ordinal, of: count)

  def price(cost, half) = I18n.t("reads.price", cost: cost, half: half_label(half))

  # Whole dollars where the amount is whole, which every authored figure so far
  # is. One currency decision for the whole register, and nothing on any page
  # has an amount to compute.
  def money(cents)
    ActiveSupport::NumberHelper.number_to_currency(
      cents / 100.0, precision: (cents % 100).zero? ? 0 : 2
    )
  end

  # What a Term reads as is authored beside its key, so the engine never makes
  # one up. `fetch` rather than a fallback: a key with no label is a Term this
  # Case never authored, and printing the key instead would put an identifier in
  # front of a student.
  def label_for(key) = term_labels.fetch(key)

  def term_labels = @term_labels ||= side.case_version.terms.pluck(:key, :label).to_h

  # One paper, wherever it is printed: the front matter's arrivals, the Case
  # File on the back, and the Exhibit rail all read the same row.
  def document(entry)
    {
      identifier: entry.identifier,
      title: entry.title,
      body: entry.body,
      day: entry.day.ordinal,
      day_label: day_label(entry.day.ordinal),
      # A symbol survives to the page as a string, so it is made one here: what
      # a spec asserts on and what the page reads have to be the same value.
      arrival: entry.arrival.to_s,
      served: entry.served?,
      playable: entry.playable,
      spent: entry.spent,
      at_the_open: entry.at_the_open?
    }
  end

  def docket_line(entry)
    {
      at: entry.at.iso8601,
      act: entry.act.to_s,
      act_label: act_label(entry),
      by: entry.by&.name,
      day: entry.day&.ordinal,
      kind: entry.kind,
      cost: entry.cost,
      half: entry.half,
      half_label: entry.half && half_label(entry.half),
      band: entry.band && band_label(entry.band),
      reads_as: entry.band && I18n.t("reads.back_of_file.band", band: band_label(entry.band)),
      lands_on_day: entry.lands_on_day&.ordinal,
      day_label: day_label(entry.day&.ordinal || "—"),
      price: docket_price(entry),
      spend: entry.spend?,
      instructor_action: entry.instructor_action?
    }
  end

  # A spend is named by the Action it bought; the three acts with no cost are
  # named by the act, because there is no Action behind them to name.
  #
  # And so is the fourth, which *does* have a cost: executing a draft is a spend
  # with no authored Action behind it, so there is no kind to name it by —
  # `docket_entries.case_action_id` is nullable and CHECKed to the exchange half
  # for precisely that. Asking `kind_label(nil)` instead hands I18n a key with
  # nothing after the dot, which resolves to the whole kinds Hash and prints as
  # `[object Object]` on the one line a Team most wants to read back.
  def act_label(entry)
    return I18n.t("reads.docket.acts.offer_committed") if entry.commit?

    entry.spend? ? kind_label(entry.kind) : I18n.t("reads.docket.acts.#{entry.act}")
  end

  def docket_price(entry)
    return I18n.t("reads.back_of_file.no_cost") unless entry.spend?

    I18n.t("reads.back_of_file.lands",
      count: entry.cost, half: half_label(entry.half), day: entry.lands_on_day&.ordinal)
  end

  # What we know, and what we have done — under one heading, because the back of
  # the instrument is one surface. It is the same back on both faces of the
  # game: settling does not unknow anything, and the Docket already folds the
  # Acceptance in as one of the acts with no cost.
  def back_of_file(case_file, docket)
    {
      copy: copy("reads.back_of_file"),
      case_file: {
        empty_state: case_file.empty_state,
        documents: case_file.entries.map { |entry| document(entry) }
      },
      docket: {
        empty_state: docket.empty_state,
        entries: docket.entries.map { |entry| docket_line(entry) }
      }
    }
  end

  # The band is a symbol the engine names a rule by, like a refusal and an
  # Action's kind, so it becomes text here and not on a page. One key serves the
  # Consult memo and the Docket line both — see `reads.en.yml` for why.
  def band_label(band) = I18n.t("reads.bands.#{band}")

  def kind_label(kind) = I18n.t("reads.action_board.kinds.#{kind}")

  def half_label(half) = I18n.t("reads.action_board.halves.#{half}")

  # The face, composed rather than fetched from an endpoint of its own: the two
  # inks resolve through custom properties on an ancestor, and an SVG behind an
  # `<img>` cannot see the page it sits on — so the portrait would stop
  # following the paper, which is the whole of what ADR 0008 decided about ink.
  #
  # ADR 0008 binds the **read**: a `Beat` hands on a seed and an expression and
  # never a rendered portrait, because a halftone screen is fixed in ink and a
  # read has no business choosing a size. This layer is where a size exists.
  def portrait(beat)
    Portraits::Compose.call(
      seed: beat.portrait_seed, expression: beat.expression, size: PORTRAIT_SIZE
    )
  end
end
