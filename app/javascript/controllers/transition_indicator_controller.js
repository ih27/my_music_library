import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="transition-indicator"
export default class extends Controller {
  static values = {
    fromTrack: String,
    toTrack: String,
    fromKey: String,
    toKey: String,
    quality: String
  }

  connect() {
    this.setTooltip()
  }

  setTooltip() {
    // Add browser native tooltip showing transition details
    const qualityLabels = {
      perfect: 'Perfect Match',
      smooth: 'Smooth Transition',
      energy_boost: 'Energy Boost',
      rough: 'Rough Transition'
    }

    const label = qualityLabels[this.qualityValue] || 'Unknown'
    this.element.setAttribute('title', `${this.fromKeyValue} → ${this.toKeyValue}: ${label}`)
  }
}
