-- ============================================================================
-- Script 02: Table Creation & S3 Batch Load
-- Author: Aaron Lee Peter
-- 
-- Quick Reference (Abbreviations used):
--   SKU = Stock Keeping Unit (a unique product + weight variant in the store)
--   MRP = Maximum Retail Price (original price before discount)
--   INR = Indian Rupee (₹)
--   OOS = Out of Stock (items currently unavailable to order)
-- ============================================================================

USE WAREHOUSE ZEPTO_WH;
USE SCHEMA ZEPTO_DB.ANALYTICS;

-- Step 1: Create the main inventory table
-- Added INGESTED_AT at the end to automatically stamp when the data was loaded.
CREATE OR REPLACE TABLE FACT_ZEPTO_INVENTORY (
    CATEGORY                  VARCHAR(100),
    NAME                      VARCHAR(255),
    MRP_INR                   NUMBER(10, 2),
    DISCOUNT_PERCENT          NUMBER(5, 2),
    AVAILABLE_QUANTITY        NUMBER(10, 0),
    DISCOUNTED_SELLING_PRICE  NUMBER(10, 2),
    WEIGHT_IN_GMS             NUMBER(10, 2),
    OUT_OF_STOCK              BOOLEAN,
    QUANTITY                  NUMBER(10, 0),
    INGESTED_AT               TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Step 2: Load the CSV data from our S3 stage into the table
COPY INTO FACT_ZEPTO_INVENTORY (
    CATEGORY,
    NAME,
    MRP_INR,
    DISCOUNT_PERCENT,
    AVAILABLE_QUANTITY,
    DISCOUNTED_SELLING_PRICE,
    WEIGHT_IN_GMS,
    OUT_OF_STOCK,
    QUANTITY
)
FROM @ZEPTO_S3_STAGE
FILE_FORMAT = (FORMAT_NAME = ZEPTO_CSV_FORMAT)
ON_ERROR = 'CONTINUE';

-- Step 3: Sanity check the load
-- Should return 3,731 total SKUs and 453 out-of-stock SKUs (12.14% OOS rate)
SELECT 
    COUNT(*) AS total_skus,
    SUM(CASE WHEN OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END) AS oos_skus,
    ROUND(
        SUM(CASE WHEN OUT_OF_STOCK = TRUE THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
        2
    ) AS stockout_rate_pct
FROM FACT_ZEPTO_INVENTORY;