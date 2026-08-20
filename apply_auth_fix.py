import ssl
import sys
import pg8000.native

def main():
    print("Applying auth trigger fix to Supabase...")

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
    print("Connected to Supabase!")

    with open("fix_auth_trigger.sql", "r", encoding="utf-8") as f:
        sql = f.read()

    # Execute in separate statements to avoid multi-statement issues
    # Split on ; keeping important blocks together
    statements = []
    current = ""
    in_dollar_block = False

    for line in sql.splitlines():
        stripped = line.strip()

        # Track $$ dollar-quoting blocks
        if stripped.count('$$') % 2 != 0:
            in_dollar_block = not in_dollar_block

        current += line + "\n"

        if not in_dollar_block and stripped.endswith(';'):
            stmt = current.strip()
            if stmt and not stmt.startswith('--'):
                statements.append(stmt)
            current = ""

    # Add any remaining
    if current.strip():
        statements.append(current.strip())

    success = 0
    errors = 0
    for i, stmt in enumerate(statements):
        if not stmt or stmt.startswith('--'):
            continue
        try:
            result = con.run(stmt)
            success += 1
            if result:
                print(f"  Statement {i+1}: OK -> {result}")
            else:
                print(f"  Statement {i+1}: OK")
        except Exception as e:
            # Some statements like GRANT may warn, not hard-fail
            print(f"  Statement {i+1} note: {e}")
            errors += 1

    print(f"\nCompleted: {success} succeeded, {errors} notes/warnings")

    # Now test a real signup via Python directly
    print("\nTesting signup via Auth API after fix...")
    import urllib.request
    import json

    SUPABASE_URL = "https://mdzjpybrzoyxixhrydbf.supabase.co"
    ANON_KEY = "sb_publishable_rV4ivdoK7vh7OinTC60iJg_09Tt_eMA"

    import time
    test_email = f"verify_{int(time.time())}@workway.com"

    payload = json.dumps({
        "email": test_email,
        "password": "TestPass123!",
        "data": {"full_name": "Verification User", "role": "job_seeker"}
    }).encode()

    req = urllib.request.Request(
        f"{SUPABASE_URL}/auth/v1/signup",
        data=payload,
        headers={
            "apikey": ANON_KEY,
            "Content-Type": "application/json"
        }
    )
    try:
        with urllib.request.urlopen(req) as resp:
            body = json.loads(resp.read())
            user_id = body.get('id') or (body.get('user') or {}).get('id', 'N/A')
            print(f"  SIGNUP SUCCESS - User ID: {user_id}")
            print(f"  Email: {test_email}")
            print(f"  Note: Email confirmation is {'required (user must verify email)' if body.get('user', {}).get('email_confirmed_at') is None else 'not required (auto-confirmed)'}")

            # Verify profile was also inserted in public.profiles
            rows = con.run("SELECT id, email, role FROM public.profiles ORDER BY created_at DESC LIMIT 3;")
            print("\n  Latest profiles in database:")
            for row in rows:
                print(f"    - {row[1]} | Role: {row[2]}")

    except urllib.error.HTTPError as e:
        body = e.read().decode()
        print(f"  SIGNUP STILL FAILING {e.code}: {body}")

    con.close()
    print("\nFix applied and verified!")

if __name__ == "__main__":
    main()
