--Create a table app_tokens to store the credentials used for authenticationbetween systems. The table should include:
--system_name (VARCHAR2)
--token (VARCHAR2)
--expiry_dt (DATE)
--Write the full CREATE TABLE script

create table app_tokens (
system_name varchar2(100),
token varchar2(100),
expiry_dt date
);


select * from app_tokens

desc app_tokens


--Task 2: Insert Sample Tokens
--Question:
--Insert two records into the app_tokens table:
--System A with token TOKEN123A, valid for 3 days


insert into app_tokens(system_name, token, expiry_dt)
values('System_A', 'TOKEN123A', to_date('05/02/2025', 'mm-dd-yyyy'));

update app_tokens 
set expiry_dt = to_date('05/05/2025')
where expiry_dt = to_date('05/02/2025')

select * from app_tokens

delete from app_tokens where rowid > (select min(rowid)from app_tokens)

insert into app_tokens(system_name, token, expiry_dt)
values('System_B', 'TOKEN123B', to_date('05/07/2025', 'mm-dd-yyyy'));




--Task 3: Write a Token Validation Procedure
--Question:
--Write a PL/SQL procedure validate_token(p_token IN VARCHAR2) that:
--* Checks if the token exists and is not expired
--* Returns 'Authenticated' or 'Invalid Token' using an OUT parameter

Create or replace procedure tkn_validtn(
p_token IN varchar2
)
is
v_system_name   app_tokens.system_name%type;
v_token     app_tokens.token%type;
v_expiry_dt  app_tokens.expiry_dt%type;

begin
select system_name, token, expiry_dt into v_system_name, v_token, v_expiry_dt
from app_tokens where token = p_token;

dbms_output.put_line('Token exist: '|| v_token);
dbms_output.put_line('Token not expired' || expiry_dt);

end;
/



--Task 4: Simulate API Call Using PL/SQL Block
--Question:
--Write an anonymous PL/SQL block that simulates a system calling the token
--validation procedure with a token and prints the authentication status using
--DBMS_OUTPUT.

begin
tkn_validtn()
end;

Task 5 : Auto Expiry Cleanup
Question:

--Write a scheduled PL/SQL job or procedure to clean up expired tokens from the
--app_tokens table and insert new token


create or replace procedure expired_tkns(
p_expired IN app_tokens.expiry_dt%type

begin 


if(to_date('05/05/2025')) then
delete from app_tokens where system_name = 'SYSTEM A';
end if;

dbms_output.put_line('Token deleted')


insert into app_tokens(SYSTEM_NAME, TOKEN, EXPIRY_DT)
values('SYSTEMC', 'TOKEN123C', to_date('05/05/2025', 'dd-mm-yyyy');

dbms_output.put_line('New token inserted');

end;


