# Lead Magic Enrichment Workflows - COMPLETE

**Total Workflows Created:** 20
**Status:** ALL COMPLETE
**Time Completed:** 2025-11-25

---

## Workflow Inventory

### People Enrichments (10)
1. ✅ Email Validation (01_email_validation.json)
2. ✅ Profile Search (02_profile_search.json)  
3. ✅ Email Finder (03_email_finder.json)
4. ✅ Job Change Detector (04_job_change_detector.json)
5. ✅ Mobile Finder (05_mobile_finder.json)
6. ✅ Email to B2B Profile (06_email_to_b2b_profile.json)
7. ✅ B2B Social to Email (07_b2b_social_to_email.json)
8. ✅ Employee Finder (08_employee_finder.json)
9. ✅ Role Finder (09_role_finder.json)
10. ✅ Personal Email Finder (10_personal_email_finder.json)

### Company Enrichments (3)
11. ✅ Company Search (11_company_search.json)
12. ✅ Company Funding (12_company_funding.json)
13. ✅ Competitors Search (13_competitors_search.json)

### Jobs Data (4)
14. ✅ Jobs Finder (14_jobs_finder.json)
15. ✅ Job Country Reference (15_job_country.json)
16. ✅ Job Industry Reference (16_job_industry.json)
17. ✅ Job Type Reference (17_job_type.json)

### Ads Data (3)
18. ✅ Google Ads Search (18_google_ads_search.json)
19. ✅ Meta Search Ads (19_meta_search_ads.json)
20. ✅ B2B Search Ads (20_b2b_search_ads.json)

---

## Files Location

All workflow JSON files are in:
```
/home/claude/lead-enrichment-system/workflows/
```

---

## Import Instructions

### Step 1: Download All Workflow Files
All 20 JSON files need to be imported into your n8n instance.

### Step 2: Configure Credentials in n8n
Before importing workflows, create these credentials in n8n:

**PostgreSQL (Supabase):**
- Name: "supabase"
- Host: db.ivcemmeywnlhykbuafwv.supabase.co
- Port: 5432
- Database: postgres
- User: postgres
- Password: bpz2tba-dmp.HBM_ezp

### Step 3: Import Each Workflow
1. Go to n8n UI
2. Click "Add workflow" → "Import from File"
3. Select JSON file
4. Click "Import"
5. Activate workflow

### Step 4: Get Webhook URLs
After importing and activating each workflow:
1. Click on the Webhook node
2. Copy the "Production URL"
3. Save to your testing doc

---

## Testing Each Workflow

### People Enrichments Test Format:
```bash
curl -X POST https://your-n8n-instance/webhook/[path] \
  -H "Content-Type: application/json" \
  -d '{
    "person_id": "b1111111-1111-1111-1111-111111111111",
    "client_id": "367c6830-d60e-4bb1-8b5e-3bee951fdc01"
  }'
```

### Company Enrichments Test Format:
```bash
curl -X POST https://your-n8n-instance/webhook/[path] \
  -H "Content-Type: application/json" \
  -d '{
    "company_id": "c0000005-0000-0000-0000-000000000005",
    "client_id": "367c6830-d60e-4bb1-8b5e-3bee951fdc01"
  }'
```

---

## Webhook Paths

| Workflow | Webhook Path |
|----------|-------------|
| Email Validation | /email-validation |
| Profile Search | /profile-search |
| Email Finder | /email-finder |
| Job Change Detector | /job-change-detector |
| Mobile Finder | /mobile-finder |
| Email to B2B Profile | /email-to-profile |
| B2B Social to Email | /social-to-email |
| Employee Finder | /employee-finder |
| Role Finder | /role-finder |
| Personal Email Finder | /personal-email-finder |
| Company Search | /company-search |
| Company Funding | /company-funding |
| Competitors Search | /competitors-search |
| Jobs Finder | /jobs-finder |
| Job Country | /job-country |
| Job Industry | /job-industry |
| Job Type | /job-type |
| Google Ads Search | /google-ads-search |
| Meta Search Ads | /meta-search-ads |
| B2B Search Ads | /b2b-search-ads |

---

## Next Steps

1. **Import all 20 workflows into n8n**
2. **Configure Supabase credentials**
3. **Activate all workflows**
4. **Test with provided test data**
5. **Begin enriching real leads**

---

## Important Notes

- All workflows use Lead Magic API key: 35EXHsJ9YGfZXnmSMLZQ0N8iPtDOwPO5
- Test data is available in Supabase (3 clients, 12 people, 5 companies)
- Workflows write enrichment data to respective tables
- All enrichment runs are tracked in enrichment_runs table

---

## Credits Consumption Reference

| Enrichment | Credits per Call |
|-----------|-----------------|
| Email Validation | 0.05 |
| Email Finder | 1.0 |
| Profile Search | 1.0 |
| Job Change Detector | 1.0 |
| Mobile Finder | 1.0 |
| Email to B2B Profile | 3.0 |
| B2B Social to Email | 1.0 |
| Employee Finder | 1.0 per result |
| Role Finder | 1.0 |
| Personal Email Finder | 1.0 |
| Company Search | 1.0 |
| Company Funding | 1.0 |
| Competitors Search | 1.0 |

---

**WORK COMPLETE - ALL 20 WORKFLOWS READY FOR IMPORT**
