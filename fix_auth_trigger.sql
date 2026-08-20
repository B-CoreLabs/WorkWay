-- ==============================================================================
-- FIX: Auth Trigger & Profile Permissions for Supabase
-- Error: "Database error saving new user" on signup
-- Root cause: Missing grants & trigger function needs adjustments
-- ==============================================================================

-- 1. Grant the auth schema access to public tables
GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;

GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO postgres, anon, authenticated, service_role;

-- 2. Set default privileges for future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public
    GRANT ALL ON FUNCTIONS TO postgres, anon, authenticated, service_role;

-- 3. Drop and recreate the trigger function with proper error handling and permissions
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP FUNCTION IF EXISTS public.handle_new_user();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    user_role_val user_role;
BEGIN
    -- Safely parse the role from metadata, defaulting to job_seeker
    BEGIN
        user_role_val := COALESCE(
            (new.raw_user_meta_data->>'role')::user_role,
            'job_seeker'::user_role
        );
    EXCEPTION WHEN invalid_text_representation THEN
        user_role_val := 'job_seeker'::user_role;
    END;

    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        role,
        created_at,
        updated_at
    )
    VALUES (
        new.id,
        new.email,
        COALESCE(
            new.raw_user_meta_data->>'full_name',
            split_part(new.email, '@', 1)
        ),
        user_role_val,
        NOW(),
        NOW()
    )
    ON CONFLICT (id) DO UPDATE
        SET email      = EXCLUDED.email,
            full_name  = COALESCE(EXCLUDED.full_name, public.profiles.full_name),
            role       = COALESCE(EXCLUDED.role, public.profiles.role),
            updated_at = NOW();

    RETURN new;
EXCEPTION WHEN OTHERS THEN
    -- Log the error but do not block user creation
    RAISE WARNING 'handle_new_user: failed for %, error: %', new.email, SQLERRM;
    RETURN new;
END;
$$;

-- 4. Re-create the trigger on auth.users
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- 5. Grant the trigger function explicit execution rights
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO supabase_auth_admin;

-- 6. Verify the trigger is active
SELECT
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers
WHERE trigger_name = 'on_auth_user_created';
