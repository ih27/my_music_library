import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["coverArt", "coverArtLabel", "playlistFile", "playlistFileLabel", "audioFile", "audioFileLabel", "setFile", "setFileLabel"]

    connect() {
        if (this.hasAudioFileTarget) {
            this.audioFileTarget.addEventListener("change", this.updateAudioFileLabel.bind(this));
        } else if (this.hasSetFileTarget) {
            this.setFileTarget.addEventListener("change", this.updateSetFileLabel.bind(this));
        } else {
            this.coverArtTarget.addEventListener("change", this.updateCoverArtLabel.bind(this));
            this.playlistFileTarget.addEventListener("change", this.updatePlaylistFileLabel.bind(this));
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

    updateSetFileLabel() {
        const fileName = this.setFileTarget.files[0]?.name || "Select Set File";
        this.setFileLabelTarget.textContent = fileName;
    }
}
