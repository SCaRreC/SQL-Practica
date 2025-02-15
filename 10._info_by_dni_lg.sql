-- 10. 'create info_by_dni_lg' field for each call_id and client when call passed through 'CUSTOMERINFOBYDNI.TX' .

with flagging as (
  select
    calls_ivr_id,
    step_name,
    step_result,
    case 
      when step_name = 'CUSTOMERINFOBYDNI.TX' and step_result = 'OK' then 1
      else 0
    end as new_flag
  from `keepcoding.ivr_detail`
)
select
  calls_ivr_id,
  max(new_flag) as info_by_dni_lg
from flagging
group by calls_ivr_id
;
