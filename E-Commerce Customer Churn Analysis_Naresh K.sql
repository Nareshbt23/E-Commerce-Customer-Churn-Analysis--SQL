USE ecomm;

-- 1. Data Cleaning:
-- Handling Missing Values and Outliers:

-- 1.1 Impute mean for the following columns, and round off to the nearest integer if
-- required: WarehouseToHome, HourSpendOnApp, OrderAmountHikeFromlastYear,
-- DaySinceLastOrder.

SET SQL_SAFE_UPDATES = 0;

-- Calculate mean using user-defined variables
SET @WarehouseToHome_avg = (SELECT ROUND(AVG(WarehouseToHome),0) FROM customer_churn);
SET @HourSpendOnApp_avg = (SELECT ROUND(AVG(HourSpendOnApp),0) FROM customer_churn);
SET @OrderAmountHikeFromlastYear_avg = (SELECT ROUND(AVG(OrderAmountHikeFromlastYear),0) FROM customer_churn);
SET @DaySinceLastOrder_avg = (SELECT ROUND(AVG(DaySinceLastOrder),0) FROM customer_churn);

-- Impute mean for the specified columns 
UPDATE customer_churn
SET WarehouseToHome = @WarehouseToHome_avg
WHERE WarehouseToHome IS NULL;

UPDATE customer_churn
SET HourSpendOnApp = @HourSpendOnApp_avg 
WHERE HourSpendOnApp IS NULL;

UPDATE customer_churn
SET OrderAmountHikeFromlastYear = @OrderAmountHikeFromlastYear_avg
WHERE OrderAmountHikeFromlastYear IS NULL;

UPDATE customer_churn
SET DaySinceLastOrder = @DaySinceLastOrder_avg
WHERE DaySinceLastOrder IS NULL;

-- --------------------------------------------------------------------------------------------------

-- 1.2.Impute mode for the following columns: Tenure, CouponUsed, OrderCount.
-- Impute mode for the Tenure column

-- Calculate mode using user-defined variables
SET @Tenure_mode = (SELECT Tenure FROM customer_churn GROUP BY Tenure ORDER BY COUNT(*) DESC LIMIT 1);
SET @CouponUsed_mode = (SELECT CouponUsed FROM customer_churn GROUP BY CouponUsed ORDER BY COUNT(*) DESC LIMIT 1);
SET @OrderCount_mode = (SELECT OrderCount FROM customer_churn GROUP BY OrderCount ORDER BY COUNT(*) DESC LIMIT 1);

-- Impute mode for the specified columns 
UPDATE customer_churn
SET Tenure = @Tenure_mode 
WHERE Tenure IS NULL;
 
UPDATE customer_churn
SET CouponUsed= @CouponUsed_mode
WHERE CouponUsed IS NULL; 
 
UPDATE customer_churn
SET OrderCount = @OrderCount_mode 
WHERE OrderCount IS NULL;
 
 -- --------------------------------------------------------------------------------------------------

-- 1.3.Handle outliers in the 'WarehouseToHome' column by deleting rows where the
-- values are greater than 100.

-- handle outliers in 'WarehouseToHome' column

DELETE FROM customer_churn
WHERE WarehouseToHome > 100;

-- --------------------------------------------------------------------------------------------------

-- 2. Data Transformation:
-- Column Renaming:

-- 2.1. Rename the column "PreferedOrderCat" to "PreferredOrderCat".

ALTER TABLE customer_churn
CHANGE COLUMN PreferedOrderCat PreferredOrderCat VARCHAR(20);

-- --------------------------------------------------------------------------------------------------

-- 2.2. Rename the column "HourSpendOnApp" to "HoursSpentOnApp".

ALTER TABLE customer_churn
CHANGE COLUMN HourSpendOnApp HoursSpentOnApp INT;

-- --------------------------------------------------------------------------------------------------

-- Creating New Columns:

-- 2.3.Create a new column named ‘ComplaintReceived’ with values "Yes" if the
-- corresponding value in the ‘Complain’ is 1, and "No" otherwise.

ALTER TABLE customer_churn
ADD COLUMN ComplaintReceived VARCHAR(3);

UPDATE customer_churn
SET ComplaintReceived = 
    CASE 
        WHEN Complain = 1 THEN 'Yes'
        ELSE 'No'
    END;

-- --------------------------------------------------------------------------------------------------

-- 2.4.Create a new column named 'ChurnStatus'. Set its value to “Churned” if the
-- corresponding value in the 'Churn' column is 1, else assign “Active”.

ALTER TABLE customer_churn
ADD COLUMN ChurnStatus VARCHAR(7);

UPDATE customer_churn
SET ChurnStatus = 
    CASE 
        WHEN Churn = 1 THEN 'Churned'
        ELSE 'Active'
    END;

-- --------------------------------------------------------------------------------------------------

-- Column Dropping:
-- 2.5.Drop the columns "Churn" and "Complain" from the table.

ALTER TABLE customer_churn
DROP COLUMN Churn,
DROP COLUMN Complain;

-- --------------------------------------------------------------------------------------------------

-- 3.Data Exploration and Analysis:
-- 3.1. Retrieve the count of churned and active customers from the dataset.

SELECT ChurnStatus, COUNT(*) AS CustomerCount 
FROM customer_churn 
GROUP BY ChurnStatus;

-- --------------------------------------------------------------------------------------------------

-- 3.2. Display the average tenure of customers who churned.

SELECT AVG(Tenure) AS AverageTenure
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- --------------------------------------------------------------------------------------------------

-- 3.3. Calculate the total cashback amount earned by customers who churned.

SELECT SUM(CashbackAmount) AS TotalCashback
FROM customer_churn
WHERE ChurnStatus = 'Churned';

-- --------------------------------------------------------------------------------------------------

-- 3.4. Determine the percentage of churned customers who complained.

SELECT 
    (COUNT(CASE WHEN ChurnStatus = 'Churned' THEN 1 END) / COUNT(*)) * 100 AS PercentageChurned
FROM 
    customer_churn;

-- --------------------------------------------------------------------------------------------------

-- 3.5. Find the gender distribution of customers who complained.
SELECT 
    Gender,
    COUNT(*) AS ComplaintCount
FROM 
    customer_churn
WHERE 
    ComplaintReceived = 'Yes'
GROUP BY 
    Gender;

-- --------------------------------------------------------------------------------------------------

-- 3.6. Identify the city tier with the highest number of churned customers whose
-- preferred order category is Laptop & Accessory.

SELECT 
    CityTier,
    COUNT(*) AS ChurnedCustomerCount
FROM 
    customer_churn
WHERE 
    ChurnStatus = 'Churned'
    AND PreferredOrderCat = 'Laptop & Accessory'
GROUP BY 
    CityTier
ORDER BY 
    ChurnedCustomerCount DESC
LIMIT 1;

-- --------------------------------------------------------------------------------------------------

-- 3.7. Identify the most preferred payment mode among active customers.
SELECT 
    PreferredPaymentMode,
    COUNT(*) AS ActiveCustomerCount
FROM 
    customer_churn
WHERE 
    ChurnStatus = 'Active'
GROUP BY 
    PreferredPaymentMode
ORDER BY 
    ActiveCustomerCount DESC
LIMIT 1;

-- --------------------------------------------------------------------------------------------------

-- 3.8. List the preferred login device(s) among customers who took more than 10 days
-- since their last order.
SELECT 
    PreferredLoginDevice,
    COUNT(*) AS CustomerCount
FROM 
    customer_churn
WHERE 
    DaySinceLastOrder > 10
GROUP BY 
    PreferredLoginDevice;

-- --------------------------------------------------------------------------------------------------

-- 3.9. List the number of active customers who spent more than 3 hours on the app.

SELECT 
    COUNT(*) AS ActiveCustomerCount
FROM 
    customer_churn
WHERE 
    ChurnStatus = 'Active'
    AND HoursSpentOnApp > 3;


-- --------------------------------------------------------------------------------------------------
-- 3.10. Find the average cashback amount received by customers who spent at least 2
-- hours on the app.

SELECT 
    AVG(CashbackAmount) AS AverageCashback
FROM 
    customer_churn
WHERE 
    HoursSpentOnApp >= 2;

-- --------------------------------------------------------------------------------------------------
-- 3.11. Display the maximum hours spent on the app by customers in each preferred
-- order category.

SELECT 
    PreferredOrderCat,
    MAX(HoursSpentOnApp) AS MaxHoursSpent
FROM 
    customer_churn
GROUP BY 
    PreferredOrderCat;


-- --------------------------------------------------------------------------------------------------

-- 3.12. Find the average order amount hike from last year for customers in each marital
-- status category.
SELECT 
    MaritalStatus,
    AVG(OrderAmountHikeFromlastYear) AS AverageOrderAmountHike
FROM 
    customer_churn
GROUP BY 
    MaritalStatus;

-- --------------------------------------------------------------------------------------------------

-- 3.13. Calculate the total order amount hike from last year for customers who are single
-- and prefer mobile phones for ordering.
SELECT 
    SUM(OrderAmountHikeFromlastYear) AS TotalOrderAmountHike
FROM 
    customer_churn
WHERE 
    MaritalStatus = 'Single'
    AND PreferredOrderCat = 'Mobile Phone';

-- --------------------------------------------------------------------------------------------------

-- 3.14. Find the average number of devices registered among customers who used UPI as
-- their preferred payment mode.
SELECT 
    AVG(NumberOfDeviceRegistered) AS AverageDevicesRegistered
FROM 
    customer_churn
WHERE 
    PreferredPaymentMode = 'UPI';

-- --------------------------------------------------------------------------------------------------

-- 3.15. Determine the city tier with the highest number of customers.
SELECT 
    CityTier,
    COUNT(*) AS CustomerCount
FROM 
    customer_churn
GROUP BY 
    CityTier
ORDER BY 
    CustomerCount DESC
LIMIT 1;

-- --------------------------------------------------------------------------------------------------

-- 3.16. Find the marital status of customers with the highest number of addresses.

SELECT 
    MaritalStatus,
    MAX(NumberOfAddress) AS MaxAddresses
FROM 
    customer_churn
GROUP BY 
    MaritalStatus
ORDER BY 
    MaxAddresses DESC
LIMIT 1;

-- --------------------------------------------------------------------------------------------------

-- 3.17. Identify the gender that utilized the highest number of coupons.

SELECT 
    Gender,
    SUM(CouponUsed) AS TotalCouponsUsed
FROM 
    customer_churn
GROUP BY 
    Gender
ORDER BY 
    TotalCouponsUsed DESC
LIMIT 1;

-- --------------------------------------------------------------------------------------------------

-- 3.18. List the average satisfaction score in each of the preferred order categories.

SELECT 
    PreferredOrderCat,
    AVG(SatisfactionScore) AS AverageSatisfactionScore
FROM 
    customer_churn
GROUP BY 
    PreferredOrderCat;

-- --------------------------------------------------------------------------------------------------

-- 3.19. Calculate the total order count for customers who prefer using credit cards and
-- have the maximum satisfaction score.

SELECT 
    SUM(OrderCount) AS TotalOrderCount
FROM 
    customer_churn
WHERE 
    PreferredPaymentMode = 'Credit Card'
    AND SatisfactionScore = (SELECT MAX(SatisfactionScore) FROM customer_churn);

-- --------------------------------------------------------------------------------------------------

-- 3.20. How many customers are there who spent only one hour on the app and days
-- since their last order was more than 5?

SELECT 
    COUNT(*) AS CustomerCount
FROM 
    customer_churn
WHERE 
    HoursSpentOnApp = 1
    AND DaySinceLastOrder > 5;

-- --------------------------------------------------------------------------------------------------

-- 3.21. What is the average satisfaction score of customers who have complained?
SELECT 
    AVG(SatisfactionScore) AS AverageSatisfactionScore
FROM 
    customer_churn
WHERE 
    ComplaintReceived = 'Yes';

-- --------------------------------------------------------------------------------------------------

-- 3.22. How many customers are there in each preferred order category?

SELECT 
    PreferredOrderCat,
    COUNT(*) AS CustomerCount
FROM 
    customer_churn
GROUP BY 
    PreferredOrderCat;

-- --------------------------------------------------------------------------------------------------

-- 3.23. What is the average cashback amount received by married customers?

SELECT 
    AVG(CashbackAmount) AS AverageCashback
FROM 
    customer_churn
WHERE 
    MaritalStatus = 'Married';

-- --------------------------------------------------------------------------------------------------

-- 3.24. What is the average number of devices registered by customers who are not
-- using Mobile Phone as their preferred login device?

SELECT 
    AVG(NumberOfDeviceRegistered) AS AverageDevicesRegistered
FROM 
    customer_churn
WHERE 
    PreferredLoginDevice <> 'Mobile Phone';

-- --------------------------------------------------------------------------------------------------

-- 3.25. List the preferred order category among customers who used more than 5 coupons.
SELECT 
    PreferredOrderCat
FROM 
    customer_churn
WHERE 
    CouponUsed > 5;

-- --------------------------------------------------------------------------------------------------

-- 3.26. List the top 3 preferred order categories with the highest average cashback amount.

SELECT 
    PreferredOrderCat,
    AVG(CashbackAmount) AS AverageCashback
FROM 
    customer_churn
GROUP BY 
    PreferredOrderCat
ORDER BY 
    AverageCashback DESC
LIMIT 3;

-- --------------------------------------------------------------------------------------------------

-- 3.27. Find the preferred payment modes of customers whose average tenure is 10
-- months and have placed more than 500 orders.

SELECT 
    PreferredPaymentMode
FROM 
    customer_churn
WHERE 
    Tenure = 10
    AND OrderCount > 500;

-- --------------------------------------------------------------------------------------------------

-- 3.28. Categorize customers based on their distance from the warehouse to home such
-- as 'Very Close Distance' for distances <=5km, 'Close Distance' for <=10km,
-- 'Moderate Distance' for <=15km, and 'Far Distance' for >15km. Then, display the
-- churn status breakdown for each distance category.

SELECT 
    CASE 
        WHEN WarehouseToHome <= 5 THEN 'Very Close Distance'
        WHEN WarehouseToHome <= 10 THEN 'Close Distance'
        WHEN WarehouseToHome <= 15 THEN 'Moderate Distance'
        ELSE 'Far Distance'
    END AS DistanceCategory,
    ChurnStatus,
    COUNT(*) AS CustomerCount
FROM 
    customer_churn
GROUP BY 
    DistanceCategory, ChurnStatus
ORDER BY 
    DistanceCategory, ChurnStatus;

-- --------------------------------------------------------------------------------------------------

-- 3.29. List the customer’s order details who are married, live in City Tier-1, and their
-- order counts are more than the average number of orders placed by all customers.

SELECT 
    *
FROM 
    customer_churn
WHERE 
    MaritalStatus = 'Married'
    AND CityTier = 1
    AND OrderCount > (SELECT AVG(OrderCount) FROM customer_churn);

-- --------------------------------------------------------------------------------------------------

-- 3.30. a) Create a ‘customer_returns’ table in the ‘ecomm’ database and insert the following data:
-- ReturnID CustomerID ReturnDate RefundAmount
-- 1001 50022 2023-01-01 2130
-- 1002 50316 2023-01-23 2000
-- 1003 51099 2023-02-14 2290
-- 1004 52321 2023-03-08 2510
-- 1005 52928 2023-03-20 3000
-- 1006 53749 2023-04-17 1740
-- 1007 54206 2023-04-21 3250
-- 1008 54838 2023-04-30 1990


CREATE TABLE ecomm.customer_returns (
    ReturnID INT PRIMARY KEY,
    CustomerID INT,
    ReturnDate DATE,
    RefundAmount INT
);

INSERT INTO ecomm.customer_returns (ReturnID, CustomerID, ReturnDate, RefundAmount) VALUES
(1001, 50022, '2023-01-01', 2130),
(1002, 50316, '2023-01-23', 2000),
(1003, 51099, '2023-02-14', 2290),
(1004, 52321, '2023-03-08', 2510),
(1005, 52928, '2023-03-20', 3000),
(1006, 53749, '2023-04-17', 1740),
(1007, 54206, '2023-04-21', 3250),
(1008, 54838, '2023-04-30', 1990);

-- --------------------------------------------------------------------------------------------------
-- 3.30. b) Display the return details along with the customer details of those who have
-- churned and have made complaints.
SELECT 
    cr.ReturnID,
    cr.CustomerID,
    cr.ReturnDate,
    cr.RefundAmount,
    cc.ChurnStatus,
    cc.MaritalStatus,
    cc.Gender,
    cc.CityTier,
    cc.PreferredPaymentMode,
    cc.OrderCount
FROM 
    ecomm.customer_returns AS cr
JOIN 
    customer_churn AS cc ON cr.CustomerID = cc.CustomerID
WHERE 
    cc.ChurnStatus = 'Churned'
    AND cc.ComplaintReceived = 'Yes';
SELECT * FROM customer_churn;