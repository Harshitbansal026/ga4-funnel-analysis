WITH
funnel_events AS (
  SELECT user_pseudo_id, event_name, event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout',
                       'add_shipping_info', 'add_payment_info', 'purchase')
),
s1 AS (
  SELECT user_pseudo_id, MIN(event_timestamp) AS t1
  FROM funnel_events
  WHERE event_name = 'view_item'
  GROUP BY user_pseudo_id
),
s2 AS (
  SELECT e.user_pseudo_id, MIN(e.event_timestamp) AS t2
  FROM s1
  JOIN funnel_events e
    ON e.user_pseudo_id = s1.user_pseudo_id
  WHERE e.event_name = 'add_to_cart'
    AND e.event_timestamp >= s1.t1
  GROUP BY e.user_pseudo_id
),
s3 AS (
  SELECT e.user_pseudo_id, MIN(e.event_timestamp) AS t3
  FROM s2
  JOIN funnel_events e
    ON e.user_pseudo_id = s2.user_pseudo_id
  WHERE e.event_name = 'begin_checkout'
    AND e.event_timestamp >= s2.t2
  GROUP BY e.user_pseudo_id
),
s4 AS (
  SELECT e.user_pseudo_id, MIN(e.event_timestamp) AS t4
  FROM s3
  JOIN funnel_events e
    ON e.user_pseudo_id = s3.user_pseudo_id
  WHERE e.event_name = 'add_shipping_info'
    AND e.event_timestamp >= s3.t3
  GROUP BY e.user_pseudo_id
),
lost AS (
  SELECT s3.user_pseudo_id, s3.t3
  FROM s3
  LEFT JOIN s4
    ON s4.user_pseudo_id = s3.user_pseudo_id
  WHERE s4.user_pseudo_id IS NULL
),
gaps AS (
  SELECT
    l.user_pseudo_id,
    (l.t3 - MAX(e.event_timestamp)) / 1000000 AS gap_seconds
  FROM lost l
  JOIN funnel_events e
    ON e.user_pseudo_id = l.user_pseudo_id
  WHERE e.event_name = 'add_shipping_info'
    AND e.event_timestamp < l.t3
  GROUP BY l.user_pseudo_id, l.t3
)
SELECT COUNT(*) AS users, MIN(gap_seconds) AS min_gap, MAX(gap_seconds) AS max_gap
FROM gaps;




























