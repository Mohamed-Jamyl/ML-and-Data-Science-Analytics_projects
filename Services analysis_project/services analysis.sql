select * from services_data
select * from Branch_data
-----------------------------------------------------------
select top 5 * from services_data
-----------------------------------------------------------
-- count of rows and columns
SELECT 
  (SELECT COUNT(*) FROM services_data) AS total_rows,
  (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'services_data') AS total_columns
----------------------------------------------------------
-- count of distinct values in columns
select distinct count(client_name) from services_data
----------------------------------------------------------
-- detect duplicates
select service_id, service_type_id, client_name, hours , service_date, service_time, hourly_rate, total_revenue, branch_id, department ,service_description,count(*) as dupl_count
from services_data
group by service_id, service_type_id, client_name, hours , service_date, service_time, hourly_rate, total_revenue, branch_id, department ,service_description
having count(*) > 1
-----------------------------------------------------------
select client_name, COUNT(*) as dupl_count
from services_data
group by client_name
having count(*) > 1
------------------------------------------------
-- distinct values in columns
select count (distinct client_name) from services_data
----------------------------------------------------------
select SUM(total_revenue) as "sum of total revenue" 
from services_data
-----------------------------------------------------------
-- sum of total revenue group by department
SELECT department , SUM(total_revenue) as sum_of_total_revenue
from services_data
GROUP BY department
ORDER BY sum_of_total_revenue DESC

-- highier sum of total revenue in departments
select max(sum_of_total_revenue) as high_max_of_total_revenue_in_departments
from
    (select department , sum(total_revenue) as sum_of_total_revenue
     from services_data
     group by department) t
-------------------------------------------------------------
-- max of total revenue group by department
select department, max(total_revenue) as [max of total revenue] 
from services_data
GROUP BY department
ORDER BY [max of total revenue] DESC
---------------------------------------------------------------
-- min of total revenue group by department
select department, min(total_revenue) as [min of total revenue] 
from services_data
GROUP BY department
ORDER BY [min of total revenue] DESC
-----------------------------------------------------------------
-- sum of total revenue group by client name
select client_name, SUM(total_revenue) as [sum of total revenue] 
from services_data
GROUP BY client_name
ORDER BY [sum of total revenue] DESC
-----------------------------------------------------------------
-- sum of total revenue group by region
select region , sum(total_revenue) as [sum of total revenue]
from services_data s, Branch_data b
where s.branch_id = b.Branch_ID
GROUP BY Region
ORDER BY [sum of total revenue] DESC
------------------------------------------------------------------
-- sum of total revenue group by country
select Country , sum(total_revenue) as [sum of total revenue]
from services_data s, Branch_data b
where s.branch_id = b.Branch_ID
GROUP BY Country
order by [sum of total revenue] DESC
------------------------------------------------------------------
-- The clients whose total revenue are higher than the general average of tatal revenue
SELECT client_name, avg(total_revenue) as 'avg total revenue'
FROM services_data
GROUP