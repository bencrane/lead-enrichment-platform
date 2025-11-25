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
