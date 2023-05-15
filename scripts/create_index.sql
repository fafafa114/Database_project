
CREATE INDEX "customer_pid"
    ON customer
    USING btree
    (pid);

CREATE INDEX "bank_card_customer_id"
    ON bank_card
    USING btree
    (customer_id);

CREATE INDEX "bank_card_deposit_type_id"
    ON bank_card
    USING btree
    (deposit_type_id);

CREATE INDEX "bank_card_branch_id"
    ON bank_card
    USING btree
    (branch_id);

CREATE INDEX "transfer_sender_card_id"
    ON transfer
    USING btree
    (sender_card_id);

CREATE INDEX "transfer_receiver_card_id"
    ON transfer
    USING btree
    (receiver_card_id);

CREATE INDEX "transaction_bank_card_id"
    ON transaction
    USING btree
    (bank_card_id);

CREATE INDEX "transaction_transfer_id"
    ON transaction
    USING btree
    (transfer_id);

CREATE INDEX "bank_employee_branch_id"
    ON bank_employee
    USING btree
    (branch_id);

CREATE INDEX "loan_deposit_type_id"
    ON loan
    USING btree
    (deposit_type_id);

CREATE INDEX "loan_branch_id"
    ON loan
    USING btree
    (branch_id);

CREATE INDEX "loan_customer_id"
    ON loan
    USING btree
    (customer_id);
