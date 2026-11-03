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