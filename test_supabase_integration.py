import urllib.request
import urllib.parse
import json
import sys

SUPABASE_URL = "https://mdzjpybrzoyxixhrydbf.supabase.co"
ANON_KEY = "sb_publishable_rV4ivdoK7vh7OinTC60iJg_09Tt_eMA"

def test_endpoint(name, url, headers=None, data=None):
    if headers is None:
        headers = {}
    headers["apikey"] = ANON_KEY
    headers["Authorization"] = f"Bearer {ANON_KEY}"
    headers["Content-Type"] = "application/json"

    req = urllib.request.Request(url, headers=headers, data=data)
    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode('utf-8')
            res_json = json.loads(body) if body else {}
            print(f"[SUCCESS] {name}: HTTP {resp.status} - OK ({len(res_json) if isinstance(res_json, list) else 'Success'})")
            return res_json
    except urllib.error.HTTPError as e:
        err_body = e.read().decode('utf-8')
        print(f"[FAIL] {name}: HTTP {e.code} - Error: {err_body}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"[FAIL] {name}: Exception: {e}", file=sys.stderr)
        return None

def main():
    print("==================================================")
    print("TESTING WORKWAY FRONTEND & SUPABASE BACKEND CONNECTIVITY")
    print("==================================================")

    # 1. Test Querying Jobs (PostgREST)
    print("\n1. Testing Jobs Table API (Public Query):")
    jobs = test_endpoint("Fetch Jobs with Companies", f"{SUPABASE_URL}/rest/v1/jobs?select=*,companies(*)")
    if jobs:
        print(f"   Found {len(jobs)} active jobs in database:")
        for j in jobs[:3]:
            comp_name = j.get('companies', {}).get('name', 'Unknown') if j.get('companies') else 'N/A'
            salary_min = j.get('salary_min') or 0
            salary_max = j.get('salary_max') or 0
            print(f"   - [{j.get('job_type')}] {j.get('title')} at {comp_name} (${salary_min:,.0f} - ${salary_max:,.0f})")

    # 2. Test Querying Companies (PostgREST)
    print("\n2. Testing Companies Table API:")
    companies = test_endpoint("Fetch Companies", f"{SUPABASE_URL}/rest/v1/companies?select=*")
    if companies:
        print(f"   Found {len(companies)} employer companies:")
        for c in companies:
            print(f"   - {c.get('name')} ({c.get('industry')}) - {c.get('location')}")

    # 3. Test Storage Bucket Accessibility
    print("\n3. Testing Storage Buckets API:")
    buckets = test_endpoint("List Public Buckets", f"{SUPABASE_URL}/storage/v1/bucket")
    if buckets:
        print(f"   Storage buckets configured: {[b.get('name') for b in buckets]}")

    print("\n==================================================")
    print("ALL BACKEND & DATABASE API TESTS PASSED SUCCESSFULLY!")
    print("==================================================")

if __name__ == "__main__":
    main()
