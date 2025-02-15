--12. Create a table summarizing all the fields generated previously and adding them to a table with one unique registry per call.

-- Create a temp. table with all unique registries from ivr_detail
create table `keepcoding.temp_ivr_summary` as (
  with vdn_agr as (
    select
      calls_ivr_id,
      calls_vdn_label,
      case when upper(calls_vdn_label) like 'ATC%' then 'FRONT'
        when upper(calls_vdn_label) like 'TECH%' then 'TECH'
          when upper(calls_vdn_label) like 'ABSORPTION' then 'ABSORPTION'
          else 'RESTO'
      end as vdn_aggregation
    from `keepcoding.ivr_detail`
    group by all)

  select
    det.calls_ivr_id as ivr_id,
    calls_phone_number as phone_number,
    calls_ivr_result as ivr_result,
    vdn.vdn_aggregation,
    calls_start_date as start_date,
    calls_end_date as end_date,
    calls_total_duration as total_duration,
    calls_customer_segment as customer_segment,
    calls_ivr_language as ivr_language,
    calls_steps_module as steps_module,
    calls_module_aggregation as module_aggregation
    from `keepcoding.ivr_detail` det
    left
    join vdn_agr vdn
    on cast(det.calls_ivr_id as string) = cast(vdn.calls_ivr_id as string)
    group by all);

-- Create a second temp table with all the calculated fields

create table `keepcoding.temp_table` as (
  with documents as (
    with identification as (
      select
        calls_ivr_id,
        document_type,
        document_identification, 
        row_number() over(partition by cast(calls_ivr_id as string) order by document_type desc, document_identification desc) as row_num
      from `keepcoding.ivr_detail`
    ) 
  select 
    calls_ivr_id,
    document_type,
    document_identification,
  from `keepcoding.ivr_detail`
  qualify(ROW_NUMBER() OVER (PARTITION BY CAST(calls_ivr_id AS STRING) ORDER BY document_type, document_identification )) = 1
  order by calls_ivr_id
  ),
  cus_phone as (
    with found_phone as (
      select
        distinct calls_ivr_id,
        customer_phone
      from `keepcoding.ivr_detail`
      where customer_phone != 'UNKNOWN'
    )
  select
    distinct det.calls_ivr_id,
    coalesce(fou.customer_phone, 'UNKNOWN') as customer_phone
  from `keepcoding.ivr_detail` det
  left join found_phone fou
  on det.calls_ivr_id = fou.calls_ivr_id
  order by calls_ivr_id
  ),
-- Hasta aqui funciona
  bill_acc_id as (
    with known_bill_acc as (
      select distinct
        calls_ivr_id,
        document_identification
        billing_account_id
      from `keepcoding.ivr_detail`
      where billing_account_id != 'UNKNOWN'
      order by 1,2
    )
    select 
      det.calls_ivr_id,
      coalesce(kno.billing_account_id, 'UNKNOWN') as billing_account_id,
    from `keepcoding.ivr_detail` det 
    left
    join known_bill_acc kno 
    on det.calls_ivr_id = kno.calls_ivr_id
    group by 1, 2
  ),
  --Hasta aqui tb funciona pero crea 4 registros mas para billing accounts
  masiva as (
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
  ),
  by_phone as (
    with flagging as (
      select
        calls_ivr_id,
        step_name,
        step_result,
        case 
          when step_name = 'CUSTOMERINFOBYPHONE.TX' and step_result = 'OK' then 1
          else 0
        end as new_flag
      from `keepcoding.ivr_detail`
    )
    select
      calls_ivr_id,
      max(new_flag) as info_by_phone_lg
    from flagging
    group by calls_ivr_id
  ),
  by_dni as (
    with flagging_II as (
      select
        calls_ivr_id,
        step_name,
        step_result,
        case 
          when step_name = 'CUSTOMERINFOBYDNI.TX' and step_result = 'OK' then 1
          else 0
        end as new_flag_II
      from `keepcoding.ivr_detail`
    )
    select
      calls_ivr_id,
      max(new_flag_II) as info_by_dni_lg
    from flagging_II
    group by calls_ivr_id
  ),
  hours_call as (
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
  )
select
  doc.calls_ivr_id,
  doc.document_type,
  doc.document_identification,
  pho.customer_phone,
  bil.billing_account_id,
  mas.masiva_lg,
  byp.info_by_phone_lg,
  byd.info_by_dni_lg,
  hou.repeated_phone_24H,
  hou.cause_recall_phone_24H
from documents doc
left
join cus_phone pho
on doc.calls_ivr_id = pho.calls_ivr_id
left
join bill_acc_id bil 
on doc.calls_ivr_id = bil.calls_ivr_id
left
join masiva mas 
on doc.calls_ivr_id = mas.calls_ivr_id
left
join by_phone byp 
on doc.calls_ivr_id = byp.calls_ivr_id
left
join by_dni byd 
on doc.calls_ivr_id = byd.calls_ivr_id
left
join hours_call hou  
on doc.calls_ivr_id = hou.calls_ivr_id
);

-- Finally, merge those two temp. tables through calls_ivr_id.

create table `keepcoding.ivr_summary` as (
  select
    det.ivr_id,
    det.phone_number,
    det.ivr_result,
    det.vdn_aggregation,
    det.start_date,
    det.end_date,
    det.total_duration,
    det.customer_segment,
    det.ivr_language,
    det.steps_module,
    det.module_aggregation,
    tem.document_type,
    tem.document_identification,
    tem.customer_phone,
    tem.billing_account_id,
    tem.masiva_lg,
    tem.info_by_phone_lg,
    tem.info_by_dni_lg,
    tem.repeated_phone_24H,
    tem.cause_recall_phone_24H
  from `keepcoding.temp_ivr_summary` det
  left 
  join `keepcoding.temp_table` tem
  on det.ivr_id = tem.calls_ivr_id
);

-- I understand that I could have created ivr_summary table in other ways with the functions ALTER TABLE ADD or UPDATE TABLE but, 
-- as BigQuery free version does not allow data modifying options on its free version, I decided to do with by using temp. tables to see if it would work.