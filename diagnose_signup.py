import urllib.request
import json
import sys
import ssl
import pg8000.native

SUPABASE_URL = "https://mdzjpybrzoyxixhrydbf.supabase.co"
ANON_KEY = "sb_publishable_rV4ivdoK7vh7OinTC60iJg_09Tt_eMA"

def main():
    print("Diagnosing signup issues...\n")

    # Test 1: Check if Auth endpoint is reachable and key works
    print("Test 1: Check Auth API endpoint reachability")
    headers = {
        "apikey": ANON_KEY,
        "Content-Type": "application/json"
    }
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/settings",
        headers=headers
    )
    try:
        with urllib.request.urlopen(req) as resp:
            body = json.loads(resp.read())
            print(f"  Auth API: HTTP {resp.status} OK")
            print(f"  Email signups enabled: {body.get('disable_signup') == False or 'disable_signup' not in body}")
            print(f"  Email confirmations required: {body.get('mailer_autoconfirm', False) == False}")
            print(f"  Full settings: {json.dumps(body, indent=2)}")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  Auth API ERROR {e.code}: {body}")

    # Test 2: Attempt a test signup to see actual error
    print("\nTest 2: Attempt signup with test credentials")
    payload = json.dumps({
        "email": "testuser_diag@workway.com",
        "password": "TestPass123!",
        "data": {"full_name": "Test Diagnostic User", "role": "job_seeker"}
    }).encode()
    headers2 = {
        "apikey": ANON_KEY,
        "Content-Type": "application/json"
    }
    req2 = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/signup",
        data=payload,
        headers=headers2
    )
    try:
        with urllib.request.urlopen(req2) as resp:
            body = json.loads(resp.read())
            print(f"  Signup: HTTP {resp.status}")
            print(f"  User ID returned: {body.get('id') or body.get('user', {}).get('id', 'N/A')}")
            email_confirmed = body.get('user', {}).get('email_confirmed_at')
            print(f"  Email confirmed_at: {email_confirmed}")
            if email_confirmed is None:
                print("  *** EMAIL CONFIRMATION IS REQUIRED - users must verify email before logging in ***")
            else:
                print("  Email auto-confirmation is ON - users can log in immediately")
    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  Signup ERROR {e.code}: {body}")

    # Test 3: Check correct JWT anon key format
    print("\nTest 3: Verify Supabase key format compatibility")
    ssl_ctx = ssl.create_default_context()
    ssl_ctx.check_hostname = False
    ssl_ctx.verify_mode = ssl.CERT_NONE
    con = pg8000.native.Connection(
        user="postgres.mdzjpybrzoyxixhrydbf",
        password="22Horizon00@JMS",
        host="aws-1-eu-west-1.pooler.supabase.com",
        port=6543,
        database="postgres",
        ssl_context=ssl_ctx
    )
    # Get the actual anon key from the vault/config
    try:
        result = con.run("SELECT current_setting('request.jwt.claims', true);")
        print(f"  JWT Claims config: {result}")
    except Exception as e:
        print(f"  JWT claims check: {e}")
    
    try:
        result = con.run("""
            SELECT value FROM vault.secrets WHERE name IN ('anon_key', 'service_role') LIMIT 5;
        """)
        print(f"  Vault secrets: {result}")
    except Exception as e:
        print(f"  Vault check: {e}")

    con.close()
    print("\nDiagnosis complete.")

if __name__ == "__main__":
    main()
