CREATE SEQUENCE account_index START WITH 0 INCREMENT BY 1 MINVALUE 0 NOCACHE;
CREATE SEQUENCE product_index START WITH 0 INCREMENT BY 1 MINVALUE 0 NOCACHE;
CREATE SEQUENCE category_index START WITH 0 INCREMENT BY 1 MINVALUE 0 NOCACHE;
CREATE SEQUENCE platform_index START WITH 0 INCREMENT BY 1 MINVALUE 0 NOCACHE;
CREATE SEQUENCE studio_index START WITH 0 INCREMENT BY 1 MINVALUE 0 NOCACHE;
CREATE SEQUENCE franchise_index START WITH 0 INCREMENT BY 1 MINVALUE 0 NOCACHE;
/*********************************************************************************/
CREATE TABLE categories (
    category_id     NUMBER(5) DEFAULT category_index.NEXTVAL PRIMARY KEY,
    category_name   VARCHAR2(32) NOT NULL UNIQUE);

CREATE TABLE studios (
    studio_id     NUMBER(5) DEFAULT studio_index.NEXTVAL PRIMARY KEY,
    studio_name   VARCHAR2(64) NOT NULL UNIQUE,
    parent_id     NUMBER(5) REFERENCES studios ( studio_id ) ON DELETE SET NULL);

CREATE TABLE franchises (
    franchise_id     NUMBER(5) DEFAULT franchise_index.NEXTVAL PRIMARY KEY,
    franchise_name   VARCHAR2(64) NOT NULL UNIQUE,
    holder_id        NUMBER(5) REFERENCES studios ( studio_id ) ON DELETE SET NULL);

CREATE TABLE platforms (
    platform_id     NUMBER(5) DEFAULT platform_index.NEXTVAL PRIMARY KEY,
    platform_name   VARCHAR2(32) NOT NULL UNIQUE,
    release_date    DATE DEFAULT sysdate,
    owner_id        NUMBER(5) REFERENCES studios ( studio_id ) ON DELETE SET NULL);

CREATE TABLE sales (
    start_date   DATE DEFAULT sysdate PRIMARY KEY,
    end_date     DATE NOT NULL,
    sale_name    VARCHAR2(64) NOT NULL,
    CONSTRAINT sales_valid CHECK ( end_date > start_date ));

CREATE TABLE accounts (
    account_id      NUMBER(5) DEFAULT account_index.NEXTVAL PRIMARY KEY,
    username        VARCHAR2(32) NOT NULL UNIQUE,
    display_name    VARCHAR2(64) NOT NULL,
    join_date       DATE DEFAULT sysdate NOT NULL,
    email           VARCHAR2(32) NOT NULL UNIQUE CHECK ( email LIKE '%@%' ),
    phone           VARCHAR2(15) UNIQUE,
    password_hash   CHAR(64) NOT NULL);

CREATE TABLE products (
    product_id      NUMBER(5) DEFAULT product_index.NEXTVAL PRIMARY KEY,
    product_title   VARCHAR2(64) NOT NULL,
    release_date    DATE DEFAULT sysdate,
    base_price      NUMBER(4, 2) DEFAULT 0 NOT NULL CHECK ( base_price >= 0 ),
    developer_id    NUMBER(5) NOT NULL REFERENCES studios ( studio_id ) ON DELETE CASCADE,
    publisher_id    NUMBER(5) NOT NULL REFERENCES studios ( studio_id ) ON DELETE CASCADE,
    franchise_id    NUMBER(5) REFERENCES franchises ( franchise_id ) ON DELETE SET NULL,
    dependency_id   NUMBER(5) REFERENCES products ( product_id ) ON DELETE CASCADE);

CREATE TABLE purchases (
    client_id       NUMBER(5) REFERENCES accounts ( account_id ) ON DELETE CASCADE,
    purchase_date   DATE DEFAULT sysdate,
    receiver_id     NUMBER(5) REFERENCES accounts ( account_id ) ON DELETE SET NULL,
    CONSTRAINT pk_purchases PRIMARY KEY ( client_id, purchase_date ));

CREATE TABLE reviews (
    account_id    NUMBER(5) REFERENCES accounts ( account_id ) ON DELETE CASCADE,
    product_id    NUMBER(5) REFERENCES products ( product_id ) ON DELETE CASCADE,
    review_date   DATE DEFAULT sysdate NOT NULL,
    rating        NUMBER(3, 2) NOT NULL CHECK ( rating >= 0 AND rating <= 5 ),
    CONSTRAINT pk_reviews PRIMARY KEY ( account_id,product_id ));

CREATE TABLE product_categorising (
    product_id    NUMBER(5) REFERENCES products ( product_id ) ON DELETE CASCADE,
    category_id   NUMBER(5) REFERENCES categories ( category_id ) ON DELETE CASCADE,
    CONSTRAINT pk_prod_cat PRIMARY KEY ( product_id,category_id ));

CREATE TABLE product_availability (
    product_id    NUMBER(5) REFERENCES products ( product_id ) ON DELETE CASCADE,
    platform_id   NUMBER(5) REFERENCES platforms ( platform_id ) ON DELETE CASCADE,
    CONSTRAINT pk_prod_plat PRIMARY KEY ( product_id,platform_id ));

CREATE TABLE discount_history (
    product_id   NUMBER(5) REFERENCES products ( product_id ) ON DELETE CASCADE,
    sale_date    DATE REFERENCES sales ( start_date ) ON DELETE CASCADE,
    discount     NUMBER(2, 2) NOT NULL CHECK ( discount > 0 AND discount <= 1 ),
    CONSTRAINT pk_discount PRIMARY KEY ( product_id,sale_date ));

CREATE TABLE platform_usage (
    account_id    NUMBER(5) REFERENCES accounts ( account_id ) ON DELETE CASCADE,
    platform_id   NUMBER(5) REFERENCES platforms ( platform_id ) ON DELETE CASCADE,
    CONSTRAINT pk_plat_usg PRIMARY KEY ( platform_id,account_id ));

CREATE TABLE friendships (
    account_id   NUMBER(5) REFERENCES accounts ( account_id ) ON DELETE CASCADE,
    friend_id    NUMBER(5) REFERENCES accounts ( account_id ) ON DELETE CASCADE,
    CONSTRAINT non_self_friend CHECK ( account_id != friend_id ),
    CONSTRAINT pk_friends PRIMARY KEY ( account_id,friend_id ));

CREATE TABLE product_purchases (
    product_id      NUMBER(5) REFERENCES products ( product_id ) ON DELETE CASCADE,
    platform_id     NUMBER(5) REFERENCES platforms (platform_id) ON DELETE CASCADE,
    client_id       NUMBER(5),
    purchase_date   DATE,
    CONSTRAINT fk_prod_purch FOREIGN KEY ( client_id,purchase_date ) REFERENCES purchases ( client_id,purchase_date ) ON DELETE CASCADE,
    CONSTRAINT pk_prod_purch PRIMARY KEY ( product_id,platform_id,client_id,purchase_date ));
/***********************************************/

INSERT INTO accounts (username,display_name,email,phone,password_hash,join_date) 
VALUES ('widderr','widz','tavaandrei@gmail.com','+40759145680',
    '7138f2e1e38c8b5b9e06d4822e083560d4ce717b8c45f571b6768d852193f0d7',
    TO_DATE('07/06/2015, 7:27:27 PM', 'MM/DD/YYYY, HH12:MI:SS AM'));

INSERT INTO accounts (username,display_name,email,phone,password_hash,join_date)
VALUES ('berkesmcheru','bigboiberke','berkemusellim@hotmail.com','+40757049004',
    '3c97be15cc5259a68287081c4b41d7ef0cfea261edc9dcbca2b2357a737c34ca',
    TO_DATE('05/07/2020, 5:26:26 PM', 'MM/DD/YYYY, HH12:MI:SS AM'));

INSERT INTO accounts (username,display_name,email,phone,password_hash,join_date)
VALUES ('Qmpz','Diaconu','weAre@palmier.com','(void*(0))',
    'af5f269ddf697cd26239e7f7e6853e1d3e8fdcd213b9f0ffe825f7725582643f',
    TO_DATE('05/07/2020, 5:30:05 PM', 'MM/DD/YYYY, HH12:MI:SS AM'));

INSERT INTO accounts (username,display_name,email,phone,password_hash,join_date)
VALUES ('JohnXina','JohnCena','youcantseeme@fbi.mail.us',NULL,
    'c83f0be82792393aa49eaae8115931279c0d45259577acea04e50d3b4b7b0344',
    TO_DATE('05/07/2020, 5:39:54 PM', 'MM/DD/YYYY, HH12:MI:SS AM'));

INSERT INTO accounts (username,display_name,email,phone,password_hash,join_date) 
VALUES ('freesciofficial','Sizzle','sizzlefrostindeed@gmail.com',NULL,
    'f0cc9b7bf0cb92e5bca6d191a7a4350f17f3ea0d28e0a5e143b347ea560a4434',
    TO_DATE('05/09/2015, 5:30:11 PM', 'MM/DD/YYYY, HH12:MI:SS AM'));

INSERT INTO accounts (username,display_name,email,phone,password_hash,join_date)
VALUES ('popescu_d017','Decebal Popescu','decebalpopescu2013@yahoo.ro','074000000',
    '05047861e93fb4b8ce12534d7b4eb21020595c45dcf2693bfe906da1b4b20fc5',
    TO_DATE('07/10/2021, 2:15:11 PM', 'MM/DD/YYYY, HH12:MI:SS AM'));
/***********************************************/
INSERT INTO categories ( category_name ) VALUES ( 'Roguelike' );
INSERT INTO categories ( category_name ) VALUES ( 'First Person Shooter' );
INSERT INTO categories ( category_name ) VALUES ( 'Multiplayer' );
INSERT INTO categories ( category_name ) VALUES ( 'Singleplayer' );
INSERT INTO categories ( category_name ) VALUES ( 'Sandbox' );
INSERT INTO categories ( category_name ) VALUES ( '2D' );
INSERT INTO categories ( category_name ) VALUES ( '3D' );
/***********************************************/
INSERT INTO studios (studio_name,parent_id) 
VALUES ('Valve',NULL);

INSERT INTO studios (studio_name,parent_id) 
VALUES ('Sony Interactive Entertainment',NULL);

INSERT INTO studios (studio_name,parent_id) 
VALUES ('Microsoft',NULL);

INSERT INTO studios (studio_name,parent_id) 
VALUES ('Nintendo',NULL);

INSERT INTO studios (studio_name,parent_id) 
VALUES ('Mojang',2);

INSERT INTO studios (studio_name,parent_id) 
VALUES ('Nicalis, Inc',NULL);
/***********************************************/
INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('Personal Computer',NULL,NULL);

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('PlayStation 3',1,TO_DATE('23 MAR 2007', 'DD MON YYYY'));

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('PlayStation 4',1,TO_DATE('29 NOV 2013', 'DD MON YYYY'));

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('PlayStation 5',1,TO_DATE('19 NOV 2020', 'DD MON YYYY'));

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('Xbox 360',2,TO_DATE('02 DEC 2005', 'DD MON YYYY'));

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('Xbox One',2,TO_DATE('22 NOV 2013', 'DD MON YYYY'));

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('Xbox Series X',2,TO_DATE('10 NOV 2020', 'DD MON YYYY'));

INSERT INTO platforms (platform_name,owner_id,release_date) 
VALUES ('Nintendo Switch',3,TO_DATE('03 MAR 2017', 'DD MON YYYY'));
/***********************************************/

INSERT INTO franchises (franchise_name,holder_id) 
VALUES ('Team Fortress',0);

INSERT INTO franchises (franchise_name,holder_id) 
VALUES ('Binding of Isaac',5);

INSERT INTO franchises (franchise_name,holder_id) 
VALUES ('Pokemon',3);

INSERT INTO franchises (franchise_name,holder_id) 
VALUES ('Alice in Wonderland',NULL);

INSERT INTO franchises (franchise_name,holder_id) 
VALUES ('Age of Empires',2);

/***********************************************/
INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id)
VALUES ('Team Fortress 2',TO_DATE('10 OCT 2007', 'DD MON YYYY'),0,0,0,0,NULL);

INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id) 
VALUES ('Minecraft',TO_DATE('17 MAY 2009', 'DD MON YYYY'),23.95,4,4,NULL,NULL);

INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id) 
VALUES ('The Binding of Isaac: Rebirth',TO_DATE('04 NOV 2014', 'DD MON YYYY'),14.99,5,5,1,NULL);

INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id) 
VALUES ('The Binding of Isaac: Afterbirth',TO_DATE('30 OCT 2015', 'DD MON YYYY'),10.99,5,5,1,2);

INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id) 
VALUES ('The Binding of Isaac: Afterbirth+',TO_DATE('03 JAN 2017', 'DD MON YYYY'),9.99,5,5,1,3);

INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id)
VALUES ('The Binding of Isaac: Repentance',TO_DATE('31 MAR 2021', 'DD MON YYYY'),14.59,5,5,1,4);

INSERT INTO products (product_title,release_date,base_price,publisher_id,developer_id,franchise_id,dependency_id) 
VALUES ('Pokemon Sword and Shield',TO_DATE('15 NOV 2021', 'DD MON YYYY'),30,3,3,2,NULL);
/***********************************************/
INSERT INTO product_categorising VALUES (0,1);
INSERT INTO product_categorising VALUES (0,2);
INSERT INTO product_categorising VALUES (0,6);
INSERT INTO product_categorising VALUES (1,2);
INSERT INTO product_categorising VALUES (1,3);
INSERT INTO product_categorising VALUES (1,4);
INSERT INTO product_categorising VALUES (1,6);
INSERT INTO product_categorising VALUES (2,0);
INSERT INTO product_categorising VALUES (2,3);
INSERT INTO product_categorising VALUES (2,5);
INSERT INTO product_categorising VALUES (3,0);
INSERT INTO product_categorising VALUES (3,3);
INSERT INTO product_categorising VALUES (3,5);
INSERT INTO product_categorising VALUES (4,0);
INSERT INTO product_categorising VALUES (4,3);
INSERT INTO product_categorising VALUES (4,5);
INSERT INTO product_categorising VALUES (5,0);
INSERT INTO product_categorising VALUES (5,3);
INSERT INTO product_categorising VALUES (5,5);
INSERT INTO product_categorising VALUES (6,3);
INSERT INTO product_categorising VALUES (6,6);
/***********************************************/
INSERT INTO product_availability VALUES (0,0);
INSERT INTO product_availability VALUES (0,1);
INSERT INTO product_availability VALUES (0,4);
INSERT INTO product_availability VALUES (1,0);
INSERT INTO product_availability VALUES (1,1);
INSERT INTO product_availability VALUES (1,2);
INSERT INTO product_availability VALUES (1,3);
INSERT INTO product_availability VALUES (1,4);
INSERT INTO product_availability VALUES (1,5);
INSERT INTO product_availability VALUES (1,6);
INSERT INTO product_availability VALUES (1,7);
INSERT INTO product_availability VALUES (2,0);
INSERT INTO product_availability VALUES (2,2);
INSERT INTO product_availability VALUES (2,5);
INSERT INTO product_availability VALUES (3,0);
INSERT INTO product_availability VALUES (3,2);
INSERT INTO product_availability VALUES (3,5);
INSERT INTO product_availability VALUES (4,0);
INSERT INTO product_availability VALUES (4,2);
INSERT INTO product_availability VALUES (4,5);
INSERT INTO product_availability VALUES (5,0);
INSERT INTO product_availability VALUES (5,2);
INSERT INTO product_availability VALUES (5,5);
INSERT INTO product_availability VALUES (6,7);
/****************************************************************************************************/
INSERT INTO sales VALUES (TO_DATE('01 AUG 2018', 'DD MON YYYY'),TO_DATE('02 AUG 2018', 'DD MON YYYY'),'Lightning Sale');
INSERT INTO sales VALUES (TO_DATE('28 DEC 2019', 'DD MON YYYY'),TO_DATE('07 JAN 2020', 'DD MON YYYY'),'Winter Sale 2020');
INSERT INTO sales VALUES (TO_DATE('31 MAR 2021', 'DD MON YYYY'),TO_DATE('07 APR 2021', 'DD MON YYYY'),'Roguelike Sale 2021');
INSERT INTO sales VALUES (TO_DATE('15 NOV 2021', 'DD MON YYYY'),TO_DATE('20 NOV 2021', 'DD MON YYYY'),'Nintendo Handheld Sale');
INSERT INTO sales VALUES (TO_DATE('19 JUN 2022', 'DD MON YYYY'),TO_DATE('30 JUN 2022', 'DD MON YYYY'),'Summer Sale 2022');
/***********************************************/
INSERT INTO discount_history VALUES (1,TO_DATE('01 AUG 2018', 'DD MON YYYY'),0.3);
INSERT INTO discount_history VALUES (1,TO_DATE('28 DEC 2019', 'DD MON YYYY'),0.15);
INSERT INTO discount_history VALUES (2,TO_DATE('28 DEC 2019', 'DD MON YYYY'),0.2);
INSERT INTO discount_history VALUES (3,TO_DATE('28 DEC 2019', 'DD MON YYYY'),0.25);
INSERT INTO discount_history VALUES (4,TO_DATE('28 DEC 2019', 'DD MON YYYY'),0.1);
INSERT INTO discount_history VALUES (2,TO_DATE('31 MAR 2021', 'DD MON YYYY'),0.5);
INSERT INTO discount_history VALUES (3,TO_DATE('31 MAR 2021', 'DD MON YYYY'),0.5);
INSERT INTO discount_history VALUES (4,TO_DATE('31 MAR 2021', 'DD MON YYYY'),0.5);
INSERT INTO discount_history VALUES (5,TO_DATE('31 MAR 2021', 'DD MON YYYY'),0.5);
INSERT INTO discount_history VALUES (6,TO_DATE('15 NOV 2021', 'DD MON YYYY'),0.5);
INSERT INTO discount_history VALUES (1,TO_DATE('19 JUN 2022', 'DD MON YYYY'),0.1);
INSERT INTO discount_history VALUES (2,TO_DATE('19 JUN 2022', 'DD MON YYYY'),0.2);
/********************************************************************************************************/
INSERT INTO reviews VALUES (0,0,TO_DATE('08/12/2015', 'DD/MM/YYYY'),4.7);
INSERT INTO reviews VALUES (0,1,TO_DATE('07/07/2018', 'DD/MM/YYYY'),5);
INSERT INTO reviews VALUES (0,5,TO_DATE('15/09/2021', 'DD/MM/YYYY'),4);
INSERT INTO reviews VALUES (1,1,TO_DATE('08/07/2018', 'DD/MM/YYYY'),5);
INSERT INTO reviews VALUES (1,6,TO_DATE('17/11/2021', 'DD/MM/YYYY'),3);
INSERT INTO reviews VALUES (3,1,TO_DATE('10/07/2018', 'DD/MM/YYYY'),5);
INSERT INTO reviews VALUES (4,1,TO_DATE('11/07/2018', 'DD/MM/YYYY'),5);
INSERT INTO reviews VALUES (5,1,TO_DATE('12/07/2018', 'DD/MM/YYYY'),5);
INSERT INTO reviews VALUES (5,2,TO_DATE('21/03/2022', 'DD/MM/YYYY'),1.13);
/***********************************************/
INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (0,0,TO_DATE('08/07/2015', 'DD/MM/YYYY'));

INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (0,0,TO_DATE('02/04/2021', 'DD/MM/YYYY'));

INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (1,1,TO_DATE('01/08/2018', 'DD/MM/YYYY'));

INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (1,1,TO_DATE('16/11/2021', 'DD/MM/YYYY'));

INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (3,3,TO_DATE('03/08/2018', 'DD/MM/YYYY'));

INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (4,4,TO_DATE('07/07/2015', 'DD/MM/YYYY'));

INSERT INTO purchases (client_id,receiver_id,purchase_date) 
VALUES (5,0,TO_DATE('19/11/2017', 'DD/MM/YYYY'));
/***********************************************/

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (0,TO_DATE('08/07/2015', 'DD/MM/YYYY'),0,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),2,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),2,2);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id) 
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),3,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id) 
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),3,2);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),4,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id) 
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),4,2);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),5,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id) 
VALUES (0,TO_DATE('02/04/2021', 'DD/MM/YYYY'),5,2);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (1,TO_DATE('01/08/2018', 'DD/MM/YYYY'),1,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (1,TO_DATE('01/08/2018', 'DD/MM/YYYY'),1,7);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (1,TO_DATE('16/11/2021', 'DD/MM/YYYY'),6,7);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id) 
VALUES (3,TO_DATE('03/08/2018', 'DD/MM/YYYY'),1,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (4,TO_DATE('07/07/2015', 'DD/MM/YYYY'),0,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (5,TO_DATE('19/11/2017', 'DD/MM/YYYY'),1,0);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (5,TO_DATE('19/11/2017', 'DD/MM/YYYY'),1,2);

INSERT INTO product_purchases (client_id,purchase_date,product_id,platform_id)
VALUES (5,TO_DATE('19/11/2017', 'DD/MM/YYYY'),1,3);
/***********************************************/
INSERT INTO platform_usage VALUES (0,0);
INSERT INTO platform_usage VALUES (0,2);
INSERT INTO platform_usage VALUES (0,3);
INSERT INTO platform_usage VALUES (1,0);
INSERT INTO platform_usage VALUES (1,7);
INSERT INTO platform_usage VALUES (2,0);
INSERT INTO platform_usage VALUES (3,0);
INSERT INTO platform_usage VALUES (4,0);
INSERT INTO platform_usage VALUES (5,0);
INSERT INTO platform_usage VALUES (5,2);
INSERT INTO platform_usage VALUES (5,3);
/***********************************************/
INSERT INTO friendships VALUES (0,1);
INSERT INTO friendships VALUES (0,2);
INSERT INTO friendships VALUES (0,3);
INSERT INTO friendships VALUES (0,4);
INSERT INTO friendships VALUES (0,5);
INSERT INTO friendships VALUES (1,2);
INSERT INTO friendships VALUES (1,3);
INSERT INTO friendships VALUES (2,5);
/*****************************************************/
COMMIT;