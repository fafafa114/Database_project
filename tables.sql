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
