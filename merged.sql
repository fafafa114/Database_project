CREATE TABLE customer (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    pid VARCHAR(100) UNIQUE NOT NULL
);

CREATE TABLE deposit_type (
    id SERIAL PRIMARY KEY,
    type_name VARCHAR(100) NOT NULL,
    interest_rate DECIMAL(4, 2) NOT NULL DEFAULT 0.0,
    description VARCHAR(100) NOT NULL
);

CREATE TABLE branch (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    address VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    month_cost DECIMAL(12, 2) NOT NULL DEFAULT 0.0
);

CREATE TABLE bank_card (
    id SERIAL PRIMARY KEY,
    card_number VARCHAR(20) UNIQUE NOT NULL,
    balance DECIMAL(12, 2) NOT NULL DEFAULT 0.0,
    customer_id INTEGER REFERENCES customer(id),
    deposit_type_id INTEGER REFERENCES deposit_type(id),
    branch_id INTEGER REFERENCES branch(id)
);

CREATE TABLE transfer (
    id SERIAL PRIMARY KEY,
    amount DECIMAL(12, 2) NOT NULL,
    sender_card_id INTEGER REFERENCES bank_card(id),
    receiver_card_id INTEGER REFERENCES bank_card(id),
    transfer_date TIMESTAMP NOT NULL
);

CREATE TABLE transaction (
    id SERIAL PRIMARY KEY,
    bank_card_id INTEGER REFERENCES bank_card(id),
    branch_id INTEGER REFERENCES branch(id),
    transfer_id INTEGER REFERENCES transfer(id),
    amount DECIMAL(12, 2) NOT NULL,
    transaction_date TIMESTAMP NOT NULL
);

CREATE TABLE bank_employee (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    pid VARCHAR(100) UNIQUE NOT NULL,
    branch_id INTEGER REFERENCES branch(id),
    email VARCHAR(100) UNIQUE NOT NULL,
    salary DECIMAL(12, 2) NOT NULL DEFAULT 2000
);

CREATE TABLE loan (
    id SERIAL PRIMARY KEY,
    amount DECIMAL(12, 2) NOT NULL,
    deposit_type_id INTEGER REFERENCES deposit_type(id),
    branch_id INTEGER REFERENCES branch(id),
    customer_id INTEGER REFERENCES customer(id),
    loan_start_date TIMESTAMP NOT NULL,
    loan_end_date TIMESTAMP NOT NULL DEFAULT '9999-12-31 23:59:59'
);

-- update the month_cost of the branch when a new employee is added/deleted
CREATE OR REPLACE FUNCTION update_month_cost() 
RETURNS TRIGGER 
AS 
$$
BEGIN 
    UPDATE branch 
    SET month_cost = month_cost + NEW.salary 
    WHERE id = NEW.branch_id;
    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_month_cost_trigger 
AFTER INSERT ON bank_employee 
FOR EACH ROW 
EXECUTE FUNCTION update_month_cost();

CREATE OR REPLACE FUNCTION update_month_cost_on_delete()
RETURNS TRIGGER 
AS 
$$ 
BEGIN 
    UPDATE branch
    SET month_cost = month_cost - OLD.salary 
    WHERE id = OLD.branch_id;
    RETURN OLD;
END;
$$
LANGUAGE plpgsql;

CREATE TRIGGER update_month_cost_on_delete_trigger 
AFTER DELETE ON bank_employee 
FOR EACH ROW 
EXECUTE FUNCTION update_month_cost_on_delete();



-- automatically add two transactions when a transfer is added
CREATE OR REPLACE FUNCTION add_transfer_transaction()
RETURNS TRIGGER 
AS 
$$ 
BEGIN 
    INSERT INTO TRANSACTION (
        bank_card_id, 
        branch_id, 
        transfer_id, 
        amount, 
        transaction_date
    ) 
    VALUES (
        NEW.sender_card_id, 
        (SELECT branch_id FROM bank_card WHERE id = NEW.sender_card_id), 
        NEW.id, 
        NEW.amount, 
        NEW.transfer_date
    ), 
    (
        NEW.receiver_card_id, 
        (SELECT branch_id FROM bank_card WHERE id = NEW.receiver_card_id), 
        NEW.id, 
        - NEW.amount, 
        NEW.transfer_date
    );
    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql;

CREATE TRIGGER add_transfer_transaction_trigger 
AFTER INSERT ON transfer 
FOR EACH ROW 
EXECUTE FUNCTION add_transfer_transaction();


-- check the balance of the bank card before a new transaction is added
-- and update the balance if the balance is sufficient
CREATE OR REPLACE FUNCTION check_and_update_balance() 
RETURNS TRIGGER 
AS 
$$ 
DECLARE 
    card_balance DECIMAL(12, 2);
BEGIN 
    SELECT balance INTO card_balance FROM bank_card WHERE id = NEW.bank_card_id;
    IF (card_balance - NEW.amount) < 0 THEN 
        RAISE EXCEPTION 'Insufficient balance to complete transaction';
    ELSE 
        UPDATE bank_card SET balance = card_balance - NEW.amount WHERE id = NEW.bank_card_id;
    END IF;
    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql;

CREATE TRIGGER check_and_update_balance_trigger 
BEFORE INSERT ON TRANSACTION 
FOR EACH ROW 
EXECUTE FUNCTION check_and_update_balance();


-- delete all the transactions, transfers and bank cards of a customer when the customer is deleted
CREATE OR REPLACE FUNCTION delete_customer_info() 
RETURNS TRIGGER 
AS 
$$ 
BEGIN 
    DELETE FROM bank_card WHERE customer_id = OLD.id;
    DELETE FROM transfer 
    WHERE sender_card_id IN (SELECT id FROM bank_card WHERE customer_id = OLD.id) 
        OR receiver_card_id IN (SELECT id FROM bank_card WHERE customer_id = OLD.id);
    DELETE FROM TRANSACTION 
    WHERE bank_card_id IN (SELECT id FROM bank_card WHERE customer_id = OLD.id);
    RETURN OLD;
END;
$$ 
LANGUAGE plpgsql;


-- update the month_cost of the branch when the salary of an employee is updated
CREATE OR REPLACE FUNCTION update_month_cost_on_employee_update() 
RETURNS TRIGGER 
AS 
$$ 
BEGIN 
    UPDATE branch 
    SET month_cost = month_cost - OLD.salary + NEW.salary 
    WHERE id = NEW.branch_id;
    RETURN NEW;
END;
$$ 
LANGUAGE plpgsql;

CREATE TRIGGER update_month_cost_on_employee_update_trigger 
AFTER UPDATE ON bank_employee 
FOR EACH ROW 
WHEN (OLD.salary IS DISTINCT FROM NEW.salary) 
EXECUTE FUNCTION update_month_cost_on_employee_update();

INSERT INTO customer (name, pid)
VALUES ('John Smith', '123-45-6789'),
       ('Jane Doe', '987-65-4321'),
       ('Bob Johnson', '456-78-9123'),
       ('Mary Brown', '789-12-3456'),
       ('David Lee', '654-32-1098'),
       ('Sarah Davis', '321-98-7654'),
       ('Peter Jones', '246-80-1357'),
       ('Emily Wilson', '579-13-4680'),
       ('Michael White', '135-79-2468'),
       ('Amy Chen', '468-01-3579');

INSERT INTO deposit_type (type_name, interest_rate, description)
VALUES ('Savings', 0.02, 'Current Deposit'),
       ('Deposit', 0.05, 'Fixed Deposit'),
       ('Money Market', 0.06, 'Investment');

INSERT INTO deposit_type (type_name, interest_rate, description)
VALUES ('Loan', 0.08, 'Loan');

INSERT INTO branch (name, address, email, month_cost)
VALUES ('A Branch', '1, A street', 'Ab@bank.com', 5000),
       ('B Branch', '2, B street', 'B@bank.com', 5000),
       ('C Branch', '3, A street', 'C@bank.com', 10000);

INSERT INTO bank_card (card_number, customer_id, deposit_type_id, branch_id, balance)
VALUES ('1234-5678-9012-3456', 1, 1, 1, 10000.00),
       ('2345-6789-0123-4567', 2, 2, 2, 20000.00),
       ('3456-7890-1234-5678', 3, 3, 3, 30000.00),
       ('4567-8901-2345-6789', 4, 1, 1, 40000.00),
       ('5678-9012-3456-7890', 5, 2, 2, 50000.00),
       ('6789-0123-4567-8901', 6, 3, 3, 60000.00),
       ('7890-1234-5678-9012', 7, 1, 1, 70000.00),
       ('8901-2345-6789-0123', 8, 2, 2, 80000.00),
       ('9012-3456-7890-1234', 9, 3, 3, 90000.00),
       ('1111-2222-3333-4444', 1, 1, 2, 1000.00),
       ('2222-3333-4444-5555', 2, 2, 3, 2000.00),
       ('3333-4444-5555-6666', 3, 3, 1, 3000.00),
       ('4444-5555-6666-7777', 4, 1, 2, 4000.00),
       ('5555-6666-7777-8888', 5, 2, 3, 5000.00),
       ('6666-7777-8888-9999', 6, 3, 1, 6000.00),
       ('7777-8888-9999-1111', 7, 1, 2, 7000.00),
       ('8888-9999-1111-2222', 8, 2, 3, 8000.00),
       ('9999-1111-2222-3333', 9, 3, 1, 9000.00),
       ('0000-1111-2222-3333', 10, 1, 2, 0.00),
       ('1111-2222-3333-4445', 10, 2, 3, 20000.00);

INSERT INTO bank_employee (name, pid, branch_id, email, salary)
VALUES 
    ('Tom Jones', '246-80-1357', 1, 'a@a.com', 1000),
    ('Lisa Smith', '135-79-2468', 2, 'b@b.com', 2500),
    ('Mike Brown', '579-13-4680', 3, 'c@a.com', 5000);

INSERT INTO loan (
    amount,
    deposit_type_id,
    branch_id,
    customer_id,
    loan_start_date,
    loan_end_date
)
VALUES 
    (
        100.00,
        4,
        1,
        1,
        '2023-04-16 10:00:00',
        '2024-04-16 10:00:00'
    ),
    (
        200000.00,
        4,
        2,
        2,
        '2023-04-17 11:00:00',
        '2024-04-17 11:00:00'
    ),
    (
        10000.00,
        4,
        3,
        1,
        '2023-04-18 12:00:00',
        '2024-04-18 12:00:00'
    );
INSERT INTO transfer (
    amount,
    sender_card_id,
    receiver_card_id,
    transfer_date
)
VALUES 
    (5000, 1, 2, '2023-04-16 10:00:00'),
    (10000, 2, 3, '2023-04-16 11:00:00'),
    (2000, 3, 4, '2023-04-16 12:00:00'),
    (3000, 4, 5, '2023-04-17 10:00:00'),
    (8000, 5, 6, '2023-04-17 11:00:00'),
    (4000, 6, 7, '2023-04-17 12:00:00'),
    (1500, 7, 8, '2023-04-18 10:00:00'),
    (2500, 8, 9, '2023-04-18 11:00:00'),
    (3500, 9, 2, '2023-04-18 12:00:00'),
    (500, 2, 1, '2023-04-19 10:00:00'),
    (1500, 3, 2, '2023-04-19 11:00:00'),
    (2000, 4, 3, '2023-04-19 12:00:00'),
    (1000, 5, 4, '2023-04-20 10:00:00'),
    (3000, 6, 5, '2023-04-20 11:00:00'),
    (5000, 7, 6, '2023-04-20 12:00:00');

-- Annual update for deposit types
CREATE OR REPLACE PROCEDURE update_loan_amount() 
    LANGUAGE SQL 
AS $$
    UPDATE loan
    SET amount = amount * (1 + deposit_type.interest_rate)
    FROM deposit_type
    WHERE loan.deposit_type_id = deposit_type.id;
$$;

CALL update_loan_amount();

CREATE OR REPLACE PROCEDURE update_balance() 
    LANGUAGE SQL 
AS $$
    UPDATE bank_card
    SET balance = balance * (1 + deposit_type.interest_rate)
    FROM deposit_type
    WHERE bank_card.deposit_type_id = deposit_type.id;
$$;

CALL update_balance();



-- Delete unused bank cards
CREATE OR REPLACE PROCEDURE delete_unused_bank_card() 
    LANGUAGE SQL 
AS $$
    DELETE FROM bank_card
    WHERE id IN (
        SELECT bc.id
        FROM bank_card bc
        LEFT JOIN transaction t ON bc.id = t.bank_card_id
        WHERE t.id IS NULL
        AND bc.balance < 1
    );
$$;

CALL delete_unused_bank_card();

-- high risk customer, whose total deposit is less than total loan
SELECT 
    c.id,
    c.name,
    SUM(bc.balance) AS balance_sum,
    SUM(DISTINCT l.amount) AS loan_sum
FROM 
    customer c
    JOIN bank_card bc ON c.id = bc.customer_id
    JOIN loan l ON c.id = l.customer_id
GROUP BY 
    c.id
HAVING 
    SUM(bc.balance) < SUM(DISTINCT l.amount);

-- sum of deposit and loan by branch
SELECT 
    branch.name,
    SUM(bank_card.balance) AS total_deposit
FROM 
    branch
    JOIN bank_card ON branch.id = bank_card.branch_id
GROUP BY 
    branch.id;

SELECT 
    branch.name,
    SUM(loan.amount) AS total_loan
FROM 
    branch
    JOIN loan ON branch.id = loan.branch_id
GROUP BY 
    branch.id;

WITH deposit_summary AS (
    SELECT 
        bank_card.branch_id,
        deposit_type.type_name,
        SUM(bank_card.balance) AS total_balance,
        AVG(bank_card.balance) AS avg_balance
    FROM 
        bank_card
        JOIN deposit_type ON bank_card.deposit_type_id = deposit_type.id
    WHERE 
        deposit_type.type_name != 'Loan'
    GROUP BY 
        bank_card.branch_id,
        deposit_type.type_name
),
loan_summary AS (
    SELECT 
        loan.branch_id,
        SUM(loan.amount) AS total_loan,
        AVG(loan.amount) AS avg_loan
    FROM 
        loan
    GROUP BY 
        loan.branch_id
)
SELECT 
    branch.name,
    AVG(deposit_summary.avg_balance) AS avg_balance,
    AVG(loan_summary.avg_loan) AS avg_loan,
    AVG(deposit_summary.avg_balance) - AVG(loan_summary.avg_loan) AS diff_amount
FROM 
    branch
    LEFT JOIN deposit_summary ON branch.id = deposit_summary.branch_id
    LEFT JOIN loan_summary ON branch.id = loan_summary.branch_id
GROUP BY 
    branch.id;

SELECT 
    t.id AS transaction_id,
    bc.card_number,
    b.name AS branch_name,
    t.amount,
    t.transaction_date,
    ROW_NUMBER() OVER (PARTITION BY bc.card_number ORDER BY t.transaction_date) AS transaction_number
FROM 
    transaction t
    JOIN bank_card bc ON t.bank_card_id = bc.id
    JOIN branch b ON t.branch_id = b.id;

-- view for customer balance, including net worth
CREATE OR REPLACE VIEW view_customer_balance AS 
WITH customer_balance AS (
        SELECT 
            c.id AS customer_id,
            SUM(bc.balance) AS total_deposit,
            SUM(
                DISTINCT CASE
                    WHEN l.id IS NOT NULL THEN l.amount
                    ELSE 0
                END
            ) AS total_loan
        FROM 
            customer c
            JOIN bank_card bc ON c.id = bc.customer_id
            LEFT JOIN loan l ON c.id = l.customer_id
        GROUP BY 
            c.id
    )
SELECT 
    c.id,
    c.name AS customer_name,
    cb.total_deposit,
    cb.total_loan AS total_loan,
    cb.total_deposit - cb.total_loan AS net_worth
FROM 
    customer_balance cb
    JOIN customer c ON cb.customer_id = c.id
ORDER BY 
    net_worth DESC;

SELECT 
    * 
FROM 
    view_customer_balance;


-- view for all bank cards, including customer name and branch name
CREATE OR REPLACE VIEW view_bank_card_balance AS 
SELECT 
    bc.id AS bank_card_id,
    bc.card_number,
    bc.balance,
    c.name AS customer_name,
    b.name AS branch_name
FROM 
    bank_card bc
    JOIN customer c ON bc.customer_id = c.id
    JOIN branch b ON bc.branch_id = b.id
ORDER BY
    bc.balance DESC;

SELECT 
    * 
FROM 
    view_bank_card_balance;

-- view for all transactions, including card number, branch name, amount and transaction date
SELECT 
    t.id AS transaction_id,
    bc.card_number,
    b.name AS branch_name,
    t.amount,
    t.transaction_date,
    ROW_NUMBER() OVER (PARTITION BY bc.card_number ORDER BY t.transaction_date) AS transaction_number
FROM 
    transaction t
    JOIN bank_card bc ON t.bank_card_id = bc.id
    JOIN branch b ON t.branch_id = b.id;

