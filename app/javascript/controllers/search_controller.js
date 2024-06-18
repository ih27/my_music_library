import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    static targets = ["input"];

    connect() {
        this.inputTarget.addEventListener("input", this.debounce(this.search.bind(this), 300));

        document.getElementById("clear-search").addEventListener("click", () => {
            this.inputTarget.value = "";
            this.element.submit();
        });
    }

    search(event) {
        if (this.inputTarget.value.length >= 3 || this.inputTarget.value.length === 0) {
            const input = this.inputTarget;
            const form = this.element;
            const url = new URL(form.action);
            const params = new URLSearchParams(new FormData(form));
            url.search = params.toString();

            fetch(url, {
                method: "GET",
                headers: {
                    "Accept": "text/html"
                }
            }).then(response => {
                if (response.ok) {
                    return response.text();
                } else {
                    throw new Error("Network response was not ok.");
                }
            }).then(html => {
                const parser = new DOMParser();
                const doc = parser.parseFromString(html, 'text/html');
                const newContent = doc.querySelector('#tracks-content').innerHTML;
                document.querySelector('#tracks-content').innerHTML = newContent;
                this.inputTarget.focus();  // Refocus the input field after content update
            }).catch(error => {
                console.error("Fetch error:", error);
            });
        }
    }

    debounce(func, wait) {
        let timeout;
        return function(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
}
