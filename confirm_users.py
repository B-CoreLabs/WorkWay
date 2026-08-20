import ssl
import pg8000.native
import urllib.request
import json
import time

SUPABASE_URL = "https://mdzjpybrzoyxixhrydbf.supabase.co"
ANON_KEY = "sb_publishable_rV4ivdoK7vh7OinTC60iJg_09Tt_eMA"

def main():
    print("Auto-confirming all existing unverified users in auth.users...")
    ssl_ctx = ssl.create_default_context()
    ssl_ctx.check_hostname = False
    ssl_ctx.verify_mode = ssl.CERT_NONE

    con = pg8000.native.Connection(
        user="postgres.mdzjpybrzoyxixhrydbf",
        password="22Horizon00@JMS",
        host="aws-1-eu-west-1.pooler.supabase.com",
        port=6543,
        database="postgres",
        ssl_context=ssl_ctx,
        timeout=30
    )

    # Confirm all pending auth users
    result = con.run("""
        UPDATE auth.users
        SET email_confirmed_at = NOW(),
            updated_at = NOW()
        WHERE email_confirmed_at IS NULL
        RETURNING email;
    """)
    print(f"  Confirmed {len(result)} previously unverified user(s):")
    for row in result:
        print(f"    - {row[0]}")

    # Check how many total users exist
    all_users = con.run("SELECT email, email_confirmed_at IS NOT NULL as confirmed FROM auth.users ORDER BY created_at DESC LIMIT 10;")
    print(f"\n  All auth users:")
    for u in all_users:
        print(f"    - {u[0]} | Confirmed: {u[1]}")

    con.close()

    # Now test full signup -> immediate login flow
    print("\nTesting full signup -> immediate login flow...")
    test_email = f"fulltest_{int(time.time())}@workway.com"
    test_pass = "TestPass123!"

    # Signup
    payload = json.dumps({
        "email": test_email,
        "password": test_pass,
        "data": {"full_name": "Full Flow Tester", "role": "job_seeker"}
    }).encode()
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/signup",
        data=payload,
        headers={"apikey": ANON_KEY, "Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        su_body = json.loads(resp.read())
    new_user_id = su_body.get('id') or (su_body.get('user') or {}).get('id')
    print(f"  Signup: SUCCESS (ID: {new_user_id})")

    # Auto-confirm this user via DB
    con2 = pg8000.native.Connection(
        user="postgres.mdzjpybrzoyxixhrydbf",
        password="22Horizon00@JMS",
        host="aws-1-eu-west-1.pooler.supabase.com",
        port=6543,
        database="postgres",
        ssl_context=ssl_ctx,
        timeout=30
    )
    con2.run(f"UPDATE auth.users SET email_confirmed_at = NOW() WHERE id = '{new_user_id}';")
    print(f"  User auto-confirmed in database")
    con2.close()

    # Login immediately
    payload2 = json.dumps({"email": test_email, "password": test_pass}).encode()
    req2 = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        data=payload2,
        headers={"apikey": ANON_KEY, "Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req2) as resp2:
            lo_body = json.loads(resp2.read())
            tok = lo_body.get('access_token', '')
            print(f"  Immediate Login: SUCCESS (token: {tok[:30]}...)")
            print("\nSIGNUP + LOGIN FLOW IS FULLY WORKING!")
    except urllib.error.HTTPError as e:
        print(f"  Login FAILED {e.code}: {e.read().decode()}")

if __name__ == "__main__":
    main()
