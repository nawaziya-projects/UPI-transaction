
--01.PRODUCT AND INVENTORY 
--Find top 10 purchased products based on units sold for each product sorted in a descent

USE Northwind
SELECT TOP 10 p.ProductName, SUM(od.Quantity) AS [Number of Units Sold]
FROM
[Order Details] od
INNER JOIN
Products p
ON od.ProductID = p.ProductID
GROUP BY p.ProductName
ORDER BY [Number of Units Sold] DESC;

--Find the product has the second highest cost in the company 
SELECT ProductName, UnitPrice FROM Products p1
WHERE 1 = (SELECT COUNT(DISTINCT UnitPrice)
FROM Products p2
WHERE p2.UnitPrice > p1.UnitPrice)

--Dense_Rank() to rank the sold products in each city in the USA
SELECT  p.ProductName, c.City, od.quantity,
DENSE_RANK() OVER (PARTITION BY c.Country ORDER BY od.quantity DESC) AS Product_Rank  
FROM 
Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
INNER JOIN 
Products p
ON od.ProductID = p.ProductID
WHERE Country = 'USA'
ORDER BY od.Quantity DESC

--Find all orders in Order table that took more than 2 days to ship after the order date,
--and the number of days after the order date with the customer ID and Country,
--where the total sale value is greater than 10000

SELECT o.OrderID, o.CustomerID, o.OrderDate, o.ShippedDate, o.ShipCountry,
DATEDIFF(DAY, OrderDate, ShippedDate) AS Duration_to_Ship,
SUM(od.Quantity * od.UnitPrice) AS [Total Sale Amount]
FROM
Orders o
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
WHERE
DATEDIFF(DAY, OrderDate, ShippedDate) > 2
GROUP BY o.OrderID, CustomerID, OrderDate, ShippedDate, ShipCountry
HAVING SUM(od.Quantity * od.UnitPrice) > 10000
ORDER BY DATEDIFF(DAY, OrderDate, ShippedDate) DESC

--Create product stock status using CASE Statement
SELECT productid,ProductName,
CASE
WHEN (UnitsInStock < UnitsOnOrder and
Discontinued = 0)
THEN 'Negative Inventory - Order Now!'
WHEN ((UnitsInStock - UnitsOnOrder)<
ReorderLevel and Discontinued = 0)
THEN 'Reorder Level Reached - Place Order'
WHEN (Discontinued = 1)
THEN '****Discontinued****'
ELSE 'In Stock'
END AS [Stock Status]
FROM products

--Number of orders per product
SELECT
p.ProductName, COUNT(o.orderid) AS [Number of
Orders]
FROM Products p
LEFT JOIN [Order Details] od
ON p.ProductID = od.ProductID
LEFT JOIN Orders o
ON o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = '2017'
GROUP BY p.ProductName
ORDER BY COUNT(o.orderid) DESC

--company decided to increase the product stick by 20% next month 
--list that contains the current and next month required stock for all products 
;WITH itemCTE (ProductID, ProductName, UnitsInStock, Desciption)
AS
(
SELECT ProductID, ProductName, UnitsInStock ,'Present Stock' AS
UnitsInStock
FROM Products
WHERE UnitsInStock != 0
UNION ALL
SELECT ProductID, ProductName,
(UnitsInStock + (UnitsInStock *20 )/100) AS UnitsInStock,
'Next Month Stock' AS UnitsInStock
FROM Products
WHERE UnitsInStock != 0
)
SELECT * FROM itemCTE ORDER BY ProductID


--02.SALES AND CUSTOMERS
--Find number of orders, revenue and avg revenue per order in 2017
SELECT
COUNT(o.orderid) AS [Number of Orders],
SUM(od.unitprice * od.quantity) AS [Revenue US Dollar],
AVG(od.unitprice * od.quantity) AS [Revenue Average per Order]
FROM orders o
INNER JOIN [Order Details] od
ON o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = '2017'

--Find the top ten customers who contributed to the highest sale with
--their cities and countries for the year 2018
SELECT TOP 10 c.CompanyName, c.City, c.Country,
SUM(od.Quantity * od.UnitPrice) AS Total
FROM Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
WHERE YEAR (o.OrderDate) = '2018'
GROUP BY c.CompanyName, c.City, c.Country
ORDER BY Total DESC


--Classify customers from A to D based on their sales volumes as follows:
--WHEN Total sale greater than or equal 30000 THEN grade is A
--WHEN Total sale less than 30000 and greater or equal than 20000
--THEN grade is B
--WHEN Total sale less than 20000 THEN grade is C
SELECT c.CompanyName,
SUM(od.Quantity * od.UnitPrice) AS Total,
CASE
WHEN SUM(od.Quantity * od.UnitPrice) >= 30000 THEN 'A'
WHEN SUM(od.Quantity * od.UnitPrice) < 30000 and sum(od.Quantity * od.UnitPrice) >= 20000
THEN 'B'
ELSE 'C'
END AS Customer_Grade
FROM Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
inner join
[Order Details] od
ON o.OrderID = od.OrderID
GROUP BY c.CompanyName
ORDER BY Total DESC


--Find customers that generated total sale amount more than the average sale volume in
--the company
SELECT c.CompanyName, c.City, c.Country,
SUM(od.Quantity * od.UnitPrice) AS Total
FROM Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
WHERE YEAR (o.OrderDate) = '2018'
GROUP BY c.CompanyName, c.City, c.Country
HAVING
SUM(od.Quantity * od.UnitPrice) >=
(SELECT AVG(Quantity * UnitPrice) FROM [Order Details])
ORDER BY Total DESC

--Find the sales volume per cusromer for each year 

CREATE VIEW Sale_Year AS
(
SELECT c.CompanyName AS [Customer Name], YEAR(o.orderdate) AS Year, (od.unitprice *
od.Quantity) AS Sale
FROM
Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
)

SELECT * FROM Sale_year
PIVOT (SUM(sale) for Year in ([2016],[2017],[2018])) AS SumSalesPerYear
ORDER BY [Customer Name]

--Customers did not buy from the company for more than 20 monthsUSE Northwind
SELECT c.CompanyName, MAX(o.OrderDate) AS [Last Order Date],
DATEDIFF(MONTH, MAX(o.OrderDate), GETDATE()) AS [Months Since Last Order]FROM Customers AS c
INNER JOIN Orders AS o ON c.CustomerID = o.CustomerID
GROUP BY c.CompanyName
HAVING DATEDIFF(MONTH, MAX(o.OrderDate), GETDATE()) > 20
ORDER BY [Months Since Last Order] DESC

--Find the customers list and the number of orders per customer
SELECT c.CompanyName, c.City ,
(SELECT COUNT(OrderID) FROM Orders o
WHERE c.CustomerID = o.CustomerID ) AS [Number Of Orders] FROM
Customers c
ORDER BY [Number Of Orders] DESC

--Find the customer contributed to the third highest sales volume 
CREATE VIEW [Customer Sale] AS
(
SELECT c.CompanyName AS [Customer Name], c.Country, SUM(od.unitprice * od.Quantity)
AS Sale
FROM
Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
GROUP BY c.CompanyName, c.Country
)

SELECT [Customer Name], Country, Sale FROM [Customer Sale] cs1
WHERE 2 = (SELECT COUNT(DISTINCT Sale)
FROM [Customer Sale] cs2
WHERE cs2.sale > cs1.sale)

--Find the duration in days between two orders
SELECT a.CustomerID, a.OrderDate,
DATEDIFF(DAY, a.OrderDate, b.OrderDate) AS [Days between two orders]FROM Orders a
INNER JOIN
Orders b
ON a.OrderID = b.OrderID - 1
ORDER BY a.OrderDate


--Sales data analysis in time series 
IF OBJECT_ID('[Customer Sale]') IS NOT NULL
DROP VIEW [Customer Sale]

CREATE VIEW [Customer Sale] AS
(
SELECT c.CompanyName AS [Customer Name], c.Country,YEAR(o.OrderDate) AS Year, MONTH
(o.OrderDate) AS Month,
SUM(od.unitprice * od.Quantity)
AS Sale
FROM
Customers c
INNER JOIN Orders o
ON c.CustomerID = o.CustomerID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
GROUP BY c.CompanyName, c.Country, YEAR(o.OrderDate), MONTH(o.OrderDate)
)

SELECT SUM
(SALE) AS SUM_SALE, MONTH, YEAR
 FROM [Customer Sale]
 WHERE YEAR = 2016
 GROUP BY MONTH, YEAR
 ORDER BY MONTH, SUM_SALE DESC
 SELECT SUM
(SALE) AS SUM_SALE, MONTH, YEAR
 FROM [Customer Sale]
 WHERE YEAR = 2017 AND MONTH IN (7,8,9,10,11,12)
 GROUP BY MONTH, YEAR
 ORDER BY MONTH, SUM_SALE DESC

--OR

SELECT
c.companyname,
COUNT(CASE WHEN MONTH(o.orderdate)= 1 THEN o.OrderID END) AS [JAN],
COUNT(CASE WHEN MONTH(o.orderdate)= 2 THEN o.OrderID END) AS [FEB],
COUNT(CASE WHEN MONTH(o.orderdate)= 3 THEN o.OrderID END) AS [MAR],
COUNT(CASE WHEN MONTH(o.orderdate)= 4 THEN o.OrderID END) AS [APR],
COUNT(CASE WHEN MONTH(o.orderdate)= 5 THEN o.OrderID END) AS [MAY],
COUNT(CASE WHEN MONTH(o.orderdate)= 6 THEN o.OrderID END) AS [JUN],
COUNT(CASE WHEN MONTH(o.orderdate)= 7 THEN o.OrderID END) AS [JUL],
COUNT(CASE WHEN MONTH(o.orderdate)= 8 THEN o.OrderID END) AS [AUG],
COUNT(CASE WHEN MONTH(o.orderdate)= 9 THEN o.OrderID END) AS [SEP],
COUNT(CASE WHEN MONTH(o.orderdate)= 10 THEN o.OrderID END) AS [OCT],
COUNT(CASE WHEN MONTH(o.orderdate)= 11 THEN o.OrderID END) AS [NOV],
COUNT(CASE WHEN MONTH(o.orderdate)= 12 THEN o.OrderID END) AS [DEC]
FROM
Customers c
JOIN Orders o
ON c.CustomerID = o.CustomerID
JOIN [Order Details] od
ON o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = '2017'
GROUP BY c.CompanyName
ORDER BY c.CompanyName

--Find the number of orders per date, week and day in 2017 
SELECT
CONVERT (DATE, orderdate) AS [Order Date],
DATEPART(WEEK,OrderDate) AS Week,
DATEPART(DAY,OrderDate) AS Day,
COUNT(OrderID) AS [Number of Orders]
FROM Orders
WHERE YEAR(OrderDate) = '2017'
GROUP BY CONVERT (DATE, orderdate),
DATEPART(WEEK,OrderDate), DATEPART(DAY,OrderDate)

--Find the revenue and revenue percentage per customer
DECLARE @Total_Rev money
SET @Total_Rev = (SELECT SUM(unitprice * quantity) FROM [Order Details])
SELECT
c.CompanyName AS [Customer Name], SUM(od.unitprice * od.quantity) AS [Revenue by
Customer],
SUM(od.unitprice * od.quantity)/@Total_Rev AS [Revnue Percentage per Customer]
FROM
[Customers] c
LEFT JOIN Orders o
ON c.CustomerID = o.CustomerID
LEFT JOIN [Order Details] od ON
o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = '2017'
GROUP BY c.CompanyName
ORDER BY [Revnue Percentage per Customer] DESC


--03 EMPLOYEES AND STAFF 
----Find employees who achieved the top 3 highest sale volume, their sale volumes,
--cities, and bonus (0.02 of the their total sale) for Jan(2018)
SELECT TOP 3 e.FirstName + ' ' + e.LastName AS [Full Name], e.City,
SUM(od.Quantity * od.UnitPrice) as [Total Sale],
ROUND(SUM(od.Quantity * od.UnitPrice)* .02, 0) AS [Bonus]
FROM
Employees e
INNER JOIN
Orders o
ON e.EmployeeID = o.EmployeeID
INNER JOIN
[Order Details] od
ON o.OrderID = od.OrderID
WHERE YEAR(o.OrderDate) = '2018' AND MONTH(o.OrderDate) ='1'
GROUP BY e.FirstName + ' ' + e.LastName, e.City
ORDER BY [Total Sale] DESC

--Find the number of of employees per title for each city
SELECT Title, City, COUNT(Title) AS [Number of Employees] FROM Employees
GROUP BY Title, City

--company's employees and their work duation in years
SELECT Lastname, Firstname, Title, DATEDIFF(YEAR, HireDate, GETDATE()) AS [Work Years
in the Company]
FROM Employees
WHERE City = 'London'

--Find the employees older than 70years old 
SELECT Lastname, Firstname, Title, DATEDIFF(YEAR, BirthDate, GETDATE()) AS [Age]
FROM Employees
WHERE DATEDIFF(YEAR, BirthDate, GETDATE()) >= 70