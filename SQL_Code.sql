1. SalesPersonPerformance.
WITH table1 as(SELECT
--Creating a new table with the column with distinct Seller IDs derived from `sales.SalesPersonID` (where each `SalesPersonID` appears multiple times). 
--This is intended for subsequent application of aggregation functions SUM    
    CASE 
        WHEN sales.SalesPersonID IS NOT NULL THEN CAST(sales.SalesPersonID AS STRING) 
        ELSE 'Online' END AS SalesPersonNew,
        --Convert the `SalesPersonID` into a string format. 
        --The original column includes null values for online sales. Assigning the null value in to “Online” as the string.
        --We aim to differentiate between online and offline sales to create unique data entries for each Seller ID. 
        --Note that the `SalesPersonID` column contains data exclusively for offline sales
    ROUND(SUM(sales.TotalDue)) as Sum_Sales   --a calculation of total sales per “SalesPersonNew” dimension

   FROM  
    salesorderheader as sales
   GROUP BY ALL),

TotalSales as( select
                SUM(sales.TotalDue) as Total_Slaes --calculation which shows total sales of your whole data source
               FROM  
                 salesorderheader as sales)

SELECT 
       t1.SalesPersonNew,
       t1.Sum_Sales,
       t2.Total_Slaes,
       DENSE_RANK() OVER (order by Sum_Sales DESC) as Rank_Sum_Sales, -- a calculation which assigns rank of calculated sales per “Sales Person New” dimension
       SUM(t1.Sum_Sales) OVER (ORDER BY Sum_Sales DESC) as Cum_Sum_Sales, --cumulative total of your “Sum_Sales” calculation
       Round(SUM(t1.Sum_Sales) OVER (ORDER BY Sum_Sales DESC)/t2.Total_Slaes,2)*100 as Cum_Percent --calculation which takes “Cum_Sum_Sales” and divides it by “Total_Slaes”
FROM table1 as t1
Cross JOIN TotalSales as t2
Group by all
order by Rank_Sum_Sales



2.SalesReason.
--Creating a temporary table 
WITH sales_per_reason AS (SELECT
        DATE_TRUNC(OrderDate, MONTH) AS year_month, --select yy-mm date for "OrderDate"
        sales_reason.SalesReasonID, --select reason ID for sales
        SUM(sales.TotalDue) AS sales_amount --calculating total revenue for each reaosn for sales
  FROM
   `salesorderheader` AS sales --the table doesn't have "SalesReasonID" and has "TotalDue" and "OrderDate"
  INNER JOIN
   `salesorderheadersalesreason` AS sales_reason --the table has a "SalesReasonID"
   ON
   sales.SalesOrderID = sales_reason.salesOrderID
   GROUP BY 1,2)
--Creating the final table
SELECT
      sales_per_reason.year_month,
      reason.Name AS sales_reason, --select names for "SalesReasonID"
      sales_per_reason.sales_amount
FROM
      sales_per_reason
LEFT JOIN
      `salesreason` AS reason --the table has a reason names for sales and "SalesReasonID"
ON
      sales_per_reason.SalesReasonID = reason.SalesReasonID 


3.CountrySalesPerformance
--Adding state and country code to the original data from “salesorderheader”.
SELECT
      salesorderheader.*,
      province.stateprovincecode as ship_province,
      province.CountryRegionCode as country_code,
      province.name as country_state_name
FROM `salesorderheader` as salesorderheader --original data from “salesorderheader”
INNER JOIN
     `address` as address --the table with the "StateProvinceID"
    ON salesorderheader.ShipToAddressID = address.AddressID
INNER JOIN
     `stateprovince` as province --the table with "stateprovincecode" and "CountryRegionCode"
    ON address.stateprovinceid = province.stateprovinceid