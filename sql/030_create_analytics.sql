BEGIN;

-- Dimensions
DROP TABLE IF EXISTS analytics.dim_customers CASCADE;
CREATE TABLE analytics.dim_customers AS
SELECT customer_id, customer_unique_id, zip_code_prefix, city, state
FROM staging.customers;
ALTER TABLE analytics.dim_customers ADD PRIMARY KEY (customer_id);

DROP TABLE IF EXISTS analytics.dim_sellers CASCADE;
CREATE TABLE analytics.dim_sellers AS
SELECT seller_id, zip_code_prefix, city, state
FROM staging.sellers;
ALTER TABLE analytics.dim_sellers ADD PRIMARY KEY (seller_id);

DROP TABLE IF EXISTS analytics.dim_products CASCADE;
CREATE TABLE analytics.dim_products AS
SELECT p.product_id,
       p.category_name,
       COALESCE(t.product_category_name_english, p.category_name, 'unknown') AS category_name_en,
       p.weight_g, p.length_cm, p.height_cm, p.width_cm
FROM staging.products p
LEFT JOIN staging.product_category_translation t
       ON t.product_category_name = p.category_name;
ALTER TABLE analytics.dim_products ADD PRIMARY KEY (product_id);

-- Fait : une ligne = un article d'une commande
DROP TABLE IF EXISTS analytics.fact_order_items CASCADE;
CREATE TABLE analytics.fact_order_items AS
SELECT i.order_id,
       i.order_item_id,
       i.product_id,
       i.seller_id,
       o.customer_id,
       o.order_status,
       o.purchase_ts,
       date_trunc('month', o.purchase_ts)::date AS purchase_month,
       i.price,
       i.freight_value,
       (i.price + i.freight_value) AS item_total,
       (o.order_status NOT IN ('canceled', 'unavailable')) AS is_revenue_order
FROM staging.order_items i
JOIN staging.orders o ON o.order_id = i.order_id;
ALTER TABLE analytics.fact_order_items ADD PRIMARY KEY (order_id, order_item_id);
CREATE INDEX ix_foi_seller ON analytics.fact_order_items (seller_id);
CREATE INDEX ix_foi_product ON analytics.fact_order_items (product_id);
CREATE INDEX ix_foi_month ON analytics.fact_order_items (purchase_month);

-- Fait : une ligne = une commande
DROP TABLE IF EXISTS analytics.fact_orders CASCADE;
CREATE TABLE analytics.fact_orders AS
WITH items AS (
    SELECT order_id,
           COUNT(*)           AS items_count,
           SUM(price)         AS items_revenue,
           SUM(freight_value) AS freight_total
    FROM staging.order_items
    GROUP BY order_id
),
pay AS (
    SELECT order_id, SUM(payment_value) AS payment_total
    FROM staging.order_payments
    GROUP BY order_id
),
rev AS (
    SELECT order_id, review_score
    FROM (
        SELECT order_id, review_score,
               ROW_NUMBER() OVER (
                   PARTITION BY order_id
                   ORDER BY review_answer_ts DESC NULLS LAST,
                            review_creation_ts DESC NULLS LAST,
                            review_id
               ) AS rn
        FROM staging.order_reviews
    ) t
    WHERE rn = 1
)
SELECT o.order_id,
       o.customer_id,
       c.customer_unique_id,
       o.order_status,
       o.purchase_ts,
       date_trunc('month', o.purchase_ts)::date AS purchase_month,
       o.delivered_customer_ts,
       o.estimated_delivery_ts,
       CASE WHEN o.delivered_customer_ts IS NOT NULL
            THEN o.delivered_customer_ts::date - o.purchase_ts::date END AS delivery_days,
       CASE WHEN o.delivered_customer_ts IS NOT NULL
            THEN o.delivered_customer_ts::date - o.estimated_delivery_ts::date END AS delay_days,
       CASE WHEN o.delivered_customer_ts IS NOT NULL
            THEN o.delivered_customer_ts > o.estimated_delivery_ts END AS is_late,
       COALESCE(i.items_count, 0)    AS items_count,
       COALESCE(i.items_revenue, 0)  AS items_revenue,
       COALESCE(i.freight_total, 0)  AS freight_total,
       COALESCE(p.payment_total, 0)  AS payment_total,
       r.review_score,
       (o.order_status NOT IN ('canceled', 'unavailable')) AS is_revenue_order,
       o.has_items,
       o.has_payment,
       o.flag_delivered_no_date,
       o.flag_canceled_with_delivery
FROM staging.orders o
LEFT JOIN staging.customers c ON c.customer_id = o.customer_id
LEFT JOIN items i ON i.order_id = o.order_id
LEFT JOIN pay   p ON p.order_id = o.order_id
LEFT JOIN rev   r ON r.order_id = o.order_id;
ALTER TABLE analytics.fact_orders ADD PRIMARY KEY (order_id);
CREATE INDEX ix_fo_month ON analytics.fact_orders (purchase_month);
CREATE INDEX ix_fo_customer ON analytics.fact_orders (customer_unique_id);

COMMIT;