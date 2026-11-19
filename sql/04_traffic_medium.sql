select traffic_source.medium as medium,
count(distinct user_pseudo_id) as users
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
group by medium
order by users desc;