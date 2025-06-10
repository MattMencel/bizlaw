# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'admin/organizations/index.html.erb', type: :view do
  let(:organizations) do
    [
      create(:organization, name: 'Harvard University', active: true),
      create(:organization, name: 'MIT', active: false)
    ]
  end

  before do
    assign(:organizations, Kaminari.paginate_array(organizations).page(1).per(20))
    allow(view).to receive(:policy).and_return(double(new?: true, create?: true))
    render
  end

  it 'displays the page title' do
    expect(rendered).to include('Organization Management')
  end

  it 'displays organization names' do
    organizations.each do |org|
      expect(rendered).to include(org.name)
    end
  end

  it 'displays organization status' do
    expect(rendered).to include('Active')
    expect(rendered).to include('Inactive')
  end

  it 'includes search form' do
    expect(rendered).to include('search')
    expect(rendered).to include('Search organizations')
  end

  it 'includes status filter options' do
    expect(rendered).to include('All Organizations')
    expect(rendered).to include('Active Only')
    expect(rendered).to include('Inactive Only')
  end

  it 'includes new organization link' do
    expect(rendered).to include('Add New Organization')
  end

  it 'includes action links for each organization' do
    organizations.each do |org|
      expect(rendered).to include("View")
      expect(rendered).to include("Edit")
    end
  end
end
