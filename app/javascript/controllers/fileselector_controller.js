import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["coverArt", "coverArtLabel", "playlistFile", "playlistFileLabel", "audioFile", "audioFileLabel"]

    connect() {
        this.coverArtTarget.addEventListener("change", this.updateCoverArtLabel.bind(this));
        this.playlistFileTarget.addEventListener("change", this.updatePlaylistFileLabel.bind(this));
        if (this.hasAudioFileTarget) {
            this.audioFileTarget.addEventListener("change", this.updateAudioFileLabel.bind(this));
        }
    }

    updateCoverArtLabel() {
        const fileName = this.coverArtTarget.files[0]?.name || "Select Cover Art";
        this.coverArtLabelTarget.textContent = fileName;
    }

    updatePlaylistFileLabel() {
        const fileName = this.playlistFileTarget.files[0]?.name || "Select Playlist File";
        this.playlistFileLabelTarget.textContent = fileName;
    }

    updateAudioFileLabel() {
        const fileName = this.audioFileTarget.files[0]?.name || "Select Audio File";
        this.audioFileLabelTarget.textContent = fileName;
    }
}
