import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['checkbox', 'submitButton'];

  connect() {
    this.updateButton();
  }

  selectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true;
    });
    this.updateButton();
  }

  selectNone() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false;
    });
    this.updateButton();
  }

  updateButton() {
    const checkedBoxes = this.checkboxTargets.filter(checkbox => checkbox.checked);
    const hasSelection = checkedBoxes.length > 0;

    this.submitButtonTarget.disabled = !hasSelection;
  }
}
