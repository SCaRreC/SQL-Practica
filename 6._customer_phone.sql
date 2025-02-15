-- 6. customer_phone for each call_id and client.

with found_phone as (
  select
    distinct(calls_ivr_id),
    customer_phone
  from `keepcoding.ivr_detail`
  where customer_phone != 'UNKNOWN'
)

select
  distinct(det.calls_ivr_id),
  coalesce(fou.customer_phone, 'UNKNOWN') as customer_phone
from `keepcoding.ivr_detail` det
left join found_phone fou
on det.calls_ivr_id = fou.calls_ivr_id
order by calls_ivr_id
;
