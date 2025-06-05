/* Scripts are using Google Cloud Database */

-- v_provider_metrics

Select 
  a.npi
  , p.provider_name
  , p.zip
  , z.city
  , z.state
  , z.zip_1
  , a.cpt
  , a.cpt_name
  , count(*) service_count  -- Cpt service count
  , count(distinct a.patient_id) unique_patients  -- Unique patients seen
  , sum(a.adverse_event_ind) total_adverse_events -- detect outcomes metrics
  , sum(a.paid_amount) total_cost -- Total aggregate cost by CPT
  , sum(a.paid_amount)/count(a.npi) avg_cost_per_service  -- Avg the cost per cpt service
  , sum(a.adverse_event_ind)/count(a.npi) avg_adverse_event_per_service -- Frequency of adverse events
From icon_health_demo.stg_encounter_details a
Left Join icon_health_demo.stg_providers p
  on a.npi = p.npi
Left Join icon_health_demo.ref_zip z
  on p.zip = z.zip
Group by all
;


-------------------------------------------------------
-- v_patient_referrals (bonus used for referral dashboard)

-- Table shows patient referrals and all referral locations in their city
  -- Rank referrals based on quality, cost, volume (availabiltiy)
Select 
  r.*
  , z.city
  , p.cpt_name
  , p.npi
  , p.provider_name
  , p.avg_adverse_event_per_service
  , p.avg_cost_per_service
  , p.service_count as cpt_services
  , pp.total_services
  , case when r.zip = p.zip then 'Yes' else 'No' end as exact_zip
  , case when n.in_network_npis like concat('%',p.npi,',%') then 'Yes' else 'No' end as NPI_In_Network
  , ROW_NUMBER() OVER(PARTITION BY r.patient_id, r.procedure, z.city
      ORDER BY p.avg_adverse_event_per_service asc, p.avg_cost_per_service asc, pp.total_services asc)
      as referral_rank  -- High quality, lower cost, volume / availability
From `icon_health_demo.stg_referrals` r
left join `icon_health_demo.ref_zip` z    -- Add referrals for same city even if zip isn't exat
  on r.zip = z.zip
Left Join `icon_health_demo.v_provider_metrics` p   -- Referral criteria based on performance
  on z.zip_1 = p.zip_1
  and r.procedure = p.cpt
LEFT JOIN `icon_health_demo.stg_employer_in_network` n
  on r.employer_id = n.employer_id
LEFT JOIN (
  -- Total_service volume to extrapolate availability
  Select npi, count(*) total_services
  FROM icon_health_demo.stg_encounter_details
  GROUP BY 1
  ) pp
  on p.npi = pp.npi
GROUP BY all
;


-------------------------------------------------------
-- v_patient_all

Select distinct
  a.patient_id
  , a.gender
  , a.birth_date
  , date_diff(current_date(),birth_date,YEAR) as age
  , p.zip
  , z.zip_1
  , z.zip_2
  , z.city
from icon_health_demo.stg_patients a
left join `icon_health_demo.stg_encounter_details` e
  on a.patient_id = e.patient_id
left join `icon_health_demo.stg_providers` p
  on e.npi = p.npi
Left Join icon_health_demo.ref_zip z
  on z.zip = p.zip

UNION Distinct

Select
  patient_id
  , gender
  , birth_date
  , date_diff(current_date(),birth_date,YEAR) as age
  , r.zip
  , z.zip_1
  , z.zip_2
  , z.city
From icon_health_demo.stg_referrals r
Left Join icon_health_demo.ref_zip z
  on z.zip = r.zip
;