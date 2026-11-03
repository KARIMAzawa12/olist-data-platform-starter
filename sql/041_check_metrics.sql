SELECT * FROM analytics.v_monthly_sales ORDER BY purchase_month;
SELECT * FROM analytics.v_seller_performance ORDER BY revenue_rank LIMIT 5;
SELECT * FROM analytics.v_category_performance ORDER BY revenue_rank LIMIT 5;
SELECT * FROM analytics.v_delivery_monthly ORDER BY purchase_month;
SELECT * FROM analytics.v_customer_behavior ORDER BY order_count;