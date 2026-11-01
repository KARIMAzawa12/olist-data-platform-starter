-- 1. Avis : combien de review_id sont répétés, et sur combien de commandes ?
SELECT review_id, COUNT(*) AS nb_lignes, COUNT(DISTINCT order_id) AS nb_commandes
FROM raw.order_reviews
GROUP BY review_id
HAVING COUNT(*) > 1
ORDER BY nb_lignes DESC
LIMIT 5;

-- 2. Avis : distribution du nombre d'avis par commande
SELECT nb_avis, COUNT(*) AS nb_commandes
FROM (SELECT order_id, COUNT(*) AS nb_avis FROM raw.order_reviews GROUP BY order_id) t
GROUP BY nb_avis
ORDER BY nb_avis;

-- 3. Commandes sans article : quels statuts ?
SELECT o.order_status, COUNT(*) AS nb_commandes
FROM raw.orders o
LEFT JOIN raw.order_items i ON i.order_id = o.order_id
WHERE i.order_id IS NULL
GROUP BY o.order_status
ORDER BY nb_commandes DESC;

-- 4. Commandes sans paiement
SELECT o.order_id, o.order_status
FROM raw.orders o
LEFT JOIN raw.order_payments p ON p.order_id = o.order_id
WHERE p.order_id IS NULL;

-- 5. Incohérences statut / date de livraison
SELECT order_status, COUNT(*) AS nb
FROM raw.orders
WHERE (order_status = 'delivered' AND order_delivered_customer_date IS NULL)
   OR (order_status = 'canceled'  AND order_delivered_customer_date IS NOT NULL)
GROUP BY order_status;

-- 6. Orphelins : lignes enfants dont le parent n'existe pas
SELECT 'items sans commande' AS controle, COUNT(*) AS nb
FROM raw.order_items i LEFT JOIN raw.orders o ON o.order_id = i.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'paiements sans commande', COUNT(*)
FROM raw.order_payments p LEFT JOIN raw.orders o ON o.order_id = p.order_id
WHERE o.order_id IS NULL
UNION ALL
SELECT 'items sans produit', COUNT(*)
FROM raw.order_items i LEFT JOIN raw.products pr ON pr.product_id = i.product_id
WHERE pr.product_id IS NULL
UNION ALL
SELECT 'items sans vendeur', COUNT(*)
FROM raw.order_items i LEFT JOIN raw.sellers s ON s.seller_id = i.seller_id
WHERE s.seller_id IS NULL;