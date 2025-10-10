# Water Point Census

The code in this folder deals with the data processing and analysis of the water point census. The code in each folder can be ran at once in sequence using bookdown::render_book after setting your working directory to the respective folder.

**Contents**
- wrangling
	- This folder includes the code to process the raw data from the water point census data collection
	- The code in this folder results in the "final" water point census data, saved in `i-h2o-takeup/Data/WaterPointCensus/DataSets/Final/wp-census.rds`
- hfc
	- This code conducts high-frequency checks for the water point census
	- The folder is structured to conduct high-frequency checks for each data set produced in the `wrangling` folder
	- The high-frequency checks output a list of issues with the data to be corrected before data cleaning
	- When data collection is complete and the data corrections are complete, the high-frequency checks will not output anything
	
## Setup

- Make sure you have bookdown downloaded
- Open up the project `WaterPointCensus.Proj`

## Comments for replicators

To run the code in the `wrangling` folder or the `hfc` folder:

- Make sure your working directory is set to the folder
- Run `bookdown::render_book()`
- To edit the files included in the book, edit the 	`_bookdown.yml` file.

### Memory and Runtime Requirements

Approximate time needed to reproduce the analyses on a standard 2023 MacBook Pro:
- `wrangling` ~ 30 seconds
- `hfc` ~ 1 minute

## Description of programs/code

### 	`wrangling`
- `01-import-census` loads the raw census data (a dta file) and exports it as an RDS file. 
- `02-clean-census` cleans the data by renaming variables, converting to factors, and coding missing values
- `03-construct-wp-variables` creates variables for analysis, including sourcetype, sourcetype_simp, etc.
- `04-construct-wp-location` converts the coordinates of water points into an sf object.
- `05-construct-wp-distances` computes distances between water points
- `06-collapse-wp-census` collapses water points.
	- This is because for each water point, there will be 5 observations from 5 different enumerators.
	- Some of these enumerators will conduct different parts of the water spot check
	- This code uses distance and water source characteristics to combine all of these observations into 1 unique water point entry
- `07-match-ea` matches the water points from the census to EA administrative data on the locations of their water points.
- `08-create-final-wp-data` produces the final water point data used for later analysis.


## List of final outputs


| Figure/Table #    | Program                  | Line Number | Output file                      | Note                            |
|-------------------|--------------------------|-------------|----------------------------------|---------------------------------|
| Table 1           | 02_analysis/table1.do    |             | summarystats.csv                 ||
| Table 2           | 02_analysis/table2and3.do| 15          | table2.csv                       ||
| Table 3           | 02_analysis/table2and3.do| 145         | table3.csv                       ||
| Figure 1          | n.a. (no data)           |             |                                  | Source: Herodus (2011)          |
| Figure 2          | 02_analysis/fig2.do      |             | figure2.png                      ||
| Figure 3          | 02_analysis/fig3.do      |             | figure-robustness.png            | Requires confidential data      |

## List of datasets

### Master data sets

| Data set name    | Location                            | [Key](https://dimewiki.worldbank.org/ID_Variable_Properties)        | [Foreign keys](https://en.wikipedia.org/wiki/Foreign_key)  | Main variables         | Created by |
|------------------|-------------------------------------|------------|------------|------------------------------------------------|--------|

### Raw data

| Data set name    | Location                     | Unit of observation | Key        | Foreign keys | Main variables                          | Instrument/source |
|------------------|------------------------------|---------------------|------------|--------------|-----------------------------------------|-------------------|
| Water point census   | Data/WaterPointCensus/DataSets/Raw/DIL Water Point Census.dta   | enumerator    | wp_id, key, enumerator_id, date |    | Water point census           | [Link](https://ipauganda.surveycto.com/collect/dil_waterpoint_census?caseid=) |

### Tidy data

| Data set name  | Location                    | Unit of observation | Key        | Foreign keys | Main variables                          | Created by |
|----------------|-----------------------------|---------------------|------------|--------------|-----------------------------------------|------------|

### Intermediate/constructed data

| Data set name         | Location                                  | Unit of observation | Key        | Foreign keys | Main variables               | Created by |
|-----------------------|-------------------------------------------|---------------------|------------|--------------|------------------------------|------------|
| 

### Analysis/final data

| Data set name    | Location                        | Unit of observation | Key      | Main variables | Created by |
|------------------|---------------------------------|---------------------|----------|----------------|------------|
| Water point census  | Data/WaterPointCensus/DataSets/Final/wp-census | water point          | wp_id | wp_id, wp_func, wp_disp | code/WaterPointCensus/wrangling/08-create-final-wp-data.dta 


---

## Acknowledgements

This file was adapted from the Social Science Data Editors website. For the latest version, visit [https://social-science-data-editors.github.io/template_README/](https://social-science-data-editors.github.io/template_README/)
