BEGIN;

CREATE OR REPLACE VIEW analytics.v_monthly_sales AS
SELECT purchase_month,
       COUNT(*)                                          AS orders,
       SUM(items_revenue)                                AS revenue,
       ROUND(SUM(items_revenue) / NULLIF(COUNT(*), 0), 2) AS avg_order_value,
       ROUND(100.0 * (SUM(items_revenue) - LAG(SUM(items_revenue)) OVER (ORDER BY purchase_month))
             / NULLIF(LAG(SUM(items_revenue)) OVER (ORDER BY purchase_month), 0), 1) AS revenue_growth_pct
FROM analytics.fact_orders
WHERE is_revenue_order AND has_items
GROUP BY purchase_month;

CREATE OR REPLACE VIEW analytics.v_seller_performance AS
SELECT seller_id,
       COUNT(DISTINCT order_id)                           AS orders,
       SUM(price)                                         AS revenue,
       RANK() OVER (ORDER BY SUM(price) DESC)             AS revenue_rank,
       ROUND(100.0 * SUM(price) / SUM(SUM(price)) OVER (), 2) AS revenue_share_pct
FROM analytics.fact_order_items
WHERE is_revenue_order
GROUP BY seller_id;

CREATE OR REPLACE VIEW analytics.v_category_performance AS
SELECT p.category_name_en,
       COUNT(DISTINCT f.order_id)                         AS orders,
       COUNT(*)                                           AS items_sold,
       SUM(f.price)                                       AS revenue,
       RANK() OVER (ORDER BY SUM(f.price) DESC)           AS revenue_rank
FROM analytics.fact_order_items f
JOIN analytics.dim_products p ON p.product_id = f.product_id
WHERE f.is_revenue_order
GROUP BY p.category_name_en;

CREATE OR REPLACE VIEW analytics.v_delivery_monthly AS
SELECT purchase_month,
       COUNT(*)                                           AS delivered_orders,
       ROUND(AVG(delivery_days), 1)                       AS avg_delivery_days,
       ROUND(100.0 * COUNT(*) FILTER (WHERE is_late) / COUNT(*), 1) AS late_pct
FROM analytics.fact_orders
WHERE order_status = 'delivered' AND delivered_customer_ts IS NOT NULL
GROUP BY purchase_month;

CREATE OR REPLACE VIEW analytics.v_customer_behavior AS
SELECT order_count, COUNT(*) AS customers
FROM (
    SELECT customer_unique_id, COUNT(*) AS order_count
    FROM analytics.fact_orders
    WHERE is_revenue_order
    GROUP BY customer_unique_id
) t
GROUP BY order_count;

COMMIT;