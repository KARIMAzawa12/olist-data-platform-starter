import pytest


# --- Grain et absence de double comptage ---

def test_fact_orders_one_row_per_order(scalar):
    total = scalar("SELECT COUNT(*) FROM analytics.fact_orders")
    distinct = scalar("SELECT COUNT(DISTINCT order_id) FROM analytics.fact_orders")
    assert total == distinct


def test_fact_orders_keeps_every_staging_order(scalar):
    assert scalar("SELECT COUNT(*) FROM analytics.fact_orders") == scalar(
        "SELECT COUNT(*) FROM staging.orders"
    )


def test_items_revenue_not_duplicated(scalar):
    source = scalar("SELECT SUM(price) FROM staging.order_items")
    fact = scalar("SELECT SUM(items_revenue) FROM analytics.fact_orders")
    assert source == fact


def test_payments_not_duplicated(scalar):
    source = scalar("SELECT SUM(payment_value) FROM staging.order_payments")
    fact = scalar("SELECT SUM(payment_total) FROM analytics.fact_orders")
    assert source == fact


def test_one_review_per_order(scalar):
    with_review = scalar("SELECT COUNT(DISTINCT order_id) FROM staging.order_reviews")
    in_fact = scalar("SELECT COUNT(review_score) FROM analytics.fact_orders")
    assert with_review == in_fact


# --- Flags qualité : valeurs mesurées lors de l'enquête ---

@pytest.mark.parametrize(
    "condition, expected",
    [
        ("NOT has_items", 775),
        ("NOT has_payment", 1),
        ("flag_delivered_no_date", 8),
        ("flag_canceled_with_delivery", 6),
    ],
)
def test_quality_flags_match_investigation(scalar, condition, expected):
    n = scalar(f"SELECT COUNT(*) FROM analytics.fact_orders WHERE {condition}")
    assert n == expected


# --- Règles de validité (non vérifiées avant : un échec serait une découverte) ---

def test_amounts_are_not_negative(scalar):
    bad = scalar(
        "SELECT (SELECT COUNT(*) FROM staging.order_items WHERE price < 0 OR freight_value < 0)"
        " + (SELECT COUNT(*) FROM staging.order_payments WHERE payment_value < 0)"
    )
    assert bad == 0


def test_review_scores_between_1_and_5(scalar):
    bad = scalar(
        "SELECT COUNT(*) FROM staging.order_reviews WHERE review_score NOT BETWEEN 1 AND 5"
    )
    assert bad == 0


# --- Régression sur la croissance mensuelle ---

def test_growth_is_null_for_tiny_months(scalar):
    bad = scalar(
        "SELECT COUNT(*) FROM analytics.v_monthly_sales "
        "WHERE orders < 100 AND revenue_growth_pct IS NOT NULL"
    )
    assert bad == 0


def test_growth_is_null_when_base_month_is_tiny(scalar):
    bad = scalar(
        "SELECT COUNT(*) FROM analytics.v_monthly_sales "
        "WHERE purchase_month IN ('2016-10-01', '2017-01-01') "
        "AND revenue_growth_pct IS NOT NULL"
    )
    assert bad == 0