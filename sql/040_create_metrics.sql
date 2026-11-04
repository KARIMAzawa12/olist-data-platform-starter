BEGIN;

CREATE OR REPLACE VIEW analytics.v_monthly_sales AS
WITH m AS (
    SELECT purchase_month,
           COUNT(*)           AS orders,
           SUM(items_revenue) AS revenue
    FROM analytics.fact_orders
    WHERE is_revenue_order AND has_items
    GROUP BY purchase_month
)
SELECT purchase_month,
       orders,
       revenue,
       ROUND(revenue / NULLIF(orders, 0), 2) AS avg_order_value,
       CASE WHEN orders >= 100
                 AND LAG(orders) OVER w >= 100
                 AND LAG(purchase_month) OVER w = (purchase_month - INTERVAL '1 month')::date
            THEN ROUND(100.0 * (revenue - LAG(revenue) OVER w)
                       / NULLIF(LAG(revenue) OVER w, 0), 1)
       END AS revenue_growth_pct
FROM m
WINDOW w AS (ORDER BY purchase_month);

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
