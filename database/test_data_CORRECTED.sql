-- ============================================================================
-- LEAD ENRICHMENT SYSTEM - TEST DATA (VALID HEX UUIDS)
-- ============================================================================
-- Uses your existing client UUIDs + valid hexadecimal pattern UUIDs
-- All UUIDs use only 0-9 and a-f (no 'p' which is invalid hex)
-- ============================================================================

-- Your existing client IDs:
-- TechStart Inc:     30deebe2-4af4-48da-8bcb-b97fb9745bb0
-- Acme Corp:         367c6830-d60e-4bb1-8b5e-3bee951fdc01
-- Global Solutions:  a0d4bdab-14c5-4bc6-957e-7edf03b385a1

-- ============================================================================
-- 1. INSERT CSV UPLOADS
-- ============================================================================

INSERT INTO csv_uploads (id, client_id, original_filename, total_rows, processed_rows, status, uploaded_at) VALUES
-- TechStart Inc upload
('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '30deebe2-4af4-48da-8bcb-b97fb9745bb0', 'TechStart_Newsletter_Nov_2024.csv', 3, 0, 'pending', NOW() - INTERVAL '1 hour'),

-- Acme Corp upload
('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '367c6830-d60e-4bb1-8b5e-3bee951fdc01', 'Acme_Webinar_Leads_Nov_2024.csv', 5, 0, 'pending', NOW() - INTERVAL '2 hours'),

-- Global Solutions upload
('cccccccc-cccc-cccc-cccc-cccccccccccc', 'a0d4bdab-14c5-4bc6-957e-7edf03b385a1', 'GlobalSolutions_Conference_2024.csv', 4, 0, 'pending', NOW() - INTERVAL '3 hours');

-- ============================================================================
-- 2. INSERT TEST COMPANIES (Shared Across All Clients)
-- ============================================================================

INSERT INTO companies (id, name, domain, linkedin_url, linkedin_id, employee_count, industry) VALUES
('c0000001-0000-0000-0000-000000000001', 'Microsoft', 'microsoft.com', 'https://www.linkedin.com/company/microsoft/', '1035', 220000, 'Technology'),
('c0000002-0000-0000-0000-000000000002', 'Google', 'google.com', 'https://www.linkedin.com/company/google/', '1441', 150000, 'Technology'),
('c0000003-0000-0000-0000-000000000003', 'Salesforce', 'salesforce.com', 'https://www.linkedin.com/company/salesforce/', '3185', 73000, 'Technology'),
('c0000004-0000-0000-0000-000000000004', 'HubSpot', 'hubspot.com', 'https://www.linkedin.com/company/hubspot/', '42147', 7000, 'Technology'),
('c0000005-0000-0000-0000-000000000005', 'Gong', 'gong.io', 'https://www.linkedin.com/company/gong-io/', '10048292', 1200, 'Technology');

-- ============================================================================
-- 3. INSERT TEST PEOPLE
-- ============================================================================

-- TechStart Inc leads (3 people) - prefix 'a1'
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status) VALUES
('a1111111-1111-1111-1111-111111111111', '30deebe2-4af4-48da-8bcb-b97fb9745bb0', 'c0000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'james.wilson@microsoft.com', 'James', 'Wilson', 'James Wilson', 'https://www.linkedin.com/in/jameswilson/', 'Microsoft', 'microsoft.com', 'staging', 'pending'),
('a1111112-1111-1111-1111-111111111111', '30deebe2-4af4-48da-8bcb-b97fb9745bb0', 'c0000003-0000-0000-0000-000000000003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'lisa.garcia@salesforce.com', 'Lisa', 'Garcia', 'Lisa Garcia', 'https://www.linkedin.com/in/lisagarcia/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
('a1111113-1111-1111-1111-111111111111', '30deebe2-4af4-48da-8bcb-b97fb9745bb0', 'c0000005-0000-0000-0000-000000000005', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'robert.lee@gong.io', 'Robert', 'Lee', 'Robert Lee', 'https://www.linkedin.com/in/robertlee/', 'Gong', 'gong.io', 'staging', 'pending');

-- Acme Corp leads (5 people) - prefix 'b1'
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status) VALUES
('b1111111-1111-1111-1111-111111111111', '367c6830-d60e-4bb1-8b5e-3bee951fdc01', 'c0000001-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'sarah.chen@microsoft.com', 'Sarah', 'Chen', 'Sarah Chen', 'https://www.linkedin.com/in/sarahchen/', 'Microsoft', 'microsoft.com', 'staging', 'pending'),
('b1111112-1111-1111-1111-111111111111', '367c6830-d60e-4bb1-8b5e-3bee951fdc01', 'c0000002-0000-0000-0000-000000000002', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'michael.rodriguez@google.com', 'Michael', 'Rodriguez', 'Michael Rodriguez', 'https://www.linkedin.com/in/michaelrodriguez/', 'Google', 'google.com', 'staging', 'pending'),
('b1111113-1111-1111-1111-111111111111', '367c6830-d60e-4bb1-8b5e-3bee951fdc01', 'c0000003-0000-0000-0000-000000000003', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'jennifer.kim@salesforce.com', 'Jennifer', 'Kim', 'Jennifer Kim', 'https://www.linkedin.com/in/jenniferkim/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
('b1111114-1111-1111-1111-111111111111', '367c6830-d60e-4bb1-8b5e-3bee951fdc01', 'c0000004-0000-0000-0000-000000000004', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'david.patel@hubspot.com', 'David', 'Patel', 'David Patel', 'https://www.linkedin.com/in/davidpatel/', 'HubSpot', 'hubspot.com', 'staging', 'pending'),
('b1111115-1111-1111-1111-111111111111', '367c6830-d60e-4bb1-8b5e-3bee951fdc01', 'c0000005-0000-0000-0000-000000000005', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'emily.johnson@gong.io', 'Emily', 'Johnson', 'Emily Johnson', 'https://www.linkedin.com/in/emilyjohnson/', 'Gong', 'gong.io', 'staging', 'pending');

-- Global Solutions leads (4 people) - prefix 'd1'
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status) VALUES
('d1111111-1111-1111-1111-111111111111', 'a0d4bdab-14c5-4bc6-957e-7edf03b385a1', 'c0000002-0000-0000-0000-000000000002', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'amanda.martinez@google.com', 'Amanda', 'Martinez', 'Amanda Martinez', 'https://www.linkedin.com/in/amandamartinez/', 'Google', 'google.com', 'staging', 'pending'),
('d1111112-1111-1111-1111-111111111111', 'a0d4bdab-14c5-4bc6-957e-7edf03b385a1', 'c0000003-0000-0000-0000-000000000003', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'christopher.brown@salesforce.com', 'Christopher', 'Brown', 'Christopher Brown', 'https://www.linkedin.com/in/christopherbrown/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
('d1111113-1111-1111-1111-111111111111', 'a0d4bdab-14c5-4bc6-957e-7edf03b385a1', 'c0000004-0000-0000-0000-000000000004', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'melissa.taylor@hubspot.com', 'Melissa', 'Taylor', 'Melissa Taylor', 'https://www.linkedin.com/in/melissataylor/', 'HubSpot', 'hubspot.com', 'staging', 'pending'),
('d1111114-1111-1111-1111-111111111111', 'a0d4bdab-14c5-4bc6-957e-7edf03b385a1', 'c0000005-0000-0000-0000-000000000005', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'daniel.anderson@gong.io', 'Daniel', 'Anderson', 'Daniel Anderson', 'https://www.linkedin.com/in/danielanderson/', 'Gong', 'gong.io', 'staging', 'pending');

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Check what was created
SELECT 'CSV Uploads:' as info, COUNT(*) as count FROM csv_uploads;
SELECT 'Companies:' as info, COUNT(*) as count FROM companies;
SELECT 'People:' as info, COUNT(*) as count FROM people;

-- Show people per client
SELECT 
    c.client_name,
    COUNT(p.id) as lead_count
FROM clients c
LEFT JOIN people p ON c.id = p.client_id
GROUP BY c.client_name
ORDER BY c.client_name;

-- Show all test people
SELECT 
    c.client_name,
    p.full_name,
    p.email,
    p.company_name,
    p.status
FROM people p
JOIN clients c ON p.client_id = c.id
ORDER BY c.client_name, p.last_name;

-- ============================================================================
-- QUICK REFERENCE - TEST UUIDS FOR n8n WORKFLOWS
-- ============================================================================

/*
═══════════════════════════════════════════════════════════════════════════
CLIENT IDS (YOUR EXISTING CLIENTS):
═══════════════════════════════════════════════════════════════════════════
TechStart Inc:     30deebe2-4af4-48da-8bcb-b97fb9745bb0
Acme Corp:         367c6830-d60e-4bb1-8b5e-3bee951fdc01
Global Solutions:  a0d4bdab-14c5-4bc6-957e-7edf03b385a1

═══════════════════════════════════════════════════════════════════════════
CSV UPLOAD IDS (NEW):
═══════════════════════════════════════════════════════════════════════════
TechStart upload:  aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa
Acme upload:       bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb
Global upload:     cccccccc-cccc-cccc-cccc-cccccccccccc

═══════════════════════════════════════════════════════════════════════════
PERSON IDS - TechStart Inc (3 people) - Pattern: a111111X
═══════════════════════════════════════════════════════════════════════════
James Wilson:      a1111111-1111-1111-1111-111111111111
Lisa Garcia:       a1111112-1111-1111-1111-111111111111
Robert Lee:        a1111113-1111-1111-1111-111111111111

═══════════════════════════════════════════════════════════════════════════
PERSON IDS - Acme Corp (5 people) - Pattern: b111111X
═══════════════════════════════════════════════════════════════════════════
Sarah Chen:        b1111111-1111-1111-1111-111111111111
Michael Rodriguez: b1111112-1111-1111-1111-111111111111
Jennifer Kim:      b1111113-1111-1111-1111-111111111111
David Patel:       b1111114-1111-1111-1111-111111111111
Emily Johnson:     b1111115-1111-1111-1111-111111111111

═══════════════════════════════════════════════════════════════════════════
PERSON IDS - Global Solutions (4 people) - Pattern: d111111X
═══════════════════════════════════════════════════════════════════════════
Amanda Martinez:   d1111111-1111-1111-1111-111111111111
Christopher Brown: d1111112-1111-1111-1111-111111111111
Melissa Taylor:    d1111113-1111-1111-1111-111111111111
Daniel Anderson:   d1111114-1111-1111-1111-111111111111

═══════════════════════════════════════════════════════════════════════════
COMPANY IDS (Pattern: c000000X):
═══════════════════════════════════════════════════════════════════════════
Microsoft:         c0000001-0000-0000-0000-000000000001
Google:            c0000002-0000-0000-0000-000000000002
Salesforce:        c0000003-0000-0000-0000-000000000003
HubSpot:           c0000004-0000-0000-0000-000000000004
Gong:              c0000005-0000-0000-0000-000000000005
*/

-- ============================================================================
-- TEST WEBHOOK PAYLOADS FOR n8n
-- ============================================================================

/*
═══════════════════════════════════════════════════════════════════════════
Test Email Validation workflow (Acme Corp - Sarah Chen):
═══════════════════════════════════════════════════════════════════════════
{
  "person_id": "b1111111-1111-1111-1111-111111111111",
  "client_id": "367c6830-d60e-4bb1-8b5e-3bee951fdc01",
  "enrichment_type": "email_validation"
}

═══════════════════════════════════════════════════════════════════════════
Test Profile Search workflow (TechStart Inc - James Wilson):
═══════════════════════════════════════════════════════════════════════════
{
  "person_id": "a1111111-1111-1111-1111-111111111111",
  "client_id": "30deebe2-4af4-48da-8bcb-b97fb9745bb0",
  "enrichment_type": "profile_search"
}

═══════════════════════════════════════════════════════════════════════════
Test Company Funding workflow (Gong):
═══════════════════════════════════════════════════════════════════════════
{
  "company_id": "c0000005-0000-0000-0000-000000000005",
  "client_id": "367c6830-d60e-4bb1-8b5e-3bee951fdc01",
  "enrichment_type": "company_funding"
}
*/

-- ============================================================================
-- PATTERN KEY FOR EASY MEMORY
-- ============================================================================
/*
a1111111... = TechStart person 1
a1111112... = TechStart person 2
a1111113... = TechStart person 3

b1111111... = Acme person 1
b1111112... = Acme person 2
b1111113... = Acme person 3
b1111114... = Acme person 4
b1111115... = Acme person 5

d1111111... = Global person 1
d1111112... = Global person 2
d1111113... = Global person 3
d1111114... = Global person 4

c0000001... = Microsoft
c0000002... = Google
c0000003... = Salesforce
c0000004... = HubSpot
c0000005... = Gong
*/
