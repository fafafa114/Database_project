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