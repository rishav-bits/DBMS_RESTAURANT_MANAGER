-- ============================================================================
-- DA2: Restaurant Table Reservation & Food Ordering System
-- Script: 06_auth_schema.sql
-- Description: DDL to create APP_USER table for multi-role authentication
--              (Customer, Staff/Receptionist, Owner)
-- Target DBMS: Oracle Database 21c XE
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    FOR t IN (SELECT table_name FROM user_tables WHERE table_name = 'APP_USER') LOOP
        EXECUTE IMMEDIATE 'DROP TABLE APP_USER CASCADE CONSTRAINTS PURGE';
        DBMS_OUTPUT.PUT_LINE('Dropped existing APP_USER table.');
    END LOOP;
END;
/

CREATE TABLE APP_USER (
    user_id          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email            VARCHAR2(100) NOT NULL,
    password_hash    VARCHAR2(255) NOT NULL,
    full_name        VARCHAR2(100) NOT NULL,
    phone            VARCHAR2(20),
    role             VARCHAR2(20) NOT NULL,
    staff_title      VARCHAR2(50),
    restaurant_id    NUMBER,
    customer_id      NUMBER,
    staff_id         NUMBER,
    created_at       DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT uq_app_user_email UNIQUE (email),
    CONSTRAINT chk_app_user_role CHECK (role IN ('CUSTOMER', 'STAFF', 'OWNER')),
    CONSTRAINT fk_app_user_rest FOREIGN KEY (restaurant_id) REFERENCES RESTAURANT(restaurant_id) ON DELETE SET NULL,
    CONSTRAINT fk_app_user_cust FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON DELETE SET NULL,
    CONSTRAINT fk_app_user_staff FOREIGN KEY (staff_id) REFERENCES STAFF(staff_id) ON DELETE SET NULL
);

CREATE INDEX idx_app_user_email ON APP_USER(email);
CREATE INDEX idx_app_user_role  ON APP_USER(role);

PROMPT APP_USER table created successfully.
EXIT;
