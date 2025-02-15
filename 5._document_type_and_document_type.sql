
-- 5. create fields' document_type' and 'Document_identification' unique for each call_id


-- with this query, I check what's the difference regarding document type and document_identification in the regitries for one same call.
SELECT
  calls_ivr_id,
  document_type,
  document_identification,
  ROW_NUMBER() OVER (PARTITION BY CAST(calls_ivr_id AS STRING) order by document_type, document_identification) AS num_registries
FROM `keepcoding.ivr_detail`
order by calls_ivr_id, num_registries
;

-- it looks like the registries labeled with the highest value in num_registries have all the info needed, so I will select only those registries.
with identification as (
  SELECT
    calls_ivr_id,
    document_type,
    document_identification, 
    ROW_NUMBER() OVER (PARTITION BY CAST(calls_ivr_id AS STRING) ORDER BY document_type DESC, document_identification DESC) AS row_num
  FROM `keepcoding.ivr_detail`
) 
select 
  calls_ivr_id,
  document_type,
  document_identification,
from `keepcoding.ivr_detail`
qualify(ROW_NUMBER() OVER (PARTITION BY CAST(calls_ivr_id AS STRING) ORDER BY document_type, document_identification )) = 1
order by 1;

