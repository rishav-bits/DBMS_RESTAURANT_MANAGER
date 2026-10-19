"""
Setup Authentication System in Oracle 21c XE
Creates APP_USER table and seeds initial accounts for:
  - Customer
  - Staff / Receptionist
  - Owner
"""

import sys
sys.stdout.reconfigure(encoding='utf-8')
from werkzeug.security import generate_password_hash
import app.db as db

def setup_auth():
    print("Checking APP_USER table in Oracle database...")
    check = db.query_all("SELECT table_name FROM user_tables WHERE table_name = 'APP_USER'")
    if not check:
        print("Creating APP_USER table...")
        ddl = """
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
        )
        """
        db.execute(ddl)
        # UNIQUE constraint on email already creates unique index in Oracle
        db.execute("CREATE INDEX idx_app_user_role ON APP_USER(role)")
        print("✓ APP_USER table and indexes created.")
    else:
        print("✓ APP_USER table already exists.")

    # Fetch first customer and first restaurant/staff
    cust_rows = db.query_all("SELECT customer_id, name, email, phone FROM CUSTOMER WHERE ROWNUM <= 3")
    rest_rows = db.query_all("SELECT restaurant_id, name FROM RESTAURANT WHERE ROWNUM <= 3")
    staff_rows = db.query_all("SELECT staff_id, restaurant_id, name, role, contact FROM STAFF WHERE ROWNUM <= 3")

    first_cust_id = cust_rows[0]['customer_id'] if cust_rows else None
    first_rest_id = rest_rows[0]['restaurant_id'] if rest_rows else None
    first_staff_id = staff_rows[0]['staff_id'] if staff_rows else None

    # Pre-defined core accounts
    accounts = [
        {
            "email": "customer@example.com",
            "password": "customer123",
            "full_name": "Rohan Jena (Customer)",
            "phone": "+91 98765 43210",
            "role": "CUSTOMER",
            "staff_title": None,
            "restaurant_id": None,
            "customer_id": first_cust_id,
            "staff_id": None
        },
        {
            "email": "receptionist@example.com",
            "password": "staff123",
            "full_name": "Khyati (Receptionist)",
            "phone": "+91 98111 22334",
            "role": "STAFF",
            "staff_title": "Receptionist / Front Desk",
            "restaurant_id": first_rest_id,
            "customer_id": None,
            "staff_id": first_staff_id
        },
        {
            "email": "owner@example.com",
            "password": "owner123",
            "full_name": "Rishav Singh (Owner)",
            "phone": "+91 99999 88888",
            "role": "OWNER",
            "staff_title": "Restaurant Owner & Founder",
            "restaurant_id": None,
            "customer_id": None,
            "staff_id": None
        }
    ]

    # Also register seeded customers so their emails work directly
    for c in cust_rows:
        accounts.append({
            "email": c['email'],
            "password": "pass123",
            "full_name": c['name'],
            "phone": c['phone'],
            "role": "CUSTOMER",
            "staff_title": None,
            "restaurant_id": None,
            "customer_id": c['customer_id'],
            "staff_id": None
        })

    print("\nSeeding accounts into APP_USER...")
    for acc in accounts:
        existing = db.query_one("SELECT user_id FROM APP_USER WHERE email = :email", {"email": acc['email'].lower()})
        if not existing:
            p_hash = generate_password_hash(acc['password'])
            sql = """
            INSERT INTO APP_USER (email, password_hash, full_name, phone, role, staff_title, restaurant_id, customer_id, staff_id)
            VALUES (:email, :pwd, :name, :phone, :role, :title, :rest_id, :cust_id, :staff_id)
            """
            db.execute_dml(sql, {
                "email": acc['email'].lower(),
                "pwd": p_hash,
                "name": acc['full_name'],
                "phone": acc['phone'],
                "role": acc['role'],
                "title": acc['staff_title'],
                "rest_id": acc['restaurant_id'],
                "cust_id": acc['customer_id'],
                "staff_id": acc['staff_id']
            })
            print(f"  + Created [{acc['role']:<8}] {acc['email']} (Password: {acc['password']})")
        else:
            print(f"  * Exists  [{acc['role']:<8}] {acc['email']}")

    # Report all active accounts
    total = db.query_all("SELECT user_id, email, full_name, role, staff_title FROM APP_USER ORDER BY user_id")
    print(f"\nTotal APP_USER records: {len(total)}")
    for u in total:
        print(f"  ID #{u['user_id']}: {u['email']:<26} | Role: {u['role']:<8} | Name: {u['full_name']}")

if __name__ == '__main__':
    setup_auth()
