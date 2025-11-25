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
