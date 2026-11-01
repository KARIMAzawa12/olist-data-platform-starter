-- 1. orders : order_id est-il unique ?
SELECT 'orders' AS table_name,
       COUNT(*) AS nb_lignes,
       COUNT(DISTINCT order_id) AS nb_distincts
FROM raw.orders;

-- 2. customers : customer_id vs customer_unique_id
SELECT COUNT(*) AS nb_lignes,
       COUNT(DISTINCT customer_id) AS customer_id_distincts,
       COUNT(DISTINCT customer_unique_id) AS personnes_distinctes
FROM raw.customers;

-- 3. order_reviews : review_id et order_id sont-ils uniques ?
SELECT COUNT(*) AS nb_lignes,
       COUNT(DISTINCT review_id) AS review_id_distincts,
       COUNT(DISTINCT order_id) AS order_id_distincts
FROM raw.order_reviews;

-- 4. order_items : clé composée (order_id, order_item_id)
SELECT COUNT(*) AS nb_lignes,
       COUNT(DISTINCT (order_id, order_item_id)) AS cles_distinctes,
       COUNT(DISTINCT order_id) AS commandes_distinctes
FROM raw.order_items;

-- 5. order_payments : clé composée (order_id, payment_sequential)
SELECT COUNT(*) AS nb_lignes,
       COUNT(DISTINCT (order_id, payment_sequential)) AS cles_distinctes,
       COUNT(DISTINCT order_id) AS commandes_distinctes
FROM raw.order_payments;

-- 6. Statuts des commandes et dates de livraison manquantes
SELECT order_status,
       COUNT(*) AS nb_commandes,
       COUNT(*) FILTER (WHERE order_delivered_customer_date IS NULL) AS sans_date_livraison
FROM raw.orders
GROUP BY order_status
ORDER BY nb_commandes DESC;