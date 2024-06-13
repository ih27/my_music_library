import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["coverArt", "coverArtLabel", "playlistFile", "playlistFileLabel"]

    connect() {
        this.coverArtTarget.addEventListener("change", this.updateCoverArtLabel.bind(this))
        this.playlistFileTarget.addEventListener("change", this.updatePlaylistFileLabel.bind(this))
    }

    updateCoverArtLabel() {
        const fileName = this.coverArtTarget.files[0]?.name || "Select Cover Art"
        this.coverArtLabelTarget.textContent = fileName
    }

    updatePlaylistFileLabel() {
        const fileName = this.playlistFileTarget.files[0]?.name || "Select Playlist File"
        this.playlistFileLabelTarget.textContent = fileName
    }

    selectCoverArt(event) {
        event.preventDefault()
        this.coverArtTarget.click()
    }

    selectPlaylistFile(event) {
        event.preventDefault()
        this.playlistFileTarget.click()
    }
}
