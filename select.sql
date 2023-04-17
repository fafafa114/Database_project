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
