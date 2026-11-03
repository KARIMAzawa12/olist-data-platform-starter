WITH pay_info AS (
    SELECT order_id,
           MAX(payment_installments)            AS max_installments,
           BOOL_OR(payment_type = 'voucher')    AS has_voucher
    FROM staging.order_payments
    GROUP BY order_id
),
gap AS (
    SELECT f.order_id,
           f.payment_total - (f.items_revenue + f.freight_total) AS ecart
    FROM analytics.fact_orders f
    WHERE f.has_items AND f.has_payment
      AND ABS(f.payment_total - (f.items_revenue + f.freight_total)) > 0.01
)
SELECT CASE WHEN g.ecart > 0 THEN 'paiement > articles+port'
            ELSE 'paiement < articles+port' END AS sens,
       COUNT(*)                                   AS nb,
       ROUND(MIN(g.ecart), 2)                     AS ecart_min,
       ROUND(MAX(g.ecart), 2)                     AS ecart_max,
       COUNT(*) FILTER (WHERE p.max_installments > 1) AS en_plusieurs_fois,
       COUNT(*) FILTER (WHERE p.has_voucher)      AS avec_voucher
FROM gap g
JOIN pay_info p ON p.order_id = g.order_id
GROUP BY 1;