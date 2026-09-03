-- ============================================================
-- DELIVERY & LOGISTICS
-- Olist Brazilian E-Commerce — SQL Portfolio Project
-- ============================================================

-- ------------------------------------------------------------
-- 0. ORDER STATUS OVERVIEW
-- ------------------------------------------------------------

-- Distribution of order statuses across all orders
SELECT order_status, COUNT(*) AS count
FROM orders
GROUP BY order_status
ORDER BY COUNT(*) DESC;


-- ------------------------------------------------------------
-- 1. CANCELLATION DEEP-DIVE
-- ------------------------------------------------------------

-- 1a. Total cancelled orders
SELECT COUNT(*) 
FROM orders 
WHERE order_status = "canceled";
-- 625


-- 1b. Cancelled orders with no order_items rows (no seller_id possible)
SELECT *
FROM orders o
LEFT JOIN order_items oi ON oi.order_id = o.order_id
WHERE oi.order_id IS NULL 
    AND o.order_status = "canceled";
-- 164 (26.2% of 625) — excluded from seller-level analysis below


-- 1c. % of cancelled orders (with order_items) that are multi-seller
SELECT
    SUM(CASE WHEN seller_count > 1 THEN 1 ELSE 0 END) AS multi_seller_cancelled,
    COUNT(*) AS total_cancelled,
    SUM(CASE WHEN seller_count > 1 THEN 1 ELSE 0 END) / COUNT(*) AS pct_multi_seller_cancelled
FROM (
    SELECT oi.order_id, COUNT(DISTINCT oi.seller_id) AS seller_count
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_status = "canceled"
    GROUP BY oi.order_id
) AS seller_counts;
-- 0 out of 461 (0%)


-- 1d. Seller-level cancellation rate
-- Restricted to single-seller orders, sellers with >= 35 total orders
SELECT 
    cancelled.seller_id,
    cancelled.cancelled_order_count,
    totals.total_orders,
    100 * (cancelled.cancelled_order_count / totals.total_orders) AS cancellation_rate
FROM (
    SELECT oit.seller_id, COUNT(DISTINCT oit.order_id) AS cancelled_order_count
    FROM (
        SELECT oi.order_id
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        WHERE o.order_status = "canceled"
        GROUP BY oi.order_id
        HAVING COUNT(DISTINCT oi.seller_id) = 1
    ) single_seller_orders
    JOIN order_items oit ON oit.order_id = single_seller_orders.order_id
    GROUP BY oit.seller_id
) AS cancelled
LEFT JOIN (
    SELECT oit.seller_id, COUNT(DISTINCT oit.order_id) AS total_orders
    FROM (
        SELECT oi.order_id
        FROM order_items oi
        JOIN orders o ON o.order_id = oi.order_id
        GROUP BY oi.order_id
        HAVING COUNT(DISTINCT oi.seller_id) = 1
    ) single_seller_orders
    JOIN order_items oit ON oit.order_id = single_seller_orders.order_id
    GROUP BY oit.seller_id
) AS totals ON cancelled.seller_id = totals.seller_id
HAVING total_orders >= 35
ORDER BY cancellation_rate DESC
LIMIT 10;


-- 1e. Cancellation rate by total-payment quintile (1 = cheapest, 5 = priciest)
-- Bucket ranges first, then cancellation rate per bucket
SELECT MAX(sum_payment_value), MIN(sum_payment_value), bucket
FROM (
    SELECT order_id, SUM(payment_value) AS sum_payment_value, 
           NTILE(5) OVER (ORDER BY SUM(payment_value)) AS bucket
    FROM order_payments
    GROUP BY order_id
) order_payments
GROUP BY bucket;

SELECT bucket, 
       (SUM(CASE WHEN o.order_status = 'canceled' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS cancellation_rate
FROM (
    SELECT order_id, SUM(payment_value) AS sum_payment_value, 
           NTILE(5) OVER (ORDER BY SUM(payment_value)) AS bucket
    FROM order_payments
    GROUP BY order_id
) sub
JOIN orders o ON o.order_id = sub.order_id
GROUP BY bucket;


-- ------------------------------------------------------------
-- 2. DELIVERY TIMING
-- ------------------------------------------------------------

-- 2a. Average gap between estimated and actual delivery date
-- (positive = delivered early, negative = late)
SELECT ROUND(AVG(total_days), 2) AS avg_days_estimate_vs_actual
FROM (
    SELECT 
        order_id, 
        order_estimated_delivery_date, 
        order_delivered_customer_date, 
        TIMESTAMPDIFF(DAY, order_delivered_customer_date, order_estimated_delivery_date) AS total_days
    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
) sub;


-- 2b. Average time from purchase to delivery
SELECT ROUND(AVG(total_days), 2) AS avg_purchase_to_delivery_days
FROM (
    SELECT 
        order_id, 
        order_purchase_timestamp, 
        order_delivered_customer_date, 
        TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS total_days
    FROM orders
    WHERE order_delivered_customer_date IS NOT NULL
) sub;


-- ------------------------------------------------------------
-- 3. SELLER DELIVERY PERFORMANCE
-- ------------------------------------------------------------

-- Top 10 sellers by delivery speed vs. estimate
-- Single-seller orders only, sellers with > 40 orders
SELECT 
    seller_id, 
    AVG(total_days) AS avg_days_estimate_vs_actual, 
    COUNT(order_id) AS total_orders
FROM (
    SELECT 
        oi.order_id, 
        MAX(oi.seller_id) AS seller_id, 
        o.order_estimated_delivery_date, 
        o.order_delivered_customer_date, 
        TIMESTAMPDIFF(DAY, o.order_delivered_customer_date, o.order_estimated_delivery_date) AS total_days
    FROM order_items oi
    JOIN orders o ON o.order_id = oi.order_id
    WHERE o.order_delivered_customer_date IS NOT NULL
    GROUP BY oi.order_id
    HAVING COUNT(DISTINCT oi.seller_id) = 1
) sub
GROUP BY seller_id
HAVING COUNT(order_id) > 40
ORDER BY avg_days_estimate_vs_actual ASC
LIMIT 10;


-- ------------------------------------------------------------
-- 4. FREIGHT COST vs WEIGHT (distance-controlled)
-- ------------------------------------------------------------

-- 4a. Weight buckets (light / medium / heavy) — row counts
SELECT 
    CASE 
        WHEN product_weight < 500 THEN 'light'
        WHEN product_weight < 1500 THEN 'medium'
        ELSE 'heavy'
    END AS weight_bucket,
    COUNT(*) AS row_count
FROM products
GROUP BY weight_bucket;


-- 4b. Freight cost by weight bucket, same-state vs different-state shipping
SELECT 
    weight_bucket, 
    same_state_flag,
    COUNT(*) AS number_of_orders, 
    AVG(freight_value) AS avg_freight_value, 
    AVG(price) AS avg_price, 
    AVG(freight_value / price) AS avg_freight_to_price_ratio
FROM (
    SELECT 
        oi.order_id, oi.seller_id, oi.freight_value, oi.price, 
        c.customer_state, p.product_category_name, p.product_weight, s.seller_state,
        CASE 
            WHEN product_weight < 500 THEN 'light'
            WHEN product_weight < 1500 THEN 'medium'
            ELSE 'heavy'
        END AS weight_bucket, 
        CASE WHEN customer_state = seller_state THEN 1 ELSE 0 END AS same_state_flag
    FROM order_items oi
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN customers c ON o.customer_id = c.customer_id
    LEFT JOIN products p ON p.product_id = oi.product_id
    LEFT JOIN sellers s ON s.seller_id = oi.seller_id
    WHERE price > 0
) sub
GROUP BY weight_bucket, same_state_flag
ORDER BY weight_bucket;