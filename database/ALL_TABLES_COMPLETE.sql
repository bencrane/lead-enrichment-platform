-- ============================================================================
-- LEAD ENRICHMENT SYSTEM - COMPLETE DATABASE SCHEMA
-- ============================================================================
-- Creates ALL 35 tables in one shot
-- Run this single file in Supabase SQL Editor
-- Estimated execution time: 30-60 seconds
-- ============================================================================

-- ============================================================================
-- LEAD ENRICHMENT SYSTEM - CORE SCHEMA (UPDATED)
-- ============================================================================
-- Multi-tenant lead enrichment system for your business
-- Clients = Your customers who upload leads
-- Companies = Organizations that leads work at
-- People = The actual leads you're enriching
-- ============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- UTILITY FUNCTION: Auto-update updated_at timestamp
-- ============================================================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- 1. CLIENTS TABLE (Your Business Customers)
-- ============================================================================

CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Client info
    client_name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    
    -- Status
    status TEXT NOT NULL DEFAULT 'active', -- 'active', 'paused', 'churned'
    tier TEXT DEFAULT 'standard', -- 'standard', 'premium', 'enterprise'
    
    -- Dates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Billing
    total_leads_enriched INTEGER DEFAULT 0,
    total_credits_consumed DECIMAL(15,2) DEFAULT 0,
    
    -- Notes
    notes TEXT
);

CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_email ON clients(email);

CREATE TRIGGER update_clients_updated_at 
    BEFORE UPDATE ON clients 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 2. CSV UPLOADS TABLE (Track Enrichment Batches)
-- ============================================================================

CREATE TABLE csv_uploads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Upload info
    original_filename TEXT NOT NULL,
    total_rows INTEGER NOT NULL DEFAULT 0,
    processed_rows INTEGER DEFAULT 0,
    
    -- Status
    status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    
    -- Dates
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    processing_started_at TIMESTAMP WITH TIME ZONE,
    processing_completed_at TIMESTAMP WITH TIME ZONE,
    
    -- Graduation (when delivered to client)
    graduated_at TIMESTAMP WITH TIME ZONE,
    graduated_by TEXT,
    
    -- Notes
    upload_note TEXT,
    error_message TEXT
);

CREATE INDEX idx_csv_uploads_client ON csv_uploads(client_id);
CREATE INDEX idx_csv_uploads_status ON csv_uploads(status);
CREATE INDEX idx_csv_uploads_uploaded_at ON csv_uploads(uploaded_at);

-- ============================================================================
-- 3. COMPANIES TABLE (Organizations That Leads Work At)
-- ============================================================================

CREATE TABLE companies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- Company identifiers
    name TEXT,
    domain TEXT,
    linkedin_url TEXT,
    linkedin_id TEXT,
    
    -- Basic info (updated by enrichments)
    employee_count INTEGER,
    revenue BIGINT,
    founded_year VARCHAR(10),
    industry TEXT,
    
    -- Dates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Tracking
    enrichment_count INTEGER DEFAULT 0,
    last_enriched_at TIMESTAMP WITH TIME ZONE
);

-- Unique constraints for deduplication
CREATE UNIQUE INDEX idx_companies_domain ON companies(domain) WHERE domain IS NOT NULL;
CREATE UNIQUE INDEX idx_companies_linkedin_id ON companies(linkedin_id) WHERE linkedin_id IS NOT NULL;

CREATE INDEX idx_companies_name ON companies(name);
CREATE INDEX idx_companies_linkedin_url ON companies(linkedin_url);

CREATE TRIGGER update_companies_updated_at 
    BEFORE UPDATE ON companies 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 4. PEOPLE TABLE (The Actual Leads Being Enriched)
-- ============================================================================

CREATE TABLE people (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    csv_upload_id UUID REFERENCES csv_uploads(id) ON DELETE SET NULL,
    
    -- Person identifiers
    email TEXT,
    first_name TEXT,
    last_name TEXT,
    full_name TEXT,
    linkedin_url TEXT,
    phone TEXT,
    
    -- Company info (redundant for quick access)
    company_name TEXT,
    company_domain TEXT,
    company_linkedin_url TEXT,
    
    -- Status
    status TEXT DEFAULT 'staging', -- 'staging', 'live', 'archived'
    enrichment_status TEXT DEFAULT 'pending', -- 'pending', 'processing', 'completed', 'failed'
    
    -- Dates
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Enrichment tracking
    enrichment_count INTEGER DEFAULT 0,
    last_enriched_at TIMESTAMP WITH TIME ZONE,
    
    -- Notes
    upload_note TEXT,
    tags TEXT[]
);

-- Indexes for performance
CREATE INDEX idx_people_client ON people(client_id);
CREATE INDEX idx_people_company ON people(company_id);
CREATE INDEX idx_people_csv_upload ON people(csv_upload_id);
CREATE INDEX idx_people_email ON people(email);
CREATE INDEX idx_people_linkedin_url ON people(linkedin_url);
CREATE INDEX idx_people_status ON people(status);
CREATE INDEX idx_people_enrichment_status ON people(enrichment_status);
CREATE INDEX idx_people_client_status ON people(client_id, status);

CREATE TRIGGER update_people_updated_at 
    BEFORE UPDATE ON people 
    FOR EACH ROW 
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 5. ENRICHMENT RUNS TABLE (Track Every Enrichment Execution)
-- ============================================================================

CREATE TABLE enrichment_runs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    
    -- What was enriched
    person_id UUID REFERENCES people(id) ON DELETE CASCADE,
    company_id UUID REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Which enrichment
    enrichment_type TEXT NOT NULL, -- 'email_validation', 'profile_search', etc.
    
    -- Result
    status TEXT NOT NULL, -- 'completed', 'failed', 'skipped'
    credits_consumed DECIMAL(10,2) DEFAULT 0,
    
    -- Error handling
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- Timing
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    
    -- API response metadata
    api_response_status INTEGER,
    api_request_id TEXT
);

CREATE INDEX idx_enrichment_runs_person ON enrichment_runs(person_id);
CREATE INDEX idx_enrichment_runs_company ON enrichment_runs(company_id);
CREATE INDEX idx_enrichment_runs_client ON enrichment_runs(client_id);
CREATE INDEX idx_enrichment_runs_type ON enrichment_runs(enrichment_type);
CREATE INDEX idx_enrichment_runs_status ON enrichment_runs(status);
CREATE INDEX idx_enrichment_runs_completed_at ON enrichment_runs(completed_at);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all multi-tenant tables
ALTER TABLE csv_uploads ENABLE ROW LEVEL SECURITY;
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrichment_runs ENABLE ROW LEVEL SECURITY;

-- Policies (examples - adjust based on your auth setup)

-- Clients can only see their own uploads
CREATE POLICY csv_uploads_isolation ON csv_uploads
    FOR ALL
    USING (client_id = current_setting('app.current_client_id')::UUID);

-- Clients can only see their own people
CREATE POLICY people_isolation ON people
    FOR ALL
    USING (client_id = current_setting('app.current_client_id')::UUID);

-- Clients can only see their own enrichment runs
CREATE POLICY enrichment_runs_isolation ON enrichment_runs
    FOR ALL
    USING (client_id = current_setting('app.current_client_id')::UUID);

-- ============================================================================
-- VIEWS FOR REPORTING
-- ============================================================================

-- Client enrichment summary
CREATE VIEW client_enrichment_summary AS
SELECT 
    c.id as client_id,
    c.client_name,
    c.status as client_status,
    COUNT(DISTINCT p.id) as total_leads,
    COUNT(DISTINCT CASE WHEN p.status = 'live' THEN p.id END) as graduated_leads,
    COUNT(DISTINCT CASE WHEN p.enrichment_status = 'completed' THEN p.id END) as enriched_leads,
    COUNT(DISTINCT er.id) as total_enrichments,
    SUM(er.credits_consumed) as total_credits_consumed,
    MAX(p.last_enriched_at) as last_enrichment_date
FROM clients c
LEFT JOIN people p ON c.id = p.client_id
LEFT JOIN enrichment_runs er ON c.id = er.client_id AND er.status = 'completed'
GROUP BY c.id, c.client_name, c.status;

-- CSV upload progress
CREATE VIEW csv_upload_progress AS
SELECT 
    cu.id as upload_id,
    cu.original_filename,
    c.client_name,
    cu.total_rows,
    cu.processed_rows,
    ROUND((cu.processed_rows::DECIMAL / NULLIF(cu.total_rows, 0)) * 100, 2) as progress_percent,
    cu.status,
    cu.uploaded_at,
    COUNT(DISTINCT p.id) as people_created,
    COUNT(DISTINCT CASE WHEN p.enrichment_status = 'completed' THEN p.id END) as people_enriched,
    SUM(er.credits_consumed) as credits_consumed
FROM csv_uploads cu
LEFT JOIN clients c ON cu.client_id = c.id
LEFT JOIN people p ON cu.id = p.csv_upload_id
LEFT JOIN enrichment_runs er ON p.id = er.person_id AND er.status = 'completed'
GROUP BY cu.id, cu.original_filename, c.client_name, cu.total_rows, cu.processed_rows, cu.status, cu.uploaded_at;

-- ============================================================================
-- SAMPLE TEST DATA
-- ============================================================================

-- Insert test clients
INSERT INTO clients (client_name, email, status, tier) VALUES
('Acme Corp', 'admin@acme.com', 'active', 'premium'),
('TechStart Inc', 'admin@techstart.com', 'active', 'standard'),
('Global Solutions', 'admin@globalsolutions.com', 'active', 'enterprise');

-- Get client IDs for reference
-- In real usage, you'd use these UUIDs to insert test data

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to graduate leads (move from staging to live)
CREATE OR REPLACE FUNCTION graduate_leads(p_csv_upload_id UUID, p_graduated_by TEXT)
RETURNS TABLE(updated_count INTEGER) AS $$
DECLARE
    v_count INTEGER;
BEGIN
    UPDATE people 
    SET status = 'live',
        updated_at = NOW()
    WHERE csv_upload_id = p_csv_upload_id
      AND status = 'staging';
    
    GET DIAGNOSTICS v_count = ROW_COUNT;
    
    UPDATE csv_uploads
    SET graduated_at = NOW(),
        graduated_by = p_graduated_by
    WHERE id = p_csv_upload_id;
    
    RETURN QUERY SELECT v_count;
END;
$$ LANGUAGE plpgsql;

-- Function to calculate enrichment costs for a client
CREATE OR REPLACE FUNCTION calculate_client_enrichment_cost(p_client_id UUID)
RETURNS DECIMAL(15,2) AS $$
DECLARE
    v_total_cost DECIMAL(15,2);
BEGIN
    SELECT COALESCE(SUM(credits_consumed), 0)
    INTO v_total_cost
    FROM enrichment_runs
    WHERE client_id = p_client_id
      AND status = 'completed';
    
    RETURN v_total_cost;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE clients IS 'Your business customers who upload leads for enrichment';
COMMENT ON TABLE csv_uploads IS 'Track each batch of leads uploaded by clients';
COMMENT ON TABLE companies IS 'Organizations that leads work at (shared across clients)';
COMMENT ON TABLE people IS 'Individual leads being enriched (belongs to specific client)';
COMMENT ON TABLE enrichment_runs IS 'Track every enrichment API call executed';

COMMENT ON COLUMN people.status IS 'staging = not yet delivered to client, live = delivered to client, archived = old data';
COMMENT ON COLUMN people.enrichment_status IS 'pending = not enriched, processing = enriching now, completed = done, failed = error';
COMMENT ON COLUMN csv_uploads.graduated_at IS 'When the enriched leads were delivered to client (staging → live)';
-e 

-- ============================================================================
-- PEOPLE ENRICHMENT TABLES (from schema.sql)
-- ============================================================================

    status VARCHAR(50) DEFAULT 'staging', -- staging, live, archived
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_people_client_id ON people(client_id);
CREATE INDEX idx_people_email ON people(email);
CREATE INDEX idx_people_status ON people(status);
CREATE INDEX idx_people_company_id ON people(company_id);

-- ============================================================================
-- ENRICHMENT TRACKING
-- ============================================================================

-- Track which enrichments have been run for each person
CREATE TABLE enrichment_runs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_type VARCHAR(100) NOT NULL, -- 'email_validation', 'profile_search', etc.
    status VARCHAR(50) DEFAULT 'pending', -- pending, running, completed, failed
    credits_consumed DECIMAL(10,2),
    error_message TEXT,
    started_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_enrichment_runs_person ON enrichment_runs(person_id);
CREATE INDEX idx_enrichment_runs_client ON enrichment_runs(client_id);
CREATE INDEX idx_enrichment_runs_type ON enrichment_runs(enrichment_type);

-- ============================================================================
-- LEAD MAGIC PEOPLE ENRICHMENT TABLES
-- ============================================================================

-- Email Validation Enrichment
CREATE TABLE email_validation_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Email validation data
    email VARCHAR(255) NOT NULL,
    email_status VARCHAR(50), -- valid, invalid, unknown
    is_domain_catch_all BOOLEAN,
    mx_record VARCHAR(255),
    mx_provider VARCHAR(255),
    mx_security_gateway BOOLEAN,
    
    -- Company data (from validation)
    company_name VARCHAR(255),
    company_industry VARCHAR(255),
    company_size VARCHAR(50),
    company_founded INTEGER,
    company_location JSONB, -- Store full location object
    company_linkedin_url VARCHAR(500),
    company_linkedin_id VARCHAR(100),
    company_facebook_url VARCHAR(500),
    company_twitter_url VARCHAR(500),
    company_type VARCHAR(50),
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_email_validation_person ON email_validation_enrichment(person_id);
CREATE INDEX idx_email_validation_client ON email_validation_enrichment(client_id);

-- Email Finder Enrichment
CREATE TABLE email_finder_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Found email data
    email VARCHAR(255) NOT NULL,
    status VARCHAR(50),
    domain VARCHAR(255),
    is_domain_catch_all BOOLEAN,
    mx_record VARCHAR(255),
    mx_provider VARCHAR(255),
    mx_security_gateway BOOLEAN,
    
    -- Company data
    company_name VARCHAR(255),
    company_industry VARCHAR(255),
    company_size VARCHAR(50),
    company_founded INTEGER,
    company_location JSONB,
    company_linkedin_url VARCHAR(500),
    company_linkedin_id VARCHAR(100),
    company_facebook_url VARCHAR(500),
    company_twitter_url VARCHAR(500),
    company_type VARCHAR(50),
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_email_finder_person ON email_finder_enrichment(person_id);
CREATE INDEX idx_email_finder_client ON email_finder_enrichment(client_id);

-- Profile Search Enrichment
CREATE TABLE profile_search_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Profile data
    profile_url VARCHAR(500),
    full_name VARCHAR(255),
    professional_title TEXT,
    bio TEXT,
    company_name VARCHAR(255),
    company_industry VARCHAR(255),
    company_website VARCHAR(500),
    
    -- Tenure data
    total_tenure_months INTEGER,
    total_tenure_days INTEGER,
    total_tenure_years INTEGER,
    
    -- Additional data
    followers_range VARCHAR(50),
    personal_website JSONB, -- {name, link}
    country VARCHAR(100),
    location VARCHAR(255),
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_profile_search_person ON profile_search_enrichment(person_id);
CREATE INDEX idx_profile_search_client ON profile_search_enrichment(client_id);

-- Work History (from Profile Search & Job Change Detector)
CREATE TABLE work_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    source VARCHAR(50), -- 'profile_search', 'job_change_detector'
    
    -- Job data
    position_title VARCHAR(255),
    company_name VARCHAR(255),
    company_website VARCHAR(500),
    company_logo_url VARCHAR(500),
    employment_period TEXT,
    duration TEXT,
    start_date VARCHAR(50),
    end_date VARCHAR(50),
    is_present BOOLEAN,
    is_current_position BOOLEAN,
    days_at_job INTEGER,
    tenure_formatted VARCHAR(100),
    
    -- ICP matching (for buyer history analysis)
    is_icp BOOLEAN DEFAULT FALSE,
    icp_score DECIMAL(5,2),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_work_history_person ON work_history(person_id);
CREATE INDEX idx_work_history_client ON work_history(client_id);
CREATE INDEX idx_work_history_is_icp ON work_history(is_icp);

-- Education
CREATE TABLE education (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    institution_name VARCHAR(255),
    degree VARCHAR(255),
    attendance_period VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_education_person ON education(person_id);

-- Certifications
CREATE TABLE certifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    certification_name VARCHAR(255),
    issuing_organization VARCHAR(255),
    issue_date VARCHAR(100),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_certifications_person ON certifications(person_id);

-- Honors/Awards
CREATE TABLE honors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    title VARCHAR(255),
    description TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_honors_person ON honors(person_id);

-- Job Change Detection Enrichment
CREATE TABLE job_change_detection_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Detection results
    job_change_detected BOOLEAN,
    status VARCHAR(50), -- NEVER_WORKED_THERE, STILL_WORKING, JOB_CHANGED, etc.
    summary TEXT,
    employee_name VARCHAR(255),
    expected_company VARCHAR(255),
    current_company VARCHAR(255),
    
    -- Current position
    current_position JSONB, -- {title, company, start_date, days_at_job, tenure_formatted, is_current_position}
    
    -- Tenure statistics
    tenure_stats JSONB, -- {average_tenure_months, total_positions, longest_tenure_months, etc.}
    
    profile_found BOOLEAN,
    profile_url VARCHAR(500),
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_job_change_person ON job_change_detection_enrichment(person_id);
CREATE INDEX idx_job_change_client ON job_change_detection_enrichment(client_id);
CREATE INDEX idx_job_change_detected ON job_change_detection_enrichment(job_change_detected);

-- Mobile Finder Enrichment
CREATE TABLE mobile_finder_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    profile_url VARCHAR(500),
    mobile_number BIGINT,
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_mobile_finder_person ON mobile_finder_enrichment(person_id);
CREATE INDEX idx_mobile_finder_client ON mobile_finder_enrichment(client_id);

-- Email to B2B Profile Enrichment
CREATE TABLE email_to_profile_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    email VARCHAR(255),
    profile_url VARCHAR(500),
    message TEXT,
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_email_to_profile_person ON email_to_profile_enrichment(person_id);
CREATE INDEX idx_email_to_profile_client ON email_to_profile_enrichment(client_id);

-- B2B Social to Email Enrichment
CREATE TABLE social_to_email_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    profile_url VARCHAR(500),
    email VARCHAR(255),
    message TEXT,
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_social_to_email_person ON social_to_email_enrichment(person_id);
CREATE INDEX idx_social_to_email_client ON social_to_email_enrichment(client_id);

-- Employee Finder Enrichment
CREATE TABLE employee_finder_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Found employee data
    email VARCHAR(255),
    status VARCHAR(50),
    domain VARCHAR(255),
    is_domain_catch_all BOOLEAN,
    mx_record VARCHAR(255),
    mx_provider VARCHAR(255),
    mx_security_gateway BOOLEAN,
    
    -- Company data
    company_name VARCHAR(255),
    company_industry VARCHAR(255),
    company_size VARCHAR(50),
    company_founded INTEGER,
    company_location JSONB,
    company_linkedin_url VARCHAR(500),
    company_linkedin_id VARCHAR(100),
    company_facebook_url VARCHAR(500),
    company_twitter_url VARCHAR(500),
    company_type VARCHAR(50),
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_employee_finder_person ON employee_finder_enrichment(person_id);
CREATE INDEX idx_employee_finder_client ON employee_finder_enrichment(client_id);

-- Role Finder Enrichment
CREATE TABLE role_finder_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    person_id UUID NOT NULL REFERENCES people(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    name VARCHAR(255),
    profile_url VARCHAR(500),
    company_name VARCHAR(255),
    company_website VARCHAR(500),
    message TEXT,
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_role_finder_person ON role_finder_enrichment(person_id);
CREATE INDEX idx_role_finder_client ON role_finder_enrichment(client_id);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) FOR MULTI-TENANCY
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;
ALTER TABLE people ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE enrichment_runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_validation_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_finder_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_search_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE work_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE education ENABLE ROW LEVEL SECURITY;
ALTER TABLE certifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE honors ENABLE ROW LEVEL SECURITY;
ALTER TABLE job_change_detection_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_finder_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE email_to_profile_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE social_to_email_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE employee_finder_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE role_finder_enrichment ENABLE ROW LEVEL SECURITY;

-- Example RLS policies (adjust based on your auth setup)
-- Admin can see everything
CREATE POLICY "Admin full access to clients" ON clients
    FOR ALL USING (true);

-- Clients can only see their own data
CREATE POLICY "Clients see own people" ON people
    FOR SELECT USING (
        client_id = (SELECT id FROM clients WHERE id = auth.uid())
    );

-- Apply similar policies to all enrichment tables using client_id

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply to relevant tables
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_companies_updated_at BEFORE UPDATE ON companies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_people_updated_at BEFORE UPDATE ON people
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VIEWS FOR COMMON QUERIES
-- ============================================================================

-- View: People with all enrichment status
CREATE VIEW people_enrichment_status AS
SELECT 
    p.id,
    p.client_id,
    p.email,
    p.first_name,
    p.last_name,
    p.status,
    COUNT(DISTINCT er.id) as total_enrichments,
    COUNT(DISTINCT CASE WHEN er.status = 'completed' THEN er.id END) as completed_enrichments,
    COUNT(DISTINCT CASE WHEN er.status = 'failed' THEN er.id END) as failed_enrichments,
    SUM(er.credits_consumed) as total_credits_consumed
FROM people p
LEFT JOIN enrichment_runs er ON p.id = er.person_id
GROUP BY p.id;

-- ============================================================================
-- SAMPLE DATA (for testing)
-- ============================================================================

-- Insert test clients
INSERT INTO clients (id, name, status) VALUES
    ('11111111-1111-1111-1111-111111111111', 'Client One', 'active'),
    ('22222222-2222-2222-2222-222222222222', 'Client Two', 'active'),
    ('33333333-3333-3333-3333-333333333333', 'Client Three', 'active');

-- Note: Add sample people/companies/enrichments as needed for testing
-e 

-- ============================================================================
-- COMPANY ENRICHMENT TABLES
-- ============================================================================

-- ============================================================================
-- COMPANY ENRICHMENT TABLES - ADDENDUM TO SCHEMA.SQL
-- ============================================================================
-- Add these tables to the existing schema for Lead Magic company enrichments
-- ============================================================================

-- Company Search Enrichment
CREATE TABLE company_search_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Basic company info
    company_name VARCHAR(255),
    company_linkedin_id VARCHAR(100),
    employee_count INTEGER,
    employee_count_range JSONB, -- {start, end}
    specialities TEXT[],
    tagline TEXT,
    follower_count INTEGER,
    industry VARCHAR(255),
    description TEXT,
    website_url VARCHAR(500),
    
    -- Founded info
    founded_on JSONB, -- {year, month, day}
    founded_year VARCHAR(10),
    
    -- Social/URLs
    universal_name VARCHAR(255),
    hashtag VARCHAR(255),
    linkedin_url VARCHAR(500),
    logo_url VARCHAR(500),
    twitter_url VARCHAR(500),
    facebook_url VARCHAR(500),
    
    -- Financial
    ownership_status VARCHAR(50),
    revenue BIGINT,
    revenue_formatted VARCHAR(50),
    employee_range VARCHAR(50),
    stock_ticker VARCHAR(20),
    
    -- Funding
    total_funding VARCHAR(50),
    funding_rounds INTEGER,
    last_funding_round VARCHAR(100),
    last_funding_amount BIGINT,
    last_funding_date VARCHAR(50),
    
    -- Acquisitions
    acquisitions_count INTEGER,
    
    -- Competitors (stored as array for quick access)
    competitors TEXT[],
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_search_company ON company_search_enrichment(company_id);
CREATE INDEX idx_company_search_client ON company_search_enrichment(client_id);

-- Company Locations (from Company Search)
CREATE TABLE company_locations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    source VARCHAR(50), -- 'company_search', 'company_funding', etc.
    
    -- Location data
    country VARCHAR(100),
    city VARCHAR(255),
    geographic_area VARCHAR(255),
    postal_code VARCHAR(50),
    line1 TEXT,
    line2 TEXT,
    description VARCHAR(255),
    is_headquarter BOOLEAN DEFAULT FALSE,
    localized_name VARCHAR(255),
    latitude DECIMAL(10,7),
    longitude DECIMAL(10,7),
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_locations_company ON company_locations(company_id);
CREATE INDEX idx_company_locations_is_hq ON company_locations(is_headquarter);

-- Company Funding Enrichment
CREATE TABLE company_funding_enrichment (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Basic info
    company_name VARCHAR(255),
    short_name VARCHAR(100),
    description TEXT,
    founded VARCHAR(10),
    primary_domain VARCHAR(255),
    phone VARCHAR(50),
    status VARCHAR(50),
    followers INTEGER,
    ownership VARCHAR(50),
    
    -- Headquarters
    headquarters JSONB, -- {city, state, country, fullAddress}
    
    -- Financial info
    revenue BIGINT,
    formatted_revenue VARCHAR(50),
    total_funding BIGINT,
    formatted_funding VARCHAR(50),
    last_funding_round JSONB, -- {round, date, amount}
    
    -- Company size
    employees INTEGER,
    employee_range VARCHAR(50),
    employee_growth VARCHAR(50),
    
    -- Industry
    industry_sectors TEXT[],
    industries TEXT[],
    technology_stack TEXT,
    
    -- Summary
    summary_section TEXT,
    
    credits_consumed DECIMAL(10,2),
    enriched_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_funding_company ON company_funding_enrichment(company_id);
CREATE INDEX idx_company_funding_client ON company_funding_enrichment(client_id);

-- Funding Rounds (from Company Funding)
CREATE TABLE funding_rounds (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    round VARCHAR(50), -- 'Series A', 'Series B', etc.
    date TIMESTAMP WITH TIME ZONE,
    amount BIGINT,
    formatted_amount VARCHAR(50),
    investors TEXT[], -- Array of investor names
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_funding_rounds_company ON funding_rounds(company_id);
CREATE INDEX idx_funding_rounds_round ON funding_rounds(round);

-- Company Leadership (from Company Funding)
CREATE TABLE company_leadership (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    designation VARCHAR(255),
    linkedin_url VARCHAR(500),
    twitter_url VARCHAR(500),
    role VARCHAR(50), -- 'ceo', 'cfo', 'cto', etc.
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_leadership_company ON company_leadership(company_id);
CREATE INDEX idx_company_leadership_role ON company_leadership(role);

-- Company Competitors (from multiple sources)
CREATE TABLE company_competitors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    source VARCHAR(50), -- 'company_search', 'company_funding', 'competitors_search'
    
    -- Competitor data
    competitor_name VARCHAR(255),
    competitor_domain VARCHAR(255),
    short_description TEXT,
    founded_year VARCHAR(10),
    company_type VARCHAR(50),
    headquarters VARCHAR(255),
    employees_count INTEGER,
    valuation BIGINT,
    revenue BIGINT,
    revenue_formatted VARCHAR(50),
    total_funding BIGINT,
    funding_formatted VARCHAR(50),
    
    -- Tags/categories
    tags JSONB, -- Array of {name, slug, primary}
    
    -- Locations
    non_hq_locations TEXT[],
    
    -- Metrics
    financial_metrics JSONB,
    operating_metrics JSONB,
    funding_metrics JSONB,
    
    -- Social
    twitter_followers INTEGER,
    twitter_engagement JSONB,
    
    -- Growth indicator
    growth INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_competitors_company ON company_competitors(company_id);
CREATE INDEX idx_company_competitors_name ON company_competitors(competitor_name);

-- Company Acquisitions (from Company Funding)
CREATE TABLE company_acquisitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    acquired_company_name VARCHAR(255),
    acquisition_date TIMESTAMP WITH TIME ZONE,
    description TEXT,
    source_url TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_acquisitions_company ON company_acquisitions(company_id);
CREATE INDEX idx_company_acquisitions_date ON company_acquisitions(acquisition_date);

-- Company News (from Company Funding)
CREATE TABLE company_news (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    news_type VARCHAR(50), -- 'news', 'press_release', 'key_highlight'
    title TEXT,
    source VARCHAR(255),
    date TIMESTAMP WITH TIME ZONE,
    url TEXT,
    
    -- For key highlights
    highlight_type VARCHAR(50), -- 'partnership', 'ai', 'funding', etc.
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_news_company ON company_news(company_id);
CREATE INDEX idx_company_news_type ON company_news(news_type);
CREATE INDEX idx_company_news_date ON company_news(date);

-- Company Technographics
CREATE TABLE company_technographics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    technology_name VARCHAR(255),
    technology_description TEXT,
    categories TEXT[],
    
    -- Sub-technologies stored as JSONB array
    sub_technologies JSONB, -- [{name, description, categories}]
    
    credits_consumed DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_company_technographics_company ON company_technographics(company_id);
CREATE INDEX idx_company_technographics_name ON company_technographics(technology_name);

-- ============================================================================
-- ENABLE RLS ON NEW TABLES
-- ============================================================================

ALTER TABLE company_search_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_locations ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_funding_enrichment ENABLE ROW LEVEL SECURITY;
ALTER TABLE funding_rounds ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_leadership ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_competitors ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_acquisitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_news ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_technographics ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- UPDATED ENRICHMENT SUMMARY VIEW
-- ============================================================================

-- Drop existing view and recreate with company enrichments
DROP VIEW IF EXISTS people_enrichment_status;

CREATE VIEW enrichment_status_summary AS
SELECT 
    'person' as entity_type,
    p.id as entity_id,
    p.client_id,
    p.email as identifier,
    p.status,
    COUNT(DISTINCT er.id) as total_enrichments,
    COUNT(DISTINCT CASE WHEN er.status = 'completed' THEN er.id END) as completed_enrichments,
    COUNT(DISTINCT CASE WHEN er.status = 'failed' THEN er.id END) as failed_enrichments,
    SUM(er.credits_consumed) as total_credits_consumed
FROM people p
LEFT JOIN enrichment_runs er ON p.id = er.person_id
GROUP BY p.id, p.client_id, p.email, p.status

UNION ALL

SELECT 
    'company' as entity_type,
    c.id as entity_id,
    NULL as client_id,
    c.domain as identifier,
    NULL as status,
    COUNT(DISTINCT er.id) as total_enrichments,
    COUNT(DISTINCT CASE WHEN er.status = 'completed' THEN er.id END) as completed_enrichments,
    COUNT(DISTINCT CASE WHEN er.status = 'failed' THEN er.id END) as failed_enrichments,
    SUM(er.credits_consumed) as total_credits_consumed
FROM companies c
LEFT JOIN enrichment_runs er ON er.enrichment_type LIKE 'company_%'
GROUP BY c.id, c.domain;

-- ============================================================================
-- COMPANY ENRICHMENT TYPES FOR enrichment_runs TABLE
-- ============================================================================

-- Reference: Valid enrichment_type values for company enrichments:
-- 'company_search'
-- 'company_funding'
-- 'competitors_search'
-- 'technographics'
-e 

-- ============================================================================
-- JOBS DATA TABLES
-- ============================================================================

-- ============================================================================
-- JOBS DATA TABLES - ADDENDUM TO SCHEMA.SQL
-- ============================================================================
-- Add these tables for Lead Magic Jobs Data (Job Finder endpoint)
-- ============================================================================

-- Job Postings (from Job Finder)
CREATE TABLE job_postings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    enrichment_run_id UUID REFERENCES enrichment_runs(id) ON DELETE SET NULL,
    
    -- Company info
    company_name VARCHAR(255),
    company_website_url VARCHAR(500),
    company_linkedin_url VARCHAR(500),
    company_twitter_handle VARCHAR(100),
    company_github_url VARCHAR(500),
    
    -- Job details
    job_title VARCHAR(500),
    location VARCHAR(500),
    has_remote BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMP WITH TIME ZONE,
    description TEXT,
    application_url TEXT,
    language VARCHAR(10),
    clearance_required BOOLEAN DEFAULT FALSE,
    experience_level VARCHAR(100),
    
    -- Salary (often null)
    salary_min DECIMAL(15,2),
    salary_max DECIMAL(15,2),
    salary_currency VARCHAR(10),
    
    -- Job types (stored as JSONB array)
    job_types JSONB, -- [{id: 1, name: "Full Time"}]
    
    -- Location data (stored as JSONB for flexibility)
    cities JSONB, -- Array of city objects
    countries JSONB, -- Array of country objects
    regions JSONB, -- Array of region objects
    
    -- Metadata
    credits_consumed DECIMAL(10,2),
    search_query JSONB, -- Store original search parameters
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_job_postings_company ON job_postings(company_id);
CREATE INDEX idx_job_postings_client ON job_postings(client_id);
CREATE INDEX idx_job_postings_company_name ON job_postings(company_name);
CREATE INDEX idx_job_postings_published ON job_postings(published_at);
CREATE INDEX idx_job_postings_remote ON job_postings(has_remote);

-- Enable RLS
ALTER TABLE job_postings ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USE CASES FOR JOB POSTINGS DATA
-- ============================================================================

-- 1. BUYING SIGNAL: Companies hiring = actively spending money
/*
SELECT DISTINCT ON (company_name)
    company_name,
    company_website_url,
    COUNT(*) as open_positions,
    MAX(published_at) as latest_posting
FROM job_postings
WHERE published_at > NOW() - INTERVAL '30 days'
GROUP BY company_name, company_website_url
HAVING COUNT(*) > 5  -- Hiring aggressively
ORDER BY company_name, COUNT(*) DESC;
*/

-- 2. COMPETITIVE INTELLIGENCE: Track competitor hiring patterns
/*
SELECT 
    company_name,
    job_title,
    published_at,
    location
FROM job_postings
WHERE company_name IN ('Competitor A', 'Competitor B', 'Competitor C')
ORDER BY published_at DESC;
*/

-- 3. MARKET RESEARCH: Popular job titles in your ICP
/*
SELECT 
    job_title,
    COUNT(*) as posting_count,
    AVG(salary_min) as avg_min_salary,
    AVG(salary_max) as avg_max_salary
FROM job_postings
WHERE salary_min IS NOT NULL
GROUP BY job_title
ORDER BY posting_count DESC
LIMIT 20;
*/

-- 4. IDENTIFY EXPANSION COMPANIES: Companies hiring in specific roles
/*
SELECT 
    company_name,
    company_linkedin_url,
    COUNT(*) as sales_positions
FROM job_postings
WHERE job_title ILIKE '%sales%' 
  OR job_title ILIKE '%account executive%'
  OR job_title ILIKE '%business development%'
GROUP BY company_name, company_linkedin_url
HAVING COUNT(*) > 3
ORDER BY COUNT(*) DESC;
*/

-- ============================================================================
-- REFERENCE DATA TABLES (OPTIONAL - FOR CACHING LOOKUPS)
-- ============================================================================
-- These are typically fetched from GET endpoints and cached in application
-- Only create if you want to store reference data in database

-- Job Countries (optional - cache in app instead)
CREATE TABLE IF NOT EXISTS job_countries (
    country_code VARCHAR(2) PRIMARY KEY,
    country_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Job Regions (optional - cache in app instead)
CREATE TABLE IF NOT EXISTS job_regions (
    region_id INTEGER PRIMARY KEY,
    region_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Job Types (optional - cache in app instead)
CREATE TABLE IF NOT EXISTS job_types (
    type_id INTEGER PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Job Industries (optional - cache in app instead)
CREATE TABLE IF NOT EXISTS job_industries (
    industry_id INTEGER PRIMARY KEY,
    industry_name VARCHAR(255) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ============================================================================
-- NOTES ON JOBS DATA
-- ============================================================================

/*
CREDITS USAGE:
- Job Finder: 20 credits for 20 results (1 credit per result)
- Reference endpoints (country, region, type, industry): 0 credits (GET requests)

RECOMMENDED WORKFLOW:
1. Call reference endpoints once, cache results in frontend
2. Use Job Finder periodically to:
   - Identify companies hiring (buying signal)
   - Track competitor hiring patterns
   - Find expansion opportunities (companies scaling sales teams)
3. Link job_postings to companies table via company_name or company_website_url
4. Query for insights: hiring velocity, popular roles, salary trends

NOT FOR:
- Individual lead enrichment (this is company-level intelligence)
- Real-time job board (data may be delayed)
*/
-e 

-- ============================================================================
-- ADS DATA TABLES
-- ============================================================================

-- ============================================================================
-- ADS DATA TABLES - ADDENDUM TO SCHEMA.SQL
-- ============================================================================
-- Add these tables for Lead Magic Ads Data (competitive intelligence)
-- ============================================================================

-- Google Ads
CREATE TABLE google_ads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Ad identifiers
    advertiser_id VARCHAR(255),
    creative_id VARCHAR(255),
    original_url TEXT,
    advertiser_name VARCHAR(255),
    
    -- Ad details
    format VARCHAR(100), -- 'Text', 'Image', 'Video'
    variants JSONB, -- Array of variant objects {content, height, width}
    
    -- Timing
    start_date DATE,
    last_seen DATE,
    
    -- Metadata
    credits_consumed DECIMAL(10,2),
    search_query VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_google_ads_company ON google_ads(company_id);
CREATE INDEX idx_google_ads_advertiser ON google_ads(advertiser_name);
CREATE INDEX idx_google_ads_dates ON google_ads(start_date, last_seen);

-- Meta Ads (Facebook/Instagram)
CREATE TABLE meta_ads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Ad identifiers
    ad_id VARCHAR(255),
    ad_archive_id VARCHAR(255),
    collation_id BIGINT,
    page_id VARCHAR(255),
    page_name VARCHAR(255),
    
    -- Status
    is_active BOOLEAN,
    entity_type VARCHAR(100),
    
    -- Timing
    start_date TIMESTAMP WITH TIME ZONE,
    end_date TIMESTAMP WITH TIME ZONE,
    total_active_time INTEGER, -- seconds
    
    -- Snapshot (rich ad data)
    snapshot JSONB, -- Full ad creative object
    /*
    Snapshot includes:
    - ad_creative_id
    - title, caption, body
    - cta_text, link_url
    - images[], videos[]
    - page info, targeting
    */
    
    -- Platform
    publisher_platform TEXT[], -- ['facebook', 'instagram']
    
    -- Spend/impressions
    spend DECIMAL(15,2),
    impressions_text VARCHAR(100),
    
    -- Metadata
    credits_consumed DECIMAL(10,2),
    search_query VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_meta_ads_company ON meta_ads(company_id);
CREATE INDEX idx_meta_ads_page ON meta_ads(page_name);
CREATE INDEX idx_meta_ads_active ON meta_ads(is_active);
CREATE INDEX idx_meta_ads_dates ON meta_ads(start_date, end_date);

-- B2B Ads (LinkedIn - Simple List)
CREATE TABLE b2b_ads (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    
    -- Ad data
    content TEXT,
    link TEXT, -- LinkedIn ad library URL
    
    -- Metadata
    credits_consumed DECIMAL(10,2),
    search_query VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_b2b_ads_company ON b2b_ads(company_id);
CREATE INDEX idx_b2b_ads_link ON b2b_ads(link);

-- B2B Ad Details (LinkedIn - Full Data)
CREATE TABLE b2b_ad_details (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    company_id UUID REFERENCES companies(id) ON DELETE SET NULL,
    client_id UUID REFERENCES clients(id) ON DELETE CASCADE,
    b2b_ad_id UUID REFERENCES b2b_ads(id) ON DELETE SET NULL,
    
    -- Ad type
    ads_type VARCHAR(100), -- 'Video Ad', 'Image Ad', 'Text Ad'
    
    -- Content
    content TEXT,
    heading TEXT,
    sub_heading TEXT,
    image_url TEXT,
    
    -- CTA
    cta JSONB, -- {button_text, link}
    
    -- Video data
    video JSONB, -- {video_thumbnail, data_sources[]}
    
    -- Metrics
    total_impressions BIGINT,
    country_impressions JSONB, -- Array of country impression data
    
    -- Targeting
    targeting_language VARCHAR(100),
    targeting_location VARCHAR(255),
    availability_duration VARCHAR(100),
    
    -- Organization
    organization JSONB, -- {linkedin, advertiser}
    paying_entity TEXT,
    
    -- Metadata
    ad_url TEXT,
    credits_consumed DECIMAL(10,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_b2b_ad_details_company ON b2b_ad_details(company_id);
CREATE INDEX idx_b2b_ad_details_type ON b2b_ad_details(ads_type);

-- Enable RLS
ALTER TABLE google_ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE meta_ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE b2b_ads ENABLE ROW LEVEL SECURITY;
ALTER TABLE b2b_ad_details ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- USE CASES FOR ADS DATA
-- ============================================================================

-- 1. COMPETITIVE INTELLIGENCE: Track competitor ad creative
/*
-- See what messaging competitors are using
SELECT 
    advertiser_name,
    format,
    start_date,
    last_seen,
    EXTRACT(DAY FROM (last_seen - start_date)) as days_active
FROM google_ads
WHERE advertiser_name IN ('Competitor A', 'Competitor B')
ORDER BY start_date DESC;
*/

-- 2. BUYING SIGNAL: Companies advertising = companies with budget
/*
-- Find companies actively running ads (all platforms)
SELECT DISTINCT
    COALESCE(g.advertiser_name, m.page_name, o.advertiser) as company_name,
    COUNT(*) as total_ads,
    MAX(GREATEST(g.last_seen, m.end_date)) as last_ad_activity
FROM companies c
LEFT JOIN google_ads g ON c.id = g.company_id
LEFT JOIN meta_ads m ON c.id = m.company_id
LEFT JOIN (
    SELECT company_id, organization->>'advertiser' as advertiser
    FROM b2b_ad_details
) o ON c.id = o.company_id
WHERE g.last_seen > NOW() - INTERVAL '30 days'
   OR m.end_date > NOW() - INTERVAL '30 days'
GROUP BY company_name
HAVING COUNT(*) > 3
ORDER BY COUNT(*) DESC;
*/

-- 3. AD CREATIVE RESEARCH: Successful ad formats/messaging
/*
-- Analyze ad types by platform
SELECT 
    ads_type,
    COUNT(*) as count,
    AVG(total_impressions) as avg_impressions
FROM b2b_ad_details
WHERE total_impressions IS NOT NULL
GROUP BY ads_type
ORDER BY AVG(total_impressions) DESC;
*/

-- 4. MARKET TIMING: Ad activity trends
/*
-- Track when companies increase ad spend (seasonal patterns)
SELECT 
    DATE_TRUNC('month', start_date) as month,
    COUNT(*) as ads_launched
FROM google_ads
WHERE start_date > NOW() - INTERVAL '12 months'
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY month;
*/

-- ============================================================================
-- WORKFLOW: TWO-STEP LINKEDIN AD ENRICHMENT
-- ============================================================================
/*
Step 1: Get ad links
POST /v1/ads/b2b-search-ads
{
  "company_name": "Gong"
}

Response:
{
  "ads": [
    {"content": "...", "link": "https://linkedin.com/ad-library/detail/123"}
  ]
}

Step 2: Get full ad details for each link
POST /v1/ads/b2b-ads-details
{
  "ad_url": "https://linkedin.com/ad-library/detail/123"
}

Response:
{
  "adDetails": {
    "ads_type": "Video Ad",
    "video": {...},
    "cta": {...}
  }
}
*/

-- ============================================================================
-- NOTES ON ADS DATA
-- ============================================================================

/*
CREDITS USAGE:
- Google Ads Search: ~8 credits (variable by results)
- Meta Ads Search: ~2.6 credits
- B2B Search Ads: 2 credits (simple list)
- B2B Ad Details: 2 credits per ad (detailed data)

USE FOR:
1. Competitive intelligence (what messaging works)
2. Buying signals (companies with ad budgets)
3. Market research (trends, formats, timing)
4. Outreach personalization ("I saw your LinkedIn ad about...")

NOT FOR:
- Real-time ad tracking (data may be delayed)
- Precise spend estimates (not always available)
- Ad performance metrics (limited impression data)

RECOMMENDED FREQUENCY:
- Weekly for active competitors
- Monthly for market research
- On-demand for specific prospects
*/
