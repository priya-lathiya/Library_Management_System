SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM members;
SELECT * FROM return_status;


-- Project Tasks:

-- Task 1. Create a New Book Record:
-- "('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher) 
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co');
SELECT * FROM books;



-- Task 2: Update an Existing Member's Address:

UPDATE members 
SET member_address = '100 Main St'
WHERE member_id = 'C101';
SELECT * FROM members;



-- Task 3: Delete a Record from the Issued Status Table 
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE issued_id = 'IS121';
SELECT * FROM issued_status;



-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101';



-- Task 5: List Members Who Have Issued More Than One Book 
-- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT * FROM issued_status;
SELECT issued_emp_id, COUNT(issued_id) AS total_books
FROM issued_status
GROUP BY issued_emp_id
HAVING COUNT(issued_id) > 1;



-- CTAS (Create Table As Select)
-- Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**

SELECT * FROM books;
SELECT * FROM issued_status;

CREATE TABLE book_summary
AS 
SELECT 
	b.isbn,
	b.book_title,
	COUNT(ib.issued_book_isbn) AS total_issued_books
FROM books AS b
JOIN issued_status as ib
ON b.isbn = ib.issued_book_isbn
GROUP BY 1, 2;

SELECT * FROM book_summary;




-- Data Analysis & Findings:
-- The following SQL queries were used to address specific questions:

-- Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books 
WHERE category = 'History';



-- Task 8: Find Total Rental Income by Category:

SELECT * FROM books;
SELECT * FROM issued_status;

SELECT b.category,
	COUNT(ib.issued_id) AS book_count,
	SUM(b.rental_price) AS total_income
FROM books AS b
JOIN issued_status AS ib
ON b.isbn = ib.issued_book_isbn
GROUP BY b.category;



-- Task 9: List Members Who Registered in the Last 180 Days:

SELECT * FROM members 
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';



-- Task 10: List Employees with Their Branch Manager's Name and their branch details:

SELECT * FROM branch;
SELECT * FROM employees;

SELECT e2.emp_name AS manager_name,
		b.*,
		e1.emp_name,
		e1.position,
		e1.salary
FROM branch AS b
JOIN employees AS e1
ON e1.branch_id = b.branch_id
JOIN employees AS e2
ON b.manager_id = e2.emp_id;



-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold :

CREATE TABLE books_price_greater_than_seven
AS 
SELECT * FROM books
WHERE rental_price > 7.00; 

SELECT * FROM books_price_greater_than_seven;



-- Task 12: Retrieve the List of Books Not Yet Returned :

SELECT * FROM issued_status;
SELECT * FROM return_status;

SELECT DISTINCT ist.issued_book_name
FROM issued_status AS ist
LEFT JOIN return_status AS rst
ON ist.issued_id = rst.issued_id
WHERE rst.return_id IS NULL;
