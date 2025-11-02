import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="track-remover"
export default class extends Controller {
  static targets = ["checkbox", "selectAll", "toolbar", "selectedCount"]

  connect() {
    this.selectedTrackIds = new Set()
    this.updateUI()
  }

  // Toggle individual track checkbox
  toggleTrack(event) {
    const trackId = event.target.value

    if (event.target.checked) {
      this.selectedTrackIds.add(trackId)
    } else {
      this.selectedTrackIds.delete(trackId)
    }

    this.updateUI()
    this.updateSelectAllCheckbox()
  }

  // Toggle all checkboxes
  toggleAll(event) {
    const isChecked = event.target.checked

    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = isChecked
      const trackId = checkbox.value

      if (isChecked) {
        this.selectedTrackIds.add(trackId)
      } else {
        this.selectedTrackIds.delete(trackId)
      }
    })

    this.updateUI()
  }

  // Update select all checkbox based on individual selections
  updateSelectAllCheckbox() {
    if (!this.hasSelectAllTarget) return

    const totalCheckboxes = this.checkboxTargets.length
    const selectedCheckboxes = this.checkboxTargets.filter(cb => cb.checked).length

    if (selectedCheckboxes === 0) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    } else if (selectedCheckboxes === totalCheckboxes) {
      this.selectAllTarget.checked = true
      this.selectAllTarget.indeterminate = false
    } else {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = true
    }
  }

  // Update UI based on selection state
  updateUI() {
    const count = this.selectedTrackIds.size

    // Update selected count display
    if (this.hasSelectedCountTarget) {
      this.selectedCountTarget.textContent = `${count} track${count !== 1 ? 's' : ''} selected`
    }

    // Show/hide toolbar
    if (this.hasToolbarTarget) {
      if (count > 0) {
        this.toolbarTarget.classList.add('active')
      } else {
        this.toolbarTarget.classList.remove('active')
      }
    }
  }

  // Clear all selections
  clearSelection() {
    this.selectedTrackIds.clear()

    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    }

    this.updateUI()
  }

  // Remove selected tracks
  removeSelected(event) {
    event.preventDefault()

    if (this.selectedTrackIds.size === 0) {
      alert('Please select at least one track to remove')
      return
    }

    const count = this.selectedTrackIds.size
    const confirmed = confirm(`Remove ${count} track${count !== 1 ? 's' : ''} from this set?`)

    if (!confirmed) return

    const setId = this.element.dataset.setId
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = `/dj_sets/${setId}/remove_tracks`

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add _method for DELETE
    const methodInput = document.createElement('input')
    methodInput.type = 'hidden'
    methodInput.name = '_method'
    methodInput.value = 'delete'
    form.appendChild(methodInput)

    // Add track IDs
    this.selectedTrackIds.forEach(trackId => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'track_ids[]'
      input.value = trackId
      form.appendChild(input)
    })

    document.body.appendChild(form)
    form.submit()
  }
}
