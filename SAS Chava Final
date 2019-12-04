libname path "Q:/Data-ReadOnly/CRSP/";

proc contents data=path.dsf(obs=10);
run;

proc import datafile = "P:\records.csv" out = records dbms = csv replace;
GUESSINGROWS=MAX;
run;

proc print data=records(obs=10);
run;

proc sql;
	create table data as
	select CUSIP, DATE, VOL, RET from 
	path.dsf as dsf
	where dsf.CUSIP in (select CUSIP from records);
quit;

proc export data = data outfile = "P:\sub_dsf.csv" dbms = csv replace;
