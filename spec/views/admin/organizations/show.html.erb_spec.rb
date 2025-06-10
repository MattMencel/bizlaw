# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'admin/organizations/show.html.erb', type: :view do
  let(:organization) { create(:organization, name: 'Test University', domain: 'test.edu') }
  let(:recent_users) { create_list(:user, 3, organization: organization) }
  let(:recent_courses) { create_list(:course, 2, organization: organization) }

  before do
    assign(:organization, organization)
    assign(:users_count, 10)
    assign(:courses_count, 5)
    assign(:recent_users, recent_users)
    assign(:recent_courses, recent_courses)
    allow(view).to receive(:policy).and_return(double(edit?: true, destroy?: true, activate?: true, deactivate?: true))
    render
  end

  it 'displays organization name' do
    expect(rendered).to include(organization.name)
  end

  it 'displays organization domain' do
    expect(rendered).to include(organization.domain)
  end

  it 'displays organization status' do
    if organization.active?
      expect(rendered).to include('Active')
    else
      expect(rendered).to include('Inactive')
    end
  end

  it 'displays user count' do
    expect(rendered).to include('10')
    expect(rendered).to include('Users')
  end

  it 'displays course count' do
    expect(rendered).to include('5')
    expect(rendered).to include('Courses')
  end

  it 'displays recent users' do
    recent_users.each do |user|
      expect(rendered).to include(user.email)
    end
  end

  it 'displays recent courses' do
    recent_courses.each do |course|
      expect(rendered).to include(course.name)
    end
  end

  it 'includes action buttons' do
    expect(rendered).to include('Edit Organization')
    expect(rendered).to include('Back to Organizations')
  end

  context 'when organization is active' do
    let(:organization) { create(:organization, active: true) }

    it 'shows deactivate button' do
      expect(rendered).to include('Deactivate')
    end
  end

  context 'when organization is inactive' do
    let(:organization) { create(:organization, active: false) }

    it 'shows activate button' do
      expect(rendered).to include('Activate')
    end
  end
end
