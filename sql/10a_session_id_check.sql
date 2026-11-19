SELECT
  COUNT(*) AS funnel_events,
  COUNTIF((SELECT value.int_value
           FROM UNNEST(event_params)
           WHERE key = 'ga_session_id') IS NULL) AS no_session_id
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout',
                     'add_payment_info', 'purchase');