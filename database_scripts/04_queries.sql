-- ============================================================================
-- DA2: Restaurant Table Reservation & Food Ordering System
-- Script: 04_queries.sql
-- Description: 12 System-Specific Business Queries using SQL and PL/SQL.
-- Target DBMS: Oracle Database 21c XE / Free
-- ============================================================================

SET LINESIZE 200;
SET PAGESIZE 100;
SET SERVEROUTPUT ON;
SET FEEDBACK ON;
SET DEFINE OFF;

PROMPT ========================================================================
PROMPT QUERY 1: Free Dining Tables with Capacity >= 4 for a Restaurant, Date & Slot
PROMPT Technique: NOT EXISTS correlated subquery with availability check
PROMPT ========================================================================

SELECT 
    t.table_id,
    r.name AS restaurant_name,
    t.table_number,
    t.capacity,
    t.is_available
FROM DINING_TABLE t
JOIN RESTAURANT r ON t.restaurant_id = r.restaurant_id
WHERE t.restaurant_id = 1
  AND t.capacity >= 4
  AND t.is_available = 'Y'
  AND NOT EXISTS (
      SELECT 1 
      FROM RESERVATION res
      WHERE res.table_id = t.table_id
        AND TRUNC(res.reservation_date) = DATE '2026-10-15'
        AND res.time_slot = '19:00-21:00'
        AND res.status <> 'CANCELLED'
  )
ORDER BY t.capacity, t.table_number;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 2: Top 5 Best-Selling Menu Items by Quantity with Category
PROMPT Technique: Multi-table JOIN, GROUP BY, SUM, FETCH FIRST 5 ROWS ONLY
PROMPT ========================================================================

SELECT 
    m.item_id,
    m.name AS item_name,
    c.name AS category_name,
    m.is_veg,
    SUM(oi.quantity) AS total_quantity_sold
FROM ORDER_ITEM oi
JOIN MENU_ITEM m ON oi.item_id = m.item_id
JOIN CATEGORY c ON m.category_id = c.category_id
GROUP BY m.item_id, m.name, c.name, m.is_veg
ORDER BY total_quantity_sold DESC, m.name
FETCH FIRST 5 ROWS ONLY;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 3: Monthly Revenue per Restaurant from Settled (SUCCESS) Payments
PROMPT Technique: GROUP BY with TO_CHAR date formatting and SUM
PROMPT ========================================================================

SELECT 
    r.name AS restaurant_name,
    TO_CHAR(p.payment_date, 'YYYY-MM') AS month_year,
    COUNT(p.payment_id) AS settled_orders_count,
    SUM(p.amount) AS total_revenue
FROM PAYMENT p
JOIN ORDERS o ON p.order_id = o.order_id
JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
WHERE p.status = 'SUCCESS'
GROUP BY r.name, TO_CHAR(p.payment_date, 'YYYY-MM')
ORDER BY r.name, month_year;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 4: Loyal Customers with More than 2 Orders and their Total Spend
PROMPT Technique: GROUP BY with HAVING aggregate filter and SUM
PROMPT ========================================================================

SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.email,
    COUNT(o.order_id) AS total_orders,
    SUM(o.total_amount) AS total_spent
FROM CUSTOMER c
JOIN ORDERS o ON c.customer_id = o.customer_id
WHERE o.status <> 'CANCELLED'
GROUP BY c.customer_id, c.name, c.email
HAVING COUNT(o.order_id) > 2
ORDER BY total_spent DESC;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 5: Average Rating and Total Review Count per Restaurant
PROMPT Technique: LEFT OUTER JOIN, NVL, ROUND, AVG and COUNT
PROMPT ========================================================================

SELECT 
    r.restaurant_id,
    r.name AS restaurant_name,
    r.cuisine_type,
    COUNT(rev.review_id) AS total_reviews,
    ROUND(NVL(AVG(rev.rating), 0), 2) AS average_rating
FROM RESTAURANT r
LEFT JOIN REVIEW rev ON r.restaurant_id = rev.restaurant_id
GROUP BY r.restaurant_id, r.name, r.cuisine_type
ORDER BY average_rating DESC, total_reviews DESC;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 6: Current Active Price of Items & Number of Historical Price Revisions
PROMPT Technique: Filter on end_date IS NULL with correlated scalar subquery
PROMPT ========================================================================

SELECT 
    m.item_id,
    m.name AS item_name,
    r.name AS restaurant_name,
    ph.price AS current_price,
    (
        SELECT COUNT(*) 
        FROM PRICE_HISTORY ph_all 
        WHERE ph_all.item_id = m.item_id
    ) AS total_price_revisions
FROM MENU_ITEM m
JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
JOIN PRICE_HISTORY ph ON m.item_id = ph.item_id AND ph.end_date IS NULL
WHERE (
    SELECT COUNT(*) 
    FROM PRICE_HISTORY ph_all 
    WHERE ph_all.item_id = m.item_id
) > 1
ORDER BY total_price_revisions DESC, m.name;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 7: Customers Who Reserved a Table but Never Placed an Order
PROMPT Technique: Correlated NOT EXISTS against ORDERS with EXISTS on RESERVATION
PROMPT ========================================================================

SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.email,
    c.phone,
    c.reg_date
FROM CUSTOMER c
WHERE EXISTS (
    SELECT 1 FROM RESERVATION res WHERE res.customer_id = c.customer_id
)
AND NOT EXISTS (
    SELECT 1 FROM ORDERS o WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 8: Orders with Missing, Pending or Failed Payment (Auditing View)
PROMPT Technique: Querying view v_order_summary with NULL / status condition
PROMPT ========================================================================

SELECT 
    order_id,
    TO_CHAR(order_date, 'YYYY-MM-DD') AS order_date,
    customer_name,
    restaurant_name,
    total_amount,
    order_status,
    NVL(payment_status, 'UNPAID') AS payment_status
FROM v_order_summary
WHERE payment_status IS NULL 
   OR payment_status IN ('PENDING', 'FAILED')
ORDER BY order_id;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 9: Menu Items That Have Never Been Ordered
PROMPT Technique: NOT EXISTS subquery against ORDER_ITEM
PROMPT ========================================================================

SELECT 
    m.item_id,
    m.name AS item_name,
    r.name AS restaurant_name,
    c.name AS category_name,
    ph.price AS current_price
FROM MENU_ITEM m
JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
JOIN CATEGORY c ON m.category_id = c.category_id
JOIN PRICE_HISTORY ph ON m.item_id = ph.item_id AND ph.end_date IS NULL
WHERE NOT EXISTS (
    SELECT 1 FROM ORDER_ITEM oi WHERE oi.item_id = m.item_id
)
ORDER BY r.name, m.name;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 10: Most Expensive Menu Item in Each Restaurant
PROMPT Technique: Analytic Function RANK() OVER (PARTITION BY restaurant_id)
PROMPT ========================================================================

WITH ranked_menu AS (
    SELECT 
        r.name AS restaurant_name,
        m.name AS item_name,
        c.name AS category_name,
        ph.price,
        RANK() OVER (PARTITION BY r.restaurant_id ORDER BY ph.price DESC) AS price_rank
    FROM MENU_ITEM m
    JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
    JOIN CATEGORY c ON m.category_id = c.category_id
    JOIN PRICE_HISTORY ph ON m.item_id = ph.item_id AND ph.end_date IS NULL
)
SELECT 
    restaurant_name,
    item_name,
    category_name,
    price
FROM ranked_menu
WHERE price_rank = 1
ORDER BY restaurant_name;

PROMPT
PROMPT ========================================================================
PROMPT QUERY 11 (PL/SQL): Daily Sales & Performance Report (sp_daily_sales_report)
PROMPT Technique: Executing PL/SQL Procedure utilizing Explicit Cursor and DBMS_OUTPUT
PROMPT ========================================================================

BEGIN
    sp_daily_sales_report(
        p_restaurant_id => 1,
        p_date          => DATE '2026-06-10'
    );
    sp_daily_sales_report(
        p_restaurant_id => 3,
        p_date          => DATE '2026-08-22'
    );
END;
/

PROMPT
PROMPT ========================================================================
PROMPT QUERY 12 (PL/SQL): Customer Spend Analytics via Ref Cursor (sp_customer_spend_report)
PROMPT Technique: Executing PL/SQL Stored Procedure with SYS_REFCURSOR OUT parameter
PROMPT ========================================================================

VARIABLE rc REFCURSOR;
BEGIN
    sp_customer_spend_report(
        p_min_orders => 2,
        p_cursor     => :rc
    );
END;
/
PRINT rc;

PROMPT
PROMPT ========================================================================
PROMPT All 12 Queries executed successfully.
PROMPT ========================================================================
EXIT;
