// app/javascript/controllers/sortable_controller.js

import { Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

export default class extends Controller {
  connect() {
    this.initializeSortable();
  }

  initializeSortable() {
    const el = this.element.querySelector('tbody');
    const reorderUrl = this.element.dataset.reorderUrl; // Ensure the correct data attribute is accessed

    Sortable.create(el, {
      animation: 150,
      onEnd: (evt) => {
        const order = [];
        const rows = el.getElementsByTagName('tr');
        for (let i = 0; i < rows.length; i++) {
          order.push({
            id: rows[i].getAttribute('data-id'),
            order: i + 1
          });
          // Update the order number in the table
          rows[i].querySelector('.order-cell').textContent = i + 1;
        }
        fetch(reorderUrl, { // Use the correct reorder URL
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({ order: order })
        });
      }
    });
  }
}
