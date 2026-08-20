-- ==============================================================================
-- WORKWAY DATABASE SCHEMA FOR SUPABASE
-- Run this complete script in the Supabase SQL Editor (Dashboard > SQL Editor)
-- ==============================================================================

-- 1. EXTENSIONS & CUSTOM TYPES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('job_seeker', 'recruiter', 'admin');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE job_type AS ENUM ('full_time', 'part_time', 'contract', 'remote', 'internship');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE experience_level AS ENUM ('entry', 'mid', 'senior', 'lead', 'executive');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE TYPE application_status AS ENUM ('applied', 'reviewing', 'shortlisted', 'interviewing', 'rejected', 'offered', 'hired');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 2. CORE TABLES
-- ==============================================================================

-- User Profiles (Extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'job_seeker',
    full_name TEXT,
    headline TEXT,
    bio TEXT,
    avatar_url TEXT,
    resume_url TEXT,
    skills TEXT[] DEFAULT '{}',
    experience_years INTEGER DEFAULT 0,
    location TEXT,
    phone TEXT,
    portfolio_url TEXT,
    linkedin_url TEXT,
    github_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company / Employer Profiles
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    website TEXT,
    industry TEXT,
    company_size TEXT,
    description TEXT,
    location TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Job Postings
CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    recruiter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    requirements TEXT[] DEFAULT '{}',
    skills_required TEXT[] DEFAULT '{}',
    job_type job_type NOT NULL DEFAULT 'full_time',
    experience_level experience_level NOT NULL DEFAULT 'mid',
    location TEXT NOT NULL,
    is_remote BOOLEAN DEFAULT FALSE,
    salary_min NUMERIC,
    salary_max NUMERIC,
    salary_currency TEXT DEFAULT 'USD',
    is_active BOOLEAN DEFAULT TRUE,
    views_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Job Applications
CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    applicant_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_url TEXT,
    cover_letter TEXT,
    match_score NUMERIC(5,2) DEFAULT 85.0,
    status application_status NOT NULL DEFAULT 'applied',
    recruiter_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(job_id, applicant_id)
);

-- Saved / Bookmarked Jobs
CREATE TABLE IF NOT EXISTS public.saved_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, job_id)
);

-- Conversations (Messaging)
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    applicant_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    recruiter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(applicant_id, recruiter_id, job_id)
);

-- Direct Messages
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Notifications
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    link TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 3. INDEXES FOR PERFORMANCE
-- ==============================================================================
CREATE INDEX IF NOT EXISTS idx_jobs_is_active ON public.jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_jobs_company_id ON public.jobs(company_id);
CREATE INDEX IF NOT EXISTS idx_jobs_recruiter_id ON public.jobs(recruiter_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_job_id ON public.job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_applicant_id ON public.job_applications(applicant_id);
CREATE INDEX IF NOT EXISTS idx_saved_jobs_user_id ON public.saved_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conversation_id ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);

-- ==============================================================================
-- 4. AUTOMATED AUTH USER PROFILE TRIGGER
-- ==============================================================================
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        email,
        full_name,
        role
    )
    VALUES (
        new.id,
        new.email,
        COALESCE(new.raw_user_meta_data->>'full_name', split_part(new.email, '@', 1)),
        COALESCE((new.raw_user_meta_data->>'role')::user_role, 'job_seeker'::user_role)
    )
    ON CONFLICT (id) DO UPDATE
    SET full_name = EXCLUDED.full_name,
        role = EXCLUDED.role;
        
    RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- ==============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
DROP POLICY IF EXISTS "Public profiles are viewable by everyone" ON public.profiles;
CREATE POLICY "Public profiles are viewable by everyone"
    ON public.profiles FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Users can update their own profile" ON public.profiles;
CREATE POLICY "Users can update their own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can insert their own profile" ON public.profiles;
CREATE POLICY "Users can insert their own profile"
    ON public.profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

-- COMPANIES POLICIES
DROP POLICY IF EXISTS "Companies viewable by everyone" ON public.companies;
CREATE POLICY "Companies viewable by everyone"
    ON public.companies FOR SELECT
    USING (true);

DROP POLICY IF EXISTS "Recruiters can insert companies" ON public.companies;
CREATE POLICY "Recruiters can insert companies"
    ON public.companies FOR INSERT
    WITH CHECK (auth.uid() = created_by);

DROP POLICY IF EXISTS "Recruiters can update own companies" ON public.companies;
CREATE POLICY "Recruiters can update own companies"
    ON public.companies FOR UPDATE
    USING (auth.uid() = created_by);

-- JOBS POLICIES
DROP POLICY IF EXISTS "Anyone can view active jobs" ON public.jobs;
CREATE POLICY "Anyone can view active jobs"
    ON public.jobs FOR SELECT
    USING (is_active = true OR auth.uid() = recruiter_id);

DROP POLICY IF EXISTS "Recruiters can insert jobs" ON public.jobs;
CREATE POLICY "Recruiters can insert jobs"
    ON public.jobs FOR INSERT
    WITH CHECK (auth.uid() = recruiter_id);

DROP POLICY IF EXISTS "Recruiters can update own jobs" ON public.jobs;
CREATE POLICY "Recruiters can update own jobs"
    ON public.jobs FOR UPDATE
    USING (auth.uid() = recruiter_id);

DROP POLICY IF EXISTS "Recruiters can delete own jobs" ON public.jobs;
CREATE POLICY "Recruiters can delete own jobs"
    ON public.jobs FOR DELETE
    USING (auth.uid() = recruiter_id);

-- JOB APPLICATIONS POLICIES
DROP POLICY IF EXISTS "Applicants can view own applications" ON public.job_applications;
CREATE POLICY "Applicants can view own applications"
    ON public.job_applications FOR SELECT
    USING (auth.uid() = applicant_id);

DROP POLICY IF EXISTS "Recruiters can view applications for their jobs" ON public.job_applications;
CREATE POLICY "Recruiters can view applications for their jobs"
    ON public.job_applications FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.jobs
            WHERE jobs.id = job_applications.job_id
            AND jobs.recruiter_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Applicants can submit applications" ON public.job_applications;
CREATE POLICY "Applicants can submit applications"
    ON public.job_applications FOR INSERT
    WITH CHECK (auth.uid() = applicant_id);

DROP POLICY IF EXISTS "Recruiters can update application status" ON public.job_applications;
CREATE POLICY "Recruiters can update application status"
    ON public.job_applications FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.jobs
            WHERE jobs.id = job_applications.job_id
            AND jobs.recruiter_id = auth.uid()
        )
    );

-- SAVED JOBS POLICIES
DROP POLICY IF EXISTS "Users can manage own saved jobs" ON public.saved_jobs;
CREATE POLICY "Users can manage own saved jobs"
    ON public.saved_jobs FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- NOTIFICATIONS POLICIES
DROP POLICY IF EXISTS "Users can manage own notifications" ON public.notifications;
CREATE POLICY "Users can manage own notifications"
    ON public.notifications FOR ALL
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

-- ==============================================================================
-- 6. REALTIME REPLICATION ENABLEMENT
-- ==============================================================================
DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.messages;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.job_applications;
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- ==============================================================================
-- 7. INITIAL SAMPLE SEED DATA
-- ==============================================================================
INSERT INTO public.companies (id, name, slug, logo_url, website, industry, company_size, description, location)
VALUES
    ('a1111111-1111-1111-1111-111111111111', 'TechFlow Solutions', 'techflow', 'https://images.unsplash.com/photo-1549923746-c502d488b3ea?w=150', 'https://techflow.example.com', 'Software & Cloud', '50-200 employees', 'Building the next generation of scalable cloud infrastructure.', 'San Francisco, CA'),
    ('a2222222-2222-2222-2222-222222222222', 'Nexus AI Systems', 'nexus-ai', 'https://images.unsplash.com/photo-1572021335469-31706a17aaef?w=150', 'https://nexusai.example.com', 'Artificial Intelligence', '200-500 employees', 'Transforming workflow automation with intelligent LLM systems.', 'London, UK'),
    ('a3333333-3333-3333-3333-333333333333', 'Veritas Digital', 'veritas-digital', 'https://images.unsplash.com/photo-1551434678-e076c223a692?w=150', 'https://veritas.example.com', 'FinTech & Security', '100-250 employees', 'Modern financial tooling and secured digital payments.', 'Berlin, Germany')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.jobs (id, company_id, title, description, requirements, skills_required, job_type, experience_level, location, is_remote, salary_min, salary_max, salary_currency, is_active)
VALUES
    (
        'b1111111-1111-1111-1111-111111111111',
        'a1111111-1111-1111-1111-111111111111',
        'Senior Frontend Engineer (React & TypeScript)',
        'We are seeking a talented Senior Frontend Engineer to build high-performance web applications, responsive user dashboards, and real-time stateful interfaces.',
        ARRAY['5+ years of experience with modern JavaScript / TypeScript', 'Deep expertise in React or Vue and CSS architecture', 'Proven track record of building accessible web applications'],
        ARRAY['React', 'TypeScript', 'TailwindCSS', 'REST APIs', 'Supabase'],
        'full_time',
        'senior',
        'San Francisco, CA',
        true,
        120000,
        160000,
        'USD',
        true
    ),
    (
        'b2222222-2222-2222-2222-222222222222',
        'a2222222-2222-2222-2222-222222222222',
        'AI Product Designer & UI/UX Specialist',
        'Join Nexus AI to craft intuitive, modern user experiences for machine learning products, candidate matching engines, and analytics dashboards.',
        ARRAY['3+ years designing complex SaaS products', 'Proficiency in Figma, design systems, and user testing', 'Strong visual and interaction design skills'],
        ARRAY['UI/UX Design', 'Figma', 'Design Systems', 'User Research', 'Prototyping'],
        'full_time',
        'mid',
        'London, UK',
        true,
        85000,
        110000,
        'USD',
        true
    ),
    (
        'b3333333-3333-3333-3333-333333333333',
        'a3333333-3333-3333-3333-333333333333',
        'Full Stack Cloud Developer',
        'Build scalable backend microservices, real-time messaging pipelines, and clean frontend components for financial applications.',
        ARRAY['Strong proficiency in Node.js, Python, or Go', 'Hands-on PostgreSQL / SQL database design', 'Experience with AWS / cloud deployment'],
        ARRAY['Node.js', 'PostgreSQL', 'Docker', 'REST API', 'JavaScript'],
        'contract',
        'mid',
        'Berlin, Germany',
        false,
        90000,
        130000,
        'USD',
        true
    )
ON CONFLICT (id) DO NOTHING;
