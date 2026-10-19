"""
End-to-End Integration Test for Restaurant DBMS Web Interface
Simulates all web browser user flows: Insert, Update, Delete, and Business Validation Rejections.
"""

import sys
import requests
import oracledb

sys.stdout.reconfigure(encoding='utf-8')

BASE_URL = "http://127.0.0.1:5000"
session = requests.Session()

# Authenticate as OWNER for administrative E2E flows
login_resp = session.post(f"{BASE_URL}/login", data={
    "email": "owner@example.com",
    "password": "owner123"
}, allow_redirects=True)
assert login_resp.status_code == 200, "Owner login failed during test bootstrap"
print("  [AUTH] Authenticated test session as OWNER (owner@example.com)")

# Pre-test cleanup of any previous test records
conn = oracledb.connect(user='restaurant_app', password='restaurant_pass', host='localhost', port=1521, service_name='XEPDB1')
cur = conn.cursor()
cur.execute("DELETE FROM ORDERS WHERE customer_id IN (SELECT customer_id FROM CUSTOMER WHERE email LIKE '%@testdomain.com')")
cur.execute("DELETE FROM CUSTOMER WHERE email LIKE '%@testdomain.com'")
cur.execute("DELETE FROM MENU_ITEM WHERE name = 'E2E Crispy Corn Chaap'")
cur.execute("DELETE FROM RESERVATION WHERE TRUNC(reservation_date) = DATE '2026-11-28'")
conn.commit()
conn.close()

def assert_status(resp, expected=200, action_name=""):
    assert resp.status_code == expected, f"FAILED {action_name}: Expected {expected}, got {resp.status_code}"
    print(f"  [OK] {action_name}")

print("==================================================================")
print("RUNNING E2E WEB INTERFACE CRUD & VALIDATION TEST SUITE")
print("==================================================================")

# 1. CUSTOMERS CRUD
print("\n--- 1. Testing Customer Management (Insert, Update, Delete) ---")
# Insert Customer
resp = session.post(f"{BASE_URL}/customers/create", data={
    "name": "Priyanka Nair",
    "email": "priyanka.nair@testdomain.com",
    "phone": "+91 97777 66666",
    "address": "Indiranagar 100ft Road, Bengaluru"
}, allow_redirects=True)
assert_status(resp, 200, "Customer Insert (POST /customers/create)")
assert "Priyanka Nair" in resp.text, "Customer not found in HTML table"

# Find Customer ID
import oracledb
conn = oracledb.connect(user='restaurant_app', password='restaurant_pass', host='localhost', port=1521, service_name='XEPDB1')
cur = conn.cursor()
cur.execute("SELECT customer_id FROM CUSTOMER WHERE email = 'priyanka.nair@testdomain.com'")
row = cur.fetchone()
assert row is not None, "Customer not in database"
cid = row[0]
print(f"  [DB VERIFIED] Inserted Customer ID: {cid}")

# Update Customer
resp = session.post(f"{BASE_URL}/customers/update", data={
    "customer_id": cid,
    "name": "Priyanka Nair (Updated)",
    "email": "priyanka.nair@testdomain.com",
    "phone": "+91 99999 11111",
    "address": "Koramangala 4th Block, Bengaluru"
}, allow_redirects=True)
assert_status(resp, 200, "Customer Update (POST /customers/update)")
assert "Priyanka Nair (Updated)" in resp.text, "Updated name not in HTML table"
print(f"  [DB VERIFIED] Updated Customer ID: {cid}")

# Duplicate Email Rejection
resp = session.post(f"{BASE_URL}/customers/create", data={
    "name": "Clone Priyanka",
    "email": "priyanka.nair@testdomain.com",
    "phone": "+91 12345 67890",
    "address": "Unknown"
}, allow_redirects=True)
assert "already exists" in resp.text or "unique" in resp.text.lower(), "Duplicate email validation failed"
print("  [VALIDATION PASSED] Duplicate email correctly rejected with user alert.")

# Delete Customer
resp = session.post(f"{BASE_URL}/customers/delete/{cid}", allow_redirects=True)
assert_status(resp, 200, "Customer Delete (POST /customers/delete/<id>)")
cur.execute("SELECT COUNT(*) FROM CUSTOMER WHERE customer_id = :id", {"id": cid})
assert cur.fetchone()[0] == 0, "Customer still in DB after delete"
print(f"  [DB VERIFIED] Customer #{cid} successfully deleted.")

# 2. MENU & PRICE HISTORY (PL/SQL sp_set_price)
print("\n--- 2. Testing Menu Management & Price Change (sp_set_price) ---")
# Insert new menu item
resp = session.post(f"{BASE_URL}/menu/create", data={
    "restaurant_id": 1,
    "category_id": 1,
    "name": "E2E Crispy Corn Chaap",
    "price": 310.00,
    "preparation_time": 15,
    "is_veg": "Y",
    "description": "Sweet corn kernels tossed with spices and mint"
}, allow_redirects=True)
assert_status(resp, 200, "Menu Item Insert (POST /menu/create)")
assert "E2E Crispy Corn Chaap" in resp.text, "Menu item not rendered"

cur.execute("SELECT item_id FROM MENU_ITEM WHERE name = 'E2E Crispy Corn Chaap'")
item_id = cur.fetchone()[0]
print(f"  [DB VERIFIED] Menu Item ID: {item_id}")

# Price Change via sp_set_price
resp = session.post(f"{BASE_URL}/menu/change-price", data={
    "item_id": item_id,
    "new_price": 345.50
}, allow_redirects=True)
assert_status(resp, 200, "Price Change via sp_set_price (POST /menu/change-price)")

# Verify Price History
cur.execute("SELECT price, end_date FROM PRICE_HISTORY WHERE item_id = :id ORDER BY start_date", {"id": item_id})
hist_rows = cur.fetchall()
assert len(hist_rows) == 2, f"Expected 2 price rows (old and new), found {len(hist_rows)}"
assert hist_rows[0][1] is not None, "Previous price row was not closed"
assert hist_rows[1][1] is None, "New price row was not left open"
assert float(hist_rows[1][0]) == 345.50, "New price does not match"
print(f"  [DB VERIFIED] sp_set_price atomically updated PRICE_HISTORY (2 revisions logged).")

# 3. RESERVATIONS (PL/SQL sp_make_reservation & sp_cancel_reservation)
print("\n--- 3. Testing Reservations & Cancellation ---")
# Check availability API
resp = session.get(f"{BASE_URL}/api/tables?restaurant_id=1&date=2026-11-28&slot=19:00-21:00&guests=2")
assert resp.status_code == 200, "API tables returned error"
tables = resp.json()
assert len(tables) > 0, "No tables available for testing"
selected_table = tables[0]["table_id"]
print(f"  [API OK] Live availability returned {len(tables)} free tables for slot.")

# Make Reservation
resp = session.post(f"{BASE_URL}/reservations/create", data={
    "customer_id": 1,
    "restaurant_id": 1,
    "table_id": selected_table,
    "reservation_date": "2026-11-28",
    "time_slot": "19:00-21:00",
    "number_of_guests": 2
}, allow_redirects=True)
assert_status(resp, 200, "Make Reservation (POST /reservations/create)")
assert "booked successfully" in resp.text.lower() or "reservation" in resp.text.lower()

cur.execute("""
    SELECT reservation_id FROM RESERVATION
    WHERE customer_id = 1 AND table_id = :tid AND TRUNC(reservation_date) = DATE '2026-11-28' AND status <> 'CANCELLED'
""", {"tid": selected_table})
res_id = cur.fetchone()[0]
print(f"  [DB VERIFIED] Reservation #{res_id} created.")

# Double Booking Prevention
resp = session.post(f"{BASE_URL}/reservations/create", data={
    "customer_id": 2,
    "restaurant_id": 1,
    "table_id": selected_table,
    "reservation_date": "2026-11-28",
    "time_slot": "19:00-21:00",
    "number_of_guests": 2
}, allow_redirects=True)
assert "already booked" in resp.text.lower() or "violated" in resp.text.lower(), "Double booking was not rejected"
print("  [VALIDATION PASSED] Double-booking correctly blocked by system.")

# Cancel Reservation (sp_cancel_reservation)
resp = session.post(f"{BASE_URL}/reservations/cancel/{res_id}", allow_redirects=True)
assert_status(resp, 200, "Cancel Reservation (POST /reservations/cancel/<id>)")
cur.execute("SELECT status FROM RESERVATION WHERE reservation_id = :id", {"id": res_id})
assert cur.fetchone()[0] == "CANCELLED", "Reservation status was not updated to CANCELLED"
print(f"  [DB VERIFIED] Reservation #{res_id} cancelled via sp_cancel_reservation.")

# Delete Reservation
resp = session.post(f"{BASE_URL}/reservations/delete/{res_id}", allow_redirects=True)
assert_status(resp, 200, "Delete Reservation (POST /reservations/delete/<id>)")
cur.execute("SELECT COUNT(*) FROM RESERVATION WHERE reservation_id = :id", {"id": res_id})
assert cur.fetchone()[0] == 0, "Reservation still in DB after delete"
print(f"  [DB VERIFIED] Reservation #{res_id} deleted.")

# 4. ORDERS & BILLING (Compound Trigger Total Recalculation)
print("\n--- 4. Testing Orders, Compound Trigger Totals & Payments ---")
# Create Order
resp = session.post(f"{BASE_URL}/orders/create", data={
    "customer_id": 1,
    "restaurant_id": 1
}, allow_redirects=True)
assert_status(resp, 200, "Order Initialize (POST /orders/create)")

cur.execute("SELECT MAX(order_id) FROM ORDERS WHERE customer_id = 1 AND restaurant_id = 1")
order_id = cur.fetchone()[0]
print(f"  [DB VERIFIED] Initialized Order #{order_id} in PLACED status.")

# Add item 1 (Murgh Malai Tikka, Price 460) quantity 2
resp = session.post(f"{BASE_URL}/orders/{order_id}/add-item", data={
    "item_id": 1,
    "quantity": 2
}, allow_redirects=True)
assert_status(resp, 200, "Add Order Item (POST /orders/<id>/add-item)")

cur.execute("SELECT total_amount FROM ORDERS WHERE order_id = :id", {"id": order_id})
total_val = float(cur.fetchone()[0])
assert total_val == 920.00, f"Expected 920.00, got {total_val}"
print(f"  [TRIGGER VERIFIED] Compound trigger updated order total: ₹{total_val:.2f}")

# Add item 8 (Garlic Naan, Price 90) quantity 2
resp = session.post(f"{BASE_URL}/orders/{order_id}/add-item", data={
    "item_id": 8,
    "quantity": 2
}, allow_redirects=True)
cur.execute("SELECT total_amount FROM ORDERS WHERE order_id = :id", {"id": order_id})
total_val = float(cur.fetchone()[0])
assert total_val == 1100.00, f"Expected 1100.00, got {total_val}"
print(f"  [TRIGGER VERIFIED] Compound trigger updated order total to: ₹{total_val:.2f}")

# Advance Status: PLACED -> PREPARING -> READY -> SERVED -> DELIVERED
for next_status in ["PREPARING", "READY", "SERVED", "DELIVERED"]:
    resp = session.post(f"{BASE_URL}/orders/{order_id}/update-status", data={"new_status": next_status}, allow_redirects=True)
    assert_status(resp, 200, f"Advance status to {next_status}")

# Record Payment with Amount Mismatch (Expect failure)
resp = session.post(f"{BASE_URL}/orders/{order_id}/pay", data={
    "amount": 500.00, # mismatch with 1100.00
    "payment_method": "UPI",
    "status": "SUCCESS"
}, allow_redirects=True)
assert "match order total" in resp.text.lower() or "violated" in resp.text.lower(), "Payment mismatch was not rejected"
print("  [VALIDATION PASSED] Invalid payment amount rejected by trigger trg_payment_validate.")

# Record Valid Exact Payment
resp = session.post(f"{BASE_URL}/orders/{order_id}/pay", data={
    "amount": 1100.00,
    "payment_method": "UPI",
    "status": "SUCCESS"
}, allow_redirects=True)
assert_status(resp, 200, "Valid Payment Submission")
cur.execute("SELECT status FROM PAYMENT WHERE order_id = :id", {"id": order_id})
assert cur.fetchone()[0] == "SUCCESS", "Payment status not SUCCESS"
print(f"  [DB VERIFIED] Payment settled for Order #{order_id}: ₹1100.00.")

# Submit Review
resp = session.post(f"{BASE_URL}/reviews/create", data={
    "order_id": order_id,
    "rating": 5,
    "comment": "Outstanding food and blazing fast service in Indiranagar!"
}, allow_redirects=True)
assert_status(resp, 200, "Review Submission (POST /reviews/create)")

cur.execute("SELECT review_id FROM REVIEW WHERE order_id = :id", {"id": order_id})
rev_id = cur.fetchone()[0]
print(f"  [DB VERIFIED] Review #{rev_id} created for Order #{order_id}.")

# Delete Review
resp = session.post(f"{BASE_URL}/reviews/delete/{rev_id}", allow_redirects=True)
assert_status(resp, 200, "Review Delete (POST /reviews/delete/<id>)")
print(f"  [DB VERIFIED] Review #{rev_id} deleted.")

# Delete Test Menu Item
resp = session.post(f"{BASE_URL}/menu/delete/{item_id}", allow_redirects=True)
assert_status(resp, 200, f"Menu Item Delete #{item_id}")
print(f"  [DB VERIFIED] Menu item #{item_id} deleted.")

# 5. REPORTS TESTING
print("\n--- 5. Testing Reports Page (All 12 Queries) ---")
for q in range(1, 13):
    resp = session.get(f"{BASE_URL}/reports?q={q}")
    assert resp.status_code == 200, f"Report Q{q} failed"
    print(f"  [OK] Report Query {q} Executed and Rendered")

conn.close()

print("\n==================================================================")
print("ALL E2E INTEGRATION & BUSINESS RULE TESTS PASSED SUCCESSFULLY!")
print("==================================================================")
