WITH
funnel_events AS (
  SELECT user_pseudo_id, event_name, event_timestamp
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name IN ('view_item', 'add_to_cart', 'begin_checkout',
                      'add_payment_info', 'purchase')
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
  WHERE e.event_name = 'add_payment_info'
    AND e.event_timestamp >= s3.t3
  GROUP BY e.user_pseudo_id
),
s5 AS (
  SELECT e.user_pseudo_id, MIN(e.event_timestamp) AS t5
  FROM s4
  JOIN funnel_events e
    ON e.user_pseudo_id = s4.user_pseudo_id
  WHERE e.event_name = 'purchase'
    AND e.event_timestamp >= s4.t4
  GROUP BY e.user_pseudo_id
),
first_event AS (
  SELECT
    user_pseudo_id,
    device.category AS device,
    CASE
      WHEN traffic_source.medium IN ('<Other>', '(data deleted)') THEN 'Unknown'
      ELSE traffic_source.medium
    END AS medium,
    CASE
      WHEN user_first_touch_timestamp IS NULL THEN 'Unknown'
      WHEN user_first_touch_timestamp < UNIX_MICROS(TIMESTAMP '2020-11-01') THEN 'returning'
      ELSE 'new'
    END AS user_type,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) AS rn
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
),
user_funnel AS (
  SELECT
    f.device, f.medium, f.user_type,
    s1.user_pseudo_id AS u1,
    s2.user_pseudo_id AS u2,
    s3.user_pseudo_id AS u3,
    s4.user_pseudo_id AS u4,
    s5.user_pseudo_id AS u5
  FROM s1
  JOIN first_event f
    ON f.user_pseudo_id = s1.user_pseudo_id AND f.rn = 1
  LEFT JOIN s2 ON s2.user_pseudo_id = s1.user_pseudo_id
  LEFT JOIN s3 ON s3.user_pseudo_id = s1.user_pseudo_id
  LEFT JOIN s4 ON s4.user_pseudo_id = s1.user_pseudo_id
  LEFT JOIN s5 ON s5.user_pseudo_id = s1.user_pseudo_id
),
by_segment AS (
  SELECT 'device' AS split, device AS segment,
         COUNT(u1) AS viewed, COUNT(u2) AS carted, COUNT(u3) AS checked_out,
         COUNT(u4) AS paid, COUNT(u5) AS bought
  FROM user_funnel GROUP BY device
  UNION ALL
  SELECT 'medium', medium, COUNT(u1), COUNT(u2), COUNT(u3), COUNT(u4), COUNT(u5)
  FROM user_funnel GROUP BY medium
  UNION ALL
  SELECT 'user_type', user_type, COUNT(u1), COUNT(u2), COUNT(u3), COUNT(u4), COUNT(u5)
  FROM user_funnel GROUP BY user_type
)
SELECT
  split, segment, viewed, carted, checked_out, paid, bought,
  ROUND(100 * SAFE_DIVIDE(carted, viewed), 1)      AS cart_rate,
  ROUND(100 * SAFE_DIVIDE(checked_out, carted), 1) AS checkout_rate,
  ROUND(100 * SAFE_DIVIDE(paid, checked_out), 1)   AS payment_rate,
  ROUND(100 * SAFE_DIVIDE(bought, paid), 1)        AS purchase_rate,
  ROUND(100 * SAFE_DIVIDE(bought, viewed), 2)      AS conversion
FROM by_segment
ORDER BY split, viewed DESC;