INSERT INTO customer (name, pid)
VALUES ('Donald Trump', '123-125-333'),
       ('Joe Biden', '987-65-4322');

INSERT INTO deposit_type (type_name, interest_rate, description)
VALUES ('Presidents', 0.70, 'Only for president');

INSERT INTO branch (name, address, email, month_cost)
VALUES ('Trump Branch', '1, A street', 'trump@bank.com', 1000000);


DELETE FROM customer c WHERE c.name LIKE '%Joe%';

SELECT * FROM customer;

SELECT * FROM branch;

UPDATE branch SET month_cost = month_cost / 10 WHERE month_cost > 10000;

SELECT * FROM branch;