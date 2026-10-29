"""
Flask Application for Restaurant Table Reservation & Food Ordering System
Provides full Multi-Role Authentication (Customer, Staff/Receptionist, Owner),
role-based permissions, distinct user interfaces, CRUD operations, PL/SQL integration,
and 12 system-specific queries.
"""

import os
import re
from datetime import datetime
from functools import wraps
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify, session
from werkzeug.security import generate_password_hash, check_password_hash
import oracledb
from db import get_connection, query_all, query_one, execute_dml, execute_proc

app = Flask(__name__)
app.secret_key = os.getenv("SECRET_KEY", "restaurant_secret_key_bacse202_oracle21c")

def format_oracle_error(err_msg):
    """Extract clean, user-friendly message from Oracle exceptions."""
    s = str(err_msg)
    # Check for ORA-20xxx custom business errors
    match = re.search(r"ORA-20\d{3}:\s*([^\n]+)", s)
    if match:
        return match.group(1).strip()
    if "ORA-00001" in s:
        if "UQ_APP_USER_EMAIL" in s.upper():
            return "An account with this email address is already registered."
        if "UQ_CUSTOMER_EMAIL" in s.upper():
            return "A customer with this email address already exists."
        if "UQ_RES_ACTIVE_SLOT" in s.upper():
            return "This table is already booked for the selected date and time slot."
        if "UQ_ORDER_ITEM" in s.upper():
            return "This item is already in the order. Please update its quantity instead."
        if "UQ_PAYMENT_ORDER" in s.upper():
            return "A payment record already exists for this order."
        if "UQ_REVIEW_ORDER" in s.upper():
            return "A review has already been submitted for this order."
        return "Duplicate record detected. Unique constraint violated."
    if "ORA-02292" in s:
        return "Cannot delete this record because associated dependent records (reservations, orders, or history) exist."
    if "ORA-01400" in s:
        return "A required field was left empty."
    if "PLS-" in s:
        pls_match = re.search(r"(PLS-\d+:[^\n]+)", s)
        if pls_match:
            return pls_match.group(1).strip()
    return s.split("\n")[0]

# ----------------------------------------------------------------------------
# AUTHENTICATION & ACCESS CONTROL DECORATORS
# ----------------------------------------------------------------------------
def login_required(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        if "user_id" not in session:
            flash("Please sign in to access this section.", "warning")
            return redirect(url_for("login", next=request.path))
        return f(*args, **kwargs)
    return decorated_function

def role_required(allowed_roles):
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if "user_id" not in session:
                flash("Please sign in to access this section.", "warning")
                return redirect(url_for("login", next=request.path))
            user_role = session.get("role")
            if user_role not in allowed_roles:
                flash(f"Access denied: This section is restricted to {', '.join(allowed_roles)} accounts.", "danger")
                return redirect(url_for("index"))
            return f(*args, **kwargs)
        return decorated_function
    return decorator

@app.context_processor
def inject_user():
    """Make current_user accessible in all Jinja templates."""
    if "user_id" in session:
        return {
            "current_user": {
                "is_authenticated": True,
                "user_id": session.get("user_id"),
                "email": session.get("email"),
                "name": session.get("name"),
                "role": session.get("role"),
                "staff_title": session.get("staff_title"),
                "restaurant_id": session.get("restaurant_id"),
                "customer_id": session.get("customer_id"),
                "staff_id": session.get("staff_id"),
                "is_customer": session.get("role") == "CUSTOMER",
                "is_staff": session.get("role") == "STAFF",
                "is_owner": session.get("role") == "OWNER",
            }
        }
    return {
        "current_user": {
            "is_authenticated": False,
            "role": None,
            "is_customer": False,
            "is_staff": False,
            "is_owner": False,
        }
    }

# ----------------------------------------------------------------------------
# 1. AUTHENTICATION ROUTES (Register, Login, Logout, Profile)
# ----------------------------------------------------------------------------
@app.route("/register", methods=["GET", "POST"])
def register():
    if request.method == "POST":
        name = request.form.get("name", "").strip()
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        phone = request.form.get("phone", "").strip()
        role = request.form.get("role", "CUSTOMER").strip().upper()
        address = request.form.get("address", "").strip()
        rest_id_val = request.form.get("restaurant_id", "")
        staff_title = request.form.get("staff_title", "").strip()

        if not name or not email or not password:
            flash("Please fill in all required fields (Name, Email, Password).", "danger")
            return redirect(url_for("register"))

        if len(password) < 6:
            flash("Password must be at least 6 characters long.", "danger")
            return redirect(url_for("register"))

        # Check existing user
        existing = query_one("SELECT user_id FROM APP_USER WHERE email = :email", {"email": email})
        if existing:
            flash(f"An account with email '{email}' already exists. Please log in.", "danger")
            return redirect(url_for("login"))

        restaurant_id = int(rest_id_val) if rest_id_val and rest_id_val.isdigit() else None
        customer_id = None
        staff_id = None

        try:
            # 1. If role is CUSTOMER, ensure record in CUSTOMER table
            if role == "CUSTOMER":
                cust_match = query_one("SELECT customer_id FROM CUSTOMER WHERE LOWER(email) = :email", {"email": email})
                if cust_match:
                    customer_id = cust_match["customer_id"]
                else:
                    conn = get_connection()
                    try:
                        with conn.cursor() as cursor:
                            out_id = cursor.var(oracledb.NUMBER)
                            sql = """
                            INSERT INTO CUSTOMER (name, email, phone, address)
                            VALUES (:name, :email, :phone, :addr)
                            RETURNING customer_id INTO :out_id
                            """
                            cursor.execute(sql, {"name": name, "email": email, "phone": phone, "addr": address, "out_id": out_id})
                            conn.commit()
                            customer_id = int(out_id.getvalue()[0])
                    finally:
                        conn.close()

            # 2. If role is STAFF, ensure record in STAFF table
            elif role == "STAFF":
                if not restaurant_id:
                    flash("Please select an assigned restaurant for Staff registration.", "danger")
                    return redirect(url_for("register"))
                conn = get_connection()
                try:
                    with conn.cursor() as cursor:
                        out_id = cursor.var(oracledb.NUMBER)
                        sql = """
                        INSERT INTO STAFF (restaurant_id, name, role, contact)
                        VALUES (:rest_id, :name, :role_title, :contact)
                        RETURNING staff_id INTO :out_id
                        """
                        cursor.execute(sql, {
                            "rest_id": restaurant_id,
                            "name": name,
                            "role_title": staff_title or "Receptionist / Floor Staff",
                            "contact": phone or "N/A",
                            "out_id": out_id
                        })
                        conn.commit()
                        staff_id = int(out_id.getvalue()[0])
                finally:
                    conn.close()

            # 3. Create record in APP_USER
            pwd_hash = generate_password_hash(password)
            conn = get_connection()
            try:
                with conn.cursor() as cursor:
                    out_user_id = cursor.var(oracledb.NUMBER)
                    sql = """
                    INSERT INTO APP_USER (email, password_hash, full_name, phone, role, staff_title, restaurant_id, customer_id, staff_id)
                    VALUES (:email, :pwd, :name, :phone, :role, :title, :rest_id, :cust_id, :staff_id)
                    RETURNING user_id INTO :out_user_id
                    """
                    cursor.execute(sql, {
                        "email": email,
                        "pwd": pwd_hash,
                        "name": name,
                        "phone": phone,
                        "role": role,
                        "title": staff_title if role == "STAFF" else ("Executive Owner" if role == "OWNER" else None),
                        "rest_id": restaurant_id,
                        "cust_id": customer_id,
                        "staff_id": staff_id,
                        "out_user_id": out_user_id
                    })
                    conn.commit()
                    new_user_id = int(out_user_id.getvalue()[0])
            finally:
                conn.close()

            # Log user in
            session["user_id"] = new_user_id
            session["email"] = email
            session["name"] = name
            session["role"] = role
            session["staff_title"] = staff_title if role == "STAFF" else None
            session["restaurant_id"] = restaurant_id
            session["customer_id"] = customer_id
            session["staff_id"] = staff_id

            flash(f"Account created successfully! Welcome to Restaurant DBMS as {role}.", "success")
            return redirect(url_for("index"))

        except Exception as e:
            flash(f"Registration error: {format_oracle_error(e)}", "danger")
            return redirect(url_for("register"))

    # GET request
    restaurants = query_all("SELECT restaurant_id, name FROM RESTAURANT ORDER BY name")
    return render_template("register.html", restaurants=restaurants)

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "POST":
        email = request.form.get("email", "").strip().lower()
        password = request.form.get("password", "")
        next_url = request.form.get("next", "")

        user = query_one("""
            SELECT user_id, email, password_hash, full_name, phone, role, staff_title,
                   restaurant_id, customer_id, staff_id
            FROM APP_USER
            WHERE LOWER(email) = :email
        """, {"email": email})

        if not user or not check_password_hash(user["password_hash"], password):
            flash("Invalid email address or password. Please try again.", "danger")
            return render_template("login.html")

        # Set session
        session["user_id"] = user["user_id"]
        session["email"] = user["email"]
        session["name"] = user["full_name"]
        session["role"] = user["role"]
        session["staff_title"] = user["staff_title"]
        session["restaurant_id"] = user["restaurant_id"]
        session["customer_id"] = user["customer_id"]
        session["staff_id"] = user["staff_id"]

        flash(f"Signed in as {user['full_name']} ({user['role']}).", "success")
        if next_url and next_url.startswith("/"):
            return redirect(next_url)
        return redirect(url_for("index"))

    return render_template("login.html")

@app.route("/quick-auth/<role>")
def quick_auth(role):
    target_role = role.upper()
    user = query_one("""
        SELECT user_id, email, full_name, role, staff_title, restaurant_id, customer_id, staff_id
        FROM APP_USER
        WHERE role = :r
        ORDER BY user_id ASC
        FETCH FIRST 1 ROWS ONLY
    """, {"r": target_role})
    if user:
        session["user_id"] = user["user_id"]
        session["email"] = user["email"]
        session["name"] = user["full_name"]
        session["role"] = user["role"]
        session["staff_title"] = user["staff_title"]
        session["restaurant_id"] = user["restaurant_id"]
        session["customer_id"] = user["customer_id"]
        session["staff_id"] = user["staff_id"]
    next_url = request.args.get("next", "/")
    return redirect(next_url)


@app.route("/logout")
def logout():
    user_name = session.get("name", "User")
    session.clear()
    flash(f"Goodbye, {user_name}! You have been signed out.", "info")
    return redirect(url_for("login"))

@app.route("/profile")
@login_required
def profile():
    user = query_one("""
        SELECT u.user_id, u.email, u.full_name, u.phone, u.role, u.staff_title,
               u.restaurant_id, u.customer_id, u.staff_id,
               TO_CHAR(u.created_at, 'YYYY-MM-DD') AS created_at_str,
               r.name AS restaurant_name,
               c.address
        FROM APP_USER u
        LEFT JOIN RESTAURANT r ON u.restaurant_id = r.restaurant_id
        LEFT JOIN CUSTOMER c ON u.customer_id = c.customer_id
        WHERE u.user_id = :id
    """, {"id": session.get("user_id")})

    stats = {}
    if user and user["role"] == "CUSTOMER" and user["customer_id"]:
        s_row = query_one("""
            SELECT 
                (SELECT COUNT(*) FROM ORDERS WHERE customer_id = :cid) AS orders_count,
                (SELECT COUNT(*) FROM RESERVATION WHERE customer_id = :cid) AS res_count
            FROM DUAL
        """, {"cid": user["customer_id"]})
        stats = s_row or {}

    return render_template("profile.html", user=user, stats=stats)

# ----------------------------------------------------------------------------
# 2. HOME & ROLE-BASED DASHBOARDS
# ----------------------------------------------------------------------------
@app.route("/")
def index():
    role = session.get("role")

    # 1. CUSTOMER DASHBOARD
    if role == "CUSTOMER":
        cid = session.get("customer_id")
        # Personal KPIs
        kpi_row = query_one("""
            SELECT 
                (SELECT COUNT(*) FROM RESERVATION WHERE customer_id = :cid) AS res_count,
                (SELECT COUNT(*) FROM ORDERS WHERE customer_id = :cid) AS orders_count,
                (SELECT NVL(SUM(total_amount), 0) FROM ORDERS WHERE customer_id = :cid) AS total_spent,
                (SELECT COUNT(*) FROM REVIEW WHERE customer_id = :cid) AS reviews_count
            FROM DUAL
        """, {"cid": cid or -1})
        my_kpis = kpi_row or {"res_count": 0, "orders_count": 0, "total_spent": 0, "reviews_count": 0}

        # My active reservations
        my_reservations = query_all("""
            SELECT res.reservation_id,
                   TO_CHAR(res.reservation_date, 'YYYY-MM-DD') AS res_date,
                   res.time_slot, res.number_of_guests, res.status,
                   r.name AS restaurant_name, t.table_number
            FROM RESERVATION res
            JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
            JOIN DINING_TABLE t ON res.table_id = t.table_id
            WHERE res.customer_id = :cid
            ORDER BY res.reservation_date DESC, res.reservation_id DESC
            FETCH FIRST 5 ROWS ONLY
        """, {"cid": cid or -1})

        # My recent orders
        my_orders = query_all("""
            SELECT o.order_id, o.status AS order_status, o.total_amount,
                   r.name AS restaurant_name
            FROM ORDERS o
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            WHERE o.customer_id = :cid
            ORDER BY o.order_date DESC, o.order_id DESC
            FETCH FIRST 5 ROWS ONLY
        """, {"cid": cid or -1})

        return render_template(
            "index_customer.html",
            my_kpis=my_kpis,
            my_reservations=my_reservations,
            my_orders=my_orders
        )

    # 2. STAFF DASHBOARD
    elif role == "STAFF":
        rest_id = session.get("restaurant_id")
        staff_rest = None
        if rest_id:
            staff_rest = query_one("SELECT * FROM RESTAURANT WHERE restaurant_id = :id", {"id": rest_id})

        # Staff KPIs
        kpis_sql = """
            SELECT
                (SELECT COUNT(*) FROM RESERVATION 
                 WHERE (:rid IS NULL OR restaurant_id = :rid) 
                   AND TRUNC(reservation_date) = TRUNC(SYSDATE)) AS today_res,
                (SELECT COUNT(*) FROM DINING_TABLE 
                 WHERE (:rid IS NULL OR restaurant_id = :rid)) AS total_tables,
                (SELECT COUNT(*) FROM DINING_TABLE 
                 WHERE (:rid IS NULL OR restaurant_id = :rid) AND is_available = 'N') AS tables_occupied,
                (SELECT COUNT(*) FROM ORDERS 
                 WHERE (:rid IS NULL OR restaurant_id = :rid) AND status IN ('PLACED', 'PREPARING')) AS orders_in_kitchen,
                (SELECT COUNT(*) FROM ORDERS 
                 WHERE (:rid IS NULL OR restaurant_id = :rid) AND status = 'READY') AS orders_ready
            FROM DUAL
        """
        kpi_row = query_one(kpis_sql, {"rid": rest_id})
        staff_kpis = kpi_row or {
            "today_res": 0, "total_tables": 0, "tables_occupied": 0,
            "orders_in_kitchen": 0, "orders_ready": 0
        }

        # Today's incoming reservations
        today_res = query_all("""
            SELECT res.reservation_id, res.time_slot, res.number_of_guests, res.status,
                   c.name AS customer_name, c.phone AS customer_phone,
                   t.table_number
            FROM RESERVATION res
            JOIN CUSTOMER c ON res.customer_id = c.customer_id
            JOIN DINING_TABLE t ON res.table_id = t.table_id
            WHERE (:rid IS NULL OR res.restaurant_id = :rid)
            ORDER BY res.reservation_date DESC, res.reservation_id DESC
            FETCH FIRST 6 ROWS ONLY
        """, {"rid": rest_id})

        # Active orders needing attention
        active_orders = query_all("""
            SELECT o.order_id, o.status AS order_status, o.total_amount,
                   c.name AS customer_name
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            WHERE (:rid IS NULL OR o.restaurant_id = :rid)
              AND o.status IN ('PLACED', 'PREPARING', 'READY', 'SERVED')
            ORDER BY o.order_date DESC
            FETCH FIRST 6 ROWS ONLY
        """, {"rid": rest_id})

        return render_template(
            "index_staff.html",
            staff_rest=staff_rest,
            staff_kpis=staff_kpis,
            today_reservations=today_res,
            active_orders=active_orders
        )

    # 3. OWNER DASHBOARD
    elif role == "OWNER":
        counts_sql = """
            SELECT 'Customers' AS label, COUNT(*) AS count, 'bi-people' AS icon, 'primary' AS color FROM CUSTOMER UNION ALL
            SELECT 'Restaurants', COUNT(*), 'bi-shop', 'info' FROM RESTAURANT UNION ALL
            SELECT 'Dining Tables', COUNT(*), 'bi-grid-3x3', 'secondary' FROM DINING_TABLE UNION ALL
            SELECT 'Menu Items', COUNT(*), 'bi-egg-fried', 'warning' FROM MENU_ITEM UNION ALL
            SELECT 'Reservations', COUNT(*), 'bi-calendar-check', 'success' FROM RESERVATION UNION ALL
            SELECT 'Orders Placed', COUNT(*), 'bi-receipt', 'danger' FROM ORDERS UNION ALL
            SELECT 'Staff Members', COUNT(*), 'bi-person-badge', 'info' FROM STAFF UNION ALL
            SELECT 'Customer Reviews', COUNT(*), 'bi-star-fill', 'warning' FROM REVIEW
        """
        counts = query_all(counts_sql)
        rev_row = query_one("SELECT NVL(SUM(amount), 0) AS total_revenue FROM PAYMENT WHERE status = 'SUCCESS'")
        total_revenue = rev_row["total_revenue"] if rev_row else 0
        rating_row = query_one("SELECT NVL(AVG(rating), 0) AS avg_rating FROM REVIEW")
        avg_rating = rating_row["avg_rating"] if rating_row else 0
        user_row = query_one("SELECT COUNT(*) AS total_users FROM APP_USER")
        user_count = user_row["total_users"] if user_row else 0

        branch_summary = query_all("""
            SELECT r.restaurant_id, r.name, r.cuisine_type, r.opening_hour, r.closing_hour, r.phone,
                   (SELECT COUNT(*) FROM DINING_TABLE dt WHERE dt.restaurant_id = r.restaurant_id) AS tables_count,
                   (SELECT NVL(SUM(capacity), 0) FROM DINING_TABLE dt WHERE dt.restaurant_id = r.restaurant_id) AS total_seats
            FROM RESTAURANT r
            ORDER BY r.restaurant_id
        """)

        recent_orders = query_all("""
            SELECT o.order_id, o.order_date, o.status, o.total_amount,
                   c.name AS customer_name, r.name AS restaurant_name
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            ORDER BY o.order_date DESC, o.order_id DESC
            FETCH FIRST 6 ROWS ONLY
        """)

        upcoming_res = query_all("""
            SELECT res.reservation_id, res.time_slot, res.number_of_guests, res.status,
                   c.name AS customer_name, r.name AS restaurant_name, t.table_number
            FROM RESERVATION res
            JOIN CUSTOMER c ON res.customer_id = c.customer_id
            JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
            JOIN DINING_TABLE t ON res.table_id = t.table_id
            ORDER BY res.reservation_date DESC, res.reservation_id DESC
            FETCH FIRST 6 ROWS ONLY
        """)

        return render_template(
            "index_owner.html",
            counts=counts,
            total_revenue=total_revenue,
            avg_rating=avg_rating,
            user_count=user_count,
            branch_summary=branch_summary,
            recent_orders=recent_orders,
            upcoming_res=upcoming_res
        )

    # 4. GUEST / NOT LOGGED IN
    counts_sql = """
        SELECT 'Restaurants' AS label, COUNT(*) AS count, 'bi-shop' AS icon, 'info' AS color FROM RESTAURANT UNION ALL
        SELECT 'Menu Items', COUNT(*), 'bi-egg-fried', 'warning' FROM MENU_ITEM UNION ALL
        SELECT 'Dining Tables', COUNT(*), 'bi-grid-3x3', 'secondary' FROM DINING_TABLE UNION ALL
        SELECT 'Customer Reviews', COUNT(*), 'bi-star-fill', 'warning' FROM REVIEW
    """
    counts = query_all(counts_sql)
    recent_orders = query_all("""
        SELECT o.order_id, o.order_date, o.status, o.total_amount,
               c.name AS customer_name, r.name AS restaurant_name
        FROM ORDERS o
        JOIN CUSTOMER c ON o.customer_id = c.customer_id
        JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
        ORDER BY o.order_date DESC, o.order_id DESC
        FETCH FIRST 4 ROWS ONLY
    """)
    upcoming_res = query_all("""
        SELECT res.reservation_id, res.reservation_date, res.time_slot, res.number_of_guests, res.status,
               c.name AS customer_name, r.name AS restaurant_name, t.table_number
        FROM RESERVATION res
        JOIN CUSTOMER c ON res.customer_id = c.customer_id
        JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
        JOIN DINING_TABLE t ON res.table_id = t.table_id
        WHERE res.status IN ('BOOKED', 'CONFIRMED')
        ORDER BY res.reservation_date ASC, res.reservation_id ASC
        FETCH FIRST 4 ROWS ONLY
    """)
    return render_template(
        "index.html",
        counts=counts,
        recent_orders=recent_orders,
        upcoming_res=upcoming_res
    )

# ----------------------------------------------------------------------------
# 3. CUSTOMERS (Owner Administration Only)
# ----------------------------------------------------------------------------
@app.route("/customers")
@role_required(["OWNER"])
def customers():
    search = request.args.get("q", "").strip()
    if search:
        customers_list = query_all("""
            SELECT c.*,
                   (SELECT COUNT(*) FROM ORDERS o WHERE o.customer_id = c.customer_id) AS total_orders,
                   (SELECT COUNT(*) FROM RESERVATION r WHERE r.customer_id = c.customer_id) AS total_reservations
            FROM CUSTOMER c
            WHERE LOWER(name) LIKE :q OR LOWER(email) LIKE :q OR phone LIKE :q
            ORDER BY customer_id DESC
        """, {"q": f"%{search.lower()}%"})
    else:
        customers_list = query_all("""
            SELECT c.*,
                   (SELECT COUNT(*) FROM ORDERS o WHERE o.customer_id = c.customer_id) AS total_orders,
                   (SELECT COUNT(*) FROM RESERVATION r WHERE r.customer_id = c.customer_id) AS total_reservations
            FROM CUSTOMER c
            ORDER BY customer_id DESC
        """)
    return render_template("customers.html", customers=customers_list, search=search)

@app.route("/customers/create", methods=["POST"])
@role_required(["OWNER"])
def customer_create():
    name = request.form.get("name", "").strip()
    email = request.form.get("email", "").strip().lower()
    phone = request.form.get("phone", "").strip()
    address = request.form.get("address", "").strip()

    if not name or not email:
        flash("Name and email are required fields.", "danger")
        return redirect(url_for("customers"))

    try:
        execute_dml("""
            INSERT INTO CUSTOMER (name, email, phone, address)
            VALUES (:name, :email, :phone, :address)
        """, {"name": name, "email": email, "phone": phone, "address": address})
        flash(f"Customer '{name}' added successfully!", "success")
    except Exception as e:
        flash(f"Failed to add customer: {format_oracle_error(e)}", "danger")
    return redirect(url_for("customers"))

@app.route("/customers/update", methods=["POST"])
@role_required(["OWNER"])
def customer_update():
    cust_id = request.form.get("customer_id")
    name = request.form.get("name", "").strip()
    email = request.form.get("email", "").strip().lower()
    phone = request.form.get("phone", "").strip()
    address = request.form.get("address", "").strip()

    try:
        execute_dml("""
            UPDATE CUSTOMER
            SET name = :name, email = :email, phone = :phone, address = :address
            WHERE customer_id = :id
        """, {"name": name, "email": email, "phone": phone, "address": address, "id": cust_id})
        flash(f"Customer #{cust_id} updated successfully!", "success")
    except Exception as e:
        flash(f"Failed to update customer: {format_oracle_error(e)}", "danger")
    return redirect(url_for("customers"))

@app.route("/customers/delete/<int:customer_id>", methods=["POST"])
@role_required(["OWNER"])
def customer_delete(customer_id):
    try:
        execute_dml("DELETE FROM CUSTOMER WHERE customer_id = :id", {"id": customer_id})
        flash(f"Customer #{customer_id} deleted successfully.", "success")
    except Exception as e:
        flash(f"Cannot delete customer: {format_oracle_error(e)}", "danger")
    return redirect(url_for("customers"))

# ----------------------------------------------------------------------------
# 4. MENU & PRICE HISTORY
# ----------------------------------------------------------------------------
@app.route("/menu")
def menu():
    rest_id = request.args.get("restaurant_id")
    if rest_id and rest_id.isdigit():
        items = query_all("""
            SELECT m.item_id, m.name, m.description, m.is_veg, m.preparation_time,
                   r.restaurant_id, r.name AS restaurant_name,
                   c.category_id, c.name AS category_name,
                   NVL(p.price, 0) AS current_price,
                   (SELECT COUNT(*) FROM PRICE_HISTORY ph WHERE ph.item_id = m.item_id) AS revisions_count
            FROM MENU_ITEM m
            JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
            JOIN CATEGORY c ON m.category_id = c.category_id
            LEFT JOIN PRICE_HISTORY p ON m.item_id = p.item_id AND p.end_date IS NULL
            WHERE m.restaurant_id = :rid
            ORDER BY c.name, m.name
        """, {"rid": int(rest_id)})
    else:
        items = query_all("""
            SELECT m.item_id, m.name, m.description, m.is_veg, m.preparation_time,
                   r.restaurant_id, r.name AS restaurant_name,
                   c.category_id, c.name AS category_name,
                   NVL(p.price, 0) AS current_price,
                   (SELECT COUNT(*) FROM PRICE_HISTORY ph WHERE ph.item_id = m.item_id) AS revisions_count
            FROM MENU_ITEM m
            JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
            JOIN CATEGORY c ON m.category_id = c.category_id
            LEFT JOIN PRICE_HISTORY p ON m.item_id = p.item_id AND p.end_date IS NULL
            ORDER BY r.name, c.name, m.name
        """)

    restaurants = query_all("SELECT restaurant_id, name FROM RESTAURANT ORDER BY name")
    categories = query_all("SELECT category_id, name FROM CATEGORY ORDER BY name")
    return render_template(
        "menu.html",
        items=items,
        restaurants=restaurants,
        categories=categories,
        selected_rest=rest_id
    )

@app.route("/menu/create", methods=["POST"])
@role_required(["OWNER"])
def menu_create():
    rest_id = int(request.form.get("restaurant_id"))
    cat_id = int(request.form.get("category_id"))
    name = request.form.get("name", "").strip()
    description = request.form.get("description", "").strip()
    is_veg = request.form.get("is_veg", "Y")
    prep_time = int(request.form.get("preparation_time", 15))
    initial_price = float(request.form.get("price", 0))

    try:
        conn = get_connection()
        try:
            with conn.cursor() as cursor:
                out_id = cursor.var(oracledb.NUMBER)
                sql_item = """
                    INSERT INTO MENU_ITEM (restaurant_id, category_id, name, description, is_veg, preparation_time)
                    VALUES (:rid, :cid, :name, :descr, :veg, :prep)
                    RETURNING item_id INTO :out_id
                """
                cursor.execute(sql_item, {
                    "rid": rest_id, "cid": cat_id, "name": name,
                    "descr": description, "veg": is_veg, "prep": prep_time,
                    "out_id": out_id
                })
                new_item_id = int(out_id.getvalue()[0])

                # Insert initial price
                cursor.execute("""
                    INSERT INTO PRICE_HISTORY (item_id, price, start_date, end_date)
                    VALUES (:id, :price, TRUNC(SYSDATE), NULL)
                """, {"id": new_item_id, "price": initial_price})
                conn.commit()

            flash(f"Dish '{name}' created with active price ₹{initial_price:.2f}.", "success")
        finally:
            conn.close()
    except Exception as e:
        flash(f"Failed to create menu item: {format_oracle_error(e)}", "danger")
    return redirect(url_for("menu"))

@app.route("/menu/update", methods=["POST"])
@role_required(["OWNER"])
def menu_update():
    item_id = int(request.form.get("item_id"))
    cat_id = int(request.form.get("category_id"))
    name = request.form.get("name", "").strip()
    description = request.form.get("description", "").strip()
    is_veg = request.form.get("is_veg", "Y")
    prep_time = request.form.get("preparation_time", 15)

    try:
        execute_dml("""
            UPDATE MENU_ITEM
            SET category_id = :cid, name = :name, description = :descr,
                is_veg = :veg, preparation_time = :prep
            WHERE item_id = :id
        """, {"cid": cat_id, "name": name, "descr": description, "veg": is_veg, "prep": prep_time, "id": item_id})
        flash(f"Menu item '{name}' updated successfully!", "success")
    except Exception as e:
        flash(f"Failed to update menu item: {format_oracle_error(e)}", "danger")
    return redirect(url_for("menu"))

@app.route("/menu/change-price", methods=["POST"])
@role_required(["OWNER"])
def menu_change_price():
    item_id = int(request.form.get("item_id"))
    new_price = float(request.form.get("new_price"))
    try:
        conn = get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.callproc("sp_set_price", [item_id, new_price, datetime.now()])
                conn.commit()
            flash(f"Price for item #{item_id} updated to ₹{new_price:.2f} (History logged).", "success")
        finally:
            conn.close()
    except Exception as e:
        flash(f"Price update failed: {format_oracle_error(e)}", "danger")
    return redirect(url_for("menu"))

@app.route("/menu/price-history/<int:item_id>")
def menu_price_history(item_id):
    history = query_all("""
        SELECT history_id, price,
               TO_CHAR(start_date, 'YYYY-MM-DD') AS start_date,
               TO_CHAR(end_date, 'YYYY-MM-DD') AS end_date,
               CASE WHEN end_date IS NULL THEN 'Active (Current)' ELSE 'Historical' END AS status
        FROM PRICE_HISTORY
        WHERE item_id = :id
        ORDER BY start_date DESC
    """, {"id": item_id})
    item = query_one("SELECT name FROM MENU_ITEM WHERE item_id = :id", {"id": item_id})
    return jsonify({"item_name": item["name"] if item else f"Item #{item_id}", "history": history})

@app.route("/menu/delete/<int:item_id>", methods=["POST"])
@role_required(["OWNER"])
def menu_delete(item_id):
    try:
        execute_dml("DELETE FROM MENU_ITEM WHERE item_id = :id", {"id": item_id})
        flash(f"Menu item #{item_id} deleted successfully.", "success")
    except Exception as e:
        flash(f"Cannot delete menu item: {format_oracle_error(e)}", "danger")
    return redirect(url_for("menu"))

# ----------------------------------------------------------------------------
# 5. RESERVATIONS
# ----------------------------------------------------------------------------
@app.route("/reservations")
@login_required
def reservations():
    role = session.get("role")
    cid = session.get("customer_id")
    rest_id = session.get("restaurant_id")

    if role == "CUSTOMER" and cid:
        res_list = query_all("""
            SELECT res.reservation_id,
                   TO_CHAR(res.reservation_date, 'YYYY-MM-DD') AS res_date,
                   res.time_slot, res.number_of_guests, res.status,
                   c.customer_id, c.name AS customer_name, c.phone AS customer_phone,
                   r.restaurant_id, r.name AS restaurant_name,
                   t.table_id, t.table_number, t.capacity AS table_capacity
            FROM RESERVATION res
            JOIN CUSTOMER c ON res.customer_id = c.customer_id
            JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
            JOIN DINING_TABLE t ON res.table_id = t.table_id
            WHERE res.customer_id = :cid
            ORDER BY res.reservation_date DESC, res.reservation_id DESC
        """, {"cid": cid})
    elif role == "STAFF" and rest_id:
        res_list = query_all("""
            SELECT res.reservation_id,
                   TO_CHAR(res.reservation_date, 'YYYY-MM-DD') AS res_date,
                   res.time_slot, res.number_of_guests, res.status,
                   c.customer_id, c.name AS customer_name, c.phone AS customer_phone,
                   r.restaurant_id, r.name AS restaurant_name,
                   t.table_id, t.table_number, t.capacity AS table_capacity
            FROM RESERVATION res
            JOIN CUSTOMER c ON res.customer_id = c.customer_id
            JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
            JOIN DINING_TABLE t ON res.table_id = t.table_id
            WHERE res.restaurant_id = :rid
            ORDER BY res.reservation_date DESC, res.reservation_id DESC
        """, {"rid": rest_id})
    else:
        res_list = query_all("""
            SELECT res.reservation_id,
                   TO_CHAR(res.reservation_date, 'YYYY-MM-DD') AS res_date,
                   res.time_slot, res.number_of_guests, res.status,
                   c.customer_id, c.name AS customer_name, c.phone AS customer_phone,
                   r.restaurant_id, r.name AS restaurant_name,
                   t.table_id, t.table_number, t.capacity AS table_capacity
            FROM RESERVATION res
            JOIN CUSTOMER c ON res.customer_id = c.customer_id
            JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
            JOIN DINING_TABLE t ON res.table_id = t.table_id
            ORDER BY res.reservation_date DESC, res.reservation_id DESC
        """)

    customers = query_all("SELECT customer_id, name, email FROM CUSTOMER ORDER BY name")
    restaurants = query_all("SELECT restaurant_id, name FROM RESTAURANT ORDER BY name")
    tables = query_all("SELECT table_id, restaurant_id, table_number, capacity FROM DINING_TABLE WHERE is_available = 'Y' ORDER BY table_number")
    return render_template(
        "reservations.html",
        reservations=res_list,
        customers=customers,
        restaurants=restaurants,
        tables=tables
    )

@app.route("/api/tables")
def api_tables():
    rest_id = request.args.get("restaurant_id")
    date_str = request.args.get("date")
    time_slot = request.args.get("slot")
    party_size = request.args.get("guests", 1)

    if not rest_id or not date_str or not time_slot:
        return jsonify([])

    try:
        tables = query_all("""
            SELECT t.table_id, t.table_number, t.capacity
            FROM DINING_TABLE t
            WHERE t.restaurant_id = :rest_id
              AND t.is_available = 'Y'
              AND t.capacity >= :party_size
              AND NOT EXISTS (
                  SELECT 1 FROM RESERVATION r
                  WHERE r.table_id = t.table_id
                    AND TRUNC(r.reservation_date) = TO_DATE(:res_date, 'YYYY-MM-DD')
                    AND r.time_slot = :slot
                    AND r.status IN ('BOOKED', 'CONFIRMED')
              )
            ORDER BY t.capacity ASC, t.table_number ASC
        """, {
            "rest_id": int(rest_id),
            "party_size": int(party_size),
            "res_date": date_str,
            "slot": time_slot
        })
        return jsonify(tables)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/reservations/create", methods=["POST"])
@login_required
def reservation_create():
    role = session.get("role")
    if role == "CUSTOMER":
        customer_id = session.get("customer_id")
    else:
        customer_id = int(request.form.get("customer_id"))

    restaurant_id = int(request.form.get("restaurant_id"))
    table_id = int(request.form.get("table_id"))
    res_date = request.form.get("reservation_date")
    time_slot = request.form.get("time_slot")
    guests = int(request.form.get("number_of_guests", 2))

    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            out_res_id = cursor.var(oracledb.NUMBER)
            cursor.callproc("sp_make_reservation", [
                customer_id, table_id,
                datetime.strptime(res_date, "%Y-%m-%d"),
                time_slot, guests, out_res_id
            ])
            conn.commit()
            new_id = int(out_res_id.getvalue())
            flash(f"Reservation #{new_id} booked successfully!", "success")
    except Exception as e:
        flash(f"Reservation failed: {format_oracle_error(e)}", "danger")
    finally:
        conn.close()
    return redirect(url_for("reservations"))

@app.route("/reservations/update", methods=["POST"])
@login_required
def reservation_update():
    res_id = int(request.form.get("reservation_id"))
    guests = int(request.form.get("number_of_guests"))
    time_slot = request.form.get("time_slot")
    status = request.form.get("status")

    try:
        execute_dml("""
            UPDATE RESERVATION
            SET number_of_guests = :g, time_slot = :s, status = :st
            WHERE reservation_id = :id
        """, {"g": guests, "s": time_slot, "st": status, "id": res_id})
        flash(f"Reservation #{res_id} updated.", "success")
    except Exception as e:
        flash(f"Update failed: {format_oracle_error(e)}", "danger")
    return redirect(url_for("reservations"))

@app.route("/reservations/cancel/<int:reservation_id>", methods=["POST"])
@login_required
def reservation_cancel(reservation_id):
    try:
        conn = get_connection()
        try:
            with conn.cursor() as cursor:
                cursor.callproc("sp_cancel_reservation", [reservation_id])
                conn.commit()
            flash(f"Reservation #{reservation_id} cancelled and slot is now freed.", "success")
        finally:
            conn.close()
    except Exception as e:
        flash(f"Cancellation error: {format_oracle_error(e)}", "danger")
    return redirect(url_for("reservations"))

@app.route("/reservations/delete/<int:reservation_id>", methods=["POST"])
@role_required(["OWNER"])
def reservation_delete(reservation_id):
    try:
        execute_dml("DELETE FROM RESERVATION WHERE reservation_id = :id", {"id": reservation_id})
        flash(f"Reservation #{reservation_id} record deleted.", "success")
    except Exception as e:
        flash(f"Cannot delete reservation: {format_oracle_error(e)}", "danger")
    return redirect(url_for("reservations"))

# ----------------------------------------------------------------------------
# 6. ORDERS & BILLING
# ----------------------------------------------------------------------------
@app.route("/orders")
@login_required
def orders():
    role = session.get("role")
    cid = session.get("customer_id")
    rest_id = session.get("restaurant_id")

    if role == "CUSTOMER" and cid:
        orders_list = query_all("""
            SELECT o.order_id,
                   TO_CHAR(o.order_date, 'YYYY-MM-DD HH24:MI') AS order_date,
                   o.status AS order_status, o.total_amount,
                   c.customer_id, c.name AS customer_name,
                   r.restaurant_id, r.name AS restaurant_name,
                   p.payment_id, p.payment_method, p.status AS payment_status,
                   (SELECT COUNT(*) FROM ORDER_ITEM oi WHERE oi.order_id = o.order_id) AS items_count
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            LEFT JOIN PAYMENT p ON o.order_id = p.order_id
            WHERE o.customer_id = :cid
            ORDER BY o.order_date DESC, o.order_id DESC
        """, {"cid": cid})
    elif role == "STAFF" and rest_id:
        orders_list = query_all("""
            SELECT o.order_id,
                   TO_CHAR(o.order_date, 'YYYY-MM-DD HH24:MI') AS order_date,
                   o.status AS order_status, o.total_amount,
                   c.customer_id, c.name AS customer_name,
                   r.restaurant_id, r.name AS restaurant_name,
                   p.payment_id, p.payment_method, p.status AS payment_status,
                   (SELECT COUNT(*) FROM ORDER_ITEM oi WHERE oi.order_id = o.order_id) AS items_count
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            LEFT JOIN PAYMENT p ON o.order_id = p.order_id
            WHERE o.restaurant_id = :rid
            ORDER BY o.order_date DESC, o.order_id DESC
        """, {"rid": rest_id})
    else:
        orders_list = query_all("""
            SELECT o.order_id,
                   TO_CHAR(o.order_date, 'YYYY-MM-DD HH24:MI') AS order_date,
                   o.status AS order_status, o.total_amount,
                   c.customer_id, c.name AS customer_name,
                   r.restaurant_id, r.name AS restaurant_name,
                   p.payment_id, p.payment_method, p.status AS payment_status,
                   (SELECT COUNT(*) FROM ORDER_ITEM oi WHERE oi.order_id = o.order_id) AS items_count
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            LEFT JOIN PAYMENT p ON o.order_id = p.order_id
            ORDER BY o.order_date DESC, o.order_id DESC
        """)

    customers = query_all("SELECT customer_id, name FROM CUSTOMER ORDER BY name")
    restaurants = query_all("SELECT restaurant_id, name FROM RESTAURANT ORDER BY name")
    return render_template("orders.html", orders=orders_list, customers=customers, restaurants=restaurants)

@app.route("/orders/create", methods=["POST"])
@login_required
def order_create():
    role = session.get("role")
    if role == "CUSTOMER":
        customer_id = session.get("customer_id")
    else:
        customer_id = int(request.form.get("customer_id"))

    restaurant_id = int(request.form.get("restaurant_id"))

    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            out_id = cursor.var(oracledb.NUMBER)
            cursor.callproc("sp_create_order", [customer_id, restaurant_id, out_id])
            conn.commit()
            new_id = int(out_id.getvalue())
            flash(f"Order #{new_id} created successfully! Add dishes below.", "success")
            return redirect(url_for("order_detail", order_id=new_id))
    except Exception as e:
        flash(f"Order creation failed: {format_oracle_error(e)}", "danger")
        return redirect(url_for("orders"))
    finally:
        conn.close()

@app.route("/orders/<int:order_id>")
@login_required
def order_detail(order_id):
    order = query_one("""
        SELECT o.order_id,
               TO_CHAR(o.order_date, 'YYYY-MM-DD HH24:MI') AS order_date_str,
               o.status AS order_status, o.total_amount,
               c.customer_id, c.name AS customer_name, c.email AS customer_email, c.phone AS customer_phone,
               r.restaurant_id, r.name AS restaurant_name,
               p.payment_id, p.payment_method, p.status AS payment_status, p.amount AS paid_amount,
               TO_CHAR(p.payment_date, 'YYYY-MM-DD HH24:MI') AS payment_date_str
        FROM ORDERS o
        JOIN CUSTOMER c ON o.customer_id = c.customer_id
        JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
        LEFT JOIN PAYMENT p ON o.order_id = p.order_id
        WHERE o.order_id = :id
    """, {"id": order_id})

    if not order:
        flash("Order not found.", "danger")
        return redirect(url_for("orders"))

    # Security check: if customer, ensure order belongs to them
    if session.get("role") == "CUSTOMER" and order["customer_id"] != session.get("customer_id"):
        flash("Access denied: You can only view your own orders.", "danger")
        return redirect(url_for("orders"))

    items = query_all("""
        SELECT oi.order_item_id, oi.item_id, oi.quantity,
               fn_price_on(oi.item_id, o.order_date) AS unit_price,
               (oi.quantity * fn_price_on(oi.item_id, o.order_date)) AS line_subtotal,
               m.name AS item_name, m.is_veg, c.name AS category_name
        FROM ORDER_ITEM oi
        JOIN ORDERS o ON oi.order_id = o.order_id
        JOIN MENU_ITEM m ON oi.item_id = m.item_id
        JOIN CATEGORY c ON m.category_id = c.category_id
        WHERE oi.order_id = :id
        ORDER BY oi.order_item_id ASC
    """, {"id": order_id})

    available_items = query_all("""
        SELECT m.item_id, m.name, c.name AS category_name, NVL(p.price, 0) AS price
        FROM MENU_ITEM m
        JOIN CATEGORY c ON m.category_id = c.category_id
        LEFT JOIN PRICE_HISTORY p ON m.item_id = p.item_id AND p.end_date IS NULL
        WHERE m.restaurant_id = :rid
        ORDER BY m.name
    """, {"rid": order["restaurant_id"]})

    return render_template(
        "order_detail.html",
        order=order,
        items=items,
        available_items=available_items
    )

@app.route("/orders/<int:order_id>/add-item", methods=["POST"])
@login_required
def order_add_item(order_id):
    item_id = int(request.form.get("item_id"))
    qty = int(request.form.get("quantity", 1))

    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.callproc("sp_add_order_item", [order_id, item_id, qty])
            conn.commit()
        flash("Dish added to order. Total amount recalculated automatically.", "success")
    except Exception as e:
        flash(f"Could not add dish: {format_oracle_error(e)}", "danger")
    finally:
        conn.close()
    return redirect(url_for("order_detail", order_id=order_id))

@app.route("/orders/<int:order_id>/update-item", methods=["POST"])
@login_required
def order_update_item(order_id):
    order_item_id = int(request.form.get("order_item_id"))
    quantity = int(request.form.get("quantity"))

    try:
        execute_dml("""
            UPDATE ORDER_ITEM
            SET quantity = :qty
            WHERE order_item_id = :id
        """, {"qty": quantity, "id": order_item_id})
        flash("Line item quantity updated. Trigger updated total amount.", "success")
    except Exception as e:
        flash(f"Update failed: {format_oracle_error(e)}", "danger")
    return redirect(url_for("order_detail", order_id=order_id))

@app.route("/orders/<int:order_id>/delete-item/<int:order_item_id>", methods=["POST"])
@login_required
def order_delete_item(order_id, order_item_id):
    try:
        execute_dml("DELETE FROM ORDER_ITEM WHERE order_item_id = :id", {"id": order_item_id})
        flash("Line item removed. Running order total adjusted.", "success")
    except Exception as e:
        flash(f"Delete item error: {format_oracle_error(e)}", "danger")
    return redirect(url_for("order_detail", order_id=order_id))

@app.route("/orders/<int:order_id>/update-status", methods=["POST"])
@role_required(["STAFF", "OWNER"])
def order_update_status(order_id):
    new_status = request.form.get("new_status")
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.callproc("sp_update_order_status", [order_id, new_status])
            conn.commit()
        flash(f"Order #{order_id} status advanced to {new_status}.", "success")
    except Exception as e:
        flash(f"Status update rejected: {format_oracle_error(e)}", "danger")
    finally:
        conn.close()
    return redirect(url_for("order_detail", order_id=order_id))

@app.route("/orders/<int:order_id>/record-payment", methods=["POST"])
@app.route("/orders/<int:order_id>/pay", methods=["POST"])
@login_required
def order_record_payment(order_id):
    amount = float(request.form.get("amount"))
    method = request.form.get("payment_method")
    status = request.form.get("status", "SUCCESS")

    try:
        execute_dml("""
            INSERT INTO PAYMENT (order_id, amount, payment_method, payment_date, status)
            VALUES (:oid, :amt, :method, SYSDATE, :status)
        """, {"oid": order_id, "amt": amount, "method": method, "status": status})
        flash(f"Payment of ₹{amount:.2f} ({method}) recorded successfully!", "success")
    except Exception as e:
        flash(f"Payment validation failed: {format_oracle_error(e)}", "danger")
    return redirect(url_for("order_detail", order_id=order_id))

@app.route("/orders/delete/<int:order_id>", methods=["POST"])
@role_required(["OWNER"])
def order_delete(order_id):
    try:
        execute_dml("DELETE FROM ORDERS WHERE order_id = :id", {"id": order_id})
        flash(f"Order #{order_id} deleted successfully.", "success")
    except Exception as e:
        flash(f"Cannot delete order: {format_oracle_error(e)}", "danger")
    return redirect(url_for("orders"))

# ----------------------------------------------------------------------------
# 7. REVIEWS
# ----------------------------------------------------------------------------
@app.route("/reviews")
@login_required
def reviews():
    role = session.get("role")
    cid = session.get("customer_id")

    reviews_list = query_all("""
        SELECT rev.review_id, rev.rating, rev.review_comment,
               TO_CHAR(rev.review_date, 'YYYY-MM-DD') AS review_date,
               c.name AS customer_name,
               r.name AS restaurant_name,
               o.order_id, o.total_amount
        FROM REVIEW rev
        JOIN CUSTOMER c ON rev.customer_id = c.customer_id
        JOIN RESTAURANT r ON rev.restaurant_id = r.restaurant_id
        JOIN ORDERS o ON rev.order_id = o.order_id
        ORDER BY rev.review_date DESC, rev.review_id DESC
    """)

    # Eligible orders
    if role == "CUSTOMER" and cid:
        eligible_orders = query_all("""
            SELECT o.order_id, o.total_amount, c.name AS customer_name, r.name AS restaurant_name
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            JOIN PAYMENT p ON o.order_id = p.order_id AND p.status = 'SUCCESS'
            WHERE o.status IN ('SERVED', 'DELIVERED')
              AND o.customer_id = :cid
              AND NOT EXISTS (SELECT 1 FROM REVIEW rev WHERE rev.order_id = o.order_id)
            ORDER BY o.order_id DESC
        """, {"cid": cid})
    else:
        eligible_orders = query_all("""
            SELECT o.order_id, o.total_amount, c.name AS customer_name, r.name AS restaurant_name
            FROM ORDERS o
            JOIN CUSTOMER c ON o.customer_id = c.customer_id
            JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
            JOIN PAYMENT p ON o.order_id = p.order_id AND p.status = 'SUCCESS'
            WHERE o.status IN ('SERVED', 'DELIVERED')
              AND NOT EXISTS (SELECT 1 FROM REVIEW rev WHERE rev.order_id = o.order_id)
            ORDER BY o.order_id DESC
        """)

    return render_template(
        "reviews.html",
        reviews=reviews_list,
        eligible_orders=eligible_orders
    )

@app.route("/reviews/create", methods=["POST"])
@login_required
def review_create():
    order_id = int(request.form.get("order_id"))
    rating = int(request.form.get("rating"))
    comment_text = request.form.get("comment", "").strip()

    ord_info = query_one("""
        SELECT customer_id, restaurant_id FROM ORDERS WHERE order_id = :id
    """, {"id": order_id})

    if not ord_info:
        flash("Referenced order not found.", "danger")
        return redirect(url_for("reviews"))

    try:
        execute_dml("""
            INSERT INTO REVIEW (customer_id, restaurant_id, order_id, rating, review_comment, review_date)
            VALUES (:cid, :rid, :oid, :rating, :rev_comment, SYSDATE)
        """, {
            "cid": ord_info["customer_id"],
            "rid": ord_info["restaurant_id"],
            "oid": order_id,
            "rating": rating,
            "rev_comment": comment_text
        })
        flash("Thank you! Your verified dining review has been posted.", "success")
    except Exception as e:
        flash(f"Review rejected: {format_oracle_error(e)}", "danger")
    return redirect(url_for("reviews"))

@app.route("/reviews/delete/<int:review_id>", methods=["POST"])
@role_required(["OWNER"])
def review_delete(review_id):
    try:
        execute_dml("DELETE FROM REVIEW WHERE review_id = :id", {"id": review_id})
        flash(f"Review #{review_id} removed by administrator.", "success")
    except Exception as e:
        flash(f"Cannot delete review: {format_oracle_error(e)}", "danger")
    return redirect(url_for("reviews"))

# ----------------------------------------------------------------------------
# 8. REPORTS (12 SQL & PL/SQL Queries - Restricted to Owner)
# ----------------------------------------------------------------------------
@app.route("/reports")
@role_required(["OWNER"])
def reports():
    q_num = request.args.get("q", "1")
    restaurants = query_all("SELECT restaurant_id, name FROM RESTAURANT ORDER BY name")

    query_metadata = {
        "1": {
            "title": "Available Dining Tables by Slot & Capacity",
            "technique": "Subquery with NOT EXISTS filter against active reservations",
            "sql": """SELECT t.table_id, t.table_number, t.capacity, r.name AS restaurant_name
FROM DINING_TABLE t
JOIN RESTAURANT r ON t.restaurant_id = r.restaurant_id
WHERE t.restaurant_id = :p_rest_id
  AND t.is_available = 'Y'
  AND t.capacity >= :p_cap
  AND NOT EXISTS (
      SELECT 1 FROM RESERVATION res
      WHERE res.table_id = t.table_id
        AND TRUNC(res.reservation_date) = TO_DATE(:p_date, 'YYYY-MM-DD')
        AND res.time_slot = :p_slot
        AND res.status IN ('BOOKED', 'CONFIRMED')
  )
ORDER BY t.capacity ASC, t.table_number ASC"""
        },
        "2": {
            "title": "Top Selling Dishes by Quantity & Revenue",
            "technique": "Multi-table JOIN with GROUP BY and aggregate SUM ordering",
            "sql": """SELECT m.item_id, m.name AS dish_name, c.name AS category_name,
       r.name AS restaurant_name,
       SUM(oi.quantity) AS total_quantity_sold,
       SUM(oi.quantity * oi.unit_price) AS total_revenue
FROM ORDER_ITEM oi
JOIN MENU_ITEM m ON oi.item_id = m.item_id
JOIN CATEGORY c ON m.category_id = c.category_id
JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
GROUP BY m.item_id, m.name, c.name, r.name
ORDER BY total_quantity_sold DESC, total_revenue DESC"""
        },
        "3": {
            "title": "Monthly Revenue per Restaurant Branch",
            "technique": "Date grouping with TO_CHAR, SUM aggregation, and chronological sort",
            "sql": """SELECT r.name AS restaurant_name,
       TO_CHAR(p.payment_date, 'YYYY-MM') AS month_period,
       COUNT(DISTINCT o.order_id) AS settled_orders_count,
       SUM(p.amount) AS total_monthly_revenue
FROM PAYMENT p
JOIN ORDERS o ON p.order_id = o.order_id
JOIN RESTAURANT r ON o.restaurant_id = r.restaurant_id
WHERE p.status = 'SUCCESS'
GROUP BY r.name, TO_CHAR(p.payment_date, 'YYYY-MM')
ORDER BY r.name, month_period DESC"""
        },
        "4": {
            "title": "Loyal High-Frequency Customers",
            "technique": "Aggregate GROUP BY with HAVING clause filtering > 2 orders",
            "sql": """SELECT c.customer_id, c.name AS customer_name, c.email, c.phone,
       COUNT(o.order_id) AS total_orders,
       NVL(SUM(o.total_amount), 0) AS total_spent,
       NVL(AVG(o.total_amount), 0) AS avg_ticket_size
FROM CUSTOMER c
JOIN ORDERS o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name, c.email, c.phone
HAVING COUNT(o.order_id) >= 2
ORDER BY total_spent DESC, total_orders DESC"""
        },
        "5": {
            "title": "Restaurant Performance & Average Ratings",
            "technique": "LEFT OUTER JOIN with NVL and AVG aggregation across reviews",
            "sql": """SELECT r.restaurant_id, r.name AS restaurant_name, r.cuisine_type,
       COUNT(rev.review_id) AS total_reviews_received,
       NVL(ROUND(AVG(rev.rating), 2), 0) AS avg_star_rating,
       (SELECT COUNT(*) FROM ORDERS o WHERE o.restaurant_id = r.restaurant_id) AS all_time_orders
FROM RESTAURANT r
LEFT JOIN REVIEW rev ON r.restaurant_id = rev.restaurant_id
GROUP BY r.restaurant_id, r.name, r.cuisine_type
ORDER BY avg_star_rating DESC, total_reviews_received DESC"""
        },
        "6": {
            "title": "Price History Audit & Active vs Historical Rates",
            "technique": "Self-contained history scan using PRICE_HISTORY with CASE classification",
            "sql": """SELECT m.item_id, m.name AS dish_name, r.name AS restaurant_name,
       ph.price,
       TO_CHAR(ph.start_date, 'YYYY-MM-DD') AS effective_from,
       TO_CHAR(ph.end_date, 'YYYY-MM-DD') AS effective_until,
       CASE WHEN ph.end_date IS NULL THEN 'Active Current' ELSE 'Historical' END AS price_state
FROM PRICE_HISTORY ph
JOIN MENU_ITEM m ON ph.item_id = m.item_id
JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
ORDER BY m.item_id, ph.start_date DESC"""
        },
        "7": {
            "title": "Customers Reserving Tables with No Orders",
            "technique": "Subquery with NOT EXISTS correlating CUSTOMER between RESERVATION and ORDERS",
            "sql": """SELECT DISTINCT c.customer_id, c.name AS customer_name, c.email, c.phone,
       r.name AS reserved_restaurant,
       TO_CHAR(res.reservation_date, 'YYYY-MM-DD') AS reservation_date,
       res.time_slot
FROM RESERVATION res
JOIN CUSTOMER c ON res.customer_id = c.customer_id
JOIN RESTAURANT r ON res.restaurant_id = r.restaurant_id
WHERE NOT EXISTS (
    SELECT 1 FROM ORDERS o
    WHERE o.customer_id = res.customer_id
      AND o.restaurant_id = res.restaurant_id
      AND TRUNC(o.order_date) = TRUNC(res.reservation_date)
)
ORDER BY c.customer_id"""
        },
        "8": {
            "title": "Unpaid Orders Auditing via Database View",
            "technique": "Querying Oracle Relational View v_order_summary for billing discrepancies",
            "sql": """SELECT order_id, customer_name, restaurant_name,
       order_date, order_status, total_amount, payment_status, items_count
FROM v_order_summary
WHERE payment_status = 'UNPAID'
ORDER BY order_id DESC"""
        },
        "9": {
            "title": "Registered Customers with Zero Food Orders",
            "technique": "Set difference using NOT EXISTS against the ORDERS master table",
            "sql": """SELECT c.customer_id, c.name, c.email, c.phone,
       TO_CHAR(c.reg_date, 'YYYY-MM-DD') AS registration_date
FROM CUSTOMER c
WHERE NOT EXISTS (
    SELECT 1 FROM ORDERS o WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_id ASC"""
        },
        "10": {
            "title": "Top-3 Highest Priced Dishes per Restaurant",
            "technique": "Analytic Window Function DENSE_RANK() OVER (PARTITION BY ...)",
            "sql": """SELECT ranked.restaurant_name, ranked.dish_name,
       ranked.category_name, ranked.price, ranked.price_rank
FROM (
    SELECT r.name AS restaurant_name,
           m.name AS dish_name,
           c.name AS category_name,
           ph.price,
           DENSE_RANK() OVER (PARTITION BY m.restaurant_id ORDER BY ph.price DESC) AS price_rank
    FROM MENU_ITEM m
    JOIN RESTAURANT r ON m.restaurant_id = r.restaurant_id
    JOIN CATEGORY c ON m.category_id = c.category_id
    JOIN PRICE_HISTORY ph ON m.item_id = ph.item_id AND ph.end_date IS NULL
) ranked
WHERE ranked.price_rank <= 3
ORDER BY ranked.restaurant_name, ranked.price_rank"""
        },
        "11": {
            "title": "PL/SQL Procedure: sp_daily_sales_report (Explicit Cursor)",
            "technique": "PL/SQL stored procedure utilizing explicit cursor and DBMS_OUTPUT capture",
            "sql": """DECLARE
    -- PL/SQL execution wrapper
BEGIN
    sp_daily_sales_report(
        p_restaurant_id => :p_rest_id,
        p_report_date   => TO_DATE(:p_date, 'YYYY-MM-DD')
    );
END;"""
        },
        "12": {
            "title": "PL/SQL Procedure: sp_customer_spend_report (Ref Cursor)",
            "technique": "PL/SQL stored procedure returning an open SYS_REFCURSOR to client",
            "sql": """DECLARE
    v_rc SYS_REFCURSOR;
BEGIN
    sp_customer_spend_report(
        p_min_orders => :p_min_orders,
        p_report_rc  => v_rc
    );
END;"""
        }
    }

    meta = query_metadata.get(q_num, query_metadata["1"])
    results = []
    columns = []
    plsql_output = ""

    # Execute query
    try:
        if q_num == "1":
            p_rest = int(request.args.get("p_rest_id", 1))
            p_date = request.args.get("p_date", "2026-10-15")
            p_slot = request.args.get("p_slot", "19:00-21:00")
            p_cap = int(request.args.get("p_cap", 4))
            results = query_all(meta["sql"], {
                "p_rest_id": p_rest, "p_date": p_date,
                "p_slot": p_slot, "p_cap": p_cap
            })
        elif q_num == "11":
            p_rest = int(request.args.get("p_rest_id", 1))
            p_date = request.args.get("p_date", "2026-06-10")
            conn = get_connection()
            try:
                with conn.cursor() as cursor:
                    cursor.callproc("dbms_output.enable", [50000])
                    cursor.callproc("sp_daily_sales_report", [
                        p_rest, datetime.strptime(p_date, "%Y-%m-%d")
                    ])
                    lines = []
                    line_var = cursor.var(oracledb.STRING)
                    status_var = cursor.var(oracledb.NUMBER)
                    while True:
                        cursor.callproc("dbms_output.get_line", [line_var, status_var])
                        if status_var.getvalue() != 0:
                            break
                        lines.append(line_var.getvalue())
                    plsql_output = "\n".join(lines)
            finally:
                conn.close()
        elif q_num == "12":
            p_min = int(request.args.get("p_min_orders", 2))
            conn = get_connection()
            try:
                with conn.cursor() as cursor:
                    ref_cursor = conn.cursor()
                    cursor.callproc("sp_customer_spend_report", [p_min, ref_cursor])
                    cols = [col[0].lower() for col in ref_cursor.description]
                    rows = ref_cursor.fetchall()
                    results = [dict(zip(cols, r)) for r in rows]
            finally:
                conn.close()
        else:
            results = query_all(meta["sql"])

        if results:
            columns = list(results[0].keys())

    except Exception as e:
        flash(f"Query execution error: {format_oracle_error(e)}", "danger")

    return render_template(
        "reports.html",
        query_num=q_num,
        query_title=meta["title"],
        query_technique=meta["technique"],
        query_sql=meta["sql"],
        results=results,
        columns=columns,
        plsql_output=plsql_output,
        restaurants=restaurants
    )

# ============================================================================
# DA3: SURREALDB MULTI-MODEL DATABASE EXTENSION ROUTES
# ============================================================================
import time
from surreal_db import db_engine

@app.route("/surreal")
def surreal_dashboard():
    """Main DA3 SurrealDB Showcase & Interactive Playground"""
    tables_summary = {tbl: len(recs) for tbl, recs in db_engine.tables.items()}
    total_records = sum(tables_summary.values())
    total_edges = len(db_engine.edges)
    query_history = db_engine.query_log[:10]
    restaurants = list(db_engine.tables.get("restaurant", {}).values())
    menu_items = list(db_engine.tables.get("menu_item", {}).values())
    customers = list(db_engine.tables.get("customer", {}).values())
    edges_sample = db_engine.edges[-10:]

    return render_template(
        "surreal_dashboard.html",
        tables_summary=tables_summary,
        total_records=total_records,
        total_edges=total_edges,
        query_history=query_history,
        restaurants=restaurants,
        menu_items=menu_items,
        customers=customers,
        edges_sample=edges_sample
    )

@app.route("/api/surreal/query", methods=["POST"])
def surreal_query_api():
    """Execute arbitrary SurrealQL query and return JSON"""
    data = request.get_json(silent=True) or {}
    query = data.get("query", "").strip()
    if not query:
        return jsonify({"status": "ERR", "error": "Query cannot be empty", "time": "0ms", "result": []})
    response = db_engine.execute_surrealql(query)
    return jsonify(response)

@app.route("/api/surreal/order", methods=["POST"])
def surreal_order_api():
    """Create a new live order using RELATE customer->ordered->menu_item"""
    data = request.get_json(silent=True) or {}
    customer_id = data.get("customer_id", "customer:c101")
    item_id = data.get("item_id", "menu_item:m103")
    quantity = int(data.get("quantity", 1))
    spice = data.get("spice", "Medium")

    item = db_engine.get_record(item_id) or {}
    price = item.get("price", 350.0)
    subtotal = price * quantity
    order_num = f"ORD-{int(time.time() * 1000) % 10000}"

    edge = db_engine.relate(customer_id, "ordered", item_id, {
        "order_id": order_num,
        "quantity": quantity,
        "unit_price": price,
        "subtotal": subtotal,
        "customization": {"spice": spice},
        "order_status": "PLACED"
    })

    return jsonify({
        "status": "OK",
        "message": f"Live order {order_num} placed via SurrealDB graph relation!",
        "edge": edge
    })

@app.route("/api/surreal/graph-data", methods=["GET"])
def surreal_graph_data_api():
    """Returns Cytoscape.js compatible graph elements (nodes and edges)"""
    relation_filter = request.args.get("relation", "all")
    elements = db_engine.get_cytoscape_elements(filter_rel=relation_filter)
    return jsonify({
        "status": "OK",
        "elements": elements,
        "counts": {
            "nodes": len(elements["nodes"]),
            "edges": len(elements["edges"])
        }
    })

@app.route("/api/surreal/recommend/<item_id>", methods=["GET"])
def surreal_recommend_api(item_id):
    """Knowledge graph traversal for dish co-ordering recommendations"""
    recs = db_engine.get_recommendations(item_id)
    return jsonify({
        "status": "OK",
        "item_id": item_id,
        "recommendations": recs
    })

@app.route("/api/surreal/customer-profile/<customer_id>", methods=["GET"])
def surreal_customer_profile_api(customer_id):
    """Customer 360 view via direct graph traversals (0 SQL JOINs)"""
    customer = db_engine.get_record(customer_id)
    if not customer:
        return jsonify({"status": "ERR", "message": f"Customer {customer_id} not found"}), 404

    reservations = db_engine.traverse(customer_id, "reserved", "dining_table")
    orders = db_engine.traverse(customer_id, "ordered", "menu_item")

    return jsonify({
        "status": "OK",
        "customer": customer,
        "reservations": reservations,
        "orders": orders
    })

@app.route("/api/surreal/reset", methods=["POST"])
def surreal_reset_api():
    """Reset and re-seed SurrealDB"""
    db_engine.reset()
    db_engine.seed_default_data()
    db_engine.save_to_disk()
    return jsonify({"status": "OK", "message": "SurrealDB successfully re-seeded from surreal_data.surql!"})

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=True)


