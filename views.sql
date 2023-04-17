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
CREATE OR REPLACE VIEW view_transaction_history AS 
SELECT 
    t.id AS transaction_id,
    bc.card_number,
    b.name AS branch_name,
    t.amount,
    t.transaction_date
FROM 
    transaction t
    JOIN bank_card bc ON t.bank_card_id = bc.id
    JOIN branch b ON t.branch_id = b.id
ORDER BY 
    bc.id;

SELECT 
    * 
FROM 
    view_transaction_history;
