WITH
first_purchase AS (
  SELECT
    user_pseudo_id,
    (SELECT value.int_value
     FROM UNNEST(event_params)
     WHERE key = 'ga_session_number') AS session_number,
    ROW_NUMBER() OVER (PARTITION BY user_pseudo_id ORDER BY event_timestamp) AS rn
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE event_name = 'purchase'
)
SELECT
  CASE
    WHEN session_number IS NULL THEN 'Unknown'
    WHEN session_number >= 5 THEN '5+'
    ELSE CAST(session_number AS STRING)
  END AS sessions_to_first_purchase,
  COUNT(*) AS buyers,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_buyers
FROM first_purchase
WHERE rn = 1
GROUP BY sessions_to_first_purchase
ORDER BY MIN(session_number);