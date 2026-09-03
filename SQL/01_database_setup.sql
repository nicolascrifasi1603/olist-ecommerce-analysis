-- =====================================================================
-- Olist E-Commerce Database Setup
-- =====================================================================
-- Tables are created first (no foreign keys yet),
-- then data is cleaned/inserted, and all foreign key constraints are
-- added last, once every referenced table actually exists.
-- =====================================================================

CREATE DATABASE olist_commerce;
USE olist_commerce;

-- ---------------------------------------------------------------------
-- 1. CREATE TABLES (no foreign keys yet — added in a later block once
--    every table this script creates actually exists)
-- ---------------------------------------------------------------------

CREATE TABLE SELLERS (
    seller_id varchar(50) PRIMARY KEY,
    seller_zip_code_prefix char(5),
    seller_city varchar(50),
    seller_state char(2)
);

CREATE TABLE CUSTOMERS (
    customer_id char(50) PRIMARY KEY,
    customer_unique_id char(50),
    customer_zip_code_prefix char(5),
    customer_city varchar(50),
    customer_state char(2)
);

-- Note: Geolocation table is not currently joined to any other table in this project's queries —
-- kept in case seller/customer distance analysis (via zip code prefix
-- lat/long) gets picked up later.
CREATE TABLE GEOLOCATION (
    geolocation_zip_code_prefix char(5),
    geolocation_lat DECIMAL(10,8),
    geolocation_lng DECIMAL(10,8),
    geolocation_city varchar(50),
    geolocation_state char(2)
);

-- English translations for product_category_name. Two rows are added
-- manually later (pc_gamer, food preparers) that don't exist in the
-- original Kaggle source file.
CREATE TABLE CATEGORY_NAMES (
    product_category_name varchar(50) PRIMARY KEY,
    product_category_name_english varchar(50)
);

CREATE TABLE PRODUCTS (
    product_id char(32) PRIMARY KEY,
    product_category_name varchar(50),
    product_name_length int,
    product_description_length int,
    product_photos_qty int,
    product_weight int,
    product_length_cm int,
    product_height_cm int,
    product_width_cm int
);

CREATE TABLE ORDERS (
    order_id varchar(40) PRIMARY KEY,
    customer_id varchar(40),
    order_status varchar(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME
);

-- Composite PK (order_id, order_item): a single order can contain
-- multiple line items, so order_id alone isn't unique in this table.
CREATE TABLE ORDER_ITEMS (
    order_id char(50),
    order_item int,
    product_id varchar(50),
    seller_id varchar(50),
    shipping_limit_date DATETIME,
    price DECIMAL(6,2),
    freight_value DECIMAL(6,2),
    PRIMARY KEY (order_id, order_item)
);

-- Composite PK (order_id, payment_sequential): an order can be paid
-- across multiple rows (e.g. split payment methods).
CREATE TABLE ORDER_PAYMENTS (
    order_id varchar(50),
    payment_sequential int,
    payment_type varchar(15),
    payment_installments int,
    payment_value DECIMAL(7,2),
    PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE ORDER_REVIEWS (
    review_id varchar(40),
    order_id varchar(40),
    review_score int,
    review_comment_title varchar(40),
    review_comment_message varchar(300),
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    PRIMARY KEY (review_id, order_id)
);

-- ---------------------------------------------------------------------
-- 2. DATA LOADING happens here (LOAD DATA INFILE statements, not shown
--    in this file — see /sql/02_data_loading.sql)
-- ---------------------------------------------------------------------

-- ---------------------------------------------------------------------
-- 3. DATA CLEANING — must happen before the foreign keys below are
--    added, since dirty values (empty strings that should be NULL,
--    category names missing from CATEGORY_NAMES) would otherwise
--    violate those constraints.
-- ---------------------------------------------------------------------

-- One specific product had a category name that didn't correspond to
-- any real category — set to NULL rather than left as invalid data.
UPDATE products
SET product_category_name = NULL
WHERE product_id = '0082684bb4a60a862baaf7a60a5845ed';

-- Empty strings are a real value, not NULL, and would fail the FK
-- check below. SQL_SAFE_UPDATES is toggled off because this UPDATE's
-- WHERE clause doesn't filter on an indexed key column.
SET SQL_SAFE_UPDATES = 0;
UPDATE products
SET product_category_name = NULL
WHERE product_category_name = '';
SET SQL_SAFE_UPDATES = 1;

-- Two categories present in PRODUCTS but missing from the original
-- Kaggle translation file — added manually and documented as project
-- additions rather than source data.
INSERT INTO CATEGORY_NAMES (product_category_name, product_category_name_english)
VALUES
    ('pc_gamer', 'Gaming_PC'),
    ('portateis_cozinha_e_preparadores_de_alimentos', 'food_preparers_processors');

-- ---------------------------------------------------------------------
-- 4. FOREIGN KEY CONSTRAINTS — added last, once every table exists and
--    the data referenced by each FK is clean.
-- ---------------------------------------------------------------------

ALTER TABLE PRODUCTS
    ADD CONSTRAINT fk_products_category_name
    FOREIGN KEY (product_category_name) REFERENCES CATEGORY_NAMES(product_category_name);

ALTER TABLE ORDERS
    ADD CONSTRAINT fk_orders_customer
    FOREIGN KEY (customer_id) REFERENCES CUSTOMERS(customer_id);

ALTER TABLE ORDER_ITEMS
    ADD CONSTRAINT fk_order_items_order_id
    FOREIGN KEY (order_id) REFERENCES ORDERS(order_id);

ALTER TABLE ORDER_ITEMS
    ADD CONSTRAINT fk_order_items_products
    FOREIGN KEY (product_id) REFERENCES PRODUCTS(product_id);

ALTER TABLE ORDER_ITEMS
    ADD CONSTRAINT fk_order_items_sellers
    FOREIGN KEY (seller_id) REFERENCES SELLERS(seller_id);

ALTER TABLE ORDER_PAYMENTS
    ADD CONSTRAINT fk_order_payments_orders
    FOREIGN KEY (order_id) REFERENCES ORDERS(order_id);

ALTER TABLE ORDER_REVIEWS
    ADD CONSTRAINT fk_order_reviews_order_id
    FOREIGN KEY (order_id) REFERENCES ORDERS(order_id);

-- ---------------------------------------------------------------------
-- 5. DERIVED COLUMN
-- ---------------------------------------------------------------------

-- Generated column: total line-item cost including freight, computed
-- automatically and stored on every row rather than recalculated in
-- every query that needs it.
ALTER TABLE ORDER_ITEMS
    ADD COLUMN total_product_price INT GENERATED ALWAYS AS (price + freight_value) STORED;
