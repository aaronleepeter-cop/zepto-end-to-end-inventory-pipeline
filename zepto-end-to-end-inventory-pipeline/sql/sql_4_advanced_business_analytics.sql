--Out-of-Stock (OOS) Revenue Bleed & Stockout Rate by Category

SELECT 
    category                                                                         AS "Product Category",
    COUNT(*)                                                                         AS "Total Products Available",
    SUM(CASE WHEN is_out_of_stock THEN 1 ELSE 0 END)                                 AS "Out of Stock Count",
    ROUND(SUM(CASE WHEN is_out_of_stock THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2)    AS "Out of Stock Rate (%)",
    ROUND(SUM(potential_stockout_loss_inr), 2)                                      AS "Estimated Revenue Loss (₹)",
    ROUND(AVG(discount_percent), 2)                                                 AS "Average Discount (%)"
FROM ZEPTO_DB.ANALYTICS.FACT_ZEPTO_INVENTORY
GROUP BY category
ORDER BY "Estimated Revenue Loss (₹)" DESC;


--Safety Stock Depletion & Critical Restock Ranking (Window Functions)

WITH low_stock_items AS (
    SELECT 
        category,
        brand,
        name,
        available_quantity,
        discounted_sp_inr,
        DENSE_RANK() OVER (
            PARTITION BY category 
            ORDER BY available_quantity ASC, discounted_sp_inr DESC
        ) AS restock_priority_rank
    FROM ZEPTO_DB.ANALYTICS.FACT_ZEPTO_INVENTORY
    WHERE is_out_of_stock = FALSE 
      AND available_quantity <= 2
)
SELECT * 
FROM low_stock_items
WHERE restock_priority_rank <= 3
ORDER BY category, restock_priority_rank;


--Unit Economics & Pack Size Efficiency (Price per 100g)


SELECT 
    category,
    ROUND(AVG(price_per_100g), 2) AS avg_price_per_100g,
    ROUND(MIN(price_per_100g), 2) AS min_price_per_100g,
    ROUND(MAX(price_per_100g), 2) AS max_price_per_100g,
    ROUND(AVG(discounted_sp_inr), 2) AS avg_selling_price_inr
FROM ZEPTO_DB.ANALYTICS.FACT_ZEPTO_INVENTORY
WHERE price_per_100g IS NOT NULL 
  AND price_per_100g > 0
GROUP BY category
ORDER BY avg_price_per_100g DESC;


--FMCG Brand Dominance & Concentration Risk

WITH brand_metrics AS (
    SELECT 
        brand,
        COUNT(*) AS total_products,
        ROUND(SUM(discounted_sp_inr * available_quantity), 2) AS total_inventory_value_inr,
        ROUND(AVG(discount_percent), 2) AS avg_discount_offered
    FROM ZEPTO_DB.ANALYTICS.FACT_ZEPTO_INVENTORY
    GROUP BY brand
)
SELECT 
    brand,
    total_products,
    total_inventory_value_inr,
    avg_discount_offered,
    ROUND(total_inventory_value_inr * 100.0 / SUM(total_inventory_value_inr) OVER (), 2) AS share_of_inventory_val_pct
FROM brand_metrics
WHERE total_products >= 10
ORDER BY total_inventory_value_inr DESC
LIMIT 10;


--Discount Elasticity & Dead Stock Diagnostics

SELECT 
    CASE 
        WHEN discount_percent = 0 THEN '1. No Discount (0%)'
        WHEN discount_percent BETWEEN 1 AND 15 THEN '2. Moderate Discount (1-15%)'
        WHEN discount_percent BETWEEN 16 AND 30 THEN '3. High Discount (16-30%)'
        ELSE '4. Deep Clearance (>30%)'
    END AS discount_tier,
    COUNT(*) AS total_skus,
    ROUND(AVG(available_quantity), 2) AS avg_stock_remaining,
    SUM(CASE WHEN is_out_of_stock THEN 1 ELSE 0 END) AS out_of_stock_count,
    ROUND(AVG(discount_amount_inr), 2) AS avg_discount_rupees
FROM ZEPTO_DB.ANALYTICS.FACT_ZEPTO_INVENTORY
GROUP BY 1
ORDER BY 1;


--PowerBI Dashboard Metrics for Zepto Inventory

CREATE OR REPLACE VIEW ZEPTO_DB.ANALYTICS.VW_ZEPTO_ANALYTICS_DASHBOARD AS
SELECT 
    category,
    brand,
    name,
    weight_in_gms,
    mrp_inr,
    discounted_sp_inr,
    discount_percent,
    discount_amount_inr,
    price_per_100g,
    available_quantity,
    is_out_of_stock,
    potential_stockout_loss_inr,
    CASE 
        WHEN is_out_of_stock THEN 'Out of Stock'
        WHEN available_quantity <= 2 THEN 'Critical Stock'
        ELSE 'Healthy Stock'
    END AS stock_health_status,
    CASE 
        WHEN discount_percent = 0 THEN 'No Discount'
        WHEN discount_percent <= 15 THEN 'Low Discount'
        WHEN discount_percent <= 30 THEN 'Medium Discount'
        ELSE 'Deep Discount'
    END AS discount_tier
FROM ZEPTO_DB.ANALYTICS.FACT_ZEPTO_INVENTORY;