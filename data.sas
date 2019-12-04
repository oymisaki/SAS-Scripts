libname path "Q:\Data-ReadOnly\COMP";

proc contents data = path.funda(obs=10);
run;

data sub_funda;
	set path.funda;
	year = year(datadate);
	if indfmt='INDL' and datafmt='STD' and popsrc='D' and con-
	sol='C';
	if 1961 < fyear < 2017;
	if 5999 < sich < 7000 then delete;
	if 4899 < sich < 5000 then delete;
	if compst ne 'AB';

	wcta = (ACT - LCT) / AT;
	reta = RE/AT;
	ebitta = OIADP / AT;
	mktvaleqtl = (PRCC_F*CSHO)/LT;
	salesta =  SALE/AT;
	logta = log(AT);
	tlta = LT/AT;
	curliabca = LCT / ACT;
	nita = NI/AT;
	fndsfrmopertl = (PI +DP)/LT;

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

	/* table 9 */
	divna = DV / na;
	capinvna = cap_investment / na;
	itrnlcfna = internal_cf / na;
	findfna = fin_deficit / na;
	dltisna = DLTIS / na;
	ndina = net_debt_issued / na;
	neina = net_equity_issued / na;
	tnefna = total_net_ext_fin / na;
	dlcna = dlc / na;
	tng  = PPENT/AT;
	mvaat = MKVALT/AT;
	prftbl = NI/AT;
	/* table 10 */
	logsales = log(sale);

	RECTt1 = lag1(RECT);
	INVTt1 = lag1(INVT);
	APt1 = lag1(AP);
	ATt1 = lag1(AT);
	TEQt1 = lag1(TEQ);
	if LCT ne 0 then cr = ACT/LCT; else cr = .;
	if LCT ne 0 then qr = (CHE+RECT)/LCT; else qr = .;
	if TEQ ne 0 then dr = LT/TEQ; else dr = .;
	if OIADP ne 0 then ib = (OIADP - XINT)/OIADP; else ib = .;
	if XINT ne 0 then ic = OIADP/XINT; else ic = .;
	if TEQ ne 0 then lvg = AT/TEQ; else lvg = .;
	if AT ne 0 and ATt1 ne 0 then ROA = OIADP/((AT+ATt1)/2); else ROA =.;
	if TEQ ne 0 and TEQt1 ne 0 then ROE = NI/((TEQ+TEQt1)/2); else ROE = .;
	if SALE ne 0 then ROS = OIADP/SALE; else ROS = .;
	keep year datadate CUSIP wcta reta ebitta mktvaleqtl salesta logta tlta curliabca nita 
	fndsfrmopertl divna capinvna itrnlcfna findfna dltisna ndina 
	neina tnefna dlcna tng mvaat prftbl logsales
	cr qr dr ib ic lvg ROA ROE ROS;


proc export data = sub_funda outfile = "P:\hazardmodel\sub_funda.csv" dbms = csv replace;
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

proc export data = sub_dsf4 outfile = "P:\hazardmodel\sub_dsf.csv" dbms = csv replace;
run;
