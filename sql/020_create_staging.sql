BEGIN;

DROP TABLE IF EXISTS staging.orders;
CREATE TABLE staging.orders AS
SELECT
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp::timestamp      AS purchase_ts,
    o.order_approved_at::timestamp             AS approved_ts,
    o.order_delivered_carrier_date::timestamp  AS delivered_carrier_ts,
    o.order_delivered_customer_date::timestamp AS delivered_customer_ts,
    o.order_estimated_delivery_date::timestamp AS estimated_delivery_ts,
    EXISTS (SELECT 1 FROM raw.order_items i WHERE i.order_id = o.order_id)    AS has_items,
    EXISTS (SELECT 1 FROM raw.order_payments p WHERE p.order_id = o.order_id) AS has_payment,
    (o.order_status = 'delivered' AND o.order_delivered_customer_date IS NULL) AS flag_delivered_no_date,
    (o.order_status = 'canceled'  AND o.order_delivered_customer_date IS NOT NULL) AS flag_canceled_with_delivery
FROM raw.orders o;

DROP TABLE IF EXISTS staging.customers;
CREATE TABLE staging.customers AS
SELECT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix AS zip_code_prefix,
    customer_city            AS city,
    customer_state           AS state
FROM raw.customers;

DROP TABLE IF EXISTS staging.order_items;
CREATE TABLE staging.order_items AS
SELECT
    order_id,
    order_item_id::int               AS order_item_id,
    product_id,
    seller_id,
    shipping_limit_date::timestamp   AS shipping_limit_ts,
    price::numeric(12,2)             AS price,
    freight_value::numeric(12,2)     AS freight_value
FROM raw.order_items;

DROP TABLE IF EXISTS staging.order_payments;
CREATE TABLE staging.order_payments AS
SELECT
    order_id,
    payment_sequential::int          AS payment_sequential,
    payment_type,
    payment_installments::int        AS payment_installments,
    payment_value::numeric(12,2)     AS payment_value
FROM raw.order_payments;

DROP TABLE IF EXISTS staging.order_reviews;
CREATE TABLE staging.order_reviews AS
SELECT
    review_id,
    order_id,
    review_score::int                       AS review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date::timestamp         AS review_creation_ts,
    review_answer_timestamp::timestamp      AS review_answer_ts
FROM raw.order_reviews;

DROP TABLE IF EXISTS staging.products;
CREATE TABLE staging.products AS
SELECT
    product_id,
    product_category_name                          AS category_name,
    product_name_lenght::numeric::int              AS name_length,
    product_description_lenght::numeric::int       AS description_length,
    product_photos_qty::numeric::int               AS photos_qty,
    product_weight_g::numeric                      AS weight_g,
    product_length_cm::numeric                     AS length_cm,
    product_height_cm::numeric                     AS height_cm,
    product_width_cm::numeric                      AS width_cm
FROM raw.products;

DROP TABLE IF EXISTS staging.sellers;
CREATE TABLE staging.sellers AS
SELECT
    seller_id,
    seller_zip_code_prefix AS zip_code_prefix,
    seller_city            AS city,
    seller_state           AS state
FROM raw.sellers;

DROP TABLE IF EXISTS staging.product_category_translation;
CREATE TABLE staging.product_category_translation AS
SELECT product_category_name, product_category_name_english
FROM raw.product_category_translation;

COMMIT;