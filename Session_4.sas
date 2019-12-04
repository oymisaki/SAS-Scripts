/* This session covers regression analysis */

libname path "P:\SAS_Session\Session_4";

proc import datafile = "P:\SAS_Session\Session_4\aapl.csv" out = aapl dbms = csv replace;
run;

proc import datafile = "P:\SAS_Session\Session_4\ibm.csv" out = ibm dbms = csv replace;
run;

proc import datafile = "P:\SAS_Session\Session_4\msft.csv" out = msft dbms = csv replace;
run;

proc sql;
create table aapl_ibm as
select 
	a.date,
	a.close as aapl_closing,
	b.close as ibm_closing
from aapl as a 
inner join ibm as b
on a.date = b.date;
quit;

proc sql;
create table closing_prices as
select 
	a.date,
	a.aapl_closing,
	a.ibm_closing,
	b.close as msft_closing
from aapl_ibm as a 
inner join msft as b
on a.date = b.date;
quit;

/* Linear Regression */

proc reg data = closing_prices;
	model aapl_closing = msft_closing;
	plot residual.*predicted. / cframe = ligr;
run;

/* Logit Regression */

proc logistic data = path.remission;	
	model remiss (event='1') = cell smear infil li blast temp;
run;

/* Probit Regression */

proc logistic data = path.grad_admission;
	model admit (event = '1') = gre topnotch gpa / link = probit;
run;

/* Stepwise Regression */

proc logistic data = path.grad_admission outest = betas;
	model admit (event = '1') = gre topnotch gpa / selection = stepwise slentry = 0.3 slstay = 0.1;
	output out = pred p = prob;
run;

/* 	Solving non-linear equations using proc model*/

data test;
	input a b @@;
	datalines;
	0 1 	1 1		1 2
;

proc model data = test;
	eq.sqrt = sqrt(x) - y;
	eq.hyperbola = a + b / x - y;
	solve x y / solveprint;
	id a b;
run;

/* OLS Single Non-Linear Equation */

proc model data = path.us_pop;
	population = a / (1 + exp( b - c * (year - 1790)));
	fit population start = (a 1000 b 5.5 c .02) / out = resid outresid;
run;

proc gplot data = resid;
	plot population * year;
	title "Residual";
	symbol value = plus;
run;

/*
	2-equation econometric model used to fit US production data from 1909-1949

	z1 = capital input
	z2 = labor input
	z3 = real output
	z4 = time in years with 1929 as year 0
	z5 = ratio of price of capital services to wage scale 
*/

proc model data = path.us_prod;
	parms c1-c5;
	endogenous z1 z2;
	exogenous z3 z4 z5;
	eq.g1 = c1*10**(c2*z4)*(c5*z1**(-c4) + (1-c5)*z2**(-c4))**(-c3/c4) - z3;
	eq.g2 = (c5/(1-c5))*(z1/z2)**(-1-c4) - z5;
	fit g1 g2 / fiml;
run;
