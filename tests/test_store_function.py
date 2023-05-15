# create the triggers before insert
# create functions before executing the tests
# This test works only on the basis of insert_data.sql
import os
import pytest
from dataclasses import dataclass
from urllib.parse import quote
import psycopg2 as pg
import sqlalchemy
import sys
from decimal import Decimal

def assert_decimal_equal(actual, expected, precision):
    assert abs(actual - expected) < precision

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


def test_get_customer_loan_summary(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT * FROM get_customer_loan_summary(1);
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 1

        column_names = result.keys()
        row_dict = dict(zip(column_names, rows[0]))

        assert_decimal_equal(row_dict['total_loans'], Decimal('10100.00'), Decimal('0.01'))
        assert row_dict['number_of_loans'] == 2
        assert_decimal_equal(row_dict['average_loan'], Decimal('5050.0000000000000000'), Decimal('0.01'))

def test_get_employee_branch_summary(sqlalchemy_conn):
    with sqlalchemy_conn.connect() as connection:
        query = sqlalchemy.text("""
        SELECT * FROM get_employee_branch_summary(1);
        """)
        result = connection.execute(query)
        rows = result.fetchall()
        assert len(rows) == 1

        column_names = result.keys()
        row_dict = dict(zip(column_names, rows[0]))

        assert row_dict['number_of_employees'] == 1
        assert_decimal_equal(row_dict['average_salary'], Decimal('1000.0000000000000000'), Decimal('0.01'))
        assert_decimal_equal(row_dict['total_salary'], Decimal('1000.00'), Decimal('0.01'))
