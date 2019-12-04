/* This session covers library, basic DATA step, and PROC step */

libname path "P:\SAS_Session\Session_1";

/* To start, check the metadata and header information of the table */

proc contents data = path.comp;
run;

proc print data = path.comp(obs = 20);
run;

/* Only interested in 2006 data and non-missing close price and common shares outstanding */ 
/* use drop to drop the variables...but highlight the use of 'keep' */

%let variables = gvkey datadate conm cusip cshom prccm prchm prclm;
%let y = 2006 2007;

data one;
	set path.comp(keep = &variables.);
	year = year(datadate);
	if year in (2006 2007);
	* if year in (&y.);
	* if year = 2006;
	* if year ~= 2007;
	if prccm = . then delete;
	if cshom = . then delete;
	/* array miss{2} prccm cshom;
	do i = 1 to dim(miss);
		if miss(i)=. then delete;
	end;
	drop i; */
run;

/* Random Sampling using proc surveyselect */

proc surveyselect data = one
	method = srs 
	n = 100 
	seed = 123 
	out = random_sampled_comp;
run;

/* Sort data for stratified sampling */

proc sort data = one;
	by year;
run;

proc surveyselect data = one
	method = srs 
	n = 100 
	seed = 123 
	out = strata_sampled_comp;
	strata year;
run;

/* Sort data by company identifier and date */

proc sort data = one;
	by gvkey datadate;
run;

/* create new variables using variables already present */

data two;
	set one;
	by gvkey datadate;
	year = year(datadate);
	monthly_diff = prchm - prclm;
	market_cap = prccm*cshom; 
	lag_prccm = lag(prccm);
	ret = prccm/lag_prccm - 1;
	if first.gvkey then ret = .;
run;

/* Sort data and create summary statistics */

proc sort data = two;
	by year;
run;

ods pdf file = "P:\SAS_Session\Session_1\sample.pdf";

proc means data = two n mean std p25 p75 min max;
	by year;
	var prccm;
run;

proc corr data= two;
	var prccm prchm prclm;
run;

ods pdf close;

proc sort data=two;
	by gvkey datadate;
run;

/* Display just the average monthly closing price for a specific company */

data avg_closing_monthly;
	set two;
	by gvkey datadate;
	retain sum count;
	if first.gvkey then do;
		sum = prccm;
		count = 1;
	end;
	else do;
		sum = sum + prccm;
		count = count + 1;
	end;
	avg_prccm = sum/count;
	* if last.gvkey then output;
	* keep gvkey count avg_prccm;
run;

/* Save final table as a permanent sas dataset */

data path.comp2;
	set two;
run;

/* Save final table as a csv file for analysis in R and Python */

proc export data = two outfile = "P:\SAS_Session\Session_1\comp2.csv" dbms = csv replace;
run;
