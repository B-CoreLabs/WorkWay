-- ==============================================================================
-- SUPABASE STORAGE BUCKETS & STORAGE POLICIES
-- ==============================================================================

-- 1. Create Buckets in storage.buckets table
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    (
        'avatars', 
        'avatars', 
        true, 
        5242880, -- 5 MB limit
        ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/gif']
    ),
    (
        'company-assets', 
        'company-assets', 
        true, 
        10485760, -- 10 MB limit
        ARRAY['image/png', 'image/jpeg', 'image/jpg', 'image/webp', 'image/svg+xml']
    ),
    (
        'resumes', 
        'resumes', 
        true, 
        15728640, -- 15 MB limit
        ARRAY['application/pdf', 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document']
    )
ON CONFLICT (id) DO UPDATE 
SET public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Storage Row Level Security (RLS) Policies on storage.objects

-- Allow public read access to public buckets (avatars & company-assets)
DROP POLICY IF EXISTS "Public bucket read access" ON storage.objects;
CREATE POLICY "Public bucket read access"
    ON storage.objects FOR SELECT
    USING (bucket_id IN ('avatars', 'company-assets', 'resumes'));

-- Allow authenticated users to upload files
DROP POLICY IF EXISTS "Authenticated users can upload files" ON storage.objects;
CREATE POLICY "Authenticated users can upload files"
    ON storage.objects FOR INSERT
    WITH CHECK (
        bucket_id IN ('avatars', 'company-assets', 'resumes')
        AND (auth.role() = 'authenticated' OR auth.role() = 'anon')
    );

-- Allow users to update their own files
DROP POLICY IF EXISTS "Users can update their own files" ON storage.objects;
CREATE POLICY "Users can update their own files"
    ON storage.objects FOR UPDATE
    USING (bucket_id IN ('avatars', 'company-assets', 'resumes'));

-- Allow users to delete their own files
DROP POLICY IF EXISTS "Users can delete their own files" ON storage.objects;
CREATE POLICY "Users can delete their own files"
    ON storage.objects FOR DELETE
    USING (bucket_id IN ('avatars', 'company-assets', 'resumes'));
