create table public.company_acquisitions (
  id uuid not null default extensions.uuid_generate_v4 (),
  company_id uuid not null,
  client_id uuid not null,
  enrichment_run_id uuid null,
  acquired_company_name character varying(255) null,
  acquisition_date timestamp with time zone null,
  description text null,
  source_url text null,
  created_at timestamp with time zone null default now(),
  constraint company_acquisitions_pkey primary key (id),
  constraint company_acquisitions_client_id_fkey foreign KEY (client_id) references clients (id) on delete CASCADE,
  constraint company_acquisitions_company_id_fkey foreign KEY (company_id) references companies (id) on delete CASCADE,
  constraint company_acquisitions_enrichment_run_id_fkey foreign KEY (enrichment_run_id) references enrichment_runs (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_company_acquisitions_company on public.company_acquisitions using btree (company_id) TABLESPACE pg_default;

create index IF not exists idx_company_acquisitions_date on public.company_acquisitions using btree (acquisition_date) TABLESPACE pg_default;
