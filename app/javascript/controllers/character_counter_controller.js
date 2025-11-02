import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter"]

  connect() {
    this.updateCount()
  }

  updateCount() {
    const currentLength = this.inputTarget.value.length
    this.counterTarget.textContent = currentLength
  }
}
