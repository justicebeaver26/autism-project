LIBNAME MYSASLIB "/home/u63797843/sasuser.v94/Semester2/ENGE817";

PROC IMPORT DATAFILE = "/home/u63797843/sasuser.v94/Semester2/ENGE817/ASD_waittime.csv"
OUT = waittime
DBMS = CSV
REPLACE;
GETNAMES = YES;
RUN;

PROC CONTENTS DATA=waittime;
RUN;


PROC PRINT DATA = waittime (OBS=10);
RUN;


DATA waittime;
SET waittime;
DROP Referrals Median_Wait_Days BREAKDOWN;
RUN;


/* Renaming Columns */
DATA waittime_clean;
SET waittime;
RENAME PRIMARY_LEVEL = age_group;
RENAME Referrals_excluding_RX3 = referrals;
RENAME Median_Wait_Days_excluding_RX3 = wait_time;
RENAME REPORTING_PERIOD_START = date;
RUN;

DATA waittime_clean;
SET waittime_clean;
IF age_group = "18 and over" OR age_group="Under 18";
RUN;

/* Boxplot */
PROC SGPLOT DATA = waittime_clean;
VBOX wait_time / CATEGORY=age_group;
XAXIS LABEL = 'Age Groups';
YAXIS LABEL = 'Wait Times';
TITLE "Boxplot of Median Wait Times for Adults and Children";
RUN;

/* Descriptive Stats */
PROC MEANS DATA = waittime_clean N MEAN MAX MIN;
BY age_group notsorted ;
VAR wait_time;
RUN;


/* Creating Dataframes */
DATA adult;
SET waittime_clean;
IF age_group = "18 and over";
RENAME wait_time = wait_time_adults;
RENAME referrals = referrals_adults;
RUN;

DATA children;
SET waittime_clean;
IF age_group = "Under 18";
RENAME wait_time = wait_time_children;
RENAME referrals = referrals_children;
RUN;

/* Descriptive Stats */
PROC MEANS DATA = adult N MEAN MAX MIN STD;
VAR wait_time_adults referrals_adults;
RUN;

PROC MEANS DATA = children N MEAN MAX MIN STD;
VAR wait_time_children referrals_children;
RUN;


DATA combined;
SET adult children;
RUN;

/* Time series plot for children */
PROC SGPLOT DATA = children;
TITLE 'Time series of Monthly Median Waiting Times for Autism Screening in Children (in Days)';
SERIES x=date y=wait_time_children /lineattrs = (color=blue) thickmax=10 legendlabel='Daily Average' name='daily';
SCATTER x=date y=wait_time_children / MARKERATTRS=(symbol=circlefilled SIZE=5 COLOR=blue) LEGENDLABEL="Data Points";
/*SERIES x=date y=referrals_children /lineattrs = (color=red) thickmax=10 legendlabel='Daily Average' name='daily';
SCATTER x=date y=referrals_children / MARKERATTRS=(symbol=circlefilled SIZE=5 COLOR=red) LEGENDLABEL="Data Points";*/
KEYLEGEND 'monthly' / location=inside position=topright across=1;
   XAXIS LABEL='Date' grid;
   YAXIS LABEL='Monthly Median Wait Times For Children (in Days)' grid;
RUN;


PROC SGPLOT DATA = adults;
TITLE 'Time series of Monthly Median Waiting Times for Autism Screening in Adults (in Days)';
SERIES x=date y=wait_time_adults /lineattrs = (color=blue) thickmax=10 legendlabel='Daily Average' name='daily';
SCATTER x=date y=wait_time_adults / MARKERATTRS=(symbol=circlefilled SIZE=5 COLOR=blue) LEGENDLABEL="Data Points";
/*SERIES x=date y=referrals_children /lineattrs = (color=red) thickmax=10 legendlabel='Daily Average' name='daily';
SCATTER x=date y=referrals_children / MARKERATTRS=(symbol=circlefilled SIZE=5 COLOR=red) LEGENDLABEL="Data Points";*/
KEYLEGEND 'monthly' / location=inside position=topright across=1;
   XAXIS LABEL='Date' grid;
   YAXIS LABEL='Monthly Median Wait Times for Adults (in Days)' grid;
RUN;



/* Multiple Linear Regression */
PROC GLM DATA = waittime_clean PLOTS=ALL;
CLASS age_group;
MODEL wait_time = referrals | age_group / SOLUTION CLPARM;
RUN; 

/* ANOVA TEST */
PROC ANOVA data=waittime_clean ;
CLASS age_group;
MODEL wait_time = age_group ;
MEANS age_group / tukey lines;
RUN;


/* ANCOVA TEST */
PROC SGPLOT DATA = adult;
SCATTER Y = referrals_adults X = wait_time_adults;
RUN;

proc sgplot data = children;
scatter y = referrals_children x = wait_time_children;
run;


PROC MIXED DATA = waittime_clean;
CLASS age_group;
MODEL wait_time = age_group | referrals;
RUN;

/* ANCOVA TEST */
PROC MIXED DATA = waittime_clean;
CLASS age_group;
MODEL wait_time = age_group | referrals / noint solution;
LSMEANS age_group / pdiff adjust=tukey;
TITLE 'Different Slopes Model';
RUN;

DATA reduced_model;
  SET waittime_clean;
  wait_time_A = 91.2011 + (0.02388+0.05324)*referrals; /* Predicted values for reduced model */
  wait_time_C = 140.62 + (0.02388 + 0)*referrals;
RUN;

PROC SGPLOT DATA=reduced_model;
  SERIES x=referrals y=wait_time_A / LINEATTRS=(color=blue thickness=2) legendlabel='Adults';
  SERIES x=referrals y=wait_time_C/ LINEATTRS=(color=red thickness=2) legendlabel='Children';
  KEYLEGEND / location=inside position=topright across=1; 
  YAXIS LABEL='Wait Times';
RUN;

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                          AUTOREGRESSIVE MODEL                              */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

/* Generating Future Dates */
DATA future_dates;
    FORMAT date YYMMDD10.;
    wait_time_adults = .; /* Placeholder for future values */
    DO i = 0 TO 12;
        date = INTNX('month', '01OCT2023'd, i); /* Increment by months */
        OUTPUT;
    END;
RUN;

/* Merging Historical Data with Future Dates */
DATA combined_data_adults;
    MERGE adult future_dates;
    BY date;
RUN;

/* AUTOREG Procedure */
PROC AUTOREG DATA=combined_data_adults plots=all;
    MODEL wait_time_adults = date  / nlag=2 method=ml;
    OUTPUT OUT=forecasted P=predicted_waittime R=residual
    lcl=lcl ucl=ucl ;
run; quit;

/* PROC ARIMA to extend the forecast by 12 periods */
PROC ARIMA DATA=forecasted;
    IDENTIFY VAR=wait_time_adults;
    ESTIMATE P=2 METHOD=ML;
    FORECAST LEAD=12 OUT=forecast_12months;
RUN;
QUIT;


/* FOR CHILDREN */
DATA future_dates;
    FORMAT date YYMMDD10.;
    wait_time_children = .; /* Placeholder for future values */
    DO i = 0 TO 12;
        date = INTNX('month', '01OCT2023'd, i); /* Increment by months */
        OUTPUT;
    END;
RUN;

/* Merging Historical Data with Future Dates */
DATA combined_data_children;
    MERGE children future_dates;
    BY date;
RUN;


PROC AUTOREG DATA=combined_data_children plots=all;
    MODEL wait_time_children = date / nlag=2 method=ml;
    OUTPUT OUT=forecasted_children P=predicted_waittime R=residual
   lcl=lcl ucl=ucl;
run; quit;

PROC ARIMA DATA=forecasted_children;
    IDENTIFY VAR=residual NLAG=20;
RUN;
QUIT;

title 'Forecasted Median Wait Times for Children';
proc sgplot data=forecasted_children;
 band x=date upper=ucl lower=lcl;
 scatter x=date y=wait_time_children/ LEGENDLABEL="Actual Value";
 series x=date y=predicted_waittime / LEGENDLABEL="Predicted Value" ;
     XAXIS LABEL="Date";
    YAXIS LABEL="Wait Time";
run;






/* ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ */
/*                   Exponential Smoothing                                */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
ods graphics on;
PROC ESM DATA=adult OUT=exp_forecast LEAD=12 PLOT=(all) PRINT=ALL;
	ID date INTERVAL=month;
	FORECAST wait_time_adults / MODEL=linear;
	RUN;


ods graphics on;
PROC ESM DATA=children OUT=exp_forecast LEAD=12 PLOT=(all) PRINT=ALL;
	ID date INTERVAL=month;
	FORECAST wait_time_children / MODEL=linear;
	RUN;




/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                       ARIMA                                                        */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
  



PROC ARIMA DATA=adult PLOTS=all;
IDENTIFY VAR=wait_time_adults(2) NLAG=24; /* Second differencing */
ESTIMATE P=2 Q=1;
FORECAST LEAD=12 INTERVAL=month ID=date OUT=results;
RUN;


PROC ARIMA DATA=children;
IDENTIFY VAR=wait_time_children nlag=24;
RUN;


PROC ARIMA DATA=children plots=all;
IDENTIFY VAR=wait_time_children(2) nlag=24;
estimate p=2 q=1;
forecast lead=12 interval=month id=date out=results;
RUN;




/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
/*                             Out-of-sample                              */
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/


/* Holding out last 12 months */
PROC AUTOREG DATA=combined_data_adults;
    MODEL wait_time_adults = date  / nlag=2 method=ml;
    WHERE date <= '1SEP2022'd;
    OUTPUT OUT=adult_autoreg_results P=predicted_waittime R=residual
    lcl=lcl ucl=ucl ;
run; quit;

/* Using ARIMA to forecast the next 12 months */
PROC ARIMA DATA=adult_autoreg_results;
    IDENTIFY VAR=wait_time_adults;
    ESTIMATE P=2 METHOD=ML;
    FORECAST LEAD=12 interval=month id=date OUT=forecast_12months_adults;
RUN;
QUIT;

/* Creating a test set */
DATA test_set_autoreg_adults;
   SET adult;
   IF date > '1SEP2022'd;
   RENAME wait_time_adults = wait_time_actual_adults;
run;

DATA forecasted_adults;
SET forecast_12months_adults;
IF date > '1SEP2022'd;
RUN;

/* Merging test set with forecasted values */
DATA merged_autoreg_adults;
MERGE test_set_autoreg_adults forecasted_adults;
BY date;
run;

/* Calculating Accuracy Metrics */
DATA errors_autoreg_adults;
   SET merged_autoreg_adults;
   err_add_auto = wait_time_actual_adults-FORECAST;
   e2_add_auto = err_add_auto**2;
   pcterr_add_auto = 100*abs(err_add_auto)/abs(wait_time_actual_adults);
RUN; 

PROC MEANS N MEAN DATA = errors_autoreg_adults;
TITLE "Out-of-Sample Forecast Accuracy Measures: AUTOREG MODEL";
VAR e2_add_auto pcterr_add_auto;
LABEL e2_add_auto = "Mean Squared Error";
LABEL pcterr_add_auto = "Mean Absolute Percentage Error";
RUN; QUIT;







/* Creating a training set */
DATA trainset_exp_adults;
SET adult;
IF date <= '1SEP2022'd;
RUN;

/* Fitting the model on training set */
PROC ESM DATA=trainset_exp_adults OUT=exp_results_adults LEAD=12 PLOT=(all) PRINT=all;
	ID date INTERVAL=month;
	FORECAST wait_time_adults / MODEL=linear;
RUN;


/* Extracting forecasted values for the next 12 months */
DATA exp_results_adults2;
SET exp_results_adults;
forecast = wait_time_adults;
DROP wait_time_adults;
IF date > '1SEP2022'd;
RUN;


/* Creating a test set and merging the forecasted values with actual values */
DATA test_set_exp_adults;
   MERGE adult exp_results_adults2;
   BY date;
   IF date > '1SEP2022'd;
   KEEP date wait_time_adults forecast;
RUN;


/* Calculating accuracy metrics */
DATA err_exp_adults;
   SET test_set_exp_adults;
   err_add_exp= wait_time_adults-forecast;
   e2_add_exp = err_add_exp**2;
   pcterr_add_exp = 100*abs(err_add_exp)/abs(wait_time_adults);
RUN; 

PROC MEANS N MEAN DATA = err_exp_adults;
TITLE "Out-of-Sample Forecast Accuracy Measures: ES MODEL";
VAR e2_add_exp pcterr_add_exp;
LABEL e2_add_exp = "Mean Squared Error";
LABEL pcterr_add_exp = "Mean Absolute Percentage Error";
RUN; QUIT;





PROC ARIMA DATA=adult;
IDENTIFY VAR=wait_time_adults(2) nlag=24;
estimate p=2 q=1;
forecast lead=12 interval=month id=date out=results;
RUN;


/* Holding out for the last 12 months */
PROC ARIMA DATA=adult;
IDENTIFY VAR=wait_time_adults(2) nlag=24;
ESTIMATE p = 2 q = 1 METHOD=ML;
WHERE date <= '1SEP2022'd;  
FORECAST LEAD=12 INTERVAL=month ID=date OUT=ARIMA_result_adult;
RUN; QUIT;

/* Creating a test set */
DATA test_set_arima_adults;
SET adult;
  IF date > '1SEP2022'd;
run;

/* Extracting forecasted values */
DATA ARIMA_result2_adults;
   SET ARIMA_result_adult;
   IF date > '1SEP2022'd;
   keep date Forecast;
run;

/* Merging forecasted values with actual values */
DATA merged_ARIMA;
MERGE ARIMA_result2_adults test_set_arima_adults;
BY date;
KEEP date wait_time_adults FORECAST;
RUN;


/* Calculating accuracy metrics */
DATA error_arima_adults;
   set test_set_arima_adults;
   set ARIMA_result2_adults;
   err_add = wait_time_adults-Forecast;
   e2_add = err_add**2;
   pcterr_add = 100*abs(err_add)/abs(wait_time_adults);
run; 

PROC MEANS N MEAN DATA = error_arima_adults;
TITLE "Out-of-Sample Forecast Accuracy Measures: ARIMA Model";
VAR e2_add pcterr_add;
LABEL e2_add = "Mean Squared Error";
LABEL pcterr_add = "Mean Absolute Percentage Error";
RUN; QUIT;

proc print data=adult;
run;


/* For children */

PROC AUTOREG DATA=combined_data_children;
    MODEL wait_time_children = date  / nlag=2 method=ml;
    WHERE date <= '1SEP2022'd;
    OUTPUT OUT=results1children P=predicted_waittime R=residual
    lcl=lcl ucl=ucl ;
run; quit;

PROC ARIMA DATA=results1children;
    IDENTIFY VAR=wait_time_children;
    ESTIMATE P=2 METHOD=ML;
    FORECAST LEAD=12 interval=month id=date OUT=forecast_12months;
RUN;
QUIT;

DATA test_set_autoreg;
   SET children;
   IF date > '1SEP2022'd;
   RENAME wait_time_children = wait_time_actual;
run;

DATA forecasted;
SET forecast_12months;
IF date > '1SEP2022'd;
RUN;


DATA results1_autoreg;
MERGE test_set_autoreg forecasted;
/*KEEP FORECAST date wait_time_adults;*/
run;

DATA fore_err_auto;
   SET results1_autoreg;
   err_add_auto = wait_time_actual-FORECAST;
   e2_add_auto = err_add_auto**2;
   pcterr_add_auto = 100*abs(err_add_auto)/abs(wait_time_actual);
run; 

proc means n mean data = fore_err_auto;
title "Out-of-Sample Forecast Accuracy Measures: AUTOREG MODEL";
var e2_add_auto pcterr_add_auto;
label e2_add_auto = "Mean Squared Error";
label pcterr_add_auto = "Mean Absolute Percentage Error";
run; quit;





proc print data=children;
run;


DATA waittime_trainset_exp;
SET children;
IF date <= '1SEP2022'd;
RUN;

PROC ESM DATA=waittime_trainset_exp OUT=exp_results1 LEAD=12 PLOT=(all) PRINT=all;
	ID date INTERVAL=month;
	FORECAST wait_time_children / MODEL=linear;
RUN;



DATA exp_results;
SET exp_results1;
forecast = wait_time_children;
DROP wait_time_children;
IF date > '1SEP2022'd;
RUN;

DATA test_set_exp;
   MERGE children exp_results;
   BY date;
   IF date > '1SEP2022'd;
   KEEP date wait_time_children forecast;
run;


DATA fore_err_exp;
   SET test_set_exp;
   err_add_exp= wait_time_children-forecast;
   e2_add_exp = err_add_exp**2;
   pcterr_add_exp = 100*abs(err_add_exp)/abs(wait_time_children);
run; 

proc means n mean data = fore_err_exp;
title "Out-of-Sample Forecast Accuracy Measures: ES MODEL";
var e2_add_exp pcterr_add_exp;
label e2_add_exp = "Mean Squared Error";
label pcterr_add_exp = "Mean Absolute Percentage Error";
run; quit;





PROC ARIMA DATA=children;
IDENTIFY VAR=wait_time_children(2) nlag=24;
estimate p=2 q=1;
forecast lead=12 interval=month id=date out=results;
RUN;


PROC ARIMA DATA=children;
IDENTIFY VAR=wait_time_children(2) nlag=24;
ESTIMATE p = 2 q = 1 METHOD=ML;
WHERE date <= '1SEP2022'd;  
FORECAST LEAD=12 INTERVAL=month ID=date OUT=ARIMA_result;
RUN; QUIT;

DATA test_set_arima;
SET children;
  IF date > '1SEP2022'd;
run;

DATA ARIMA_result2;
   SET ARIMA_result;
   IF date > '1SEP2022'd;
   keep date Forecast;
run;

DATA merged_ARIMA;
MERGE ARIMA_result2 test_set_arima;
BY date;
KEEP date wait_time_children FORECAST;
RUN;

DATA fore_err;
   set test_set_arima;
   set ARIMA_result2;
   err_add = wait_time_children-Forecast;
   e2_add = err_add**2;
   pcterr_add = 100*abs(err_add)/abs(wait_time_children);
run; 

proc means n mean data = fore_err;
title "Out-of-Sample Forecast Accuracy Measures: ARIMA Model";
var e2_add pcterr_add;
label e2_add = "Mean Squared Error";
label pcterr_add = "Mean Absolute Percentage Error";
run; quit;
