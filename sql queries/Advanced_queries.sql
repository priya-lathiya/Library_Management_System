-- ADVANCED QUERIES:

/*
Task 13: Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period).
Display the member's_id, member's name, book title, issue date, and days overdue.
*/

SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM books;

SELECT m.member_name,
		m.member_id,
		ist.issued_book_name,
		ist.issued_date,
		rst.return_date,
		(COALESCE(rst.return_date, CURRENT_DATE) - ist.issued_date) - 30 AS days_overdue
FROM issued_status AS ist
JOIN members AS m
ON m.member_id = ist.issued_member_id
LEFT JOIN return_status AS rst
ON ist.issued_id = rst.issued_id
WHERE COALESCE(return_date, CURRENT_DATE) > issued_date + INTERVAL '30 days';



/*    
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

-- Stored Procedure: 
CREATE OR REPLACE PROCEDURE add_return_recored (p_return_id VARCHAR(10), p_issued_id VARCHAR(10))

LANGUAGE plpgsql

AS $$ 

DECLARE 

	v_isbn VARCHAR(50);
	v_name VARCHAR(80);
	
BEGIN
	-- inserting into issued status table based on users input.
	INSERT INTO return_status (return_id, issued_id, return_date)
	VALUES 
	(p_return_id, p_issued_id, CURRENT_DATE);

	SELECT 
		issued_book_isbn,
		issued_book_name
		INTO 
		v_isbn,
		v_name
	FROM issued_status
	WHERE issued_id = p_issued_id;

	UPDATE books
	SET status = 'yes'
	WHERE isbn = v_isbn;

	RAISE NOTICE 'Thank you for returning book: %', v_name;
END;

$$ 


-- Testing function add_return_recored
SELECT * FROM books
WHERE isbn = '978-0-375-41398-8';

SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-375-41398-8';

SELECT * FROM return_status
WHERE issued_id = 'IS134';

-- calling function: 
CALL add_return_recored('RS119', 'IS134');



/*
Task 15: Branch Performance Report: 
Create a query that generates a performance report for each branch, showing the number of books issued, 
the number of books returned, and the total revenue generated from book rentals.
*/

SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;

CREATE TABLE branch_reports
AS
SELECT 
	b.branch_id,
	COUNT(ist.issued_id) AS total_issued_books,
	COUNT(rst.return_id) AS total_returned_books,
	SUM(bk.rental_price) AS total_revenue
FROM issued_status as ist
JOIN employees as e
ON e.emp_id = ist.issued_emp_id
JOIN branch as b
ON b.branch_id = e.branch_id
LEFT JOIN return_status as rst
ON rst.issued_id = ist.issued_id
JOIN books as bk
ON bk.isbn = ist.issued_book_isbn
GROUP BY 1;

SELECT * FROM branch_reports;



/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing 
members who have issued at least one book in the last 6 months.
*/

SELECT * FROM issued_status;

CREATE TABLE active_members
AS 
SELECT * FROM members
WHERE member_id IN (SELECT issued_member_id
					FROM issued_status
					WHERE issued_date >= CURRENT_DATE - INTERVAL '6 month'
					)
;


SELECT * FROM active_members;



/* Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.
*/

SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;

SELECT e.emp_name,
	COUNT(ist.issued_id) AS no_of_books_issued,
	b.branch_address
FROM employees AS e
JOIN issued_status AS ist
ON ist.issued_emp_id = e.emp_id
JOIN branch as b
ON b.branch_id = e.branch_id
GROUP BY e.emp_name, b.branch_address
ORDER BY no_of_books_issued DESC
LIMIT 3;



/* Task 18: 

Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system.

Description: Write a stored procedure that updates the status of a book in the library based on its issuance. 

The procedure should function as follows:
	The stored procedure should take the book_id as an input parameter. 
	The procedure should first check if the book is available (status = 'yes'). 
	If the book is available, it should be issued, and the status in the books table should be updated to 'no'. 
	If the book is not available (status = 'no'),
	the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE issue_book(p_issued_id VARCHAR(10), p_issued_member_id VARCHAR(10),
p_issued_book_isbn VARCHAR(30), p_issued_emp_id VARCHAR(10))

LANGUAGE plpgsql

AS $$ 

DECLARE 
	v_status VARCHAR(10);

BEGIN
	-- checking if the status is "yes"
	SELECT status
		INTO
		v_status
	FROM books 
	WHERE isbn = p_issued_book_isbn;

	IF v_status = 'yes' THEN 

		INSERT INTO issued_status(issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
		VALUES 
		(p_issued_id, p_issued_member_id, CURRENT_DATE, p_issued_book_isbn, p_issued_emp_id);
	
		UPDATE books
		SET status = 'no'
		WHERE isbn = p_issued_book_isbn;
	
		RAISE NOTICE 'Book record is added successfully for book_isbn: %', p_issued_book_isbn;


	ELSE
	
		RAISE NOTICE 'Sorry, Book is not available for book_isbn: %', p_issued_book_isbn;


	END IF;

END;
$$ 

-- check the function issued_status():

SELECT * FROM books;
-- for status 'yes': "978-0-679-76489-8"
-- for status 'no': "978-0-307-58837-1"
SELECT * FROM issued_status;

-- for status = 'yes': 
CALL issue_book('IS141', 'C109', '978-0-679-76489-8', 'E105');

SELECT * FROM books 
WHERE isbn = '978-0-679-76489-8'; 

-- for status = 'no': 
CALL issue_book('IS141', 'C109', '978-0-307-58837-1', 'E105');

SELECT * FROM books 
WHERE isbn = '978-0-307-58837-1'; 




/*
Task 19: 

Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description:
	Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. 
	
The table should include:
	The number of overdue books. 
	The total fines, with each day's fine calculated at $0.50. 
	The number of books issued by each member. 
	The resulting table should show: Member ID, Number of overdue books, Total fines
*/

SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;

CREATE TABLE overdue_books_fines AS
SELECT 
    m.member_id,
    COUNT(*) AS overdue_books,
    SUM(GREATEST((COALESCE(rst.return_date, CURRENT_DATE) - ist.issued_date) - 30, 0) * 0.50) AS total_fine,
    COUNT(*) AS total_books_issued
FROM issued_status AS ist
JOIN members AS m
    ON m.member_id = ist.issued_member_id
LEFT JOIN return_status AS rst
    ON ist.issued_id = rst.issued_id
WHERE COALESCE(rst.return_date, CURRENT_DATE) > ist.issued_date + INTERVAL '30 days'
GROUP BY m.member_id;

SELECT * FROM overdue_books_fines;


