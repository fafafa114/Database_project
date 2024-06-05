# create the triggers before insert
# create views before executing the tests
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

def assert_decimal_equal(actual, expected, precision):
    assert abs(actual - expected) < precision

def test_view_customer_balance(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            * 
        FROM 
            view_customer_balance;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 10

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        max_total_deposit = max(row['total_deposit'] for row in row_dicts)
        assert_decimal_equal(max_total_deposit, Decimal('98000.00'), Decimal('0.01'))

        first_row_id = row_dicts[0]['id']
        assert first_row_id == 9

        second_row_id = row_dicts[1]['id']
        assert second_row_id == 8


def test_view_bank_card_balance(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            * 
        FROM 
            view_bank_card_balance;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 20

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        max_balance = max(row['balance'] for row in row_dicts)
        assert_decimal_equal(max_balance, Decimal('89000.00'), Decimal('0.01'))

        min_balance = min(row['balance'] for row in row_dicts)
        assert_decimal_equal(min_balance, Decimal('0.00'), Decimal('0.01'))

        emily_wilson_row = next((row for row in row_dicts if row['customer_name'] == 'Emily Wilson'), None)
        assert emily_wilson_row is not None


def test_view_transaction_history(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT 
            * 
        FROM 
            view_transaction_history;
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 30

        column_names = result.keys()
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        amount_sum = sum(row['amount'] for row in row_dicts)
        mx = max(row['amount'] for row in row_dicts)
        assert_decimal_equal(amount_sum, Decimal('0.00'), Decimal('0.01'))
        assert_decimal_equal(mx, Decimal('10000'), Decimal('0.01'))


def test_hide_customer_columns(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("SELECT * FROM hide_customer;")
        result = connection.execute(query)
        rows = result.fetchall()

        column_names = result.keys()
        assert 'id' in column_names
        assert 'name' in column_names
        assert 'pid' in column_names


def test_hide_bank_card_columns(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("SELECT * FROM hide_bank_card;")
        result = connection.execute(query)
        rows = result.fetchall()

        column_names = result.keys()
        assert 'id' in column_names
        assert 'card_number' in column_names
        assert 'balance' in column_names
        assert 'customer_id' in column_names
        assert 'deposit_type_id' in column_names
        assert 'branch_id' in column_names


def test_hide_bank_employee_columns(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("SELECT * FROM hide_bank_employee;")
        result = connection.execute(query)
        rows = result.fetchall()

        column_names = result.keys()
        assert 'id' in column_names
        assert 'name' in column_names
        assert 'pid' in column_names
        assert 'branch_id' in column_names
        assert 'email' in column_names
        assert 'salary' in column_names

def test_branch_deposit_summary(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("SELECT * FROM branch_deposit_summary;")
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 3

        column_names = result.keys()
        assert 'branch_id' in column_names
        assert 'branch_name' in column_names
        assert 'branch_address' in column_names
        assert 'total_deposit_types' in column_names
        assert 'average_interest_rate' in column_names

        branch_interest_rates = {
            'C Branch': Decimal('0.05428'),
            'A Branch': Decimal('0.040000'),
            'B Branch': Decimal('0.03285')
        }
        row_dicts = [dict(zip(column_names, row)) for row in rows]

        for row in row_dicts:
            branch_name = row['branch_name']
            average_interest_rate = row['average_interest_rate']
            assert branch_name in branch_interest_rates
            assert_decimal_equal(average_interest_rate, branch_interest_rates[branch_name], Decimal('0.001'))
