/* This session covers some advanced techniques in SAS */

options ls=70 nodate nocenter mprint;

%let path = P:\SAS_Session\Session_6;

proc import out = midas_2014q2 datafile = "&path\q2_2014_all.csv"
	dbms = csv 
	replace;
	getnames = yes;
run;

/*** Read the column of variable names **/
proc contents data = midas_2014q2 out = temp(keep = name) noprint;
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

/*** Recode the main dataset and rename all variables when reading the data **/
data midas_2014q2_recode;
	set midas_2014q2(rename = (&var_renames.));
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

/*** Read the column of variable names again **/
proc contents data = midas_2014q2_recode out = invars(keep = varnum name) noprint;
run;

proc print data = invars;
run;

/******** Store the list of variables names needed into a macro variable which can be used in the procedures **********/
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


%macro auto_var_list_2;

/******** Another way to store each variables names into a macro variable **********/
proc sql noprint;
	select name
	into:same_var_name1 -: same_var_name&numvars.
	from invars
	where varnum >= 8
	order by varnum;
quit;

%do i = 1 %to &numvars.;
	%put &&same_var_name&i..;
%end;

%mend;

%auto_var_list_2;


%macro compute_stats;

%do i = 1 %to &numvars.;                                                                                                             
	%let var_name&i = %qscan(&var_names, &i, %str(" ")); 
%end;

/************* Compute desc stats for ETF and save them in different datasets*************/
proc means data = midas_2014q2_recode(where = (security = 'ETF')) mean p25 median p75 std noprint;
	by date;
	var %do i = 1 %to &numvars. - 1; &&var_name&i.. %end; &&var_name&i..;
	output out = MeanETF100 mean = ;
	output out = p25ETF100 p25 = ;
	output out = MedianETF100 median = ;
	output out = p75ETF100 p75 = ;
	output out = stdETF100 std = ;
run;	

%mend;

%compute_stats;


%macro report;

/******** Generate the list for plotting variables automatically **********/
%do i = 1 %to &numvars.;
	%let var_name&i = %qscan(&var_names, &i, %str(" ")); 
	%let plot_var_name&i = &&var_name&i.. * Date;
	%put &&plot_var_name&i..;
%end;

/*************** Generate the graphs for ETF and note that macro can be used inside the macro ************/
%macro generate_graphs(desc, sec);
title "&desc&sec";
proc gplot data = &desc&sec.100; 
	plot %do i = 1 %to &numvars. - 1; &&plot_var_name&i.. %end; &&plot_var_name&i..;
run; 
quit;
%mend;

ods pdf file = "&path\graphETF100.pdf";
%generate_graphs(Mean, ETF);
%generate_graphs(p25, ETF);
%generate_graphs(Median, ETF);
%generate_graphs(p75, ETF);
%generate_graphs(std, ETF);
ods pdf close;
	
%mend;

%report;
