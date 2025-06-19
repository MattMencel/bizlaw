# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin/organizations/new.html.erb", type: :view do
  let(:organization) { Organization.new }

  before do
    assign(:organization, organization)
    render
  end

  it "displays the page title" do
    expect(rendered).to include("New Organization")
  end

  it "includes form fields" do
    expect(rendered).to include("Name")
    expect(rendered).to include("Domain")
    expect(rendered).to include("Slug")
  end

  it "includes submit button" do
    expect(rendered).to include("Create Organization")
  end

  it "includes cancel link" do
    expect(rendered).to include("Cancel")
  end

  it "has proper form action" do
    expect(rendered).to include('action="/admin/organizations"')
  end

  it "uses POST method" do
    expect(rendered).to include('method="post"')
  end
end
