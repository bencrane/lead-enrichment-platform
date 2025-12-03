create table public.b2b_ads (
  id uuid not null default extensions.uuid_generate_v4 (),
  company_id uuid null,
  client_id uuid null,
  content text null,
  link text null,
  credits_consumed numeric(10, 2) null,
  search_query character varying(255) null,
  created_at timestamp with time zone null default now(),
  constraint b2b_ads_pkey primary key (id),
  constraint b2b_ads_client_id_fkey foreign KEY (client_id) references clients (id) on delete CASCADE,
  constraint b2b_ads_company_id_fkey foreign KEY (company_id) references companies (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_b2b_ads_company on public.b2b_ads using btree (company_id) TABLESPACE pg_default;

create index IF not exists idx_b2b_ads_link on public.b2b_ads using btree (link) TABLESPACE pg_default;
