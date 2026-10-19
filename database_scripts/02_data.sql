-- ============================================================================
-- DA2: Restaurant Table Reservation & Food Ordering System
-- Script: 02_data.sql
-- Description: Realistic sample dataset populating all 12 tables.
--              Includes rich price histories, reservations, orders,
--              payments, and reviews designed to validate all 12 queries.
-- Target DBMS: Oracle Database 21c XE / Free
-- ============================================================================

SET SERVEROUTPUT ON;
SET DEFINE OFF;

-- ----------------------------------------------------------------------------
-- 1. RESTAURANTS (3 Restaurants)
-- ----------------------------------------------------------------------------
INSERT INTO RESTAURANT (name, address, phone, cuisine_type, opening_hour, closing_hour)
VALUES ('The Royal Tandoor', '42 Heritage Boulevard, Indiranagar, Bengaluru', '+91 98450 11223', 'North Indian & Mughlai', '11:00', '23:00');

INSERT INTO RESTAURANT (name, address, phone, cuisine_type, opening_hour, closing_hour)
VALUES ('Spice Garden Bistro', '18 Palmgrove Avenue, Alwarpet, Chennai', '+91 98410 44556', 'South Indian & Chettinad', '07:00', '22:30');

INSERT INTO RESTAURANT (name, address, phone, cuisine_type, opening_hour, closing_hour)
VALUES ('Saffron Bay Coastal Kitchen', '7 Marine Promenade, Bandra West, Mumbai', '+91 98200 77889', 'Coastal & Seafood', '12:00', '23:30');

-- ----------------------------------------------------------------------------
-- 2. DINING TABLES (7 per restaurant = 21 tables)
-- ----------------------------------------------------------------------------
-- The Royal Tandoor (restaurant_id = 1)
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-101', 2, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-102', 2, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-103', 4, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-104', 4, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-105', 6, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-106', 8, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (1, 'T-107', 4, 'N');

-- Spice Garden Bistro (restaurant_id = 2)
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-01', 2, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-02', 4, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-03', 4, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-04', 6, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-05', 6, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-06', 8, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (2, 'SG-07', 2, 'Y');

-- Saffron Bay Coastal Kitchen (restaurant_id = 3)
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-A1', 2, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-A2', 2, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-B1', 4, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-B2', 4, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-C1', 6, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-D1', 8, 'Y');
INSERT INTO DINING_TABLE (restaurant_id, table_number, capacity, is_available) VALUES (3, 'SB-D2', 10, 'Y');

-- ----------------------------------------------------------------------------
-- 3. CATEGORIES (6 Categories)
-- ----------------------------------------------------------------------------
INSERT INTO CATEGORY (name, description) VALUES ('Starters & Appetizers', 'Crispy, skewered and clay oven special appetizers');
INSERT INTO CATEGORY (name, description) VALUES ('Main Course Curries', 'Rich slow-cooked gravies and regional specialties');
INSERT INTO CATEGORY (name, description) VALUES ('Biryani & Pulao', 'Fragrant aged basmati rice cooked on dum');
INSERT INTO CATEGORY (name, description) VALUES ('Breads & Accompaniments', 'Freshly baked tandoori naans, rotis, and raitas');
INSERT INTO CATEGORY (name, description) VALUES ('Desserts & Sweets', 'Decadent traditional and contemporary Indian sweets');
INSERT INTO CATEGORY (name, description) VALUES ('Beverages & Coolers', 'Refreshing lassis, fresh juices, and specialty mocktails');

-- ----------------------------------------------------------------------------
-- 4. MENU ITEMS (28 Menu Items across 3 Restaurants)
-- ----------------------------------------------------------------------------
-- Restaurant 1: The Royal Tandoor
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 1, 'Murgh Malai Tikka', 'Tender chicken morsels in rich cream and cardamom marinade', 'N', 20);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 1, 'Paneer Tikka Shashlik', 'Chargrilled cottage cheese cubes with bell peppers and onion', 'Y', 18);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 1, 'Galouti Kebab', 'Melt-in-mouth smoked lamb patties infused with 16 royal spices', 'N', 25);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 2, 'Butter Chicken Aslam', 'Smoked shredded tandoori chicken simmered in creamy tomato gravy', 'N', 22);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 2, 'Dal Makhani Bukhara', 'Black lentils slow cooked overnight with butter and cream', 'Y', 15);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 2, 'Nalli Nihari Gosht', 'Slow-braised lamb shanks in an aromatic spiced stock gravy', 'N', 30);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 3, 'Awadhi Dum Gosht Biryani', 'Kolkata-Awadhi style mutton biryani with aromatic saffron rice', 'N', 25);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 4, 'Garlic Butter Naan', 'Tandoor baked leavened bread brushed with garlic butter', 'Y', 8);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 5, 'Shahi Tukda Royal', 'Crispy saffron soaked bread pudding garnished with silver leaf', 'Y', 12);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (1, 6, 'Kesariya Badam Lassi', 'Chilled churned yogurt with crushed almonds and saffron strands', 'Y', 8);

-- Restaurant 2: Spice Garden Bistro
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 1, 'Guntur Chilli Paneer', 'Wok-tossed spicy paneer with fiery Andhra red chillies', 'Y', 15);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 1, 'Kozhi Varuval', 'Crisp Chettinad pan-fried country chicken with curry leaves', 'N', 20);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 2, 'Chettinad Kozhi Curry', 'Peppery chicken curry spiced with stone-ground Chettinad masala', 'N', 22);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 2, 'Ennai Kathirikai Kulambu', 'Baby brinjals cooked in a tangy sesame tamarind gravy', 'Y', 18);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 3, 'Dindigul Thalappakatti Biryani', 'Seeraga samba rice cooked with tender mutton and pepper spices', 'N', 25);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 4, 'Malabar Parotta (2 pcs)', 'Flaky layered Kerala parottas fresh off the griddle', 'Y', 10);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 5, 'Elaneer Payasam', 'Tender coconut pudding made with thickened coconut milk', 'Y', 10);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 6, 'Filter Kaapi Frappe', 'Decoction brewed Kumbakonam coffee served chilled', 'Y', 6);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (2, 2, 'Paneer Kurma Special', 'Mild fragrant cashew and coconut gravy with cottage cheese', 'Y', 18);

-- Restaurant 3: Saffron Bay Coastal Kitchen
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 1, 'Koliwada Prawns Fry', 'Crunchy batter-fried coastal tiger prawns with carom seeds', 'N', 18);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 1, 'Surmai Rawa Fry', 'Kingfish steaks crusted in seasoned semolina and pan roasted', 'N', 22);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 2, 'Goan Prawn Balchao', 'Fiery and tangy prawn pickle curry cooked in toddy vinegar', 'N', 25);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 2, 'Mangalorean Fish Gassi', 'Pomfret cooked in freshly ground roasted coconut and Byadgi chilli', 'N', 25);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 3, 'Malvani Crab Pulao', 'Deshelled mud crab meat tossed with fragrant short grain rice', 'N', 28);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 4, 'Appam Trio with Stew', 'Bowl-shaped fermented rice pancakes with mild coconut vegetable stew', 'Y', 15);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 5, 'Bebinca Layer Cake', 'Traditional 7-layer Goan dessert baked with coconut milk and ghee', 'Y', 12);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 6, 'Sol Kadhi Cooler', 'Digestive pink drink made with kokum extract and fresh coconut milk', 'Y', 5);
INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
VALUES (3, 1, 'Squid Calamari Masala', 'Squid rings tossed in spicy coastal dry roasted masala', 'N', 20);

-- ----------------------------------------------------------------------------
-- 5. PRICE HISTORY (Initial prices + 10 items with older revised prices)
-- ----------------------------------------------------------------------------
-- Older closed prices (at least 8 items with revisions):
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (1, 420.00, DATE '2026-01-01', DATE '2026-05-31');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (4, 480.00, DATE '2026-01-01', DATE '2026-06-15');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (5, 340.00, DATE '2026-01-01', DATE '2026-06-30');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (7, 580.00, DATE '2026-01-01', DATE '2026-07-31');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (8, 75.00,  DATE '2026-01-01', DATE '2026-08-15');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (13, 380.00, DATE '2026-01-01', DATE '2026-07-15');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (15, 450.00, DATE '2026-01-01', DATE '2026-08-01');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (20, 480.00, DATE '2026-01-01', DATE '2026-06-30');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (22, 540.00, DATE '2026-01-01', DATE '2026-07-20');
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (23, 620.00, DATE '2026-01-01', DATE '2026-08-10');

-- Current open prices (end_date IS NULL) for all 28 items:
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (1, 460.00, DATE '2026-06-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (2, 380.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (3, 520.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (4, 520.00, DATE '2026-06-16', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (5, 380.00, DATE '2026-07-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (6, 680.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (7, 640.00, DATE '2026-08-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (8, 90.00,  DATE '2026-08-16', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (9, 240.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (10, 160.00, DATE '2026-01-01', NULL);

INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (11, 340.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (12, 420.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (13, 420.00, DATE '2026-07-16', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (14, 310.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (15, 490.00, DATE '2026-08-02', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (16, 110.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (17, 210.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (18, 140.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (19, 330.00, DATE '2026-01-01', NULL);

INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (20, 520.00, DATE '2026-07-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (21, 580.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (22, 590.00, DATE '2026-07-21', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (23, 680.00, DATE '2026-08-11', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (24, 650.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (25, 260.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (26, 250.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (27, 120.00, DATE '2026-01-01', NULL);
INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date) VALUES (28, 460.00, DATE '2026-01-01', NULL);

-- ----------------------------------------------------------------------------
-- 6. CUSTOMERS (18 Customers)
-- ----------------------------------------------------------------------------
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Aarav Sharma', 'aarav.sharma@example.com', '+91 98111 22334', 'Flat 402, Oakwood Apts, Bengaluru', DATE '2026-01-10');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Diya Iyer', 'diya.iyer@example.com', '+91 98222 33445', '14 Temple Street, Chennai', DATE '2026-01-15');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Kabir Patel', 'kabir.patel@example.com', '+91 98333 44556', '702 Sea View Heights, Bandra, Mumbai', DATE '2026-02-01');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Ananya Deshmukh', 'ananya.d@example.com', '+91 98444 55667', '23 Park Residency, Pune', DATE '2026-02-12');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Rohan Varma', 'rohan.varma@example.com', '+91 98555 66778', '89 Jubilee Hills, Hyderabad', DATE '2026-03-01');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Sneha Kulkarni', 'sneha.k@example.com', '+91 98666 77889', '12 Mayur Vihar, Delhi', DATE '2026-03-15');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Vikramaditya Nair', 'vikram.nair@example.com', '+91 98777 88990', '5 Panampilly Nagar, Kochi', DATE '2026-04-05');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Pooja Banerjee', 'pooja.b@example.com', '+91 98888 99001', '34 Southern Avenue, Kolkata', DATE '2026-04-20');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Ishaan Malhotra', 'ishaan.m@example.com', '+91 98999 11223', '56 Golf Course Road, Gurugram', DATE '2026-05-02');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Meera Sundaram', 'meera.s@example.com', '+91 99000 22334', '8 Gandhi Nagar, Bengaluru', DATE '2026-05-18');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Arjun Reddy', 'arjun.reddy@example.com', '+91 99111 33445', '11 Banjara Hills, Hyderabad', DATE '2026-06-01');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Tanvi Joshi', 'tanvi.joshi@example.com', '+91 99222 44556', '6 Shivaji Park, Dadar, Mumbai', DATE '2026-06-15');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Aditya Singhania', 'aditya.s@example.com', '+91 99333 55667', '7 Civil Lines, Jaipur', DATE '2026-07-01');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Kavya Pillai', 'kavya.pillai@example.com', '+91 99444 66778', '42 Anna Nagar, Chennai', DATE '2026-07-15');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Nikhil Chopra', 'nikhil.c@example.com', '+91 99555 77889', '19 Koregaon Park, Pune', DATE '2026-08-01');
-- Customers with reservations but NO orders (Query 7 targets):
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Siddharth Rao', 'siddharth.rao@example.com', '+91 99666 88990', '9 MG Road, Bengaluru', DATE '2026-08-10');
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Gauri Sen', 'gauri.sen@example.com', '+91 99777 99001', '15 Salt Lake, Kolkata', DATE '2026-08-15');
-- Customer with NO reservations and NO orders:
INSERT INTO CUSTOMER (name, email, phone, address, reg_date) VALUES ('Manish Kapoor', 'manish.k@example.com', '+91 99888 11223', '3 Sector 17, Chandigarh', DATE '2026-09-01');

-- ----------------------------------------------------------------------------
-- 7. STAFF (10 Staff Members across 3 Restaurants)
-- ----------------------------------------------------------------------------
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (1, 'Vikas Khanna Jr.', 'Head Chef', '+91 98451 00001');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (1, 'Rajesh Menon', 'General Manager', '+91 98451 00002');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (1, 'Sunil Gurung', 'Captain & Host', '+91 98451 00003');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (1, 'Amit Rawat', 'Senior Waiter', '+91 98451 00004');

INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (2, 'Muthuswamy Chettiar', 'Master Chef', '+91 98411 00005');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (2, 'Karthik Subramanian', 'Floor Manager', '+91 98411 00006');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (2, 'Saravanan Perumal', 'Senior Steward', '+91 98411 00007');

INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (3, 'Maria Fernandes', 'Executive Chef', '+91 98201 00008');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (3, 'Prashant Sawant', 'Restaurant Manager', '+91 98201 00009');
INSERT INTO STAFF (restaurant_id, name, role, contact) VALUES (3, 'Deepak Patil', 'Captain', '+91 98201 00010');

-- ----------------------------------------------------------------------------
-- 8. RESERVATIONS (22 Reservations)
-- ----------------------------------------------------------------------------
-- The Royal Tandoor
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (1, 3, 1, DATE '2026-06-10', '19:00-21:00', 4, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (2, 5, 1, DATE '2026-06-15', '21:00-23:00', 6, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (3, 1, 1, DATE '2026-07-02', '12:00-14:00', 2, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (4, 4, 1, DATE '2026-07-12', '19:00-21:00', 4, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (5, 6, 1, DATE '2026-08-05', '19:00-21:00', 8, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (6, 2, 1, DATE '2026-08-20', '14:00-16:00', 2, 'CANCELLED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (7, 2, 1, DATE '2026-08-20', '14:00-16:00', 2, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (8, 3, 1, DATE '2026-10-15', '19:00-21:00', 4, 'CONFIRMED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (9, 5, 1, DATE '2026-10-18', '21:00-23:00', 5, 'BOOKED');

-- Spice Garden Bistro
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (2, 9, 2, DATE '2026-06-18', '12:00-14:00', 4, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (10, 10, 2, DATE '2026-07-08', '19:00-21:00', 4, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (11, 11, 2, DATE '2026-07-25', '19:00-21:00', 6, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (12, 8, 2, DATE '2026-08-14', '12:00-14:00', 2, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (13, 13, 2, DATE '2026-08-28', '21:00-23:00', 7, 'CANCELLED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (14, 12, 2, DATE '2026-10-20', '19:00-21:00', 6, 'BOOKED');

-- Saffron Bay Coastal Kitchen
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (3, 17, 3, DATE '2026-06-25', '19:00-21:00', 4, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (12, 19, 3, DATE '2026-07-15', '21:00-23:00', 6, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (15, 18, 3, DATE '2026-08-02', '12:00-14:00', 4, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (1, 20, 3, DATE '2026-08-22', '19:00-21:00', 8, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (5, 16, 3, DATE '2026-10-22', '19:00-21:00', 2, 'CONFIRMED');

-- Reservations for Siddharth and Gauri (who NEVER placed orders):
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (16, 1, 1, DATE '2026-09-05', '12:00-14:00', 2, 'COMPLETED');
INSERT INTO RESERVATION (customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status)
VALUES (17, 8, 2, DATE '2026-09-12', '19:00-21:00', 2, 'BOOKED');

-- ----------------------------------------------------------------------------
-- 9. ORDERS (28 Orders across 3 Restaurants)
-- Note: total_amount is automatically recalculated by compound trigger trg_order_item_total!
-- ----------------------------------------------------------------------------
-- Restaurant 1: The Royal Tandoor
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (1, 1, DATE '2026-06-10', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (2, 1, DATE '2026-06-15', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (3, 1, DATE '2026-07-02', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (4, 1, DATE '2026-07-12', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (5, 1, DATE '2026-08-05', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (7, 1, DATE '2026-08-20', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (1, 1, DATE '2026-08-25', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (1, 1, DATE '2026-09-02', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (8, 1, DATE '2026-09-10', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (9, 1, DATE '2026-09-20', 'SERVED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (10, 1, DATE '2026-10-01', 'PREPARING', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (11, 1, DATE '2026-10-05', 'CANCELLED', 0);

-- Restaurant 2: Spice Garden Bistro
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (2, 2, DATE '2026-06-18', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (10, 2, DATE '2026-07-08', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (11, 2, DATE '2026-07-25', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (12, 2, DATE '2026-08-14', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (2, 2, DATE '2026-08-22', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (2, 2, DATE '2026-09-05', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (13, 2, DATE '2026-09-15', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (14, 2, DATE '2026-09-28', 'SERVED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (4, 2, DATE '2026-10-02', 'READY', 0);

-- Restaurant 3: Saffron Bay Coastal Kitchen
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (3, 3, DATE '2026-06-25', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (12, 3, DATE '2026-07-15', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (15, 3, DATE '2026-08-02', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (1, 3, DATE '2026-08-22', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (3, 3, DATE '2026-09-08', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (12, 3, DATE '2026-09-25', 'DELIVERED', 0);
INSERT INTO ORDERS (customer_id, restaurant_id, order_date, status, total_amount) VALUES (5, 3, DATE '2026-10-08', 'PLACED', 0);

-- ----------------------------------------------------------------------------
-- 10. ORDER ITEMS (65 Line Items)
-- Trigger trg_order_item_total will maintain orders.total_amount!
-- ----------------------------------------------------------------------------
-- Order 1: Aarav at Royal Tandoor (2026-06-10) -> items: 1(460), 4(480 old), 8(75 old)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (1, 1, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (1, 4, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (1, 8, 4);

-- Order 2: Diya at Royal Tandoor (2026-06-15) -> items: 2(380), 5(340 old), 8(75 old)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (2, 2, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (2, 5, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (2, 8, 4);

-- Order 3: Kabir at Royal Tandoor (2026-07-02) -> items: 3(520), 7(580 old), 10(160)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (3, 3, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (3, 7, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (3, 10, 2);

-- Order 4: Ananya at Royal Tandoor (2026-07-12) -> items: 1(460), 4(520 new), 8(75 old), 9(240)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (4, 1, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (4, 4, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (4, 8, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (4, 9, 2);

-- Order 5: Rohan at Royal Tandoor (2026-08-05) -> items: 6(680), 7(640 new), 8(75 old), 10(160)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (5, 6, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (5, 7, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (5, 8, 4);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (5, 10, 4);

-- Order 6: Vikram at Royal Tandoor (2026-08-20) -> items: 1(460), 5(380 new), 8(90 new)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (6, 1, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (6, 5, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (6, 8, 2);

-- Order 7: Aarav at Royal Tandoor (2026-08-25) -> items: 4(520 new), 7(640 new)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (7, 4, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (7, 7, 1);

-- Order 8: Aarav at Royal Tandoor (2026-09-02) -> items: 1(460), 8(90 new), 10(160)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (8, 1, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (8, 8, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (8, 10, 2);

-- Order 9: Pooja at Royal Tandoor (2026-09-10) -> items: 2(380), 5(380 new), 9(240)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (9, 2, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (9, 5, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (9, 9, 2);

-- Order 10: Ishaan at Royal Tandoor (2026-09-20) -> items: 3(520), 6(680)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (10, 3, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (10, 6, 1);

-- Order 11: Meera at Royal Tandoor (2026-10-01) -> items: 1(460), 8(90 new)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (11, 1, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (11, 8, 2);

-- Order 12: Arjun at Royal Tandoor (cancelled) -> items: 7(640 new)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (12, 7, 1);

-- Spice Garden Bistro orders:
-- Order 13: Diya at Spice Garden (2026-06-18) -> items: 11(340), 13(380 old), 16(110)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (13, 11, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (13, 13, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (13, 16, 2);

-- Order 14: Meera at Spice Garden (2026-07-08) -> items: 12(420), 15(450 old), 18(140)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (14, 12, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (14, 15, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (14, 18, 2);

-- Order 15: Arjun at Spice Garden (2026-07-25) -> items: 13(420 new), 16(110), 17(210)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (15, 13, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (15, 16, 4);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (15, 17, 2);

-- Order 16: Tanvi at Spice Garden (2026-08-14) -> items: 14(310), 16(110), 18(140)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (16, 14, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (16, 16, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (16, 18, 1);

-- Order 17: Diya at Spice Garden (2026-08-22) -> items: 15(490 new), 17(210)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (17, 15, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (17, 17, 1);

-- Order 18: Diya at Spice Garden (2026-09-05) -> items: 12(420), 16(110)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (18, 12, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (18, 16, 2);

-- Order 19: Aditya at Spice Garden (2026-09-15) -> items: 13(420 new), 15(490 new)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (19, 13, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (19, 15, 1);

-- Order 20: Kavya at Spice Garden (2026-09-28) -> items: 11(340), 14(310)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (20, 11, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (20, 14, 1);

-- Order 21: Ananya at Spice Garden (2026-10-02) -> items: 15(490 new), 18(140)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (21, 15, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (21, 18, 1);

-- Saffron Bay Coastal Kitchen orders:
-- Order 22: Kabir at Saffron Bay (2026-06-25) -> items: 20(480 old), 22(540 old), 27(120)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (22, 20, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (22, 22, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (22, 27, 2);

-- Order 23: Tanvi at Saffron Bay (2026-07-15) -> items: 21(580), 23(620 old), 25(260)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (23, 21, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (23, 23, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (23, 25, 2);

-- Order 24: Nikhil at Saffron Bay (2026-08-02) -> items: 20(520 new), 24(650), 26(250)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (24, 20, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (24, 24, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (24, 26, 1);

-- Order 25: Aarav at Saffron Bay (2026-08-22) -> items: 22(590 new), 23(680 new), 27(120)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (25, 22, 2);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (25, 23, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (25, 27, 4);

-- Order 26: Kabir at Saffron Bay (2026-09-08) -> items: 20(520 new), 21(580)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (26, 20, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (26, 21, 1);

-- Order 27: Tanvi at Saffron Bay (2026-09-25) -> items: 24(650), 27(120)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (27, 24, 1);
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (27, 27, 2);

-- Order 28: Rohan at Saffron Bay (2026-10-08) -> items: 21(580)
INSERT INTO ORDER_ITEM (order_id, item_id, quantity) VALUES (28, 21, 1);

-- ----------------------------------------------------------------------------
-- 11. PAYMENTS (for most orders, matching orders.total_amount)
-- ----------------------------------------------------------------------------
-- Helper block to insert payments with exact total_amount
DECLARE
    PROCEDURE pay(p_ord NUMBER, p_method VARCHAR2, p_status VARCHAR2, p_dt DATE) IS
        v_tot NUMBER;
    BEGIN
        SELECT total_amount INTO v_tot FROM ORDERS WHERE order_id = p_ord;
        INSERT INTO PAYMENT (order_id, amount, payment_method, payment_date, status)
        VALUES (p_ord, v_tot, p_method, p_dt, p_status);
    END;
BEGIN
    pay(1,  'UPI',    'SUCCESS', DATE '2026-06-10');
    pay(2,  'CARD',   'SUCCESS', DATE '2026-06-15');
    pay(3,  'UPI',    'SUCCESS', DATE '2026-07-02');
    pay(4,  'CARD',   'SUCCESS', DATE '2026-07-12');
    pay(5,  'CASH',   'SUCCESS', DATE '2026-08-05');
    pay(6,  'UPI',    'SUCCESS', DATE '2026-08-20');
    pay(7,  'CARD',   'SUCCESS', DATE '2026-08-25');
    pay(8,  'UPI',    'SUCCESS', DATE '2026-09-02');
    pay(9,  'CARD',   'SUCCESS', DATE '2026-09-10');
    pay(10, 'UPI',    'PENDING', DATE '2026-09-20');
    -- Order 11 has NO payment yet (missing payment)
    -- Order 12 is cancelled, no payment

    pay(13, 'UPI',    'SUCCESS', DATE '2026-06-18');
    pay(14, 'CARD',   'SUCCESS', DATE '2026-07-08');
    pay(15, 'UPI',    'SUCCESS', DATE '2026-07-25');
    pay(16, 'COUPON', 'SUCCESS', DATE '2026-08-14');
    pay(17, 'UPI',    'SUCCESS', DATE '2026-08-22');
    pay(18, 'CASH',   'SUCCESS', DATE '2026-09-05');
    pay(19, 'CARD',   'SUCCESS', DATE '2026-09-15');
    pay(20, 'UPI',    'FAILED',  DATE '2026-09-28');
    -- Order 21 has NO payment yet (missing payment)

    pay(22, 'CARD',   'SUCCESS', DATE '2026-06-25');
    pay(23, 'UPI',    'SUCCESS', DATE '2026-07-15');
    pay(24, 'CARD',   'SUCCESS', DATE '2026-08-02');
    pay(25, 'UPI',    'SUCCESS', DATE '2026-08-22');
    pay(26, 'CARD',   'SUCCESS', DATE '2026-09-08');
    pay(27, 'UPI',    'SUCCESS', DATE '2026-09-25');
    -- Order 28 is placed, no payment
END;
/

-- ----------------------------------------------------------------------------
-- 12. REVIEWS (16 Reviews tied to DELIVERED/SERVED orders with SUCCESS payment)
-- ----------------------------------------------------------------------------
INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (1, 1, 1, 5, 'The Murgh Malai Tikka was tender and the Aslam butter chicken was sublime! Royal dining experience.', DATE '2026-06-11');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (2, 1, 2, 5, 'The Dal Bukhara slow-cooked texture is unmatched. Truly lived up to its reputation.', DATE '2026-06-16');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (3, 1, 3, 4, 'Galouti kebabs melt instantly. Fragrant Awadhi biryani with perfect saffron aroma.', DATE '2026-07-03');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (4, 1, 4, 5, 'Excellent service and crispy hot garlic naans. Loved the Shahi Tukda dessert!', DATE '2026-07-13');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (5, 1, 5, 5, 'Nalli Nihari was rich and velvety. Generous portions for our family gathering.', DATE '2026-08-06');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (7, 1, 6, 4, 'Very good food, prompt table service and pleasant ambience in Indiranagar.', DATE '2026-08-21');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (1, 1, 7, 5, 'Consistent top quality every single visit. The butter chicken gravy is unmatched.', DATE '2026-08-26');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (8, 1, 9, 4, 'Loved the Paneer Tikka and fresh naans. Fast service even on busy evenings.', DATE '2026-09-11');

-- Spice Garden Bistro Reviews:
INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (2, 2, 13, 4, 'Authentic Chettinad spices! Flaky parottas and fiery curry made my day.', DATE '2026-06-19');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (10, 2, 14, 4, 'Thalappakatti biryani with seeraga samba rice had great aroma. Nice cold coffee.', DATE '2026-07-09');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (11, 2, 15, 3, 'Spices were a bit too hot for the kids, but authentic Chettinad flavors.', DATE '2026-07-26');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (12, 2, 16, 4, 'Loved the Ennai Kathirikai gravy and parotta combination. Great value.', DATE '2026-08-15');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (2, 2, 17, 4, 'The tender coconut Elaneer payasam was fresh and cooling. Must order.', DATE '2026-08-23');

-- Saffron Bay Coastal Kitchen Reviews:
INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (3, 3, 22, 5, 'Koliwada prawns fry was crunchy perfection. Prawn Balchao had nice tang!', DATE '2026-06-26');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (12, 3, 23, 5, 'Surmai Rawa fry and Pomfret Gassi transported us right to coastal Mangalore.', DATE '2026-07-16');

INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
VALUES (1, 3, 25, 5, 'The Sol Kadhi and seafood dishes were extraordinary. Best coastal spot in town.', DATE '2026-08-23');

COMMIT;

-- ----------------------------------------------------------------------------
-- 13. PRINT ROW COUNTS FOR AUDIT AND ACCEPTANCE CHECK
-- ----------------------------------------------------------------------------
PROMPT
PROMPT ========================================================
PROMPT SAMPLE DATA INSERTED - VERIFYING TABLE ROW COUNTS
PROMPT ========================================================
SELECT 'RESTAURANT' AS table_name, COUNT(*) AS row_count FROM RESTAURANT UNION ALL
SELECT 'DINING_TABLE', COUNT(*) FROM DINING_TABLE UNION ALL
SELECT 'CATEGORY', COUNT(*) FROM CATEGORY UNION ALL
SELECT 'MENU_ITEM', COUNT(*) FROM MENU_ITEM UNION ALL
SELECT 'PRICE_HISTORY', COUNT(*) FROM PRICE_HISTORY UNION ALL
SELECT 'CUSTOMER', COUNT(*) FROM CUSTOMER UNION ALL
SELECT 'STAFF', COUNT(*) FROM STAFF UNION ALL
SELECT 'RESERVATION', COUNT(*) FROM RESERVATION UNION ALL
SELECT 'ORDERS', COUNT(*) FROM ORDERS UNION ALL
SELECT 'ORDER_ITEM', COUNT(*) FROM ORDER_ITEM UNION ALL
SELECT 'PAYMENT', COUNT(*) FROM PAYMENT UNION ALL
SELECT 'REVIEW', COUNT(*) FROM REVIEW;

EXIT;
