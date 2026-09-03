-- ============================================================
-- GROSS MERCHANDISE VALUE (GMV) & ORDER VOLUME
-- Olist Brazilian E-Commerce — SQL Portfolio Project
-- ============================================================

-- ------------------------------------------------------------
-- 0. HEADLINE METRICS (ALL-TIME, UNFILTERED)
-- ------------------------------------------------------------

-- 0a. Total GMV across the entire dataset
SELECT SUM(payment_value) AS total_gmv
FROM ORDER_PAYMENTS;

-- 0b. Total number of orders across the entire dataset
SELECT COUNT(order_id) AS total_orders
FROM ORDERS;

-- 0c. Average order value across the entire dataset
SELECT AVG(sum_payment_value) as average_order_value
FROM (
SELECT order_id, SUM(payment_value) AS sum_payment_value
FROM ORDER_PAYMENTS
GROUP BY order_id
) sub
;


-- ------------------------------------------------------------
-- 1. ORDER STATUS & DATA COVERAGE
-- ------------------------------------------------------------

-- 1a. Distinct order statuses present in the dataset
SELECT DISTINCT(order_status) FROM ORDERS;

-- 1b. Total orders and total GMV by order status — basis for the
-- decision to exclude cancelled/unavailable orders elsewhere
SELECT o.order_status as order_status, SUM(s.sum_payment_value) as total_gmv, AVG(s.sum_payment_value) as average_order_value, COUNT(*) as total_orders
FROM ORDERS o
LEFT JOIN (SELECT order_id, SUM(payment_value) AS sum_payment_value FROM order_payments GROUP BY order_id) s ON s.order_id = o.order_id
GROUP BY o.order_status;

-- 1c. Maximum order date in the dataset
SELECT MAX(order_purchase_timestamp)
FROM ORDERS;

-- 1d. Minimum order date in the dataset
SELECT MIN(order_purchase_timestamp)
FROM ORDERS;

-- 1e. Net GMV, net orders, and average order value by year (full
-- calendar years — 2016 minimal, 2018 partial, neither used for YoY)
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y') AS order_year, 
    COUNT(*) AS net_orders,
    SUM(s.sum_payment_value) AS net_gmv,
    AVG(s.sum_payment_value) AS average_order_value
FROM ORDERS o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS sum_payment_value 
    FROM order_payments 
    GROUP BY order_id
) s ON s.order_id = o.order_id
WHERE o.order_purchase_timestamp BETWEEN "2016-01-01" AND "2020-12-31"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_year
ORDER BY order_year;

-- 1f. Net orders by month, 2017-2018 — confirms 2018 is a partial year,
-- hence the Jan-Aug restriction used throughout the sections below
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month, COUNT(*) AS net_orders
FROM ORDERS
WHERE order_purchase_timestamp BETWEEN "2017-01-01" AND "2018-12-31"
  AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;


-- ------------------------------------------------------------
-- 2. GMV & ORDER VOLUME TREND (2017 vs 2018, Jan-Aug)
-- ------------------------------------------------------------
-- Restricted to Jan-Aug both years — complete 2017 data compared
-- against partial 2018 data over equal, like-for-like windows.

-- 2a. Net GMV, net orders, and average order value — 2017 vs 2018
SELECT 
    DATE_FORMAT(o.order_purchase_timestamp, '%Y') AS order_year, 
    SUM(s.sum_payment_value) AS net_gmv, 
    COUNT(*) AS net_orders,
    AVG(s.sum_payment_value) AS average_order_value
FROM ORDERS o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS sum_payment_value 
    FROM order_payments 
    GROUP BY order_id
) s ON s.order_id = o.order_id
WHERE (o.order_purchase_timestamp >= "2017-01-01" AND o.order_purchase_timestamp < "2017-09-01"
       OR o.order_purchase_timestamp >= "2018-01-01" AND o.order_purchase_timestamp < "2018-09-01")
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_year
ORDER BY order_year;

-- 2b. Monthly net GMV, 2017 comparative months (Jan-Aug)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
       SUM(s.sum_payment_value) AS net_gmv
FROM ORDERS o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS sum_payment_value 
    FROM order_payments 
    GROUP BY order_id
) s ON s.order_id = o.order_id
WHERE o.order_purchase_timestamp >= "2017-01-01" AND o.order_purchase_timestamp < "2017-09-01"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

-- 2c. Monthly net orders, 2017 comparative months (Jan-Aug)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
       COUNT(*) AS net_orders
FROM ORDERS o
WHERE o.order_purchase_timestamp >= "2017-01-01" AND o.order_purchase_timestamp < "2017-09-01"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

-- 2d. Monthly average order value, 2017 comparative months (Jan-Aug)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
       AVG(s.sum_payment_value) AS average_order_value
FROM ORDERS o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS sum_payment_value 
    FROM order_payments 
    GROUP BY order_id
) s ON s.order_id = o.order_id
WHERE o.order_purchase_timestamp >= "2017-01-01" AND o.order_purchase_timestamp < "2017-09-01"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

-- 2e. Monthly net GMV, 2018 comparative months (Jan-Aug)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
       SUM(s.sum_payment_value) AS net_gmv
FROM ORDERS o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS sum_payment_value 
    FROM order_payments 
    GROUP BY order_id
) s ON s.order_id = o.order_id
WHERE o.order_purchase_timestamp >= "2018-01-01" AND o.order_purchase_timestamp < "2018-09-01"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

-- 2f. Monthly net orders, 2018 comparative months (Jan-Aug)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
       COUNT(*) AS net_orders
FROM ORDERS o
WHERE o.order_purchase_timestamp >= "2018-01-01" AND o.order_purchase_timestamp < "2018-09-01"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

-- 2g. Monthly average order value, 2018 comparative months (Jan-Aug)
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
       AVG(s.sum_payment_value) AS average_order_value
FROM ORDERS o
LEFT JOIN (
    SELECT order_id, SUM(payment_value) AS sum_payment_value 
    FROM order_payments 
    GROUP BY order_id
) s ON s.order_id = o.order_id
WHERE o.order_purchase_timestamp >= "2018-01-01" AND o.order_purchase_timestamp < "2018-09-01"
  AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month;

-- 2h. Month-on-month order volume growth (CTE + LAG window function)
-- LAG offset of 8 aligns each 2018 month with its 2017 counterpart
WITH monthly_data AS (
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS order_month, COUNT(*) as net_orders
FROM ORDERS
WHERE (
    order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
    OR
    order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01"
)
AND order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_month
ORDER BY order_month
), filtered_monthly_data AS (
SELECT 
    order_month,
    net_orders,
    LAG(net_orders, 8) OVER (ORDER BY order_month) AS net_orders_previous_year
FROM monthly_data
)
SELECT order_month, net_orders, net_orders_previous_year, ((net_orders - net_orders_previous_year)/(net_orders_previous_year))*100 AS orders_growth_percentage
FROM filtered_monthly_data
WHERE order_month LIKE '2018%';

-- 2i. Month-on-month GMV growth (CTE + LAG window function)
WITH monthly_data AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
           SUM(s.sum_payment_value) AS net_gmv
    FROM ORDERS o
    LEFT JOIN (
        SELECT order_id, SUM(payment_value) AS sum_payment_value 
        FROM order_payments 
        GROUP BY order_id
    ) s ON s.order_id = o.order_id
    WHERE (o.order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
           OR o.order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01")
      AND o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY order_month
    ORDER BY order_month
), filtered_monthly_data AS (
    SELECT 
        order_month,
        net_gmv,
        LAG(net_gmv, 8) OVER (ORDER BY order_month) AS net_gmv_previous_year
    FROM monthly_data
)
SELECT order_month, net_gmv, net_gmv_previous_year, 
       ((net_gmv - net_gmv_previous_year)/(net_gmv_previous_year))*100 AS gmv_growth_percentage
FROM filtered_monthly_data
WHERE order_month LIKE '2018%';

-- 2j. Month-on-month average order value growth (CTE + LAG window function)
WITH monthly_data AS (
    SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month, 
           AVG(s.sum_payment_value) AS average_order_value
    FROM ORDERS o
    LEFT JOIN (
        SELECT order_id, SUM(payment_value) AS sum_payment_value 
        FROM order_payments 
        GROUP BY order_id
    ) s ON s.order_id = o.order_id
    WHERE (o.order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
           OR o.order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01")
      AND o.order_status NOT IN ('canceled', 'unavailable')
    GROUP BY order_month
    ORDER BY order_month
), filtered_monthly_data AS (
    SELECT 
        order_month,
        average_order_value,
        LAG(average_order_value, 8) OVER (ORDER BY order_month) AS average_order_value_previous_year
    FROM monthly_data
)
SELECT order_month, average_order_value, average_order_value_previous_year, 
       ((average_order_value - average_order_value_previous_year)/(average_order_value_previous_year))*100 AS aov_growth_percentage
FROM filtered_monthly_data
WHERE order_month LIKE '2018%';


-- ------------------------------------------------------------
-- 3. PRODUCT CATEGORY-LEVEL ANALYSIS (2017 vs 2018, Jan-Aug)
-- ------------------------------------------------------------

-- 3a. Top 10 categories by net order count, 2017 comparative months
SELECT product_category_name_english, COUNT(*) as net_orders
FROM (
    SELECT oi.order_id, p.product_category_name, c.product_category_name_english, o.order_purchase_timestamp
    FROM ORDER_ITEMS oi
    LEFT JOIN PRODUCTS p ON oi.product_id = p.product_id
    LEFT JOIN CATEGORY_NAMES c on p.product_category_name = c.product_category_name
    LEFT JOIN ORDERS o on oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
    AND o.order_status NOT IN ('canceled', 'unavailable')
) sub
GROUP BY product_category_name_english
ORDER BY net_orders DESC
LIMIT 10;

-- 3b. Top 10 categories by net order count, 2018 comparative months
SELECT COUNT(*) as net_orders, product_category_name_english
FROM (
    SELECT oi.order_id, p.product_category_name, c.product_category_name_english, o.order_purchase_timestamp
    FROM ORDER_ITEMS oi
    LEFT JOIN PRODUCTS p ON oi.product_id = p.product_id
    LEFT JOIN CATEGORY_NAMES c on p.product_category_name = c.product_category_name
    LEFT JOIN ORDERS o on oi.order_id = o.order_id
    WHERE o.order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01"
    AND o.order_status NOT IN ('canceled', 'unavailable')
) sub
GROUP BY product_category_name_english
ORDER BY net_orders DESC
LIMIT 10;

-- 3c. Category growth 2017 -> 2018, by net order count (CTE + LAG,
-- partitioned by category). Floor of 75 on the 2017 base — tested
-- multiple thresholds, top-10 ranking stabilizes at 75.
with yearly_categorical_data AS (
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y') AS order_year, c.product_category_name_english, COUNT(*) AS net_orders
FROM ORDER_ITEMS oi
LEFT JOIN PRODUCTS p ON oi.product_id = p.product_id
LEFT JOIN CATEGORY_NAMES c on p.product_category_name = c.product_category_name
LEFT JOIN ORDERS o on oi.order_id = o.order_id
WHERE (o.order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
           OR o.order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01")
AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_year, c.product_category_name_english
), yearly_categorical_data_with_lag AS (
    SELECT 
		order_year,
        net_orders,
        product_category_name_english,
        LAG(net_orders, 1) OVER (PARTITION BY product_category_name_english ORDER BY order_year) AS net_orders_previous_year
    FROM yearly_categorical_data
    )
SELECT order_year, product_category_name_english, net_orders, net_orders_previous_year, ((net_orders - net_orders_previous_year)/net_orders_previous_year)*100 AS growth_percentage
FROM yearly_categorical_data_with_lag
WHERE order_year = 2018
  AND net_orders_previous_year >= 75
ORDER BY growth_percentage DESC
LIMIT 10;


-- ------------------------------------------------------------
-- 4. STATE-LEVEL ANALYSIS (2017 vs 2018, Jan-Aug)
-- ------------------------------------------------------------

-- 4a. States by net order count, 2017 comparative months
SELECT COUNT(*) AS net_orders, c.customer_state
FROM ORDERS o
LEFT JOIN CUSTOMERS c ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_state 
ORDER BY net_orders DESC;

-- 4b. States by net order count, 2018 comparative months
SELECT COUNT(*) AS net_orders, c.customer_state
FROM ORDERS o
LEFT JOIN CUSTOMERS c ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01"
AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_state 
ORDER BY net_orders DESC;

-- 4c. State growth 2017 -> 2018, by net order count (CTE + LAG,
-- partitioned by state)
with yearly_categorical_data AS (
SELECT DATE_FORMAT(o.order_purchase_timestamp, '%Y') AS order_year, c.customer_state, COUNT(*) AS net_orders
FROM ORDERS o
LEFT JOIN CUSTOMERS c ON c.customer_id = o.customer_id
WHERE (o.order_purchase_timestamp BETWEEN "2017-01-01" AND "2017-09-01"
           OR o.order_purchase_timestamp BETWEEN "2018-01-01" AND "2018-09-01")
AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY order_year, c.customer_state
), yearly_categorical_data_with_lag AS (
    SELECT 
		order_year,
        net_orders,
        customer_state,
        LAG(net_orders, 1) OVER (PARTITION BY customer_state ORDER BY order_year) AS net_orders_previous_year
    FROM yearly_categorical_data
    )
SELECT order_year, customer_state, net_orders, net_orders_previous_year, ((net_orders - net_orders_previous_year)/net_orders_previous_year)*100 AS growth_percentage
FROM yearly_categorical_data_with_lag
WHERE order_year = 2018
ORDER BY growth_percentage DESC
LIMIT 10;