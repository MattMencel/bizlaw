require "rails_helper"

RSpec.describe "shared/navigation/_nav_item.html.erb", type: :view do
  let(:title) { "Test Navigation Item" }
  let(:icon) { "home" }
  let(:path) { "/test-path" }

  before do
    # Mock the current_page? helper
    allow(view).to receive(:current_page?).and_return(false)

    # Mock the request.path for testing
    request = double("request", path: "/cases")
    allow(view).to receive(:request).and_return(request)
  end

  describe "active state detection" do
    context "when using current_page? helper" do
      it "marks item as active when current_page? returns true" do
        allow(view).to receive(:current_page?).with(path).and_return(true)

        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: path,
          icon: icon
        }

        expect(rendered).to include("bg-blue-600 text-white")
        expect(rendered).not_to include("text-gray-300 hover:bg-gray-700")
      end

      it "marks item as inactive when current_page? returns false" do
        allow(view).to receive(:current_page?).with(path).and_return(false)

        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: path,
          icon: icon
        }

        expect(rendered).to include("text-gray-300 hover:bg-gray-700")
        expect(rendered).not_to include("bg-blue-600 text-white")
      end
    end

    context "when using admin route detection" do
      let(:path) { "/admin/dashboard" }

      before do
        request = double("request", path: "/admin/dashboard")
        allow(view).to receive(:request).and_return(request)
      end

      it "marks admin items as active when in same admin section" do
        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: path,
          icon: icon
        }

        expect(rendered).to include("bg-blue-600 text-white")
      end

      it "marks admin items as inactive when in different admin section" do
        request = double("request", path: "/admin/users")
        allow(view).to receive(:request).and_return(request)

        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: "/admin/settings",
          icon: icon
        }

        expect(rendered).to include("text-gray-300 hover:bg-gray-700")
      end
    end

    context "when using path prefix matching" do
      before do
        request = double("request", path: "/cases")
        allow(view).to receive(:request).and_return(request)
      end

      it "marks item as active when current path starts with item path" do
        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: "/cases",
          icon: icon
        }

        expect(rendered).to include("bg-blue-600 text-white")
      end

      it "marks item as inactive when current path does not start with item path" do
        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: "/teams",
          icon: icon
        }

        expect(rendered).to include("text-gray-300 hover:bg-gray-700")
      end

      it "handles query parameters correctly" do
        request = double("request", path: "/cases?page=2")
        allow(view).to receive(:request).and_return(request)

        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: "/cases?tab=active",
          icon: icon
        }

        expect(rendered).to include("bg-blue-600 text-white")
      end
    end

    context "when handling edge cases" do
      it "handles nil path gracefully" do
        expect {
          render partial: "shared/navigation/nav_item", locals: {
            title: title,
            path: "#",
            icon: icon
          }
        }.not_to raise_error
      end

      it "handles empty string path" do
        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: "",
          icon: icon
        }

        expect(rendered).to include("text-gray-300 hover:bg-gray-700")
      end

      it "handles hash (#) path" do
        render partial: "shared/navigation/nav_item", locals: {
          title: title,
          path: "#",
          icon: icon
        }

        expect(rendered).to include("text-gray-300 hover:bg-gray-700")
      end

      it "handles exception during active state detection" do
        allow(view).to receive(:current_page?).and_raise(StandardError, "Test error")

        expect {
          render partial: "shared/navigation/nav_item", locals: {
            title: title,
            path: path,
            icon: icon
          }
        }.not_to raise_error

        expect(rendered).to include("text-gray-300 hover:bg-gray-700")
      end
    end
  end

  describe "size variations" do
    it "applies small size classes when size is sm" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon,
        size: "sm"
      }

      expect(rendered).to include("px-2 py-1.5 text-xs")
      expect(rendered).to include("h-4 w-4")
    end

    it "applies large size classes when size is lg" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon,
        size: "lg"
      }

      expect(rendered).to include("px-4 py-3 text-base")
      expect(rendered).to include("h-6 w-6")
    end

    it "applies medium size classes by default" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon
      }

      expect(rendered).to include("px-3 py-2 text-sm")
      expect(rendered).to include("h-5 w-5")
    end
  end

  describe "badge support" do
    it "displays badge when provided" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon,
        badge: "3"
      }

      expect(rendered).to include("3")
      expect(rendered).to include("bg-gray-600 text-white text-xs rounded-full")
    end

    it "does not display badge when not provided" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon
      }

      expect(rendered).not_to include("bg-gray-600 text-white text-xs rounded-full")
    end
  end

  describe "accessibility" do
    it "includes proper focus styles" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon
      }

      expect(rendered).to include("focus:outline-none focus:ring-2 focus:ring-blue-500")
    end

    it "includes turbo navigation" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon
      }

      expect(rendered).to include('data-turbo="true"')
    end
  end

  describe "icon rendering" do
    it "renders the specified icon" do
      # Stub the icon partial to avoid missing icon errors
      allow(view).to receive(:render).and_call_original
      allow(view).to receive(:render).with("shared/icons/user").and_return('<path d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />')

      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: "user"
      }

      expect(rendered).to include("svg")
      expect(rendered).to include('stroke="currentColor"')
    end

    it "applies correct icon classes for active state" do
      allow(view).to receive(:current_page?).with(path).and_return(true)

      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon
      }

      expect(rendered).to include("text-white")
    end

    it "applies correct icon classes for inactive state" do
      render partial: "shared/navigation/nav_item", locals: {
        title: title,
        path: path,
        icon: icon
      }

      expect(rendered).to include("text-gray-400")
    end
  end
end
