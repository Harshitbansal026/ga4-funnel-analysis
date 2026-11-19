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
s5 AS (
  SELECT e.user_pseudo_id, MIN(e.event_timestamp) AS t5
  FROM s4
  JOIN funnel_events e
    ON e.user_pseudo_id = s4.user_pseudo_id
  WHERE e.event_name = 'add_payment_info'
    AND e.event_timestamp >= s4.t4
  GROUP BY e.user_pseudo_id
),
s6 AS (
  SELECT e.user_pseudo_id, MIN(e.event_timestamp) AS t6
  FROM s5
  JOIN funnel_events e
    ON e.user_pseudo_id = s5.user_pseudo_id
  WHERE e.event_name = 'purchase'
    AND e.event_timestamp >= s5.t5
  GROUP BY e.user_pseudo_id
),
funnel AS (
  SELECT 1 AS step, 'view_item' AS step_name, COUNT(*) AS users FROM s1
  UNION ALL
  SELECT 2, 'add_to_cart', COUNT(*) FROM s2
  UNION ALL
  SELECT 3, 'begin_checkout', COUNT(*) FROM s3
  UNION ALL
  SELECT 4, 'add_shipping_info', COUNT(*) FROM s4
  UNION ALL
  SELECT 5, 'add_payment_info', COUNT(*) FROM s5
  UNION ALL
  SELECT 6, 'purchase', COUNT(*) FROM s6
)
SELECT
  step,
  step_name,
  users,
  ROUND(100 * users / LAG(users) OVER (ORDER BY step), 1)         AS step_rate,
  ROUND(100 * users / FIRST_VALUE(users) OVER (ORDER BY step), 1) AS pct_of_viewers
FROM funnel
ORDER BY step;




























