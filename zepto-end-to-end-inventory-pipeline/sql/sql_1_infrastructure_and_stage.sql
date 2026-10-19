-- ============================================================================
-- Script 01: Snowflake Setup & AWS S3 Connection
-- Author: Aaron Lee Peter
-- 
-- Quick Reference (Abbreviations used):
--   WH  = Warehouse (Snowflake's compute engine that runs queries)
--   DB  = Database
--   S3  = Amazon Simple Storage Service (where our raw CSV is stored)
--   IAM = Identity and Access Management (AWS security keys)
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- Step 1: Set up the compute warehouse
-- Keeping this on X-SMALL with a 60-second auto-suspend so it goes to sleep 
-- right after running queries and doesn't burn through cloud credits.
CREATE WAREHOUSE IF NOT EXISTS ZEPTO_WH
    WITH WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

USE WAREHOUSE ZEPTO_WH;

-- Step 2: Create the database and schema for our analytics layer
CREATE DATABASE IF NOT EXISTS ZEPTO_DB;
CREATE SCHEMA IF NOT EXISTS ZEPTO_DB.ANALYTICS;

USE SCHEMA ZEPTO_DB.ANALYTICS;

-- Step 3: Tell Snowflake how to read our CSV file
-- Added FIELD_OPTIONALLY_ENCLOSED_BY = '"' because some product names in the 
-- Zepto catalog contain commas (e.g., "Cashews, Whole") which would otherwise 
-- shift the columns during import.
CREATE OR REPLACE FILE FORMAT ZEPTO_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    NULL_IF = ('NULL', 'null', '');

-- Step 4: Connect Snowflake to our AWS S3 bucket (Sydney region: ap-southeast-2)
-- Note: Keys are removed here for GitHub security. Replace with your IAM keys to run.
CREATE OR REPLACE STAGE ZEPTO_S3_STAGE
    URL = 's3://zepto-inventory-analytics-end-699073937703-ap-southeast-2-an/raw/'
    CREDENTIALS = (
        AWS_KEY_ID = 'YOUR_AWS_ACCESS_KEY_HERE'
        AWS_SECRET_KEY = 'YOUR_AWS_SECRET_KEY_HERE'
    )
    FILE_FORMAT = ZEPTO_CSV_FORMAT;

-- Quick check to make sure Snowflake can see the uploaded CSV in the bucket
LIST @ZEPTO_S3_STAGE;