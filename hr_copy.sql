--Task 1: Design the Token Authentication Table
--
--Question:
--Create a table app_tokens to store the credentials used for authentication between systems. The table should include:
--
--system_name (VARCHAR2)
--token (VARCHAR2)
--expiry_dt (DATE)
--Write the full CREATE TABLE script.
--

CREATE TABLE APP_TOKENS(
SYSTEM_NAME VARCHAR2(50) PRIMARY KEY,
TOKEN VARCHAR2(50),
EXPIRY_DT DATE
);


--Task 2: Insert Sample Tokens
--
--Question:
--Insert two records into the app_tokens table:
--
--System A with token TOKEN123A, valid for 3 days
--System B with token TOKEN123B, valid for 5 days
--

INSERT INTO APP_TOKENS(SYSTEM_NAME, TOKEN, EXPIRY_DT)
VALUES('SYSTEM A', 'TOKEN123A', SYSDATE);

INSERT INTO APP_TOKENS (SYSTEM_NAME, TOKEN, EXPIRY_DT)
VALUES('SYSTEM B', 'TOKEN123B', SYSDATE +2);


INSERT INTO APP_TOKENS (SYSTEM_NAME, TOKEN, EXPIRY_DT)
VALUES('SYSTEM ', 'TOKEN123C', SYSDATE -2);

SELECT * FROM APP_TOKENS



--Task 3: Write a Token Validation Procedure

--
--Question:
--Write a PL/SQL procedure validate_token(p_token IN VARCHAR2) that:
--
--* Checks if the token exists and is not expired
--* Returns 'Authenticated' or 'Invalid Token' using an OUT parameter



CREATE OR REPLACE PROCEDURE TKN_VALIDTN
(P_TOKEN IN VARCHAR2, P_STATUS OUT VARCHAR2)

AS

V_COUNT NUMBER;

BEGIN

SELECT COUNT(*) INTO V_COUNT FROM APP_TOKENS 
WHERE TRUNC(EXPIRY_DT) = TRUNC(SYSDATE);
IF V_COUNT > 0 THEN
P_STATUS := ('AUTHENTICATED');
ELSE
P_STATUS := ('INVALID TOKEN');
END IF;
EXCEPTION
WHEN OTHERS THEN
P_STATUS := 'AN ERROR OCCURED';
END;

BEGIN
TKN_VALIDTN(TOKEN123A, P_STATUS);
END;





CREATE OR REPLACE PROCEDURE TKN_VALIDTN
(P_TOKEN IN VARCHAR2, P_STATUS OUT VARCHAR2)

AS

V_COUNT NUMBER;

BEGIN

SELECT COUNT (*) INTO  V_COUNT FROM APP_TOKENS 
WHERE TOKEN = P_TOKEN
AND TRUNC(EXPIRY_DT) <= TRUNC(SYSDATE);
IF V_COUNT > 0 THEN
P_STATUS := ('AUTHENTICATED');
ELSE
P_STATUS := ('INVALID TOKEN');
END IF;
EXCEPTION
WHEN OTHERS THEN
P_STATUS := ('AN ERROR OCCURED');
END;



DECLARE

V_STATUS VARCHAR2(50);
BEGIN
TKN_VALIDTN('TOKEN123A', V_STATUS);
DBMS_OUTPUT.PUT_LINE(V_STATUS);
END;



--
--Task 4: Simulate API Call Using PL/SQL Block
--
--Question:
--Write an anonymous PL/SQL block that simulates a system calling the token validation procedure with a token and prints the authentication status using DBMS_OUTPUT.
--
-

CREATE OR REPLACE PROCEDURE CLEAR_EXP(P_TOKEN IN VARCHAR2, P_STATUS VARCHAR2)
AS


BEGIN
SELECT COUNT(*) IN V_COUNT FROM APP_TOKENS
WHERE TRUNC(SYSDATE) > TRUNC(EXPIRY_DT)
AND TOKEN = P_TOKEN

IF V_COUNT > 0 THEN
DELETE FROM APP_TOKENS WHERE TOKEN = 'TOKEN123A'
ELSIF
P_STATUS := 'NO EXPIRED RECORD'
ELSE 
INSERT INTO APP_TOKENS(SYSTEM_NAME, TOKEN, EXPIRY_DT)VALUES('SYSTEM C' 'TOKEN123C', SYSDATE +1);
END IF;
end;


--Task 5 : Auto Expiry Cleanup
--Question:
--Write a scheduled PL/SQL job or procedure to clean up expired tokens from the app_tokens table and insert new token

create or replace procedure clr_token(p_status out Varchar2) as 

cursor clr_cur is 
select * from app_tokens 
where sysdate > expiry_dt;

v_clr clr_cur%rowtype;

begin

open clr_cur;
loop
fetch clr_cur into v_clr;
exit when clr_cur%Notfound;

delete from app_tokens 
where token = v_clr.token;

end loop;

close clr_cur;

INSERT INTO APP_TOKENS(SYSTEM_NAME, TOKEN, EXPIRY_DT)
VALUES('SYSTEM C', 'TOKEN123C', SYSDATE +1);

p_status := 'expired token deleted and a new token inseretd';

exception

when others then
p_status := ('No record found! Error occured');
end;

declare
v_status varchar2(50);
begin
clr_token(v_status);
dbms_output.put_line('v_status');
end;

