/* -----------------------------------------------------------------------------------------------------
        Chart 1: Top 3 rented families movies by categories
----------------------------------------------------------------------------------------------------- */

SELECT 'Chart 1: Top 3 rented families movies by categories';

WITH most_rented_family_movies AS 
(
SELECT f.title, c.name,  COUNT(r.rental_id) AS rental_count
  FROM category c 
       INNER JOIN film_category fc
               ON c.category_id = fc.category_id 
       INNER JOIN film f 
               ON fc.film_id  = f.film_id 
       INNER JOIN inventory i  
               ON f.film_id = i.film_id 
       INNER JOIN rental r 
               ON i.inventory_id  = r.inventory_id 
 WHERE c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
 GROUP BY f.title, c.name
 ORDER BY c.name, f.title
),

top3_movies_by_family_categories AS 
(
SELECT m.name, 
       m.title,
       m.rental_count,
       ROW_NUMBER() OVER (PARTITION BY m.name ORDER BY m.rental_count DESC) AS rownumber
  FROM most_rented_family_movies m
 ORDER BY m.name, m.rental_count DESC
)

SELECT t.name, t.title, t.rental_count, t.rownumber
  FROM top3_movies_by_family_categories t
 WHERE t.rownumber <=3
 ORDER BY t.name, t.rownumber ASC;


/* -----------------------------------------------------------------------------------------------------
        Chart 2: Monthly rentals by store, year 2017
----------------------------------------------------------------------------------------------------- */

SELECT 'Chart 2: Monthly rentals by store, year 2017';

SELECT DATE_PART('month', r.rental_date ) AS Rental_Month,
        DATE_PART('year', r.rental_date ) AS Rental_Year,
        sto.store_id,
        COUNT(r.rental_id) AS Count_rentals
    FROM store sto
        INNER JOIN staff sta
                ON sto.store_id = sta.store_id 
        INNER JOIN rental r 
                ON sta.staff_id = r.staff_id 
    GROUP BY Rental_Month, Rental_Year, sto.store_id  
    ORDER BY Count_rentals DESC;


/* -----------------------------------------------------------------------------------------------------
        Chart 3: Top ten customers and revenue over 2017
----------------------------------------------------------------------------------------------------- */

SELECT 'Chart 3: Top ten customers and revenue over 2017';

SELECT p.customer_id,
       c.first_name || ' ' || c.last_name AS fullname,   
       COUNT(p.amount) AS pay_count,
       SUM(p.amount) AS pay_amount
  FROM payment p
       INNER JOIN CUSTOMER c
               ON p.customer_id = c.customer_id 
 WHERE DATE_PART('year', p.payment_date) = 2007
 GROUP BY p.customer_id, fullname
 ORDER BY pay_amount DESC
 LIMIT 10 ;
  

/* -----------------------------------------------------------------------------------------------------
        Chart 4: Top ten customers and revenue month by month over 2017
----------------------------------------------------------------------------------------------------- */

SELECT 'Chart 4: Top ten customers and revenue month by month over 2017';


WITH best_ten_customers_2017 AS 
(
	SELECT p.customer_id,
	       SUM(p.amount) AS pay_amount
	  FROM payment p
	 WHERE DATE_PART('year', p.payment_date) = 2007
	 GROUP BY p.customer_id 
	 ORDER BY pay_amount DESC
	 LIMIT 10
),

best_ten_customers_2017_by_month AS
(
SELECT DATE_PART('year', p.payment_date) AS year,
       DATE_PART('month', p.payment_date) AS month,
       c.first_name || ' ' || c.last_name AS fullname, 
       COUNT(p.payment_id) AS pay_countpermonth,
       SUM(p.amount) AS pay_amount
  FROM payment p
       INNER JOIN CUSTOMER c
               ON p.customer_id = c.customer_id 
 WHERE DATE_PART('year', p.payment_date) = 2007
   AND p.customer_id IN ( SELECT bc.customer_id
       						FROM best_ten_customers_2017 bc
						)		
 GROUP BY YEAR, MONTH, fullname
),

final_result AS
(
SELECT bcbm1.year,
       bcbm1.month,
       bcbm1.fullname, 
       bcbm1.pay_countpermonth,
       bcbm1.pay_amount AS pay_amount_month,
       LAG(bcbm1.pay_amount) OVER (PARTITION BY bcbm1.year, bcbm1.fullname ORDER BY bcbm1.month) AS lag,
       LEAD(bcbm1.pay_amount) OVER (PARTITION BY bcbm1.year, bcbm1.fullname ORDER BY bcbm1.month) AS lead,
       bcbm1.pay_amount - LAG(bcbm1.pay_amount) OVER (PARTITION BY bcbm1.year, bcbm1.fullname ORDER BY bcbm1.month) AS lag_difference
  FROM best_ten_customers_2017_by_month AS bcbm1
 ORDER BY bcbm1.year, bcbm1.fullname, bcbm1.month 
 )
 
SELECT fr.*
  FROM final_result fr;
						  