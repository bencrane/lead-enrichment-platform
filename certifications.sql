create table public.certifications (
  id uuid not null default extensions.uuid_generate_v4 (),
  person_id uuid not null,
  client_id uuid not null,
  enrichment_run_id uuid null,
  certification_name character varying(255) null,
  issuing_organization character varying(255) null,
  issue_date character varying(100) null,
  created_at timestamp with time zone null default now(),
  constraint certifications_pkey primary key (id),
  constraint certifications_client_id_fkey foreign KEY (client_id) references clients (id) on delete CASCADE,
  constraint certifications_enrichment_run_id_fkey foreign KEY (enrichment_run_id) references enrichment_runs (id) on delete set null,
  constraint certifications_person_id_fkey foreign KEY (person_id) references people (id) on delete CASCADE
) TABLESPACE pg_default;

create index IF not exists idx_certifications_person on public.certifications using btree (person_id) TABLESPACE pg_default;
