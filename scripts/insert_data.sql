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

