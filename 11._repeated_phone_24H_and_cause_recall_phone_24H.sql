-- 11. create a flag when the same phone number had received a call in the previous or posterior 24h.

with next_calls as (
  select distinct
    calls_ivr_id,
    calls_phone_number,
    calls_start_date,
    lag(calls_start_date)
      over(partition by calls_phone_number order by calls_start_date) as preceding_call,
    lag(calls_start_date)
      over(partition by calls_phone_number order by calls_start_date desc) as following_call
  from `keepcoding.ivr_detail`
  group by calls_ivr_id, 2, 3
  order by calls_start_date
)
select
  calls_ivr_id,
  case
    when timestamp_diff(calls_start_date, preceding_call,hour) <= 24 then 1
    else 0
  end as repeated_phone_24H,
  case
    when timestamp_diff(following_call, calls_start_date,hour) <= 24 then 1
    else 0
  end as cause_recall_phone_24H
from next_calls
;


