# frozen_string_literal: true

# `expect { act }.to raise_refusal(:the_day_has_closed)` — the act was turned
# down, and by that rule. Every seam raises the one `Refused`, so the class says
# only that it was refused; the reason is what a spec is about.
RSpec::Matchers.define :raise_refusal do |expected|
  supports_block_expectations

  match do |act|
    act.call
    false
  rescue Refused => e
    @raised = e.reason
    @raised == expected
  end

  failure_message do
    actual = @raised ? "it was refused with #{@raised.inspect}" : "it was not refused"
    "expected the act to be refused with #{expected.inspect}, but #{actual}"
  end
end
