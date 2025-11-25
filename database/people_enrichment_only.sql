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
