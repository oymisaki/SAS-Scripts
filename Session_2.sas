/* This session covers joining tables */

libname path "P:\SAS_Session\Session_2";

/* Overview of proc import */

proc import datafile = "P:\SAS_Session\Session_2\left_table.csv" out = left_table dbms = csv replace;
run;

proc import datafile = "P:\SAS_Session\Session_2\right_table.csv" out = right_table dbms = csv replace;
run;

/* Another way to import data */

data left_table;
	%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
	infile 'P:\SAS_Session\Session_2\left_table.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;
	informat ID best32.;
	informat NAME $8.;
	format ID best12.;
	format NAME $8.;
	input ID NAME $;
	if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data right_table;
	%let _EFIERR_ = 0;
	infile 'P:\SAS_Session\Session_2\right_table.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;
	informat NAME $8.;
	informat CONTACT best32.;
	format NAME $8.;
	format CONTACT best12.;
	input NAME $ CONTACT;
	if _ERROR_ then call symputx('_EFIERR_',1);
run;

/* Sort both tables before merging them */

proc sort data=left_table;
	by name;
run;

proc sort data=right_table;
	by name;
run;

/* Basic inner join */
/* returns a result table for all the rows in a table that have one or more matching rows in the other tables */

data inner_join;
	merge left_table(in = a) right_table(in = b);
	by name;
	if a & b;
run;

/* outer joins */
/* outer joins are inner joins that have been augmented with rows that did not match with any row from the other table in the join */

/*Simple left outer joins */

data left_join;
	merge left_table(in = a) right_table(in = b);
	by name;
	if a;
run;

/*Simple right outer join */

data right_join;
	merge left_table(in = a) right_table(in = b);
	by name;
	if b;
run;

/* Full join */

data full_join;
	merge left_table right_table;
	by name;
run;


/* Another way to join tables by using proc sql (no need to sort data before joining) */
/* Basic inner join */

proc sql;
	create table inner_join as
	select *
	from left_table as l 
	inner join right_table as r
	on l.name = r.name;
quit;

/*Simple left outer joins */

proc sql;
	create table left_join as
	select *
	from left_table as l 
	left join right_table as r
	on l.name = r.name;
quit;

/*Simple right outer join */

proc sql;
	create table right_join as
	select 
		l.id,
		r.name as name,
		r.contact
	from left_table as l 
	right join right_table as r
	on l.name = r.name;
quit;

/* Full join */

proc sql;
	create table full_join as
	select
		l.id, 
		coalesce(l.name, r.name) as name,
		r.contact
	from left_table as l 
	full join right_table as r
	on l.name = r.name;
quit;
