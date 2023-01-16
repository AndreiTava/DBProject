--Ex.6..9 +13
CREATE OR REPLACE PACKAGE misc AS
    BAD_DISCOUNT EXCEPTION;
    INVALID_THRESHOLD EXCEPTION;
    INVALID_DATE EXCEPTION;
    
    FUNCTION average_diff(p_platform_name IN platforms.platform_name%TYPE) RETURN NUMBER;
    PROCEDURE discount_all_independent(p_discount IN products.base_price%TYPE);
    FUNCTION review_count(p_product IN products.product_title%TYPE,
                                        p_threshold IN reviews.rating%TYPE,
                                        p_date_since IN reviews.review_date%TYPE)
                                        RETURN NUMBER;
    PROCEDURE delete_uncommon_friends(p_user IN accounts.display_name%TYPE);
END misc;
/

CREATE OR REPLACE PACKAGE BODY misc AS
    
--Pentru o platforma dată, să se returneze diferența medie dintre prețul fiecărui produs 
--și prețul celui mai scump produs din franciza respectivă.
--(dacă nu face parte din vreo franciza, se considera pretul maxim 0.)
    FUNCTION average_diff(p_platform_name IN platforms.platform_name%TYPE) RETURN NUMBER IS
        TYPE fran_prod_map IS TABLE OF products.base_price%TYPE INDEX BY PLS_INTEGER;
        TYPE prod_rec IS RECORD 
            (prod_id products.product_id%TYPE, 
            fran_id products.franchise_id%TYPE, 
            price products.base_price%TYPE);
        TYPE prod_tab IS TABLE OF prod_rec;
        v_products prod_tab := prod_tab();
        v_max_prod fran_prod_map;
        v_average NUMBER := 0;
        v_plat_id platforms.platform_id%TYPE;
    BEGIN
        SELECT platform_id
        INTO v_plat_id
        FROM platforms
        WHERE platform_name = p_platform_name;
                    
        SELECT product_id,franchise_id,base_price
        BULK COLLECT INTO v_products
        FROM product_availability JOIN products USING (product_id) 
        WHERE platform_id = v_plat_id;
            
        FOR i IN v_products.FIRST..v_products.LAST LOOP --we know for sure it's dense
           IF v_products(i).fran_id IS NULL 
                THEN  v_average := v_average + v_products(i).price;
                    CONTINUE;
            END IF;
                    
            IF NOT v_max_prod.EXISTS(v_products(i).fran_id) --if we've already computed the maximum for this franchise
                THEN SELECT MAX(base_price)
                     INTO v_max_prod(v_products(i).fran_id)
                     FROM products
                     WHERE franchise_id = v_products(i).fran_id;
            END IF;
            v_average := v_average + v_max_prod(v_products(i).fran_id) - v_products(i).price;
        END LOOP;
        
        RETURN (v_average/v_products.COUNT);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('PLATFORM ' || p_platform_name ||' NOT FOUND!');
                                RAISE NO_DATA_FOUND;
        WHEN VALUE_ERROR THEN DBMS_OUTPUT.PUT_LINE('THERE ARE NO PRODUCTS FOR PLATFORM ' || p_platform_name);
    END average_diff;
    
--Să se reducă cu un procent dat prețul tuturor produselor dezvoltate de către studiouri independente
--(care nu au alt studio parinte).
    PROCEDURE discount_all_independent(p_discount IN products.base_price%TYPE) IS
        CURSOR products_by(studio_id studios.studio_id%TYPE) IS --parameter cursor
            SELECT product_id
            FROM products
            WHERE developer_id = studio_id
            FOR UPDATE OF base_price;
        BAD_DISCOUNT EXCEPTION;
    BEGIN
        IF p_discount NOT BETWEEN 0 AND 1 THEN RAISE BAD_DISCOUNT;
        END IF;
        FOR studio IN (SELECT studio_id     -- subquery cursor
                       FROM studios
                       WHERE parent_id IS NULL) LOOP
            FOR product IN products_by(studio.studio_id) LOOP
                UPDATE products
                SET base_price = base_price * (1 - p_discount)
                WHERE CURRENT OF products_by;
            END LOOP;
        END LOOP;
        COMMIT;
    EXCEPTION
        WHEN BAD_DISCOUNT THEN DBMS_OUTPUT.PUT_LINE('INVALID DISCOUNT VALUE');
    END discount_all_independent;

--Să se returneze numărul de recenzii cu scor mai mare sau egal cu o valoare data,
--pentru un anumit produs, făcute după o anumită dată 
--doar de către utilizatorii care dețin produsul.
    FUNCTION review_count(p_product IN products.product_title%TYPE,
                                        p_threshold IN reviews.rating%TYPE,
                                        p_date_since IN reviews.review_date%TYPE)
                                        RETURN NUMBER IS
        v_count NUMBER;
        v_id products.product_id%TYPE;
        v_release products.release_date%TYPE;
        INVALID_THRESHOLD EXCEPTION;
        INVALID_DATE EXCEPTION;
    BEGIN
        IF p_threshold NOT BETWEEN 0 AND 5 THEN RAISE INVALID_THRESHOLD;
        END IF;
        
        SELECT product_id,release_date
        INTO v_id,v_release
        FROM products
        WHERE lower(product_title) = lower(p_product);
        
        IF p_date_since NOT BETWEEN v_release AND sysdate THEN RAISE INVALID_DATE;
        END IF;
        
        SELECT count(*)
        INTO v_count                       --3 tables
        FROM reviews
        WHERE (account_id,product_id) IN (SELECT receiver_id, product_id
                                          FROM product_purchases JOIN  purchases USING (client_id,purchase_date)
                                          WHERE product_id = v_id)
               AND rating >= p_threshold 
               AND review_date >= p_date_since;
        RETURN v_count;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('PRODUCT '||p_product||' NOT FOUND!');
                                RAISE NO_DATA_FOUND;
        WHEN INVALID_THRESHOLD THEN DBMS_OUTPUT.PUT_LINE('INVALID THRESHOLD! SHOULD BE BETWEEN 0 and 5!');
        WHEN INVALID_DATE THEN DBMS_OUTPUT.PUT_LINE('INVALID DATE! SHOULD BE BETWEEN PRODUCT DATE AND PRESENT');
    END review_count;

--Pentru un utilizator dat(display name), sa se șteargă toate prieteniile 
--cu utilizatori care nu au niciun produs în comun pe o platforma comună.
    PROCEDURE delete_uncommon_friends(p_user IN accounts.display_name%TYPE) IS
        --procedure could be simplified by declaring this collection at schema level
        --thus enabling me to use it in SQL expressions... I chose not to do that however
        TYPE account_table IS TABLE OF accounts.account_id%TYPE;
        v_user accounts.account_id%TYPE;
        v_all_friends account_table := account_table();
        v_common_friends account_table := account_table();
        v_uncommon_friends account_table := account_table();
    BEGIN
        SELECT account_id
        INTO v_user
        FROM accounts
        WHERE lower(display_name) = lower(p_user);
        
        WITH friends AS
            (SELECT a.account_id
            FROM friendships   f
            JOIN accounts a ON (f.friend_id = a.account_id)
            WHERE f.account_id = v_user
            UNION
            SELECT account_id 
            FROM friendships
            JOIN accounts USING (account_id)
            WHERE friend_id = v_user)
        SELECT account_id
        BULK COLLECT INTO v_all_friends
        FROM friends;
        
        WITH friends AS
            (SELECT a.account_id
            FROM friendships   f
            JOIN accounts a ON (f.friend_id = a.account_id)
            WHERE f.account_id = v_user
            UNION
            SELECT account_id 
            FROM friendships
            JOIN accounts USING (account_id)
            WHERE friend_id = v_user)
        SELECT DISTINCT a.account_id
        BULK COLLECT INTO v_common_friends
        FROM friends a JOIN purchases p ON (a.account_id = p.receiver_id)      --5 tables
             JOIN product_purchases pp ON (pp.client_id = p.client_id
                                      AND pp.purchase_date = p.purchase_date)
             JOIN product_availability pa ON (pa.product_id = pp.product_id)
        WHERE(pa.product_id,pa.platform_id) IN (SELECT pa.product_id, pa.platform_id
                                                FROM purchases p
                                                JOIN product_purchases pp ON (pp.client_id = p.client_id
                                                                          AND pp.purchase_date = p.purchase_date)
                                                JOIN product_availability pa ON (pa.product_id = pp.product_id)
                                                WHERE receiver_id = v_user);
         
         v_uncommon_friends := v_all_friends MULTISET EXCEPT v_common_friends;
         
         FORALL i IN v_uncommon_friends.FIRST..v_uncommon_friends.LAST
         DELETE FROM friendships
         WHERE (account_id = v_user AND friend_id = v_uncommon_friends(i))
            OR (friend_id = v_user AND account_id = v_uncommon_friends(i));         
         
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('USER WITH DISPLAY NAME '|| p_user || ' NOT FOUND');
                                RAISE NO_DATA_FOUND;
        WHEN TOO_MANY_ROWS THEN DBMS_OUTPUT.PUT_LINE('MORE THAN ONE USER WITH DISPLAY NAME ' || p_user);
                                RAISE TOO_MANY_ROWS;
    END delete_uncommon_friends;    

END misc;
/
--Ex.10
--Dacă un sezon de reducere este în desfășurare, 
--nu este permisă inserarea altuia nou.
CREATE OR REPLACE TRIGGER sale_protection
    BEFORE INSERT ON sales
    DECLARE
        v_start DATE;
        v_end DATE;
    BEGIN
        SELECT start_date, end_date
        INTO v_start,v_end
        FROM sales
        WHERE end_date = (SELECT max(end_date)
                          FROM sales);
                          
        IF sysdate BETWEEN v_start AND v_end THEN RAISE_APPLICATION_ERROR(-20042,'CANNOT START A NEW SALE DURING A SALE!');
        END IF;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN NULL;
END;
/

--Ex.11
--Când se modifică prețul unui produs, să se insereze automat vechiul preț în price_history.
CREATE OR REPLACE TRIGGER price_change
    AFTER UPDATE OF base_price ON products
    FOR EACH ROW
    BEGIN
        INSERT INTO price_history
        VALUES (:old.product_id, sysdate, :old.base_price);    
END;
/

UPDATE products
SET base_price = 15
WHERE product_id = 5;

SELECT * FROM price_history;

--Ex.12
--trigger de sistem/ldd care valideaza denumirea unui obiect nou:
--numele trebuie sa aiba minim 2 caractere alfanumerice sau _ si nu poate incepe cu sql/dba
CREATE OR REPLACE TRIGGER name_validation
    BEFORE CREATE ON SCHEMA
    BEGIN
    
    IF regexp_like(ora_dict_obj_name,'^.{0,2}$|^(sql|dba)|[^a-z^0-9_]','i') THEN RAISE_APPLICATION_ERROR(-20043,'INVALID OBJECT NAME!');
    END IF;
END;
/
CREATE PROCEDURE sql_proc IS
BEGIN
    NULL;
END sql_proc;
/

--Ex.14
CREATE OR REPLACE PACKAGE transactions AS
    INVALID_SUM EXCEPTION;
    INSUFFICIENT_FUNDS EXCEPTION;
    INVALID_DATE EXCEPTION;
    TYPE product IS RECORD(
        id products.product_id%TYPE,
        title products.product_title%TYPE);
    TYPE product_list IS TABLE OF product; 
    TYPE purchase IS RECORD(
        client_id purchases.client_id%TYPE,
        receiver_id purchases.receiver_id%TYPE,
        purchase_date purchases.purchase_date%TYPE,
        products product_list);
    FUNCTION getPrice(p_product IN products.product_title%TYPE, p_date IN DATE) RETURN products.base_price%TYPE;
    FUNCTION getPurchase(p_client IN accounts.username%TYPE, p_date IN DATE) RETURN purchase;
    FUNCTION getPurchaseTotal(p_purchase IN purchase) RETURN products.base_price%TYPE;
    FUNCTION getUserBalance(p_user IN accounts.username%TYPE) RETURN deposits.deposit_sum%TYPE;
    PROCEDURE addToCart(p_product IN products.product_title%TYPE, p_cart IN OUT product_list);
    PROCEDURE removeFromCart(p_product IN products.product_title%TYPE, p_cart IN OUT product_list);
    PROCEDURE makePurchase(p_client IN accounts.username%TYPE, p_cart IN product_list, p_receiver IN accounts.username%TYPE := NULL);
    PROCEDURE makeDeposit(p_user IN accounts.username%TYPE, p_sum IN deposits.deposit_sum%TYPE);
END transactions;
/

CREATE OR REPLACE PACKAGE BODY transactions AS
    FUNCTION getPrice(p_product IN products.product_title%TYPE, p_date IN DATE) RETURN products.base_price%TYPE IS
    v_prod_id products.product_id%TYPE;
    v_price products.base_price%TYPE;
    v_discount discount_history.discount%TYPE;
    v_release DATE;
    BEGIN
        SELECT product_id,base_price,release_date
        INTO v_prod_id,v_price,v_release
        FROM products
        WHERE lower(product_title) = lower(p_product);
        
        IF p_date NOT BETWEEN v_release AND sysdate THEN RAISE INVALID_DATE;
        END IF;
        
        BEGIN
            SELECT price
            INTO v_price
            FROM price_history
            WHERE product_id = v_prod_id AND change_date = 
                            (SELECT min(change_date)
                            FROM price_history
                            WHERE product_id = v_prod_id AND p_date < change_date);
        EXCEPTION
            WHEN NO_DATA_FOUND THEN NULL;
        END;
        
        BEGIN
            SELECT discount
            INTO v_discount
            FROM discount_history JOIN SALES ON (sale_date = start_date)
            WHERE product_id = v_prod_id
                AND p_date BETWEEN start_date AND end_date;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN v_discount := 0;
        END;
        
        
        
        RETURN v_price *(1 - v_discount);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('PRODUCT '||p_product ||' NOT FOUND');
                                RAISE NO_DATA_FOUND;
        WHEN INVALID_DATE THEN DBMS_OUTPUT.PUT_LINE('DATE IS INVALID! HAS TO BE BETWEEN PRODUCT DATE AND PRESENT!');
                                RAISE INVALID_DATE;
    END getPrice;
    
    FUNCTION getPurchase(p_client IN accounts.username%TYPE, p_date IN DATE) RETURN purchase IS
        v_purchase purchase;
    BEGIN
        
        SELECT client_id, purchase_date, receiver_id
        INTO v_purchase.client_id, v_purchase.purchase_date, v_purchase.receiver_id
        FROM purchases JOIN accounts ON (account_id = client_id)
        WHERE lower(username) = lower(p_client) AND purchase_date = p_date;
        
        v_purchase.products := product_list();
        
        SELECT product_id, product_title
        BULK COLLECT INTO v_purchase.products
        FROM product_purchases JOIN products USING(product_id)
        WHERE client_id = v_purchase.client_id AND purchase_date = v_purchase.purchase_date;
            
        return v_purchase;    
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('THERE IS NO PURCHASE DONE BY '||p_client||' AT DATE '||to_char(p_date,'DD/MM/YYYY'));
                                RAISE NO_DATA_FOUND;
    END getPurchase;
    
    FUNCTION getPurchaseTotal(p_purchase IN purchase) RETURN products.base_price%TYPE IS
        v_total products.base_price%TYPE := 0;
        v_index PLS_INTEGER;
    BEGIN
         v_index := p_purchase.products.first;
         WHILE v_index IS NOT NULL LOOP
            v_total := v_total + getPrice(p_purchase.products(v_index).title,p_purchase.purchase_date);
            v_index := p_purchase.products.next(v_index);
         END LOOP;
         
         RETURN v_total;
    END getPurchaseTotal;
    
    FUNCTION getUserBalance(p_user IN accounts.username%TYPE) RETURN deposits.deposit_sum%TYPE IS
        v_balance deposits.deposit_sum%TYPE :=0;
        v_spent deposits.deposit_sum%TYPE :=0;
        v_user_id accounts.account_id%TYPE;
    BEGIN
    
        SELECT account_id,sum(deposit_sum)
        INTO v_user_id,v_balance
        FROM deposits JOIN accounts ON (client_id = account_id)
        WHERE lower(username) = lower(p_user)
        GROUP BY account_id;
        
        FOR purchase IN (SELECT purchase_date
                         FROM purchases
                         WHERE client_id = v_user_id) LOOP
            v_spent := v_spent + getPurchaseTotal(getPurchase(p_user,purchase.purchase_date));
        END LOOP;
        RETURN v_balance - v_spent;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('USER ' || p_user || ' NOT FOUND!');
                                RAISE NO_DATA_FOUND;
    END getUserBalance;
    
    PROCEDURE addToCart(p_product IN products.product_title%TYPE, p_cart IN OUT product_list) IS
        v_exists BOOLEAN := FALSE;
        v_index PLS_INTEGER;
        v_prod product;
    BEGIN
        SELECT product_id,product_title
        INTO v_prod
        FROM products
        WHERE lower(product_title) = lower(p_product);
        
        v_index := p_cart.first;
        WHILE v_index IS NOT NULL LOOP
            IF lower(p_cart(v_index).title) = lower(p_product)
                THEN v_exists := TRUE;
                EXIT;
            END IF;
            v_index := p_cart.next(v_index);
        END LOOP;
        
        IF NOT v_exists 
            THEN p_cart.extend();
            p_cart(p_cart.last) := v_prod;
        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('PRODUCT '||p_product ||' NOT FOUND');
                                RAISE NO_DATA_FOUND; 
    END addToCart;
    
    PROCEDURE removeFromCart(p_product IN products.product_title%TYPE, p_cart IN OUT product_list) IS
        v_index PLS_INTEGER;
    BEGIN
        v_index := p_cart.first;
        WHILE v_index IS NOT NULL LOOP
            IF lower(p_cart(v_index).title) = lower(p_product)
                THEN p_cart.delete(v_index);
                EXIT;
            END IF;
            v_index := p_cart.next(v_index);
        END LOOP;
    END;
    
    PROCEDURE makePurchase(p_client IN accounts.username%TYPE, p_cart IN product_list, p_receiver IN accounts.username%TYPE := NULL) IS
        INSUFFICIENT_FUNDS EXCEPTION;
        v_purchase purchase;
    BEGIN
        
        SELECT account_id
        INTO v_purchase.client_id
        FROM accounts
        WHERE lower(username) = lower(p_client);
        
        IF p_receiver IS NULL 
            THEN v_purchase.receiver_id := v_purchase.client_id;
        ELSE
            SELECT account_id
            INTO v_purchase.receiver_id
            FROM accounts
            WHERE lower(username) = lower(p_receiver);
        END IF;
        
        v_purchase.products := p_cart;
        v_purchase.purchase_date := sysdate;
        
        IF getPurchaseTotal(v_purchase) > getUserBalance(p_client) 
            THEN RAISE INSUFFICIENT_FUNDS;
        END IF;
        
        INSERT INTO purchases
        VALUES (v_purchase.client_id,v_purchase.purchase_date,v_purchase.receiver_id);
        
        FORALL i IN INDICES OF v_purchase.products
            INSERT INTO product_purchases
            VALUES (v_purchase.products(i).id,v_purchase.client_id,v_purchase.purchase_date);
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('USER NOT FOUND!');
                                RAISE NO_DATA_FOUND;
        WHEN INSUFFICIENT_FUNDS THEN DBMS_OUTPUT.PUT_LINE('USER HAS INSUFFICIENT FUNDS!');
                                RAISE INSUFFICIENT_FUNDS;
    END makePurchase;
    
    PROCEDURE makeDeposit(p_user IN accounts.username%TYPE, p_sum IN deposits.deposit_sum%TYPE) IS
        v_user_id accounts.account_id%TYPE;
    BEGIN
        IF p_sum <= 0 THEN RAISE INVALID_SUM;
        END IF;
        
        SELECT account_id
        INTO v_user_id
        FROM accounts
        WHERE lower(username) = lower(p_user);
        
        INSERT INTO deposits
        VALUES (v_user_id, sysdate, p_sum);
        
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN DBMS_OUTPUT.PUT_LINE('USER ' || p_user || ' NOT FOUND!');
                                RAISE NO_DATA_FOUND;
        WHEN INVALID_SUM THEN DBMS_OUTPUT.PUT_LINE('DEPOSITED SUM HAS TO BE POSITIVE!');
                              RAISE INVALID_SUM;
    END makeDeposit;
END transactions;
/