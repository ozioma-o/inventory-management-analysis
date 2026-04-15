
# 📦 Inventory Management Analysis — AdventureWorks

## Project Overview

The goal of this project was to analyse inventory and sales data for a manufacturing and retail company using SQL, identify inefficiencies in inventory management, and provide actionable business recommendations.

The analysis uses the **AdventureWorks2019** database and was conducted entirely in **SQL Server Management Studio (SSMS)**.

---

## Business Context

The business was experiencing three key problems:

- **Frequent stock-outs** for some products
- **Excess inventory** for other products
- **Limited visibility** into which products required immediate attention

The objective was to understand what was happening, diagnose why it was happening, and recommend actions to optimise inventory management.

---

## Tools Used

| Tool | Purpose |
|------|---------|
| SQL Server Management Studio (SSMS) | Data exploration and analysis |
| AdventureWorks2019 Database | Source data |

---

## Project Structure

---

## Analysis Approach

The analysis was structured in three stages:

### 1. Understand What Is Happening
- Identified products and categories with the highest and lowest inventory levels
- Identified products that sell the most and least
- Found products with high inventory but low sales and vice versa
- Discovered patterns and trends across categories

### 2. Diagnose Why It Is Happening
- Compared sales patterns against inventory levels
- Analysed safety stock levels and reorder points against average monthly sales
- Investigated products with no category or subcategory
- Identified products no longer available for sale but still in inventory

### 3. Provide Business Intelligence
- Prioritised products and categories requiring immediate action
- Provided data-backed recommendations for inventory optimisation

---

## Key Discoveries Made During Analysis

### Discovery 1: Non-Salable Items in Inventory
During initial exploration, several high inventory products had no category or subcategory assigned. Investigation revealed these products have `FinishedGoodsFlag = 0`, meaning they were never intended for sale. All subsequent analysis was refined to separate salable from non-salable products.

### Discovery 2: Expired Products Still in Inventory
A number of products that were once salable have exceeded their `SellEndDate` but remain in inventory. These represent dead stock that cannot generate revenue.

### Discovery 3: Safety Stock Completely Misaligned
High selling products had dangerously low safety stock while low selling products had unnecessarily high safety stock, directly causing the stock-outs and excess inventory the business was experiencing.

---

## Key Findings

| Finding | Detail |
|---------|--------|
| Safety stock misalignment | Approx. 76% products have either Too Low or Too High safety stock relative to sales velocity |
| Highest stock-out risk | Bikes, Helmets and Jerseys have the lowest inventory to sales ratios despite being high selling subcategories |
| Most overstocked subcategory | Saddles and Bottom Brackets hold an inventory to sales ratio of 2.82 despite having among the lowest sales volumes |
| Dead stock | Multiple products have exceeded their sell end date but remain in inventory |
| Zero inventory risk | Some subcategories show active sales with critically low inventory levels |

---

## SQL Techniques Used

- `INNER JOIN` and `LEFT JOIN`
- Subqueries for pre-aggregation to avoid row multiplication
- `GROUP BY` with multiple columns
- `CASE WHEN` for conditional classification
- `NULLIF` to prevent divide by zero errors
- `CAST` for data type conversion
- `GETDATE()` for current date comparisons
- `COUNT(DISTINCT ...)` for accurate monthly sales calculation
- Inventory to sales ratio calculation
- Average monthly sales (sales velocity) formula

---

## Assumptions and Limitations

### Assumptions
- `FinishedGoodsFlag = 1` identifies salable finished goods
- `FinishedGoodsFlag = 0` identifies non-salable items
- Safety stock classified using average monthly sales as benchmark:
  - **Too Low** = below 1 month of average sales
  - **Too High** = above 3 months of average sales
- `SellEndDate` past current date indicates a product is no longer available for sale

### Limitations
- The 1 month and 3 month thresholds are general best practice estimates and were not confirmed against company policy or supplier lead times. They should be validated with the operations team before any decisions are made.
- Non-salable items (`FinishedGoodsFlag = 0`) could not be fully categorised due to limited data context. They are likely raw materials or components but this could not be confirmed from the available data.
- Products with a short sales history may be unreliably classified due to insufficient data.

---

## Recommendations Summary

| Priority | Action |
|----------|--------|
|  Immediate | Replenish stock for Bikes, Helmets and Jerseys which face the highest stock-out risk |
|  Immediate | Investigate products with active sales but critically low inventory |
|  Short term | Recalibrate safety stock levels and reorder points for all products based on actual average monthly sales |
|  Short term | Review and write off or clear products that have exceeded their sell end date |
|  Medium term | Reduce order quantities for the most overstocked subcategory to free up capital and warehouse space |
|  Medium term | Establish a regular review process to keep stock levels aligned with evolving sales patterns |

---

## How to Run the Analysis

1. Restore the `AdventureWorks2019.bak` file to your SQL Server 
2. Open `inventory management analysis.sql` in SQL Server Management Studio
3. Select your AdventureWorks2019 database
4. Run queries section by section following the comments

---

## Ozioma F. Okoyenta

