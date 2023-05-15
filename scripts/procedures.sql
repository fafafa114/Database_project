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
