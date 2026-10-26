# Pfizer Sales, Forecast & Budget Dashboard

A 3-page Power BI dashboard that looks at why 2025 sales came in under budget and how far off the demand forecast was. I started from a messy sales export of 3.2 million rows, cleaned it in MySQL, and built the report on top of it.

**Note:** the data is simulated. I generated it in Python. The yearly total for each brand follows the revenue Pfizer reported publicly for 2024 and 2025, and the brand names are real, but every order, customer and number below that level is made up. The targets (OTIF 95%, forecast accuracy 75%, bias ±5%) are my own assumptions.

## Pages

### 1. Executive Summary
![Executive Summary](screenshots/executive-summary.png)

The main KPIs for 2025 compared with 2024: net sales, customers, delivered units, OTIF, budget achievement and forecast accuracy. It also shows sales against budget and forecast by quarter, the top 5 brands, a table by region, and three insight boxes. The text in those boxes changes with the filters.

### 2. Customer & Sales
![Customer & Sales](screenshots/customer-sales.png)

This page checks where sales went down. It shows like-for-like growth without the COVID brands (Paxlovid and Comirnaty), a table of therapeutic area by region, whether the drop came from fewer units or lower prices, the top 10 customers, and the brands that grew or fell the most.

### 3. Forecast & Budget
![Forecast & Budget](screenshots/forecast-budget.png)

This page is about the forecast: bias, how much the planners improved on the statistical model, which months were over- or under-forecast, how accuracy drops the further ahead you forecast, which brands made the gap, and whether the 2026 forecast makes the same mistake.

## What I found (2025 vs 2024)

- Net sales were $57.6bn, down 2%, which is 95.4% of the $60.4bn budget.
- Most of the drop came from Paxlovid, which fell by $3.35bn. Vyndaqel, Eliquis and Prevnar 20 grew by $1.67bn together. Discounts stayed the same, prices went up about 3%, units went down 6.3%, and the fill rate was 98%, so it wasn't a price or supply problem.
- Without Paxlovid and Comirnaty, sales grew 6.6%.
- North America was down 4.1% and accounts for 67% of the budget gap.
- The forecast was $4.0bn higher than actual sales (bias +3.6%). The tender months (Jan, Apr, Jul, Oct) were forecast too low and the other 8 months too high.
- Planners did better than the statistical model, 74.4% vs 64.2% accuracy. Accuracy was 83% one month ahead and 61% twelve months ahead.
- New launch brands were forecast 18.3% too high and reached only 83.9% of their budget.
- The 2026 forecast repeats the problem: tender months were 49% of demand in 2025 but only 33% of the 2026 forecast.

## Cleaning the data in MySQL

The raw table had 3,232,764 rows and every column was stored as text. I listed all the problems first (32 types), then fixed them on a copy and kept the original as a backup. The clean table has 3,228,213 rows.

1. Deleted 21 empty rows, 30 test rows and 4,500 duplicate lines.
2. Fixed customer codes (upper case) and product codes (removed spaces and "SKU-", added the missing leading zeros).
3. Made country names and order status consistent, and turned fake values like "N/A" and "-" into real NULLs.
4. Filled missing names, types, cities and brands from the master tables. Missing customer codes came from other lines of the same order.
5. Fixed dates: 4 different formats, future years, dates like 30 February, and orders delivered before they were placed.
6. Fixed numbers: commas in quantities, wrong delivered quantities, discounts written as "15%", prices with "$" or a decimal comma, and zero prices.
7. Recalculated net sales where it didn't match quantity × price × (1 − discount).
8. Changed the column types to numbers and dates.

Power BI connects to the clean table in MySQL with a read-only user.

## Data model

A star schema. Fact tables: Sales, Forecast, Demand History, Budget and Demand Events. Dimension tables: Calendar, Products, Customers, Geography and Brand.

## Tools

- MySQL 8 for profiling and cleaning (UPDATE with JOIN, window functions, indexes)
- Power BI: Power Query, data modeling and DAX (year-over-year, forecast accuracy as 1 − WMAPE, bias, forecast value added, RANKX/TOPN, dynamic text and colour measures)
- Python (pandas, NumPy) to generate the data

## Files

- `sql/01_setup_mysql.sql` creates the database and loads the raw files
- `sql/02_sales_cleaning.sql` is the full cleaning script, step by step
- `data/` has the data dictionary and the smaller tables
- `screenshots/` has the three pages

The raw sales files (about 250 MB a year), the forecast table and the Power BI file are too big for GitHub. I can share them if you ask.

## Contact

Mohamed Yasser Kamal, [mohamedyasser6044@gmail.com](mailto:mohamedyasser6044@gmail.com)
