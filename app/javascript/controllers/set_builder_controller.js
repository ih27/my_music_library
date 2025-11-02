import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="set-builder"
export default class extends Controller {
  static targets = ["checkbox", "selectAll", "toolbar", "selectedCount", "modal", "modalCount", "trackIdsInput", "newSetForm", "setList"]

  connect() {
    // Load selections from sessionStorage to persist across pagination
    const savedSelections = sessionStorage.getItem('selectedTrackIds')
    this.selectedTrackIds = savedSelections ? new Set(JSON.parse(savedSelections)) : new Set()

    // Restore checkbox states for tracks on current page
    this.restoreCheckboxStates()

    this.updateUI()
    this.updateSelectAllCheckbox()
  }

  // Restore checkbox states from saved selections
  restoreCheckboxStates() {
    this.checkboxTargets.forEach(checkbox => {
      if (this.selectedTrackIds.has(checkbox.value)) {
        checkbox.checked = true
      }
    })
  }

  // Save selections to sessionStorage
  saveSelections() {
    sessionStorage.setItem('selectedTrackIds', JSON.stringify(Array.from(this.selectedTrackIds)))
  }

  // Toggle individual track checkbox
  toggleTrack(event) {
    const trackId = event.target.value

    if (event.target.checked) {
      this.selectedTrackIds.add(trackId)
    } else {
      this.selectedTrackIds.delete(trackId)
    }

    this.saveSelections()
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

    this.saveSelections()
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

    // Show/hide toolbar and add padding to content
    if (this.hasToolbarTarget) {
      if (count > 0) {
        this.toolbarTarget.classList.add('active')
        // Add padding to the tracks container to prevent toolbar from blocking pagination
        this.element.style.paddingBottom = '80px'
      } else {
        this.toolbarTarget.classList.remove('active')
        // Remove padding when toolbar is hidden
        this.element.style.paddingBottom = '0'
      }
    }

    // Update modal count
    if (this.hasModalCountTarget) {
      this.modalCountTarget.textContent = count
    }

    // Update hidden track_ids input for new set form
    if (this.hasTrackIdsInputTarget) {
      this.trackIdsInputTarget.value = JSON.stringify(Array.from(this.selectedTrackIds))
    }
  }

  // Clear all selections
  clearSelection() {
    this.selectedTrackIds.clear()
    sessionStorage.removeItem('selectedTrackIds')

    this.checkboxTargets.forEach(checkbox => {
      checkbox.checked = false
    })

    if (this.hasSelectAllTarget) {
      this.selectAllTarget.checked = false
      this.selectAllTarget.indeterminate = false
    }

    this.updateUI()
  }

  // Show the modal
  showModal() {
    if (this.selectedTrackIds.size === 0) {
      alert('Please select at least one track')
      return
    }

    if (this.hasModalTarget) {
      const modal = new bootstrap.Modal(this.modalTarget)
      modal.show()
    }
  }

  // Add tracks to selected existing set
  selectSet(event) {
    const setId = event.currentTarget.dataset.setId

    if (!setId || this.selectedTrackIds.size === 0) {
      return
    }

    // Create form and submit
    const form = document.createElement('form')
    form.method = 'POST'
    form.action = `/dj_sets/${setId}/add_tracks`

    // Add CSRF token
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    if (csrfToken) {
      const csrfInput = document.createElement('input')
      csrfInput.type = 'hidden'
      csrfInput.name = 'authenticity_token'
      csrfInput.value = csrfToken
      form.appendChild(csrfInput)
    }

    // Add track IDs
    this.selectedTrackIds.forEach(trackId => {
      const input = document.createElement('input')
      input.type = 'hidden'
      input.name = 'track_ids[]'
      input.value = trackId
      form.appendChild(input)
    })

    // Clear selections from sessionStorage before submitting
    sessionStorage.removeItem('selectedTrackIds')

    document.body.appendChild(form)
    form.submit()
  }

  // Submit new set form with track IDs
  submitNewSet(event) {
    event.preventDefault()

    if (this.selectedTrackIds.size === 0) {
      alert('Please select at least one track')
      return
    }

    const form = event.target
    const formData = new FormData(form)

    // Remove the JSON track_ids and add as array
    formData.delete('dj_set[track_ids]')
    this.selectedTrackIds.forEach(trackId => {
      formData.append('track_ids[]', trackId)
    })

    // Submit form
    fetch(form.action, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || '',
        'Accept': 'text/html'
      }
    }).then(response => {
      if (response.ok) {
        // Clear selections from sessionStorage before redirecting
        sessionStorage.removeItem('selectedTrackIds')
        // Redirect to the new set or reload page
        window.location.href = response.url
      } else {
        alert('Error creating set. Please try again.')
      }
    }).catch(error => {
      console.error('Error:', error)
      alert('Error creating set. Please try again.')
    })
  }
}
