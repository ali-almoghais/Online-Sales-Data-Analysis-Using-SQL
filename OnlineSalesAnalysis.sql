--create tables
create table Customers (
    CustomerID int primary key,
    Country varchar(100)
);

create table Products (
    StockCode varchar(50) primary key,
    Description varchar(255),
    UnitPrice decimal(10, 2),
    Category varchar(100)
);

create table Invoices (
    InvoiceNo int primary key,
    InvoiceDate datetime,
    InvoiceTime datetime,
    CustomerID int,
    foreign key (CustomerID) references Customers(CustomerID)
);

create table Orders (
    OrderID int identity(1,1) primary key,
    InvoiceNo int,
    StockCode varchar(50),
    Quantity int,
    Discount decimal(5, 2),
    OrderPriority varchar(50),
    foreign key (InvoiceNo) references Invoices(InvoiceNo),
    foreign key (StockCode) references Products(StockCode)
);

create table Shipping (
    ShippingID int identity(1,1) primary key,
    InvoiceNo int,
    ShipmentProvider varchar(100),
    WarehouseLocation varchar(100),
    ShippingCost decimal(10, 2),
    SalesChannel varchar(50),
    ReturnStatus varchar(50),
    foreign key (InvoiceNo) references Invoices(InvoiceNo)
);

create table Payments (
    PaymentID int identity(1,1) primary key,
    InvoiceNo int,
    PaymentMethod varchar(50),
    foreign key (InvoiceNo) references Invoices(InvoiceNo)
);

--insert data into the tables
insert into Customers (CustomerID, Country)
select distinct CustomerID, max(Country)
from OnlineSalesData
where CustomerID IS NOT NULL
group by CustomerID;

insert into Products (StockCode, Description, UnitPrice, Category)
select distinct StockCode, max(Description), max(UnitPrice), max(Category)
from OnlineSalesData
group by StockCode;

insert into Invoices (InvoiceNo, InvoiceDate, InvoiceTime, CustomerID)
select distinct InvoiceNo, InvoiceDate, InvoiceTime, CustomerID
from OnlineSalesData;

insert into Orders (InvoiceNo, StockCode, Quantity, Discount, OrderPriority)
select InvoiceNo, StockCode, Quantity, Discount, OrderPriority
from OnlineSalesData;

insert into Shipping (InvoiceNo, ShipmentProvider, WarehouseLocation, ShippingCost, SalesChannel, ReturnStatus)
select InvoiceNo, ShipmentProvider, WarehouseLocation, ShippingCost, SalesChannel, ReturnStatus
from OnlineSalesData;

insert into Payments (InvoiceNo, PaymentMethod)
select distinct InvoiceNo, PaymentMethod
from OnlineSalesData;

--total revenue by customer
select 
    c.CustomerID,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
inner join Products p on o.StockCode = p.StockCode
inner join Invoices i on o.InvoiceNo = i.InvoiceNo
inner join Customers c on i.CustomerID = c.CustomerID
group by c.CustomerID
order by TotalRevenue desc;

--total revenue by country
select 
    c.Country,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
JOIN Invoices i on o.InvoiceNo = i.InvoiceNo
JOIN Customers c on i.CustomerID = c.CustomerID
JOIN Products p on o.StockCode = p.StockCode
group by c.Country
order by TotalRevenue desc;

--total revenue by product
select 
    p.StockCode,
    p.Description,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Products p on o.StockCode = p.StockCode
group by p.StockCode, p.Description
order by TotalRevenue desc
offset 0 rows fetch next 5 rows only;

--total revenue by product category
select 
    p.Category,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Products p on o.StockCode = p.StockCode
group by p.Category
order by TotalRevenue desc;

--customer spending analysis
select 
    c.CustomerID,
    c.Country,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalSpent
from Orders o
join Products p on o.StockCode = p.StockCode
join Invoices i on o.InvoiceNo = i.InvoiceNo
join Customers c on i.CustomerID = c.CustomerID
group by c.CustomerID, c.Country
order by TotalSpent desc;

--total sales by payment method
select 
    p.PaymentMethod,
    sum(o.Quantity * pr.UnitPrice) as TotalSales
from 
    Payments p
join 
    Invoices i on p.InvoiceNo = i.InvoiceNo
join 
    Orders o on i.InvoiceNo = o.InvoiceNo
join 
    Products pr on o.StockCode = pr.StockCode
group by 
    p.PaymentMethod
order by
    TotalSales desc;

--sales trend over time
select 
    datepart(year, i.InvoiceDate) as Year,
    datepart(month, i.InvoiceDate) as Month,
    sum(o.Quantity * p.UnitPrice) as TotalSales
from 
    Invoices i
join 
    Orders o on i.InvoiceNo = o.InvoiceNo
join 
    Products p on o.StockCode = p.StockCode
group by 
    datepart(year, i.InvoiceDate),
    datepart(month, i.InvoiceDate)
order by
    Year, Month;

--order priority and revenue
select 
    o.OrderPriority,
    count(o.OrderID) as TotalOrders,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Products p on o.StockCode = p.StockCode
group by o.OrderPriority
order by TotalRevenue desc;

--total sellling products by quantity
select 
    p.Description as Product,
    sum(o.Quantity) as TotalQuantitySold
from 
    Orders o
join 
    Products p on o.StockCode = p.StockCode
group by 
    p.Description
order by 
    TotalQuantitySold desc;

--peak sales hours 
select 
    datepart(hour, i.InvoiceTime) as SaleHour,
    COUNT(o.InvoiceNo) as TotalOrders,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Invoices i on o.InvoiceNo = i.InvoiceNo
join Products p on o.StockCode = p.StockCode
group by datepart(hour, i.InvoiceTime)
order by TotalRevenue desc;

--returns by product
select 
    p.StockCode,
    p.Description,
    count(case when s.ReturnStatus = 'Returned' then 1 end) as Returns,
    count(o.OrderID) as TotalOrders,
    round(100.0 * count(case when s.ReturnStatus = 'Returned' then 1 end) / count(o.OrderID), 2) as ReturnRate
from Orders o
join Shipping s on o.InvoiceNo = s.InvoiceNo
join Products p on o.StockCode = p.StockCode
group by p.StockCode, p.Description
order by ReturnRate desc;

--total sales by sales channel
select 
    s.SalesChannel,
    count(o.OrderID) as TotalOrders,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Shipping s on o.InvoiceNo = s.InvoiceNo
join Products p on o.StockCode = p.StockCode
group by s.SalesChannel
order by TotalRevenue desc;

--customer order frequency
select 
    c.CustomerID,
    c.Country,
    count(distinct i.InvoiceNo) as TotalOrders
from Invoices i
join Customers c on i.CustomerID = c.CustomerID
group by c.CustomerID, c.Country
order by TotalOrders desc;

--high value orders
select 
    o.InvoiceNo,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as OrderTotal
from Orders o
join Products p on o.StockCode = p.StockCode
group by o.InvoiceNo
having sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) > 1000
order by OrderTotal desc;