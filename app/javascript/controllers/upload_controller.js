import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["trackId", "modal", "form"];

    show(event) {
        const button = event.relatedTarget;
        const trackId = button.getAttribute("data-track-id");
        this.trackIdTarget.value = trackId;

        const actionUrl = `/tracks/${trackId}/upload_audio`;
        this.formTarget.action = actionUrl;
    }
}