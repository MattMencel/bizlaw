RSpec.shared_examples "has_timestamps" do
  it "has created_at and updated_at columns" do
    expect(described_class.column_names).to include("created_at", "updated_at")
  end
end
