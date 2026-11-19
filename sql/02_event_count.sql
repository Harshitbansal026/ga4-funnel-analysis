select event_name, count(*) as number
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
 group by event_name
order by number desc;