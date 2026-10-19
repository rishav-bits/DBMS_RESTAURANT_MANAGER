-- ============================================================================
-- DA2: Restaurant Table Reservation & Food Ordering System
-- Script: 03_plsql.sql
-- Description: PL/SQL Functions, Stored Procedures, Triggers, and Views.
-- Target DBMS: Oracle Database 21c XE / Free
-- ============================================================================

SET SERVEROUTPUT ON;

-- ----------------------------------------------------------------------------
-- 1. FUNCTION: fn_price_on
-- Returns the price of an item valid on a given date from PRICE_HISTORY
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_price_on(
    p_item_id IN NUMBER,
    p_date    IN DATE
) RETURN NUMBER IS
    v_price NUMBER(10, 2);
BEGIN
    SELECT price INTO v_price
    FROM (
        SELECT price
        FROM PRICE_HISTORY
        WHERE item_id = p_item_id
          AND TRUNC(p_date) >= TRUNC(start_date)
          AND (end_date IS NULL OR TRUNC(p_date) <= TRUNC(end_date))
        ORDER BY start_date DESC
    )
    WHERE ROWNUM = 1;

    RETURN v_price;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        -- Fallback to the latest known price if order date precedes start_date
        BEGIN
            SELECT price INTO v_price
            FROM (
                SELECT price
                FROM PRICE_HISTORY
                WHERE item_id = p_item_id
                ORDER BY start_date DESC
            )
            WHERE ROWNUM = 1;
            RETURN v_price;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RETURN 0;
        END;
END fn_price_on;
/

-- ----------------------------------------------------------------------------
-- 2. FUNCTION: fn_restaurant_avg_rating
-- Returns the average rating of a restaurant rounded to 1 decimal place
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_restaurant_avg_rating(
    p_restaurant_id IN NUMBER
) RETURN NUMBER IS
    v_avg NUMBER(3, 1);
BEGIN
    SELECT ROUND(NVL(AVG(rating), 0), 1)
    INTO v_avg
    FROM REVIEW
    WHERE restaurant_id = p_restaurant_id;

    RETURN v_avg;
END fn_restaurant_avg_rating;
/

-- ----------------------------------------------------------------------------
-- 3. FUNCTION: fn_table_is_free
-- Checks if a dining table is available and not booked for a date and slot
-- Returns 1 if free, 0 if occupied or unavailable
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_table_is_free(
    p_table_id IN NUMBER,
    p_date     IN DATE,
    p_slot     IN VARCHAR2
) RETURN NUMBER IS
    v_available CHAR(1);
    v_booked_count NUMBER;
BEGIN
    -- Check table general availability
    SELECT is_available INTO v_available
    FROM DINING_TABLE
    WHERE table_id = p_table_id;

    IF v_available <> 'Y' THEN
        RETURN 0;
    END IF;

    -- Check if active booking exists
    SELECT COUNT(*) INTO v_booked_count
    FROM RESERVATION
    WHERE table_id = p_table_id
      AND TRUNC(reservation_date) = TRUNC(p_date)
      AND time_slot = p_slot
      AND status <> 'CANCELLED';

    IF v_booked_count > 0 THEN
        RETURN 0;
    ELSE
        RETURN 1;
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END fn_table_is_free;
/

-- ----------------------------------------------------------------------------
-- 4. PROCEDURE: sp_make_reservation
-- Validates party size, slot availability, and date before booking
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_make_reservation(
    p_customer_id    IN  NUMBER,
    p_table_id       IN  NUMBER,
    p_date           IN  DATE,
    p_slot           IN  VARCHAR2,
    p_guests         IN  NUMBER,
    p_reservation_id OUT NUMBER
) IS
    v_capacity       NUMBER;
    v_restaurant_id  NUMBER;
    v_is_free        NUMBER;
BEGIN
    -- Business Rule: Date cannot be in the past
    IF TRUNC(p_date) < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Reservation date cannot be in the past.');
    END IF;

    -- Fetch table capacity and restaurant
    BEGIN
        SELECT capacity, restaurant_id INTO v_capacity, v_restaurant_id
        FROM DINING_TABLE
        WHERE table_id = p_table_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20015, 'Dining table not found.');
    END;

    -- Business Rule: Guests must not exceed capacity
    IF p_guests > v_capacity THEN
        RAISE_APPLICATION_ERROR(-20002, 'Guest count (' || p_guests || ') exceeds table capacity (' || v_capacity || ').');
    END IF;

    -- Business Rule: Table must be free
    v_is_free := fn_table_is_free(p_table_id, p_date, p_slot);
    IF v_is_free = 0 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Table is already booked or unavailable for time slot ' || p_slot || '.');
    END IF;

    -- Insert reservation
    INSERT INTO RESERVATION (
        customer_id, table_id, restaurant_id, reservation_date, time_slot, number_of_guests, status
    ) VALUES (
        p_customer_id, p_table_id, v_restaurant_id, TRUNC(p_date), p_slot, p_guests, 'BOOKED'
    ) RETURNING reservation_id INTO p_reservation_id;

    COMMIT;
END sp_make_reservation;
/

-- ----------------------------------------------------------------------------
-- 5. PROCEDURE: sp_cancel_reservation
-- Cancels a reservation and frees the table slot
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_cancel_reservation(
    p_reservation_id IN NUMBER
) IS
    v_status VARCHAR2(20);
BEGIN
    SELECT status INTO v_status
    FROM RESERVATION
    WHERE reservation_id = p_reservation_id;

    IF v_status = 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Cannot cancel an already completed reservation.');
    END IF;

    IF v_status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20016, 'Reservation is already cancelled.');
    END IF;

    UPDATE RESERVATION
    SET status = 'CANCELLED'
    WHERE reservation_id = p_reservation_id;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20017, 'Reservation ID not found.');
END sp_cancel_reservation;
/

-- ----------------------------------------------------------------------------
-- 6. PROCEDURE: sp_create_order
-- Initializes a new order in PLACED status
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_create_order(
    p_customer_id   IN  NUMBER,
    p_restaurant_id IN  NUMBER,
    p_order_id      OUT NUMBER
) IS
BEGIN
    INSERT INTO ORDERS (
        customer_id, restaurant_id, order_date, status, total_amount
    ) VALUES (
        p_customer_id, p_restaurant_id, SYSDATE, 'PLACED', 0
    ) RETURNING order_id INTO p_order_id;

    COMMIT;
END sp_create_order;
/

-- ----------------------------------------------------------------------------
-- 7. PROCEDURE: sp_add_order_item
-- Adds item to order; verifies restaurant match and increments quantity if already exists
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_add_order_item(
    p_order_id   IN NUMBER,
    p_item_id    IN NUMBER,
    p_quantity   IN NUMBER
) IS
    v_order_rest NUMBER;
    v_item_rest  NUMBER;
    v_existing_id NUMBER;
BEGIN
    IF p_quantity <= 0 THEN
        RAISE_APPLICATION_ERROR(-20018, 'Item quantity must be greater than zero.');
    END IF;

    SELECT restaurant_id INTO v_order_rest
    FROM ORDERS
    WHERE order_id = p_order_id;

    SELECT restaurant_id INTO v_item_rest
    FROM MENU_ITEM
    WHERE item_id = p_item_id;

    -- Business Rule: Item must belong to same restaurant
    IF v_order_rest <> v_item_rest THEN
        RAISE_APPLICATION_ERROR(-20005, 'Selected item does not belong to the restaurant handling this order.');
    END IF;

    -- If already present, increment quantity
    BEGIN
        SELECT order_item_id INTO v_existing_id
        FROM ORDER_ITEM
        WHERE order_id = p_order_id AND item_id = p_item_id;

        UPDATE ORDER_ITEM
        SET quantity = quantity + p_quantity
        WHERE order_item_id = v_existing_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            INSERT INTO ORDER_ITEM (order_id, item_id, quantity)
            VALUES (p_order_id, p_item_id, p_quantity);
    END;

    COMMIT;
END sp_add_order_item;
/

-- ----------------------------------------------------------------------------
-- 8. PROCEDURE: sp_update_order_status
-- Enforces forward workflow: PLACED -> PREPARING -> READY -> SERVED -> DELIVERED
-- Allows CANCELLED only from PLACED or PREPARING
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_update_order_status(
    p_order_id    IN NUMBER,
    p_new_status  IN VARCHAR2
) IS
    v_current_status VARCHAR2(20);
    v_valid          BOOLEAN := FALSE;
BEGIN
    SELECT status INTO v_current_status
    FROM ORDERS
    WHERE order_id = p_order_id;

    IF v_current_status = p_new_status THEN
        RETURN;
    END IF;

    IF v_current_status = 'PLACED' AND p_new_status IN ('PREPARING', 'CANCELLED') THEN
        v_valid := TRUE;
    ELSIF v_current_status = 'PREPARING' AND p_new_status IN ('READY', 'CANCELLED') THEN
        v_valid := TRUE;
    ELSIF v_current_status = 'READY' AND p_new_status = 'SERVED' THEN
        v_valid := TRUE;
    ELSIF v_current_status = 'SERVED' AND p_new_status = 'DELIVERED' THEN
        v_valid := TRUE;
    END IF;

    IF NOT v_valid THEN
        RAISE_APPLICATION_ERROR(-20006, 'Invalid order status transition from ' || v_current_status || ' to ' || p_new_status || '.');
    END IF;

    UPDATE ORDERS
    SET status = p_new_status
    WHERE order_id = p_order_id;

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20019, 'Order not found.');
END sp_update_order_status;
/

-- ----------------------------------------------------------------------------
-- 9. PROCEDURE: sp_set_price
-- Closes active price period and inserts new price atomically
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_set_price(
    p_item_id        IN NUMBER,
    p_new_price      IN NUMBER,
    p_effective_date IN DATE
) IS
    v_eff       DATE := TRUNC(NVL(p_effective_date, SYSDATE));
    v_cur_start DATE;
BEGIN
    IF p_new_price < 0 THEN
        RAISE_APPLICATION_ERROR(-20020, 'Price must be non-negative.');
    END IF;

    -- Get current open price start_date
    BEGIN
        SELECT start_date INTO v_cur_start
        FROM PRICE_HISTORY
        WHERE item_id = p_item_id AND end_date IS NULL;

        -- Ensure effective date is strictly after current start_date to maintain end_date >= start_date
        IF v_eff <= v_cur_start THEN
            v_eff := v_cur_start + 1;
        END IF;

        -- Close open price period
        UPDATE PRICE_HISTORY
        SET end_date = v_eff - 1
        WHERE item_id = p_item_id
          AND end_date IS NULL;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            NULL;
    END;

    -- Insert new price
    INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date)
    VALUES (p_item_id, p_new_price, v_eff, NULL);

    COMMIT;
END sp_set_price;
/

-- ----------------------------------------------------------------------------
-- 10. PROCEDURE: sp_daily_sales_report
-- Explicit cursor report printing order count, revenue and top item via DBMS_OUTPUT
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_daily_sales_report(
    p_restaurant_id IN NUMBER,
    p_date          IN DATE
) IS
    CURSOR c_orders IS
        SELECT o.order_id, o.total_amount, o.status, p.payment_method
        FROM ORDERS o
        LEFT JOIN PAYMENT p ON o.order_id = p.order_id
        WHERE o.restaurant_id = p_restaurant_id
          AND TRUNC(o.order_date) = TRUNC(p_date);

    v_order_count NUMBER := 0;
    v_revenue     NUMBER := 0;
    v_top_item    VARCHAR2(100) := 'None';
    v_top_qty     NUMBER := 0;
    v_rest_name   VARCHAR2(100);
BEGIN
    SELECT name INTO v_rest_name
    FROM RESTAURANT
    WHERE restaurant_id = p_restaurant_id;

    DBMS_OUTPUT.PUT_LINE('==================================================');
    DBMS_OUTPUT.PUT_LINE('DAILY SALES REPORT: ' || v_rest_name);
    DBMS_OUTPUT.PUT_LINE('Date: ' || TO_CHAR(p_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('==================================================');

    FOR rec IN c_orders LOOP
        v_order_count := v_order_count + 1;
        IF rec.status <> 'CANCELLED' THEN
            v_revenue := v_revenue + rec.total_amount;
        END IF;
    END LOOP;

    -- Find top item sold on that date
    BEGIN
        SELECT m.name, SUM(oi.quantity)
        INTO v_top_item, v_top_qty
        FROM ORDER_ITEM oi
        JOIN ORDERS o ON oi.order_id = o.order_id
        JOIN MENU_ITEM m ON oi.item_id = m.item_id
        WHERE o.restaurant_id = p_restaurant_id
          AND TRUNC(o.order_date) = TRUNC(p_date)
          AND o.status <> 'CANCELLED'
        GROUP BY m.name
        ORDER BY SUM(oi.quantity) DESC
        FETCH FIRST 1 ROW ONLY;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_top_item := 'No items sold';
            v_top_qty := 0;
    END;

    DBMS_OUTPUT.PUT_LINE('Total Orders:   ' || v_order_count);
    DBMS_OUTPUT.PUT_LINE('Total Revenue:  INR ' || TO_CHAR(v_revenue, '999,999.99'));
    DBMS_OUTPUT.PUT_LINE('Top Sold Item:  ' || v_top_item || ' (Qty: ' || v_top_qty || ')');
    DBMS_OUTPUT.PUT_LINE('==================================================');
END sp_daily_sales_report;
/

-- ----------------------------------------------------------------------------
-- 11. PROCEDURE: sp_customer_spend_report
-- Returns a SYS_REFCURSOR for customers with order count >= p_min_orders
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_customer_spend_report(
    p_min_orders IN NUMBER,
    p_cursor     OUT SYS_REFCURSOR
) IS
BEGIN
    OPEN p_cursor FOR
        SELECT 
            c.customer_id,
            c.name AS customer_name,
            c.email,
            c.phone,
            COUNT(o.order_id) AS total_orders,
            NVL(SUM(o.total_amount), 0) AS total_spent,
            MAX(o.order_date) AS last_order_date
        FROM CUSTOMER c
        LEFT JOIN ORDERS o ON c.customer_id = o.customer_id AND o.status <> 'CANCELLED'
        GROUP BY c.customer_id, c.name, c.email, c.phone
        HAVING COUNT(o.order_id) >= NVL(p_min_orders, 0)
        ORDER BY total_spent DESC;
END sp_customer_spend_report;
/

-- ----------------------------------------------------------------------------
-- 12. COMPOUND TRIGGER: trg_order_item_total
-- Automatically recalculates orders.total_amount using fn_price_on(item_id, order_date)
-- Completely avoids mutating-table ORA-04091 error.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_order_item_total
FOR INSERT OR UPDATE OR DELETE ON ORDER_ITEM
COMPOUND TRIGGER

    TYPE t_order_ids IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    g_order_ids t_order_ids;

    BEFORE STATEMENT IS
    BEGIN
        g_order_ids.DELETE;
    END BEFORE STATEMENT;

    AFTER EACH ROW IS
    BEGIN
        IF INSERTING OR UPDATING THEN
            g_order_ids(g_order_ids.COUNT + 1) := :NEW.order_id;
        END IF;
        IF DELETING OR UPDATING THEN
            g_order_ids(g_order_ids.COUNT + 1) := :OLD.order_id;
        END IF;
    END AFTER EACH ROW;

    AFTER STATEMENT IS
        v_order_id NUMBER;
        v_order_date DATE;
        v_total NUMBER(10, 2);
        TYPE t_unique_ids IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
        v_processed t_unique_ids;
    BEGIN
        FOR i IN 1 .. g_order_ids.COUNT LOOP
            v_order_id := g_order_ids(i);
            IF NOT v_processed.EXISTS(v_order_id) THEN
                v_processed(v_order_id) := TRUE;

                SELECT order_date INTO v_order_date
                FROM ORDERS
                WHERE order_id = v_order_id;

                SELECT NVL(SUM(oi.quantity * fn_price_on(oi.item_id, v_order_date)), 0)
                INTO v_total
                FROM ORDER_ITEM oi
                WHERE oi.order_id = v_order_id;

                UPDATE ORDERS
                SET total_amount = v_total
                WHERE order_id = v_order_id;
            END IF;
        END LOOP;
    END AFTER STATEMENT;

END trg_order_item_total;
/

-- ----------------------------------------------------------------------------
-- 13. TRIGGER: trg_payment_validate
-- Validates that payment amount matches order total and order is not cancelled
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_payment_validate
BEFORE INSERT OR UPDATE ON PAYMENT
FOR EACH ROW
DECLARE
    v_order_total  NUMBER(10, 2);
    v_order_status VARCHAR2(20);
BEGIN
    SELECT total_amount, status
    INTO v_order_total, v_order_status
    FROM ORDERS
    WHERE order_id = :NEW.order_id;

    IF v_order_status = 'CANCELLED' THEN
        RAISE_APPLICATION_ERROR(-20007, 'Cannot process payment for a cancelled order.');
    END IF;

    IF ABS(:NEW.amount - v_order_total) > 0.01 THEN
        RAISE_APPLICATION_ERROR(-20008, 'Payment amount (' || :NEW.amount || ') must match order total (' || v_order_total || ').');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 14. TRIGGER: trg_review_validate
-- Review requires served/delivered order and successful payment by that customer
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_review_validate
BEFORE INSERT ON REVIEW
FOR EACH ROW
DECLARE
    v_order_cust   NUMBER;
    v_order_rest   NUMBER;
    v_order_status VARCHAR2(20);
    v_pay_status   VARCHAR2(20);
BEGIN
    SELECT customer_id, restaurant_id, status
    INTO v_order_cust, v_order_rest, v_order_status
    FROM ORDERS
    WHERE order_id = :NEW.order_id;

    IF v_order_cust <> :NEW.customer_id THEN
        RAISE_APPLICATION_ERROR(-20009, 'Customer did not place this order.');
    END IF;

    IF v_order_status NOT IN ('SERVED', 'DELIVERED') THEN
        RAISE_APPLICATION_ERROR(-20010, 'Review is only allowed for served or delivered orders.');
    END IF;

    BEGIN
        SELECT status INTO v_pay_status
        FROM PAYMENT
        WHERE order_id = :NEW.order_id;

        IF v_pay_status <> 'SUCCESS' THEN
            RAISE_APPLICATION_ERROR(-20011, 'Review requires a completed successful payment.');
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20011, 'Review requires a completed successful payment.');
    END;

    -- Ensure restaurant_id is consistent with order
    :NEW.restaurant_id := v_order_rest;
END;
/

-- ----------------------------------------------------------------------------
-- 15. TRIGGER: trg_reservation_guest_check
-- Ensures reservation guests does not exceed table capacity
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_reservation_guest_check
BEFORE INSERT OR UPDATE ON RESERVATION
FOR EACH ROW
DECLARE
    v_capacity NUMBER;
BEGIN
    SELECT capacity INTO v_capacity
    FROM DINING_TABLE
    WHERE table_id = :NEW.table_id;

    IF :NEW.number_of_guests > v_capacity THEN
        RAISE_APPLICATION_ERROR(-20012, 'Number of guests (' || :NEW.number_of_guests || ') exceeds table capacity (' || v_capacity || ').');
    END IF;
END;
/

-- ----------------------------------------------------------------------------
-- 16. VIEW: v_order_summary
-- Unified view combining orders, customer, restaurant, and payment
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_order_summary AS
SELECT 
    o.order_id,
    o.order_date,
    o.status AS order_status,
    o.total_amount,
    c.customer_id,
    c.name AS customer_name,
    c.email AS customer_email,
    c.phone AS customer_phone,
    r.restaurant_id,
    r.name AS restaurant_name,
    p.payment_id,
    p.payment_method,
    p.status AS payment_status,
    p.payment_date
FROM ORDERS o
JOIN CUSTOMER c ON o.customer_id = c.customer_id
JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
LEFT JOIN PAYMENT p ON o.order_id = p.order_id;

PROMPT PL/SQL objects and views compiled successfully.
EXIT;
