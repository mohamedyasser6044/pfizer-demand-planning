/* =====================================================================
   Pfizer Demand Planning Project  |  Mohamed Yasser
   Full cleaning script: sales_raw  ->  sales_clean   (MySQL 8)

   All the fixes from the cleaning stage, in the order they were done.
   Problem numbers (#) match the "#" column in sales_raw_problems.xlsx.
   Run top to bottom on a fresh database to rebuild sales_clean.
   Result: 3,228,213 clean rows.
   ===================================================================== */

USE pfizer_project;
SET SQL_SAFE_UPDATES = 0;

-- Work on a copy; sales_raw stays untouched as a backup
CREATE TABLE sales_clean AS
SELECT * FROM sales_raw;


/* =====================================================================
   STEP 1  Delete junk rows
   ===================================================================== */

-- #3  Fully empty rows (21)
DELETE FROM sales_clean
WHERE order_id IS NULL
  AND customer_code IS NULL
  AND product_code IS NULL;

-- #7  Test rows (30)
DELETE FROM sales_clean
WHERE order_id LIKE 'TEST%'
   OR customer_name LIKE '%TEST CUSTOMER%';

-- #8  Duplicate lines (4,500)
-- Helper: a unique number for every row + an index so the duplicate search is fast
ALTER TABLE sales_clean
ADD COLUMN row_id INT AUTO_INCREMENT PRIMARY KEY FIRST;

CREATE INDEX idx_order_line ON sales_clean (order_id, line_no);

-- Number the copies of each order line; keep copy 1, delete the rest
-- (subquery: inner = numbers the copies, outer = deletes copy_no > 1)
DELETE FROM sales_clean
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT row_id,
               ROW_NUMBER() OVER (PARTITION BY order_id, line_no
                                  ORDER BY row_id) AS copy_no
        FROM sales_clean
    ) numbered
    WHERE copy_no > 1
);


/* =====================================================================
   STEP 2  Fix codes
   ===================================================================== */

-- #16  customer_code with small letters (16,253)
UPDATE sales_clean
SET customer_code = UPPER(customer_code)
WHERE BINARY customer_code <> UPPER(customer_code);

-- #18  product_code: spaces, SKU- prefix, lost leading zeros (66,382)
UPDATE sales_clean
SET product_code = LPAD(REPLACE(TRIM(product_code), 'SKU-', ''), 8, '0')
WHERE product_code NOT REGEXP '^[0-9]{8}$';


/* =====================================================================
   STEP 3  Unify text
   ===================================================================== */

-- #1  country written many ways
UPDATE sales_clean SET country = 'United States'
WHERE TRIM(country) IN ('United States', 'USA', 'US', 'U.S.', 'United States of America');
UPDATE sales_clean SET country = 'United Kingdom'
WHERE TRIM(country) IN ('United Kingdom', 'UK', 'U.K.', 'Great Britain');
UPDATE sales_clean SET country = 'Germany'
WHERE TRIM(country) IN ('Germany', 'Deutschland');
UPDATE sales_clean SET country = 'Egypt'
WHERE TRIM(country) IN ('Egypt', 'EG', 'Egyp', 'Arab Republic of Egypt');
UPDATE sales_clean SET country = 'Saudi Arabia'
WHERE TRIM(country) IN ('Saudi Arabia', 'KSA', 'Saudi');
UPDATE sales_clean SET country = 'United Arab Emirates'
WHERE TRIM(country) IN ('United Arab Emirates', 'UAE', 'U.A.E', 'Emirates');
UPDATE sales_clean SET country = 'South Korea'
WHERE TRIM(country) IN ('South Korea', 'Korea', 'S. Korea', 'Korea, Republic of');

-- #2  order_status written many ways
UPDATE sales_clean SET order_status = 'Delivered'
WHERE TRIM(order_status) IN ('Delivered', 'Dlvd');
UPDATE sales_clean SET order_status = 'Partially Delivered'
WHERE TRIM(order_status) IN ('Partially Delivered', 'Partial', 'PARTIAL DELIVERY');
UPDATE sales_clean SET order_status = 'Cancelled'
WHERE TRIM(order_status) IN ('Cancelled', 'Canceled', 'CXL');

-- #32  fake empty cancel reasons -> real NULL
UPDATE sales_clean
SET cancel_reason = NULL
WHERE TRIM(cancel_reason) IN ('none', '-', 'N/A');


/* =====================================================================
   STEP 4  Fill / replace from the master tables
   ===================================================================== */

-- #15  Missing customer_code: take it from another line of the same order (495)
-- (subquery: inner = one real code per order, outer = writes it into the empty lines)
UPDATE sales_clean s
JOIN (
    SELECT order_id, MAX(customer_code) AS real_code
    FROM sales_clean
    WHERE customer_code IS NOT NULL
    GROUP BY order_id
) o ON o.order_id = s.order_id
SET s.customer_code = o.real_code
WHERE s.customer_code IS NULL;

-- #15  The rest (5) -> Unknown customer, which must also exist in customers
UPDATE sales_clean
SET customer_code = 'C0000'
WHERE customer_code IS NULL;

INSERT INTO customers
VALUES ('C0000', 'Unknown Customer', 'Unknown', 'XX', 'Unknown', 'X', 0);

-- #4 #5 #14 #17  customer name, type and city from customers
UPDATE sales_clean s
JOIN customers c ON s.customer_code = c.customer_code
SET s.customer_name = c.customer_name,
    s.customer_type = c.customer_type,
    s.city          = c.city;

-- #19 #20  product description, brand, therapeutic area from products
UPDATE sales_clean s
JOIN products p ON s.product_code = p.product_code
SET s.product_description = p.product_description,
    s.brand               = p.brand,
    s.therapeutic_area    = p.therapeutic_area;

-- #13  Empty region from geography by country
-- (correlated subquery: inner = finds the region of this row's country)
UPDATE sales_clean s
SET s.region = (
    SELECT g.region
    FROM geography g
    WHERE g.country = s.country
)
WHERE s.region IS NULL;


/* =====================================================================
   STEP 5  Dates
   ===================================================================== */

-- #9  order_date in 4 formats -> yyyy-mm-dd (158,793)
UPDATE sales_clean
SET order_date = CASE
       WHEN order_date LIKE '__/__/____'   THEN STR_TO_DATE(order_date, '%d/%m/%Y')
       WHEN order_date REGEXP '^[0-9]{8}$' THEN STR_TO_DATE(order_date, '%Y%m%d')
       WHEN order_date REGEXP '^[A-Za-z]'  THEN STR_TO_DATE(order_date, '%b %d, %Y')
       ELSE order_date
     END
WHERE order_date NOT LIKE '____-__-__';

-- #10  Future years 2031-2033 (180): year from delivery date, or requested date if none
UPDATE sales_clean
SET order_date = CONCAT(
      LEFT(CASE WHEN delivery_date IS NULL OR delivery_date = ''
                THEN requested_date
                ELSE delivery_date
           END, 4),
      SUBSTRING(order_date, 5)
    )
WHERE LEFT(order_date, 4) > '2030';

-- #11  Impossible 30 Feb (180) + fake 15 June left by #10 (7)
-- Bad line takes the order date of a good line in the same order (185)
UPDATE sales_clean b
JOIN sales_clean g
  ON g.order_id = b.order_id
 AND g.row_id <> b.row_id
SET b.order_date = g.order_date
WHERE (b.order_date LIKE '%-02-30'
       OR DATEDIFF(b.requested_date, b.order_date) NOT BETWEEN 0 AND 30)
  AND g.order_date NOT LIKE '%-02-30'
  AND DATEDIFF(g.requested_date, g.order_date) BETWEEN 0 AND 30;

-- No other line in the order (2): requested date minus the average gap (4 days)
UPDATE sales_clean
SET order_date = DATE_SUB(requested_date, INTERVAL 4 DAY)
WHERE order_date LIKE '%-02-30'
   OR DATEDIFF(requested_date, order_date) NOT BETWEEN 0 AND 30;

-- #12  Delivered before ordered (6,394)
-- Bad line takes the delivery date of a good line in the same order (6,329)
UPDATE sales_clean b
JOIN sales_clean g
  ON g.order_id = b.order_id
 AND g.row_id <> b.row_id
SET b.delivery_date = g.delivery_date
WHERE b.delivery_date <> ''
  AND b.delivery_date < b.order_date
  AND g.delivery_date <> ''
  AND g.delivery_date >= g.order_date;

-- No other line in the order (65): delivery = requested date (average gap 0 days)
UPDATE sales_clean
SET delivery_date = requested_date
WHERE delivery_date <> ''
  AND delivery_date < order_date;


/* =====================================================================
   STEP 6  Numbers
   ===================================================================== */

-- #21  ordered_qty with thousands comma "1,200" (1,190)
UPDATE sales_clean
SET ordered_qty = REPLACE(ordered_qty, ',', '')
WHERE ordered_qty LIKE '%,%';

-- #22 #23 #24 #25  delivered_qty: N/A, negative, empty, x1000
-- Rule: delivered = ordered - backorder, except cancelled lines = 0
UPDATE sales_clean
SET delivered_qty = CASE
      WHEN order_status = 'Cancelled' THEN 0
      ELSE ordered_qty - backorder_qty
    END
WHERE delivered_qty IS NULL
   OR delivered_qty NOT REGEXP '^[0-9]+$'
   OR (order_status <> 'Cancelled' AND delivered_qty <> ordered_qty - backorder_qty)
   OR (order_status = 'Cancelled' AND delivered_qty <> '0');

-- #26  discount written as percent "15.0%" -> 0.15 (32,201)
UPDATE sales_clean
SET discount_pct = ROUND(REPLACE(discount_pct, '%', '') / 100, 4)
WHERE RIGHT(discount_pct, 1) = '%';

-- #27 #28 #29  price with $ sign and/or decimal comma (48,349)
-- The comma here is a decimal point, so it becomes a dot (not removed)
UPDATE sales_clean
SET unit_price_usd = REPLACE(REPLACE(unit_price_usd, '$', ''), ',', '.')
WHERE unit_price_usd LIKE '$%'
   OR unit_price_usd LIKE '%,%';

-- #30  price = 0 (3,214). Not free samples: 3,183 of them had net sales.
-- One price per product + country + year, so build a small price list
CREATE TABLE price_list AS
SELECT product_code,
       country,
       LEFT(order_date, 4) AS yr,
       MAX(unit_price_usd + 0) AS price
FROM sales_clean
WHERE unit_price_usd + 0 > 0
GROUP BY product_code, country, LEFT(order_date, 4);

-- Index first, otherwise the JOIN below runs for a very long time
ALTER TABLE price_list ADD INDEX idx_price (product_code, country, yr);

UPDATE sales_clean s
JOIN price_list p
  ON p.product_code = s.product_code
 AND p.country = s.country
 AND p.yr = LEFT(s.order_date, 4)
SET s.unit_price_usd = p.price
WHERE s.unit_price_usd + 0 = 0;


/* =====================================================================
   STEP 7  Recalculate net sales
   ===================================================================== */

-- #31  net_sales inflated 1.2x to 3x (9,697)
-- net_sales = delivered x price x (1 - discount)
UPDATE sales_clean
SET net_sales_usd = ROUND(delivered_qty * unit_price_usd * (1 - discount_pct), 2)
WHERE ABS(net_sales_usd
          - ROUND(delivered_qty * unit_price_usd * (1 - discount_pct), 2)) > 0.01;


/* =====================================================================
   STEP 8  Correct column types
   ===================================================================== */

-- #6  Everything was text. Summed columns -> numbers, dates -> DATE,
--     join keys and names stay text. One ALTER = the table is rebuilt once.
ALTER TABLE sales_clean
  MODIFY line_no        INT,
  MODIFY order_date     DATE,
  MODIFY requested_date DATE,
  MODIFY delivery_date  DATE,
  MODIFY ordered_qty    INT,
  MODIFY delivered_qty  INT,
  MODIFY backorder_qty  INT,
  MODIFY unit_price_usd DECIMAL(12,4),
  MODIFY discount_pct   DECIMAL(6,4),
  MODIFY net_sales_usd  DECIMAL(14,2);


/* =====================================================================
   Final check
   ===================================================================== */

SELECT COUNT(*) AS total_rows FROM sales_clean;   -- 3,228,213
DESCRIBE sales_clean;
