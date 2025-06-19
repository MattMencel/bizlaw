# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin/organizations/edit.html.erb", type: :view do
  let(:organization) { create(:organization, name: "Test University", domain: "test.edu") }

  before do
    assign(:organization, organization)
    render
  end

  it "displays the page title" do
    expect(rendered).to include("Edit Organization")
    expect(rendered).to include(organization.name)
  end

  it "includes form fields with current values" do
    expect(rendered).to include("Name")
    expect(rendered).to include("Domain")
    expect(rendered).to include("Slug")
    expect(rendered).to include(organization.name)
    expect(rendered).to include(organization.domain)
  end

  it "includes submit button" do
    expect(rendered).to include("Update Organization")
  end

  it "includes cancel link" do
    expect(rendered).to include("Cancel")
  end

  it "has proper form action" do
    expect(rendered).to include("action=\"/admin/organizations/#{organization.id}\"")
  end

  it "uses PATCH method" do
    expect(rendered).to include('name="_method"')
    expect(rendered).to include('value="patch"')
  end
end
