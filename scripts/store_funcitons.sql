CREATE FUNCTION get_customer_loan_summary(p_customer_id INT)
RETURNS TABLE(
    total_loans DECIMAL(12, 2), 
    number_of_loans BIGINT, 
    average_loan DECIMAL(12, 2)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        SUM(l.amount) AS total_loans, 
        COUNT(l.id) AS number_of_loans, 
        AVG(l.amount) AS average_loan
    FROM 
        loan l
    WHERE 
        l.customer_id = p_customer_id;
END;
$$ LANGUAGE plpgsql;


CREATE FUNCTION get_employee_branch_summary(p_employee_id INT)
RETURNS TABLE(
    number_of_employees BIGINT, 
    average_salary DECIMAL(12, 2), 
    total_salary DECIMAL(12, 2)
) AS $$
DECLARE 
    v_branch_id INT;
BEGIN
    SELECT branch_id INTO v_branch_id FROM bank_employee WHERE id = p_employee_id;

    RETURN QUERY
    SELECT 
        COUNT(e.id) AS number_of_employees, 
        AVG(e.salary) AS average_salary, 
        SUM(e.salary) AS total_salary
    FROM 
        bank_employee e
    WHERE 
        e.branch_id = v_branch_id;
END;
$$ LANGUAGE plpgsql;

