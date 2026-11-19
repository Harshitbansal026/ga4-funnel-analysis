select mediums, count(*) as users 
from (
  select user_pseudo_id, count(distinct traffic_source.medium)  as mediums
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  group by user_pseudo_id
)
group by mediums
order by mediums;