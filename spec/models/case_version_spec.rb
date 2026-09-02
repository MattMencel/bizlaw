# frozen_string_literal: true

require "rails_helper"

RSpec.describe CaseVersion do
  it "is a draft until published, derived from published_at" do
    version = a_case_version(published: false)

    expect(version).to be_draft
    expect(version).not_to be_published

    version.update!(published_at: Time.current)

    expect(version).to be_published
    expect(version).not_to be_draft
  end

  it "takes its Day count from the length of the authored calendar" do
    expect(a_case_version(days: 8).day_count).to eq(8)
  end

  it "reads its calendar in ordinal order" do
    version = a_case_version(days: 4)

    expect(version.calendar_days.map(&:ordinal)).to eq([1, 2, 3, 4])
  end
end
