create table public.companies (
  id uuid not null default gen_random_uuid (),
  name text null,
  domain text null,
  linkedin_url text null,
  linkedin_id text null,
  employee_count integer null,
  revenue bigint null,
  founded_year character varying(10) null,
  industry text null,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  enrichment_count integer null default 0,
  last_enriched_at timestamp with time zone null,
  constraint companies_pkey primary key (id)
) TABLESPACE pg_default;

create unique INDEX IF not exists idx_companies_domain on public.companies using btree (domain) TABLESPACE pg_default
where
  (domain is not null);

create unique INDEX IF not exists idx_companies_linkedin_id on public.companies using btree (linkedin_id) TABLESPACE pg_default
where
  (linkedin_id is not null);

create index IF not exists idx_companies_name on public.companies using btree (name) TABLESPACE pg_default;

create index IF not exists idx_companies_linkedin_url on public.companies using btree (linkedin_url) TABLESPACE pg_default;

create trigger update_companies_updated_at BEFORE
update on companies for EACH row
execute FUNCTION update_updated_at_column ();
