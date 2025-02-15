-- exercise 4. Create new field 'vdn_aggregation'

select
  calls_ivr_id,
  calls_vdn_label,
  case when upper(calls_vdn_label) like 'ATC%' then 'FRONT'
    when upper(calls_vdn_label) like 'TECH%' then 'TECH'
      when upper(calls_vdn_label) like 'ABSORPTION' then 'ABSORPTION'
      else 'RESTO'
  end as vdn_aggregation
from `keepcoding.ivr_detail`
group by all
;
