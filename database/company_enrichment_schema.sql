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
