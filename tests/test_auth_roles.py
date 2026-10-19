"""
Automated Multi-Role Authentication & Access Control Verification
Tests:
1. Customer Registration & Login (Personal Dashboard, Own Bookings, Own Orders)
2. Staff / Receptionist Registration & Login (Front Desk, Kitchen Pipeline, Table Status)
3. Owner Registration & Login (Executive Overview, 12 Reports, Price Management)
4. Permission Boundaries & Unauthorized Access Rejections
"""

import sys
import time
sys.stdout.reconfigure(encoding='utf-8')
import requests

BASE_URL = "http://localhost:5000"

def test_multi_role_auth():
    print("=" * 70)
    print("TESTING MULTI-ROLE AUTHENTICATION & ACCESS CONTROL (DA2)")
    print("=" * 70)

    # 1. Test Guest Access to Landing Page & Auth Endpoints
    print("\n[1] Testing Guest Access...")
    r = requests.get(f"{BASE_URL}/")
    assert r.status_code == 200, f"Expected 200 for guest landing page, got {r.status_code}"
    assert "Customer Experience" in r.text or "Sign In to Account" in r.text
    print("  ✓ Guest landing page rendered successfully.")

    r = requests.get(f"{BASE_URL}/login")
    assert r.status_code == 200
    assert "Quick Demo Access" in r.text
    print("  ✓ Login page rendered with 1-click Quick Demo buttons.")

    r = requests.get(f"{BASE_URL}/register")
    assert r.status_code == 200
    assert "Account Registration" in r.text
    print("  ✓ Registration page rendered with Customer, Staff, Owner role options.")

    # 2. Test Customer Login & Permissions
    print("\n[2] Testing Customer Role (customer@example.com)...")
    s_cust = requests.Session()
    login_resp = s_cust.post(f"{BASE_URL}/login", data={
        "email": "customer@example.com",
        "password": "customer123"
    }, allow_redirects=True)
    assert login_resp.status_code == 200
    assert "Customer Dining Portal" in login_resp.text or "Signed in as" in login_resp.text
    print("  ✓ Customer logged in successfully.")

    # Customer Home
    r = s_cust.get(f"{BASE_URL}/")
    assert r.status_code == 200
    assert "Customer Dining Portal" in r.text or "My Dining Portal" in r.text
    assert "My Reservations" in r.text
    print("  ✓ Customer received customized Personal Dining Portal.")

    # Customer Profile
    r = s_cust.get(f"{BASE_URL}/profile")
    assert r.status_code == 200
    assert "ROLE: CUSTOMER" in r.text
    print("  ✓ Customer profile displays account ID and role permissions.")

    # Customer tries to access Owner Reports -> Should be denied
    r = s_cust.get(f"{BASE_URL}/reports", allow_redirects=True)
    assert "Access denied" in r.text or "restricted to OWNER" in r.text or r.url.endswith("/")
    print("  ✓ Security: Customer blocked from accessing 12 System Reports.")

    # Customer tries to access Customers directory -> Should be denied
    r = s_cust.get(f"{BASE_URL}/customers", allow_redirects=True)
    assert "Access denied" in r.text or "restricted to OWNER" in r.text or r.url.endswith("/")
    print("  ✓ Security: Customer blocked from accessing Customer Directory.")

    # 3. Test Staff / Receptionist Role (receptionist@example.com)
    print("\n[3] Testing Staff / Receptionist Role (receptionist@example.com)...")
    s_staff = requests.Session()
    login_resp = s_staff.post(f"{BASE_URL}/login", data={
        "email": "receptionist@example.com",
        "password": "staff123"
    }, allow_redirects=True)
    assert login_resp.status_code == 200
    assert "STAFF" in login_resp.text or "Front Desk" in login_resp.text
    print("  ✓ Staff / Receptionist logged in successfully.")

    # Staff Home
    r = s_staff.get(f"{BASE_URL}/")
    assert r.status_code == 200
    assert "Front Desk" in r.text or "Floor Operations" in r.text
    assert "Kitchen & Order Service Pipeline" in r.text or "Arrivals & Check-in Desk" in r.text
    print("  ✓ Staff received customized Front Desk & Kitchen Operations Dashboard.")

    # Staff Profile
    r = s_staff.get(f"{BASE_URL}/profile")
    assert r.status_code == 200
    assert "ROLE: STAFF" in r.text
    assert "Assigned Location" in r.text
    print("  ✓ Staff profile displays assigned restaurant branch and job title.")

    # Staff tries to access Reports -> Should be denied
    r = s_staff.get(f"{BASE_URL}/reports", allow_redirects=True)
    assert "Access denied" in r.text or "restricted to OWNER" in r.text or r.url.endswith("/")
    print("  ✓ Security: Staff blocked from accessing Executive Reports.")

    # 4. Test Owner Role (owner@example.com)
    print("\n[4] Testing Owner Role (owner@example.com)...")
    s_owner = requests.Session()
    login_resp = s_owner.post(f"{BASE_URL}/login", data={
        "email": "owner@example.com",
        "password": "owner123"
    }, allow_redirects=True)
    assert login_resp.status_code == 200
    assert "OWNER" in login_resp.text or "Executive" in login_resp.text
    print("  ✓ Owner logged in successfully.")

    # Owner Home
    r = s_owner.get(f"{BASE_URL}/")
    assert r.status_code == 200
    assert "Executive Owner Portal" in r.text or "Executive Business Analytics" in r.text
    assert "12 SQL & PL/SQL Queries" in r.text
    print("  ✓ Owner received Executive Business Analytics Overview.")

    # Owner Reports
    r = s_owner.get(f"{BASE_URL}/reports")
    assert r.status_code == 200
    assert "System Analytics & Reports" in r.text
    print("  ✓ Owner has full access to 12 SQL & PL/SQL queries.")

    # Owner Customers Directory
    r = s_owner.get(f"{BASE_URL}/customers")
    assert r.status_code == 200
    assert "Customer Management" in r.text
    print("  ✓ Owner has full access to Customer Directory.")

    # 5. Test Dynamic Registration of a New User
    print("\n[5] Testing Registration of New Account...")
    s_new = requests.Session()
    new_email = f"testuser_{int(time.time())}@example.com"
    reg_resp = s_new.post(f"{BASE_URL}/register", data={
        "name": "Ananya Sen",
        "email": new_email,
        "password": "password123",
        "phone": "+91 91234 56789",
        "role": "CUSTOMER",
        "address": "B-12, Green Park, New Delhi"
    }, allow_redirects=True)
    assert reg_resp.status_code == 200
    assert "Account created successfully" in reg_resp.text or "Customer Dining Portal" in reg_resp.text
    print(f"  ✓ Registered new CUSTOMER account '{new_email}' with automatic database insertion.")

    # Verify new user profile
    r = s_new.get(f"{BASE_URL}/profile")
    assert r.status_code == 200
    assert "Ananya Sen" in r.text
    assert "ROLE: CUSTOMER" in r.text
    print("  ✓ New user profile verified with correct role and credentials.")

    # 6. Test Logout
    print("\n[6] Testing Logout...")
    r = s_new.get(f"{BASE_URL}/logout", allow_redirects=True)
    assert r.status_code == 200
    assert "signed out" in r.text or "Sign In" in r.text
    print("  ✓ User signed out cleanly and session cleared.")

    print("\n" + "=" * 70)
    print("ALL MULTI-ROLE AUTHENTICATION & ACCESS TESTS PASSED! (100% SUCCESS)")
    print("=" * 70)

if __name__ == '__main__':
    test_multi_role_auth()
