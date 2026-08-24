# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaywrightDriverOptions do
  def headless_with(headed)
    if headed.nil?
      ENV.delete("HEADED")
    else
      ENV["HEADED"] = headed
    end
    described_class.call[:headless]
  end

  around do |example|
    original = ENV.fetch("HEADED", nil)
    example.run
  ensure
    original.nil? ? ENV.delete("HEADED") : ENV["HEADED"] = original
  end

  describe "the HEADED flag" do
    it "is headless when HEADED is unset" do
      expect(headless_with(nil)).to be(true)
    end

    it "is headed when HEADED=1" do
      expect(headless_with("1")).to be(false)
    end

    it "is headed when HEADED=true" do
      expect(headless_with("true")).to be(false)
    end

    # The old HEADLESS flag tested presence, so HEADLESS=0 was headless -- the
    # opposite of what it reads like. HEADED must not repeat that.
    it "is headless when HEADED=0" do
      expect(headless_with("0")).to be(true)
    end

    it "is headless when HEADED=false" do
      expect(headless_with("false")).to be(true)
    end

    it "is headless when HEADED is empty" do
      expect(headless_with("")).to be(true)
    end
  end

  it "targets chromium" do
    expect(described_class.call[:browser_type]).to eq(:chromium)
  end
end
