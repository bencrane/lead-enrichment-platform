create table public.clients (
  id uuid not null default gen_random_uuid (),
  client_name text not null,
  email text not null,
  status text not null default 'active'::text,
  tier text null default 'standard'::text,
  created_at timestamp with time zone null default now(),
  updated_at timestamp with time zone null default now(),
  total_leads_enriched integer null default 0,
  total_credits_consumed numeric(15, 2) null default 0,
  notes text null,
  constraint clients_pkey primary key (id),
  constraint clients_email_key unique (email)
) TABLESPACE pg_default;

create index IF not exists idx_clients_status on public.clients using btree (status) TABLESPACE pg_default;

create index IF not exists idx_clients_email on public.clients using btree (email) TABLESPACE pg_default;

create trigger update_clients_updated_at BEFORE
update on clients for EACH row
execute FUNCTION update_updated_at_column ();
