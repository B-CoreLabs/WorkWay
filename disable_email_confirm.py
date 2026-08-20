import ssl
import pg8000.native

def main():
    print("Disabling email confirmation requirement in Supabase Auth...")

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
    print("Connected!")

    # Turn on auto-confirm so users can log in immediately after signup
    con.run("UPDATE auth.config SET mailer_autoconfirm = TRUE WHERE TRUE;")
    print("  Set mailer_autoconfirm = TRUE")

    # Also auto-confirm any existing unconfirmed users so they can log in
    con.run("""
        UPDATE auth.users
        SET email_confirmed_at = NOW()
        WHERE email_confirmed_at IS NULL;
    """)
    print("  Auto-confirmed all existing pending users")

    # Verify
    result = con.run("SELECT mailer_autoconfirm FROM auth.config LIMIT 1;")
    print(f"  Verified mailer_autoconfirm = {result[0][0]}")

    # Test a fresh signup now passes without needing email verification
    import urllib.request, json, time

    SUPABASE_URL = "https://mdzjpybrzoyxixhrydbf.supabase.co"
    ANON_KEY = "sb_publishable_rV4ivdoK7vh7OinTC60iJg_09Tt_eMA"
    test_email = f"autotest_{int(time.time())}@workway.com"
    test_pass  = "TestPass123!"

    # Sign up
    payload = json.dumps({
        "email": test_email,
        "password": test_pass,
        "data": {"full_name": "Auto Test User", "role": "recruiter"}
    }).encode()
    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/signup",
        data=payload,
        headers={"apikey": ANON_KEY, "Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        su_body = json.loads(resp.read())
    user_id = su_body.get('id') or (su_body.get('user') or {}).get('id', 'N/A')
    print(f"\n  Signup test: user created ({user_id})")

    # Immediately log in without verifying email
    payload2 = json.dumps({"email": test_email, "password": test_pass}).encode()
    req2 = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/token?grant_type=password",
        data=payload2,
        headers={"apikey": ANON_KEY, "Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req2) as resp2:
            lo_body = json.loads(resp2.read())
            access_token = lo_body.get('access_token', '')
            print(f"  Immediate login test: SUCCESS (token received: {access_token[:30]}...)")
            print("\n  Signup -> Login flow is fully working without email verification!")
    except urllib.error.HTTPError as e:
        print(f"  Login test FAILED {e.code}: {e.read().decode()}")

    con.close()
    print("\nEmail confirmation disabled. Users can now register and log in instantly!")

if __name__ == "__main__":
    main()
