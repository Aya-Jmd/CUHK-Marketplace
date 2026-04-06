import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  // 'digit' targets are the 4 visible boxes. 'hidden' is the real form field.
  static targets = ["digit", "hidden"]

  handleInput(event) {
    const input = event.target;
    const index = this.digitTargets.indexOf(input);
    const value = input.value;

    // 1. Force numeric only (clear it if they type a letter)
    if (!/^\d$/.test(value)) {
      input.value = "";
      this.updateHiddenField();
      return;
    }

    // 2. Auto-advance to the next box if a number was typed
    if (index < this.digitTargets.length - 1 && value !== "") {
      this.digitTargets[index + 1].focus();
    }

    this.updateHiddenField();
  }

  handleKeydown(event) {
    const input = event.target;
    const index = this.digitTargets.indexOf(input);

    // 3. Handle Backspace: Go back to the previous box if the current one is empty
    if (event.key === "Backspace" && input.value === "") {
      if (index > 0) {
        this.digitTargets[index - 1].focus();
        this.digitTargets[index - 1].value = "";
      }
      // Use setTimeout to ensure the value clears before updating the hidden field
      setTimeout(() => this.updateHiddenField(), 0);
    }
  }

  handlePaste(event) {
    event.preventDefault();
    // Get pasted data and strip out anything that isn't a number
    const pasteData = (event.clipboardData || window.clipboardData).getData('text');
    const numbers = pasteData.replace(/\D/g, '').split(''); 

    // Fill the boxes sequentially
    this.digitTargets.forEach((input, index) => {
      input.value = numbers[index] || "";
    });

    // Focus the next empty box (or the last box)
    const nextIndex = Math.min(numbers.length, this.digitTargets.length - 1);
    this.digitTargets[nextIndex].focus();

    this.updateHiddenField();
  }

  updateHiddenField() {
    // Combine all 4 boxes into a single string (e.g., "5", "8", "3", "0" -> "5830")
    const pin = this.digitTargets.map(input => input.value).join('');
    this.hiddenTarget.value = pin;
  }
}