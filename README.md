# Restaurant Table Reservation & Food Ordering System (DA2)
**Database Systems (BACSE202) · Digital Assignment 2**  
**Team Members:** Rohan Jena (25BCE5616), Rishav Singh (25BCE5224), Khyati Shreya (25BCE5605)

---

## 1. Project Overview
This repository contains the complete, production-ready implementation of **Digital Assignment 2 (DA2)** for the Restaurant Table Reservation & Food Ordering System. The application unifies table reservations, dining floor management, menu catalogs, order workflows, financial payments, and verified diner reviews into a single relational database engine.

### Key Highlights
- **DBMS:** Oracle Database 21c Express Edition (XE) / Oracle Free running natively on `localhost:1521/XEPDB1`.
- **Database Logic:** 12 Normalized Tables (up to BCNF), Primary & Foreign Key integrity constraints, Check constraints, Function-Based Unique Indexes, PL/SQL Functions, Stored Procedures, and a Compound Trigger.
- **Web Interface:** Python 3 + Flask backend connected via `python-oracledb` (thin mode) driving a modern, responsive Dark Glassmorphism interface.
- **CRUD Operations:** Full interactive Insert, Update, and Delete capabilities on Customers, Menu Items, Table Reservations, and Food Orders with real-time Oracle business constraint validation.
- **Analytical Intelligence:** 12 System-Specific queries covering subqueries, multi-table joins, aggregations, analytic ranking functions, database views, and PL/SQL procedures with cursors and `SYS_REFCURSOR`.

---

## 2. Quick Start Guide

### Prerequisites
1. **Oracle Database 21c XE** installed and running on Windows (service `XEPDB1` on port 1521).
2. **Python 3.10+** (tested on Python 3.14).
3. Dependencies installed:
   ```bash
   pip install -r requirements.txt
   ```

### Step 1: Database Setup & Population (One-Click)
Run the provided batch script from the repository root:
```cmd
run_setup.bat
```
*What this script does:*
1. Executes `database_scripts/01_schema.sql` via SQL*Plus to create all 12 tables, constraints, and indexes.
2. Compiles `database_scripts/03_plsql.sql` to build all functions, procedures, compound triggers, and views.
3. Runs `database_scripts/02_data.sql` to populate realistic Indian culinary sample data across 3 restaurants.
4. Seeds user authentication accounts via `python setup_auth.py`.
5. Executes `database_scripts/05_tests.sql` running the automated test suite (verifying **15/15 tests PASS**).

### Step 2: Start Web Application
Run:
```cmd
run_app.bat
```
Or directly via Python:
```bash
python app/app.py
```
Open your browser and navigate to: **[http://localhost:5000](http://localhost:5000)**.

---

## 3. Multi-Role Authentication & Access Control

The application implements a role-based access control (RBAC) architecture with dedicated interfaces for **Customers**, **Restaurant Staff (Receptionist / Floor)**, and **Restaurant Owners**.

### 🔑 Default Demo Accounts

| Role | Account Email | Password | Permissions & Primary Interface |
|---|---|---|---|
| **Customer** | `customer@example.com` | `customer123` | **Personal Dining Hub:** Book tables for self, place orders, view personal billing history, leave verified reviews. |
| **Staff (Receptionist)** | `receptionist@example.com` | `staff123` | **Front Desk Operations:** Guest arrival check-in desk, live table occupancy status, kitchen order pipeline (`PLACED -> PREPARING -> READY -> SERVED`), counter billing. |
| **Owner** | `owner@example.com` | `owner123` | **Executive Overview:** Complete multi-branch overview, customer management, catalog pricing (`sp_set_price`), and all 12 analytical SQL/PL-SQL reports. |

> *Quick Demo:* The `/login` page includes 1-click preset buttons to instantly sign in as Customer, Staff, or Owner.

### 📝 User Registration (`/register`)
- **Account Type Selection:** Users specify their role during signup (**Customer**, **Staff**, or **Owner**).
- **Dynamic Field Display:** 
  - Selecting **Customer** reveals delivery address and contact fields (automatically creates records in `APP_USER` and `CUSTOMER`).
  - Selecting **Staff** reveals restaurant branch assignment and job title selection (e.g. *Receptionist*, *Floor Captain*).
  - Selecting **Owner** sets executive administrative privileges.
- **Persistent Storage:** Stored in Oracle table `APP_USER` (`email UNIQUE`, `password_hash` via Werkzeug scrypt, `role`, `customer_id`, `staff_id`, `restaurant_id`).

### 🛡️ Role Boundaries & Permission Matrix

| Feature / URL | Guest | Customer | Staff (Receptionist) | Owner |
|---|:---:|:---:|:---:|:---:|
| **Landing Portal (`/`)** | Public Info & Roles | Personal Dining Hub | Front Desk & Kitchen | Executive Analytics |
| **Registration (`/register`)** | ✅ Open | ✅ Open | ✅ Open | ✅ Open |
| **Login / Logout (`/login`, `/logout`)** | ✅ Open | ✅ Open | ✅ Open | ✅ Open |
| **Account Profile (`/profile`)** | ❌ (Redirects) | ✅ Personal Details | ✅ Staff Assignment | ✅ Executive Details |
| **Table Reservations (`/reservations`)** | ❌ (Redirects) | View/Book Own | View/Manage Branch | Full Management |
| **Food Orders (`/orders`)** | ❌ (Redirects) | View/Order Own | Manage Kitchen/Bill | Full Management |
| **Menu Catalog (`/menu`)** | ❌ (Redirects) | View Menu Only | View Menu Only | ✅ Add/Edit & Set Price |
| **Customer Directory (`/customers`)** | ❌ (Denied) | ❌ (Access Denied) | ❌ (Access Denied) | ✅ Full CRUD |
| **12 Analytical Reports (`/reports`)** | ❌ (Denied) | ❌ (Access Denied) | ❌ (Access Denied) | ✅ Full Access |

---

## 3. Relational Schema Architecture (BCNF Normalized)

All tables use synthetic identity primary keys (`NUMBER GENERATED ALWAYS AS IDENTITY`).

```
                              ┌──────────────┐
                              │   CUSTOMER   │
                              └──────┬───────┘
                                     │ 1:N
             ┌───────────────────────┼──────────────────────┐
             │ 1:N                   │ 1:N                  │ 1:N
      ┌──────▼───────┐        ┌──────▼───────┐       ┌──────▼──────┐
      │ RESERVATION  │        │    ORDERS    │       │   REVIEW    │
      └──────▲───────┘        └──────┬───────┘       └──────▲──────┘
             │                       │ 1:N                  │
             │ N:1                   ├──────────────┐       │ 1:1
      ┌──────┴───────┐        ┌──────▼───────┐ ┌────▼───────┐│
      │ DINING_TABLE │        │  ORDER_ITEM  │ │  PAYMENT   ││
      └──────▲───────┘        └──────▲───────┘ └────────────┘│
             │                       │                      │
             │ N:1                   │ N:1                  │
      ┌──────┴───────┐        ┌──────┴───────┐              │
      │  RESTAURANT  │◄───────┤  MENU_ITEM   ├──────────────┘
      └──────┬───────┘        └──────▲───────┘
             │ 1:N                   │ N:1
      ┌──────▼───────┐        ┌──────┴───────┐
      │    STAFF     │        │   CATEGORY   │
      └──────────────┘        └──────────────┘
                                     ▲
                                     │ 1:N
                              ┌──────┴───────┐
                              │PRICE_HISTORY │
                              └──────────────┘
```

### Table Inventory (12 Tables)
1. `CUSTOMER`: Diner identity, email (UNIQUE), contact details, registration date.
2. `RESTAURANT`: Restaurant branch details, cuisine type, operating hours.
3. `DINING_TABLE`: Table number (UNIQUE per restaurant), seating capacity, availability flag.
4. `CATEGORY`: Dish groupings (Starters, Main Course, Biryani, Breads, Desserts, Beverages).
5. `MENU_ITEM`: Catalog item details, veg/non-veg flag, preparation time.
6. `PRICE_HISTORY`: Historical and active prices (`end_date IS NULL` indicates current price).
7. `RESERVATION`: Table bookings with guest count, slot, and status (`BOOKED`, `CONFIRMED`, `CANCELLED`, `COMPLETED`).
8. `ORDERS`: Dining orders with workflow status and total amount maintained by compound trigger.
9. `ORDER_ITEM`: Dishes and quantities added to an order (`UNIQUE(order_id, item_id)`).
10. `PAYMENT`: Financial settlement (`1:1` with order), method (`UPI`, `CARD`, `CASH`, `COUPON`), amount matching order total.
11. `STAFF`: Restaurant personnel roster (Head Chef, General Manager, Waiter, Captain).
12. `REVIEW`: Verified dining reviews (rating 1 to 5) tied strictly to served/delivered, paid orders.

---

## 4. Business Rules & Enforcement Mechanisms

| Rule ID | Business Constraint | Enforcement Mechanism |
|---|---|---|
| **BR-1** | No double-booking for the same table, date, and slot | Function-based unique index `uq_res_active_slot` on non-cancelled rows & procedure `sp_make_reservation` |
| **BR-2** | Guest count must not exceed table seating capacity | Row trigger `trg_reservation_guest_check` & procedure `sp_make_reservation` |
| **BR-3** | Reservation date cannot be in the past | Validation in procedure `sp_make_reservation` |
| **BR-4** | Dish ordered must belong to the order's restaurant | Validation in procedure `sp_add_order_item` |
| **BR-5** | Unique dish per order line (quantity increments if re-added) | `UNIQUE(order_id, item_id)` & procedure `sp_add_order_item` |
| **BR-6** | Line item price matches price on order date | Function `fn_price_on(item_id, order_date)` |
| **BR-7** | Order total equals sum of quantity x price on order date | **Compound trigger `trg_order_item_total`** (avoids mutating-table `ORA-04091`) |
| **BR-8** | Order status moves strictly forward along workflow | Procedure `sp_update_order_status` (`PLACED -> PREPARING -> READY -> SERVED -> DELIVERED`) |
| **BR-9** | Exactly one payment per order, matching total amount | `UNIQUE(order_id)` & row trigger `trg_payment_validate` |
| **BR-10**| Review requires served/delivered order and successful payment | Row trigger `trg_review_validate` |
| **BR-11**| Unique customer email | `UNIQUE(email)` constraint on `CUSTOMER` |
| **BR-12**| At most one open price per dish in catalog | Function-based unique index `uq_item_active_price` & procedure `sp_set_price` |

---

## 5. The 12 System Queries Summary

| # | Business Question | Technique / Implementation |
|---|---|---|
| **1** | Free dining tables satisfying party size for restaurant, date, and slot | `NOT EXISTS` correlated subquery against active reservations |
| **2** | Top 5 best-selling dishes across restaurants by quantity sold | Multi-table `JOIN`, `GROUP BY`, `SUM`, `FETCH FIRST 5 ROWS ONLY` |
| **3** | Monthly revenue per restaurant from settled (`SUCCESS`) payments | `GROUP BY` with `TO_CHAR(date, 'YYYY-MM')`, `SUM` |
| **4** | Repeat customers with > 2 orders and total expenditure | `GROUP BY` with `HAVING COUNT(order_id) > 2`, `SUM` |
| **5** | Average diner rating and total review count per restaurant | `LEFT OUTER JOIN`, `NVL`, `ROUND`, `AVG`, `COUNT` |
| **6** | Active dish price and number of historical price revisions | `PRICE_HISTORY` with `end_date IS NULL` & correlated scalar subquery |
| **7** | Customers who reserved a table but never placed an order | Correlated `NOT EXISTS` against `ORDERS` with `EXISTS` on `RESERVATION` |
| **8** | Unpaid or pending orders requiring financial reconciliation | Querying database view `v_order_summary` with `NULL`/status filter |
| **9** | Catalog menu items that have never been ordered | `NOT EXISTS` subquery against `ORDER_ITEM` |
| **10**| Premier, most expensive menu item at each restaurant | Analytic function `RANK() OVER (PARTITION BY restaurant_id ORDER BY price DESC)` |
| **11**| Daily executive sales & performance summary | **PL/SQL Procedure `sp_daily_sales_report`** using explicit cursor & `DBMS_OUTPUT` |
| **12**| Customer spend analytics with dynamic order count threshold | **PL/SQL Procedure `sp_customer_spend_report`** returning `SYS_REFCURSOR` |

---

## 6. Live Evaluator Demo Journey (5-Minute Walkthrough)

1. **Dashboard (`/`):**
   - View real-time row counts across all 12 tables and aggregate revenue KPI.
2. **Customers Module (`/customers`):**
   - Click **Add Customer** (`INSERT`). Create a customer.
   - Click **Edit** (`UPDATE`). Update phone number or address.
   - Attempt duplicate email creation to observe clean Oracle unique constraint flash alert.
   - Click **Delete** (`DELETE`). Confirm record removal.
3. **Menu & Pricing (`/menu`):**
   - Filter menu items by restaurant.
   - Click **Price** on any dish to execute `sp_set_price` (`UPDATE/INSERT`). Enter a new price.
   - Click **Revisions** to inspect the `PRICE_HISTORY` audit trail modal.
4. **Reservations Module (`/reservations`):**
   - Click **Make Reservation**. Select date, slot, party size. Observe live table availability query populating available tables with sufficient capacity.
   - Click **Cancel** on any booking to execute `sp_cancel_reservation` and verify the table is instantly freed for rebooking.
5. **Orders & Billing (`/orders` & `/orders/<id>`):**
   - Create an order. On the detail screen, add dishes (`INSERT` via `sp_add_order_item`).
   - Notice the **running order total** updates automatically in real-time via Oracle compound trigger `trg_order_item_total`.
   - Advance status along the workflow (`PLACED -> PREPARING -> READY -> SERVED -> DELIVERED`).
   - Settle payment with exact amount verification via `trg_payment_validate`.
6. **Reviews Module (`/reviews`):**
   - Submit a verified review for the completed order with star rating and feedback.
7. **Reports Module (`/reports`):**
   - Interactively browse and execute all 12 queries.
   - Test Query 11 to view captured `DBMS_OUTPUT` from `sp_daily_sales_report`.
   - Test Query 12 to query the `SYS_REFCURSOR` with a custom minimum orders filter.

## 7. Project Structure & Directory Guide

```text
DBMS DA - RESTAURANT MANAGEMENT/
├── app/                        # Web Application
│   ├── app.py                  # Flask server, API endpoints & business logic
│   ├── db.py                   # Oracle database connection pool & query executor
│   ├── static/                 # Static frontend assets (Neo-Brutalism CSS & JS)
│   └── templates/              # HTML templates (Customer, Staff, Owner portals)
├── database_scripts/           # Oracle 21c SQL & PL/SQL Database Scripts
│   ├── 01_schema.sql           # DDL: 12 normalized tables, keys, constraints & indexes
│   ├── 02_data.sql             # Realistic Indian culinary dataset (300+ rows)
│   ├── 03_plsql.sql            # Procedures, functions, packages, and compound triggers
│   ├── 04_queries.sql          # 12 advanced system queries & analytics
│   ├── 05_tests.sql            # Automated SQL*Plus PL/SQL verification suite (15 tests)
│   └── 06_auth_schema.sql      # DDL: Multi-role authentication table (APP_USER)
├── tests/                      # Automated Python Test Suites
│   ├── test_auth_roles.py      # Multi-role authentication & RBAC boundary tests
│   └── test_e2e.py             # End-to-end browser workflows & CRUD integration tests
├── .env                        # Local database credentials & configuration
├── .env.example                # Example environment variable template
├── requirements.txt            # Python dependencies (Flask, oracledb, python-dotenv, etc.)
├── run_app.bat                 # 1-Click launcher for the web application
├── run_setup.bat               # 1-Click database setup script
├── setup_auth.py               # Script to seed default Customer, Staff, and Owner accounts
└── README.md                   # Complete project documentation & setup guide
```
