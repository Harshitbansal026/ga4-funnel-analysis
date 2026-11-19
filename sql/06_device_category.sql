select device.category as category,
count(distinct user_pseudo_id) as users
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
group by category 
order by users desc;
