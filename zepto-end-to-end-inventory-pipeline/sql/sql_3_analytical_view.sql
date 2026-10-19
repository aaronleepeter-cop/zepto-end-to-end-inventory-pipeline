-- ============================================================================
-- Script 03: Analytical View for Power BI Dashboard
-- Author: Aaron Lee Peter
-- 
-- Why use a View here?
-- Instead of writing heavy transformations inside Power BI, we handle the 
-- math inside Snowflake. Power BI connects directly to this clean view.
-- ============================================================================

USE WAREHOUSE ZEPTO_WH;
USE SCHEMA ZEPTO_DB.ANALYTICS;

CREATE OR REPLACE VIEW VW_ZEPTO_ANALYTICS_DASHBOARD AS
SELECT
    TRIM(CATEGORY) AS CATEGORY,
    
    -- Pull the first word of the product name to get the Brand
    SPLIT_PART(TRIM(NAME), ' ', 1) AS BRAND,
    
    TRIM(NAME) AS NAME,
    WEIGHT_IN_GMS,
    MRP_INR,
    DISCOUNT_PERCENT,
    DISCOUNTED_SELLING_PRICE,
    AVAILABLE_QUANTITY,
    OUT_OF_STOCK AS IS_OUT_OF_STOCK,

    -- Readable text label for the Power BI Donut Chart (instead of TRUE/FALSE)
    CASE 
        WHEN OUT_OF_STOCK = TRUE OR AVAILABLE_QUANTITY = 0 THEN 'Out of Stock'
        ELSE 'In Stock'
    END AS STOCK_STATUS,

    -- Group discounts into buckets to see if heavily discounted items sell out faster
    CASE
        WHEN DISCOUNT_PERCENT = 0 THEN 'No Discount'
        WHEN DISCOUNT_PERCENT <= 10 THEN '1% - 10% Off'
        WHEN DISCOUNT_PERCENT <= 25 THEN '11% - 25% Off'
        ELSE 'Over 25% Off'
    END AS DISCOUNT_TIER,

    -- Calculate price per 100g so we can compare small packs vs family packs fairly.
    -- Used Snowflake's DIV0() function so the query doesn't crash if weight is 0.
    ROUND(
        DIV0(DISCOUNTED_SELLING_PRICE, WEIGHT_IN_GMS) * 100, 
        2
    ) AS PRICE_PER_100G_INR,

    -- Estimate how much revenue is at risk when an item is Out of Stock.
    -- Assumes an average dark-store demand of 10 missed unit sales per stockout cycle.
    CASE 
        WHEN OUT_OF_STOCK = TRUE THEN ROUND(DISCOUNTED_SELLING_PRICE * 10, 2)
        ELSE 0 
    END AS POTENTIAL_STOCKOUT_LOSS_INR

FROM FACT_ZEPTO_INVENTORY;


-- Quick check: Preview the exact summary numbers that appear on the Power BI dashboard
-- Total Revenue at Risk across all categories comes out to ₹89,14,945.50 (~₹89.15 Lakhs)
SELECT 
    CATEGORY,
    COUNT(*) AS total_skus,
    SUM(CASE WHEN IS_OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END) AS oos_count,
    ROUND(AVG(DISCOUNT_PERCENT), 1) AS avg_discount_pct,
    SUM(POTENTIAL_STOCKOUT_LOSS_INR) AS revenue_at_risk_inr
FROM VW_ZEPTO_ANALYTICS_DASHBOARD
GROUP BY CATEGORY
ORDER BY revenue_at_risk_inr DESC;


-- Put the warehouse back to sleep now that we're done
ALTER WAREHOUSE ZEPTO_WH SUSPEND;