-- ============================================================================
-- LEAD ENRICHMENT SYSTEM - TEST DATA
-- ============================================================================
-- Run this AFTER creating all tables
-- Creates realistic test data you can use to test n8n workflows
-- ============================================================================

-- ============================================================================
-- 1. INSERT TEST CLIENTS (Your Business Customers)
-- ============================================================================

INSERT INTO clients (id, client_name, email, status, tier, notes) VALUES
('11111111-1111-1111-1111-111111111111', 'Acme Corp', 'admin@acmecorp.com', 'active', 'premium', 'Test client - webinar leads'),
('22222222-2222-2222-2222-222222222222', 'TechStart Inc', 'admin@techstart.io', 'active', 'standard', 'Test client - newsletter subscribers'),
('33333333-3333-3333-3333-333333333333', 'Global Solutions', 'admin@globalsolutions.com', 'active', 'enterprise', 'Test client - conference leads');

-- ============================================================================
-- 2. INSERT TEST CSV UPLOADS
-- ============================================================================

INSERT INTO csv_uploads (id, client_id, original_filename, total_rows, processed_rows, status, uploaded_at) VALUES
-- Acme Corp uploads
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Acme_Webinar_Leads_Nov_2024.csv', 5, 0, 'pending', NOW() - INTERVAL '1 hour'),

-- TechStart uploads
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'TechStart_Newsletter_Oct_2024.csv', 3, 0, 'pending', NOW() - INTERVAL '2 hours'),

-- Global Solutions uploads
('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'GlobalSolutions_Conference_2024.csv', 4, 0, 'pending', NOW() - INTERVAL '3 hours');

-- ============================================================================
-- 3. INSERT TEST COMPANIES (Shared Across All Clients)
-- ============================================================================

INSERT INTO companies (id, name, domain, linkedin_url, linkedin_id, employee_count, industry) VALUES
('c0000001-0000-0000-0000-000000000001', 'Microsoft', 'microsoft.com', 'https://www.linkedin.com/company/microsoft/', '1035', 220000, 'Technology'),
('c0000002-0000-0000-0000-000000000002', 'Google', 'google.com', 'https://www.linkedin.com/company/google/', '1441', 150000, 'Technology'),
('c0000003-0000-0000-0000-000000000003', 'Salesforce', 'salesforce.com', 'https://www.linkedin.com/company/salesforce/', '3185', 73000, 'Technology'),
('c0000004-0000-0000-0000-000000000004', 'HubSpot', 'hubspot.com', 'https://www.linkedin.com/company/hubspot/', '42147', 7000, 'Technology'),
('c0000005-0000-0000-0000-000000000005', 'Gong', 'gong.io', 'https://www.linkedin.com/company/gong-io/', '10048292', 1200, 'Technology');

-- ============================================================================
-- 4. INSERT TEST PEOPLE (Leads for Each Client)
-- ============================================================================

-- Acme Corp leads (5 people)
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status) VALUES
('p1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'c0000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'sarah.chen@microsoft.com', 'Sarah', 'Chen', 'Sarah Chen', 'https://www.linkedin.com/in/sarahchen/', 'Microsoft', 'microsoft.com', 'staging', 'pending'),
('p1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'c0000002-0000-0000-0000-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'michael.rodriguez@google.com', 'Michael', 'Rodriguez', 'Michael Rodriguez', 'https://www.linkedin.com/in/michaelrodriguez/', 'Google', 'google.com', 'staging', 'pending'),
('p1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'c0000003-0000-0000-0000-000000000003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'jennifer.kim@salesforce.com', 'Jennifer', 'Kim', 'Jennifer Kim', 'https://www.linkedin.com/in/jenniferkim/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
('p1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'c0000004-0000-0000-0000-000000000004', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'david.patel@hubspot.com', 'David', 'Patel', 'David Patel', 'https://www.linkedin.com/in/davidpatel/', 'HubSpot', 'hubspot.com', 'staging', 'pending'),
('p1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'c0000005-0000-0000-0000-000000000005', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'emily.johnson@gong.io', 'Emily', 'Johnson', 'Emily Johnson', 'https://www.linkedin.com/in/emilyjohnson/', 'Gong', 'gong.io', 'staging', 'pending');

-- TechStart Inc leads (3 people)
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status) VALUES
('p2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222', 'c0000001-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'james.wilson@microsoft.com', 'James', 'Wilson', 'James Wilson', 'https://www.linkedin.com/in/jameswilson/', 'Microsoft', 'microsoft.com', 'staging', 'pending'),
('p2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'c0000003-0000-0000-0000-000000000003', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'lisa.garcia@salesforce.com', 'Lisa', 'Garcia', 'Lisa Garcia', 'https://www.linkedin.com/in/lisagarcia/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
('p2222222-2222-2222-2222-222222222223', '22222222-2222-2222-2222-222222222222', 'c0000005-0000-0000-0000-000000000005', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'robert.lee@gong.io', 'Robert', 'Lee', 'Robert Lee', 'https://www.linkedin.com/in/robertlee/', 'Gong', 'gong.io', 'staging', 'pending');

-- Global Solutions leads (4 people)
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status) VALUES
('p3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333', 'c0000002-0000-0000-0000-000000000002', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'amanda.martinez@google.com', 'Amanda', 'Martinez', 'Amanda Martinez', 'https://www.linkedin.com/in/amandamartinez/', 'Google', 'google.com', 'staging', 'pending'),
('p3333333-3333-3333-3333-333333333332', '33333333-3333-3333-3333-333333333333', 'c0000003-0000-0000-0000-000000000003', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'christopher.brown@salesforce.com', 'Christopher', 'Brown', 'Christopher Brown', 'https://www.linkedin.com/in/christopherbrown/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
('p3333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333', 'c0000004-0000-0000-0000-000000000004', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'melissa.taylor@hubspot.com', 'Melissa', 'Taylor', 'Melissa Taylor', 'https://www.linkedin.com/in/melissataylor/', 'HubSpot', 'hubspot.com', 'staging', 'pending'),
('p3333333-3333-3333-3333-333333333334', '33333333-3333-3333-3333-333333333333', 'c0000005-0000-0000-0000-000000000005', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'daniel.anderson@gong.io', 'Daniel', 'Anderson', 'Daniel Anderson', 'https://www.linkedin.com/in/danielanderson/', 'Gong', 'gong.io', 'staging', 'pending');

-- ============================================================================
-- 5. VERIFICATION QUERIES
-- ============================================================================

-- Check clients
SELECT 
    id, 
    client_name, 
    email, 
    status 
FROM clients 
ORDER BY created_at;

-- Check CSV uploads per client
SELECT 
    cu.id,
    c.client_name,
    cu.original_filename,
    cu.total_rows,
    cu.status,
    cu.uploaded_at
FROM csv_uploads cu
JOIN clients c ON cu.client_id = c.id
ORDER BY cu.uploaded_at DESC;

-- Check people per client
SELECT 
    c.client_name,
    COUNT(p.id) as lead_count,
    COUNT(DISTINCT p.company_id) as unique_companies
FROM clients c
LEFT JOIN people p ON c.id = p.client_id
GROUP BY c.client_name
ORDER BY c.client_name;

-- Check people details
SELECT 
    p.id,
    c.client_name,
    p.email,
    p.full_name,
    p.company_name,
    p.status,
    p.enrichment_status
FROM people p
JOIN clients c ON p.client_id = c.id
ORDER BY c.client_name, p.last_name;

-- Check companies
SELECT 
    id,
    name,
    domain,
    employee_count,
    industry
FROM companies
ORDER BY name;

-- ============================================================================
-- 6. QUICK REFERENCE - TEST UUIDS TO USE IN n8n WORKFLOWS
-- ============================================================================

/*
CLIENT IDS:
- Acme Corp:         11111111-1111-1111-1111-111111111111
- TechStart Inc:     22222222-2222-2222-2222-222222222222
- Global Solutions:  33333333-3333-3333-3333-333333333333

CSV UPLOAD IDS:
- Acme upload:       aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
- TechStart upload:  bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
- Global upload:     cccccccc-cccc-cccc-cccc-cccccccccccc

PERSON IDS (Acme Corp - for testing):
- Sarah Chen:        p1111111-1111-1111-1111-111111111111
- Michael Rodriguez: p1111111-1111-1111-1111-111111111112
- Jennifer Kim:      p1111111-1111-1111-1111-111111111113
- David Patel:       p1111111-1111-1111-1111-111111111114
- Emily Johnson:     p1111111-1111-1111-1111-111111111115

COMPANY IDS:
- Microsoft:         c0000001-0000-0000-0000-000000000001
- Google:            c0000002-0000-0000-0000-000000000002
- Salesforce:        c0000003-0000-0000-0000-000000000003
- HubSpot:           c0000004-0000-0000-0000-000000000004
- Gong:              c0000005-0000-0000-0000-000000000005
*/

-- ============================================================================
-- 7. TEST WEBHOOK PAYLOADS FOR n8n
-- ============================================================================

/*
Test Email Validation workflow:
{
  "person_id": "p1111111-1111-1111-1111-111111111111",
  "client_id": "11111111-1111-1111-1111-111111111111",
  "enrichment_type": "email_validation"
}

Test Profile Search workflow:
{
  "person_id": "p1111111-1111-1111-1111-111111111111",
  "client_id": "11111111-1111-1111-1111-111111111111",
  "enrichment_type": "profile_search"
}

Test Company Funding workflow:
{
  "company_id": "c0000005-0000-0000-0000-000000000005",
  "client_id": "11111111-1111-1111-1111-111111111111",
  "enrichment_type": "company_funding"
}
*/

-- ============================================================================
-- 8. HELPFUL QUERIES FOR TESTING
-- ============================================================================

-- Get person with company data (what n8n will query)
SELECT 
    p.id as person_id,
    p.client_id,
    p.email,
    p.first_name,
    p.last_name,
    p.linkedin_url,
    p.company_name,
    c.id as company_id,
    c.domain as company_domain,
    c.name as company_name_from_companies_table
FROM people p
LEFT JOIN companies c ON p.company_id = c.id
WHERE p.id = 'p1111111-1111-1111-1111-111111111111';

-- Get all pending enrichments for a client
SELECT 
    p.id,
    p.email,
    p.full_name,
    p.company_name,
    p.enrichment_status,
    p.enrichment_count
FROM people p
WHERE p.client_id = '11111111-1111-1111-1111-111111111111'
  AND p.enrichment_status = 'pending'
ORDER BY p.created_at;

-- Check enrichment runs (will be empty until workflows run)
SELECT 
    er.id,
    er.enrichment_type,
    er.status,
    er.credits_consumed,
    p.full_name,
    c.client_name
FROM enrichment_runs er
JOIN people p ON er.person_id = p.id
JOIN clients c ON er.client_id = c.id
ORDER BY er.completed_at DESC;

-- ============================================================================
-- END OF TEST DATA
-- ============================================================================
