create Table welcome_mail_log(
log_id Number Generated always as identity Primary Key,
employee_id Number,
date_sent Date default SYSDATE,
status Varchar2(50) Default 'Not Sent'
);





CREATE TABLE companies (
    company_id      NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    company_name    VARCHAR2(100) NOT NULL,
    industry        VARCHAR2(50),
    location        VARCHAR2(100),
    founded_year    NUMBER(4)
);




CREATE TABLE employees (
    employee_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    first_name      VARCHAR2(50),
    last_name       VARCHAR2(50),
    email           VARCHAR2(100) UNIQUE NOT NULL,
    phone_number    VARCHAR2(20),
    hire_date       DATE NOT NULL,
    job_id          VARCHAR2(10) NOT NULL,
    salary          NUMBER(8,2),
    commission_pct  NUMBER(2,2),
    manager_id      NUMBER,
    department_id   NUMBER,
    company_id      NUMBER,
    CONSTRAINT fk_company
        FOREIGN KEY (company_id)
        REFERENCES companies(company_id)
);








CREATE OR REPLACE PROCEDURE send_welcome_mail_to_employee(p_employee_id IN NUMBER)
IS
    v_email         VARCHAR2(100);
    v_company_name  VARCHAR2(100);
    v_body          CLOB;
    v_count         NUMBER;
BEGIN
    SELECT e.email, c.company_name
    INTO v_email, v_company_name
    FROM employees e
    JOIN companies c ON e.company_id = c.company_id
    WHERE e.employee_id = p_employee_id;

    SELECT COUNT(*)
    INTO v_count
    FROM welcome_mail_log
    WHERE employee_id = p_employee_id;

    IF v_count = 0 THEN
        v_body := 'Welcome to ' || v_company_name || 
                  '. We are delighted to have you as one of us.' || UTL_TCP.CRLF || UTL_TCP.CRLF;

        APEX_MAIL.SEND(
            p_to    => v_email,
            p_from  => 'hr@company.com',
            p_subj  => 'Welcome to ' || v_company_name,
            p_body  => v_body
        );

        APEX_MAIL.PUSH_QUEUE;

        INSERT INTO welcome_mail_log (employee_id, date_sent, status)
        VALUES (p_employee_id, SYSDATE, 'SENT');
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error sending mail to employee_id ' || p_employee_id || ': ' || SQLERRM);
END;
/








CREATE OR REPLACE PROCEDURE send_welcome_mail
IS
    CURSOR Mail_Cursor IS
        SELECT e.employee_id,
               e.hire_date,
               e.company_id,
               c.company_name,
               e.email
        FROM employees e
        JOIN companies c ON c.company_id = e.company_id
        WHERE hire_date <= SYSDATE
          AND hire_date IS NOT NULL
          AND email IS NOT NULL;

    CURSOR Schedule_Mail_Cursor IS
        SELECT e.employee_id,
               e.hire_date
        FROM employees e
        WHERE e.hire_date > SYSDATE;

    v_count    NUMBER;
    l_body     CLOB;
    l_jobname  VARCHAR2(100);
BEGIN
    -- IMMEDIATE MAIL FOR CURRENT EMPLOYEES
    FOR emp IN Mail_Cursor LOOP
        SELECT COUNT(*)
        INTO v_count
        FROM welcome_mail_log
        WHERE employee_id = emp.employee_id;

        IF v_count = 0 THEN
            BEGIN
                l_body := 'Welcome to ' || emp.company_name ||
                          '. We are delighted to have you as one of us.' || UTL_TCP.CRLF || UTL_TCP.CRLF;

                APEX_MAIL.SEND(
                    p_to    => emp.email,
                    p_from  => 'hr@company.com',
                    p_subj  => 'Welcome to ' || emp.company_name,
                    p_body  => l_body
                );

                APEX_MAIL.PUSH_QUEUE;

                INSERT INTO welcome_mail_log (employee_id, date_sent, status)
                VALUES (emp.employee_id, SYSDATE, 'SENT');

            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Error sending mail: ' || SQLERRM);
            END;
        END IF;
    END LOOP;

    -- SCHEDULE MAIL FOR FUTURE HIRES
    FOR hired_emp IN Schedule_Mail_Cursor LOOP
        l_jobname := 'SEND_WELCOME_MAIL_' || hired_emp.employee_id;

        BEGIN
            DBMS_SCHEDULER.CREATE_JOB(
                job_name        => l_jobname,
                job_type        => 'PLSQL_BLOCK',
                job_action      => 'BEGIN send_welcome_mail_to_employee(' || hired_emp.employee_id || '); END;',
                start_date      => hired_emp.hire_date,
                enabled         => TRUE
            );
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error scheduling job for emp ' || hired_emp.employee_id || ': ' || SQLERRM);
        END;
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Unexpected error: ' || SQLERRM);
END;
/