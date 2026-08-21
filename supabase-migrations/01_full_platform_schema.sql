-- ==============================================================================
-- WORKWAY COMPLETE DATABASE SCHEMA & SECURITY MIGRATION
-- Supports Full Multi-Page Platform, Recruiter & Candidate Portals, AI Engine & Real Data
-- ==============================================================================

-- 1. EXTENSIONS & TYPES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "vector"; -- for embeddings if pgvector enabled

DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('job_seeker', 'recruiter', 'admin');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE job_type AS ENUM ('full_time', 'part_time', 'contract', 'remote', 'internship', 'freelance');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE experience_level AS ENUM ('entry', 'mid', 'senior', 'lead', 'executive');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE application_status AS ENUM ('applied', 'reviewing', 'shortlisted', 'interviewing', 'rejected', 'offered', 'hired');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE interview_status AS ENUM ('scheduled', 'completed', 'cancelled', 'rescheduled');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE report_status AS ENUM ('pending', 'investigating', 'resolved', 'dismissed');
EXCEPTION WHEN duplicate_object THEN null; END $$;

DO $$ BEGIN
    CREATE TYPE work_mode_type AS ENUM ('on_site', 'hybrid', 'remote');
EXCEPTION WHEN duplicate_object THEN null; END $$;

-- ==============================================================================
-- 2. CORE & PROFILE TABLES
-- ==============================================================================

-- Profiles Table (Extends Supabase auth.users)
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
    is_verified BOOLEAN DEFAULT FALSE,
    is_suspended BOOLEAN DEFAULT FALSE,
    theme_preference TEXT DEFAULT 'light',
    language_preference TEXT DEFAULT 'en',
    two_factor_enabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Company Profiles
CREATE TABLE IF NOT EXISTS public.companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    logo_url TEXT,
    website TEXT,
    industry TEXT NOT NULL,
    company_size TEXT,
    description TEXT,
    culture TEXT,
    benefits TEXT[] DEFAULT '{}',
    location TEXT NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidate Extended Details
CREATE TABLE IF NOT EXISTS public.candidate_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    desired_role TEXT,
    expected_salary_min NUMERIC,
    expected_salary_max NUMERIC,
    currency TEXT DEFAULT 'XAF',
    work_mode_preference work_mode_type DEFAULT 'hybrid',
    availability_status TEXT DEFAULT 'immediately',
    target_locations TEXT[] DEFAULT '{}',
    target_industries TEXT[] DEFAULT '{}',
    summary TEXT,
    resume_score INTEGER DEFAULT 80,
    ats_compatibility_score INTEGER DEFAULT 85,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidate Resumes / Versions
CREATE TABLE IF NOT EXISTS public.candidate_resumes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    file_url TEXT NOT NULL,
    version_title TEXT DEFAULT 'Primary Resume',
    is_primary BOOLEAN DEFAULT FALSE,
    parsed_skills TEXT[] DEFAULT '{}',
    ats_score INTEGER DEFAULT 85,
    improvement_notes TEXT[] DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidate Skills Normalized
CREATE TABLE IF NOT EXISTS public.candidate_skills (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    skill_name TEXT NOT NULL,
    proficiency_level TEXT DEFAULT 'intermediate',
    years_experience NUMERIC DEFAULT 1,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidate Work Experience
CREATE TABLE IF NOT EXISTS public.candidate_experience (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_title TEXT NOT NULL,
    company_name TEXT NOT NULL,
    location TEXT,
    start_date DATE NOT NULL,
    end_date DATE,
    is_current BOOLEAN DEFAULT FALSE,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Candidate Education
CREATE TABLE IF NOT EXISTS public.candidate_education (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    institution TEXT NOT NULL,
    degree TEXT NOT NULL,
    field_of_study TEXT,
    start_year INTEGER,
    end_year INTEGER,
    grade TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 3. JOBS & REQUIREMENTS
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    company_id UUID REFERENCES public.companies(id) ON DELETE CASCADE,
    recruiter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'Technology / Software',
    description TEXT NOT NULL,
    responsibilities TEXT[] DEFAULT '{}',
    requirements TEXT[] DEFAULT '{}',
    skills_required TEXT[] DEFAULT '{}',
    preferred_skills TEXT[] DEFAULT '{}',
    job_type job_type NOT NULL DEFAULT 'full_time',
    experience_level experience_level NOT NULL DEFAULT 'mid',
    work_mode work_mode_type DEFAULT 'on_site',
    location TEXT NOT NULL,
    is_remote BOOLEAN DEFAULT FALSE,
    salary_min NUMERIC,
    salary_max NUMERIC,
    salary_currency TEXT DEFAULT 'XAF',
    is_active BOOLEAN DEFAULT TRUE,
    is_featured BOOLEAN DEFAULT FALSE,
    views_count INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.job_requirements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    requirement_text TEXT NOT NULL,
    is_mandatory BOOLEAN DEFAULT TRUE,
    category TEXT DEFAULT 'technical',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 4. APPLICATIONS, SAVED JOBS & MATCHING
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.job_applications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    applicant_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    resume_url TEXT,
    cover_letter TEXT,
    match_score NUMERIC(5,2) DEFAULT 85.0,
    match_breakdown JSONB DEFAULT '{"skills": 85, "experience": 80, "education": 90, "location": 100}',
    status application_status NOT NULL DEFAULT 'applied',
    recruiter_notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(job_id, applicant_id)
);

CREATE TABLE IF NOT EXISTS public.saved_jobs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, job_id)
);

CREATE TABLE IF NOT EXISTS public.match_scores (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    candidate_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    overall_score NUMERIC(5,2) NOT NULL,
    skills_score NUMERIC(5,2) DEFAULT 0,
    experience_score NUMERIC(5,2) DEFAULT 0,
    education_score NUMERIC(5,2) DEFAULT 0,
    preferences_score NUMERIC(5,2) DEFAULT 0,
    hard_requirements_met BOOLEAN DEFAULT TRUE,
    explanation TEXT,
    computed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(candidate_id, job_id)
);

-- ==============================================================================
-- 5. MESSAGING & INTERVIEWS
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE SET NULL,
    applicant_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    recruiter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(applicant_id, recruiter_id, job_id)
);

CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID REFERENCES public.conversations(id) ON DELETE CASCADE,
    sender_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachment_url TEXT,
    attachment_name TEXT,
    message_type TEXT DEFAULT 'text', -- 'text', 'interview_invite', 'file'
    payload JSONB DEFAULT '{}',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.interviews (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    job_id UUID REFERENCES public.jobs(id) ON DELETE CASCADE,
    application_id UUID REFERENCES public.job_applications(id) ON DELETE CASCADE,
    candidate_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    recruiter_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER DEFAULT 45,
    location_type TEXT DEFAULT 'video', -- 'video', 'phone', 'on_site'
    meeting_link TEXT,
    status interview_status DEFAULT 'scheduled',
    notes TEXT,
    candidate_feedback TEXT,
    recruiter_rating INTEGER,
    recruiter_feedback TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 6. ASSESSMENTS, NOTIFICATIONS & ADMIN MODERATION
-- ==============================================================================

CREATE TABLE IF NOT EXISTS public.assessments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    category TEXT NOT NULL, -- 'personality', 'soft_skills', 'career_interests'
    description TEXT,
    questions JSONB NOT NULL DEFAULT '[]',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.assessment_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    assessment_id UUID REFERENCES public.assessments(id) ON DELETE CASCADE,
    score NUMERIC(5,2),
    personality_type TEXT,
    top_strengths TEXT[] DEFAULT '{}',
    growth_areas TEXT[] DEFAULT '{}',
    recommended_careers TEXT[] DEFAULT '{}',
    raw_responses JSONB DEFAULT '{}',
    completed_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id, assessment_id)
);

CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'general', -- 'match', 'application', 'interview', 'system'
    link TEXT,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    reporter_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    target_type TEXT NOT NULL, -- 'job', 'user', 'company'
    target_id UUID NOT NULL,
    reason TEXT NOT NULL,
    details TEXT,
    status report_status DEFAULT 'pending',
    resolution_notes TEXT,
    resolved_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action_type TEXT NOT NULL,
    target_entity TEXT NOT NULL,
    target_id UUID NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ==============================================================================
-- 7. PERFORMANCE INDEXES
-- ==============================================================================

CREATE INDEX IF NOT EXISTS idx_jobs_category ON public.jobs(category);
CREATE INDEX IF NOT EXISTS idx_jobs_location ON public.jobs(location);
CREATE INDEX IF NOT EXISTS idx_jobs_is_active ON public.jobs(is_active);
CREATE INDEX IF NOT EXISTS idx_jobs_recruiter_id ON public.jobs(recruiter_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_job ON public.job_applications(job_id);
CREATE INDEX IF NOT EXISTS idx_job_applications_applicant ON public.job_applications(applicant_id);
CREATE INDEX IF NOT EXISTS idx_saved_jobs_user ON public.saved_jobs(user_id);
CREATE INDEX IF NOT EXISTS idx_messages_conv ON public.messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_notifications_user ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_interviews_candidate ON public.interviews(candidate_id);
CREATE INDEX IF NOT EXISTS idx_interviews_recruiter ON public.interviews(recruiter_id);
CREATE INDEX IF NOT EXISTS idx_match_scores_cand ON public.match_scores(candidate_id);
CREATE INDEX IF NOT EXISTS idx_match_scores_job ON public.match_scores(job_id);

-- ==============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ==============================================================================

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_experience ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.candidate_education ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.job_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_jobs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.match_scores ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.assessment_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_actions ENABLE ROW LEVEL SECURITY;

-- Helper function to check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: Public can view non-sensitive profiles, users can update own, admin can manage all
DROP POLICY IF EXISTS "Profiles are viewable" ON public.profiles;
CREATE POLICY "Profiles are viewable" ON public.profiles FOR SELECT USING (true);

DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
CREATE POLICY "Users can update own profile" ON public.profiles FOR UPDATE USING (auth.uid() = id OR is_admin());

DROP POLICY IF EXISTS "Users can insert own profile" ON public.profiles;
CREATE POLICY "Users can insert own profile" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id OR is_admin());

-- Companies: Viewable by all, managed by creator or admin
DROP POLICY IF EXISTS "Companies viewable by all" ON public.companies;
CREATE POLICY "Companies viewable by all" ON public.companies FOR SELECT USING (true);

DROP POLICY IF EXISTS "Recruiters can insert companies" ON public.companies;
CREATE POLICY "Recruiters can insert companies" ON public.companies FOR INSERT WITH CHECK (auth.uid() = created_by OR is_admin());

DROP POLICY IF EXISTS "Recruiters can update own companies" ON public.companies;
CREATE POLICY "Recruiters can update own companies" ON public.companies FOR UPDATE USING (auth.uid() = created_by OR is_admin());

-- Candidate Profiles & Details: Candidate owns, recruiters can view if candidate applied, admin manages
DROP POLICY IF EXISTS "Candidate profile access" ON public.candidate_profiles;
CREATE POLICY "Candidate profile access" ON public.candidate_profiles FOR ALL USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "Candidate resumes access" ON public.candidate_resumes;
CREATE POLICY "Candidate resumes access" ON public.candidate_resumes FOR ALL USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "Candidate skills access" ON public.candidate_skills;
CREATE POLICY "Candidate skills access" ON public.candidate_skills FOR ALL USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "Candidate experience access" ON public.candidate_experience;
CREATE POLICY "Candidate experience access" ON public.candidate_experience FOR ALL USING (auth.uid() = user_id OR is_admin());

DROP POLICY IF EXISTS "Candidate education access" ON public.candidate_education;
CREATE POLICY "Candidate education access" ON public.candidate_education FOR ALL USING (auth.uid() = user_id OR is_admin());

-- Jobs: Anyone views active jobs; recruiters manage own; admin manages all
DROP POLICY IF EXISTS "Jobs public view" ON public.jobs;
CREATE POLICY "Jobs public view" ON public.jobs FOR SELECT USING (is_active = true OR auth.uid() = recruiter_id OR is_admin());

DROP POLICY IF EXISTS "Jobs recruiter insert" ON public.jobs;
CREATE POLICY "Jobs recruiter insert" ON public.jobs FOR INSERT WITH CHECK (auth.uid() = recruiter_id OR is_admin());

DROP POLICY IF EXISTS "Jobs recruiter update" ON public.jobs;
CREATE POLICY "Jobs recruiter update" ON public.jobs FOR UPDATE USING (auth.uid() = recruiter_id OR is_admin());

DROP POLICY IF EXISTS "Jobs recruiter delete" ON public.jobs;
CREATE POLICY "Jobs recruiter delete" ON public.jobs FOR DELETE USING (auth.uid() = recruiter_id OR is_admin());

-- Job Applications: Candidate views own, recruiter views for their jobs
DROP POLICY IF EXISTS "Applications candidate view" ON public.job_applications;
CREATE POLICY "Applications candidate view" ON public.job_applications FOR SELECT USING (
    auth.uid() = applicant_id OR 
    EXISTS (SELECT 1 FROM public.jobs WHERE jobs.id = job_applications.job_id AND jobs.recruiter_id = auth.uid()) OR
    is_admin()
);

DROP POLICY IF EXISTS "Applications candidate insert" ON public.job_applications;
CREATE POLICY "Applications candidate insert" ON public.job_applications FOR INSERT WITH CHECK (auth.uid() = applicant_id);

DROP POLICY IF EXISTS "Applications status update" ON public.job_applications;
CREATE POLICY "Applications status update" ON public.job_applications FOR UPDATE USING (
    auth.uid() = applicant_id OR 
    EXISTS (SELECT 1 FROM public.jobs WHERE jobs.id = job_applications.job_id AND jobs.recruiter_id = auth.uid()) OR
    is_admin()
);

-- Saved Jobs
DROP POLICY IF EXISTS "Saved jobs user manage" ON public.saved_jobs;
CREATE POLICY "Saved jobs user manage" ON public.saved_jobs FOR ALL USING (auth.uid() = user_id);

-- Conversations & Messages
DROP POLICY IF EXISTS "Conversations participant view" ON public.conversations;
CREATE POLICY "Conversations participant view" ON public.conversations FOR ALL USING (
    auth.uid() = applicant_id OR auth.uid() = recruiter_id OR is_admin()
);

DROP POLICY IF EXISTS "Messages participant access" ON public.messages;
CREATE POLICY "Messages participant access" ON public.messages FOR ALL USING (
    EXISTS (SELECT 1 FROM public.conversations c WHERE c.id = messages.conversation_id AND (c.applicant_id = auth.uid() OR c.recruiter_id = auth.uid())) OR
    is_admin()
);

-- Interviews
DROP POLICY IF EXISTS "Interviews participant access" ON public.interviews;
CREATE POLICY "Interviews participant access" ON public.interviews FOR ALL USING (
    auth.uid() = candidate_id OR auth.uid() = recruiter_id OR is_admin()
);

-- Assessments
DROP POLICY IF EXISTS "Assessments viewable by all" ON public.assessments;
CREATE POLICY "Assessments viewable by all" ON public.assessments FOR SELECT USING (true);

DROP POLICY IF EXISTS "Assessment results user manage" ON public.assessment_results;
CREATE POLICY "Assessment results user manage" ON public.assessment_results FOR ALL USING (auth.uid() = user_id OR is_admin());

-- Notifications
DROP POLICY IF EXISTS "Notifications user manage" ON public.notifications;
CREATE POLICY "Notifications user manage" ON public.notifications FOR ALL USING (auth.uid() = user_id);

-- Reports & Admin
DROP POLICY IF EXISTS "Reports user insert" ON public.reports;
CREATE POLICY "Reports user insert" ON public.reports FOR INSERT WITH CHECK (auth.uid() = reporter_id OR is_admin());

DROP POLICY IF EXISTS "Reports admin view" ON public.reports;
CREATE POLICY "Reports admin view" ON public.reports FOR SELECT USING (auth.uid() = reporter_id OR is_admin());

DROP POLICY IF EXISTS "Reports admin update" ON public.reports;
CREATE POLICY "Reports admin update" ON public.reports FOR UPDATE USING (is_admin());

DROP POLICY IF EXISTS "Admin actions access" ON public.admin_actions;
CREATE POLICY "Admin actions access" ON public.admin_actions FOR ALL USING (is_admin());

-- ==============================================================================
-- 9. REALISTIC SEED DATA (Cameroon & Regional African Market)
-- ==============================================================================

-- Seed Sample Assessments
INSERT INTO public.assessments (id, title, category, description, questions)
VALUES
(
    'c1111111-1111-1111-1111-111111111111',
    'WorkWay Workplace Personality & Strengths Inventory',
    'personality',
    'Assess your core collaboration style, problem-solving mindset, and workplace communication strengths.',
    '[
        {"id": "q1", "text": "When approaching a complex project deadline, you prioritize:", "options": ["Rigorous planning and structured checklists", "Iterative rapid prototyping with team feedback", "Analytical risk assessment and resource planning", "Direct action and continuous pivoting"]},
        {"id": "q2", "text": "In cross-functional team discussions, you naturally act as:", "options": ["The synthesizer who aligns differing perspectives", "The strategic visionary pushing boundaries", "The pragmatic evaluator ensuring realistic execution", "The empathetic mentor supporting colleagues"]},
        {"id": "q3", "text": "Your ideal working environment is:", "options": ["Autonomous with clear objective milestones", "High-energy collaborative squad setting", "Structured corporate framework with defined hierarchy", "Flexible hybrid with deep-focus blocks"]}
    ]'::jsonb
),
(
    'c2222222-2222-2222-2222-222222222222',
    'Professional Soft Skills & Adaptability Benchmark',
    'soft_skills',
    'Evaluate resilience, conflict resolution, client communication, and cross-cultural adaptability.',
    '[
        {"id": "s1", "text": "When client specifications shift unexpectedly late in a delivery cycle, you:", "options": ["Clarify trade-offs immediately and renegotiate priorities", "Absorb the extra effort without compromising initial requirements", "Deconstruct the delta into minimal viable adjustments", "Consult stakeholders for an executive alignment meeting"]},
        {"id": "s2", "text": "How do you deliver constructive critical feedback to a peer?", "options": ["Direct, data-driven examples paired with actionable suggestions", "Private 1-on-1 discussion using the situation-behavior-impact model", "Collaborative coaching session focused on future iterations", "Written summary highlighting achievements before improvement areas"]}
    ]'::jsonb
)
ON CONFLICT (id) DO NOTHING;

-- Seed Diverse African Companies across Multiple Sectors
INSERT INTO public.companies (id, name, slug, logo_url, website, industry, company_size, description, culture, benefits, location, is_verified)
VALUES
(
    'c1000000-0000-0000-0000-000000000001',
    'Afriland First Bank',
    'afriland-first-bank',
    'https://images.unsplash.com/photo-1551836022-d5d88e9218df?w=150',
    'https://afrilandfirstbank.com',
    'Finance & Banking',
    '1000+ employees',
    'Leading commercial and investment bank in Central Africa providing pan-African banking solutions, trade finance, and digital payment innovations.',
    'Excellence, African ingenuity, integrity, and sustainable economic empowerment.',
    ARRAY['Health insurance', 'Performance bonus', 'Retirement savings plan', 'Professional development allowance'],
    'Yaoundé, Cameroon',
    true
),
(
    'c1000000-0000-0000-0000-000000000002',
    'Razel-BEC Cameroun & BTP Infrastructure',
    'razel-bec-btp',
    'https://images.unsplash.com/photo-1504307651254-35680f356dfd?w=150',
    'https://razel-bec.com',
    'Engineering & Civil Construction',
    '500-1000 employees',
    'Pioneering major civil engineering, highway infrastructure, hydroelectric dams, and structural construction across Central Africa.',
    'Safety first, engineering precision, operational rigor, and teamwork.',
    ARRAY['Site accommodation & transport', 'Full medical coverage', 'Safety hazard allowance', 'Hazardous duty coverage'],
    'Douala, Cameroon',
    true
),
(
    'c1000000-0000-0000-0000-000000000003',
    'Clinique de la Cathédrale & Healthcare Alliance',
    'clinique-cathedrale-health',
    'https://images.unsplash.com/photo-1538108149393-fbbd81895907?w=150',
    'https://cliniquecathedrale.cm',
    'Medicine & Healthcare',
    '100-250 employees',
    'Premier medical facility and polyclinic providing multidisciplinary surgical care, intensive diagnostics, oncology, and maternity health in Central Cameroon.',
    'Compassionate patient care, clinical rigor, ethical practice, and medical research.',
    ARRAY['Comprehensive family medical cover', 'Continuing medical education (CME) budget', 'Subsidized on-call meals'],
    'Yaoundé, Cameroon',
    true
),
(
    'c1000000-0000-0000-0000-000000000004',
    'Africa Global Logistics Douala Port Terminals',
    'agl-logistics-douala',
    'https://images.unsplash.com/photo-1586528116311-ad8dd3c8310d?w=150',
    'https://aglgroup.com',
    'Logistics & Supply Chain',
    '1000+ employees',
    'Operator of maritime port logistics, multimodal rail-road transportation, warehousing, and customs clearance corridors across CEMAC.',
    'Operational velocity, customer centricity, supply-chain resilience, and digital tracking.',
    ARRAY['Transport allowance', 'International mobility opportunities', 'Performance incentives', 'Annual bonus'],
    'Douala, Cameroon',
    true
),
(
    'c1000000-0000-0000-0000-000000000005',
    'SOCAPALM Agro-Industrial Group',
    'socapalm-agro',
    'https://images.unsplash.com/photo-1500937386664-56d1dfef3854?w=150',
    'https://socapalm-cameroun.com',
    'Agriculture & Agro-Industry',
    '2000+ employees',
    'Major agricultural producer specializing in sustainable sustainable oil palm cultivation, processing refineries, and rural agro-development.',
    'Environmental stewardship, community engagement, agro-scientific advancement.',
    ARRAY['Housing allowance', 'On-site health clinic access', 'School support subsidies for children', 'Food rations'],
    'Kribi / Edéa, Cameroon',
    true
),
(
    'c1000000-0000-0000-0000-000000000006',
    'Bilingual International Leadership Academy',
    'bilingual-academy',
    'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?w=150',
    'https://bilingualacademy.org',
    'Education & Training',
    '50-100 employees',
    'Accredited bilingual (French-English) institution delivering STEM curriculum, Cambridge examinations, and dual-baccalaureate diplomas.',
    'Pedagogical excellence, student empowerment, bilingual fluency, and character building.',
    ARRAY['Tuition waivers for dependants', 'Annual pedagogical conference travel', 'Health insurance', 'Paid sabbatical blocks'],
    'Yaoundé, Cameroon',
    true
),
(
    'c1000000-0000-0000-0000-000000000007',
    'KMR Tech Innovations & Digital Labs',
    'kmr-tech-labs',
    'https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=150',
    'https://kmrtech.cm',
    'Technology & Software',
    '50-200 employees',
    'Fast-growing African FinTech software studio building USSD mobile money gateways, enterprise SaaS, and AI-powered payroll engines.',
    'High agency, engineering craft, open communication, remote-first flexibility.',
    ARRAY['Remote work stipend', 'MacBook Pro provided', 'Gym membership', 'Continuous learning budget'],
    'Douala, Cameroon (Remote)',
    true
)
ON CONFLICT (id) DO NOTHING;

-- Seed Diverse Real Jobs Spanning All Required Categories
INSERT INTO public.jobs (id, company_id, title, category, description, responsibilities, requirements, skills_required, preferred_skills, job_type, experience_level, work_mode, location, is_remote, salary_min, salary_max, salary_currency, is_active, is_featured)
VALUES
(
    'd1000000-0000-0000-0000-000000000001',
    'c1000000-0000-0000-0000-000000000001',
    'Senior Financial Analyst & Risk Controller',
    'Finance & Accounting',
    'Manage corporate credit risk evaluations, regulatory capital adequacy reporting for COBAC compliance, and investment portfolio modeling.',
    ARRAY[
        'Conduct in-depth credit assessments on corporate loan applications exceeding 500M XAF',
        'Prepare monthly COBAC risk prudential ratio filings and treasury liquidity reports',
        'Model financial sensitivity scenarios for foreign exchange and sovereign bond holdings',
        'Collaborate with internal auditors on anti-money laundering (AML) protocols'
    ],
    ARRAY[
        'Minimum 5 years in commercial banking, audit firm, or asset management',
        'Bilingual proficiency in French and English (written and verbal)',
        'Master’s degree in Finance, Accounting, or CFA Level 2 candidate'
    ],
    ARRAY['Financial Modeling', 'Risk Management', 'COBAC Regulations', 'Credit Analysis', 'IFRS 9', 'Excel / VBA'],
    ARRAY['Python for Finance', 'PowerBI', 'French/English Bilingual'],
    'full_time',
    'senior',
    'on_site',
    'Yaoundé, Cameroon',
    false,
    850000,
    1400000,
    'XAF',
    true,
    true
),
(
    'd1000000-0000-0000-0000-000000000002',
    'c1000000-0000-0000-0000-000000000002',
    'Civil Works Project Engineer (Roads & Bridges)',
    'Engineering & Civil Construction',
    'Lead on-site execution of major highway corridors, structural asphalt laying, drainage culverts, and contractor quality assurance.',
    ARRAY[
        'Supervise daily heavy equipment operations, earthmoving, and reinforced concrete pours',
        'Inspect soil compaction tests, aggregate grading, and laboratory concrete crushing tests',
        'Track bill of quantities (BOQ), work progress certificates, and contractor variations',
        'Enforce environmental and workplace safety protocols on active construction segments'
    ],
    ARRAY[
        'Bachelor or Master of Engineering in Civil / Structural Engineering (Génie Civil)',
        '3+ years field experience on public works or transport infrastructure projects',
        'Proficiency in AutoCAD Civil 3D, Covadis, or MS Project'
    ],
    ARRAY['Civil Engineering', 'AutoCAD Civil 3D', 'Covadis', 'Site Supervision', 'Topography', 'BOQ Management'],
    ARRAY['Bridge Design', 'French/English Fluency', 'Driver License B/C'],
    'full_time',
    'mid',
    'on_site',
    'Douala / Littoral Region, Cameroon',
    false,
    700000,
    1200000,
    'XAF',
    true,
    true
),
(
    'd1000000-0000-0000-0000-000000000003',
    'c1000000-0000-0000-0000-000000000003',
    'Chief Medical Officer & General Surgeon',
    'Medicine & Healthcare',
    'Coordinate inpatient clinical rotations, perform scheduled and emergency surgical procedures, and oversee patient care protocols.',
    ARRAY[
        'Perform general abdominal, trauma, and laparoscopic surgical interventions',
        'Lead clinical morning handovers, surgical morbidity conferences, and patient ward rounds',
        'Direct hospital hygiene, infection control committees, and surgical theater sterilization',
        'Provide consultative leadership on complex pediatric and adult acute admissions'
    ],
    ARRAY[
        'Doctor of Medicine (MD) + Specialist Certification / DES in General Surgery',
        'Registered with the National Council of Medical Practitioners of Cameroon (ONMC)',
        'Demonstrated 4+ years post-residency surgical clinical experience'
    ],
    ARRAY['General Surgery', 'Clinical Diagnosis', 'Emergency Care', 'Laparoscopy', 'Patient Management', 'ONMC Registered'],
    ARRAY['Hospital Administration', 'Ultrasound Diagnostics', 'French/English Bilingual'],
    'full_time',
    'lead',
    'on_site',
    'Yaoundé, Cameroon',
    false,
    1200000,
    2200000,
    'XAF',
    true,
    true
),
(
    'd1000000-0000-0000-0000-000000000004',
    'c1000000-0000-0000-0000-000000000004',
    'Maritime Customs Clearance & Freight Coordinator',
    'Logistics & Supply Chain',
    'Coordinate port container dispatching, automated customs declarations via SYDONIA++, and bonded warehouse logistics.',
    ARRAY[
        'Process import/export customs clearance dossiers on the Guce / Sydonia++ platform',
        'Liaise with shipping lines (Maersk, CMA CGM) for bill of lading (B/L) releases',
        'Coordinate customs inspections, phytosanitary checks, and truck terminal departures',
        'Optimize container demurrage turnaround times and tracking dispatch updates to clients'
    ],
    ARRAY[
        'Degree in Logistics, International Trade, or Transport Management',
        '2+ years working with Douala Port Authority clearance procedures',
        'Familiarity with Incoterms 2020 and CEMAC customs tariffs'
    ],
    ARRAY['SYDONIA++', 'Freight Forwarding', 'Customs Clearance', 'Incoterms 2020', 'Port Logistics', 'Supply Chain Management'],
    ARRAY['Bilingual English/French', 'Dangerous Goods (IMDG) Certification'],
    'full_time',
    'mid',
    'on_site',
    'Douala, Cameroon',
    false,
    450000,
    750000,
    'XAF',
    true,
    false
),
(
    'd1000000-0000-0000-0000-000000000005',
    'c1000000-0000-0000-0000-000000000005',
    'Agro-Industrial Estate Agronomist',
    'Agriculture & Agro-Industry',
    'Manage plantation phytosanitary surveillance, soil fertility enrichment, organic composting, and seedling nursery development.',
    ARRAY[
        'Oversee nursery germination cycles, transplant schedules, and crop yield forecasting',
        'Formulate biological pest management and eco-responsible fertilizer application protocols',
        'Train field supervisors in pruning techniques and seasonal harvesting standards',
        'Collect soil core samples for pH, nitrogen, and organic carbon laboratory profiling'
    ],
    ARRAY[
        'Degree in Agronomy, Agricultural Engineering (Ingénieur Agronome), or Crop Science',
        '3+ years field experience in tropical perennial crops or agro-forestry',
        'Strong leadership in rural agricultural management'
    ],
    ARRAY['Agronomy', 'Soil Science', 'Crop Protection', 'Plantation Management', 'Phytosanitary Inspection', 'GIS Mapping'],
    ARRAY['Organic Certification (RSPO)', 'GPS Land Surveying'],
    'full_time',
    'mid',
    'on_site',
    'Edéa / Littoral, Cameroon',
    false,
    550000,
    950000,
    'XAF',
    true,
    false
),
(
    'd1000000-0000-0000-0000-000000000006',
    'c1000000-0000-0000-0000-000000000006',
    'Senior STEM & Computer Science Educator',
    'Education & Training',
    'Instruct secondary students in Python programming, mathematics, physics laboratories, and Cambridge IGCSE / Dual-Diploma curricula.',
    ARRAY[
        'Deliver interactive classroom lessons combining theoretical foundations and hands-on coding labs',
        'Design continuous assessment exams, science fair projects, and robotics club activities',
        'Provide academic tutoring, career mentorship, and university application counseling',
        'Maintain detailed grade books and parent-teacher communication portals'
    ],
    ARRAY[
        'Bachelor or Master’s in Computer Science, Education, Mathematics, or Physics',
        'Proven teaching record in accredited bilingual or international secondary schools',
        'Fluency in English with strong working French'
    ],
    ARRAY['Python', 'Computer Science Curriculum', 'STEM Education', 'Pedagogical Design', 'Classroom Management', 'Mentoring'],
    ARRAY['Robotics / Arduino', 'Cambridge IGCSE Experience', 'Educational Tech'],
    'full_time',
    'mid',
    'on_site',
    'Yaoundé, Cameroon',
    false,
    400000,
    700000,
    'XAF',
    true,
    false
),
(
    'd1000000-0000-0000-0000-000000000007',
    'c1000000-0000-0000-0000-000000000007',
    'Senior Full-Stack Cloud Engineer (TypeScript & Supabase)',
    'Technology & Software',
    'Architect resilient microservices, responsive web portals, real-time message feeds, and PostgreSQL database queries for our SaaS platform.',
    ARRAY[
        'Develop responsive web apps with vanilla CSS, modern JS/TypeScript, and component state architectures',
        'Design normalized PostgreSQL database schemas, indexes, and Row Level Security (RLS) policies',
        'Implement real-time WebSocket messaging, background queues, and AI matching algorithms',
        'Maintain automated CI/CD deployment pipelines, unit tests, and performance monitoring'
    ],
    ARRAY[
        '4+ years professional software development experience',
        'Strong expertise in TypeScript, PostgreSQL, REST APIs, and modern frontend frameworks/vanilla JS',
        'Track record of building secure, scalable cloud applications'
    ],
    ARRAY['TypeScript', 'JavaScript', 'PostgreSQL', 'Supabase', 'Node.js', 'REST APIs', 'HTML5/CSS3', 'Git'],
    ARRAY['Python / AI Embeddings', 'Docker', 'AWS / Cloud Architecture'],
    'full_time',
    'senior',
    'remote',
    'Douala, Cameroon (Remote)',
    true,
    900000,
    1600000,
    'XAF',
    true,
    true
)
ON CONFLICT (id) DO NOTHING;

-- Seed Sample Match Scores for Candidate Demonstration
-- (Will dynamically calculate based on user profiles as candidates create accounts)
