/* This session covers access to WRDS through SAS */

libname path "P:\SAS_Session\Session_5";

%let wrds = wrds.wharton.upenn.edu 4016;
options comamid = TCP remote = WRDS;
signon username = _prompt_;
rsubmit;

libname wrds '/wrds/crsp/sasdata/a_stock';

/* Get monthly information for stocks with price greater than 100 since 2015 */

PROC SQL;               
	create table temp as
	select permno, date, prc, ret 
	from wrds.msf
	where year(date) >= 2015 and prc > 100;
quit;

proc download data = temp out = path.msf;
run;

endrsubmit;
