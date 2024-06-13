import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
    sort(event) {
        event.preventDefault();
        const column = event.currentTarget.dataset.sortColumn;
        const direction = this.sortDirection(column);
        const url = new URL(window.location.href);

        url.searchParams.set("sort", column);
        url.searchParams.set("direction", direction);

        window.location = url.toString();
    }

    sortDirection(column) {
        const currentSort = new URLSearchParams(window.location.search).get("sort");
        const currentDirection = new URLSearchParams(window.location.search).get("direction");

        if (currentSort === column) {
            return currentDirection === "asc" ? "desc" : "asc";
        } else {
            return "asc";
        }
    }
}
