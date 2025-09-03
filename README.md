# autism-project
This is my project on Forecasting Autism Waiting Times.

# Forecasting Autism Screening Waiting Times
## Purpose of the Project
The purpose of this study is to analyze and forecast median waiting times for autism screening in England across two age groups: under 18 and 18 and over.
The goal is to understand historical patterns, evaluate the impact of referrals on waiting times, and provide reliable forecasts to inform resource allocation and improve patient satisfaction.

## How to run
1. Open the `Research_Latest_code (1).sas` file in SAS Studio or your local SAS environment.  
2. Ensure the dataset `ASD_waittime.csv` is also uploaded on SAS.  
3. Update the file path in the SAS code if necessary.  
4. Run the script to reproduce the exploratory analysis, regression, and ARIMA forecasting.  

## Data Extraction
Data source: Autism screening referral and waiting time data (April 2019 – September 2023).
Data contains:
Median waiting times (children & adults).
Number of referrals over time.

## Data Cleaning
1. Removed missing or inconsistent entries.
2. Aligned dates across age categories.
3. Checked for outliers in referral numbers and waiting times.
4. Formatted time-series data for modeling.

## Modelling
Several statistical and forecasting models were applied:

### Exploratory Analysis:
Identified trends and correlation between referrals and waiting times.

### Regression Models:
Showed that higher referral numbers increase waiting times, with a stronger effect observed for adults.

### Time-Series Models:
Autoregressive (AR)
Exponential Smoothing (ETS)
ARIMA (selected as the best performing model)

## Dashboards for Visualization 
Interactive dashboards and plots were developed to show:
1. Historical trends in waiting times.
   ![Children Waiting Times](outputs/Autism%20children.png)
3. Comparison between children and adults.
4. Correlation between referrals and waiting times.
5. Forecasts of future waiting times.

## Conclusion
1. Children face longer but more stable waiting times compared to adults.
2. Adults experience greater variability, and their waiting times are more strongly affected by referral volumes.
3. ARIMA provided the most reliable forecasts.
4. Findings can help health services plan resources more effectively and improve patient satisfaction.

### Limitations:
1. Narrow time horizon (2019–2023).
2. Limited geographic scope (England).
3. Lack of non-linear modeling approaches.

### Future Work 
Extend analysis across wider regions, incorporate longer time frames, and apply non-linear / machine learning models for better accuracy.

