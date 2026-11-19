select geo.country as country,
count(distinct user_pseudo_id) as users
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
group by country
order by users desc;