select event_date, count(*) as views
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
where event_name='view_item_list'
Group by event_date
order by event_date;