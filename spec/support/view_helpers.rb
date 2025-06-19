# frozen_string_literal: true

# Helper methods for view specs
RSpec.configure do |config|
  config.before(:each, type: :view) do
    # Mock current_user helper
    allow(view).to receive(:current_user).and_return(
      create(:user, role: "admin")
    )

    # Mock sortable_column_header helper
    allow(view).to receive(:sortable_column_header) do |column, title, path|
      content_tag(:a, title, href: path, class: "text-left text-xs font-medium text-gray-500 uppercase tracking-wider")
    end
  end
end
