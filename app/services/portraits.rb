# frozen_string_literal: true

# The Client's face: a part set, a seed and a compositor, printed in two inks.
#
# A Case authors an opaque `portrait_seed` and nothing else. The seed draws the
# **identity** groups once and they never move again — skull, hair, garment,
# glasses and facial hair — and the engine picks the **expression** groups,
# which are the brows and the mouth and nothing else. See ADR 0008.
#
# Composition is string concatenation over committed SVG. There is no Node at
# build time, none at import and none at runtime; `rake portraits:derive` is a
# design-time tool whose output is what ships.
module Portraits
  # Raised when a Case authors a seed for a face the set cannot draw, or a
  # caller asks for a size the set has never been looked at in.
  Unrenderable = Class.new(StandardError)

  # The one expression that is not a band: authored to the occasion and
  # invariant, because there is no band to derive from once the instrument is
  # executed (ADR 0007).
  SETTLEMENT = "settlement"

  # The three occasions a face is picked for, and the whole inventory a part set
  # must be able to draw. The first two are the Reaction Bands, named where a
  # band is named — the expression at a Consult *is* the band, by engine rule,
  # so a Client's face cannot change between two variants that mean the same
  # thing. The compositor borrows the vocabulary rather than owning it.
  EXPRESSIONS = [CaseClientBand::FIRM, CaseClientBand::READY, SETTLEMENT].freeze

  # Where the default set lives. A commissioned set is proprietary, ships with
  # the Cases rather than with the engine, and is pointed at from here — the
  # same split the repo already draws between the engine and its content.
  def self.part_set_root
    Pathname(ENV.fetch("PORTRAIT_PART_SET", Rails.root.join("portraits/default").to_s))
  end
end
