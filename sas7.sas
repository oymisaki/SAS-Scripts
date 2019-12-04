libname path "Q:/Data-ReadOnly/COMP/";
%let rc = %sysfunc(dlgcdir('Q:/Users/lyang383'));

/*read data and filter the dataset as the paper, note, the outliers are not removed*/
data sub_funda;
	set path.funda;
	year = year(datadate);
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and consol='C' 
	and FIC = 'USA'  and YEAR >= 1970 and YEAR <= 2017;
	CUSIP = substr(CUSIP,1,8);
	DLC = DLC*1000000;
	DLTT = DLTT*1000000;
	F = DLC + 0.5 * DLTT;
	keep CUSIP YEAR F ;

proc print data = sub_funda(obs=10);
run;

proc export data = sub_funda outfile = "P:\ASSIGNMENT_7\sub_funda.csv" dbms = csv replace;
run;

libname path "Q:\Data-ReadOnly\CRSP";	


data sub_dsf;
	set path.dsf;
	year = year(DATE);
	SHROUT = SHROUT * 1000;
	E = ABS(PRC) * SHROUT;
	keep cusip shrout RET PRC year E;

proc sql;
	create table sub_dsf2 as
	select cusip, year, 
	exp(sum(log(1+ret))) as annret, 
	STD(RET)*sqrt(250) as sigmae
	from sub_dsf
	group by CUSIP, year;

proc sort data = sub_dsf;
	by CUSIP year;

data sub_dsf3;
	set sub_dsf;
	if (lag(year) - year) ~= 0;

proc print data = sub_dsf3(obs=10);
run;

proc sql;
	create table sub_dsf4 as
	select l.CUSIP, l.year, annret, sigmae, E from
	sub_dsf2 as l
	join sub_dsf3 as r
	on l.CUSIP = r.CUSIP AND l.year = r.year;

proc print data = sub_dsf4(obs=10);
run;

proc export data = sub_dsf4 outfile = "P:\ASSIGNMENT_7\sub_dsf.csv" dbms = csv replace;
run;
