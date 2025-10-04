select * from house_price
-------------------------------------------
-- Total Rows and columns
SELECT 
  (SELECT COUNT(*) FROM house_price) AS total_rows,
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'house_price') AS total_columns
-------------------------------------------

EXEC sp_help house_price

------------------------------------------------
-- distinct elements
select distinct Garage_Type from house_price

select count(distinct Garage_Type) from house_price

select Garage_Type, count(*) as value_counts
from house_price
group by Garage_Type
order by value_counts desc
--------------------------
select distinct Foundation_Type from house_price

select count(distinct Foundation_Type) from house_price

select Foundation_Type, count(*) as value_counts
from house_price
group by Foundation_Type
order by value_counts desc
---------------------------
select distinct Neighborhood from house_price

select count(distinct Neighborhood) from house_price

select Neighborhood, count(*) as value_counts
from house_price
group by Neighborhood 
order by value_counts desc
----------------------------------
select Number_of_Full_Bathrooms from house_price

select Number_of_Full_Bathrooms, count(*) as value_counts
from house_price
group by Number_of_Full_Bathrooms
order by value_counts

-----------------------------------------
-- Detect duplicates for some columns

select Overall_Quality, Ground_Living_Area, Total_Basement_Area,
       Year_Built, Year_Remodeled_or_Added, Number_of_Full_Bathrooms,
       Kitchen_Quality, Number_of_Fireplaces, Garage_Area,
       Neighborhood,Exterior_Quality,
       count(*) as dupl_count
from house_price
group by Overall_Quality, Ground_Living_Area, Total_Basement_Area,
       Year_Built, Year_Remodeled_or_Added, Number_of_Full_Bathrooms,
       Kitchen_Quality, Number_of_Fireplaces, Garage_Area,
       Neighborhood,Exterior_Quality
having count(*) > 1

----------------------------------------------------------------
-- remove duplicates with save old version of file
WITH CTE AS (
  SELECT *, 
         ROW_NUMBER() OVER (
           PARTITION BY Overall_Quality, Ground_Living_Area, Total_Basement_Area,
           Year_Built, Year_Remodeled_or_Added, Number_of_Full_Bathrooms,
           Kitchen_Quality, Number_of_Fireplaces, Garage_Area,
           Neighborhood,Exterior_Quality
           ORDER BY (SELECT NULL)) AS rn
  FROM house_price
)
DELETE FROM CTE WHERE rn > 1

select * from house_price

-----------------------------------------------------------------
-- Change column's name
EXEC sp_rename 'house_price.SalePrice', 'sale_price', 'COLUMN'
-----------------------------------------------------------------
-- detect outliers
-- Step 1: Get Q1 and Q3 using PERCENTILE_CONT
WITH percentiles AS (
    SELECT 
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY sale_price) OVER () AS Q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY sale_price) OVER () AS Q3
    FROM house_price
)
-- Step 2: Join with data and show full information
SELECT 
    h.sale_price,
    p.Q1,
    p.Q3,
    (p.Q3 - p.Q1) AS IQR,
    p.Q1 - 1.5 * (p.Q3 - p.Q1) AS lower_bound,
    p.Q3 + 1.5 * (p.Q3 - p.Q1) AS upper_bound
FROM house_price h
CROSS JOIN percentiles p
WHERE h.sale_price < p.Q1 - 1.5 * (p.Q3 - p.Q1)
   OR h.sale_price > p.Q3 + 1.5 * (p.Q3 - p.Q1)


SELECT * FROM house_price WHERE sale_price < 3625 and sale_price > 340625
-----------------------------------------------------------------------------
-- remove outliers
delete from house_price where sale_price < 3625 
delete from house_price where sale_price > 340625

select sale_price from house_price where sale_price < 3625
select sale_price from house_price where sale_price > 340625

-----------------------------------------------------------------------------
-- detect missing values
DECLARE @table_name SYSNAME = 'house_price';  
DECLARE @schema_name SYSNAME = 'dbo';        

DECLARE @sql NVARCHAR(MAX) = N'SELECT' + CHAR(13);
DECLARE @column_list NVARCHAR(MAX) = '';

-- Build list of NULL counters
SELECT @column_list += 
    '  COUNT(CASE WHEN ' + QUOTENAME(name) + ' IS NULL THEN 1 END) AS ' + QUOTENAME(name + '_nulls') + ',' + CHAR(13)
FROM sys.columns
WHERE object_id = OBJECT_ID(QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name));

-- Remove final comma and newline
SET @column_list = LEFT(@column_list, LEN(@column_list) - 2);

-- Build full query
SET @sql += @column_list + CHAR(13) +
    'FROM ' + QUOTENAME(@schema_name) + '.' + QUOTENAME(@table_name) + ';';

-- Execute the dynamic SQL
EXEC sp_executesql @sql;
-----------------------------------------------------------------------------
-- replace nulls by 0
select Paved_Driveway, count(*) as value_counts
from house_price
group by Paved_Driveway
order by value_counts desc

update house_price
set Paved_Driveway = 0
where Paved_Driveway is null

-----------------------------------------------------------------------------
-- replace all nulls by 'No'
select Basement_Exposure, count(*) as value_counts
from house_price
group by Basement_Exposure
order by value_counts desc

update house_price
set Basement_Exposure = 'No'
where Basement_Exposure is null
-----------------------------------------------------------------------------
-- replace all nulls by 'TA'
select Basement_Condition, count(*) as value_counts
from house_price
group by Basement_Condition
order by value_counts desc

update house_price
set Basement_Condition = 'TA'
where Basement_Condition is null
----------------------------------------------------------------------------
-- replace all nulls by 'Gd'
select Basement_Quality, count(*) as value_counts
from house_price
group by Basement_Quality
order by value_counts desc

update house_price
set Basement_Quality = 'Gd'
where Basement_Quality is null
----------------------------------------------------------------------------
-- replace nulls by 'Attchd'
select distinct Garage_Type from house_price 

select Garage_Type, count(*) as value_counts
from house_price
group by Garage_Type
order by value_counts desc

UPDATE house_price
SET Garage_Type = 'Attchd'
WHERE Garage_Type IS NULL

---------------------------------------------------
-- remove all null 

select Lot_Frontage, count(*) as value_counts
from house_price
group by Lot_Frontage
order by value_counts desc

SELECT TOP 1 Lot_Frontage
FROM house_price
WHERE Lot_Frontage IS NOT NULL
GROUP BY Lot_Frontage
ORDER BY COUNT(*) DESC

delete from house_price
where Lot_Frontage is null
-----------------------------------------------------------------------
-- Standardize Values
-----------------------------------------------------------------------
UPDATE house_price
SET Kitchen_Quality = 
    CASE 
        WHEN LOWER(Kitchen_Quality) IN ('Fa', 'Fair') THEN 'Fair'
        WHEN LOWER(Kitchen_Quality) IN ('Ex', 'Excellent') THEN 'Excellent'
        WHEN LOWER(Kitchen_Quality) IN ('Gd', 'Good') THEN 'Good'
        WHEN LOWER(Kitchen_Quality) IN ('Ta', 'Typical') THEN 'Typical'
        ELSE Kitchen_Quality
    END

select Kitchen_Quality, count(*) as value_counts
from house_price
group by Kitchen_Quality
order by value_counts

----------------------------------------------------------------------------
UPDATE house_price
SET Exterior_Quality = 
    CASE 
        WHEN LOWER(Exterior_Quality) IN ('Fa', 'Fair') THEN 'Fair'
        WHEN LOWER(Exterior_Quality) IN ('Ex', 'Excellent') THEN 'Excellent'
        WHEN LOWER(Exterior_Quality) IN ('Gd', 'Good') THEN 'Good'
        WHEN LOWER(Exterior_Quality) IN ('TA', 'Typical') THEN 'Typical'
        ELSE Exterior_Quality
    END

select Exterior_Quality, count(*) as value_counts
from house_price
group by Exterior_Quality
order by value_counts

-------------------------------------------------------------------------------
UPDATE house_price
SET Basement_Quality = 
    CASE 
        WHEN LOWER(Basement_Quality) IN ('Fa', 'Fair') THEN 'Fair'
        WHEN LOWER(Basement_Quality) IN ('Ex', 'Excellent') THEN 'Excellent'
        WHEN LOWER(Basement_Quality) IN ('Gd', 'Good') THEN 'Good'
        WHEN LOWER(Basement_Quality) IN ('TA', 'Typical') THEN 'Typical'
        ELSE Basement_Quality
    END

select Basement_Quality, count(*) as value_counts
from house_price
group by Basement_Quality
order by value_counts

--------------------------------------------------------------------------------
UPDATE house_price
SET Basement_Condition = 
    CASE 
        WHEN LOWER(Basement_Condition) IN ('Fa', 'Fair') THEN 'Fair'
        WHEN LOWER(Basement_Condition) IN ('Po', 'Poor') THEN 'Poor'
        WHEN LOWER(Basement_Condition) IN ('Gd', 'Good') THEN 'Good'
        WHEN LOWER(Basement_Condition) IN ('TA', 'Typical') THEN 'Typical'
        ELSE Basement_Condition
    END

select Basement_Condition, count(*) as value_counts
from house_price
group by Basement_Condition
order by value_counts

-------------------------------------------------------------------------------
UPDATE house_price
SET Basement_Exposure = 
    CASE 
        WHEN LOWER(Basement_Exposure) IN ('Mn', 'Minimum') THEN 'Minimum'
        WHEN LOWER(Basement_Exposure) IN ('No', 'No') THEN 'No'
        WHEN LOWER(Basement_Exposure) IN ('Gd', 'Good') THEN 'Good'
        WHEN LOWER(Basement_Exposure) IN ('Av', 'Average') THEN 'Average'
        ELSE Basement_Exposure
    END

select Basement_Exposure, count(*) as value_counts
from house_price
group by Basement_Exposure
order by value_counts

--------------------------------------------------------------------------------
UPDATE house_price
SET Heating_Quality_Condition = 
    CASE 
        WHEN LOWER(Heating_Quality_Condition) IN ('Po', 'Poor') THEN 'Poor'
        WHEN LOWER(Heating_Quality_Condition) IN ('Fa', 'Fair') THEN 'Fair'
        WHEN LOWER(Heating_Quality_Condition) IN ('Gd', 'Good') THEN 'Good'
        WHEN LOWER(Heating_Quality_Condition) IN ('TA', 'Typical') THEN 'Typical'
        WHEN LOWER(Heating_Quality_Condition) IN ('Ex', 'Exellent') THEN 'Exellent'
        ELSE Heating_Quality_Condition
    END

select Heating_Quality_Condition, count(*) as value_counts
from house_price
group by Heating_Quality_Condition
order by value_counts

--------------------------------------------------------------------------------
-- drop columns
ALTER TABLE house_price DROP COLUMN Year_Built2, TotRmsAbvGrd2

--------------------------------------------------------------------------------
-- extract new column from old column
ALTER TABLE house_price ADD price_group VARCHAR(20)

UPDATE house_price
SET price_group = CASE
    WHEN sale_price < 168708 THEN 'Cheap'
    WHEN sale_price BETWEEN 168708 AND 200000 THEN 'Normal'
    ELSE 'Expensive'
END

---------------------------------------------------------------------
-- change type of variable
ALTER TABLE house_price
ALTER COLUMN sale_price float

---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- Analysis
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
-- total_price_group by price_group

select price_group, count(*) as total_price_group
from house_price
group by price_group

-------------------------------------------------------------------------
-- max of sale price for each year built
select Year_Built,max(sale_price) as max_sale_price
from house_price
group by Year_Built
order by Year_Built


-- 
select * from house_price
