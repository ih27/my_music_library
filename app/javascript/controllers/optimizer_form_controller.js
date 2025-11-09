import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "startTrack", "endTrack", "harmonicWeight"]

  interceptSubmit(event) {
    event.preventDefault()
    
    const form = this.formTarget
    
    // Remove existing hidden inputs to avoid duplicates
    form.querySelectorAll('input[type="hidden"]').forEach(input => {
      if (['start_track_id', 'end_track_id', 'harmonic_weight'].includes(input.name)) {
        input.remove()
      }
    })
    
    // Inject current values from the select dropdowns and slider
    const startTrackValue = this.startTrackTarget.value
    const endTrackValue = this.endTrackTarget.value
    const harmonicWeightValue = this.harmonicWeightTarget.value
    
    if (startTrackValue) {
      const startInput = document.createElement('input')
      startInput.type = 'hidden'
      startInput.name = 'start_track_id'
      startInput.value = startTrackValue
      form.appendChild(startInput)
    }
    
    if (endTrackValue) {
      const endInput = document.createElement('input')
      endInput.type = 'hidden'
      endInput.name = 'end_track_id'
      endInput.value = endTrackValue
      form.appendChild(endInput)
    }
    
    const harmonicInput = document.createElement('input')
    harmonicInput.type = 'hidden'
    harmonicInput.name = 'harmonic_weight'
    harmonicInput.value = harmonicWeightValue
    form.appendChild(harmonicInput)
    
    // Now submit the form
    form.submit()
  }
}

