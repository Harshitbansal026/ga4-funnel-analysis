select 
count(*) as total_events,
count( DISTINCT user_pseudo_id) as total_users,
count( DISTINCT event_date) as total_days
from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`;