import { Controller } from '@hotwired/stimulus';

export default class extends Controller {
  static targets = ['checkbox', 'removeButton'];

  connect() {
    this.updateButtons();
  }

  selectAll() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = true;
    });
    this.updateButtons();
  }

  selectNone() {
    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false;
    });
    this.updateButtons();
  }

  updateButtons() {
    const checkedBoxes = this.checkboxTargets.filter(checkbox => checkbox.checked);
    const hasSelection = checkedBoxes.length > 0;

    this.removeButtonTarget.disabled = !hasSelection;
  }
}
