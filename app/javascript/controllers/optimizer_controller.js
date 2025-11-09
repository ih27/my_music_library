import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="optimizer"
export default class extends Controller {
  static targets = ["harmonicWeight", "energyWeight", "slider", "collapse"]

  connect() {
    this.updateWeights()
  }

  updateWeights() {
    const harmonicValue = this.sliderTarget.value
    const energyValue = 100 - harmonicValue

    this.harmonicWeightTarget.textContent = harmonicValue
    this.energyWeightTarget.textContent = energyValue
  }

  toggleCollapse() {
    if (this.collapseTarget.style.display === "none" || this.collapseTarget.style.display === "") {
      this.collapseTarget.style.display = "block"
    } else {
      this.collapseTarget.style.display = "none"
    }
  }
}
