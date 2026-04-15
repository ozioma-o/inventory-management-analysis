
/*INVENTORY MANAGEMENT ANALYSIS
AdventureWorks Database

OBJECTIVE: Analyze inventory levels and sales patterns to identify insufficiencies and provide recommendations for optimizing
inventory management.

ASSUMPTION: 
-FinishedGoodsFlag=1 identifies salable finished products/items
-FinishedGoodsFlag=0identifies non-salable products/items
-Safety stock level and reorder point thresholds based on average monthly sales:
Too Low=below one month of average sales
Too high=above one month of average sales
-SellEndDate= past current date,indicates expired products
*/


---Section 1: UNDERSTANDING WHAT IS HAPPENING(DESCRIPTIVE)

---INITIAL EXPLORATION(Before Data Discovery)

---Query 1: Initial view of all Products by inventory levels
---LOGIC:INNER JOIN used to get records common to both inventory and product table
---SUM function aggregates the quantities per product
---ASSUMPTION: All products in inventory are salable
SELECT
pri.ProductID,
p.Name,
SUM(pri.Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
GROUP BY pri.ProductID,p.Name 
ORDER BY TotalQuantity DESC;

---Query 2: categories/subcategories by inventory levels
---LOGIC:INNER JOIN returns only what is common to both inventory and product table
---LEFT JOIN function was used join both category and subcategory table to avoid dropping products with no category and 
---sub categories assigned
---DISCOVERY: I noticed that some products had no category or sub category
--- I investigated further to understand why
SELECT
pri.ProductID,
p.Name AS ProductName,
pc.Name AS Category,
psc.Name AS SubCategory,
SUM(pri.Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
LEFT  JOIN Production.ProductSubcategory psc
ON p.ProductSubcategoryID=psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc
ON psc.ProductCategoryID= pc.ProductCategoryID
GROUP BY pri.ProductID,p.Name,pc.Name,psc.Name
ORDER BY TotalQuantity DESC;

---From my investigation, i discovered that these products have FinishedGoodsFlag=0 
---meaning they are non-salable items
---Decision: I separated subsequent analysis by salable vs non-salable 
SELECT
pri.ProductID,
p.Name AS ProductName,
pc.Name AS Category,
psc.Name AS SubCategory,
p.FinishedGoodsFlag,
SUM(pri.Quantity) AS TotalQuantity
FROM AdventureWorks2019.Production.ProductInventory pri
INNER JOIN AdventureWorks2019.Production.Product p
ON pri.ProductID=p.ProductID
LEFT JOIN Production.ProductSubcategory psc
ON p.ProductSubcategoryID=psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc
ON psc.ProductCategoryID= pc.ProductCategoryID
GROUP BY pri.ProductID,p.Name,pc.Name,psc.Name,p.FinishedGoodsFlag
---filtering to return only non-salable products
HAVING p.FinishedGoodsFlag =0
ORDER BY TotalQuantity DESC;

---Query 3: Products by category and sub-category for salable products only
---LOGIC: filtering by FinishedGoodsFlag=1 which represents the salable products
SELECT
pri.ProductID,
p.Name AS ProductName,
pc.Name AS Category,
psc.Name AS SubCategory,
p.FinishedGoodsFlag,
SUM(pri.Quantity) AS TotalQuantity
FROM AdventureWorks2019.Production.ProductInventory pri
INNER JOIN AdventureWorks2019.Production.Product p
ON pri.ProductID=p.ProductID
LEFT JOIN Production.ProductSubcategory psc
ON p.ProductSubcategoryID=psc.ProductSubcategoryID
LEFT JOIN Production.ProductCategory pc
ON psc.ProductCategoryID= pc.ProductCategoryID
GROUP BY pri.ProductID,p.Name,pc.Name,psc.Name,p.FinishedGoodsFlag
HAVING p.FinishedGoodsFlag =1
ORDER BY TotalQuantity DESC;


---Query 4:Products by Sales
---LOGIC: INNER JOIN returns only what is common in both tables(sales and product)
---SUM function aggregates the order quantity per product
SELECT  
s. ProductID,
SUM(s.OrderQty) AS TotalSales,
p.Name
FROM Sales.SalesOrderDetail s
INNER JOIN Production.Product p
ON s.ProductID=p.ProductID
GROUP BY s.ProductID,p.Name
ORDER BY TotalSales DESC;

---Query 5:Product category/subcategory by sales
---LOGIC: the INNER JOIN is used to join the products table and the sales order details table to return what is common to both
---it is used again to return the category and sub category of each product 

SELECT  
s. ProductID,
SUM(s.OrderQty) AS TotalSales,
p.Name AS ProductName,
pc.Name AS Category,
psc.Name AS SubCategory
FROM Sales.SalesOrderDetail s
INNER JOIN Production.Product p
ON s.ProductID=p.ProductID
INNER JOIN Production.ProductSubcategory psc
ON p.ProductSubcategoryID=psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
ON psc.ProductCategoryID= pc.ProductCategoryID
GROUP BY s.ProductID,p.Name,pc.Name,psc.Name
ORDER BY TotalSales DESC;

---Query 6: Products with high inventory but low sales
---LOGIC:Both tables aggregated in sub queries before joining since both tables have multiples rows per product
---joining directly causes row multiplication inflating SUM results incorrectly
---LEFT JOIN used to retain products in inventory with no sales as these are important findings in themselves 
---RESULT: I noticed that some products with high inventory had no sales and this stirred investigation to understand why
SELECT
pri.ProductID,
p.Name,
pri.TotalQuantity,
p.FinishedGoodsFlag,
s.TotalSales
FROM 
(SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
GROUP BY ProductID) pri
LEFT JOIN (
SELECT ProductID,SUM(OrderQty) AS TotalSales
FROM Sales.SalesOrderDetail 
GROUP BY ProductID) s
ON pri.ProductID=s.ProductID
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
---filtering to show only salable products
WHERE FinishedGoodsFlag =1
ORDER BY TotalQuantity DESC;

---Query 7:Products with low inventory but high sales
---LOGIC: same as above with the only exception in the ORDER BY so that we are able to see products with the lowest inventory
---levels and if they are also the products with highest sales
---RESULT:I noticed that some products with very low inventory levels had a considerable number of sales,this raised concern
SELECT
pri.ProductID,
p.Name,
pri.TotalQuantity,
s.TotalSales
FROM 
(SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
GROUP BY ProductID) pri
LEFT JOIN (
SELECT ProductID,SUM(OrderQty) AS TotalSales
FROM Sales.SalesOrderDetail 
GROUP BY ProductID) s
ON pri.ProductID=s.ProductID
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
---filtering to return only salable items
WHERE FinishedGoodsFlag=1
ORDER BY TotalQuantity ASC;

---Query 8:Products with low inventory but high sales
---LOGIC: To also see how much inventory there is for products with highest sales
--RESULT: I noticed that the products with the highest sales had smaller inventory than those with way less sales
SELECT
pri.ProductID,
p.Name,
pri.TotalQuantity,
s.TotalSales
FROM 
(SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
GROUP BY ProductID) pri
LEFT JOIN (
SELECT ProductID,SUM(OrderQty) AS TotalSales
FROM Sales.SalesOrderDetail 
GROUP BY ProductID) s
ON pri.ProductID=s.ProductID
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
---filtering to return only salable items
WHERE FinishedGoodsFlag=1
ORDER BY TotalSales DESC;

---DIAGNOSTIC ANALYSIS

---Query 9: why are there products with lower sales but way higher inventory than the products with high sales
---LOGIC:I disovered that every product had a safetystocklevel and a reorder point,this point triggers the order for
---more products so i selected those columns as well to view the level for products in inventory
---RESULT: I discovered that products with the high sales had lower safety stock level and reorder point than those with low
---sales or no sales at all indicating inventory issues

SELECT
pri.ProductID,
p.Name,
p.SafetyStockLevel,
p.ReorderPoint,
pri.TotalQuantity,
s.TotalSales
FROM 
(SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
GROUP BY ProductID) pri
LEFT JOIN (
SELECT ProductID,SUM(OrderQty) AS TotalSales
FROM Sales.SalesOrderDetail 
GROUP BY ProductID) s
ON pri.ProductID=s.ProductID
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
---filtering to return only salable items
WHERE FinishedGoodsFlag=1
ORDER BY TotalSales DESC;




/*
Query 10: Summarising total inventory and total sales by category
and subcategory, and calculating inventory to sales
ratio to identify which categories are overstocked
or understocked.

LOGIC: Individual product queries showed inventory misalignment
but did not reveal whether the problem was concentrated
in specific categories. This query identifies patterns
at a higher level to support category level decisions.

Approach:
- Both ProductInventory and SalesOrderDetail are pre-aggregated in subqueries before joining to avoid row multiplication
since both tables have multiple rows per product.
- LEFT JOIN used for sales subquery to retain products with no sales so they are not excluded from the totals.
- INNER JOIN used for category tables because earlier analysis confirmed all FinishedGoodsFlag = 1 products have a category
and subcategory assigned.
- CAST used to convert inventory total to FLOAT before division to prevent integer division from dropping decimal places.
- NULLIF used to avoid divide by zero error for categories with no recorded sales.

Assumption:
- High ratio = category is overstocked relative to sales
- Low ratio = category stock is being depleted quickly
- Zero ratio = active sales but no inventory recorded,
indicating urgent stock or data issue
*/

SELECT
pc.Name AS Category,
psc.Name AS SubCategory,
SUM(pri.TotalQuantity) AS TotalInventory,
SUM(s.TotalSales) AS TotalSales,
-- ratio to spot overstocked/understocked categories
CAST(SUM(pri.TotalQuantity) AS FLOAT) /
NULLIF(SUM(s.TotalSales), 0) AS InventoryToSalesRatio
FROM (
SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory
GROUP BY ProductID
) pri
LEFT JOIN (
SELECT ProductID, SUM(OrderQty) AS TotalSales
FROM Sales.SalesOrderDetail
GROUP BY ProductID
) s 
ON pri.ProductID = s.ProductID
INNER JOIN Production.Product p 
ON pri.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE p.FinishedGoodsFlag = 1
AND SellEndDate IS NULL
GROUP BY pc.Name, psc.Name
ORDER BY TotalSales DESC;


/*
Query 11: Identifies products flagged as non-salable that still exist in inventory.
LOGIC:Initial exploration revealed high inventory product with no category or subcategory. Investigation showed
these products all have FinishedGoodsFlag = 0, meaning they were never intended for sale.
ASSUMPTION: For a manufacturing company these are expected to exist in inventory as they are likely raw materials
or components used in production.
LIMITATION: No production consumption data was available to determine whether these quantities are excessive relative to 
manufacturing activity.
*/ 

SELECT
pri.ProductID,
p.Name,
p.SafetyStockLevel,
p.ReorderPoint,
SUM(pri.Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
WHERE FinishedGoodsFlag=0
GROUP BY pri.ProductID,p.Name,p.SafetyStockLevel,p.ReorderPoint
ORDER BY TotalQuantity DESC;


/*
Query 12: Identifies products that were once salable but have exceeded their SellEndDate and still have inventory remaining.
LOGIC: A product having a past SellEndDate means it is no longer available for sale. Any remaining inventory cannot 
generate revenue and represents dead stocK tying up warehouse space and capital.

Approach:
- Filtered to FinishedGoodsFlag = 1 to focus on products that were once intended for sale.
- SellEndDate IS NOT NULL ensures only products with defined end date are included.
- CAST(GETDATE() AS DATE) used to compare date only,stripping the time component for a clean comparison.
- LEFT JOIN used for sales subquery to retain products even if they have no sales recorded.

*/

SELECT
pri.ProductID,
p.Name,
p.SellEndDate,
pri.TotalQuantity,
s.TotalSales
FROM 
(SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory pri
GROUP BY ProductID) pri
LEFT JOIN (
SELECT ProductID,SUM(OrderQty) AS TotalSales
FROM Sales.SalesOrderDetail 
GROUP BY ProductID) s
ON pri.ProductID=s.ProductID
INNER JOIN Production.Product p
ON pri.ProductID=p.ProductID
WHERE FinishedGoodsFlag=1
AND p.SellEndDate IS NOT NULL
AND p.SellEndDate < CAST(GETDATE() AS DATE)
ORDER BY TotalSales DESC;


---Query 13: Products with the least stock coverage(closest to running out of stock relative to how fast they sell)

SELECT
p.ProductID,
p.Name,
pc.Name AS Category,
inv.TotalQuantity AS CurrentInventory,
sal.TotalSales,
sal.AvgMonthlySales,
p.SafetyStockLevel,
-- how many months of stock remaining
CAST(inv.TotalQuantity AS FLOAT) /
NULLIF(sal.AvgMonthlySales, 0) AS MonthsOfStockRemaining
FROM (
SELECT ProductID, SUM(Quantity) AS TotalQuantity
FROM Production.ProductInventory
GROUP BY ProductID
) inv
LEFT JOIN (
SELECT
ProductID,
SUM(OrderQty) AS TotalSales,
SUM(OrderQty) / NULLIF(COUNT(DISTINCT MONTH(so.OrderDate)), 0)
AS AvgMonthlySales
FROM Sales.SalesOrderDetail sal
INNER JOIN Sales.SalesOrderHeader so
ON sal.SalesOrderID=so.SalesOrderID
GROUP BY ProductID
) sal ON inv.ProductID = sal.ProductID
INNER JOIN Production.Product p
ON inv.ProductID = p.ProductID
INNER JOIN Production.ProductSubcategory psc
ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN Production.ProductCategory pc
ON psc.ProductCategoryID = pc.ProductCategoryID
WHERE p.FinishedGoodsFlag = 1
AND SellEndDate IS NULL
ORDER BY MonthsOfStockRemaining ASC;
