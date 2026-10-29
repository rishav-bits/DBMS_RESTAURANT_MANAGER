-- ============================================================================
-- DA3: Modern Database Technology Extension
-- Database: SurrealDB (Multi-Model NewSQL Database)
-- Script: surreal_schema.surql
-- Description: Schema definition for Restaurant Table Reservation & Food Ordering
--              Demonstrates Multi-Model capabilities:
--              1. Document Store (Schemaless JSON objects with rich attributes)
--              2. Graph Relations (First-class edges with properties, NO JOINs)
--              3. ACID Transactions (Strict consistency for table bookings)
--              4. Real-time Live Queries (LIVE SELECT for kitchen display)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. NAMESPACE & DATABASE INITIALIZATION
-- ----------------------------------------------------------------------------
DEFINE NAMESPACE restaurant_ns;
DEFINE DATABASE restaurant_db;

USE NS restaurant_ns DB restaurant_db;

-- ----------------------------------------------------------------------------
-- 2. SCHEMAFULL DOCUMENT TABLES (CORE ENTITIES)
-- ----------------------------------------------------------------------------

-- Restaurant Table
DEFINE TABLE restaurant SCHEMAFULL;
DEFINE FIELD name ON TABLE restaurant TYPE string;
DEFINE FIELD address ON TABLE restaurant TYPE string;
DEFINE FIELD phone ON TABLE restaurant TYPE string;
DEFINE FIELD cuisine_types ON TABLE restaurant TYPE array;
DEFINE FIELD operating_hours ON TABLE restaurant TYPE object;
DEFINE FIELD operating_hours.opening ON TABLE restaurant TYPE string;
DEFINE FIELD operating_hours.closing ON TABLE restaurant TYPE string;
DEFINE FIELD created_at ON TABLE restaurant TYPE datetime DEFAULT time::now();

-- Dining Table Entity
DEFINE TABLE dining_table SCHEMAFULL;
DEFINE FIELD table_number ON TABLE dining_table TYPE string;
DEFINE FIELD capacity ON TABLE dining_table TYPE int;
DEFINE FIELD is_available ON TABLE dining_table TYPE bool DEFAULT true;
DEFINE FIELD location_section ON TABLE dining_table TYPE string; -- 'Indoor', 'Terrace', 'Private'
DEFINE FIELD restaurant ON TABLE dining_table TYPE record<restaurant>;

-- Menu Item (Rich Document with Nested Dietary Flags & Options)
DEFINE TABLE menu_item SCHEMAFULL;
DEFINE FIELD name ON TABLE menu_item TYPE string;
DEFINE FIELD description ON TABLE menu_item TYPE string;
DEFINE FIELD category ON TABLE menu_item TYPE string; -- 'Starters', 'Main Course', 'Desserts', 'Beverages'
DEFINE FIELD price ON TABLE menu_item TYPE float;
DEFINE FIELD is_available ON TABLE menu_item TYPE bool DEFAULT true;
DEFINE FIELD preparation_time_mins ON TABLE menu_item TYPE int DEFAULT 20;
DEFINE FIELD dietary_profile ON TABLE menu_item TYPE object;
DEFINE FIELD dietary_profile.is_veg ON TABLE menu_item TYPE bool;
DEFINE FIELD dietary_profile.is_vegan ON TABLE menu_item TYPE bool;
DEFINE FIELD dietary_profile.is_gluten_free ON TABLE menu_item TYPE bool;
DEFINE FIELD dietary_profile.spice_level ON TABLE menu_item TYPE string; -- 'Mild', 'Medium', 'Hot', 'Extra Hot'
DEFINE FIELD allergens ON TABLE menu_item TYPE array; -- ['Dairy', 'Gluten', 'Nuts']
DEFINE FIELD restaurant ON TABLE menu_item TYPE record<restaurant>;

-- Customer Entity
DEFINE TABLE customer SCHEMAFULL;
DEFINE FIELD name ON TABLE customer TYPE string;
DEFINE FIELD email ON TABLE customer TYPE string ASSERT string::is::email($value);
DEFINE FIELD phone ON TABLE customer TYPE string;
DEFINE FIELD loyalty_points ON TABLE customer TYPE int DEFAULT 0;
DEFINE FIELD dining_preferences ON TABLE customer TYPE object;
DEFINE FIELD dining_preferences.preferred_cuisine ON TABLE customer TYPE string;
DEFINE FIELD dining_preferences.dietary_restriction ON TABLE customer TYPE string;
DEFINE FIELD created_at ON TABLE customer TYPE datetime DEFAULT time::now();
DEFINE INDEX idx_cust_email ON TABLE customer COLUMNS email UNIQUE;

-- Staff Entity
DEFINE TABLE staff SCHEMAFULL;
DEFINE FIELD name ON TABLE staff TYPE string;
DEFINE FIELD role ON TABLE staff TYPE string; -- 'MANAGER', 'CHEF', 'WAITER', 'RECEPTIONIST'
DEFINE FIELD phone ON TABLE staff TYPE string;
DEFINE FIELD salary ON TABLE staff TYPE float;
DEFINE FIELD restaurant ON TABLE staff TYPE record<restaurant>;

-- ----------------------------------------------------------------------------
-- 3. GRAPH RELATION TABLES (EDGES WITH PROPERTIES)
-- ----------------------------------------------------------------------------

-- Relation 1: Customer -> reserved -> Dining Table
-- Graph edge representing a table booking with status and time slot
DEFINE TABLE reserved SCHEMAFULL TYPE RELATION FROM customer TO dining_table;
DEFINE FIELD reservation_date ON TABLE reserved TYPE datetime;
DEFINE FIELD time_slot ON TABLE reserved TYPE string; -- '12:00-14:00', '19:00-21:00'
DEFINE FIELD number_of_guests ON TABLE reserved TYPE int;
DEFINE FIELD status ON TABLE reserved TYPE string DEFAULT 'BOOKED'; -- 'BOOKED', 'CHECKED_IN', 'COMPLETED', 'CANCELLED'
DEFINE FIELD special_request ON TABLE reserved TYPE string;
DEFINE FIELD created_at ON TABLE reserved TYPE datetime DEFAULT time::now();

-- Relation 2: Customer -> ordered -> Menu Item
-- Graph edge representing a food item order with quantity & customizations
DEFINE TABLE ordered SCHEMAFULL TYPE RELATION FROM customer TO menu_item;
DEFINE FIELD order_id ON TABLE ordered TYPE string;
DEFINE FIELD quantity ON TABLE ordered TYPE int DEFAULT 1;
DEFINE FIELD unit_price ON TABLE ordered TYPE float;
DEFINE FIELD subtotal ON TABLE ordered TYPE float;
DEFINE FIELD customization ON TABLE ordered TYPE object; -- { "spice": "Hot", "extra_cheese": true }
DEFINE FIELD order_status ON TABLE ordered TYPE string DEFAULT 'PLACED'; -- 'PLACED', 'PREPARING', 'SERVED', 'DELIVERED'
DEFINE FIELD ordered_at ON TABLE ordered TYPE datetime DEFAULT time::now();

-- Relation 3: Menu Item -> pairs_with -> Menu Item
-- Knowledge Graph edge representing co-ordering affinity between dishes
DEFINE TABLE pairs_with SCHEMAFULL TYPE RELATION FROM menu_item TO menu_item;
DEFINE FIELD affinity_score ON TABLE pairs_with TYPE float; -- 0.0 to 1.0 co-occurrence confidence
DEFINE FIELD co_order_count ON TABLE pairs_with TYPE int;
DEFINE FIELD recommendation_reason ON TABLE pairs_with TYPE string;

-- Relation 4: Dining Table -> adjacent_to -> Dining Table
-- Spatial graph edge for party merging and seating optimization
DEFINE TABLE adjacent_to SCHEMAFULL TYPE RELATION FROM dining_table TO dining_table;
DEFINE FIELD distance_meters ON TABLE adjacent_to TYPE float;
DEFINE FIELD can_merge ON TABLE adjacent_to TYPE bool DEFAULT true;

-- ----------------------------------------------------------------------------
-- 4. LIVE QUERY TRIGGER (FOR REAL-TIME KITCHEN DISPLAY)
-- ----------------------------------------------------------------------------
-- In SurrealDB, web clients or backend listeners execute:
-- LIVE SELECT * FROM ordered WHERE order_status = 'PLACED';
-- The database pushes notifications via WebSockets whenever new orders arrive.
