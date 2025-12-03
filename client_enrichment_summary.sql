create view public.client_enrichment_summary as
select
  c.id as client_id,
  c.client_name,
  c.status as client_status,
  count(distinct p.id) as total_leads,
  count(
    distinct case
      when p.status = 'live'::text then p.id
      else null::uuid
    end
  ) as graduated_leads,
  count(
    distinct case
      when p.enrichment_status = 'completed'::text then p.id
      else null::uuid
    end
  ) as enriched_leads,
  count(distinct er.id) as total_enrichments,
  sum(er.credits_consumed) as total_credits_consumed,
  max(p.last_enriched_at) as last_enrichment_date
from
  clients c
  left join people p on c.id = p.client_id
  left join enrichment_runs er on c.id = er.client_id
  and er.status = 'completed'::text
group by
  c.id,
  c.client_name,
  c.status;
