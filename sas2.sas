libname path "C:/Users/lyang383/Downloads/funda";

%let years = 1971 1974 1979 1984 1988 1990 1995 1999 2002 2005 2008 2012 2015 2017;
%put &years;

/*read data and filter the dataset as the paper, note, the outliers are not removed*/
data sub_funda;
	set path.funda;
	year = year(datadate);
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and con-
	sol='C';
	if 1970 < fyear < 2019;
	if 5999 < sich < 7000 then delete;
	if 4899 < sich < 5000 then delete;
	if compst ne 'AB';
	if scf = 4 or scf = 5 or scf = 6 or scf = . then delete;

	cap_investment = CAPX + IVCH + AQC + FUSEO - SPPE - SIV;
	/* table 2 */
	if scf = 1 then
		changing_working_capit = WCAPC+CHECH+DLCCH;
	if scf = 2 or scf = 3 then
		changing_working_capit = -WCAPC+CHECH-DLCCH;
	if scf = 7 then
		changing_working_capit = -RECCH-INVCH-APALCH-TXACH-AOLOCH+CHECH-FIAO-DLCCH;

	if scf = 7 then
		internal_cf = IBC+XIDOC+DPC+TXDC+ESUBC+FOPO+FSRCO;
	if scf = 1 or scf = 2 or scf = 3 then
		internal_cf = IBC+XIDOC+DPC+TXDC+ESUBC+FOPO;
	if scf = 7 then
		investment = CAPX+IVCH+AQC-SPPE-SIV-IVSTCH-IVACO;
	if scf = 1 or scf = 2 or scf = 3 then
		investment = CAPX+IVCH+AQC+FUSEO-SPPE-SIV;


	
	fin_deficit = DV + cap_investment + changing_working_capit - internal_cf;
	net_debt_issued = DLTIS - DLTR;
	net_equity_issued = SSTK - PRSTKC;
	total_net_ext_fin = net_debt_issued + net_equity_issued;

	/* table 9 */
	book_value_debt = DLC + DLTT;

	na = AT - LCT;
	div_over_na = DV / na;
	cap_investment_over_na = cap_investment / na;
	changing_working_capit_over_na = changing_working_capit / na;
	internal_cf_over_na = internal_cf / na;
	fin_deficit_over_na = fin_deficit / na;
	DLTIS_over_na = DLTIS / na;
	net_debt_issued_over_na = net_debt_issued / na;
	net_equity_issued_over_na = net_equity_issued / na;
	total_net_ext_fin_over_na = total_net_ext_fin / na;
	dlc_over_na = dlc / na;
	changing_longterm_debt_at = net_debt_issued / AT;
	longterm_debt_at = DLTT / AT;
	book_leverage = (DLTT+DLC)/(DLTT+DLC+SEQ);
	Tangibility  = PPENT/AT;
	market_value_assets_at = MKVALT/AT;
	Profitability = NI/AT;

	/* table 10 */
	investment_over_na = investment / na;
	logsales = log(sale);

	RECTt1 = lag1(RECT);
	INVTt1 = lag1(INVT);
	APt1 = lag1(AP);
	ATt1 = lag1(AT);
	TEQt1 = lag1(TEQ);
	if LCT ne 0 then current_ratio = ACT/LCT; else current_ratio = .;
	if LCT ne 0 then quick_ratio = (CHE+RECT)/LCT; else quick_ratio = .;
	if TEQ ne 0 then debt_ratio = LT/TEQ; else debt_ratio = .;
	if SALE ne 0 then DSO = ((RECT+RECTt1)/2)/SALE * 365; else DSO = .;
	if COGS ne 0 then DIO = ((INVT+INVTt1)/2)/COGS * 365; else DIO = .;
	if COGS ne 0 then DPO = ((AP+APt1)/2)/COGS * 365; else DPO = .;
	CCCycle = DIO + DSO - DPO;
	if AT ne 0 and ATt1 ne 0 then total_asset_turnover = SALE/((AT+ATt1)/2); else total_asset_turnover = .;
	if INVT ne 0 and INVTt1 ne 0 then inventory_turnover = COGS/((INVT + INVTt1)/2); else inventory_turnover = .;
	if RECT ne 0 and RECTt1 ne 0 then receivable_turnover = SALE/((RECT + RECTt1)/2); else receivable_turnover = .;
	if OIADP ne 0 then Interest_burden = (OIADP - XINT)/OIADP; else interest_burden = .;
	if XINT ne 0 then Interest_coverage = OIADP/XINT; else interest_coverage = .;
	if TEQ ne 0 then Leverage = AT/TEQ; else Leverage = .;
	if AT ne 0 and ATt1 ne 0 then ROA = OIADP/((AT+ATt1)/2); else ROA =.;
	if TEQ ne 0 and TEQt1 ne 0 then ROE = NI/((TEQ+TEQt1)/2); else ROE = .;
	if SALE ne 0 then ROS = OIADP/SALE; else ROS = .;
	keep year CH IVST RECT INVT ACO ACT PPENT IVAEQ IVAO INTAN  AO AT DLC AP TXP LCO LCT DLTT LO TXDITC MIB LT PSTK CEQ TEQ  /*table 1*/
	DV changing_working_capit investment internal_cf fin_deficit net_debt_issued net_equity_issued total_net_ext_fin /* table 2 */
	SSTK PRSTKC DV DLTIS DLTR DLCCH FIAO FINCF EXRE CHECH FSRCO FUSEO WCAPC /* table 8 */
	book_value_debt cap_investment DLTR SSTK PRSTKC /* table 9 10*/
	div_over_na investment_over_na changing_working_capit_over_na internal_cf_over_na fin_deficit_over_na DLTIS_over_na
	net_debt_issued_over_na net_equity_issued_over_na total_net_ext_fin_over_na 
	book_leverage Tangibility market_value_assets_at logsales Profitability
	current_ratio quick_ratio debt_ratio DSO DIO DPO CCCycle total_asset_turnover inventory_turnover 
	receivable_turnover Interest_burden Interest_coverage Leverage ROA ROE ROS;

proc print data=sub_funda(obs=10);
run;

proc export data = sub_funda outfile = "P:\SAS_ASSIGNMENT_2\sub_funda.csv" dbms = csv replace;
run;

/* import gdp deflator data */
proc import datafile = "C:/Users/lyang383/Downloads/funda/GDPDEF.csv" out = gdpdef dbms = csv replace;
run;

proc contents data = gdpdef;
run;

data gdpdef;
	set gdpdef;
	year = year(date);
	gdpdef = GDPDEF_NBD19920101 / 100;
	keep year gdpdef;

proc print data = gdpdef(obs=10);
run;

/* merge gdpdef with funda data */
proc sql;
	create table funda_with_gdpdef as
	select *
	from sub_funda as l
	left join gdpdef as r
	on l.year = r.year;
quit;

/* deflate */

Data funda_with_gdpdef;
	set funda_with_gdpdef;
	array vars CH IVST RECT INVT ACO ACT PPENT IVAEQ IVAO INTAN  AO AT DLC AP TXP LCO LCT DLTT LO TXDITC MIB LT PSTK CEQ TEQ
	DV changing_working_capit investment internal_cf fin_deficit net_debt_issued net_equity_issued total_net_ext_fin
	SSTK PRSTKC DV DLTIS DLTR DLCCH FIAO FINCF EXRE CHECH FSRCO FUSEO WCAPC
	book_value_debt cap_investment DLTR SSTK PRSTKC;
	do over vars;
		vars = vars / gdpdef;
	end;


proc print data = funda_with_gdpdef(obs=10);
run;

/* filter years to calculate descriptive stats*/
data funda_with_gdpdef_filtered;
	set funda_with_gdpdef;
	if year in ( &years );

/* compute stats over years */
%macro compute_stat_over_var(dataset, stat, var);
	proc sort data=&dataset;
		by &var;
	run;

	proc means data = &dataset &stat. noprint;
		by &var;
		output out = &dataset._&stat. &stat= ;
	run;
%mend;

%compute_stat_over_var(funda_with_gdpdef_filtered, n, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, mean, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, p25, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, p50, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, p75, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, std, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, min, year);
%compute_stat_over_var(funda_with_gdpdef_filtered, max, year);

proc print data = funda_with_gdpdef_filtered_mean;
run;

/* export descriptive statistics*/
%macro export_stat(dataset, stat);
	proc export data = &dataset._&stat. outfile = "P:\SAS_Assignment_2\&dataset._&stat..csv" dbms = csv replace;
	run;
%mend;

%export_stat(funda_with_gdpdef_filtered, n);
%export_stat(funda_with_gdpdef_filtered, mean);
%export_stat(funda_with_gdpdef_filtered, p25);
%export_stat(funda_with_gdpdef_filtered, p50);
%export_stat(funda_with_gdpdef_filtered, p75);
%export_stat(funda_with_gdpdef_filtered, std);
%export_stat(funda_with_gdpdef_filtered, min);
%export_stat(funda_with_gdpdef_filtered, max);

data data_for_table_10;
	set sub_funda;

	keep div_over_na investment_over_na changing_working_capit_over_na 
	internal_cf_over_na fin_deficit_over_na DLTIS_over_na
	net_debt_issued_over_na net_equity_issued_over_na total_net_ext_fin_over_na 
	book_leverage Tangibility market_value_assets_at logsales Profitability ;

/* replicate table 10*/
proc corr data=data_for_table_10 outp=table_10;
run;

proc export data = table_10 outfile = "P:\SAS_Assignment_2\table_10.csv" dbms = csv replace;
run;

/* plot */
proc contents data = funda_with_gdpdef out = invars(keep = name) noprint;
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

/* Generate the graphs for ETF and note that macro can be used inside the macro */
%let path=P:\SAS_ASSIGNMENT_2;

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

%compute_stat_over_var(funda_with_gdpdef, mean, year);
%report(funda_with_gdpdef_mean, year);

/* compute the desc stat for nber recession data*/
proc import datafile = "C:/Users/lyang383/Downloads/funda/USREC.csv" out = usrec dbms = csv replace;
run;

data usrec;
	set usrec;
	if USREC = 1 or USREC = 0;
	year = year(date);
	keep year usrec;

proc print data = usrec(obs=10);
run;

proc sql;
	create table funda_with_usrec as
	select *
	from sub_funda as l
	right join usrec as r
	on l.year = r.year;
quit;

%compute_stat_over_var(funda_with_usrec, n, usrec);
%compute_stat_over_var(funda_with_usrec, mean, usrec);
%compute_stat_over_var(funda_with_usrec, p25, usrec);
%compute_stat_over_var(funda_with_usrec, p50, usrec);
%compute_stat_over_var(funda_with_usrec, p75, usrec);
%compute_stat_over_var(funda_with_usrec, std, usrec);
%compute_stat_over_var(funda_with_usrec, min, usrec);
%compute_stat_over_var(funda_with_usrec, max, usrec);

%export_stat(funda_with_usrec, mean);
%export_stat(funda_with_usrec, p50);
%export_stat(funda_with_usrec, std);

proc print data=funda_with_usrec_mean;
run;

/* plot over BAA spread */
%macro report_overlay(dataset, line2);
/* Generate the graphs for ETF and note that macro can be used inside the macro */
%let path=P:\SAS_ASSIGNMENT_2;

%macro generate_graphs();
title "&dataset";
symbol1 interpol=join Color=blue value=point width=0.05;
symbol2 interpol=join Color=red value=point width=0.05;

%macro plot_overlay(var_name);
proc gplot data = &dataset; 
	plot &var_name * year;
	plot2 &line2 * year;
run; 
quit;
%mend;

%do i = 1 %to &numvars.;
	%let var_name = %qscan(&var_names, &i, %str(" ")); 
	%plot_overlay(&var_name);
%end;
%mend;

ods pdf file = "&path\graph&dataset..pdf";
%generate_graphs();
ods pdf close;
	
%mend;

proc import datafile = "C:/Users/lyang383/Downloads/funda/BAAFFM.csv" out = baaffm dbms = csv replace;
run;

data baaffm;
	set baaffm;
	year = year(date);
	keep year baaffm;

proc sql;
	create table funda_with_baaffm as
	select *
	from funda_with_gdpdef_mean as l
	left join baaffm as r
	on l.year = r.year;
quit;

proc print data = funda_with_baaffm;
run;

%report_overlay(funda_with_baaffm, baaffm);

/* plot over Cleveland Financial Stress Index */
proc import datafile = "C:/Users/lyang383/Downloads/funda/CFSI.csv" out = cfsi dbms = csv replace;
run;

data cfsi;
	set cfsi;
	year = year(date);
	keep year cfsi;

proc sql;
	create table funda_with_cfsi as
	select *
	from funda_with_gdpdef_mean as l
	left join cfsi as r
	on l.year = r.year;
quit;

%report_overlay(funda_with_cfsi, cfsi);



