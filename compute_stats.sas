proc import datafile = "P:\SAS_ASSIGNMENT_1\total.csv" out = total dbms = csv replace;
run;

proc contents data=total;
run;
