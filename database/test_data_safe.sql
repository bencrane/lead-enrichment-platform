-- ============================================================================
-- LEAD ENRICHMENT SYSTEM - TEST DATA (SAFE VERSION)
-- ============================================================================
-- Checks for existing data before inserting to avoid duplicates
-- ============================================================================

-- Check if clients already exist, if not insert
INSERT INTO clients (id, client_name, email, status, tier, notes)
SELECT * FROM (VALUES
    ('11111111-1111-1111-1111-111111111111', 'Acme Corp', 'admin@acmecorp.com', 'active', 'premium', 'Test client - webinar leads'),
    ('22222222-2222-2222-2222-222222222222', 'TechStart Inc', 'admin@techstart.io', 'active', 'standard', 'Test client - newsletter subscribers'),
    ('33333333-3333-3333-3333-333333333333', 'Global Solutions', 'admin@globalsolutions.com', 'active', 'enterprise', 'Test client - conference leads')
) AS v(id, client_name, email, status, tier, notes)
WHERE NOT EXISTS (
    SELECT 1 FROM clients WHERE email = v.email
);

-- Check if csv_uploads already exist
INSERT INTO csv_uploads (id, client_id, original_filename, total_rows, processed_rows, status, uploaded_at)
SELECT * FROM (VALUES
    ('aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', '11111111-1111-1111-1111-111111111111', 'Acme_Webinar_Leads_Nov_2024.csv', 5, 0, 'pending', NOW() - INTERVAL '1 hour'),
    ('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', '22222222-2222-2222-2222-222222222222', 'TechStart_Newsletter_Oct_2024.csv', 3, 0, 'pending', NOW() - INTERVAL '2 hours'),
    ('cccccccc-cccc-cccc-cccc-cccccccccccc', '33333333-3333-3333-3333-333333333333', 'GlobalSolutions_Conference_2024.csv', 4, 0, 'pending', NOW() - INTERVAL '3 hours')
) AS v(id, client_id, original_filename, total_rows, processed_rows, status, uploaded_at)
WHERE NOT EXISTS (
    SELECT 1 FROM csv_uploads WHERE id = v.id
);

-- Check if companies already exist
INSERT INTO companies (id, name, domain, linkedin_url, linkedin_id, employee_count, industry)
SELECT * FROM (VALUES
    ('c0000001-0000-0000-0000-000000000001', 'Microsoft', 'microsoft.com', 'https://www.linkedin.com/company/microsoft/', '1035', 220000, 'Technology'),
    ('c0000002-0000-0000-0000-000000000002', 'Google', 'google.com', 'https://www.linkedin.com/company/google/', '1441', 150000, 'Technology'),
    ('c0000003-0000-0000-0000-000000000003', 'Salesforce', 'salesforce.com', 'https://www.linkedin.com/company/salesforce/', '3185', 73000, 'Technology'),
    ('c0000004-0000-0000-0000-000000000004', 'HubSpot', 'hubspot.com', 'https://www.linkedin.com/company/hubspot/', '42147', 7000, 'Technology'),
    ('c0000005-0000-0000-0000-000000000005', 'Gong', 'gong.io', 'https://www.linkedin.com/company/gong-io/', '10048292', 1200, 'Technology')
) AS v(id, name, domain, linkedin_url, linkedin_id, employee_count, industry)
WHERE NOT EXISTS (
    SELECT 1 FROM companies WHERE domain = v.domain
);

-- Check if people already exist (Acme Corp leads)
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status)
SELECT * FROM (VALUES
    ('p1111111-1111-1111-1111-111111111111', '11111111-1111-1111-1111-111111111111', 'c0000001-0000-0000-0000-000000000001', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'sarah.chen@microsoft.com', 'Sarah', 'Chen', 'Sarah Chen', 'https://www.linkedin.com/in/sarahchen/', 'Microsoft', 'microsoft.com', 'staging', 'pending'),
    ('p1111111-1111-1111-1111-111111111112', '11111111-1111-1111-1111-111111111111', 'c0000002-0000-0000-0000-000000000002', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'michael.rodriguez@google.com', 'Michael', 'Rodriguez', 'Michael Rodriguez', 'https://www.linkedin.com/in/michaelrodriguez/', 'Google', 'google.com', 'staging', 'pending'),
    ('p1111111-1111-1111-1111-111111111113', '11111111-1111-1111-1111-111111111111', 'c0000003-0000-0000-0000-000000000003', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'jennifer.kim@salesforce.com', 'Jennifer', 'Kim', 'Jennifer Kim', 'https://www.linkedin.com/in/jenniferkim/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
    ('p1111111-1111-1111-1111-111111111114', '11111111-1111-1111-1111-111111111111', 'c0000004-0000-0000-0000-000000000004', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'david.patel@hubspot.com', 'David', 'Patel', 'David Patel', 'https://www.linkedin.com/in/davidpatel/', 'HubSpot', 'hubspot.com', 'staging', 'pending'),
    ('p1111111-1111-1111-1111-111111111115', '11111111-1111-1111-1111-111111111111', 'c0000005-0000-0000-0000-000000000005', 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', 'emily.johnson@gong.io', 'Emily', 'Johnson', 'Emily Johnson', 'https://www.linkedin.com/in/emilyjohnson/', 'Gong', 'gong.io', 'staging', 'pending')
) AS v(id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status)
WHERE NOT EXISTS (
    SELECT 1 FROM people WHERE id = v.id
);

-- Check if people already exist (TechStart Inc leads)
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status)
SELECT * FROM (VALUES
    ('p2222222-2222-2222-2222-222222222221', '22222222-2222-2222-2222-222222222222', 'c0000001-0000-0000-0000-000000000001', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'james.wilson@microsoft.com', 'James', 'Wilson', 'James Wilson', 'https://www.linkedin.com/in/jameswilson/', 'Microsoft', 'microsoft.com', 'staging', 'pending'),
    ('p2222222-2222-2222-2222-222222222222', '22222222-2222-2222-2222-222222222222', 'c0000003-0000-0000-0000-000000000003', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'lisa.garcia@salesforce.com', 'Lisa', 'Garcia', 'Lisa Garcia', 'https://www.linkedin.com/in/lisagarcia/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
    ('p2222222-2222-2222-2222-222222222223', '22222222-2222-2222-2222-222222222222', 'c0000005-0000-0000-0000-000000000005', 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb', 'robert.lee@gong.io', 'Robert', 'Lee', 'Robert Lee', 'https://www.linkedin.com/in/robertlee/', 'Gong', 'gong.io', 'staging', 'pending')
) AS v(id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status)
WHERE NOT EXISTS (
    SELECT 1 FROM people WHERE id = v.id
);

-- Check if people already exist (Global Solutions leads)
INSERT INTO people (id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status)
SELECT * FROM (VALUES
    ('p3333333-3333-3333-3333-333333333331', '33333333-3333-3333-3333-333333333333', 'c0000002-0000-0000-0000-000000000002', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'amanda.martinez@google.com', 'Amanda', 'Martinez', 'Amanda Martinez', 'https://www.linkedin.com/in/amandamartinez/', 'Google', 'google.com', 'staging', 'pending'),
    ('p3333333-3333-3333-3333-333333333332', '33333333-3333-3333-3333-333333333333', 'c0000003-0000-0000-0000-000000000003', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'christopher.brown@salesforce.com', 'Christopher', 'Brown', 'Christopher Brown', 'https://www.linkedin.com/in/christopherbrown/', 'Salesforce', 'salesforce.com', 'staging', 'pending'),
    ('p3333333-3333-3333-3333-333333333333', '33333333-3333-3333-3333-333333333333', 'c0000004-0000-0000-0000-000000000004', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'melissa.taylor@hubspot.com', 'Melissa', 'Taylor', 'Melissa Taylor', 'https://www.linkedin.com/in/melissataylor/', 'HubSpot', 'hubspot.com', 'staging', 'pending'),
    ('p3333333-3333-3333-3333-333333333334', '33333333-3333-3333-3333-333333333333', 'c0000005-0000-0000-0000-000000000005', 'cccccccc-cccc-cccc-cccc-cccccccccccc', 'daniel.anderson@gong.io', 'Daniel', 'Anderson', 'Daniel Anderson', 'https://www.linkedin.com/in/danielanderson/', 'Gong', 'gong.io', 'staging', 'pending')
) AS v(id, client_id, company_id, csv_upload_id, email, first_name, last_name, full_name, linkedin_url, company_name, company_domain, status, enrichment_status)
WHERE NOT EXISTS (
    SELECT 1 FROM people WHERE id = v.id
);

-- ============================================================================
-- VERIFICATION QUERIES
-- ============================================================================

-- Show what was inserted
SELECT 'Clients created:' as info, COUNT(*) as count FROM clients WHERE id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
);

SELECT 'People created:' as info, COUNT(*) as count FROM people WHERE client_id IN (
    '11111111-1111-1111-1111-111111111111',
    '22222222-2222-2222-2222-222222222222',
    '33333333-3333-3333-3333-333333333333'
);

SELECT 'Companies created:' as info, COUNT(*) as count FROM companies WHERE id IN (
    'c0000001-0000-0000-0000-000000000001',
    'c0000002-0000-0000-0000-000000000002',
    'c0000003-0000-0000-0000-000000000003',
    'c0000004-0000-0000-0000-000000000004',
    'c0000005-0000-0000-0000-000000000005'
);
