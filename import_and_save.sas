libname path "P:\SAS_ASSIGNMENT_1";

%macro import_data;
%do i = 1 %to 4;
	%do year = 2012 %to 2018;
		%let outdata = q&i._&year.;
		%put &outdata;
		proc import datafile = "P:\SAS_ASSIGNMENT_1\individual_security_&year._q&i.\q&i._&year._all.csv" out = &outdata dbms = csv replace;
		run;
		%put "P:\SAS_ASSIGNMENT_1\individual_security_&year._q&i.\q&i._&year._all.csv";
	%end;
%end;

proc import datafile = "P:\SAS_ASSIGNMENT_1\individual_security_2019_q1\q1_2019_all.csv" out = q1_2019 dbms = csv replace;
run;

proc import datafile = "P:\SAS_ASSIGNMENT_1\individual_security_2019_q2\q2_2019_all.csv" out = q2_2019 dbms = csv replace;
run;

DATA total;
set  %do year = 2012 %to 2018;%do i = 1 %to 4;q&i._&year.%end;%end;q1_2019 q2_2019;
%mend;

%import_data;

proc contents data=total;
run;

proc export data = total outfile = "P:\SAS_ASSIGNMENT_1\total.csv" dbms = csv replace;
run;

proc import datafile = "P:\SAS_ASSIGNMENT_1\total.csv" out = total dbms = csv replace;
run;

/*generate correct names*/
proc contents data = total out = temp(keep = name) noprint;
run;

/*** Check the variable names **/
proc print data = temp;
run;

/*** Use string fucntions to generate correct variable names **/
data invars;
	set temp;
	if substr(name, length(name)-5, 6) = "__000_" then name2 = substr(name, 1, length(name)-6);
	else name2 = name;
	rename = catx("=", name, name2);
run;

/*** Check the modification of variable names **/
proc print data = invars;
run;

/******** Store the variable renaming list into a macro variable ************/
proc sql noprint;
	select rename
	into: var_renames separated by " "
	from invars;
quit;

/*** Check the variable renaming list **/
%put &var_renames;

/*compute metrics and rename*/
data total_recode;
	set total(rename = (&var_renames.));
	/*Create required variables*/
	date = input(put(date, 8.), YYMMDD8.);
	format date MMDDYY8.;

	Trade = LitTrades + TradesForHidden;

	TradeVol = TradeVolForHidden + LitVol;

	if LitTrades ne 0 then Cancel_to_Trade = Cancels / LitTrades; else Cancel_to_Trade = .;

	if OrderVol ne 0 then Trade_to_Order_Volume = LitVol / OrderVol; else Trade_to_Order_Volume = .;

	if TradesForHidden ne 0 then Hidden_Rate = Hidden / TradesForHidden; else Hidden_Rate = .;
	if TradeVolForHidden ne 0 then Hidden_Volume = HiddenVol / TradeVolForHidden; else Hidden_Volume = .; 
	if TradesForOddLots ne 0 then OddLots_Rate = OddLots/TradesForOddLots; else OddLots_Rate = .;
	if TradeVolForOddLots ne 0 then OddLots_Volume = OddLotVol / TradeVolForOddLots; else OddLots_Volume = .;
	/*Use array this time to convert rate to percentage*/
	array rate_array{5} Trade_to_Order_Volume Hidden_Rate Hidden_Volume OddLots_Rate OddLots_Volume;
	do i = 1 to 5;
		rate_array{i} = 100 * rate_array{i};
	end;

	drop i;
run;


proc print data=total_recode(obs=10);
run;

/*store the list of variable names*/

/*** Read the column of variable names again **/
proc contents data = total_recode  out = invars(keep = varnum name) noprint;
run;

proc sql noprint;
	select name
	into:var_names separated by " "
	from invars
	where varnum >= 8
	order by varnum;
quit;

%put &var_names;

/* Count the number of variables in the string */ 
%let numvars = %sysfunc(countw(&var_names.));

%put &numvars;


%macro auto_var_list_1;

/******** Store each variables names into a macro variable which can be used in the procedures **********/
%do i = 1 %to &numvars.;                                                                                                             
	%let var_name&i = %qscan(&var_names, &i, %str(" "));
	%put &&var_name&i..; 
%end;

%mend;

%auto_var_list_1;

/*compute the stats using the total dataset*/
%macro compute_stats(dataset, security, sample);

%do i = 1 %to &numvars.;                                                                                                             
	%let var_name&i = %qscan(&var_names, &i, %str(" ")); 
%end;

proc means data = &dataset(where = (security = "&security")) mean p25 median p75 std noprint;
	by date;
	var %do i = 1 %to &numvars. - 1; &&var_name&i.. %end; &&var_name&i..;
	output out = Mean&security.&sample. mean = ;
	output out = p25&security.&sample. p25 = ;
	output out = Median&security.&sample. median = ;
	output out = p75&security.&sample. p75 = ;
	output out = std&security.&sample. std = ;
run;	

%mend;

%compute_stats(total_recode, ETF, total);
%compute_stats(total_recode, Stock, total);

proc means data=total_recode(where = (security = "Stock")) qmethod=p2
	mean p25 median p75 std;
run;

%macro sample_100(security);
	proc sql;
		create table &security._ticker as
		select unique(q1_2012.Ticker) as Ticker
		from q1_2012
		where (q1_2012.security="&security");
	quit;
	
	proc surveyselect data = &security._ticker noprint
	method = srs 
    n = 100 
    seed = 123 
    out = sample_&security;
    run;

	proc sql;
		create table total_sample_&security as
		select *
		from total_recode as l
		right join sample_&security as r
		on l.Ticker = r.Ticker;
	quit;

	proc sort data=total_sample_&security;
		by  date;
	run;
%mend;

%sample_100(Stock);
%sample_100(ETF);

proc print data=total_sample_stock(obs=10);
proc print data=total_sample_etf(obs=10);

/*compute stats by date*/
%compute_stats(total_sample_stock, Stock, 100);
%compute_stats(total_sample_ETF, ETF, 100);

%macro report(security);

/******** Generate the list for plotting variables automatically **********/
%do i = 1 %to &numvars.;
	%let var_name&i = %qscan(&var_names, &i, %str(" ")); 
	%let plot_var_name&i = &&var_name&i.. * Date;
	%put &&plot_var_name&i..;
%end;

/*************** Generate the graphs for ETF and note that macro can be used inside the macro ************/
%let path=P:\SAS_ASSIGNMENT_1;

%macro generate_graphs(desc, sec);
title "&desc&sec";
symbol interpol=join Color=blue value=point width=0.05;
proc gplot data = &desc&sec.100; 
	plot %do i = 1 %to &numvars. - 1; &&plot_var_name&i.. %end; &&plot_var_name&i..;
run; 
quit;
%mend;

ods pdf file = "&path\graph&security.100.pdf";
%generate_graphs(Mean, &security);
%generate_graphs(p25, &security);
%generate_graphs(Median, &security);
%generate_graphs(p75, &security);
%generate_graphs(std, &security);
ods pdf close;
	
%mend;

%report(Stock);
%report(ETF);


