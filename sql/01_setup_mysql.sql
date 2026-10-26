/* =====================================================================
   Author: Mohamed Yasser
   PFIZER SQL PROJECT - SETUP FOR MySQL 8 (run once)
   ---------------------------------------------------------------------
   Creates the database pfizer_project with 4 tables:
     sales_raw  -> 3,232,764 rows, ALL text (raw export, full of problems to clean)
     products   -> 133 medicines   (clean master list)
     customers  -> 2,000 customers (clean master list)
     geography  -> 22 countries    (clean master list)
   BEFORE RUNNING:
     1) Put the 6 CSV files in:  C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/
        (check your folder with:  SHOW VARIABLES LIKE 'secure_file_priv'; )
     2) MySQL Workbench: Edit > Preferences > SQL Editor >
        "DBMS connection read timeout interval" = 600   (then reconnect)
     3) Run everything with the lightning button  (Ctrl + Shift + Enter)
   All data is SIMULATED. Brand totals follow Pfizer's reported revenue 2023-2025.
   ===================================================================== */

CREATE DATABASE IF NOT EXISTS pfizer_project CHARACTER SET utf8mb4;
USE pfizer_project;

DROP TABLE IF EXISTS sales_raw, products, customers, geography;

/* ---------- RAW SALES: every column is text, like a messy system export ---------- */
CREATE TABLE sales_raw (
    order_id             VARCHAR(60) NULL,
    line_no              VARCHAR(60) NULL,
    order_date           VARCHAR(60) NULL,
    requested_date       VARCHAR(60) NULL,
    delivery_date        VARCHAR(60) NULL,
    region               VARCHAR(60) NULL,
    country              VARCHAR(60) NULL,
    city                 VARCHAR(60) NULL,
    customer_code        VARCHAR(60) NULL,
    customer_name        VARCHAR(100) NULL,
    customer_type        VARCHAR(60) NULL,
    product_code         VARCHAR(60) NULL,
    product_description  VARCHAR(100) NULL,
    brand                VARCHAR(60) NULL,
    therapeutic_area     VARCHAR(60) NULL,
    order_type           VARCHAR(60) NULL,
    order_channel        VARCHAR(60) NULL,
    ordered_qty          VARCHAR(60) NULL,
    delivered_qty        VARCHAR(60) NULL,
    backorder_qty        VARCHAR(60) NULL,
    unit_price_usd       VARCHAR(60) NULL,
    discount_pct         VARCHAR(60) NULL,
    net_sales_usd        VARCHAR(60) NULL,
    order_status         VARCHAR(60) NULL,
    cancel_reason        VARCHAR(60) NULL
);

/* ---------- CLEAN MASTER LISTS (use them to fix the raw data) ---------- */
CREATE TABLE products (
    product_code         VARCHAR(10)  NOT NULL PRIMARY KEY,
    product_description  VARCHAR(100) NOT NULL,
    brand                VARCHAR(50)  NOT NULL,
    therapeutic_area     VARCHAR(50)  NOT NULL,
    category             VARCHAR(50)  NOT NULL,
    dosage_form          VARCHAR(10)  NOT NULL,
    pack_size            INT          NOT NULL,
    first_approval_year  INT          NOT NULL,
    lifecycle_stage      VARCHAR(10)  NOT NULL
);
CREATE TABLE customers (
    customer_code       VARCHAR(6)   NOT NULL PRIMARY KEY,
    customer_name       VARCHAR(100) NOT NULL,
    customer_type       VARCHAR(30)  NOT NULL,
    country_code        CHAR(2)      NOT NULL,
    city                VARCHAR(50)  NOT NULL,
    customer_tier       CHAR(1)      NOT NULL,
    payment_terms_days  INT          NOT NULL
);
CREATE TABLE geography (
    country_code   CHAR(2)       NOT NULL PRIMARY KEY,
    country        VARCHAR(50)   NOT NULL,
    region         VARCHAR(40)   NOT NULL,
    currency       CHAR(3)       NOT NULL,
    local_per_usd  DECIMAL(14,3) NOT NULL,
    weekend        VARCHAR(10)   NOT NULL
);

/* ---------- LOAD THE FILES (empty cells become NULL) ---------- */
LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MohamedYasser_Pfizer_sales_raw_2023.csv'
INTO TABLE sales_raw CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12, @v13, @v14, @v15, @v16, @v17, @v18, @v19, @v20, @v21, @v22, @v23, @v24)
SET order_id = NULLIF(@v0, ''),
    line_no = NULLIF(@v1, ''),
    order_date = NULLIF(@v2, ''),
    requested_date = NULLIF(@v3, ''),
    delivery_date = NULLIF(@v4, ''),
    region = NULLIF(@v5, ''),
    country = NULLIF(@v6, ''),
    city = NULLIF(@v7, ''),
    customer_code = NULLIF(@v8, ''),
    customer_name = NULLIF(@v9, ''),
    customer_type = NULLIF(@v10, ''),
    product_code = NULLIF(@v11, ''),
    product_description = NULLIF(@v12, ''),
    brand = NULLIF(@v13, ''),
    therapeutic_area = NULLIF(@v14, ''),
    order_type = NULLIF(@v15, ''),
    order_channel = NULLIF(@v16, ''),
    ordered_qty = NULLIF(@v17, ''),
    delivered_qty = NULLIF(@v18, ''),
    backorder_qty = NULLIF(@v19, ''),
    unit_price_usd = NULLIF(@v20, ''),
    discount_pct = NULLIF(@v21, ''),
    net_sales_usd = NULLIF(@v22, ''),
    order_status = NULLIF(@v23, ''),
    cancel_reason = NULLIF(@v24, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MohamedYasser_Pfizer_sales_raw_2024.csv'
INTO TABLE sales_raw CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12, @v13, @v14, @v15, @v16, @v17, @v18, @v19, @v20, @v21, @v22, @v23, @v24)
SET order_id = NULLIF(@v0, ''),
    line_no = NULLIF(@v1, ''),
    order_date = NULLIF(@v2, ''),
    requested_date = NULLIF(@v3, ''),
    delivery_date = NULLIF(@v4, ''),
    region = NULLIF(@v5, ''),
    country = NULLIF(@v6, ''),
    city = NULLIF(@v7, ''),
    customer_code = NULLIF(@v8, ''),
    customer_name = NULLIF(@v9, ''),
    customer_type = NULLIF(@v10, ''),
    product_code = NULLIF(@v11, ''),
    product_description = NULLIF(@v12, ''),
    brand = NULLIF(@v13, ''),
    therapeutic_area = NULLIF(@v14, ''),
    order_type = NULLIF(@v15, ''),
    order_channel = NULLIF(@v16, ''),
    ordered_qty = NULLIF(@v17, ''),
    delivered_qty = NULLIF(@v18, ''),
    backorder_qty = NULLIF(@v19, ''),
    unit_price_usd = NULLIF(@v20, ''),
    discount_pct = NULLIF(@v21, ''),
    net_sales_usd = NULLIF(@v22, ''),
    order_status = NULLIF(@v23, ''),
    cancel_reason = NULLIF(@v24, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MohamedYasser_Pfizer_sales_raw_2025.csv'
INTO TABLE sales_raw CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(@v0, @v1, @v2, @v3, @v4, @v5, @v6, @v7, @v8, @v9, @v10, @v11, @v12, @v13, @v14, @v15, @v16, @v17, @v18, @v19, @v20, @v21, @v22, @v23, @v24)
SET order_id = NULLIF(@v0, ''),
    line_no = NULLIF(@v1, ''),
    order_date = NULLIF(@v2, ''),
    requested_date = NULLIF(@v3, ''),
    delivery_date = NULLIF(@v4, ''),
    region = NULLIF(@v5, ''),
    country = NULLIF(@v6, ''),
    city = NULLIF(@v7, ''),
    customer_code = NULLIF(@v8, ''),
    customer_name = NULLIF(@v9, ''),
    customer_type = NULLIF(@v10, ''),
    product_code = NULLIF(@v11, ''),
    product_description = NULLIF(@v12, ''),
    brand = NULLIF(@v13, ''),
    therapeutic_area = NULLIF(@v14, ''),
    order_type = NULLIF(@v15, ''),
    order_channel = NULLIF(@v16, ''),
    ordered_qty = NULLIF(@v17, ''),
    delivered_qty = NULLIF(@v18, ''),
    backorder_qty = NULLIF(@v19, ''),
    unit_price_usd = NULLIF(@v20, ''),
    discount_pct = NULLIF(@v21, ''),
    net_sales_usd = NULLIF(@v22, ''),
    order_status = NULLIF(@v23, ''),
    cancel_reason = NULLIF(@v24, '');

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MohamedYasser_Pfizer_products.csv'
INTO TABLE products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MohamedYasser_Pfizer_customers.csv'
INTO TABLE customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/MohamedYasser_Pfizer_geography.csv'
INTO TABLE geography CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

/* ---------- CHECK: expected 3,232,764 / 133 / 2000 / 22 ---------- */
SELECT 'sales_raw' AS table_name, COUNT(*) AS row_count FROM sales_raw UNION ALL
SELECT 'products',  COUNT(*) FROM products  UNION ALL
SELECT 'customers', COUNT(*) FROM customers UNION ALL
SELECT 'geography', COUNT(*) FROM geography;
