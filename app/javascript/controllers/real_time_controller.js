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
    // Don't refresh if there are active forms to avoid interrupting user input
    if (this.hasActiveForms()) {
      return;
    }

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

  hasActiveForms() {
    // Check for any forms, input fields that have focus, or turbo frames with forms
    const activeForms = this.element.querySelectorAll('form');
    const activeInputs = this.element.querySelectorAll('input:focus, select:focus, textarea:focus');
    const turboFramesWithForms = this.element.querySelectorAll('turbo-frame form');

    return activeForms.length > 0 || activeInputs.length > 0 || turboFramesWithForms.length > 0;
  }
}
