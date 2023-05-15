-- Use either this file or insert_data.sql, not both.

INSERT INTO customer (name, pid)
VALUES ('Donald Trump', '123-125-333');

INSERT INTO customer (name, pid)
VALUES ('Joe Biden', '987-65-4322');

INSERT INTO deposit_type (type_name, interest_rate, description)
VALUES ('Presidents', 0.70, 'Only for president');

INSERT INTO branch (name, address, email, month_cost)
VALUES ('Trump Branch', '1, A street', 'trump@bank.com', 1000000);



SELECT * FROM customer;

SELECT * FROM branch;

UPDATE branch SET month_cost = month_cost / 10 WHERE month_cost > 10000;

SELECT * FROM branch;

DELETE FROM customer c WHERE c.name LIKE '%Joe%';
DELETE FROM customer c WHERE c.name LIKE '%Trump%';
DELETE FROM branch b WHERE b.name LIKE '%Trump%';
DELETE FROM deposit_type dt WHERE dt.interest_rate > 0.5;