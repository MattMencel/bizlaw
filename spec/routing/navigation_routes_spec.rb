require "rails_helper"

RSpec.describe "Navigation Routes", type: :routing do
  describe "Cases routes" do
    it "routes to cases index" do
      expect(get: "/cases").to route_to(
        controller: "cases",
        action: "index"
      )
    end

    it "routes to cases background collection" do
      expect(get: "/cases/background").to route_to(
        controller: "cases",
        action: "background"
      )
    end

    it "routes to cases timeline collection" do
      expect(get: "/cases/timeline").to route_to(
        controller: "cases",
        action: "timeline"
      )
    end

    it "routes to cases events collection" do
      expect(get: "/cases/events").to route_to(
        controller: "cases",
        action: "events"
      )
    end

    it "routes to individual case background" do
      expect(get: "/cases/123/background").to route_to(
        controller: "cases",
        action: "background",
        id: "123"
      )
    end

    it "routes to individual case timeline" do
      expect(get: "/cases/123/timeline").to route_to(
        controller: "cases",
        action: "timeline",
        id: "123"
      )
    end

    it "routes to individual case events" do
      expect(get: "/cases/123/events").to route_to(
        controller: "cases",
        action: "events",
        id: "123"
      )
    end
  end

  describe "Annotations routes" do
    it "routes to annotations index" do
      expect(get: "/annotations").to route_to(
        controller: "annotations",
        action: "index"
      )
    end

    it "routes to annotations show" do
      expect(get: "/annotations/123").to route_to(
        controller: "annotations",
        action: "show",
        id: "123"
      )
    end

    it "routes to annotations create" do
      expect(post: "/annotations").to route_to(
        controller: "annotations",
        action: "create"
      )
    end

    it "routes to annotations update" do
      expect(patch: "/annotations/123").to route_to(
        controller: "annotations",
        action: "update",
        id: "123"
      )
    end

    it "routes to annotations destroy" do
      expect(delete: "/annotations/123").to route_to(
        controller: "annotations",
        action: "destroy",
        id: "123"
      )
    end

    it "routes to annotations search" do
      expect(get: "/annotations/search").to route_to(
        controller: "annotations",
        action: "search"
      )
    end
  end

  describe "Document Search routes" do
    it "routes to document search index" do
      expect(get: "/document_search").to route_to(
        controller: "document_search",
        action: "index"
      )
    end

    it "routes to document search advanced" do
      expect(get: "/document_search/advanced").to route_to(
        controller: "document_search",
        action: "advanced"
      )
    end

    it "routes to document search" do
      expect(post: "/document_search/search").to route_to(
        controller: "document_search",
        action: "search"
      )
    end
  end

  describe "Mood Tracking routes" do
    it "routes to mood tracking index" do
      expect(get: "/mood_tracking").to route_to(
        controller: "mood_tracking",
        action: "index"
      )
    end

    it "routes to mood tracking show" do
      expect(get: "/mood_tracking/123").to route_to(
        controller: "mood_tracking",
        action: "show",
        id: "123"
      )
    end

    it "routes to mood tracking create" do
      expect(post: "/mood_tracking").to route_to(
        controller: "mood_tracking",
        action: "create"
      )
    end

    it "routes to mood tracking update" do
      expect(patch: "/mood_tracking/123/update_mood").to route_to(
        controller: "mood_tracking",
        action: "update_mood",
        id: "123"
      )
    end

    it "routes to mood tracking history" do
      expect(get: "/mood_tracking/history").to route_to(
        controller: "mood_tracking",
        action: "history"
      )
    end

    it "routes to mood tracking analytics" do
      expect(get: "/mood_tracking/analytics").to route_to(
        controller: "mood_tracking",
        action: "analytics"
      )
    end
  end

  describe "Feedback History routes" do
    it "routes to feedback history index" do
      expect(get: "/feedback_history").to route_to(
        controller: "feedback_history",
        action: "index"
      )
    end

    it "routes to feedback history show" do
      expect(get: "/feedback_history/123").to route_to(
        controller: "feedback_history",
        action: "show",
        id: "123"
      )
    end

    it "routes to feedback history search" do
      expect(get: "/feedback_history/search").to route_to(
        controller: "feedback_history",
        action: "search"
      )
    end

    it "routes to feedback history export" do
      expect(get: "/feedback_history/export").to route_to(
        controller: "feedback_history",
        action: "export"
      )
    end
  end

  describe "Navigation path helpers" do
    it "generates correct paths for new routes" do
      expect(background_cases_path).to eq("/cases/background")
      expect(timeline_cases_path).to eq("/cases/timeline")
      expect(events_cases_path).to eq("/cases/events")
      expect(annotations_path).to eq("/annotations")
      expect(document_search_index_path).to eq("/document_search")
      expect(mood_tracking_index_path).to eq("/mood_tracking")
      expect(feedback_history_index_path).to eq("/feedback_history")
    end

    it "generates correct member paths" do
      expect(background_case_path(123)).to eq("/cases/123/background")
      expect(timeline_case_path(123)).to eq("/cases/123/timeline")
      expect(events_case_path(123)).to eq("/cases/123/events")
      expect(annotation_path(123)).to eq("/annotations/123")
      expect(mood_tracking_path(123)).to eq("/mood_tracking/123")
      expect(feedback_history_path(123)).to eq("/feedback_history/123")
    end
  end

  describe "Existing negotiation routes integration" do
    it "maintains existing negotiation routes" do
      expect(get: "/cases/123/negotiations").to route_to(
        controller: "negotiations",
        action: "index",
        case_id: "123"
      )
    end

    it "maintains negotiation history route" do
      expect(get: "/cases/123/negotiations/history").to route_to(
        controller: "negotiations",
        action: "history",
        case_id: "123"
      )
    end

    it "maintains negotiation calculator route" do
      expect(get: "/cases/123/negotiations/calculator").to route_to(
        controller: "negotiations",
        action: "calculator",
        case_id: "123"
      )
    end

    it "maintains negotiation templates route" do
      expect(get: "/cases/123/negotiations/templates").to route_to(
        controller: "negotiations",
        action: "templates",
        case_id: "123"
      )
    end

    it "maintains client consultation route" do
      expect(get: "/cases/123/negotiations/456/client_consultation").to route_to(
        controller: "negotiations",
        action: "client_consultation",
        case_id: "123",
        id: "456"
      )
    end
  end
end
