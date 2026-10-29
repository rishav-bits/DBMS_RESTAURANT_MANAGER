-- ============================================================================
-- DA3: Modern Database Technology Extension
-- Database: SurrealDB (Multi-Model NewSQL Database)
-- Script: surreal_data.surql
-- Description: Realistic sample dataset populating SurrealDB records & graph edges.
--              Includes nested JSON documents and first-class graph relationships.
-- ============================================================================

USE NS restaurant_ns DB restaurant_db;

-- ----------------------------------------------------------------------------
-- 1. RESTAURANTS (Document records)
-- ----------------------------------------------------------------------------
CREATE restaurant:r1 SET
    name = 'The Royal Tandoor',
    address = '42 Heritage Boulevard, Indiranagar, Bengaluru',
    phone = '+91 98450 11223',
    cuisine_types = ['North Indian', 'Mughlai', 'Tandoor'],
    operating_hours = { opening: '11:00', closing: '23:00' };

CREATE restaurant:r2 SET
    name = 'Spice Garden Bistro',
    address = '18 Palmgrove Avenue, Alwarpet, Chennai',
    phone = '+91 98410 44556',
    cuisine_types = ['South Indian', 'Chettinad', 'Vegetarian'],
    operating_hours = { opening: '07:00', closing: '22:30' };

CREATE restaurant:r3 SET
    name = 'Saffron Bay Coastal Kitchen',
    address = '7 Marine Promenade, Bandra West, Mumbai',
    phone = '+91 98200 77889',
    cuisine_types = ['Coastal', 'Seafood', 'Goan'],
    operating_hours = { opening: '12:00', closing: '23:30' };

-- ----------------------------------------------------------------------------
-- 2. DINING TABLES (Spatial records with section)
-- ----------------------------------------------------------------------------
CREATE dining_table:t101 SET table_number = 'T-101', capacity = 2, is_available = true, location_section = 'Indoor AC', restaurant = restaurant:r1;
CREATE dining_table:t102 SET table_number = 'T-102', capacity = 2, is_available = true, location_section = 'Indoor AC', restaurant = restaurant:r1;
CREATE dining_table:t103 SET table_number = 'T-103', capacity = 4, is_available = true, location_section = 'Terrace Garden', restaurant = restaurant:r1;
CREATE dining_table:t104 SET table_number = 'T-104', capacity = 4, is_available = true, location_section = 'Terrace Garden', restaurant = restaurant:r1;
CREATE dining_table:t105 SET table_number = 'T-105', capacity = 6, is_available = true, location_section = 'Private Dining', restaurant = restaurant:r1;
CREATE dining_table:t106 SET table_number = 'T-106', capacity = 8, is_available = true, location_section = 'Family Hall', restaurant = restaurant:r1;

CREATE dining_table:t201 SET table_number = 'SG-01', capacity = 2, is_available = true, location_section = 'Courtyard', restaurant = restaurant:r2;
CREATE dining_table:t202 SET table_number = 'SG-02', capacity = 4, is_available = true, location_section = 'Courtyard', restaurant = restaurant:r2;
CREATE dining_table:t203 SET table_number = 'SG-03', capacity = 4, is_available = true, location_section = 'Indoor AC', restaurant = restaurant:r2;
CREATE dining_table:t204 SET table_number = 'SG-04', capacity = 6, is_available = true, location_section = 'Indoor AC', restaurant = restaurant:r2;

CREATE dining_table:t301 SET table_number = 'SB-01', capacity = 2, is_available = true, location_section = 'Sea Facing Deck', restaurant = restaurant:r3;
CREATE dining_table:t302 SET table_number = 'SB-02', capacity = 4, is_available = true, location_section = 'Sea Facing Deck', restaurant = restaurant:r3;
CREATE dining_table:t303 SET table_number = 'SB-03', capacity = 6, is_available = true, location_section = 'Main Hall', restaurant = restaurant:r3;

-- ----------------------------------------------------------------------------
-- 3. MENU ITEMS (Rich Documents with Nested Dietary & Allergen Profile)
-- ----------------------------------------------------------------------------
CREATE menu_item:m101 SET
    name = 'Murgh Malai Kebab',
    description = 'Tender chicken marinated in cream, cheese, cardamom, and roasted in tandoor clay oven',
    category = 'Starters',
    price = 380.00,
    preparation_time_mins = 15,
    dietary_profile = { is_veg: false, is_vegan: false, is_gluten_free: true, spice_level: 'Mild' },
    allergens = ['Dairy'],
    restaurant = restaurant:r1;

CREATE menu_item:m102 SET
    name = 'Paneer Tikka Shashlik',
    description = 'Cottage cheese cubes skewered with bell peppers, onions, and glazed with mustard marination',
    category = 'Starters',
    price = 320.00,
    preparation_time_mins = 12,
    dietary_profile = { is_veg: true, is_vegan: false, is_gluten_free: true, spice_level: 'Medium' },
    allergens = ['Dairy', 'Mustard'],
    restaurant = restaurant:r1;

CREATE menu_item:m103 SET
    name = 'Dum Pukht Biryani (Chicken)',
    description = 'Fragrant long-grain basmati rice layered with saffron, ghee, and slow cooked chicken in sealed handi',
    category = 'Main Course',
    price = 450.00,
    preparation_time_mins = 25,
    dietary_profile = { is_veg: false, is_vegan: false, is_gluten_free: true, spice_level: 'Hot' },
    allergens = ['Dairy'],
    restaurant = restaurant:r1;

CREATE menu_item:m104 SET
    name = 'Dal Makhani Heritage',
    description = 'Whole black lentils slow simmered overnight on tandoor coals with butter and vine-ripened tomatoes',
    category = 'Main Course',
    price = 290.00,
    preparation_time_mins = 10,
    dietary_profile = { is_veg: true, is_vegan: false, is_gluten_free: true, spice_level: 'Mild' },
    allergens = ['Dairy'],
    restaurant = restaurant:r1;

CREATE menu_item:m105 SET
    name = 'Garlic Butter Naan',
    description = 'Artisanal leavened flatbread topped with minced garlic, fresh coriander, and melted churned butter',
    category = 'Breads',
    price = 85.00,
    preparation_time_mins = 5,
    dietary_profile = { is_veg: true, is_vegan: false, is_gluten_free: false, spice_level: 'Mild' },
    allergens = ['Gluten', 'Dairy'],
    restaurant = restaurant:r1;

CREATE menu_item:m106 SET
    name = 'Kesari Phirni',
    description = 'Creamy Kashmiri ground rice pudding infused with saffron, green cardamom, and toasted pistachios',
    category = 'Desserts',
    price = 180.00,
    preparation_time_mins = 5,
    dietary_profile = { is_veg: true, is_vegan: false, is_gluten_free: true, spice_level: 'Mild' },
    allergens = ['Dairy', 'Nuts'],
    restaurant = restaurant:r1;

CREATE menu_item:m201 SET
    name = 'Ghee Roast Dosa',
    description = 'Crispy fermented crepe roasted with pure cow ghee, served with 3 coastal chutneys and sambar',
    category = 'Main Course',
    price = 160.00,
    preparation_time_mins = 10,
    dietary_profile = { is_veg: true, is_vegan: false, is_gluten_free: true, spice_level: 'Medium' },
    allergens = ['Dairy'],
    restaurant = restaurant:r2;

CREATE menu_item:m202 SET
    name = 'Chettinad Mushroom Chukka',
    description = 'Button mushrooms pan-tossed in freshly roasted black pepper, fennel, and curry leaves',
    category = 'Starters',
    price = 240.00,
    preparation_time_mins = 12,
    dietary_profile = { is_veg: true, is_vegan: true, is_gluten_free: true, spice_level: 'Extra Hot' },
    allergens = [],
    restaurant = restaurant:r2;

CREATE menu_item:m301 SET
    name = 'Mangalorean Prawn Ghee Roast',
    description = 'Tiger prawns braised in Kundapur chili paste, tamarind, and clarified ghee',
    category = 'Starters',
    price = 520.00,
    preparation_time_mins = 18,
    dietary_profile = { is_veg: false, is_vegan: false, is_gluten_free: true, spice_level: 'Hot' },
    allergens = ['Shellfish', 'Dairy'],
    restaurant = restaurant:r3;

-- ----------------------------------------------------------------------------
-- 4. CUSTOMERS (Rich Documents with Dining Preferences)
-- ----------------------------------------------------------------------------
CREATE customer:c101 SET
    name = 'Aarav Sharma',
    email = 'aarav.sharma@gmail.com',
    phone = '+91 98450 11001',
    loyalty_points = 450,
    dining_preferences = { preferred_cuisine: 'North Indian', dietary_restriction: 'None' };

CREATE customer:c102 SET
    name = 'Priya Natarajan',
    email = 'priya.n@outlook.com',
    phone = '+91 98410 22002',
    loyalty_points = 620,
    dining_preferences = { preferred_cuisine: 'South Indian', dietary_restriction: 'Vegetarian' };

CREATE customer:c103 SET
    name = 'Rohan Kulkarni',
    email = 'rohan.kulkarni@yahoo.com',
    phone = '+91 98200 33003',
    loyalty_points = 890,
    dining_preferences = { preferred_cuisine: 'Coastal', dietary_restriction: 'Gluten-Free' };

CREATE customer:c104 SET
    name = 'Ananya Sen',
    email = 'ananya.sen@gmail.com',
    phone = '+91 98300 44004',
    loyalty_points = 310,
    dining_preferences = { preferred_cuisine: 'North Indian', dietary_restriction: 'No Nuts' };

-- ----------------------------------------------------------------------------
-- 5. GRAPH RELATIONSHIPS (RELATE EDGES: NO JOINS REQUIRED)
-- ----------------------------------------------------------------------------

-- A. Table Reservations (customer -> reserved -> dining_table)
RELATE customer:c101->reserved->dining_table:t103 SET
    reservation_date = '2026-11-05T19:30:00Z',
    time_slot = '19:30-21:30',
    number_of_guests = 4,
    status = 'BOOKED',
    special_request = 'Terrace window seating requested';

RELATE customer:c102->reserved->dining_table:t202 SET
    reservation_date = '2026-11-06T13:00:00Z',
    time_slot = '13:00-14:30',
    number_of_guests = 3,
    status = 'BOOKED',
    special_request = 'High chair for infant';

RELATE customer:c103->reserved->dining_table:t301 SET
    reservation_date = '2026-11-07T20:00:00Z',
    time_slot = '20:00-22:00',
    number_of_guests = 2,
    status = 'CHECKED_IN',
    special_request = 'Anniversary celebration candlelight';

-- B. Food Orders (customer -> ordered -> menu_item)
RELATE customer:c101->ordered->menu_item:m101 SET
    order_id = 'ORD-8001',
    quantity = 2,
    unit_price = 380.00,
    subtotal = 760.00,
    customization = { spice: 'Medium', extra_mint_chutney: true },
    order_status = 'SERVED';

RELATE customer:c101->ordered->menu_item:m103 SET
    order_id = 'ORD-8001',
    quantity = 2,
    unit_price = 450.00,
    subtotal = 900.00,
    customization = { spice: 'Hot', extra_raita: true },
    order_status = 'SERVED';

RELATE customer:c101->ordered->menu_item:m105 SET
    order_id = 'ORD-8001',
    quantity = 4,
    unit_price = 85.00,
    subtotal = 340.00,
    customization = { crispy: true },
    order_status = 'SERVED';

RELATE customer:c104->ordered->menu_item:m101 SET
    order_id = 'ORD-8002',
    quantity = 1,
    unit_price = 380.00,
    subtotal = 380.00,
    customization = { spice: 'Mild' },
    order_status = 'PREPARING';

RELATE customer:c104->ordered->menu_item:m103 SET
    order_id = 'ORD-8002',
    quantity = 1,
    unit_price = 450.00,
    subtotal = 450.00,
    customization = { spice: 'Hot' },
    order_status = 'PREPARING';

RELATE customer:c102->ordered->menu_item:m201 SET
    order_id = 'ORD-8003',
    quantity = 2,
    unit_price = 160.00,
    subtotal = 320.00,
    customization = { crispy: true },
    order_status = 'DELIVERED';

-- C. Knowledge Graph: Menu Item Co-ordering Affinity (pairs_with)
RELATE menu_item:m103->pairs_with->menu_item:m105 SET
    affinity_score = 0.94,
    co_order_count = 148,
    recommendation_reason = '94% of Biryani diners order Garlic Butter Naan';

RELATE menu_item:m103->pairs_with->menu_item:m106 SET
    affinity_score = 0.81,
    co_order_count = 112,
    recommendation_reason = 'Perfect traditional sweet pairing after spicy Biryani';

RELATE menu_item:m101->pairs_with->menu_item:m104 SET
    affinity_score = 0.88,
    co_order_count = 129,
    recommendation_reason = 'Murgh Malai Kebab pairs frequently with rich Dal Makhani';

-- D. Spatial Table Adjacency Graph (adjacent_to for Party Merging)
RELATE dining_table:t103->adjacent_to->dining_table:t104 SET
    distance_meters = 1.2,
    can_merge = true;

RELATE dining_table:t101->adjacent_to->dining_table:t102 SET
    distance_meters = 1.0,
    can_merge = true;
