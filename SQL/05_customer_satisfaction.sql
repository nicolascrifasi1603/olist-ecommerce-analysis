-- ============================================================
-- CUSTOMER SATISFACTION
-- Olist Brazilian E-Commerce — SQL Portfolio Project
-- ============================================================


-- ------------------------------------------------------------
-- 0. REVIEW SCORE DISTRIBUTION
-- ------------------------------------------------------------

-- Distribution of order review scores
SELECT review_score, COUNT(*) AS count
FROM order_reviews
GROUP BY review_score
ORDER BY count DESC;


-- ------------------------------------------------------------
-- 1. PHOTO COUNT & DESCRIPTION LENGTH vs REVIEW SCORE
-- ------------------------------------------------------------

-- Restricted to single-item orders (COUNT(DISTINCT product_id) = 1) — avoids
-- averaging photo count / description length across different products
-- within the same order. Covers ~96% of orders.

-- 1a. Base join: single-item orders -> review score + product metrics
SELECT sub.order_id, p.product_id, ord.review_score, p.product_description_length, p.product_photos_qty
FROM (
    SELECT order_id, MAX(product_id) AS product_id, COUNT(DISTINCT product_id) AS distinct_products
    FROM order_items
    GROUP BY order_id
    HAVING distinct_products = 1
) sub
LEFT JOIN order_reviews ord ON ord.order_id = sub.order_id
LEFT JOIN products p ON p.product_id = sub.product_id;


-- 1b. Photo count buckets — row counts
SELECT 
    CASE 
        WHEN product_photos_qty < 2 THEN '1 photo'
        WHEN product_photos_qty < 3 THEN '2 photos'
        WHEN product_photos_qty < 5 THEN '3-4 photos'
        WHEN product_photos_qty < 7 THEN '5-6 photos'
        WHEN product_photos_qty < 21 THEN '7-20 photos'
    END AS photos_bucket,
    COUNT(*) AS row_count
FROM products
GROUP BY photos_bucket
ORDER BY photos_bucket;


-- 1c. Description length buckets (characters) — row counts
SELECT 
    CASE 
        WHEN product_description_length < 250 THEN '0-250'
        WHEN product_description_length < 400 THEN '250-400'
        WHEN product_description_length < 800 THEN '400-800'
        WHEN product_description_length < 1200 THEN '800-1200'
        WHEN product_description_length < 3992 THEN '1200-3992'
    END AS description_length_bucket,
    COUNT(*) AS row_count
FROM products
GROUP BY description_length_bucket
ORDER BY description_length_bucket;


-- 1d. Average review score by photo bucket
SELECT photos_bucket, AVG(review_score) AS average_review_score, COUNT(sub.order_id) AS number_of_orders
FROM (
    SELECT sub.order_id, p.product_id, ord.review_score, p.product_photos_qty, 
        CASE 
            WHEN product_photos_qty < 2 THEN '1 photo'
            WHEN product_photos_qty < 3 THEN '2 photos'
            WHEN product_photos_qty < 5 THEN '3-4 photos'
            WHEN product_photos_qty < 7 THEN '5-6 photos'
            WHEN product_photos_qty < 21 THEN '7-20 photos'
        END AS photos_bucket 
    FROM (
        SELECT order_id, MAX(product_id) AS product_id, COUNT(DISTINCT product_id) AS distinct_products
        FROM order_items
        GROUP BY order_id
        HAVING distinct_products = 1
    ) sub
    LEFT JOIN order_reviews ord ON ord.order_id = sub.order_id
    LEFT JOIN products p ON p.product_id = sub.product_id
) sub
GROUP BY photos_bucket
ORDER BY photos_bucket;


-- 1e. Average review score by description length bucket
SELECT description_length_bucket, AVG(review_score) AS average_review_score, COUNT(sub.order_id) AS number_of_orders
FROM (
    SELECT sub.order_id, p.product_id, ord.review_score, p.product_description_length, p.product_photos_qty, 
        CASE 
            WHEN product_description_length < 250 THEN '0-250'
            WHEN product_description_length < 400 THEN '250-400'
            WHEN product_description_length < 800 THEN '400-800'
            WHEN product_description_length < 1200 THEN '800-1200'
            WHEN product_description_length < 3992 THEN '1200-3992'
        END AS description_length_bucket
    FROM (
        SELECT order_id, MAX(product_id) AS product_id, COUNT(DISTINCT product_id) AS distinct_products
        FROM order_items
        GROUP BY order_id
        HAVING distinct_products = 1
    ) sub
    LEFT JOIN order_reviews ord ON ord.order_id = sub.order_id
    LEFT JOIN products p ON p.product_id = sub.product_id
) sub
GROUP BY description_length_bucket
ORDER BY description_length_bucket;


-- ------------------------------------------------------------
-- 2. LATE DELIVERY vs REVIEW SCORE
-- ------------------------------------------------------------

-- 2a. Diagnostic: order status breakdown for reviewed orders with no delivery
-- date. Used to refine the delivery_status buckets in 2b (originally 3 buckets,
-- expanded to 4 after this check surfaced canceled/unavailable orders mixed
-- into "not delivered").
SELECT COUNT(*), order_status
FROM (
    SELECT orw.order_id, orw.review_score, o.order_estimated_delivery_date, o.order_delivered_customer_date, o.order_status
    FROM order_reviews orw
    LEFT JOIN orders o ON orw.order_id = o.order_id
    WHERE o.order_delivered_customer_date IS NULL
) sub
GROUP BY order_status;


-- 2b. Average review score by delivery status
SELECT delivery_status, AVG(review_score) AS average_review_score, COUNT(order_id) AS total_orders
FROM (
    SELECT orw.order_id, orw.review_score, orw.review_comment_title, o.order_estimated_delivery_date, o.order_delivered_customer_date, o.order_status,
        CASE 
            WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 'late'
            WHEN order_delivered_customer_date IS NULL AND order_status IN ('canceled', 'unavailable') THEN 'canceled or unavailable orders'
            WHEN order_delivered_customer_date IS NULL AND order_status NOT IN ('canceled', 'unavailable') THEN 'still in transit'
            ELSE 'on_time'
        END AS delivery_status
    FROM order_reviews orw
    LEFT JOIN orders o ON orw.order_id = o.order_id
) sub
GROUP BY delivery_status
ORDER BY average_review_score;


-- ------------------------------------------------------------
-- 3. REPEAT PURCHASE ANALYSIS
-- ------------------------------------------------------------

-- Uses customer_unique_id throughout, not customer_id (which is generated
-- per-order and structurally can't repeat).

-- 3a. List of repeat customers (customer_unique_id with >1 order)
SELECT customer_unique_id, COUNT(customer_id) AS number_of_orders
FROM customers
GROUP BY customer_unique_id
HAVING number_of_orders > 1;


-- 3b. Total number of repeat customers
SELECT COUNT(*) AS number_of_repeat_customers
FROM (
    SELECT customer_unique_id, COUNT(customer_id) AS number_of_orders
    FROM customers
    GROUP BY customer_unique_id
    HAVING number_of_orders > 1
) sub;


-- 3c. Total number of unique customers
SELECT COUNT(DISTINCT customer_unique_id)
FROM customers;


-- 3d. Overall repeat purchase probability (%)
SELECT 100 * (
    SELECT COUNT(*) 
    FROM (
        SELECT customer_unique_id, COUNT(customer_id) AS number_of_orders
        FROM customers
        GROUP BY customer_unique_id
        HAVING number_of_orders > 1
    ) AS repeat_cust_list
)
/
(
    SELECT COUNT(DISTINCT customer_unique_id)
    FROM customers
) AS repeat_purchase_probability_percentage;


-- 3e. Total revenue generated by repeat customers (including their first order)
-- Supplementary metric — not part of the original business question, but a
-- natural extension once repeat customers were identified.
SELECT SUM(total_revenue)
FROM (
    SELECT c.customer_unique_id, 
           COUNT(DISTINCT o.order_id) AS total_orders, 
           SUM(op_agg.order_revenue) AS total_revenue
    FROM customers c
    JOIN orders o ON o.customer_id = c.customer_id
    JOIN (
        SELECT order_id, SUM(payment_value) AS order_revenue
        FROM order_payments
        GROUP BY order_id
    ) AS op_agg ON op_agg.order_id = o.order_id
    GROUP BY c.customer_unique_id
    HAVING total_orders > 1
) sub;


-- 3f. Repeat purchase probability by customer state
SELECT customer_state, (AVG(repeat_customer_check) * 100) AS repeat_customer_probability_percentage
FROM (
    SELECT customer_unique_id, customer_state,
        CASE 	
            WHEN number_of_orders > 1 THEN 1
            WHEN number_of_orders = 1 THEN 0
        END AS repeat_customer_check
    FROM (
        SELECT customer_unique_id, customer_state, COUNT(customer_id) AS number_of_orders
        FROM customers
        GROUP BY customer_unique_id, customer_state
    ) sub
) sub_2
GROUP BY customer_state
ORDER BY repeat_customer_probability_percentage DESC
LIMIT 10;


-- 3g. Repeat purchase probability by first-purchase product category
SELECT product_category_name_english, (AVG(repeat_customer_check) * 100) AS repeat_customer_probability_percentage
FROM (
    SELECT customer_unique_id, product_category_name_english,
        CASE 	
            WHEN number_of_orders > 1 THEN 1
            WHEN number_of_orders = 1 THEN 0
        END AS repeat_customer_check
    FROM (
        SELECT c.customer_id, c.customer_unique_id, cn.product_category_name_english, number_of_orders
        FROM customers c
        JOIN orders o ON c.customer_id = o.customer_id
        JOIN order_items oi ON o.order_id = oi.order_id
        JOIN products p ON p.product_id = oi.product_id
        JOIN category_names cn ON cn.product_category_name = p.product_category_name
        JOIN (
            SELECT c.customer_unique_id, MIN(o.order_purchase_timestamp) AS first_order_date
            FROM customers c
            JOIN orders o ON c.customer_id = o.customer_id
            GROUP BY c.customer_unique_id
        ) AS fo
            ON c.customer_unique_id = fo.customer_unique_id
            AND o.order_purchase_timestamp = fo.first_order_date
        JOIN (
            SELECT customer_unique_id, COUNT(customer_id) AS number_of_orders
            FROM customers
            GROUP BY customer_unique_id
        ) AS fo2
            ON fo2.customer_unique_id = fo.customer_unique_id
    ) sub
) sub2
GROUP BY product_category_name_english
ORDER BY repeat_customer_probability_percentage DESC
LIMIT 10;
