--create tables
CREATE TABLE Customers (
    CustomerID INT PRIMARY KEY,
    Country VARCHAR(100)
);

CREATE TABLE Products (
    StockCode VARCHAR(50) PRIMARY KEY,
    Description VARCHAR(255),
    UnitPrice DECIMAL(10, 2),
    Category VARCHAR(100)
);

CREATE TABLE Invoices (
    InvoiceNo INT PRIMARY KEY,
    InvoiceDate DATETIME,
    InvoiceTime DATETIME,
    CustomerID INT,
    FOREIGN KEY (CustomerID) REFERENCES Customers(CustomerID)
);

CREATE TABLE Orders (
    OrderID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo INT,
    StockCode VARCHAR(50),
    Quantity INT,
    Discount DECIMAL(5, 2),
    OrderPriority VARCHAR(50),
    FOREIGN KEY (InvoiceNo) REFERENCES Invoices(InvoiceNo),
    FOREIGN KEY (StockCode) REFERENCES Products(StockCode)
);

CREATE TABLE Shipping (
    ShippingID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo INT,
    ShipmentProvider VARCHAR(100),
    WarehouseLocation VARCHAR(100),
    ShippingCost DECIMAL(10, 2),
    SalesChannel VARCHAR(50),
    ReturnStatus VARCHAR(50),
    FOREIGN KEY (InvoiceNo) REFERENCES Invoices(InvoiceNo)
);

CREATE TABLE Payments (
    PaymentID INT IDENTITY(1,1) PRIMARY KEY,
    InvoiceNo INT,
    PaymentMethod VARCHAR(50),
    FOREIGN KEY (InvoiceNo) REFERENCES Invoices(InvoiceNo)
);

--insert data into the tables

-- Insert into Customers
INSERT INTO Customers (CustomerID, Country)
SELECT DISTINCT CustomerID, MAX(Country)
FROM OnlineSalesData
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID;

INSERT INTO Products (StockCode, Description, UnitPrice, Category)
SELECT DISTINCT StockCode, MAX(Description), MAX(UnitPrice), MAX(Category)
FROM OnlineSalesData
GROUP BY StockCode;

INSERT INTO Invoices (InvoiceNo, InvoiceDate, InvoiceTime, CustomerID)
SELECT DISTINCT InvoiceNo, InvoiceDate, InvoiceTime, CustomerID
FROM OnlineSalesData;

INSERT INTO Orders (InvoiceNo, StockCode, Quantity, Discount, OrderPriority)
SELECT InvoiceNo, StockCode, Quantity, Discount, OrderPriority
FROM OnlineSalesData;

INSERT INTO Shipping (InvoiceNo, ShipmentProvider, WarehouseLocation, ShippingCost, SalesChannel, ReturnStatus)
SELECT InvoiceNo, ShipmentProvider, WarehouseLocation, ShippingCost, SalesChannel, ReturnStatus
FROM OnlineSalesData;

INSERT INTO Payments (InvoiceNo, PaymentMethod)
SELECT DISTINCT InvoiceNo, PaymentMethod
FROM OnlineSalesData;

--total revenue by customer
SELECT 
    c.CustomerID,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
INNER JOIN Products p ON o.StockCode = p.StockCode
INNER JOIN Invoices i ON o.InvoiceNo = i.InvoiceNo
INNER JOIN Customers c ON i.CustomerID = c.CustomerID
GROUP BY c.CustomerID
ORDER BY TotalRevenue DESC;

--total revenue by country
SELECT 
    c.Country,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Invoices i ON o.InvoiceNo = i.InvoiceNo
JOIN Customers c ON i.CustomerID = c.CustomerID
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY c.Country
ORDER BY TotalRevenue DESC;

--total revenue by product
SELECT 
    p.StockCode,
    p.Description,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY p.StockCode, p.Description
ORDER BY TotalRevenue DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;

--total revenue by product category
SELECT 
    p.Category,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY p.Category
ORDER BY TotalRevenue DESC;

--customer spending analysis
SELECT 
    c.CustomerID,
    c.Country,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalSpent
FROM Orders o
JOIN Products p ON o.StockCode = p.StockCode
JOIN Invoices i ON o.InvoiceNo = i.InvoiceNo
JOIN Customers c ON i.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Country
ORDER BY TotalSpent DESC;

--total sales by payment method
SELECT 
    p.PaymentMethod,
    SUM(o.Quantity * pr.UnitPrice) AS TotalSales
FROM 
    Payments p
JOIN 
    Invoices i ON p.InvoiceNo = i.InvoiceNo
JOIN 
    Orders o ON i.InvoiceNo = o.InvoiceNo
JOIN 
    Products pr ON o.StockCode = pr.StockCode
GROUP BY 
    p.PaymentMethod
ORDER BY 
    TotalSales DESC;

--sales trend over time
SELECT 
    DATEPART(YEAR, i.InvoiceDate) AS Year,
    DATEPART(MONTH, i.InvoiceDate) AS Month,
    SUM(o.Quantity * p.UnitPrice) AS TotalSales
FROM 
    Invoices i
JOIN 
    Orders o ON i.InvoiceNo = o.InvoiceNo
JOIN 
    Products p ON o.StockCode = p.StockCode
GROUP BY 
    DATEPART(YEAR, i.InvoiceDate),
    DATEPART(MONTH, i.InvoiceDate)
ORDER BY 
    Year, Month;

--order priority and revenue
SELECT 
    o.OrderPriority,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY o.OrderPriority
ORDER BY TotalRevenue DESC;

--total sellling products by quantity
SELECT 
    p.Description AS Product,
    SUM(o.Quantity) AS TotalQuantitySold
FROM 
    Orders o
JOIN 
    Products p ON o.StockCode = p.StockCode
GROUP BY 
    p.Description
ORDER BY 
    TotalQuantitySold DESC;

--peak sales hours 
SELECT 
    DATEPART(HOUR, i.InvoiceTime) AS SaleHour,
    COUNT(o.InvoiceNo) AS TotalOrders,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Invoices i ON o.InvoiceNo = i.InvoiceNo
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY DATEPART(HOUR, i.InvoiceTime)
ORDER BY TotalRevenue DESC;

--returns by product
SELECT 
    p.StockCode,
    p.Description,
    COUNT(CASE WHEN s.ReturnStatus = 'Returned' THEN 1 END) AS Returns,
    COUNT(o.OrderID) AS TotalOrders,
    ROUND(100.0 * COUNT(CASE WHEN s.ReturnStatus = 'Returned' THEN 1 END) / COUNT(o.OrderID), 2) AS ReturnRate
FROM Orders o
JOIN Shipping s ON o.InvoiceNo = s.InvoiceNo
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY p.StockCode, p.Description
ORDER BY ReturnRate DESC;

--total sales by sales channel
SELECT 
    s.SalesChannel,
    COUNT(o.OrderID) AS TotalOrders,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Shipping s ON o.InvoiceNo = s.InvoiceNo
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY s.SalesChannel
ORDER BY TotalRevenue DESC;

--customer order frequency
SELECT 
    c.CustomerID,
    c.Country,
    COUNT(DISTINCT i.InvoiceNo) AS TotalOrders
FROM Invoices i
JOIN Customers c ON i.CustomerID = c.CustomerID
GROUP BY c.CustomerID, c.Country
ORDER BY TotalOrders DESC;

--high value orders
SELECT 
    o.InvoiceNo,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS OrderTotal
FROM Orders o
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY o.InvoiceNo
HAVING SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) > 1000
ORDER BY OrderTotal DESC;