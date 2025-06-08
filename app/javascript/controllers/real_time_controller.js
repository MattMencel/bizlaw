import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['content'];
  static values = {
    refreshInterval: { type: Number, default: 0 },
    url: String,
  };

  connect() {
    if (this.hasRefreshIntervalValue && this.refreshIntervalValue > 0) {
      this.startRefreshing();
    }
  }

  disconnect() {
    this.stopRefreshing();
  }

  startRefreshing() {
    this.refreshTimer = setInterval(() => {
      this.refresh();
    }, this.refreshIntervalValue);
  }

  stopRefreshing() {
    if (this.refreshTimer) {
      clearInterval(this.refreshTimer);
    }
  }

  async refresh() {
    try {
      const response = await fetch(this.urlValue);
      if (response.ok) {
        const html = await response.text();
        this.contentTarget.innerHTML = html;
      }
    }
    catch (error) {
      console.error('Error refreshing content:', error);
    }
  }
}
