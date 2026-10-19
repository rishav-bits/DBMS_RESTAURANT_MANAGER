-- ============================================================================
-- DA2: Restaurant Table Reservation & Food Ordering System
-- Script: 01_schema.sql
-- Description: DDL to create all 12 tables, primary keys, foreign keys,
--              check constraints, unique constraints, and indexes.
-- Target DBMS: Oracle Database 21c XE / Free
-- ============================================================================

SET SERVEROUTPUT ON;

-- ----------------------------------------------------------------------------
-- 1. Safely drop existing objects in dependency order
-- ----------------------------------------------------------------------------
BEGIN
    FOR t IN (
        SELECT table_name FROM user_tables 
        WHERE table_name IN (
            'PRICE_HISTORY', 'ORDER_ITEM', 'PAYMENT', 'REVIEW',
            'RESERVATION', 'ORDERS', 'MENU_ITEM', 'STAFF',
            'DINING_TABLE', 'CATEGORY', 'RESTAURANT', 'CUSTOMER'
        )
    ) LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Dropped table: ' || t.table_name);
    END LOOP;
END;
/

-- ----------------------------------------------------------------------------
-- 2. CUSTOMER
-- ----------------------------------------------------------------------------
CREATE TABLE CUSTOMER (
    customer_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR2(100) NOT NULL,
    email            VARCHAR2(100) NOT NULL,
    phone            VARCHAR2(20),
    address          VARCHAR2(255),
    reg_date         DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_customer_email UNIQUE (email)
);

-- ----------------------------------------------------------------------------
-- 3. RESTAURANT
-- ----------------------------------------------------------------------------
CREATE TABLE RESTAURANT (
    restaurant_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR2(100) NOT NULL,
    address          VARCHAR2(255) NOT NULL,
    phone            VARCHAR2(20) NOT NULL,
    cuisine_type     VARCHAR2(50) NOT NULL,
    opening_hour     VARCHAR2(5) NOT NULL,
    closing_hour     VARCHAR2(5) NOT NULL
);

-- ----------------------------------------------------------------------------
-- 4. DINING_TABLE
-- ----------------------------------------------------------------------------
CREATE TABLE DINING_TABLE (
    table_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    restaurant_id    NUMBER NOT NULL,
    table_number     VARCHAR2(20) NOT NULL,
    capacity         NUMBER(3) NOT NULL,
    is_available     CHAR(1) DEFAULT 'Y' NOT NULL,
    CONSTRAINT fk_dining_table_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id),
    CONSTRAINT chk_table_capacity CHECK (capacity > 0),
    CONSTRAINT chk_table_available CHECK (is_available IN ('Y', 'N')),
    CONSTRAINT uq_rest_table UNIQUE (restaurant_id, table_number)
);

-- ----------------------------------------------------------------------------
-- 5. CATEGORY
-- ----------------------------------------------------------------------------
CREATE TABLE CATEGORY (
    category_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name             VARCHAR2(100) NOT NULL,
    description      VARCHAR2(255),
    CONSTRAINT uq_category_name UNIQUE (name)
);

-- ----------------------------------------------------------------------------
-- 6. MENU_ITEM
-- ----------------------------------------------------------------------------
CREATE TABLE MENU_ITEM (
    item_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    restaurant_id    NUMBER NOT NULL,
    category_id      NUMBER NOT NULL,
    name             VARCHAR2(100) NOT NULL,
    description      VARCHAR2(255),
    is_veg           CHAR(1) DEFAULT 'Y' NOT NULL,
    preparation_time NUMBER(3) NOT NULL,
    CONSTRAINT fk_menu_item_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id),
    CONSTRAINT fk_menu_item_cat FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id),
    CONSTRAINT chk_menu_item_veg CHECK (is_veg IN ('Y', 'N')),
    CONSTRAINT chk_menu_item_preptime CHECK (preparation_time > 0)
);

-- ----------------------------------------------------------------------------
-- 7. PRICE_HISTORY
-- ----------------------------------------------------------------------------
CREATE TABLE PRICE_HISTORY (
    history_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    item_id          NUMBER NOT NULL,
    price            NUMBER(10, 2) NOT NULL,
    start_date       DATE NOT NULL,
    end_date         DATE,
    CONSTRAINT fk_price_hist_item FOREIGN KEY (item_id) REFERENCES MENU_ITEM(item_id) ON DELETE CASCADE,
    CONSTRAINT chk_price_positive CHECK (price >= 0),
    CONSTRAINT chk_price_dates CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Function-based unique index: at most one open (end_date IS NULL) price per item
CREATE UNIQUE INDEX uq_item_active_price ON PRICE_HISTORY (
    CASE WHEN end_date IS NULL THEN item_id END
);

-- ----------------------------------------------------------------------------
-- 8. RESERVATION
-- ----------------------------------------------------------------------------
CREATE TABLE RESERVATION (
    reservation_id   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id      NUMBER NOT NULL,
    table_id         NUMBER NOT NULL,
    restaurant_id    NUMBER NOT NULL,
    reservation_date DATE NOT NULL,
    time_slot        VARCHAR2(20) NOT NULL,
    number_of_guests NUMBER(3) NOT NULL,
    status           VARCHAR2(20) DEFAULT 'BOOKED' NOT NULL,
    CONSTRAINT fk_reservation_cust FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
    CONSTRAINT fk_reservation_table FOREIGN KEY (table_id) REFERENCES DINING_TABLE(table_id),
    CONSTRAINT fk_reservation_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id),
    CONSTRAINT chk_reservation_guests CHECK (number_of_guests > 0),
    CONSTRAINT chk_reservation_status CHECK (status IN ('BOOKED', 'CONFIRMED', 'CANCELLED', 'COMPLETED')),
    CONSTRAINT chk_reservation_slot CHECK (time_slot IN ('12:00-14:00', '14:00-16:00', '19:00-21:00', '21:00-23:00'))
);

-- Function-based unique index: prevent double bookings for non-cancelled reservations
CREATE UNIQUE INDEX uq_res_active_slot ON RESERVATION (
    CASE WHEN status <> 'CANCELLED' THEN table_id END,
    CASE WHEN status <> 'CANCELLED' THEN reservation_date END,
    CASE WHEN status <> 'CANCELLED' THEN time_slot END
);

-- ----------------------------------------------------------------------------
-- 9. ORDERS
-- ----------------------------------------------------------------------------
CREATE TABLE ORDERS (
    order_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id      NUMBER NOT NULL,
    restaurant_id    NUMBER NOT NULL,
    order_date       DATE DEFAULT SYSDATE NOT NULL,
    status           VARCHAR2(20) DEFAULT 'PLACED' NOT NULL,
    total_amount     NUMBER(10, 2) DEFAULT 0 NOT NULL,
    CONSTRAINT fk_orders_cust FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
    CONSTRAINT fk_orders_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id),
    CONSTRAINT chk_orders_status CHECK (status IN ('PLACED', 'PREPARING', 'READY', 'SERVED', 'DELIVERED', 'CANCELLED')),
    CONSTRAINT chk_orders_total CHECK (total_amount >= 0)
);

-- ----------------------------------------------------------------------------
-- 10. ORDER_ITEM
-- ----------------------------------------------------------------------------
CREATE TABLE ORDER_ITEM (
    order_item_id    NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id         NUMBER NOT NULL,
    item_id          NUMBER NOT NULL,
    quantity         NUMBER(3) DEFAULT 1 NOT NULL,
    CONSTRAINT fk_order_item_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_order_item_item FOREIGN KEY (item_id) REFERENCES MENU_ITEM(item_id),
    CONSTRAINT chk_order_item_qty CHECK (quantity > 0),
    CONSTRAINT uq_order_item UNIQUE (order_id, item_id)
);

-- ----------------------------------------------------------------------------
-- 11. PAYMENT
-- ----------------------------------------------------------------------------
CREATE TABLE PAYMENT (
    payment_id       NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    order_id         NUMBER NOT NULL,
    amount           NUMBER(10, 2) NOT NULL,
    payment_method   VARCHAR2(20) NOT NULL,
    payment_date     DATE DEFAULT SYSDATE NOT NULL,
    status           VARCHAR2(20) DEFAULT 'PENDING' NOT NULL,
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT uq_payment_order UNIQUE (order_id),
    CONSTRAINT chk_payment_amount CHECK (amount >= 0),
    CONSTRAINT chk_payment_method CHECK (payment_method IN ('CASH', 'CARD', 'UPI', 'COUPON')),
    CONSTRAINT chk_payment_status CHECK (status IN ('PENDING', 'SUCCESS', 'FAILED'))
);

-- ----------------------------------------------------------------------------
-- 12. STAFF
-- ----------------------------------------------------------------------------
CREATE TABLE STAFF (
    staff_id         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    restaurant_id    NUMBER NOT NULL,
    name             VARCHAR2(100) NOT NULL,
    role             VARCHAR2(50) NOT NULL,
    contact          VARCHAR2(20) NOT NULL,
    CONSTRAINT fk_staff_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id)
);

-- ----------------------------------------------------------------------------
-- 13. REVIEW
-- ----------------------------------------------------------------------------
CREATE TABLE REVIEW (
    review_id        NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    customer_id      NUMBER NOT NULL,
    restaurant_id    NUMBER NOT NULL,
    order_id         NUMBER NOT NULL,
    rating           NUMBER(1) NOT NULL,
    review_comment   VARCHAR2(1000),
    review_date      DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT fk_review_cust FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
    CONSTRAINT fk_review_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id),
    CONSTRAINT fk_review_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id),
    CONSTRAINT uq_review_order UNIQUE (order_id),
    CONSTRAINT chk_review_rating CHECK (rating BETWEEN 1 AND 5)
);

-- ----------------------------------------------------------------------------
-- 14. APP_USER (Authentication & Role Access Control)
-- ----------------------------------------------------------------------------
CREATE TABLE APP_USER (
    user_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email            VARCHAR2(100) NOT NULL CONSTRAINT uq_app_user_email UNIQUE,
    password_hash    VARCHAR2(255) NOT NULL,
    full_name        VARCHAR2(100) NOT NULL,
    phone            VARCHAR2(20),
    role             VARCHAR2(20) NOT NULL,
    staff_title      VARCHAR2(50),
    restaurant_id    NUMBER,
    customer_id      NUMBER,
    staff_id         NUMBER,
    created_at       DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT chk_app_user_role CHECK (role IN ('CUSTOMER', 'STAFF', 'OWNER')),
    CONSTRAINT fk_app_user_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id),
    CONSTRAINT fk_app_user_cust FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id),
    CONSTRAINT fk_app_user_staff FOREIGN KEY (staff_id) REFERENCES STAFF(staff_id)
);

-- ----------------------------------------------------------------------------
-- 15. Performance Indexes on Foreign Keys & Roles
-- ----------------------------------------------------------------------------
CREATE INDEX idx_dining_table_rest ON DINING_TABLE(restaurant_id);
CREATE INDEX idx_menu_item_rest    ON MENU_ITEM(restaurant_id);
CREATE INDEX idx_menu_item_cat     ON MENU_ITEM(category_id);
CREATE INDEX idx_price_hist_item   ON PRICE_HISTORY(item_id);
CREATE INDEX idx_res_cust          ON RESERVATION(customer_id);
CREATE INDEX idx_res_table         ON RESERVATION(table_id);
CREATE INDEX idx_res_rest          ON RESERVATION(restaurant_id);
CREATE INDEX idx_orders_cust       ON ORDERS(customer_id);
CREATE INDEX idx_orders_rest       ON ORDERS(restaurant_id);
CREATE INDEX idx_order_item_order  ON ORDER_ITEM(order_id);
CREATE INDEX idx_order_item_item   ON ORDER_ITEM(item_id);
CREATE INDEX idx_staff_rest        ON STAFF(restaurant_id);
CREATE INDEX idx_review_cust       ON REVIEW(customer_id);
CREATE INDEX idx_review_rest       ON REVIEW(restaurant_id);
CREATE INDEX idx_app_user_role     ON APP_USER(role);

PROMPT Schema created successfully.
EXIT;
