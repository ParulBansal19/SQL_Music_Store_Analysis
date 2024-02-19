--Who is the senior most employee based on the job title?--

SELECT first_name, last_name, title
FROM employee$
ORDER BY levels DESC

--Which countries have the most invoices?--

SELECT COUNT(*) AS c, billing_country 
FROM invoice$
GROUP BY billing_country
ORDER BY c DESC

--What are top 3 values of total invoices?--

SELECT TOP 3 total
FROM invoice$
ORDER BY total DESC


--Which city has the best customers? We would like to throw a promotional Music Festival in the city we made the most money. 
--Write a query that returns one city that has the highest sum of invoice totals. Return both the city name & sum of all invoice totals */

SELECT TOP 1 SUM(total) AS InvoiceTotal, billing_city
FROM invoice$
GROUP BY billing_city 
ORDER BY InvoiceTotal DESC

--Who is the best customer? The customer who has spent the most money will be declared the best customer. 
--Write a query that returns the person who has spent the most money.*/

SELECT TOP 2 cu.customer_id, cu.first_name, cu.last_name, SUM(inv.total) AS Total_Spending 
FROM customer$ AS cu 
INNER JOIN invoice$ AS inv
ON cu.customer_id = inv.customer_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name
ORDER BY Total_Spending DESC

--Write query to return the email, first name, last name, & Genre of all Rock Music listeners. 
--Return your list ordered alphabetically by email starting with A. */

SELECT DISTINCT first_name AS Firstname, last_name AS Lastname, email AS Email, ge.name AS Gename
FROM [Music_Database].[dbo].[customer$] AS cm
INNER JOIN [Music_Database].[dbo].[invoice$] AS inv
ON cm.customer_id = inv.customer_id
INNER JOIN [Music_Database].[dbo].[invoice_line$] AS inl
ON inv.invoice_id = inl.invoice_id
INNER JOIN [Music_Database].[dbo].[track$] AS tr
ON inl.track_id = tr.track_id
INNER JOIN [Music_Database].[dbo].[genre$] AS ge
ON tr.genre_id = ge.genre_id
WHERE ge.name Like 'Rock'
Order by email

--Let's invite the artists who have written the most rock music in our dataset. Write a query that returns the Artist name and total track count of the top 10 rock bands. 

SELECT TOP 10 ar.name, ar.artist_id, count(ar.artist_id) AS Number_of_songs
FROM [Music_Database].[dbo].[track$] AS tr
	INNER JOIN [Music_Database].[dbo].[album2$] AS al
	ON al.album_id = tr.album_id
INNER JOIN [Music_Database].[dbo].[artist$] AS ar
ON ar.artist_id = al.artist_id
	INNER JOIN [Music_Database].[dbo].[genre$] AS ge
	ON ge.genre_id = tr.genre_id
WHERE ge.name LIKE 'Rock'
GROUP BY ar.artist_id, ar.name
ORDER BY Number_of_songs DESC

--Return all the track names that have a song length longer than the average song length. 
--Return the Name and Milliseconds for each track. Order by the song length with the longest songs listed first. */

SELECT tr.name, tr.milliseconds
FROM [Music_Database].[dbo].[track$] AS tr
WHERE milliseconds > (
					SELECT AVG(milliseconds) AS Avg_Song_Length
					FROM [Music_Database].[dbo].[track$] )
ORDER BY milliseconds DESC

--Find how much amount spent by each customer on artists? Write a query to return customer name, artist name and total spent */

WITH best_selling_artist AS (
							SELECT TOP 3 ar.artist_id AS artist_id, ar.name AS artist_name, SUM(Inl.unit_price*Inl.quantity) AS Total_Sales
							FROM [Music_Database].[dbo].[invoice_line$] AS Inl
								JOIN [Music_Database].[dbo].[track$] AS tr
								ON tr.track_id = Inl.track_id
								JOIN [Music_Database].[dbo].[album2$] AS al
								ON al.album_id = tr.album_id
								JOIN [Music_Database].[dbo].[artist$] AS ar
								ON ar.artist_id = al.artist_id
							GROUP BY ar.artist_id, ar.name
							ORDER BY Total_Sales DESC
)
SELECT TOP 5 cu.customer_id, cu.first_name, cu.last_name, bsa.artist_name, SUM(Inl.unit_price*Inl.quantity) AS Amount_Spent
FROM [Music_Database].[dbo].[invoice$] AS iv
	JOIN [Music_Database].[dbo].[customer$] AS cu ON cu.customer_id = iv.customer_id
	JOIN [Music_Database].[dbo].[invoice_line$] AS Inl ON Inl.invoice_id = iv.invoice_id
	JOIN [Music_Database].[dbo].[track$] AS tr ON tr.track_id = Inl.track_id
	JOIN [Music_Database].[dbo].[album2$] AS al ON al.album_id = tr.album_id
	JOIN best_selling_artist AS bsa ON bsa.artist_id = al.artist_id
GROUP BY cu.customer_id, cu.first_name, cu.last_name, bsa.artist_name
ORDER BY Amount_Spent

--We want to find out the most popular music Genre for each country. We determine the most popular genre as the genre with the highest amount of purchases. 
--Write a query that returns each country along with the top Genre. For countries where the maximum number of purchases is shared return all Genres. */

WITH popular_genre AS(
					SELECT TOP 20 COUNT(inl.quantity) AS Purchases, ge.genre_id, ge.name, cu.country,
				    ROW_NUMBER() OVER (PARTITION BY cu.country ORDER BY COUNT(inl.quantity) DESC, cu.country ASC) AS RowNumber
					FROM [Music_Database].[dbo].[invoice_line$] AS inl
					JOIN [Music_Database].[dbo].[invoice$] AS inv ON Inv.invoice_id = inl.invoice_id
					JOIN [Music_Database].[dbo].[customer$] AS cu ON cu.customer_id = inv.customer_id
					JOIN [Music_Database].[dbo].[track$] AS tr ON tr.track_id = inl.track_id
					JOIN [Music_Database].[dbo].[genre$] AS ge ON ge.genre_id = tr.genre_id
					GROUP BY ge.genre_id, ge.name, cu.country
					ORDER BY 1 DESC, 4 ASC
)
SELECT * FROM popular_genre
WHERE RowNumber <= 1

--Write a query that determines the customer that has spent the most on music for each country. 
--Write a query that returns the country along with the top customer and how much they spent. 
--For countries where the top amount spent is shared, provide all customers who spent this amount. */

WITH customer_with_country AS(
							SELECT TOP 20 cu.customer_id, cu.first_name, cu.last_name, inv.billing_country, SUM(inv.total) AS Total_Spending,
							ROW_NUMBER() OVER (PARTITION BY billing_country ORDER BY SUM(inv.total) DESC) AS RowNumber
							FROM [Music_Database].[dbo].[invoice$] AS inv
							JOIN [Music_Database].[dbo].[customer$] AS cu ON cu.customer_id = inv.customer_id
							GROUP BY cu.customer_id, cu.first_name, cu.last_name, inv.billing_country
							ORDER BY 5 DESC, 4 ASC
)
SELECT * FROM customer_with_country
WHERE RowNumber <=1