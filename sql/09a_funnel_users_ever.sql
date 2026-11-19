select countif(viewed) as s1_viewed,
countif(viewed and carted) as s2_carted,
countif(viewed and carted and checked_out) as s3_checked_out,
countif(viewed and carted and checked_out and shipped) as s4_shipped,
countif(viewed and carted and checked_out and shipped and paid) as s5_paid,
countif(viewed and carted and checked_out and shipped and paid and bought) as s6_bought
from (
  select user_pseudo_id,
  countif(event_name='view_item')>0 as viewed,
  countif(event_name='add_to_cart')>0 as carted,
  countif(event_name='begin_checkout')>0 as checked_out,
  countif(event_name='add_shipping_info')>0 as shipped,
  countif(event_name='add_payment_info')>0 as paid,
  countif(event_name='purchase')>0 as bought
  from `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  group by user_pseudo_id
);