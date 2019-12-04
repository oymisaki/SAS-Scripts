# SAS

## 程序结构
1. DATA
   ```s
   # 句法
   DATA data_set_name;		#Name the data set.
   INPUT var1,var2,var3; 	#Define the variables in this data set.
   NEW_VAR;			        #Create new variables.
   LABEL;			      	#取名
   DATALINES;		      	#Enter the data.
   RUN;
   ```
2. PROC
   ```s
   # 句法
   PROC procedure_name options; #The name of the proc.
   RUN;

   # eg
   PROC MEANS;
   RUN;
   ```
3. OUTPUT
   ```s
   # 句法
   PROC PRINT DATA = data_set;
   OPTIONS;
   RUN;

   # eg
   PROC PRINT DATA=TEMP;
   WHERE SALARY > 700;
   RUN;
   ``` 
## 数据集
DATA data_set_name: 创建临时数据集
DATA lib.ds_name: 创建永久数据集

## 变量类型
```s
# 定义数字型变量
INPUT VAR1 VAR2 VAR3;
# 定义字符串变量
INPUT VAR1 $ VAR2 $ VAR3 $; 
# 日期变量
INPUT VAR1 DATE11. VAR2 MMDDYY10.   
# 数组
ARRAY arr[5] (12 18 5 62 44);
ARRAY QUESTS(1:5) $ Q1-Q5; # 5个字符串
ARRAY ANSWER(*) A1-A100;
# eg

```

tips:
```s
# 用LENGTH声明变量而不创建obs
# 在变量$后面声明固定长度
LENGTH string1 $ 6 String2 $ 5;

# 字符串提取函数
SUBSTRN(str, 1, 3)
# TRIMN 去空格
TRIMN(str)
# 字符串连接
str1 || '+' || str2

# 使用OF运算符对数组每一行进行统计运算
# 使用IN运算符进行 in 逻辑判断
# eg
DATA array_example_OF;
	INPUT A1 A2 A3 A4;
	ARRAY A(4) A1-A4;
	A_SUM=SUM(OF A(*));
	DATALINES;
	21 4 52 11
	96 25 42 6
	;
	RUN;
	PROC PRINT DATA=array_example_OF;
	RUN;

# 数据格式
n.p
n.
COMMAn.p
DOLLARn.p
```

## 运算符
+, - *, /, |, &, ~, =, ^=, <, >, IN, MIN, MAX

## 控制流程

```s
# while循环
DATA MYDATA;
SUM=0;
VAR=1;
DO WHILE(VAR<6) ;
   SUM=SUM+VAR;
   VAR+1;
END;
   PROC PRINT;
   RUN;

# for循环
DATA MYDATA1;
SUM=0;
DO VAR=1 to 5;
   SUM=SUM+VAR;
END;

PROC PRINT DATA=MYDATA1;
RUN;

# IF
Data EMPDAT1;
Set EMPDAT; # 连接数据集EMPDAT生成EMPDAT1
IF SALARY < 600 THEN SALRANGE ="LOW";
ELSE IF 600 <= SALARY <= 700 THEN SALRANGE="MEDIUM";
ELSE IF 700 < SALARY THEN SALRANGE="MEDIUM";
PROC PRINT DATA=EMPDAT1;
run; 
```

## 宏
全局宏：
全部可以使用
`&SYSDAY` `&SYSDATE`
局部宏：
部分使用
```s
%LET make_name = 'Audi';
%LET type_name = 'Sports';
proc print data = sashelp.cars;
where make = &make_name and type = &type_name ;
 TITLE "Sales as of &SYSDAY &SYSDATE";
run;
```

函数宏
```s
%macro test(finish);
   %let i=1;
   %do %while (&i <&finish);
      %put the value of i is &i;
      %let i=%eval(&i+1);
   %end;
%mend test;
%test(5)
```
tips:
1. 用 `&` 引用宏变量
2. 用 `%` 应用宏函数
3. 用 `%put` 宏输出到日志
4. 用 `%eval` 计算算数表达式

## SAS Session 1

### proc contents
  + 查看基本信息
### delete 关键词与 `.`
  + ```bash
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
    ```
+ TIPS:
  + `.`可以代表缺失值
### proc surveyselect 
  ```s
    proc surveyselect data = one
    method = srs 
    n = 100 
    seed = 123 
    out = random_sampled_comp;
    run;
  ```
### proc sort  
```s
  proc sort data = one;
  	by gvkey datadate;
  run;
```

### first.colname 关键词
用 `first.colname` 来判断是不是第一个
```s
data two;
	set one;
	by gvkey datadate; # 排序
	lag_prccm = lag(prccm);
	ret = prccm/lag_prccm - 1;
	if first.gvkey then ret = .;
run;
```

### retain 关键词
用 `retain` 防止每次迭代时SAS把变量自动更新成空值
```s
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
```

## SAS Session 2

### 读入数据与proc import
```s
proc import datafile = "P:\SAS_Session\Session_2\left_table.csv" out = left_table dbms = csv replace;
run;
```

TIPS:
也可以详细指定参数

```s
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
```

### join操作与proc sql

**操作一**
TIPS:
需要实现排序对齐

```s
data inner_join;
	merge left_table(in = a) right_table(in = b);
	by name;
	if a & b;
run;
```
merge操作，通过if语句来进行分割：
+ if a&b, inner join
+ if a left join
+ if b right join
+ 没有if语句 full join

**操作二**
使用sql proc，不需要对齐
```s
proc sql;
	create table inner_join as
	select *
	from left_table as l 
	inner join right_table as r
	on l.name = r.name;
quit;

proc sql;
	create table left_join as
	select *
	from left_table as l 
	left join right_table as r
	on l.name = r.name;
quit;

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
```

## SAS Session 3

### 基本Array操作
+ dim取得长度
+ 声明
```s
data funda;
	set path.funda;
	array miss {5} at ch lt capx sstk;
	do i = 1 to dim(miss);
		if miss(i)=. then delete;
	end;
	drop i;
run;
```

### Plot
```s
/* Positional Parameters */
%macro plot(dataset, year, yvar, xvar);

	data temp;
		set &dataset;
		if (fyear = &year);
	run;

	data tmp2;
		set temp(obs = 10);
	run;

	proc plot data = tmp2;
		plot &yvar*&xvar;
	run;

%mend;

%plot(funda, 1974, at, gvkey);
```

## SAS Session 4

### proc reg

```s
proc reg data = closing_prices;
	model aapl_closing = msft_closing;
	plot residual.*predicted. / cframe = ligr;
run;
```
### proc logistics

```s
/* Logit Regression */

proc logistic data = path.remission;	
	model remiss (event='1') = cell smear infil li blast temp;
run;

/* Probit Regression */

proc logistic data = path.grad_admission;
	model admit (event = '1') = gre topnotch gpa / link = probit;
run;
```

## SAS Session 6

NOTE:
+ Advanced Techniques

### advance rename
```s
# get all col names
proc contents data = midas_2014q2 out = temp(keep = name) noprint;
run;

data invars;
	set temp;
	if substr(name, length(name)-5, 6) = "__000_" then name2 = substr(name, 1, length(name)-6);
	else name2 = name;
	rename = catx("=", name, name2);
run;

/******** Store the variable renaming list into a macro variable ************/
proc sql noprint;
	select rename
	into: var_renames separated by " "
	from invars;
quit;

/*** Check the variable renaming list **/
%put &var_renames;

data midas_2014q2_recode;
	set midas_2014q2(rename = (&var_renames.));
	/*Create required variables*/
	date = input(put(date, 8.), YYMMDD8.);
	format date MMDDYY8.;
```

TIPS:
+ use `contents` + `out=temp(keep=name)` 输出列名 
+ use `catx` generate rename string
+ use `sql` to create macro and check rename string
+ use  `data` step and `rename` option and rename string to rename 
+ use `format` to deal with date variable

### advance macro
TIPS:
+ use `%put` to see how macro works
+ use `out` and `keep` generate variables about data
+ `%sysfunc`
+ `.` represents the end of `&`
+ use `&&` to reslove `var_name&i`

```s
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
```





