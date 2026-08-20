import ssl
import sys
import pg8000.native

def main():
    print("Connecting to Supabase PostgreSQL Database...")
    ssl_context = ssl.create_default_context()
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE

    try:
        con = pg8000.native.Connection(
            user="postgres.mdzjpybrzoyxixhrydbf",
            password="22Horizon00@JMS",
            host="aws-1-eu-west-1.pooler.supabase.com",
            port=6543,
            database="postgres",
            ssl_context=ssl_context,
            timeout=30
        )
        print("Connected successfully to Supabase!")

        with open("supabase-db-setup.sql", "r", encoding="utf-8") as f:
            sql_script = f.read()

        print("Executing schema migration script...")
        con.run(sql_script)
        print("Schema successfully executed!")

        # Verify created tables in public schema
        tables = con.run("""
            SELECT table_name 
            FROM information_schema.tables 
            WHERE table_schema = 'public'
            ORDER BY table_name;
        """)

        print("\n=== Public Tables Created in Supabase ===")
        for t in tables:
            print(f"- {t[0]}")

        con.close()
        print("\nAll database tables and policies are live on Supabase!")

    except Exception as e:
        print(f"Error during migration: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
