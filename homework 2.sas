libname path "C:/Users/lyang383/Downloads/funda";
/*set path name*/
%let path = C:/Users/lyang383/Downloads/funda;
%let variables = GVKEY DATADATE FYEAR TIC ACT LCT CHE RECT LT TEQ SALE INVT COGS AP OIADP XINT AT NI RE PRCC_F CSHO DP PI DV CAPX IVCH AQC FUSEO SPPE SIV IVSTCH IVACO WCAPC CHECH DLCCH RECCH INVCH APALCH TXACH AOLOCH CHECH FIAO IBC XIDOC DPC TXDC ESUBC SPPIV FOPO EXRE DLTIS DLTR SSTK PRSTKC DLTT DLC PPENT MKVALT scf;
/*get required years*/
%let years1 = 1971 1974 1979 1984 1988 1990 1995 1999 2002 2005 2008 2012 2015 2017;
/*get required years and its previous year*/
%let years = 1970 1971 1973 1974 1978 1979 1983 1984 1987 1988 1989 1990 1994 1995 1998 1999 2001 2002 2004 2005 2007 2008 2011 2012 2014 2015 2016 2017;

data sub_funda;
	set path.funda(obs=100000);
	if fyear in (&years);
run;

data filter_funda;
	set sub_funda(keep = &variables);
	if fyear in (&years);
run;

proc contents data = filter_funda out = temp(keep = name) noprint;
run;

/*get data for previous year*/
data var_name_t1;
	set temp;
	name2 = name||"t1";
	name2 = compress(name2);
	rename = catx("=", name, name2);
run;
proc sql noprint;
	select rename
	into: var_renames separated by " "
	from var_name_t1;
quit;	

%put &var_renames;

data filter_funda_t1;
	set filter_funda(rename = (&var_renames.));
run;

proc sql noprint;
	create table combined_funda as
	select*
	from filter_funda, filter_funda_t1
	where filter_funda.TIC = filter_funda_t1.TICt1 and filter_funda.FYEAR = filter_funda_t1.FYEARt1+1;
quit;

data combined_funda;
	set combined_funda;
	if fyear in (&years1);
run;
	
	
/*compute all the variables needed*/
data funda_recode;
	set combined_funda;
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
run;	

proc print data=funda_recode(obs=10);
run;

proc sort data = funda_recode;
by FYEAR;
run;


%let all_variables = current_ratio quick_ratio debt_ratio DSO DIO DPO CCCycle total_asset_turnover inventory_turnover receivable_turnover Interest_burden Interest_coverage Leverage ROA ROE ROS;


%macro compute_stats;
proc means data = funda_recode n mean p25 median p75 std min max;
 by FYEAR;
 var &all_variables;
 output out = obs_num n = ;
 output out = Mean mean = ;
 output out = p25 p25 = ;
 output out = Median median = ;
 output out = p75 p75 = ;
 output out = std std = ;
 output out = min min = ;
 output out = max max = ;
run;
%mend;
%compute_stats;

data funda_tb10;
	set filter_funda;
	v1 = dv/(at-lct);
 	if scf in (1,2,3) then v2 = (CAPX+IVCH+AQC+FUSEO-SPPE-SIV)/(at-lct); else v2 = (CAPX+IVCH+AQC-SPPE-SIV-IVSTCH-IVACO)/(at-lct);
 	if scf = 1 then v3 = (WCAPC+CHECH+DLCCH)/(at-lct); 
 	else if scf = 7 then v3 = (-RECCH-INVCH-APALCH-TXACH-AOLOCH+CHECH-FIAO-DLCCH)/(at-lct);
 	else v3 = (WCAPC+CHECH-DLCCH)/(at-lct);
 	if scf = 7 then v4 = (IBC+XIDOC+DPC+TXDC+ESUBC+SPPIV+FOPO+EXRE)/(at-lct); else v4 = (IBC+XIDOC+DPC+TXDC+ESUBC+SPPIV+FOPO+EXRE)/(at-lct);
 	v5 = v1+v2+v3-v4;v6 = dltis/(at-lct);v7 = (dltis-dltr)/(at-lct);v8 = (sstk-prstkc)/(at-lct);v9 = v7+v8;
 	v10 = (dlc+dltt)/at;v11 = PPENT/AT;v12 = MKVALT/AT;v13 = log(sale/at);v14 = NI/AT;
run;
/*compute the corr matrix*/
proc corr data= funda_tb10;
 var v1--v14;
run;


%let numvars = %sysfunc(countw(&all_variables));

%macro plot1;

%do i = 1 %to &numvars.;
	%let var_name&i = %qscan(&all_variables, &i, %str(" "));
	%let plot_var_name&i = &&var_name&i.. * fyear;
	%put &&plot_var_name&i..;
%end;

%macro generate_graphs(decs);
title "&decs";
symbol1 color=red value=square interpol=join height=1 cm width=4;  
proc gplot data = &decs;
	%do i = 1 %to &numvars.;plot &&plot_var_name&i..;  %end;
run;
quit;
%mend;

ods pdf file = "&path\plot1.pdf";
%generate_graphs(Mean);
%generate_graphs(p25);
%generate_graphs(Median);
%generate_graphs(p75);
%generate_graphs(std);
%generate_graphs(min);
%generate_graphs(max);
ods pdf close;

%mend;

%plot1;




%macro import(file = , output = test, dbms_opt =);
proc import datafile = &file out = &output dbms = &dbms_opt replace;
run;

%mend;
/*import these 3 files*/
%import(file = "&path\USREC.csv", output = USREC_data, dbms_opt = csv);
%import(file = "&path\BAAFFM.csv", output = BAAFFM_data, dbms_opt = csv);
%import(file = "&path\CFSI.csv", output = CFSI_data, dbms_opt = csv);















