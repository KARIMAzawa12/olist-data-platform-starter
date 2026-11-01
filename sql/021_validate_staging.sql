SELECT 'orders' AS tbl,
       (SELECT COUNT(*) FROM raw.orders)      AS raw_n,
       (SELECT COUNT(*) FROM staging.orders)  AS staging_n
UNION ALL SELECT 'customers',
       (SELECT COUNT(*) FROM raw.customers), (SELECT COUNT(*) FROM staging.customers)
UNION ALL SELECT 'order_items',
       (SELECT COUNT(*) FROM raw.order_items), (SELECT COUNT(*) FROM staging.order_items)
UNION ALL SELECT 'order_payments',
       (SELECT COUNT(*) FROM raw.order_payments), (SELECT COUNT(*) FROM staging.order_payments)
UNION ALL SELECT 'order_reviews',
       (SELECT COUNT(*) FROM raw.order_reviews), (SELECT COUNT(*) FROM staging.order_reviews)
UNION ALL SELECT 'products',
       (SELECT COUNT(*) FROM raw.products), (SELECT COUNT(*) FROM staging.products)
UNION ALL SELECT 'sellers',
       (SELECT COUNT(*) FROM raw.sellers), (SELECT COUNT(*) FROM staging.sellers);

SELECT
    COUNT(*) FILTER (WHERE NOT has_items)                  AS sans_articles,
    COUNT(*) FILTER (WHERE NOT has_payment)                AS sans_paiement,
    COUNT(*) FILTER (WHERE flag_delivered_no_date)         AS livrees_sans_date,
    COUNT(*) FILTER (WHERE flag_canceled_with_delivery)    AS annulees_avec_date
FROM staging.orders;