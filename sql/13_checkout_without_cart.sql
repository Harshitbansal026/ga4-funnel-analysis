WITH
flags AS (
  SELECT
    user_pseudo_id,
    COUNTIF(event_name = 'view_item')      > 0 AS viewed,
    COUNTIF(event_name = 'add_to_cart')    > 0 AS carted,
    COUNTIF(event_name = 'begin_checkout') > 0 AS checked_out
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  GROUP BY user_pseudo_id
),
first_event AS (
  SELECT
    user_pseudo_id,
    CASE
      WHEN user_first_touch_timestamp IS NULL THEN 'Unknown'
      WHEN user_first_touch_timestamp < UNIX_MICROS(TIMESTAMP '2020-11-01') THEN 'returning'
      ELSE 'new'
    END AS user_type,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) AS rn
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
)
SELECT
  CASE
    WHEN fl.viewed AND fl.carted THEN 'viewed + carted'
    WHEN fl.carted               THEN 'carted, no view'
    WHEN fl.viewed               THEN 'viewed, no cart'
    ELSE 'neither'
  END AS path_before_checkout,
  COUNT(*) AS users,
  COUNTIF(f.user_type = 'returning') AS returning_users,
  ROUND(100 * COUNTIF(f.user_type = 'returning') / COUNT(*), 1) AS pct_returning
FROM flags fl
JOIN first_event f
  ON f.user_pseudo_id = fl.user_pseudo_id AND f.rn = 1
WHERE fl.checked_out
GROUP BY path_before_checkout
ORDER BY users DESC;