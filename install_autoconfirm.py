import ssl
import pg8000.native

def main():
    print("Creating auto-confirm trigger for all future signups...")

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

    # Drop old trigger if exists
    con.run("DROP TRIGGER IF EXISTS auto_confirm_email ON auth.users;")
    con.run("DROP FUNCTION IF EXISTS public.auto_confirm_user();")

    # Create auto-confirm function
    con.run("""
        CREATE OR REPLACE FUNCTION public.auto_confirm_user()
        RETURNS trigger
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $$
        BEGIN
            -- Auto-confirm email immediately on registration
            IF new.email_confirmed_at IS NULL THEN
                new.email_confirmed_at := NOW();
            END IF;
            RETURN new;
        END;
        $$;
    """)
    print("  Created auto_confirm_user() function")

    # Create trigger that fires BEFORE INSERT so it modifies the row
    con.run("""
        CREATE TRIGGER auto_confirm_email
            BEFORE INSERT ON auth.users
            FOR EACH ROW
            EXECUTE FUNCTION public.auto_confirm_user();
    """)
    print("  Created auto_confirm_email trigger on auth.users")

    # Grant execution rights
    con.run("GRANT EXECUTE ON FUNCTION public.auto_confirm_user() TO supabase_auth_admin;")
    print("  Granted execution rights to supabase_auth_admin")

    # Verify trigger exists
    result = con.run("""
        SELECT trigger_name, event_manipulation, action_timing
        FROM information_schema.triggers
        WHERE trigger_name IN ('auto_confirm_email', 'on_auth_user_created')
        ORDER BY trigger_name;
    """)
    print(f"\n  Active auth triggers:")
    for row in result:
        print(f"    - {row[0]} | {row[2]} {row[1]}")

    con.close()
    print("\nAuto-confirm trigger installed. New users will NEVER need email verification!")

if __name__ == "__main__":
    main()
