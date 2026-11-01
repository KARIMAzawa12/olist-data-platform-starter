-- Nombre de lignes : le grain est respecté
SELECT 'fact_orders' AS tbl,
       (SELECT COUNT(*) FROM staging.orders)      AS source_n,
       (SELECT COUNT(*) FROM analytics.fact_orders) AS analytics_n
UNION ALL SELECT 'fact_order_items',
       (SELECT COUNT(*) FROM staging.order_items), (SELECT COUNT(*) FROM analytics.fact_order_items)
UNION ALL SELECT 'dim_products',
       (SELECT COUNT(*) FROM staging.products), (SELECT COUNT(*) FROM analytics.dim_products)
UNION ALL SELECT 'dim_customers',
       (SELECT COUNT(*) FROM staging.customers), (SELECT COUNT(*) FROM analytics.dim_customers)
UNION ALL SELECT 'dim_sellers',
       (SELECT COUNT(*) FROM staging.sellers), (SELECT COUNT(*) FROM analytics.dim_sellers);

-- Montants : les totaux doivent être identiques à la source
SELECT
    (SELECT SUM(price) FROM staging.order_items)              AS items_source,
    (SELECT SUM(price) FROM analytics.fact_order_items)       AS items_fact_items,
    (SELECT SUM(items_revenue) FROM analytics.fact_orders)    AS items_fact_orders,
    (SELECT SUM(payment_value) FROM staging.order_payments)   AS pay_source,
    (SELECT SUM(payment_total) FROM analytics.fact_orders)    AS pay_fact_orders;

-- Avis : une commande avec avis doit en avoir un seul
SELECT
    (SELECT COUNT(DISTINCT order_id) FROM staging.order_reviews) AS commandes_avec_avis_source,
    (SELECT COUNT(review_score) FROM analytics.fact_orders)      AS commandes_avec_avis_fact;

-- Paiement vs articles + frais de port (écart > 1 centime)
SELECT COUNT(*) AS commandes_avec_ecart
FROM analytics.fact_orders
WHERE has_items AND has_payment
  AND ABS(payment_total - (items_revenue + freight_total)) > 0.01;