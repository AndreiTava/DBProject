/*Exercitiul 12*/

/*Sa se afiseze numele produsului, numele platformei, 
data la care a fost achizitionat si pretul de baza
pentru toate produsele detinute de utilizatorul care 
si-a creat contul in Iulie 2015, prima zi de luni. */
SELECT
    product_title,
    platform_name,
    purchase_date date_added,
    CASE base_price                 --case afisare
        WHEN 0 THEN 'Free'
        ELSE to_char(base_price)
        END normal_price
FROM
         products
    JOIN product_purchases USING ( product_id )         --join tabele relevante
    JOIN platforms USING ( platform_id )
    JOIN purchases USING ( client_id,
                           purchase_date )
WHERE
    receiver_id = (SELECT account_id                      --determinare utilizatori
                   FROM accounts
                   WHERE trunc(join_date) = next_day(TO_DATE('01/JUL/2015', 'DD/MON/YYYY'), 'Monday'));
       
       
/*Pentru toate produsele cu rating mediu >=3 sa se afiseze titlul, ratingul si
numarul de unitati vandute si sa se faca ordonarea dupa aceasta valoare si dupa rating
Produsele fara rating vor primi din oficiu 0*/

SELECT
    product_title,
    nvl(AVG(rating), 0) rating,    --determinare rating
    units_sold
FROM
    products
    LEFT OUTER JOIN reviews USING ( product_id )
    LEFT OUTER JOIN (SELECT 
                        product_id,
                        COUNT(*) units_sold    
                    FROM(SELECT 
                             pp.product_id,
                             pp.client_id,             --determinarea unitatilor per produs
                             pp.purchase_date
                        FROM product_purchases pp
                        GROUP BY                            
                            pp.product_id,
                            pp.client_id,
                            pp.purchase_date)
                    GROUP BY
                        product_id) USING ( product_id )
GROUP BY
    product_title,
    units_sold                   
HAVING
    nvl(AVG(rating), 0) >= 3              --filtrarea pentru rating       
ORDER BY
    units_sold DESC,
    rating DESC;                  --ordonarea

/*Sa se afiseze username si totalul ultimei tranzactii efectuate 
de utilizatoii cu username scris doar cu litere mici sau din mai putin de 10 caractere
Datele vor fi ordonate dupa total, descrescator*/

WITH 
last_tranz AS (             --determinarea ultimelor tranzactii pentru fiecae user
        SELECT
            MAX(purchase_date) purchase_date,
            client_id
        FROM purchases
        WHERE
            client_id IN (SELECT account_id
                          FROM accounts
                          WHERE
                            username = lower(username)
                            OR length(username) < 10)
        GROUP BY
            client_id), 
last_purchased AS (
        SELECT *
        FROM product_purchases   --determinarea produselor cumparate in acele tranzactii
        WHERE
        ( client_id,purchase_date ) IN (SELECT
                                           client_id,
                                           purchase_date
                                           FROM last_tranz))
SELECT
    username,
    SUM(actual_price) total --determinarea totalului
FROM
    (SELECT DISTINCT p.product_title,
            username,
            p.base_price,
            base_price * ( 1 - nvl(d.discount, 0) ) actual_price  --calculul pretului real
        FROM
            discount_history d
            JOIN sales s                      ON ( d.sale_date = s.start_date )   --joinuri pentru a determina preturile
            RIGHT OUTER JOIN last_purchased l ON ( l.product_id = d.product_id
                                                   AND l.purchase_date >= s.start_date
                                                   AND l.purchase_date <= s.end_date )
            JOIN products p                   ON ( l.product_id = p.product_id )
            JOIN accounts                     ON ( account_id = client_id ))
GROUP BY
    username
ORDER BY
    total DESC;

SELECT max(purchase_date)
FROM(
SELECT
            MAX(purchase_date) purchase_date,
            client_id
        FROM purchases
        WHERE
            client_id IN (SELECT account_id
                          FROM accounts
                          WHERE
                            username = lower(username)
                            OR length(username) < 10)
        GROUP BY
            client_id);


/*Sa se afiseze toate produsele care au fost cumparate la o zi
dupa ce o reducere din care acestea au facut parte s-a terminat,
impreuna cu utilizatorul care le-a cumparat si data cumpararii*/

SELECT
    a.username,
    product_title,
    purchase_date
FROM
    accounts a                                       --joinul relevant
    JOIN purchases         ON ( a.account_id = client_id )
    JOIN product_purchases USING ( client_id,purchase_date )
    JOIN products USING ( product_id )
WHERE
    purchase_date - 1 IN (SELECT end_date  --determinarea datelor de incheiere pentru sales
                          FROM 
                             discount_history d
                             JOIN sales ON ( sale_date = start_date )
                          WHERE
                            d.product_id = product_id);





/*Sa se afiseze acronimul platformei(PC,XB360,XB1,XBSX,PS3-5,NS) si 
compania de care este detinuta pentru toate platformele care au cel putin
un produs dezvoltat de detinatorul platformei sau un subsidiar
al acesteia*/

SELECT
    decode(platform_id, 0, 'PC', 1, 'PS3',2, 'PS4',  --decode pentru acronim
                        3, 'PS5', 4,'XB360', 5, 'XB1', 
                        6, 'XBSX',7, 'NS', 'ALTELE') platform,
    nvl(studio_name, 'Nobody') owner
FROM
    platforms pout
    LEFT OUTER JOIN studios ON ( owner_id = studio_id )
WHERE EXISTS (SELECT 1    --subcerere ce determina existenta unui produs
              FROM
                 products
                 JOIN product_availability USING ( product_id )
              WHERE
                 pout.platform_id = platform_id
                 AND developer_id IN (SELECT studio_id  --determinarea subsidiarilor
                                      FROM studios
                                      WHERE
                                        studio_id = pout.owner_id
                                        OR parent_id = pout.owner_id));
    
   
/*Exercitiul 13*/

/*Sa se stearga toate recenziile efectuate de utilizatori care nu detin produsul respectiv*/

DELETE FROM reviews
WHERE
    product_id NOT IN ( SELECT 
                            DISTINCT product_id 
                        FROM
                            product_purchases --lista produselor recenzorului
                            JOIN purchases USING ( client_id,purchase_date )
                        WHERE
                            receiver_id = account_id);

ROLLBACK;

/*Sa se modifice display_name adaugandu-se '_darnic' pentru toti 
utilizatorii care nu detin niciun produs dar au daruit produse altora*/

UPDATE accounts
SET display_name = display_name || '_darnic'
WHERE
    account_id NOT IN (SELECT receiver_id --utilizatorii care nu au cumparat
                       FROM purchases)
    AND account_id IN (SELECT client_id --utilizatorii care nu detin
                       FROM purchases);

ROLLBACK;


/*Sa se seteze detinatorul la null pentru toate francizele
care nu au produse sau nu au avut un produs de 5 ani*/

UPDATE franchises
SET holder_id = NULL
WHERE
    franchise_id NOT IN (SELECT franchise_id
                         FROM products    --determinarea francizelor fara produse recente
                         GROUP BY franchise_id
                         HAVING MAX(release_date) >= add_months(sysdate, - 12 * 5));

ROLLBACK;

/*Exercitiul 16*/

/*Pentru fiecare franciza sa se afiseze detinatorul drepturilor, 
numarul de produse care apartin francizei si titlul celei mai recente platforme
pe care sunt disponibile produse ale sale*/

SELECT
    franchise_name,
    nvl(studio_name, 'Public Domain') holder,
    titles,
    nvl(platform_name, 'No Titles') latest_platform
FROM
    (SELECT
        franchise_name,
        studio_name,
        COUNT(DISTINCT product_id) titles,  --se numara produsele si se determina data platformei recente
        MAX(p.release_date) max_release
    FROM
        franchises
        LEFT OUTER JOIN studios ON ( holder_id = studio_id )
        LEFT OUTER JOIN products USING ( franchise_id )
        LEFT OUTER JOIN product_availability USING ( product_id )
        LEFT OUTER JOIN platforms p USING ( platform_id )
    GROUP BY
        franchise_name,
        studio_name)
    LEFT OUTER JOIN platforms ON ( max_release = release_date ); --join pentru denumirea platformei
               

/*Pentru fiecare utilizator sa se afiseze produsele pe care le are in comun cu toti prietenii sai*/

SELECT
    username,
    product_title
FROM
    products p
    JOIN product_purchases o ON ( p.product_id = o.product_id )
    JOIN purchases           USING ( client_id,purchase_date )
    JOIN accounts            ON ( account_id = receiver_id )
WHERE
    NOT EXISTS (SELECT friend_id
                FROM friendships   
                WHERE account_id = receiver_id
            UNION  --determinarea prietenilor
                SELECT account_id
                FROM friendships
                WHERE friend_id = receiver_id
            MINUS
                SELECT receiver_id
                FROM
                    product_purchases i --determinarea utilizatorilor care detin produsul
                    JOIN purchases USING ( client_id,purchase_date )
                WHERE
                    i.product_id = o.product_id);

/*Sa se afiseze produsele care fac parte simultan din categoriile 'Singleplayer' si '3D'*/

SELECT product_title
FROM products p
WHERE
    NOT EXISTS (SELECT category_id
                FROM categories --categoriile respective
                WHERE
                    initcap(category_name) = 'Singleplayer'
                    OR upper(category_name) = '3D'
            MINUS
                SELECT category_id --categoriile produsului
                FROM product_categorising pc
                WHERE pc.product_id = p.product_id);