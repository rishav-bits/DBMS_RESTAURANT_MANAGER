// Client-side interactions for Restaurant Reservation & Ordering System
// Receiptify Paper Animation & Thermal Printing Engine

document.addEventListener("DOMContentLoaded", () => {
  // Auto-dismiss alerts after 6 seconds
  const alerts = document.querySelectorAll('.alert-dismissible');
  alerts.forEach(alert => {
    setTimeout(() => {
      const bsAlert = bootstrap.Alert.getOrCreateInstance(alert);
      if (bsAlert) bsAlert.close();
    }, 6000);
  });

  // Apply thermal printout rollout animation to cards
  const slips = document.querySelectorAll('.card-glass, .receipt-card, .receipt-paper, .kpi-card');
  slips.forEach((slip, idx) => {
    slip.classList.add('animate-print');
    slip.style.animationDelay = `${Math.min(idx * 0.07, 0.55)}s`;
  });

  // Add 3D tactile paper tilt on mouse movement for receipt elements
  document.querySelectorAll('.paper-tilt').forEach(el => {
    el.addEventListener('mousemove', (e) => {
      const rect = el.getBoundingClientRect();
      const x = e.clientX - rect.left - rect.width / 2;
      const y = e.clientY - rect.top - rect.height / 2;
      const rotateX = -(y / rect.height) * 8;
      const rotateY = (x / rect.width) * 8;
      el.style.transform = `perspective(800px) rotateX(${rotateX}deg) rotateY(${rotateY}deg) translateY(-4px)`;
    });
    el.addEventListener('mouseleave', () => {
      el.style.transform = '';
    });
  });

  // Attach tactile paper sound to primary buttons
  document.querySelectorAll('.btn-tear-coupon, .btn-print-receipt, .btn-primary').forEach(btn => {
    btn.addEventListener('click', () => {
      playPaperSound();
    });
  });
});

// Synthesize a subtle, satisfying paper tear / thermal printer feed sound via Web Audio API
function playPaperSound() {
  try {
    const AudioCtx = window.AudioContext || window.webkitAudioContext;
    if (!AudioCtx) return;
    const ctx = new AudioCtx();
    const bufferSize = ctx.sampleRate * 0.04;
    const buffer = ctx.createBuffer(1, bufferSize, ctx.sampleRate);
    const data = buffer.getChannelData(0);
    for (let i = 0; i < bufferSize; i++) {
      data[i] = (Math.random() * 2 - 1) * Math.exp(-i / (bufferSize * 0.3));
    }
    const noise = ctx.createBufferSource();
    noise.buffer = buffer;
    const filter = ctx.createBiquadFilter();
    filter.type = 'highpass';
    filter.frequency.value = 1400;
    const gain = ctx.createGain();
    gain.gain.setValueAtTime(0.03, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + 0.04);
    noise.connect(filter);
    filter.connect(gain);
    gain.connect(ctx.destination);
    noise.start();
  } catch (e) {
    // AudioContext blocked or not supported - silently continue
  }
}

// 1-Click Thermal Receipt Print function
function printReceipt() {
  playPaperSound();
  window.print();
}

// Populate Customer Edit Modal
function openEditCustomerModal(id, name, email, phone, address) {
  document.getElementById('edit_customer_id').value = id;
  document.getElementById('edit_name').value = name;
  document.getElementById('edit_email').value = email;
  document.getElementById('edit_phone').value = phone;
  document.getElementById('edit_address').value = address;
  const modal = new bootstrap.Modal(document.getElementById('editCustomerModal'));
  modal.show();
}

// Populate Menu Item Edit Modal
function openEditMenuModal(id, name, catId, veg, prepTime, descr) {
  document.getElementById('edit_menu_item_id').value = id;
  document.getElementById('edit_menu_name').value = name;
  document.getElementById('edit_category_id').value = catId;
  document.getElementById('edit_is_veg').value = veg;
  document.getElementById('edit_prep_time').value = prepTime;
  document.getElementById('edit_description').value = descr;
  const modal = new bootstrap.Modal(document.getElementById('editMenuModal'));
  modal.show();
}

// Populate Change Price Modal
function openChangePriceModal(id, name, currentPrice) {
  document.getElementById('price_item_id').value = id;
  document.getElementById('price_item_name').textContent = name;
  document.getElementById('current_price_display').textContent = '₹' + parseFloat(currentPrice).toFixed(2);
  document.getElementById('new_price_input').value = currentPrice;
  const modal = new bootstrap.Modal(document.getElementById('changePriceModal'));
  modal.show();
}

// Fetch & Display Price History
function viewPriceHistory(itemId) {
  fetch(`/menu/price-history/${itemId}`)
    .then(res => res.json())
    .then(data => {
      document.getElementById('history_item_title').textContent = data.item_name;
      const tbody = document.getElementById('price_history_body');
      tbody.innerHTML = '';
      if (!data.history || data.history.length === 0) {
        tbody.innerHTML = '<tr><td colspan="4" class="text-center text-dark py-3 fw-bold">No price history available.</td></tr>';
      } else {
        data.history.forEach(h => {
          const row = document.createElement('tr');
          row.innerHTML = `
            <td class="fw-bold fs-6" style="color: #b45309;">₹${parseFloat(h.price).toFixed(2)}</td>
            <td class="text-dark fw-bold">${h.start_date}</td>
            <td class="text-dark fw-bold">${h.end_date || '<em>Present (Active)</em>'}</td>
            <td><span class="badge ${h.end_date ? 'bg-secondary text-dark' : 'bg-success text-dark'}">${h.status}</span></td>
          `;
          tbody.appendChild(row);
        });
      }
      const modal = new bootstrap.Modal(document.getElementById('priceHistoryModal'));
      modal.show();
    })
    .catch(err => alert("Failed to fetch price history: " + err));
}

// Dynamic Table Checker for Reservations Page
function checkAvailableTables() {
  const restId = document.getElementById('res_rest_id').value;
  const dateVal = document.getElementById('res_date').value;
  const slotVal = document.getElementById('res_slot').value;
  const guestsVal = document.getElementById('res_guests').value;
  const tableSelect = document.getElementById('res_table_id');
  const tableHint = document.getElementById('table_search_hint');

  if (!restId || !dateVal || !slotVal) {
    tableSelect.innerHTML = '<option value="">-- Choose restaurant, date and slot first --</option>';
    return;
  }

  tableHint.textContent = "Checking live table availability in Oracle...";
  tableHint.className = "small text-dark fw-bold mt-1";

  fetch(`/api/tables?restaurant_id=${restId}&date=${dateVal}&slot=${encodeURIComponent(slotVal)}&guests=${guestsVal}`)
    .then(res => res.json())
    .then(tables => {
      tableSelect.innerHTML = '';
      if (tables.length === 0) {
        tableSelect.innerHTML = '<option value="">No tables free for this slot and party size</option>';
        tableHint.textContent = "⚠️ All tables occupied or party size exceeds capacity for this slot.";
        tableHint.className = "text-danger fw-bold small mt-1";
      } else {
        tableSelect.innerHTML = '<option value="">-- Select an available table (' + tables.length + ' available) --</option>';
        tables.forEach(t => {
          const opt = document.createElement('option');
          opt.value = t.table_id;
          opt.textContent = `Table ${t.table_number} (Capacity: ${t.capacity} guests)`;
          tableSelect.appendChild(opt);
        });
        tableHint.textContent = `✓ Found ${tables.length} free table(s) satisfying party size.`;
        tableHint.className = "text-success fw-bold small mt-1";
      }
    })
    .catch(err => {
      tableHint.textContent = "Error checking tables: " + err;
      tableHint.className = "text-danger fw-bold small mt-1";
    });
}

// Populate Reservation Edit Modal
function openEditReservationModal(id, guests, slot, status) {
  document.getElementById('edit_res_id').value = id;
  document.getElementById('edit_res_guests').value = guests;
  document.getElementById('edit_res_slot').value = slot;
  document.getElementById('edit_res_status').value = status;
  const modal = new bootstrap.Modal(document.getElementById('editReservationModal'));
  modal.show();
}
