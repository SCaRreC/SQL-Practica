-- exercise 8. Generate campo masiva_lg for each call_id and client.

with flaging as (
  select
    calls_ivr_id,
    module_name,
    case
    when upper(module_name) = 'AVERIA_MASIVA' then 1
    else 0
    end as masiva
  from `keepcoding.ivr_detail`
)

select 
  det.calls_ivr_id,
  if (sum(fla.masiva) > 0, 1, 0) as masiva_lg
from `keepcoding.ivr_detail` det
left join flaging fla
on det.calls_ivr_id = fla.calls_ivr_id
group by 1
order by 1
;
