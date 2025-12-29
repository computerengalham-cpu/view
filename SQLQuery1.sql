create database taskbanksystem
CREATE TABLE Customer ( 
CustomerID INT PRIMARY KEY, 
FullName NVARCHAR(100), 
Email NVARCHAR(100), 
Phone NVARCHAR(15), 
SSN CHAR(9) 
); 
CREATE TABLE Account ( 
    AccountID INT PRIMARY KEY, 
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID), 
    Balance DECIMAL(10, 2), 
    AccountType VARCHAR(50), 
    Status VARCHAR(20) 
); 
 
CREATE TABLE banktransaction ( 
    TransactionID INT PRIMARY KEY, 
    AccountID INT FOREIGN KEY REFERENCES Account(AccountID), 
    Amount DECIMAL(10, 2), 
    Type VARCHAR(10), -- Deposit, Withdraw 
    TransactionDate DATETIME 
); 
 
CREATE TABLE Loan ( 
    LoanID INT PRIMARY KEY, 
    CustomerID INT FOREIGN KEY REFERENCES Customer(CustomerID), 
    LoanAmount DECIMAL(12, 2), 
    LoanType VARCHAR(50), 
    Status VARCHAR(20) 
); 
INSERT INTO Customer VALUES
(1, 'Ahmed Ali', 'ahmed@email.com', '0551234567', '123456789'),
(2, 'Sara Hassan', 'sara@email.com', '0559876543', '987654321');

INSERT INTO Account VALUES
(101, 1, 15000.00, 'Savings', 'Active'),
(102, 2, 5000.00, 'Checking', 'Active');

INSERT INTO banktransaction VALUES
(1001, 101, 2000.00, 'Deposit', GETDATE()),
(1002, 101, 500.00, 'Withdraw', GETDATE());

INSERT INTO Loan VALUES
(201, 1, 100000.00, 'Home Loan', 'Approved'),
(202, 2, 30000.00, 'Car Loan', 'Pending');

--1. Customer Service View 
-- Show only customer name, phone, and account status (hide sensitive info like SSN or balance). 
CREATE VIEW vw_CustomerServiceView
AS
SELECT 
    c.FullName,
    c.Phone,
    a.Status
FROM Customer c
JOIN Account a ON c.CustomerID = a.CustomerID;

--2. Finance Department View 
--Show account ID, balance, and account type. 
CREATE VIEW vw_FinanceView
AS
SELECT 
    AccountID,
    Balance,
    AccountType
FROM Account;

--3. Loan Officer View 
--Show loan details but hide full customer information. Only include CustomerID. 
CREATE VIEW vw_LoanOfficerView
AS
SELECT 
    LoanID,
    CustomerID,
    LoanAmount,
    LoanType,
    Status
FROM Loan;

--4. Transaction Summary View 
-- Show only recent transactions (last 30 days) with account ID and amount. 
CREATE VIEW vw_RecentTransactions
AS
SELECT 
    AccountID,
    Amount
FROM banktransaction
WHERE TransactionDate >= DATEADD(DAY, -30, GETDATE());

