-- 7._billing_account_id for each call_id and client.

with known_bill_acc as (
  select distinct
    calls_ivr_id,
    billing_account_id
  from `keepcoding.ivr_detail`
  where billing_account_id != 'UNKNOWN'
)
select 
  det.calls_ivr_id,
  coalesce(kno.billing_account_id, 'UNKNOWN') as billing_account_id,
  --lag(det.calls_ivr_id)
  --  over(partition by cast(det.calls_ivr_id as string) order by det.calls_ivr_id ) as previous_call,
from `keepcoding.ivr_detail` det 
left
join known_bill_acc kno 
on det.calls_ivr_id = kno.calls_ivr_id
group by 1, 2
order by 1
;


-- Hasta aquí sería el código de la query. He notado que algunos registros de llamada tienen dos billing_account_ids para una mismo call_id y cliente, pero supongo que no influirá en la union de códigos del ejercicio 12.
-- La manera de proceder dependería de lo que nos digan otros departamentos sobre cómo tratar esos duplicados.
select
    calls_ivr_id,
    billing_account_id
  from CTE
  where previous_call is not null
  ;
 
  select
    *
  from `keepcoding.ivr_detail`
  where cast(calls_ivr_id as string) = '1670777277.2964211'--'1670770337.33448' 
  ;
  -- Hay 357 registros con dos billing_account_ids diferentes.
