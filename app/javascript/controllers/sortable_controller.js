import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  connect() {
    this.initializeSortable();
  }

  initializeSortable() {
    const el = this.element.querySelector('tbody');
    const reorderUrl = this.element.dataset.reorderUrl;

    Sortable.create(el, {
      animation: 150,
      handle: '.drag-handle',
      filter: '.transition-row',
      onEnd: (evt) => {
        const order = [];
        const rows = el.querySelectorAll('tr[data-id]');

        rows.forEach((row, index) => {
          order.push({
            id: row.getAttribute('data-id'),
            order: index + 1
          });
        });

        fetch(reorderUrl, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ order: order })
        }).then(response => {
          if (response.ok) {
            // Reload page to show updated track numbers, transitions, and harmonic score
            window.location.reload();
          } else {
            alert('Error reordering tracks. Please try again.');
          }
        }).catch(error => {
          console.error('Error:', error);
          alert('Error reordering tracks. Please try again.');
        });
      }
    });
  }
}
