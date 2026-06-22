-- Create Tables
DROP TABLE IF EXISTS Books;
CREATE TABLE Books (
    Book_ID SERIAL PRIMARY KEY,
    Title VARCHAR(100),
    Author VARCHAR(100),
    Genre VARCHAR(50),
    Published_Year INT,
    Price NUMERIC(10, 2),
    Stock INT
);
DROP TABLE IF EXISTS customers;
CREATE TABLE Customers (
    Customer_ID SERIAL PRIMARY KEY,
    Name VARCHAR(100),
    Email VARCHAR(100),
    Phone VARCHAR(15),
    City VARCHAR(50),
    Country VARCHAR(150)
);
DROP TABLE IF EXISTS orders;
CREATE TABLE Orders (
    Order_ID SERIAL PRIMARY KEY,
    Customer_ID INT REFERENCES Customers(Customer_ID),
    Book_ID INT REFERENCES Books(Book_ID),
    Order_Date DATE,
    Quantity INT,
    Total_Amount NUMERIC(10, 2)
);

SELECT * FROM Books;
SELECT * FROM Customers;
SELECT * FROM Orders;

--Basic Questions

-- 1) Retrieve all books in the "Fiction" genre:
select * from books where genre = 'Fiction';


-- 2) Find books published after the year 1950:
select * from books where published_year > 1950;

-- 3) List all customers from the Canada:
select * from customers where country = 'Canada';

-- 4) Show orders placed in November 2023:
select * from orders 
where order_date >= '2023-11-01' 
and 
order_date < '2023-12-01';

-- 5) Retrieve the total stock of books available:
select sum(stock) as total_stock from books;

-- 6) Find the details of the most expensive book:
select * from books 
where 
price = (select max(price) from books);

-- 7) Show all customers who ordered more than 1 quantity of a book:
select c.name, c.email, c.phone, o.quantity from customers c
inner join orders o
on c.customer_id = o.customer_id
where o.quantity > 1;

-- 8) Retrieve all orders where the total amount exceeds $20:
select * from orders where total_amount > 20.00;

-- 9) List all genres available in the Books table:
select distinct genre from books;

-- 10) Find the book with the lowest stock:
select * from books 
where 
stock = (select min(stock) from books);

-- 11) Calculate the total revenue generated from all orders:
select sum(total_amount) as total_revenue from orders;

-- Intermediate Questions 

-- 1) Retrieve the total number of books sold for each genre:
select distinct b.genre, sum(o.quantity) as total_books_sold
from books b 
inner join orders o
on b.book_id = o.book_id
group by b.genre;

-- 2) Find the average price of books in the "Fantasy" genre:
select genre, round(avg(price), 2) as avg_price
from books 
where genre = 'Fantasy'
group by genre;

-- 3) List customers who have placed at least 2 orders:
select distinct c.name, c.email, c.phone, o.quantity
from customers c
inner join orders o
on c.customer_id = o.customer_id
where o.quantity > 2;

-- 4) Find the most frequently ordered book:
select distinct b.title, b.author, b.genre, b.price, sum(o.quantity) as total_ordered
from books b
inner join orders o
on b.book_id = o.book_id
group by b.title, b.author, b.genre, b.price
order by sum(o.quantity) desc limit 1;

-- 5) Show the top 3 most expensive books of 'Fantasy' Genre :
select title, genre, price 
from books where genre = 'Fantasy'
order by price desc limit 3;

-- 6) Retrieve the total quantity of books sold by each author:
select b.author, sum(o.quantity)
from books b
inner join orders o on
b.book_id = o.book_id
group by b.author
order by sum(o.quantity) desc;

-- 7) List the cities where customers who spent over $30 are located:
select c.city, c.country from customers c
inner join orders o
on c.customer_id = o.customer_id
where o.total_amount > 30;

-- 8) Find the customer who spent the most on orders:
select c.name, sum(o.total_amount) as total_spent
from customers c
inner join orders o
on c.customer_id = o.customer_id
group by c.name
order by total_spent desc limit 1;

--9) Calculate the stock remaining after fulfilling all orders:
select distinct b.title, o.quantity, b.stock as ordered_qty, (b.stock - o.quantity) as remaining_stock
from books b
inner join orders o
on b.book_id = o.book_id;

--Advanced Questions

--1. Top 10 Customers by Revenue
with customer_revenue as (
	select c.customer_id, c.name, sum(o.total_amount) as revenue
from customers c
inner join orders o
on c.customer_id = o.customer_id
group by c.customer_id, c.name
)
select *, rank() over(order by revenue desc) as revenue_rank
from customer_revenue limit 10;

--2. Top 3 Selling Books by Genre
with book_sales as (
	select b.genre, b.title, sum(o.quantity) as books_sold
from books b
inner join orders o
on b.book_id = o.book_id
group by b.genre, b.title
)
select * from (
	select *, row_number() over(partition by genre order by books_sold desc) as rn
	from book_sales
) x
where rn <= 3;

--3. Revenue Contribution by Genre
select
    b.genre,
    ROUND(
        sum(o.total_amount) * 100.0 /
        sum(sum(o.total_amount)) over (),
        2
    ) as revenue_pct
from books b
inner join orders o
on b.book_id = o.book_id
group by b.genre;

--4. Customer Segmentation
select
    customer_id,
    sum(total_amount) as total_spend,
    case
        when sum(total_amount) > 500 then 'High Value'
        when sum(total_amount) > 250 then 'Medium Value'
        else 'Low Value'
    end as customer_segment
from orders
group by customer_id;

--5. Running Revenue Trend
with daily_sales as (
    select
        order_date,
        sum(total_amount) as revenue
    from orders
    group by order_date
)
select
    order_date,
    revenue,
    sum(revenue) over(
        order by order_date
    ) as cumulative_revenue
from daily_sales;

--6. Inventory Risk Analysis
select
    title,
    stock,
    case
        when stock < 20 then 'Critical'
        when stock < 50 then 'Medium'
        else 'Healthy'
    end as inventory_status
from books;

--7. Country-wise Revenue
select
    c.country,
    sum(o.total_amount) as revenue
from customers c
join orders o
on c.customer_id = o.customer_id
group by c.country
order by revenue desc;

--8. Best selling Author
select
    b.author,
    sum(o.quantity) as books_sold
from books b
join orders o
on b.book_id = o.book_id
group by b.author
order by books_sold desc limit 10;
