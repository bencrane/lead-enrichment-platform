create table public.b2b_ad_details (
  id uuid not null default extensions.uuid_generate_v4 (),
  company_id uuid null,
  client_id uuid null,
  b2b_ad_id uuid null,
  ads_type character varying(100) null,
  content text null,
  heading text null,
  sub_heading text null,
  image_url text null,
  cta jsonb null,
  video jsonb null,
  total_impressions bigint null,
  country_impressions jsonb null,
  targeting_language character varying(100) null,
  targeting_location character varying(255) null,
  availability_duration character varying(100) null,
  organization jsonb null,
  paying_entity text null,
  ad_url text null,
  credits_consumed numeric(10, 2) null,
  created_at timestamp with time zone null default now(),
  constraint b2b_ad_details_pkey primary key (id),
  constraint b2b_ad_details_b2b_ad_id_fkey foreign KEY (b2b_ad_id) references b2b_ads (id) on delete set null,
  constraint b2b_ad_details_client_id_fkey foreign KEY (client_id) references clients (id) on delete CASCADE,
  constraint b2b_ad_details_company_id_fkey foreign KEY (company_id) references companies (id) on delete set null
) TABLESPACE pg_default;

create index IF not exists idx_b2b_ad_details_company on public.b2b_ad_details using btree (company_id) TABLESPACE pg_default;

create index IF not exists idx_b2b_ad_details_type on public.b2b_ad_details using btree (ads_type) TABLESPACE pg_default;
