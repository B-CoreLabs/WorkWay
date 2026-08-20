import ssl
import sys
import pg8000.native

def main():
    print("Connecting to Supabase PostgreSQL to configure Storage...")
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
        print("Connected successfully!")

        with open("supabase-storage-setup.sql", "r", encoding="utf-8") as f:
            sql_script = f.read()

        print("Creating storage buckets and RLS upload policies...")
        con.run(sql_script)
        print("Storage setup executed successfully!")

        # Verify buckets in storage.buckets table
        buckets = con.run("""
            SELECT id, name, public, file_size_limit
            FROM storage.buckets
            ORDER BY name;
        """)

        print("\n=== Storage Buckets Active in Supabase ===")
        for b in buckets:
            print(f"- Bucket: '{b[1]}' (Public: {b[2]}, Max Size: {b[3] / (1024*1024):.1f} MB)")

        con.close()
        print("\nStorage is fully configured and ready for image uploads!")

    except Exception as e:
        print(f"Error during storage configuration: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
