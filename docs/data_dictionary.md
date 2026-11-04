# Dictionnaire de données : couche analytics

## fact_orders (1 ligne = 1 commande, clé : order_id)
| Colonne | Description |
|---|---|
| order_id, customer_id, customer_unique_id | Identifiants (commande, client par commande, personne) |
| order_status | Statut de la commande |
| purchase_ts, purchase_month | Date d'achat, mois d'achat |
| delivered_customer_ts, estimated_delivery_ts | Livraison réelle et estimée |
| delivery_days | Jours entre achat et livraison (NULL si non livrée) |
| delay_days | Jours entre livraison réelle et estimée (positif = en retard) |
| is_late | Livraison après la date estimée (NULL si non livrée) |
| items_count, items_revenue, freight_total | Articles, somme des prix, somme des frais de port |
| payment_total | Somme des paiements de la commande |
| review_score | Note de l'avis le plus récent (NULL si aucun avis) |
| is_revenue_order | Faux pour `canceled` et `unavailable` |
| has_items, has_payment | Présence d'articles, de paiements |
| flag_delivered_no_date | Statut `delivered` sans date de livraison |
| flag_canceled_with_delivery | Statut `canceled` avec date de livraison |

## fact_order_items (1 ligne = 1 article, clé : order_id + order_item_id)
order_id, order_item_id, product_id, seller_id, customer_id, order_status,
purchase_ts, purchase_month, price, freight_value, item_total (price + freight_value),
is_revenue_order.

## Dimensions
- dim_customers (clé customer_id) : customer_unique_id, zip_code_prefix, city, state
- dim_sellers (clé seller_id) : zip_code_prefix, city, state
- dim_products (clé product_id) : category_name, category_name_en (« unknown » si absente), weight_g, length_cm, height_cm, width_cm

## Vues de métriques
v_monthly_sales, v_seller_performance, v_category_performance, v_delivery_monthly, v_customer_behavior.

## Limites connues
Voir la section « Qualité des données » du README.