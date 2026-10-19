-- ============================================================================
-- DA2: Restaurant Table Reservation & Food Ordering System
-- Script: 05_tests.sql
-- Description: Automated Test Suite verifying all integrity constraints,
--              business rules, and PL/SQL procedures/triggers.
-- Target DBMS: Oracle Database 21c XE / Free
-- ============================================================================

SET SERVEROUTPUT ON;
SET DEFINE OFF;

DECLARE
    v_test_count NUMBER := 0;
    v_pass_count NUMBER := 0;
    v_fail_count NUMBER := 0;
    v_res_id     NUMBER;
    v_order_id   NUMBER;
    v_new_total  NUMBER;
    v_old_total  NUMBER;
    v_price      NUMBER;

    PROCEDURE report(p_name VARCHAR2, p_passed BOOLEAN, p_detail VARCHAR2 := '') IS
    BEGIN
        v_test_count := v_test_count + 1;
        IF p_passed THEN
            v_pass_count := v_pass_count + 1;
            DBMS_OUTPUT.PUT_LINE('[PASS] Test ' || v_test_count || ': ' || p_name);
        ELSE
            v_fail_count := v_fail_count + 1;
            DBMS_OUTPUT.PUT_LINE('[FAIL] Test ' || v_test_count || ': ' || p_name || ' -> ' || p_detail);
        END IF;
    END;
BEGIN
    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('STARTING AUTOMATED PL/SQL & INTEGRITY TEST SUITE');
    DBMS_OUTPUT.PUT_LINE('============================================================');

    -- TEST 1: Unique Email Constraint on CUSTOMER
    BEGIN
        INSERT INTO CUSTOMER (name, email, phone, address)
        VALUES ('Duplicate Person', 'rohan.jena@example.com', '1234567890', 'Somewhere');
        report('Duplicate email must be rejected', FALSE, 'Allowed duplicate email insert');
        ROLLBACK;
    EXCEPTION
        WHEN OTHERS THEN
            report('Duplicate email rejected by unique constraint', TRUE);
            ROLLBACK;
    END;

    -- TEST 2: Valid Reservation Booking via sp_make_reservation
    BEGIN
        sp_make_reservation(
            p_customer_id    => 1,
            p_table_id       => 1, -- Table capacity 2
            p_date           => DATE '2026-11-20',
            p_slot           => '19:00-21:00',
            p_guests         => 2,
            p_reservation_id => v_res_id
        );
        report('Valid reservation booking via sp_make_reservation', v_res_id IS NOT NULL);
    EXCEPTION
        WHEN OTHERS THEN
            report('Valid reservation booking via sp_make_reservation', FALSE, SQLERRM);
    END;

    -- TEST 3: Double-booking Prevention on Same Table, Date and Slot
    BEGIN
        sp_make_reservation(
            p_customer_id    => 2,
            p_table_id       => 1,
            p_date           => DATE '2026-11-20',
            p_slot           => '19:00-21:00',
            p_guests         => 2,
            p_reservation_id => v_res_id
        );
        report('Double-booking must be rejected', FALSE, 'Allowed double booking on same slot');
    EXCEPTION
        WHEN OTHERS THEN
            report('Double-booking prevented by system', TRUE);
    END;

    -- TEST 4: Exceeding Table Capacity Rejection
    BEGIN
        sp_make_reservation(
            p_customer_id    => 3,
            p_table_id       => 1, -- Capacity is 2
            p_date           => DATE '2026-11-25',
            p_slot           => '19:00-21:00',
            p_guests         => 6, -- Exceeds 2
            p_reservation_id => v_res_id
        );
        report('Exceeding table capacity must be rejected', FALSE, 'Allowed guest count > capacity');
    EXCEPTION
        WHEN OTHERS THEN
            report('Guest count exceeding table capacity rejected', TRUE);
    END;

    -- TEST 5: Reservation in the Past Rejection
    BEGIN
        sp_make_reservation(
            p_customer_id    => 1,
            p_table_id       => 1,
            p_date           => DATE '2020-01-01',
            p_slot           => '19:00-21:00',
            p_guests         => 2,
            p_reservation_id => v_res_id
        );
        report('Past reservation date must be rejected', FALSE, 'Allowed past date booking');
    EXCEPTION
        WHEN OTHERS THEN
            report('Past reservation date rejected', TRUE);
    END;

    -- TEST 6: Cancellation Frees Slot for Rebooking
    BEGIN
        -- Find existing reservation on 2026-11-20
        SELECT reservation_id INTO v_res_id
        FROM RESERVATION
        WHERE table_id = 1 AND TRUNC(reservation_date) = DATE '2026-11-20' AND time_slot = '19:00-21:00' AND status <> 'CANCELLED';

        -- Cancel it
        sp_cancel_reservation(v_res_id);

        -- Rebook should now succeed
        sp_make_reservation(
            p_customer_id    => 4,
            p_table_id       => 1,
            p_date           => DATE '2026-11-20',
            p_slot           => '19:00-21:00',
            p_guests         => 2,
            p_reservation_id => v_res_id
        );
        report('Cancellation frees slot allowing rebooking', v_res_id IS NOT NULL);
    EXCEPTION
        WHEN OTHERS THEN
            report('Cancellation frees slot allowing rebooking', FALSE, SQLERRM);
    END;

    -- TEST 7: Order Creation and Item from Different Restaurant Rejection
    BEGIN
        sp_create_order(p_customer_id => 1, p_restaurant_id => 1, p_order_id => v_order_id);
        -- Item 11 belongs to Restaurant 2, while Order is at Restaurant 1
        sp_add_order_item(p_order_id => v_order_id, p_item_id => 11, p_quantity => 1);
        report('Cross-restaurant item in order must be rejected', FALSE, 'Allowed item from different restaurant');
    EXCEPTION
        WHEN OTHERS THEN
            report('Cross-restaurant menu item in order rejected', TRUE);
    END;

    -- TEST 8: Compound Trigger Automatic Order Total Calculation
    BEGIN
        -- Add valid item 1 (Price 460) quantity 2 -> total should become 920
        sp_add_order_item(p_order_id => v_order_id, p_item_id => 1, p_quantity => 2);
        SELECT total_amount INTO v_new_total FROM ORDERS WHERE order_id = v_order_id;
        report('Compound trigger computes order total on item add', v_new_total = 920, 'Expected 920, got ' || v_new_total);

        -- Add item 8 (Garlic Naan, Price 90) quantity 2 -> total should become 920 + 180 = 1100
        sp_add_order_item(p_order_id => v_order_id, p_item_id => 8, p_quantity => 2);
        SELECT total_amount INTO v_new_total FROM ORDERS WHERE order_id = v_order_id;
        report('Compound trigger updates order total on second item add', v_new_total = 1100, 'Expected 1100, got ' || v_new_total);

        -- Delete item 8 -> total should revert to 920
        DELETE FROM ORDER_ITEM WHERE order_id = v_order_id AND item_id = 8;
        SELECT total_amount INTO v_new_total FROM ORDERS WHERE order_id = v_order_id;
        report('Compound trigger updates order total on item delete', v_new_total = 920, 'Expected 920, got ' || v_new_total);
    EXCEPTION
        WHEN OTHERS THEN
            report('Compound trigger automatic order total calculation', FALSE, SQLERRM);
    END;

    -- TEST 9: Order Status Transition Validation
    BEGIN
        -- Valid forward move: PLACED -> PREPARING
        sp_update_order_status(p_order_id => v_order_id, p_new_status => 'PREPARING');
        -- Invalid backward move: PREPARING -> PLACED
        sp_update_order_status(p_order_id => v_order_id, p_new_status => 'PLACED');
        report('Backward order status move must be rejected', FALSE, 'Allowed backward status change');
    EXCEPTION
        WHEN OTHERS THEN
            report('Backward order status transition rejected', TRUE);
    END;

    -- TEST 10: Payment Amount Mismatch Rejection
    BEGIN
        -- Order total is 920. Attempt to pay 500
        INSERT INTO PAYMENT (order_id, amount, payment_method, status)
        VALUES (v_order_id, 500, 'UPI', 'SUCCESS');
        report('Payment amount mismatch must be rejected', FALSE, 'Allowed payment of 500 against total 920');
    EXCEPTION
        WHEN OTHERS THEN
            report('Payment amount mismatch rejected by trigger', TRUE);
    END;

    -- TEST 11: Valid Payment and Order Status Advance to DELIVERED
    BEGIN
        sp_update_order_status(p_order_id => v_order_id, p_new_status => 'READY');
        sp_update_order_status(p_order_id => v_order_id, p_new_status => 'SERVED');
        sp_update_order_status(p_order_id => v_order_id, p_new_status => 'DELIVERED');

        INSERT INTO PAYMENT (order_id, amount, payment_method, status)
        VALUES (v_order_id, 920, 'UPI', 'SUCCESS');
        report('Valid exact payment matching total accepted', TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            report('Valid exact payment matching total accepted', FALSE, SQLERRM);
    END;

    -- TEST 12: Review Submission for Delivered & Paid Order
    BEGIN
        INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment)
        VALUES (1, 1, v_order_id, 5, 'Automated test suite review confirmation.');
        report('Review on delivered and paid order accepted', TRUE);
    EXCEPTION
        WHEN OTHERS THEN
            report('Review on delivered and paid order accepted', FALSE, SQLERRM);
    END;

    -- TEST 13: Price Change via sp_set_price Updates History Atomically
    BEGIN
        sp_set_price(p_item_id => 28, p_new_price => 495.00, p_effective_date => SYSDATE);
        SELECT price INTO v_price FROM PRICE_HISTORY WHERE item_id = 28 AND end_date IS NULL;
        report('Price change via sp_set_price maintains history', v_price = 495.00, 'Expected 495.00, got ' || v_price);
    EXCEPTION
        WHEN OTHERS THEN
            report('Price change via sp_set_price maintains history', FALSE, SQLERRM);
    END;

    DBMS_OUTPUT.PUT_LINE('============================================================');
    DBMS_OUTPUT.PUT_LINE('TEST SUITE COMPLETE: ' || v_pass_count || '/' || v_test_count || ' TESTS PASSED (' || v_fail_count || ' FAILURES)');
    DBMS_OUTPUT.PUT_LINE('============================================================');
END;
/
EXIT;
