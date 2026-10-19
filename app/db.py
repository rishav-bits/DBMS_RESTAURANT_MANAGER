"""
Database Access Layer for Restaurant Table Reservation & Food Ordering System
Uses python-oracledb in thin mode with connection pooling.
"""

import os
import oracledb
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

DB_USER = os.getenv("ORACLE_USER", "restaurant_app")
DB_PASSWORD = os.getenv("ORACLE_PASSWORD", "restaurant_pass")
DB_HOST = os.getenv("ORACLE_HOST", "localhost")
DB_PORT = int(os.getenv("ORACLE_PORT", "1521"))
DB_SERVICE = os.getenv("ORACLE_SERVICE", "XEPDB1")

_pool = None

def init_pool():
    global _pool
    if _pool is None:
        _pool = oracledb.create_pool(
            user=DB_USER,
            password=DB_PASSWORD,
            host=DB_HOST,
            port=DB_PORT,
            service_name=DB_SERVICE,
            min=1,
            max=5,
            increment=1
        )
    return _pool

def get_connection():
    pool = init_pool()
    return pool.acquire()

def query_all(sql, params=None):
    """Execute a SELECT query and return rows as list of dicts."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or {})
            columns = [col[0].lower() for col in cursor.description]
            rows = cursor.fetchall()
            return [dict(zip(columns, row)) for row in rows]
    finally:
        conn.close()

def query_one(sql, params=None):
    """Execute a SELECT query and return a single row as dict, or None."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or {})
            columns = [col[0].lower() for col in cursor.description]
            row = cursor.fetchone()
            if row:
                return dict(zip(columns, row))
            return None
    finally:
        conn.close()

def execute(sql, params=None):
    """Execute generic SQL / DDL statement."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or {})
            conn.commit()
    finally:
        conn.close()

def execute_dml(sql, params=None):
    """Execute INSERT, UPDATE, or DELETE with commit."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(sql, params or {})
            conn.commit()
            return cursor.rowcount
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()

def execute_proc(proc_name, params=None):
    """Call a PL/SQL stored procedure."""
    conn = get_connection()
    try:
        with conn.cursor() as cursor:
            cursor.callproc(proc_name, params or [])
            conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()
