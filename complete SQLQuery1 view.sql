--Write SQL queries to retrieve the following information: 
--1. Library Book Inventory Report 
--Display library name, total number of books, number of available books, and number of books currently on loan for each library.  
select * from Library
select * from book
select * from members
select * from loan
select * from members
select * from staff
select * from review
select * from fine_payment
SELECT 
    l.name AS library_name,
    COUNT(b.book_id) AS total_books,
    SUM(CASE WHEN b.availability_status = 1 THEN 1 ELSE 0 END) AS available_books,
    SUM(CASE WHEN b.availability_status = 0 THEN 1 ELSE 0 END) AS books_on_loan
FROM library l
LEFT JOIN book b ON l.library_id = b.library_id
GROUP BY l.name;
--2. Active Borrowers Analysis 
--List all members who currently have books on loan (status = 'Issued' or 'Overdue'). Show member name, email, book title, loan date, due date, and current status.  
SELECT 
    m.full_name AS member_name,
    m.email,
    b.title AS book_title,
    lo.loan_date,
    lo.due_date,
    lo.status
FROM loan lo
JOIN members m ON lo.member_id = m.member_id
JOIN book b ON lo.book_id = b.book_id
WHERE lo.status IN ('Issued', 'Overdue');

--3. Overdue Loans with Member Details 
--Retrieve all overdue loans showing member name, phone number, book title, library name, days overdue (calculated as difference between current date and due date), and 
--any fines paid for that loan.  
SELECT 
    m.full_name AS member_name,
    m.phone_number,
    b.title AS book_title,
    l.name AS library_name,
    DATEDIFF(DAY, lo.due_date, GETDATE()) AS days_overdue,
    ISNULL(SUM(fp.amount), 0) AS fine_paid
FROM loan lo
JOIN members m ON lo.member_id = m.member_id
JOIN book b ON lo.book_id = b.book_id
JOIN library l ON b.library_id = l.library_id
LEFT JOIN fine_payment fp ON lo.loan_id = fp.loan_id
WHERE lo.status = 'Overdue'
GROUP BY 
    m.full_name, m.phone_number, b.title, l.name, lo.due_date;

--4. Staff Performance Overview 
--For each library, show the library name, staff member names, their positions, and count of books managed at that library.  
SELECT 
    l.name AS library_name,
    s.full_name AS staff_name,
    s.position,
    COUNT(b.book_id) AS books_managed
FROM staff s
JOIN library l ON s.library_id = l.library_id
LEFT JOIN book b ON l.library_id = b.library_id
GROUP BY 
    l.name, s.full_name, s.position;

--5. Book Popularity Report 
--Display books that have been loaned at least 3 times. Include book title, ISBN, genre, total number of times loaned, and average review rating (if any reviews exist).  
SELECT 
    b.title,
    b.ISBN,
    b.genre,
    COUNT(lo.loan_id) AS times_loaned,
    AVG(r.rating) AS avg_rating
FROM book b
JOIN loan lo ON b.book_id = lo.book_id
LEFT JOIN review r ON b.book_id = r.book_id
GROUP BY 
    b.book_id, b.title, b.ISBN, b.genre
HAVING COUNT(lo.loan_id) >= 3;
--6. Member Reading History 
--Create a query that shows each member's complete borrowing history including: 
--member name, book titles borrowed (including currently borrowed and previously returned), loan dates, return dates, and any reviews they left for those books.  
SELECT 
    m.full_name AS MemberName,
    b.title AS BookTitle,
    l.loan_date,
    l.return_date,
    r.rating AS ReviewRating,
    r.comments AS ReviewComments
FROM members m
JOIN loan l ON m.member_id = l.member_id
JOIN book b ON l.book_id = b.book_id
LEFT JOIN review r 
    ON m.member_id = r.member_id 
    AND b.book_id = r.book_id
ORDER BY m.full_name, l.loan_date;






--7. Revenue Analysis by Genre 
--Calculate total fine payments collected for each book genre. Show genre name, total number of loans for that genre, total fine amount collected, and average fine per loan. 
SELECT 
    b.genre,
    COUNT(lo.loan_id) AS total_loans,
    SUM(fp.amount) AS total_fines_collected,
    AVG(fp.amount) AS average_fine_per_loan
FROM book b
JOIN loan lo ON b.book_id = lo.book_id
LEFT JOIN fine_payment fp ON lo.loan_id = fp.loan_id
GROUP BY b.genre;

--Write queries using aggregate functions and GROUP BY: 
--8. Monthly Loan Statistics 
--Generate a report showing the number of loans issued per month for the current year. 
--Include month name, total loans, total returned, and total still issued/overdue.  
SELECT 
    DATENAME(MONTH, loan_date) AS MonthName,
    COUNT(*) AS TotalLoans,
    SUM(CASE WHEN status = 'Returned' THEN 1 ELSE 0 END) AS TotalReturned,
    SUM(CASE WHEN status IN ('Issued','Overdue') THEN 1 ELSE 0 END) AS TotalActive
FROM loan
WHERE YEAR(loan_date) = YEAR(GETDATE())
GROUP BY DATENAME(MONTH, loan_date), MONTH(loan_date)
ORDER BY MONTH(loan_date);

--9. Member Engagement Metrics 
--For each member, calculate: total books borrowed, total books currently on loan, total 
--fines paid, and average rating they give in reviews. Only include members who have borrowed at least one book.  
SELECT 
    m.member_id,
    m.full_name,
    COUNT(l.loan_id) AS TotalBooksBorrowed,
    SUM(CASE WHEN l.status IN ('Issued','Overdue') THEN 1 ELSE 0 END) AS TotalBooksOnLoan,
    ISNULL(SUM(fp.amount),0) AS TotalFinesPaid,
    ISNULL(AVG(r.rating),0) AS AvgRatingGiven
FROM members m
JOIN loan l ON m.member_id = l.member_id
LEFT JOIN fine_payment fp ON l.loan_id = fp.loan_id
LEFT JOIN review r ON m.member_id = r.member_id
GROUP BY m.member_id, m.full_name
HAVING COUNT(l.loan_id) > 0
ORDER BY m.member_id;

--10. Library Performance Comparison 
--Compare libraries by showing: library name, total books owned, total active members (members with at least one loan), total revenue from fines, and average books per member.  
SELECT 
    lib.name AS LibraryName,
    COUNT(b.book_id) AS TotalBooksOwned,
    COUNT(DISTINCT l.member_id) AS TotalActiveMembers,
    ISNULL(SUM(fp.amount),0) AS TotalRevenueFromFines,
    CASE 
        WHEN COUNT(DISTINCT l.member_id) = 0 THEN 0
        ELSE CAST(COUNT(b.book_id) AS FLOAT)/COUNT(DISTINCT l.member_id)
    END AS AvgBooksPerMember
FROM library lib
LEFT JOIN book b ON lib.library_id = b.library_id
LEFT JOIN loan l ON b.book_id = l.book_id
LEFT JOIN fine_payment fp ON l.loan_id = fp.loan_id
GROUP BY lib.name;

--11. High-Value Books Analysis 
--Identify books priced above the average book price in their genre. Show book title, genre, price, genre average price, and difference from average.  
WITH GenreAvg AS (
    SELECT 
        genre,
        AVG(price) AS AvgPrice
    FROM book
    GROUP BY genre
)
SELECT 
    b.title,
    b.genre,
    b.price,
    g.AvgPrice AS GenreAvgPrice,
    b.price - g.AvgPrice AS DifferenceFromAvg
FROM book b
JOIN GenreAvg g ON b.genre = g.genre
WHERE b.price > g.AvgPrice
ORDER BY b.genre, DifferenceFromAvg DESC;
--12. Payment Pattern Analysis 
--Group payments by payment method and show: payment method, number of transactions, total amount collected, average payment amount, and percentage of total revenue.  
SELECT
    payment_method,
    COUNT(*) AS number_of_transactions,
    SUM(amount) AS total_amount_collected,
    AVG(amount) AS average_payment_amount,
    (SUM(amount) * 100.0 / SUM(SUM(amount)) OVER ()) AS percentage_of_total_revenue
FROM fine_payment
GROUP BY payment_method;
--Create the following views: 
--13. vw_CurrentLoans 
--A view that shows all currently active loans (status 'Issued' or 'Overdue') with member details, book details, loan information, and calculated days until due (or days overdue).  
CREATE VIEW vw_CurrentLoans AS
SELECT 
    l.loan_id,
    m.member_id,
    m.full_name AS MemberName,
    m.email,
    m.phone_number,
    b.book_id,
    b.title AS BookTitle,
    b.genre,
    b.shelf_location,
    l.loan_date,
    l.due_date,
    l.status,
    CASE 
        WHEN l.due_date >= GETDATE() THEN DATEDIFF(DAY, GETDATE(), l.due_date)
        ELSE -DATEDIFF(DAY, l.due_date, GETDATE()) 
    END AS DaysUntilDueOrOverdue
FROM loan l
JOIN members m ON l.member_id = m.member_id
JOIN book b ON l.book_id = b.book_id
WHERE l.status IN ('Issued','Overdue');

select * from vw_CurrentLoans
--14. vw_LibraryStatistics 
--A comprehensive view showing library-level statistics including total books, available books, total members, active loans, total staff, and total revenue from fines.  
CREATE VIEW vw_LibraryStatistics AS
SELECT 
    lib.library_id,
    lib.name AS LibraryName,
    COUNT(DISTINCT b.book_id) AS TotalBooks,
    SUM(CASE WHEN b.availability_status = 1 THEN 1 ELSE 0 END) AS AvailableBooks,
    COUNT(DISTINCT m.member_id) AS TotalMembers,
    SUM(CASE WHEN l.status IN ('Issued','Overdue') THEN 1 ELSE 0 END) AS ActiveLoans,
    COUNT(DISTINCT s.staff_id) AS TotalStaff,
    ISNULL(SUM(fp.amount),0) AS TotalRevenueFromFines
FROM library lib
LEFT JOIN book b ON lib.library_id = b.library_id
LEFT JOIN loan l ON b.book_id = l.book_id
LEFT JOIN members m ON l.member_id = m.member_id
LEFT JOIN staff s ON lib.library_id = s.library_id
LEFT JOIN fine_payment fp ON l.loan_id = fp.loan_id
GROUP BY lib.library_id, lib.name;
select * from vw_LibraryStatistics
--15. vw_BookDetailsWithReviews 
--A view combining book information with aggregated review data (average rating, total reviews, latest review date) and current availability status.  
CREATE VIEW vw_BookDetailsWithReviews AS
SELECT
    b.book_id,
    b.title,
    b.genre,
    b.price,
    b.availability_status,
    AVG(r.rating) AS average_rating,
    COUNT(r.review_id) AS total_reviews,
    MAX(r.review_date) AS latest_review_date
FROM book b
LEFT JOIN review r
    ON b.book_id = r.book_id
GROUP BY
    b.book_id,
    b.title,
    b.genre,
    b.price,
    b.availability_status;
select * from vw_BookDetailsWithReviews
--Create stored procedures for the following operations: 
--16. sp_IssueBook 
--Input Parameters: MemberID, BookID, DueDate  
--Functionality:  
--• Check if book is available 
--• Check if member has any overdue loans 
--• If validations pass, create a new loan record and update book availability 
--• Return appropriate success or error message 
CREATE PROCEDURE sp_IssueBook
    @MemberID INT,
    @BookID INT,
    @DueDate DATE
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRANSACTION;

    -- 1. Check book availability
    IF NOT EXISTS (
        SELECT 1 FROM book 
        WHERE book_id = @BookID AND availability_status = 1
    )
    BEGIN
        ROLLBACK;
        RAISERROR('Book is not available.', 16, 1);
        RETURN;
    END

    -- 2. Check overdue loans for member
    IF EXISTS (
        SELECT 1 FROM loan
        WHERE member_id = @MemberID AND status = 'Overdue'
    )
    BEGIN
        ROLLBACK;
        RAISERROR('Member has overdue loans.', 16, 1);
        RETURN;
    END

    -- 3. Insert loan
    INSERT INTO loan (member_id, book_id, loan_date, due_date, status)
    VALUES (@MemberID, @BookID, GETDATE(), @DueDate, 'Issued');

    -- 4. Update book availability
    UPDATE book
    SET availability_status = 0
    WHERE book_id = @BookID;

    COMMIT;

    PRINT 'Book issued successfully.';
END;
EXEC sp_IssueBook 1, 2, '2025-01-15';
--17. sp_ReturnBook 
--Input Parameters: LoanID, ReturnDate  
--Functionality:  
--• Update loan status to 'Returned' and set return date 
--• Update book availability to TRUE 
--• Calculate if there's a fine (e.g., $2 per day overdue) 
--• If fine exists, automatically create a payment record with 'Pending' status 
--• Return total fine amount (if any) 
CREATE PROCEDURE sp_ReturnBook
    @loanid INT,--????????? ????? ????????? ???? ?? @
    @returndate date--????????? ????? ????????? ???? ?? @
AS
BEGIN--????? ??? ??? Procedure
    SET NOCOUNT ON;--??? SQL Server ?? ????? ??? ?????? ???????? ??? ??? (?????? ???????)
	DECLARE @DueDate DATE;--????? ??????? ?????????
    DECLARE @BookID INT;--??? ?????? ??????? ??????????
    DECLARE @DaysOverdue INT;--??? ?????? ????????
    DECLARE @FineAmount DECIMAL(10,2);--???? ??????? ????????
    BEGIN TRANSACTION;--???? ?? ????????? ????? ?????-- ??? ????????

--?? ??? ??? ? ???? ???? ROLLBACK

SELECT --  -- ??? ?????? ?????????
    @DueDate = due_date,--due_date ? ????? ???????
    @BookID = book_id--book_id ? ?????? ???? ??????
FROM loan
WHERE loan_id = @loanid;--???? ??? ????? ?? ????????? ??????? ??????

UPDATE loan--????? ???? ?????????
SET return_date = @returndate,--???? ????? ???????
status = 'Returned'--????????? ????? ??????
WHERE loan_id = @loanid;

UPDATE book--????? ???? ??????
SET availability_status = 1--1 ???? ???? ???????
WHERE book_id = @BookID;--???? ?? ?????? ???? ????????? ???????

-- ???? ???????
SET @DaysOverdue = DATEDIFF(DAY, @DueDate, @ReturnDate);
IF @DaysOverdue > 0--?? ??? ?????
BEGIN
SET @FineAmount = @DaysOverdue * 2;  --??????? = 2 ????? × ?????? ???????? 

INSERT INTO fine_payment (loan_id, payment_date, amount, payment_method)--???? ??? ??? ???? ???????
VALUES (@LoanID, GETDATE(), @FineAmount, 'Pending');   --payment_method = 'Pending'????? ?? ???? ???
   
COMMIT;--????? ?????????
SELECT @FineAmount AS FineAmount;--???? ???????
RETURN;--???? Procedure ??? ????? ??? ??????
END;
--?? ?? ??? ?????
COMMIT;--?? ????????? ???? 
SELECT 0 AS FineAmount;--?? ???? ????? ? ???? 0
END;
EXEC sp_ReturnBook
    @LoanID = 2,
    @ReturnDate = '2023-04-18';
--18. sp_GetMemberReport 
--Input Parameters: MemberID  
--Output: Multiple result sets showing:  
--• Member basic information 
--• Current loans (if any) 
--• Loan history with return status 
--• Total fines paid and any pending fines 
--• Reviews written by the member 
CREATE PROCEDURE sp_GetMemberReport --“???? ?? Stored Procedure ????? sp_GetMemberReport”
    @MemberID INT--??? Input Parameter--????: ???????? ???? ???? ??? ?????????? ?????? ?? ?? WHERE
AS
BEGIN
    SET NOCOUNT ON;
-- 1?-Member basic information
select * from members--??????? ????? ???????? ?? ???? members
where member_id=@MemberID;--???? ??? ???? ???
--2-Current loans (if any)
SELECT 
     b.title AS book_title,
     l.loan_date,
     l.due_date,
     l.status
FROM loan l
JOIN book b ON l.book_id = b.book_id
WHERE l.member_id = @MemberID
AND l.status IN ('Issued', 'Overdue');--?????:????? ???? ??? ?? ??????? ??????
--3- Loan history
SELECT 
     b.title AS book_title,
     l.loan_date,
     l.return_date,
     l.status
FROM loan l
JOIN book b ON l.book_id = b.book_id
WHERE l.member_id = @MemberID
--4- Total fines paid & pending fines 
SELECT 
        payment_method,
        COUNT(*) AS total_payments,--??? ?????? ?????
        SUM(amount) AS total_amount--????? ????????
    FROM fine_payment fp
    JOIN loan l ON fp.loan_id = l.loan_id
    WHERE l.member_id = @MemberID
    GROUP BY payment_method;

-- 5?- Reviews written by the member
    SELECT 
        b.title AS book_title,
        r.rating,
        r.comments,
        r.review_date
    FROM review r
    JOIN book b ON r.book_id = b.book_id
    WHERE r.member_id = @MemberID;
END;
 EXEC sp_GetMemberReport @MemberID = 1;


--19. sp_MonthlyLibraryReport 
--Input Parameters: LibraryID, Month, Year  
--Output: Comprehensive report showing:  
--• Total loans issued in that month 
--• Total books returned in that month 
--• Total revenue collected 
--• Most borrowed genre 
--• Top 3 most active members (by number of loans)
CREATE PROCEDURE sp_MonthlyLibraryReport --“???? ?? Stored Procedure ????? sp_MonthlyLibraryReport”
    @LibraryID INT,
	@Month INT,
	@year INT
AS
BEGIN
    SET NOCOUNT ON;
--1- Total loans issued
SELECT COUNT(*) AS TotalLoansIssued
    FROM loan l
    JOIN book b ON l.book_id = b.book_id
    WHERE b.library_id = @LibraryID
      AND MONTH(l.loan_date) = @Month
      AND YEAR(l.loan_date) = @Year;

-- 2?- Total books returned
SELECT COUNT(*) AS TotalBooksReturned
    FROM loan l
    JOIN book b ON l.book_id = b.book_id
    WHERE b.library_id = @LibraryID
      AND l.return_date IS NOT NULL
      AND MONTH(l.return_date) = @Month
      AND YEAR(l.return_date) = @Year;

-- 3?- Total revenue collected
    SELECT SUM(fp.amount) AS TotalRevenue
    FROM fine_payment fp
    JOIN loan l ON fp.loan_id = l.loan_id
    JOIN book b ON l.book_id = b.book_id
    WHERE b.library_id = @LibraryID
      AND MONTH(fp.payment_date) = @Month
      AND YEAR(fp.payment_date) = @Year;

-- 4?- Most borrowed genre
    SELECT TOP 1
        b.genre,
        COUNT(*) AS TotalLoans
    FROM loan l
    JOIN book b ON l.book_id = b.book_id
    WHERE b.library_id = @LibraryID
    GROUP BY b.genre
    ORDER BY COUNT(*) DESC;

-- 5?-Top 3 most active members
    SELECT TOP 3
        m.full_name,
        COUNT(*) AS TotalLoans
    FROM loan l
    JOIN members m ON l.member_id = m.member_id
    JOIN book b ON l.book_id = b.book_id
    WHERE b.library_id = @LibraryID
    GROUP BY m.full_name
    ORDER BY COUNT(*) DESC;
END;
EXEC sp_MonthlyLibraryReport 
    @LibraryID = 1,
    @Month = 4,
    @Year = 2023;
