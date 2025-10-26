import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="harmonic-filter"
export default class extends Controller {
  static targets = ["slider", "sliderValue", "checkbox", "results", "perfectSection", "smoothSection", "energySection", "trackSelect"]
  static values = {
    trackId: Number,
    url: String
  }

  connect() {
    // Update slider value if slider exists
    if (this.hasSliderTarget && this.hasSliderValueTarget) {
      this.updateSliderValue()

      // Hide slider initially if checkbox is unchecked
      if (this.hasCheckboxTarget) {
        const sliderContainer = this.sliderTarget.closest('.bpm-slider-container')
        if (sliderContainer) {
          sliderContainer.style.display = this.checkboxTarget.checked ? 'block' : 'none'
        }
      }
    }

    // Initialize Tom Select for searchable dropdown (tracks index page)
    if (this.hasTrackSelectTarget && typeof window.TomSelect !== 'undefined') {
      this.tomSelect = new window.TomSelect(this.trackSelectTarget, {
        placeholder: 'Select a track...',
        maxOptions: null,
        onChange: (value) => {
          if (value) {
            this.filterByCompatibility(value)
          }
        }
      })
    }

    // Load compatible tracks for track show page
    if (this.trackIdValue) {
      this.loadCompatibleTracks()
    }
  }

  disconnect() {
    if (this.tomSelect) {
      this.tomSelect.destroy()
    }
  }

  updateSliderValue() {
    const value = this.sliderTarget.value
    this.sliderValueTarget.textContent = `±${value} BPM`
  }

  sliderChanged() {
    this.updateSliderValue()
    if (this.checkboxTarget.checked) {
      this.loadCompatibleTracks()
    }
  }

  checkboxToggled() {
    // Toggle slider visibility
    if (this.hasSliderTarget) {
      const sliderContainer = this.sliderTarget.closest('.bpm-slider-container')
      if (sliderContainer) {
        sliderContainer.style.display = this.checkboxTarget.checked ? 'block' : 'none'
      }
    }
    this.loadCompatibleTracks()
  }

  loadCompatibleTracks() {
    if (!this.hasCheckboxTarget || !this.hasSliderTarget) {
      return
    }

    const bpmRange = this.checkboxTarget.checked ? this.sliderTarget.value : null
    const url = this.urlValue || `/tracks/${this.trackIdValue}/compatible`

    const params = new URLSearchParams()
    if (bpmRange) {
      params.append('bpm_range', bpmRange)
    }

    fetch(`${url}?${params}`)
      .then(response => {
        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`)
        }
        return response.json()
      })
      .then(data => {
        this.displayResults(data)
      })
      .catch(error => {
        console.error('Error loading compatible tracks:', error)
        this.showError(error.message)
      })
  }

  displayResults(data) {
    this.displaySection(this.perfectSectionTarget, data.perfect, 'Same Key', '🟢')
    this.displaySection(this.smoothSectionTarget, data.smooth, 'Smooth Transitions', '🔵')
    this.displaySection(this.energySectionTarget, data.energy_boost, 'Energy Boost', '⚡')
  }

  displaySection(section, tracks, title, indicator) {
    const count = tracks.length
    const headerHtml = `
      <h5 class="mb-3">
        <span class="transition-indicator me-2">${indicator}</span>
        ${title}
        <span class="badge bg-secondary">${count}</span>
      </h5>
    `

    if (count === 0) {
      section.innerHTML = headerHtml + '<p class="text-muted">No compatible tracks found.</p>'
      return
    }

    const tracksHtml = tracks.map(track => {
      const artistNames = track.artists.map(a => a.name).join(', ')
      return `
        <div class="card mb-2">
          <div class="card-body py-2">
            <div class="d-flex justify-content-between align-items-center">
              <div>
                <a href="/tracks/${track.id}" class="text-decoration-none">
                  <strong>${this.escapeHtml(track.name)}</strong>
                </a>
                <span class="text-muted"> - ${this.escapeHtml(artistNames)}</span>
              </div>
              <div class="text-end">
                <span class="badge bg-info">${track.key?.name || 'N/A'}</span>
                <span class="badge bg-secondary">${track.bpm} BPM</span>
              </div>
            </div>
          </div>
        </div>
      `
    }).join('')

    section.innerHTML = headerHtml + tracksHtml
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  // Filter tracks table by compatibility (for tracks index page)
  filterByCompatibility(trackId) {
    const bpmRange = this.hasCheckboxTarget && this.checkboxTarget.checked ? this.sliderTarget.value : null
    const url = `/tracks/${trackId}/compatible`

    const params = new URLSearchParams()
    if (bpmRange) {
      params.append('bpm_range', bpmRange)
    }

    fetch(`${url}?${params}`)
      .then(response => response.json())
      .then(data => {
        // Get all compatible track IDs
        const compatibleIds = new Set([
          ...data.perfect.map(t => t.id),
          ...data.smooth.map(t => t.id),
          ...data.energy_boost.map(t => t.id)
        ])

        // Show/hide table rows based on compatibility
        const table = document.querySelector('#tracks-table tbody')
        if (table) {
          const rows = table.querySelectorAll('tr')
          rows.forEach(row => {
            const trackId = parseInt(row.dataset.trackId)

            if (trackId && compatibleIds.has(trackId)) {
              row.style.display = ''
              // Add compatibility badge
              this.addCompatibilityBadge(row, trackId, data)
            } else if (trackId) {
              row.style.display = 'none'
            }
          })
        }
      })
      .catch(error => {
        console.error('Error filtering tracks:', error)
      })
  }

  addCompatibilityBadge(row, trackId, data) {
    // Determine compatibility type
    let badge = ''
    if (data.perfect.some(t => t.id === trackId)) {
      badge = '<span class="badge bg-success ms-2">🟢 Perfect</span>'
    } else if (data.smooth.some(t => t.id === trackId)) {
      badge = '<span class="badge bg-primary ms-2">🔵 Smooth</span>'
    } else if (data.energy_boost.some(t => t.id === trackId)) {
      badge = '<span class="badge bg-warning ms-2">⚡ Energy</span>'
    }

    // Add badge to first cell if not already present
    const firstCell = row.querySelector('td:first-child')
    if (firstCell && badge && !firstCell.querySelector('.badge')) {
      firstCell.innerHTML += badge
    }
  }

  clearFilter() {
    // Reset Tom Select
    if (this.tomSelect) {
      this.tomSelect.clear()
    }

    // Show all table rows
    const table = document.querySelector('#tracks-table tbody')
    if (table) {
      const rows = table.querySelectorAll('tr')
      rows.forEach(row => {
        row.style.display = ''
        // Remove compatibility badges
        const badges = row.querySelectorAll('.badge.ms-2')
        badges.forEach(badge => badge.remove())
      })
    }
  }

  showError(message) {
    if (this.hasPerfectSectionTarget) {
      this.perfectSectionTarget.innerHTML = `
        <div class="alert alert-danger" role="alert">
          <strong>Error loading compatible tracks:</strong> ${this.escapeHtml(message)}
        </div>
      `
    }
    if (this.hasSmoothSectionTarget) {
      this.smoothSectionTarget.innerHTML = ''
    }
    if (this.hasEnergySectionTarget) {
      this.energySectionTarget.innerHTML = ''
    }
  }
}
