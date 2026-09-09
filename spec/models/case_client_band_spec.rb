# frozen_string_literal: true

require "rails_helper"

# Which variant a Consult hears. `CONTEXT.md` under *Dialogue Node*: chosen by
# the Simulation seed **and** how many times the node has already been spoken.
# The count walks the variants in authored order; the seed decides which of them
# the run opens on, so two Teams on one Case do not hear their Client in one
# fixed order.
RSpec.describe CaseClientBand do
  let(:band) { a_case_version.clients.find_by(role: Side::PLAINTIFF).band_named(described_class::FIRM) }
  let(:variants) { band.lines.map(&:body) }

  it "walks the authored variants in order from wherever the seed opens" do
    spoken = Array.new(variants.size * 2) { |count| band.line(count, seed: "a-run") }

    expect(spoken.first(variants.size)).to match_array(variants)
    expect(spoken.last(variants.size)).to eq(spoken.first(variants.size))
  end

  # The whole of #334. A fixed set of seeds rather than a fixed number of runs,
  # so this is a property of the mix and not a coin flip: if every seed opened on
  # the same variant, one line of the two would be unreachable on a first
  # Consult and every Team on the Case would hear the Client identically.
  it "opens different runs on different variants" do
    opened = Array.new(50) { |run| band.line(0, seed: "run-#{run}") }

    expect(opened.uniq).to match_array(variants)
  end

  # The salt carries the node and not only the run, so a Client's two bands do
  # not step in lockstep — which is the fixed-order complaint at a smaller
  # scale. Two variants each make four possible openings; bands moving together
  # would only ever produce two of them.
  it "opens each band of a run on its own variant" do
    ready = band.case_client.band_named(described_class::READY)
    ready_variants = ready.lines.map(&:body)

    openings = (0..49).map { |run|
      seed = "run-#{run}"
      [variants.index(band.line(0, seed: seed)), ready_variants.index(ready.line(0, seed: seed))]
    }

    expect(openings.uniq.size).to be > 2
  end
end
