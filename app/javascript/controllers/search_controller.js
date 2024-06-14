import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input"];

    connect() {
        this.inputTarget.addEventListener("keydown", (event) => {
            if (event.key === "Enter") {
                event.preventDefault();
                this.element.submit();
            }
        });

        document.getElementById("clear-search").addEventListener("click", () => {
            this.inputTarget.value = "";
            this.element.submit();
        });
    }
}
