libname path "Q:\Data-ReadOnly\CRSP";

proc contents data=path.dsf;
run;

data dsf;
	set path.dsf;
	year = year(date);
	if 2003 < year < 2019;
	spread = ASKHI - BIDLO;
	keep date RET PRC spread VOL HSICCD;

proc import datafile = "P:\ASSIGNMENT_5\dsf.csv" out = dsf dbms = csv replace;
run;

proc print data=dsf(obs=10);
run;

proc export data = dsf outfile = "P:\ASSIGNMENT_5\dsf.csv" dbms = csv replace;
run;

/* ---------------- 2. compute descriptive statistics for the whole sample period --------------- */

proc means data = dsf mean p25 median p75 std noprint;
    output out = dsf_stat;
run;

proc print data = dsf_stat;
run;

/* --------------------------- 3. (a) compute daily averages over date -------------------------- */
%macro compute_stat_over_var(dataset, stat);
	proc sort data=&dataset;
		by date;
	run;

	proc means data = &dataset &stat. noprint;
		by date;
		output out = &dataset._&stat. &stat= ;
	run;
%mend;

%compute_stat_over_var(dsf, mean);

proc print data = dsf_mean(obs=10);
run;

/* -------------------------------- 3. (b) plot average over date ------------------------------- */

proc contents data = dsf_mean out = invars(keep = name) noprint;
run;

proc sql noprint;
	select name
	into: var_names separated by " "
	from invars;
quit;

%put &var_names;

/* count var names */
%let numvars = %sysfunc(countw(&var_names.));

%put &numvars;

%macro report(dataset, x_axis);

/* Generate the list for plotting variables automatically */
%do i = 1 %to &numvars.;
	%let var_name&i = %qscan(&var_names, &i, %str(" ")); 
	%let plot_var_name&i = &&var_name&i.. * &x_axis;
%end;

%let path=P:\ASSIGNMENT_5;

proc sort data=&dataset;
	by &x_axis;

%macro generate_graphs();
title "&dataset";
symbol interpol=join Color=blue value=point width=0.05;
proc gplot data = &dataset; 
	plot %do i = 1 %to &numvars. - 1; &&plot_var_name&i.. %end; &&plot_var_name&i..;
run; 
quit;
%mend;

ods pdf file = "&path\graph&dataset..pdf";
%generate_graphs();
ods pdf close;
	
%mend;

%report(dsf_mean, date);

/* ------------------------------------ CAPM model regression ----------------------------------- */

data dsi;
	set path.dsi;
	year = year(date);
	if 2003 < year < 2019;
	rmt = ewretd;
	keep date rmt;
run;

proc sql;
	create table dsf_rmt as
	select *
	from dsf as l left join dsi as  r
	on l.date = r.date;
quit;

proc contents data=dsf_rmt;
run;

proc sort data=dsf_rmt;
	by hsiccd;
run;

proc reg data=dsf_rmt noprint;
	by hsiccd;
	model ret = rmt;
	output out=b
		p=yhat
		r=yresid;
run;

proc print data = b(obs=10);
run;

proc sql;
	create table vol_res as
	select
	HSICCD as stock, 
	std(ret) as total_vol, 
	std(yhat-yresid) as system_vol,
	std(yresid) as idio_vol
	from b
	group by HSICCD;
quit;

proc print data = vol_res(obs=10);
run;

/* --------------------- 4. (d) sort by system vol and calculate performance -------------------- */

data _NULL_;
 if 0 then set vol_res nobs=n;
 call symputx('totobs',n);
 stop;
run;
%put no. of observations = &totobs;

proc sort data=vol_res;
	by system_vol;
run;

proc contents data=vol_res;
run;

data top_q20_vol;
	set vol_res;
	if _n_ / &totobs > 0.2 then stop;

data tail_q20_vol;
	set vol_res;
	if _n_ / &totobs > 0.8;

proc print data = top_q20_vol(obs=10);
run;

proc print data = tail_q20_vol(obs=10);
run;

proc sql;
	create table portfolio_ret as
	select topret, tailret, top.DATE
	from (	select avg(b.ret) as topret, DATE from top_q20_vol 
		as top_q20 
	 	inner join b 
		on top_q20.stock = b.HSICCD
		group by DATE) as top
		full join
		(	select avg(b.ret) as tailret, DATE from tail_q20_vol 
		as tail_q20 
	 	inner join b 
		on tail_q20.stock = b.HSICCD
		group by DATE) as tail
		on top.DATE = tail.DATE;
quit;

proc print data = portfolio_ret(obs=10);
run;

/* geenrate performance */
proc sql;
	create table summary as
	select avg(topret - tailret) as daily_return, std(topret - tailret) as daily_vol
	from portfolio_ret;
quit;

proc print data=summary;
run;

/* ---------------------- 4. (e) sort by idio vol and calculate performance --------------------- */

proc sort data=vol_res;
	by idio_vol;
run;

data top_q20_vol;
	set vol_res;
	if _n_ / &totobs > 0.2 then stop;

data tail_q20_vol;
	set vol_res;
	if _n_ / &totobs > 0.8;

proc print data = top_q20_vol(obs=10);
run;

proc print data = tail_q20_vol(obs=10);
run;

proc sql;
	create table portfolio_ret as
	select topret, tailret, top.DATE
	from (	select avg(b.ret) as topret, DATE from top_q20_vol 
		as top_q20 
	 	inner join b 
		on top_q20.stock = b.HSICCD
		group by DATE) as top
		full join
		(	select avg(b.ret) as tailret, DATE from tail_q20_vol 
		as tail_q20 
	 	inner join b 
		on tail_q20.stock = b.HSICCD
		group by DATE) as tail
		on top.DATE = tail.DATE;
quit;

proc print data = portfolio_ret(obs=10);
run;

/* generate performance */
proc sql;
	create table summary as
	select avg(topret - tailret) as daily_return , std(topret - tailret) as daily_vol
	from portfolio_ret;
quit;

proc print data=summary;
run;









