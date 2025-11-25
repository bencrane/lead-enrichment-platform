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
