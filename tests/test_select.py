# create the triggers before insert
# This test works only on the basis of insert_data.sql
import os
import pytest
from dataclasses import dataclass
from urllib.parse import quote
import psycopg2 as pg
import sqlalchemy
import sys
from decimal import Decimal


@dataclass
class Credentials:
    dbname: str = "postgres"
    host: str = "127.0.0.1"
    port: int = 5432
    user: str = "postgres"
    password: str = "qq1103047248"


@pytest.fixture(scope="function")
def creds():
    return Credentials(
        dbname=os.getenv("DBNAME", Credentials.dbname),
        host=os.getenv("DBHOST", Credentials.host),
        port=os.getenv("DBPORT", Credentials.port),
        user=os.getenv("DBUSER", Credentials.user),
        password=os.getenv("DBPASSWORD", Credentials.password)
    )


@pytest.fixture(scope="function")
def psycopg2_conn_string(creds):
    return f"""
        dbname='{creds.dbname}' 
        user='{creds.user}' 
        host='{creds.host}' 
        port='{creds.port}' 
        password='{creds.password}'
    """


@pytest.fixture(scope="function")
def psycopg2_conn(psycopg2_conn_string):
    return pg.connect(psycopg2_conn_string)


@pytest.fixture(scope="function")
def sqlalchemy_conn_string(creds):
    return (
        "postgresql://"
        f"{creds.user}:{quote(creds.password)}@"
        f"{creds.host}:{creds.port}/{creds.dbname}"
    )


@pytest.fixture(scope="function")
def sqlalchemy_conn(sqlalchemy_conn_string):
    return sqlalchemy.create_engine(sqlalchemy_conn_string)


def test_customer_loan_balance(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
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
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 1
        assert rows[0][1] == 'Jane Doe'


def assert_decimal_equal(actual, expected, precision):
    assert abs(actual - expected) < precision

def test_branch_total_deposit(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            branch.name,
            SUM(bank_card.balance) AS total_deposit
        FROM 
            branch
            JOIN bank_card ON branch.id = bank_card.branch_id
        GROUP BY 
            branch.id
        ORDER BY total_deposit;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 3

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        assert_decimal_equal(row_dicts[0]['total_deposit'], Decimal('129000.00'), Decimal('0.01'))
        assert_decimal_equal(row_dicts[2]['total_deposit'], Decimal('228500.00'), Decimal('0.01'))


def test_branch_total_loan(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            branch.name,
            SUM(loan.amount) AS total_loan
        FROM 
            branch
            JOIN loan ON branch.id = loan.branch_id
        GROUP BY 
            branch.id;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 3
        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]
        total_loan_sum = sum(row['total_loan'] for row in row_dicts)
        assert_decimal_equal(total_loan_sum, Decimal('210100.00'), Decimal('0.01'))


def test_branch_summary(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
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
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 3

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        max_avg_balance = max(row['avg_balance'] for row in row_dicts)
        assert_decimal_equal(max_avg_balance, Decimal('36625.00'), Decimal('0.01'))


def test_transaction_details(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            t.id AS transaction_id,
            bc.card_number,
            t.amount,
            t.transaction_date,
            ROW_NUMBER() OVER (PARTITION BY bc.card_number ORDER BY t.transaction_date) AS transaction_number
        FROM 
            transaction t
            JOIN bank_card bc ON t.bank_card_id = bc.id
        ORDER BY 
            bc.card_number, 
            transaction_date;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) >= 2

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        first_transaction_id = row_dicts[0]['transaction_id']
        assert first_transaction_id == 1

        second_transaction_id = row_dicts[1]['transaction_id']
        assert second_transaction_id == 20

        first_transaction_amount = row_dicts[0]['amount']
        assert_decimal_equal(first_transaction_amount, Decimal('5000.00'), Decimal('0.01'))


def test_bank_card_transaction_count(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            bc.card_number, 
            COUNT(1) AS transaction_count
        FROM 
            transaction t
            JOIN bank_card bc ON t.bank_card_id = bc.id
        GROUP BY 
            bc.card_number;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 9

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        transaction_count_2345 = next(row['transaction_count'] for row in row_dicts if row['card_number'] == '2345-6789-0123-4567')
        assert transaction_count_2345 == 5

def test_top_three_bank_card_balances(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            card_number, 
            balance
        FROM 
            bank_card 
        ORDER BY 
            balance DESC 
        LIMIT 3;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 3

        expected_card_numbers = [
            '9012-3456-7890-1234',
            '8901-2345-6789-0123',
            '7890-1234-5678-9012'
        ]
        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        for row in row_dicts:
            card_number = row['card_number']
            assert card_number in expected_card_numbers
