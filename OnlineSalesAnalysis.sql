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
from OnlineSalesDataset
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

--top 10 customer spending analysis
select top 10
    c.CustomerID,
    c.Country,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalSpent
from Orders o
join Products p on o.StockCode = p.StockCode
join Invoices i on o.InvoiceNo = i.InvoiceNo
join Customers c on i.CustomerID = c.CustomerID
group by c.CustomerID, c.Country
order by TotalSpent desc;

/*
output:
CustomerID		Country			TotalSpent
53125			United States	18398.0013
52408			United States	13515.9356
44086			United States	13493.2563
91749			United States	13163.0943
18887			Sweden			12569.7245
82365			United States	12310.6986
90318			Sweden			11954.7824
41410			Portugal		11370.8484
25691			Portugal		11267.9064
15401			Spain			11136.0253
*/

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

/*
output:
Country			TotalRevenue
United States	8397425.6962
United Kingdom	7878444.9690
Sweden			7244518.1295
Spain			6718816.3526
Portugal		6672766.6466
Norway			5925908.1878
Netherlands		5574153.7010
Italy			5199594.5844
Germany			5050359.1595
France			4759855.3187
Belgium			4378266.9008
Australia		4051283.0761
*/

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

/*
output:
StockCode	Description		TotalRevenue
SKU_1741	Wireless Mouse	115864.6060
SKU_1600	Wireless Mouse	113870.9583
SKU_1726	Wireless Mouse	111730.5582
SKU_1278	Wireless Mouse	111425.9250
SKU_1587	Wireless Mouse	111369.6877
*/

--total revenue by product category
select 
    p.Category,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Products p on o.StockCode = p.StockCode
group by p.Category
order by TotalRevenue desc;

/*
output:
Category	TotalRevenue
Stationery	71851392.7222
*/

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

/*
output:
PaymentMethod	TotalSales
Bank Transfer	32448905.73
Credit Card		32089724.38
paypall			31285916.37
*/

--sales trend over time (year 2024)
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
WHERE 
    DATEPART(YEAR, i.InvoiceDate) = 2024
GROUP BY 
    DATEPART(YEAR, i.InvoiceDate),
    DATEPART(MONTH, i.InvoiceDate)
ORDER BY
    Year, Month;

/*
output:
Year	Month	TotalSales
2024	1		1641794.83
2024	2		1549132.65
2024	3		1666725.74
2024	4		1730994.27
2024	5		1668029.98
2024	6		1564548.15
2024	7		1709416.15
2024	8		1709832.95
2024	9		1672881.79
2024	10		1634065.65
2024	11		114790.17
*/

--order priority and revenue
select 
    o.OrderPriority,
    count(o.OrderID) as TotalOrders,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as TotalRevenue
from Orders o
join Products p on o.StockCode = p.StockCode
group by o.OrderPriority
order by TotalRevenue desc;

/*
output:
OrderPriority	TotalOrders	TotalRevenue
Medium			13256		24177531.1436
High			13255		24081782.6099
Low				12986		23592078.9687
*/

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

/*
output:
Product				TotalQuantitySold
Wireless Mouse		958189
White Mug			24127
*/

--peak sales hours 
SELECT 
    FORMAT(DATEPART(HOUR, i.InvoiceTime), '00') AS SaleHour, COUNT(o.InvoiceNo) AS TotalOrders,
    SUM(o.Quantity * p.UnitPrice * (1 - o.Discount)) AS TotalRevenue
FROM Orders o
JOIN Invoices i ON o.InvoiceNo = i.InvoiceNo
JOIN Products p ON o.StockCode = p.StockCode
GROUP BY DATEPART(HOUR, i.InvoiceTime)
ORDER BY SaleHour;

/*
output:
SaleHour	TotalOrders		TotalRevenue
00			1643			3028644.5431
01			1635			2979892.1874
02			1646			2977601.6816
03			1666			3054696.5562
04			1635			2992806.0062
05			1633			2865140.5682
06			1660			3023815.3401
07			1641			3039921.4714
08			1632			2927151.9256
09			1650			3003610.8092
10			1647			3062857.6651
11			1653			3049908.7462
12			1637			2960808.8600
13			1644			2909627.3221
14			1652			2992516.3043
15			1648			2912459.1240
16			1646			3038889.2971
17			1658			3014671.5924
18			1656			2985622.6273
19			1641			2984255.1487
20			1640			2926888.2340
21			1653			3031832.5756
22			1634			2996886.5158
23			1647			3090887.6206
*/

--returns by product (top 10)
select top 10
    p.StockCode,
    p.Description,
    count(case when s.ReturnStatus = 'Returned' then 1 end) as Returns,
    count(o.OrderID) as TotalOrders
from Orders o
join Shipping s on o.InvoiceNo = s.InvoiceNo
join Products p on o.StockCode = p.StockCode
group by p.StockCode, p.Description

/*
output:
StockCode	Description		Returns	TotalOrders
SKU_1756	Wireless Mouse	2		33
SKU_1855	Wireless Mouse	3		31
SKU_1260	Wireless Mouse	2		47
SKU_1743	Wireless Mouse	4		50
SKU_1895	Wireless Mouse	3		46
SKU_1795	Wireless Mouse	8		49
SKU_1372	Wireless Mouse	5		44
SKU_1232	Wireless Mouse	6		41
SKU_1711	Wireless Mouse	3		35
SKU_1104	Wireless Mouse	4		39
*/

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

/*
output:
SalesChannel	TotalOrders	TotalRevenue
Online			19847		36168679.7612
In-store		19650		35682712.9610
*/

--customer order frequency (top 10)
select top 10
    c.CustomerID,
    c.Country,
    count(distinct i.InvoiceNo) as TotalOrders
from Invoices i
join Customers c on i.CustomerID = c.CustomerID
group by c.CustomerID, c.Country
order by TotalOrders desc;

/*
output:
CustomerID	Country			TotalOrders
53125		United States	6
11514		Portugal		5
44086		United States	5
91749		United States	5
20524		United Kingdom	5
14461		United Kingdom	5
81806		United Kingdom	5
17126		Netherlands		4
30067		Portugal		4
39848		Netherlands		4
*/

--high value orders (top 10)
select top 10
    o.InvoiceNo,
    sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) as OrderTotal
from Orders o
join Products p on o.StockCode = p.StockCode
group by o.InvoiceNo
having sum(o.Quantity * p.UnitPrice * (1 - o.Discount)) > 1000
order by OrderTotal desc;

/*
output:
InvoiceNo	OrderTotal
12255		4884.8100
27233		4882.8500
33156		4853.9400
18249		4851.4900
33326		4851.0000
23845		4847.5700
16548		4832.8700
34570		4831.1109
39718		4815.5877
33159		4812.2900
*/