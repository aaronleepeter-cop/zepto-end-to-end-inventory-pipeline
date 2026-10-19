# Zepto End-to-End Cloud Data Pipeline: Dark-Store Inventory & Revenue Leakage Analytics
**Tech Stack:** Python (`boto3`) • AWS S3 • Snowflake Data Warehouse • SQL • Power BI (DAX)



!\[Dashboard Preview](dashboard/dashboard\_overview.png)



\## 1. The Business Problem

In 10-minute quick-commerce (Zepto, Blinkit, Instamart), dark stores operate with limited shelf space and high inventory turnover. When high-velocity items go out of stock, the business doesn't just lose a single item sale—customers often abandon their entire cart and switch apps.



Most retail dashboards only report \*how many\* items are out of stock. I built this end-to-end data pipeline to answer a more practical operational question: \*\*Which product categories are experiencing the highest stockout rates, and how much revenue is actually at risk because of them?\*\*



\---



\## 2. Pipeline Architecture \& Workflow



```text

\[ Local CSV Catalog ] 

&#x20;        │

&#x20;        ▼  Python (boto3 + dotenv)

\[ AWS S3 Landing Zone ]  (Bucket: ap-southeast-2 | IAM Scoped Access)

&#x20;        │

&#x20;        ▼  External Stage + COPY INTO

\[ Snowflake Data Warehouse ]  (DB: ZEPTO\_DB | Schema: ANALYTICS | Auto-Suspend: 60s)

&#x20;        │

&#x20;        ▼  Analytical View (VW\_ZEPTO\_ANALYTICS\_DASHBOARD)

\[ Power BI Desktop ]  (Import Mode | Custom DAX Measures | Conditional Formatting)

```



1\. \*\*Automated Cloud Staging (`scripts/upload\_to\_s3.py`):\*\* A Python script validates the processed dataset (3,731 SKUs) and uploads it to an AWS S3 bucket in `ap-southeast-2` using scoped IAM credentials.

2\. \*\*Warehouse Ingestion (`sql/01` \& `02`):\*\* Snowflake connects to the S3 bucket via an External Stage and loads raw records into `FACT\_ZEPTO\_INVENTORY` using batch `COPY INTO` statements. Compute costs are controlled using an `X-SMALL` warehouse (`ZEPTO\_WH`) configured to auto-suspend after 60 seconds of idle time.

3\. \*\*Transformation Layer (`sql/03\_analytical\_view.sql`):\*\* Rather than bloating the Power BI model with heavy transformations, business logic is handled upstream in Snowflake via `VW\_ZEPTO\_ANALYTICS\_DASHBOARD`. This view extracts brand names, standardizes unit pricing (per 100g), and calculates estimated stockout loss per SKU.

4\. \*\*Executive BI Reporting (`dashboard/`):\*\* Power BI connects directly to the Snowflake analytical view, using a dedicated `\_Measures` table to track catalog availability, promotional discounting, and revenue exposure.



\---



\## 3. Key Findings from the Data



Across the \*\*3,731 SKUs\*\* analyzed in the catalog:

\* \*\*Overall Stockout Rate:\*\* \*\*453 SKUs (12.14%)\*\* are currently out of stock, leaving \*\*87.86%\*\* of the catalog available for immediate fulfillment.

\* \*\*Total Revenue at Risk:\*\* Stockouts represent an estimated \*\*₹89,14,946 (\~₹89.15 Lakhs)\*\* in potential lost revenue across the dark-store network.

\* \*\*Average Catalog Discount:\*\* Products carry an average markdown of \*\*7.6%\*\* off MRP.



\### Category-Level Breakdown (Where the Money is Leaking)

| Product Category | Total SKUs | OOS SKUs | Stockout Rate % | Avg Discount % | Revenue at Risk (₹) |

| :--- | :---: | :---: | :---: | :---: | :---: |

| \*\*Chocolates \& Candies\*\* | 388 | 45 | 11.6% | 8.3% | ₹13,01,033 |

| \*\*Ice Cream \& Desserts\*\* | 388 | 45 | 11.6% | 8.3% | ₹13,01,033 |

| \*\*Packaged Food\*\* | 388 | 45 | 11.6% | 8.3% | ₹13,01,033 |

| \*\*Cooking Essentials\*\* | 514 | 64 | 12.5% | 7.2% | ₹10,44,171 |

| \*\*Munchies\*\* | 514 | 64 | 12.5% | 7.2% | ₹10,44,171 |

| \*\*Meats, Fish \& Eggs\*\* | — | — | — | — | \~₹8,00,000 |



\### Operational Recommendations

1\. \*\*Prioritize Impulse \& High-Margin Restocking:\*\* \*Chocolates \& Candies\*, \*Ice Cream \& Desserts\*, and \*Packaged Food\* account for \*\*₹39.03 Lakhs (43.8%)\*\* of total revenue at risk. Because these are high-margin impulse buys with higher average discounts (8.3%), restocking frequency and safety-stock buffers should be tightened here first.

2\. \*\*Fix Staple Availability in Cooking Essentials \& Munchies:\*\* Both categories suffer from an above-average \*\*12.5% stockout rate\*\* (64 OOS SKUs each), risking over \*\*₹20.88 Lakhs\*\* combined. Stockouts in staple cooking items often trigger full cart abandonment, making vendor lead-time optimization critical for these SKUs.



\---



\## 4. Repository Structure



\* `scripts/upload\_to\_s3.py` — Boto3 ingestion script with environment variable credential handling and error logging.

\* `sql/01\_infrastructure\_and\_stage.sql` — Snowflake warehouse, database, file format, and S3 external stage DDL.

\* `sql/02\_fact\_table\_ingestion.sql` — `FACT\_ZEPTO\_INVENTORY` table creation, `COPY INTO` load, and row-level audit query.

\* `sql/03\_analytical\_view.sql` — SQL view transforming raw inventory into executive KPIs.

\* `dax/inventory\_kpi\_measures.dax` — Full list of DAX measures powering the Power BI cards, bar charts, and conditional formatting.

\* `dashboard/` — Contains the `.pbix` source file and high-resolution dashboard screenshot.



\---



\## 5. How to Reproduce This Project



1\. \*\*Clone the repository and install dependencies:\*\*

&#x20;  ```bash

&#x20;  git clone \[https://github.com/](https://github.com/)<your-username>/zepto-darkstore-stockout-pipeline.git

&#x20;  cd zepto-darkstore-stockout-pipeline

&#x20;  pip install -r requirements.txt

&#x20;  ```

2\. \*\*Configure AWS Credentials:\*\*

&#x20;  Create a `.env` file in the root directory:

&#x20;  ```ini

&#x20;  AWS\_ACCESS\_KEY\_ID=your\_iam\_access\_key

&#x20;  AWS\_SECRET\_ACCESS\_KEY=your\_iam\_secret\_key

&#x20;  AWS\_REGION=ap-southeast-2

&#x20;  S3\_BUCKET\_NAME=your\_s3\_bucket\_name

&#x20;  ```

3\. \*\*Stage Data to S3:\*\*

&#x20;  ```bash

&#x20;  python scripts/upload\_to\_s3.py

&#x20;  ```

4\. \*\*Run Snowflake SQL Scripts:\*\*

&#x20;  Execute `01`, `02`, and `03` inside a Snowflake worksheet to build `VW\_ZEPTO\_ANALYTICS\_DASHBOARD`.

5\. \*\*Open Power BI:\*\*

&#x20;  Open `dashboard/Zepto\_Inventory\_Operations.pbix` and update the Snowflake server parameter under \*Transform Data -> Data source settings\* to refresh with your Snowflake account locator.

