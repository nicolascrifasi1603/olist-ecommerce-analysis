-- =====================================================================
-- Olist E-Commerce: Data Loading
-- =====================================================================
-- Run 01_database_setup.sql first to create the schema.
--
-- File paths below are placeholders — replace /path/to/olist-dataset/
-- with wherever you've extracted the Kaggle CSVs locally.
--
-- local_infile must be enabled for LOAD DATA LOCAL INFILE to work.
-- =====================================================================

SHOW VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = 1;

-- ---------------------------------------------------------------------
-- Sellers
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_sellers_dataset.csv'
INTO TABLE sellers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------------
-- Customers
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------------
-- Geolocation
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_geolocation_dataset.csv'
INTO TABLE geolocation
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------------
-- Category name translations
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/product_category_name_translation.csv'
INTO TABLE CATEGORY_NAMES
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ---------------------------------------------------------------------
-- Products
-- Blank numeric fields in the CSV default to 0 in MySQL unless caught
-- here via NULLIF — indistinguishable from a genuine zero otherwise.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_category_name, @name_len, @desc_len, @photos_qty, @weight, @length, @height, @width)
SET
  product_name_length = NULLIF(@name_len, ''),
  product_description_length = NULLIF(@desc_len, ''),
  product_photos_qty = NULLIF(@photos_qty, ''),
  product_weight = NULLIF(@weight, ''),
  product_length_cm = NULLIF(@length, ''),
  product_height_cm = NULLIF(@height, ''),
  product_width_cm = NULLIF(@width, '');

-- ---------------------------------------------------------------------
-- Orders
-- Blank delivery/approval dates come through as '' in the CSV — loaded
-- via @variable + NULLIF so they become genuine NULLs instead of the
-- invalid 0000-00-00 placeholder MySQL would otherwise silently insert.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, order_status, order_purchase_timestamp, @approved, @carrier, @customer, order_estimated_delivery_date)
SET
  order_approved_at = NULLIF(@approved, ''),
  order_delivered_carrier_date = NULLIF(@carrier, ''),
  order_delivered_customer_date = NULLIF(@customer, '');

-- ---------------------------------------------------------------------
-- Order items
-- shipping_limit_date loaded via @variable + NULLIF to avoid blank
-- strings being converted into an invalid 0000-00-00 date.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_item, product_id, seller_id, @shipping_limit_date, price, freight_value)
SET
  shipping_limit_date = NULLIF(@shipping_limit_date, '');

-- ---------------------------------------------------------------------
-- Order payments
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_order_payments_dataset.csv'
INTO TABLE order_payments
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, payment_sequential, payment_type, payment_installments, payment_value);

-- ---------------------------------------------------------------------
-- Order reviews
-- Uses \r\n line endings (Windows-style), unlike the other files —
-- this file needed the explicit terminator, or the trailing \r got
-- glued onto review_answer_timestamp.
-- ---------------------------------------------------------------------
LOAD DATA LOCAL INFILE '/path/to/olist-dataset/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS
(review_id, order_id, review_score, review_comment_title, review_comment_message, @review_creation_date, @review_answer_timestamp)
SET
  review_creation_date = NULLIF(@review_creation_date, ''),
  review_answer_timestamp = NULLIF(@review_answer_timestamp, '');