

LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

%LET wrds=wrds.wharton.upenn.edu 4016;
OPTIONS COMAMID=TCP REMOTE=WRDS;
SIGNON USERNAME=_prompt_;


/* ************************** Assemble PatEx & Transation (patent assignment) Data ****************************** */

/* Import data to match application number and transaction identifier data*/
PROC IMPORT OUT= WORK.docid (keep= rf_id appno_doc_num appno_date grant_doc_num)  
            DATAFILE= "R:\ps664\Patent Assignment and Transfer Data\documentid.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.conv  
            DATAFILE= "R:\ps664\Patent Assignment and Transfer Data\assignment_conveyance.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.doc_adm 
            DATAFILE= "R:\ps664\Patent Assignment and Transfer Data\documentid_admin.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;
/*proc sort  data = doc_adm out=doc_adm ; by rf_id ; run;*/

PROC IMPORT OUT= WORK.assignee (keep= rf_id ee_name )  
            DATAFILE= "R:\ps664\Patent Assignment and Transfer Data\assignee.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.assignment (keep= rf_id cname record_dt)  
            DATAFILE= "R:\ps664\Patent Assignment and Transfer Data\assignment.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;

PROC IMPORT OUT= WORK.assignor (keep= rf_id or_name exec_dt)  
            DATAFILE= "R:\ps664\Patent Assignment and Transfer Data\assignor.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;


DATA conv_1;
  SET conv;
if employer_assign=1;
rename rf_id=rf_id_1;
RUN;

/* merge with docid to get application number of the transaction*/
PROC SQL ;
	CREATE TABLE conv_doc AS
	SELECT *
	FROM docid AS l LEFT JOIN conv_1 AS r
	ON	l.rf_id = r.rf_id_1 ;
QUIT;

/* keep only transactions with ssignment to the employer*/
DATA conv_doc_1 (drop = appno_date convey_ty);
  SET conv_doc;
 if employer_assign=1;
 if not missing(appno_doc_num);
 drop employer_assign;
RUN;

/* merge with assignee to get company name to which an employee assigned this patent*/
PROC SQL ;
	CREATE TABLE conv_doc_assignee AS
	SELECT *
	FROM conv_doc_1 AS l LEFT JOIN assignee AS r
	ON	l.rf_id_1 = r.rf_id ;
QUIT;

DATA conv_doc_assignee_1;
  SET conv_doc_assignee;
label appno_doc_num = "application number"
		rf_id = "transaction id"
		ee_name = "patent assignee or firm"
		grant_doc_num = "granted patent number";
drop rf_id_1;
RUN;



PROC IMPORT OUT= WORK.app_data (keep= application_number application_invention_type filing_date  examiner_id examiner_art_unit examiner_full_name  uspc_class uspc_subclass appl_status_desc appl_status_code patent_number patent_issue_date abandon_date disposal_type small_entity_indicator) 
DATAFILE= "R:\ps664\Patent Examiner Data\2019 data\application_data.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;

			/* 2017 DATA*/

			/*PROC IMPORT OUT= WORK.app_data (keep= application_number filing_date invention_subject_matter examiner_id examiner_art_unit examiner_name_last examiner_name_first examiner_name_middle uspc_class appl_status_code patent_number patent_issue_date abandon_date disposal_type small_entity_indicator) 
			DATAFILE= "R:\ps664\Patent Examiner Data\application_data.csv" 
			            DBMS=csv REPLACE;
			     GETNAMES=YES;
			RUN;
			*/


/* create examiner id based on examiner's full name*/
DATA app_data_examiner ;
  SET app_data;
  ex_art_id = input(examiner_art_unit, $12.);
  /*examiner_id_art = cats(examiner_id, ex_art_id);*/
  /*full_name = cats(examiner_name_first,examiner_name_middle,examiner_name_last);*/
RUN;
proc sort data = app_data_examiner out=app_data_examiner ; by examiner_full_name ; run;

data app_data_examiner;
set app_data_examiner;
by examiner_full_name;
if first.examiner_full_name then examiner_number + 1;
/*by full_name;
if first.full_name then examiner_number + 1;*/
drop ex_art_id;
run;

/* I required non-missing info on tech class info, filing date, */
/* keep only transactions with ssignment to the employer*/
DATA app_data_1 ;
  SET app_data_examiner;
/* dropped PCT/ internatianally filed patents because they don't have company names assigned to them*/
if find(application_number,'PCT')>0 then delete;
if not missing(filing_date);
if examiner_full_name="NoneNoneNone" then examiner_number=.;
if missing(examiner_full_name) then examiner_number=.; 
drop examiner_full_name;
application_number_1 = input(application_number, best12.);
RUN;


/* now merge info on patent assignee (firm owner) to the patent application or PatEx data*/
PROC SQL ;
	CREATE TABLE app_conv_doc_assignee AS
	SELECT *
	FROM app_data_1 AS l LEFT JOIN  conv_doc_assignee_1 AS r
	ON	l.application_number_1 = r.appno_doc_num;
QUIT;

/* several cases have a firm who filed it, but it's recorded as first named applicant*/
/* have to do robustness by dropping observations after 2012*/

/* NOTE: a lot of applications (starting with 6, 9 appl number) have some assignment but they're not in the assignment transaction data*/

DATA app_conv_doc_assignee_1;
  SET app_conv_doc_assignee;
if not missing(ee_name);
n_to_add=1;
f_year=year(filing_date);
RUN;




/* split the file to granted vs not granted patents*/
/* merge granted patents with gvkey using Stoffman or Dorn data*/

					/* Granted patents*/

/* 74.4% of patents filed by firm are granted*/
DATA granted;
  SET app_conv_doc_assignee_1;
if not missing(grant_doc_num);
RUN;

DATA granted_1;
  SET granted;
	app_y=year(filing_date);
	format grant_doc_num_1 $8.;
	grant_doc_num_1=grant_doc_num;
  if lengthn(grant_doc_num_1)<8 then
    grant_doc_num_1=repeat('0',7-lengthn(grant_doc_num_1))!!grant_doc_num_1;
	format grant_doc_num_2 best12.;
grant_doc_num_2 = input(grant_doc_num_1, best12.);
RUN;


/* Import state data for matched granted patent to gvkey from Dorn*/
PROC IMPORT
	DATAFILE="R:\ps664\Patent Applications - Michelle Michela\Name matching\Patents to GVKEY through websearch\cw_patent_compustat_adhps\cw_patent_compustat_adhps.dta"  
	DBMS=dta
	OUT=dorn_mathced (keep= patent appyear gvkey assignee_clean)
	REPLACE;
RUN;


/*now add Stoffman's update data until 2019*/

/* Stoffman data until 2019*/
PROC IMPORT
	DATAFILE="R:\ps664\Data\KPSS Patent Data and Scaled Cites\KPSS_2019_public.csv"  
	DBMS=csv
	OUT=stoffman2019 (keep= patent_num filing_date permno )
	REPLACE;
RUN;

DATA stoffman2019;
  SET stoffman2019;
 rename patent_num=patnum;
 rename filing_date=fdate;
RUN;

			/* Stoffman data until 2017*/
			/* new Stoffman's data uses PERMCO instead of PERMNO -> adjusted in CRSP-Comp merge later*/
			PROC IMPORT
				DATAFILE="C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\Patents\Stoffman  2017\patent_values.csv"  
				DBMS=csv
				OUT=stoffman2017 (keep= patnum fdate permco )
				REPLACE;
			RUN;

		/* Stoffman's data until 2010*/
			PROC IMPORT
				DATAFILE="C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\Patents\patents.csv"  
				DBMS=csv
				OUT=stoffman (keep= patnum fdate permno )
				REPLACE;
			RUN;


DATA stoffman_1;
  SET stoffman2019;
 yr = year(fdate);
RUN;


/* match granted patents*/
PROC SQL ;
	CREATE TABLE granted_stoffman AS
	SELECT *
	FROM granted_1 AS l LEFT JOIN  stoffman_1 AS r
	ON	l.grant_doc_num_2 = r.patnum AND l.app_y=r.yr;
QUIT;



/* 2.6 mil matched granted patents with stoffman (*1 mil of non-missing PERMNO)/
/* matched patent - those that matched on year */
/* 1.5 mil matched with updated Stoffman's data (non-missing PERMCO)*/
DATA granted_stoffman_1;
  SET granted_stoffman;
 if not missing(yr) & not missing(patnum);
 rename grant_doc_num_2= granted_pat;
 drop grant_doc_num_1 patnum yr;
RUN;


/* save matched patents to later stack them with name-matched patents*/
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela\Name matching';
data comp.matched_stoffman;
 set granted_stoffman_1;
run;
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

/* BELOW IS JUST A MATCH COMPARISON BETWEEN STOFFMAN 2010 AND 2017 DATA*/
/* MARK CPATENTS THAT WERE NOT IN STOFFMAN'S DATA (either 2017 or 2010)*/

		/* Stoffman's data until 2010*/
			PROC IMPORT
				DATAFILE="C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\Patents\patents.csv"  
				DBMS=csv
				OUT=stoffman (keep= patnum fdate permno )
				REPLACE;
			RUN;
/* merge with Stoffman's 2010 because for patents that he processed but didn't match to CRSP-Compustat*/
/* that way I'll mini,ize n of obs to process in google*/
DATA stoffman_2;
  SET stoffman;
 yr_2010 = year(fdate);
 rename patnum = patnum_2010;
 rename fdate = fdate_2010;
RUN;
PROC SQL ;
	CREATE TABLE granted_stoffman_2010 AS
	SELECT *
	FROM granted_stoffman AS l LEFT JOIN  stoffman_2 AS r
	ON	l.grant_doc_num_2 = r.patnum_2010 AND l.app_y=r.yr_2010;
QUIT;

/*3.3 mil not matched from Stoffman 2010 */ 
/*1.8 mil not matched from both 2010 & 2017 */
/*1.7 mil not matched from both 2010 & 2019 */
DATA stoffman_not_matched;
  SET granted_stoffman_2010;
/* if missing in both Stoffman 2010 and 2017*/
if missing(yr_2010) & missing(yr);
rename grant_doc_num_2= granted_pat;
drop grant_doc_num_1 patnum yr yr_2010 patnum_2010 fdate_2010;
drop permco permno fdate app_y;
RUN;



					/* Not Granted patents & not matched with Stoffman*/


/* 25.6% of patents filed by firm are NOT granted*/
DATA not_granted;
  SET app_conv_doc_assignee_1;
if missing(grant_doc_num);
grant_doc_num=.;
granted_pat=.;
label grant_doc_num = "patent_number";
label granted_pat = "utility_patent_number";
RUN;

/* total of 3.9 mil for not granted patents and patents granted but not merged with Stoffman*/
/* total of 3.5 (3.3 nodup) mil for not granted patents and patents granted but not merged with Stoffman*/
/*(after adding stoffman 2017, patent that are granted to private firms (not matched to CRSP-Comp are still in sample)*/

DATA not_granted_1;
  SET not_granted stoffman_not_matched;
  year = year(filing_date);
RUN;
proc sort nodupkey data = not_granted_1 out=not_granted_1 ; by application_number ee_name uspc_class filing_date granted_pat grant_doc_num ; run;
 
/* merge based on patent filer's company name - perfect match*/


/* Import CRSP-Copmustat*/
PROC IMPORT
	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\crsp_comp_reduced.dta'
	DBMS=dta
	OUT=crsp_comp_reduced 
	REPLACE;
RUN;

/* Standardize company names*/
DATA crsp_comp_reduced_1;
	SET crsp_comp_reduced;
	formatted_conm  = COMPRESS(UPCASE(conm),".");
	formatted_name  = TRANWRD(formatted_name,"EMC CORP/MA",'EMC');										
	formatted_conm  = TRANWRD(formatted_conm,"&",' AND ');
	formatted_conm  = TRANWRD(formatted_conm,"+",' AND ');
	formatted_conm  = TRANSLATE(formatted_conm,' ',"!(),/:?-");
	formatted_conm  = TRANWRD(formatted_conm,' LLC',"");
	formatted_conm  = TRANWRD(formatted_conm,' LP','');
	formatted_conm  = TRANWRD(formatted_conm,'THE ','');
	formatted_conm  = TRANWRD(formatted_conm,'FINANCIAL','FINL');
	formatted_conm  = TRANWRD(formatted_conm,' INTERNATIONAL',' INTL');
	formatted_conm  = TRANWRD(formatted_conm,' COMPANY',' CO');
	formatted_conm  = TRANWRD(formatted_conm,' CORPORATION',' CORP');
	formatted_conm  = TRANWRD(formatted_conm,' INCORP','');
	formatted_conm  = TRANWRD(formatted_conm,' INC','');
	formatted_conm  = TRANWRD(formatted_conm,' LIMITED','');
	/*formatted_conm  = TRANWRD(formatted_conm,' INDUSTRIES','');*/
	formatted_conm  = TRANWRD(formatted_conm,' CC','');
	formatted_conm  = TRANWRD(formatted_conm,' LTD','');
	formatted_conm  = TRANWRD(formatted_conm,'L L C','');
	formatted_conm  = TRANWRD(formatted_conm,' AG ','');
	formatted_conm  = TRANWRD(formatted_conm,' PLC ','');
	formatted_conm  = TRANWRD(formatted_conm,' SYSTEMS','S');
	formatted_conm  = TRANWRD(formatted_conm,' LIMITED PARTNERSHIP','');
	formatted_conm  = TRANWRD(formatted_conm,')','');
	formatted_conm  = TRANWRD(formatted_conm," INT'L",'INTL');
	formatted_conm  = TRANWRD(formatted_conm," ET AL",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANIES",'COS');
	formatted_conm  = TRANWRD(formatted_conm," US ",'');
	formatted_conm  = TRANWRD(formatted_conm," ORPORATED",'CORP');
	formatted_conm  = TRANWRD(formatted_conm," SOLTNS",' SOLUTIONS');
	formatted_conm  = TRANWRD(formatted_conm," SYS ",' S ');
	formatted_conm  = TRANWRD(formatted_conm," PRODUCTS",' PROD');
	formatted_conm  = TRANWRD(formatted_conm,"'S",'S');
	formatted_conm  = TRANWRD(formatted_conm," LABORATORY",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," LABORATORIES",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," LABORATO",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTICALS",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTICAL",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTIC",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUT",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm,' TECHNOLOGIES',' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHNOLOGY",' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHNOL",' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHN",' TECH');
	formatted_conm  = TRANWRD(formatted_conm,"'",'');
	formatted_conm  = TRANWRD(formatted_conm," CL A",'');
	formatted_conm  = TRANWRD(formatted_conm," CL B",'');
	formatted_conm  = TRANWRD(formatted_conm," REDH ",'');
	formatted_conm  = TRANWRD(formatted_conm," CORPP",'');
	formatted_conm  = TRANWRD(formatted_conm," CORP",'');
	formatted_conm  = TRANWRD(formatted_conm," COR",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANIES",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANY",'');
	formatted_conm  = TRANWRD(formatted_conm," COS ",'');
	formatted_conm  = TRANWRD(formatted_conm," CO ",'');
	formatted_conm  = TRANWRD(formatted_conm," OLD ",'');
	formatted_conm  = TRANWRD(formatted_conm," HLDGS",'');
	formatted_conm  = TRANWRD(formatted_conm," INTL",'');
	formatted_conm  = TRANWRD(formatted_conm," GROUP",'');
	formatted_conm  = TRANWRD(formatted_conm," GBR",'');
	if find(formatted_conm, 'INTL BUSINESS MACHINES') then formatted_conm="INTL BUSINESS MACHINES";
	if find(formatted_conm, 'NORTEL NETWORKS') then formatted_conm="NORTEL NETWORKS";
	if find(formatted_conm, 'UNITED TECH') then formatted_conm="UNITED TECH";
	if find(formatted_conm, "DISNEY  WALT") then formatted_conm="WALT DISNEY";
RUN;



DATA not_granted_2;
	SET not_granted_1;
	formatted_name  = COMPRESS(UPCASE(ee_name),".");
	formatted_name  = TRANWRD(formatted_name,"EMC CORPORATION",'EMC');
	formatted_name  = TRANWRD(formatted_name,"EMC TECHNOLOGY INC",'EMC');
	formatted_name  = TRANWRD(formatted_name,"&",' AND ');
	formatted_name  = TRANWRD(formatted_name,"+",' AND ');
	formatted_name  = TRANSLATE(formatted_name,' ',"!(),/:?-");
	formatted_name  = TRANWRD(formatted_name,' LLC',"");
	formatted_name  = TRANWRD(formatted_name,' LP','');
	formatted_name  = TRANWRD(formatted_name,'THE ','');
	formatted_name  = TRANWRD(formatted_name,'FINANCIAL','FINL');
	formatted_name  = TRANWRD(formatted_name,' INTERNATIONAL',' INTL');
	formatted_name  = TRANWRD(formatted_name,' COMPANY',' CO');
	formatted_name  = TRANWRD(formatted_name,' CORPORATION',' CORP');
	formatted_name  = TRANWRD(formatted_name,' INCORP','');
	formatted_name  = TRANWRD(formatted_name,' INC','');
	formatted_name  = TRANWRD(formatted_name,' LIMITED','');
	/*formatted_name  = TRANWRD(formatted_name,' INDUSTRIES','');*/
	formatted_name  = TRANWRD(formatted_name,' CC','');
	formatted_name  = TRANWRD(formatted_name,' LTD','');
	formatted_name  = TRANWRD(formatted_name,'L L C','');
	formatted_name  = TRANWRD(formatted_name,' AG ','');
	formatted_name  = TRANWRD(formatted_name,' PLC ','');
	formatted_name  = TRANWRD(formatted_name,' SYSTEMS','S');
	formatted_name  = TRANWRD(formatted_name,' LIMITED PARTNERSHIP','');
	formatted_name  = TRANWRD(formatted_name,')','');
	formatted_name  = TRANWRD(formatted_name," INT'L",'INTL');
	formatted_name  = TRANWRD(formatted_name," ET AL",'');
	formatted_name  = TRANWRD(formatted_name," COMPANIES",'COS');
	formatted_name  = TRANWRD(formatted_name," US ",'');
	formatted_name  = TRANWRD(formatted_name," ORPORATED",'CORP');
	formatted_name  = TRANWRD(formatted_name," SOLTNS",' SOLUTIONS');
	formatted_name  = TRANWRD(formatted_name," SYS ",' S ');
	formatted_name  = TRANWRD(formatted_name," PRODUCTS",' PROD');
	formatted_name  = TRANWRD(formatted_name,"'S",'S');
	formatted_name  = TRANWRD(formatted_name," LABORATORY",' LAB');
	formatted_name  = TRANWRD(formatted_name," LABORATORIES",' LAB');
	formatted_name  = TRANWRD(formatted_name," LABORATO",' LAB');
	formatted_name  = TRANWRD(formatted_name," PHARMACEUTICALS",' PHARMA');
	formatted_name  = TRANWRD(formatted_name," PHARMACEUTICAL",' PHARMA');
	formatted_name  = TRANWRD(formatted_name," PHARMACEUTIC",' PHARMA');
	formatted_name  = TRANWRD(formatted_name," PHARMACEUT",' PHARMA');
	formatted_name  = TRANWRD(formatted_name,' TECHNOLOGIES',' TECH');
	formatted_name  = TRANWRD(formatted_name," TECHNOLOGY",' TECH');
	formatted_name  = TRANWRD(formatted_name," TECHNOL",' TECH');
	formatted_name  = TRANWRD(formatted_name," TECHN",' TECH');
	formatted_name  = TRANWRD(formatted_name,"'",'');	
	formatted_name  = TRANWRD(formatted_name," CL A",'');
	formatted_name  = TRANWRD(formatted_name," CL B",'');
	formatted_name  = TRANWRD(formatted_name," REDH ",'');
	formatted_name  = TRANWRD(formatted_name," CORPP",'');
	formatted_name  = TRANWRD(formatted_name," CORP",'');
	formatted_name  = TRANWRD(formatted_name," COR",'');
	formatted_name  = TRANWRD(formatted_name," COMPANIES",'');
	formatted_name  = TRANWRD(formatted_name," COMPANY",'');
	formatted_name  = TRANWRD(formatted_name," COS ",'');
	formatted_name  = TRANWRD(formatted_name," CO ",'');
	formatted_name  = TRANWRD(formatted_name," OLD ",'');
	formatted_name  = TRANWRD(formatted_name," HLDGS",'');
	formatted_name  = TRANWRD(formatted_name," INTL",'');
	formatted_name  = TRANWRD(formatted_name," GROUP",'');
	formatted_name  = TRANWRD(formatted_name," GBR",'');	 
RUN;


PROC SQL ;
	CREATE TABLE perfect_match AS
	SELECT *
	FROM not_granted_2 AS l LEFT JOIN  crsp_comp_reduced_1 AS r
	ON	l.formatted_name = r.formatted_conm AND l.year=r.fyear;
QUIT;

/* keep those that matched easily*/
DATA perfect_match_1;
SET perfect_match;
if not missing(permno);
run;
/* save matched patents to later stack them with name-matched patents*/
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela\Name matching';
data comp.matched_perfect;
 set perfect_match_1;
run;
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';


/* save the rest for a snap*/
DATA left_to_match;
SET perfect_match;
if missing(permno);
drop permno gvkey formatted_conm fyear;
run;

LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela\Name matching';
DATA comp.full_left_to_match_2019 ;
  SET left_to_match;
RUN;
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';


/* keep application_number to merge back to left_to_match*/
/* keep ee_name - assignee name, */
/* IMPORTANT: BECAUSE STOFFMAN PROCESSED ALL GRANTED PATENTS UNTIL 2017 - NO!! just those that were granted to public firms */
/* I WILL ONLY LOOK FOR NON-GRANTED PATENT APPLICATIONS AND GRANTED PATENTS FROM NON-UNTILITY (AS STOFFMAN DOESNT' CHECK THEM)*/
/* (that would be all applications that don't have a utility pat number assigned to it) */
DATA not_granted_snap (keep = formatted_name application_number year granted_pat);
  SET left_to_match;
	/* new line of code with Stoffman 2017*/
	if missing(granted_pat);
  drop granted_pat;
RUN;

DATA crsp_comp_reduced_1 ;
  SET crsp_comp_reduced_1;
  drop conm formatted_name;
RUN;


/* delete repeated company names*/
/* total of 13,677 unique compnay names from CRSP-Comp*/
proc sort nodupkey data = crsp_comp_reduced_1 out=crsp_comp_reduced_1 ; by permno gvkey formatted_conm ; run;
/* total of 375,528  unique applicants names*/
proc sort nodupkey data = not_granted_snap out=not_granted_snap ; by formatted_name ; run;
/* merge back by formatted_name*/

/* 3.4 mil applications left to match */
/* this dataset has applications and company names that filed them*/
PROC EXPORT
	DATA=crsp_comp_reduced_1
	DBMS=xlsx
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\Name matching\crsp_comp_reduced.xlsx'
	REPLACE;
RUN;

PROC EXPORT
	DATA=not_granted_snap
	DBMS=xlsx
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\Name matching\not_granted_snap.xlsx'
	REPLACE;
RUN;










/* ************************** Name-matching ****************************** */

/* all name-matching will take 233707obs * 5(pairs)(= n of google searches)/60/60/24 = 13.5 days (if google takes 1 sec per obs)  */

LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

/* Import CRSP-Copmustat*/
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\crsp_comp_reduced.xlsx'	DBMS=xlsx
	OUT=crsp_comp_reduced 	REPLACE; RUN;

/* Import CRSP-Copmustat*/
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\not_granted_snap.xlsx'	DBMS=xlsx
	OUT=not_granted_snap 	REPLACE; RUN;

	/* STOPPED WITH STOFFMAN'S 2017 DATA HERE FOR PYTHON MATCH*/

/* I broke down requests to WRDS by year to join them all later => last request was for 2016 */
/* (because WRDS creates 233707*13677=3,196,410,639 pairs to create GED score*/
proc sort data = not_granted_snap ; by year; run;
DATA not_granted_snap ;
  SET not_granted_snap;
if year>=2016 ;  
RUN;

%LET wrds=wrds.wharton.upenn.edu 4016;
OPTIONS COMAMID=TCP REMOTE=WRDS;
SIGNON USERNAME=_prompt_;


/* Submit the request to WRDS computer*/
RSUBMIT;

proc upload data=crsp_comp_reduced ;
run;
proc upload data=not_granted_snap ;
run;

proc sort data = not_granted_snap; by formatted_name; run;
proc sort data = crsp_comp_reduced; by formatted_conm; run;


/* Create the potential matches*/
proc sql;
	create table potential_matches as
	select a.*, b.*
	from not_granted_snap as a, crsp_comp_reduced as b;
quit;


/* Fin the distance score*/
data potential_matches_1;
	set potential_matches;
	gedscore = compged(formatted_name, formatted_conm, 'iLn:');
run;


proc sort data = potential_matches_1 ; by formatted_name gedscore; run;

data potential_matches_2;
  set potential_matches_1;
  top_5 + 1;
  by formatted_name ;
  if first.formatted_name  then top_5 = 1;
run;

data lawsuits_comp_np_3;
  set potential_matches_2;
  if top_5 < 4 ;
  rename formatted_name=lawsuit_name;
  rename  formatted_conm=matched_CRSP_name;
  rename gvkey=matched_gvkey;
run;

PROC DOWNLOAD DATA=lawsuits_comp_np_3 OUT=potential_pairs;
RUN;

ENDRSUBMIT;


PROC EXPORT
	DATA=potential_pairs
	DBMS=csv
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_11.csv'
	REPLACE;
RUN;


/* Putting files back together*/

/* Import CRSP-Copmustat*/
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_1.csv'	DBMS=csv
	OUT=pairs1 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_2.csv'	DBMS=csv
	OUT=pairs2 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_3.csv'	DBMS=csv
	OUT=pairs3 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_4.csv'	DBMS=csv
	OUT=pairs4 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_5.csv'	DBMS=csv
	OUT=pairs5 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_6.csv'	DBMS=csv
	OUT=pairs6 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_7.csv'	DBMS=csv
	OUT=pairs7 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_8.csv'	DBMS=csv
	OUT=pairs8 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_9.csv'	DBMS=csv
	OUT=pairs9 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_10.csv'	DBMS=csv
	OUT=pairs10 	REPLACE; RUN;
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\potential_pairs_11.csv'	DBMS=csv
	OUT=pairs11 	REPLACE; RUN;

data all_pairs;
  set pairs7 pairs6 pairs4 pairs3  pairs2 pairs1  pairs5 pairs8 pairs9 pairs10 pairs11;
rename lawsuit_name = assignee_name;
run;

proc sort data = all_pairs ; by year application_number gedscore; run;

proc sort data = all_pairs out = m_all_pairs ; by gedscore; run;


data matched;
  set m_all_pairs;
if gedscore=0;
run;

data not_matched;
  set m_all_pairs;
if gedscore>0;
run;

PROC EXPORT 	DATA=not_matched	DBMS=csv
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\Name matching\left_to_match.csv'	REPLACE; RUN;

/* match applications that matched to gvkey back to the main dataset*/

LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela\Name matching';


/* Get Python Output*/
/* Merge gvkey back to the matched Python dataset*/
/* Merge Python Output back to full_left_to_match using formatted_name */
/*(and not year as I collapsed all repeated year observations for the same company name)*/

LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela\Name matching';

data full_left_to_match;
 set comp.full_left_to_match_2019;
run;

data matched_perfect;
 set comp.matched_perfect;
 gvkey_1 = input(gvkey, best12.);
 drop gvkey;
run;

data matched_stoffman;
 set comp.matched_stoffman;
run;

/* Match data from Python back */
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Applications - Michelle Michela\Name matching\Python Code Files\matched_by_name.xlsx'	DBMS=xlsx
	OUT=python_match 	REPLACE; RUN;


data python_match_1;
 set python_match;
 if match=1;
 drop A;
run;


/* Merge back using formatted_name (I only kept one name)*/
PROC SQL;
	CREATE TABLE crsp_python AS
	SELECT *
	FROM full_left_to_match  AS l LEFT JOIN python_match_1 AS r
	ON	l.formatted_name = r.assignee_name ;
QUIT;

data matched_python;
 set crsp_python;
 if match=1;
 drop match;
run;


/* Reorder variables to stack all data together*/
data matched_perfect_1;
retain application_number examiner_number examiner_id_art examiner_art_unit filing_date invention_subject_matter examiner_id uspc_class appl_status_code patent_number patent_issue_date abandon_date disposal_type  small_entity_indicator application_number_1  rf_id ee_name grant_doc_num granted_pat permno gvkey_1 fyear formatted_name;
set matched_perfect;
drop grant_doc_num year  application appno_doc_num formatted_conm ;
rename formatted_name=conm;
rename gvkey_1=gvkey;
if granted_pat=0 then granted_pat=.;
match="perfect";
run;

data matched_python_1;
retain application_number examiner_number examiner_id_art examiner_art_unit filing_date invention_subject_matter examiner_id uspc_class appl_status_code patent_number patent_issue_date abandon_date disposal_type  small_entity_indicator application_number_1  rf_id ee_name grant_doc_num granted_pat permno matched_gvkey fyear formatted_name ;
set matched_python;
drop grant_doc_num  year VAR1 gedscore matched_CRSP_name  assignee_name application appno_doc_num;
rename matched_gvkey = gvkey;
label gvkey = gvkey;
rename formatted_name = conm;
fyear = year(filing_date);
match="python";
drop A;
run;

/* for Stoffman2017 use PERMCO, for Stoffman2019 use PERMNO*/
data matched_stoffman_1;
retain application_number examiner_number examiner_id_art examiner_art_unit filing_date invention_subject_matter examiner_id uspc_class appl_status_code patent_number patent_issue_date abandon_date disposal_type  small_entity_indicator application_number_1  rf_id ee_name grant_doc_num granted_pat permno gvkey conm;
set matched_stoffman;
drop app_y fdate appno_doc_num;
rename permno=permno_s;
fyear_s = year(filing_date);
if permno=. then delete;
run;


/* ************************** Get PERMNO and CONM columns for Stoffman's data to collapse all data ********************* */
%LET wrds=wrds.wharton.upenn.edu 4016;
OPTIONS COMAMID=TCP REMOTE=WRDS;
SIGNON USERNAME=_prompt_;

RSUBMIT;
/* Get gvkey, conm, fyear from Compustat*/
DATA funda1 ;
	SET comp.funda (KEEP = fyear conm gvkey datadate);
	WHERE 1970	 <= fyear <= 2021;
RUN;
PROC DOWNLOAD DATA=funda1 OUT=funda1;
RUN;
ENDRSUBMIT;

/* Get permno from CRSP + merge with Compustat */
RSUBMIT;
%MACRO CCM (INSET=,DATEVAR=DATADATE,OUTSET=,LINKTYPE=LULC,REMDUPS=1,OVERLAP=0);
 
/* Check Validity of CCM Library Assignment */
%if (%sysfunc(libref(CCM))) %then %do; libname CCM ("/wrds/crsp/sasdata/q_ccm/"); %end;
%if (%sysfunc(libref(CCM))) %then %do; libname CCM ("/wrds/crsp/sasdata/a_ccm/") ; %end;
%put; %put ### START. ;
 
/* Convert the overlap distance into months */
%let overlap=%sysevalf(12*&overlap.);
 
options nonotes;
/* Make sure first that the input dataset has no duplicates by GVKEY-&DATEVAR */
proc sort data=&INSET out=_ccm0 nodupkey; by GVKEY &DATEVAR; run;
 
/* Add Permno to Compustat sample */
proc sql;
create table _ccm1 as
select distinct b.lpermno as PERMNO " ", b.lpermco as PERMCO, a.*, b.linkprim, b.linkdt
from _ccm0 as a, crsp.ccmxpf_linktable as b
where a.gvkey=b.gvkey and index("&linktype.",strip(b.linktype))>0
and (a.&datevar>= intnx("month",b.linkdt   ,-&overlap.,"b") or missing(b.linkdt)   )
and (a.&datevar<= intnx("month",b.linkenddt, &overlap.,"e") or missing(b.linkenddt));
quit;
proc sort data=_ccm1;
  by &datevar permno descending linkprim descending linkdt gvkey;
run;
 
/* it ties in the linkprim, then use most recent link or keep all */
data _ccm2;
set _ccm1;
by &datevar permno descending linkprim descending linkdt gvkey;
if first.permno;
%if &REMDUPS=0 %then %do; drop linkprim linkdt; %end;
run;
  
%if &REMDUPS=1 %then
 %do;
   proc sort data=_ccm2; by &datevar gvkey descending linkprim descending linkdt;
   data _ccm2;
   set _ccm2;
   by &datevar gvkey descending linkprim descending linkdt;
   if first.gvkey;
   drop linkprim linkdt;
   run;
   %put ## Removed Multiple PERMNO Matches per GVKEY ;
 %end;
 
/* Sanity Check -- No Duplicates -- and Save Output Dataset */
proc sort data=_ccm2 out=&OUTSET nodupkey; by gvkey &datevar permno; run;
%put ## &OUTSET Linked Table Created;
 
/* House Cleaning */
proc sql;
 drop table _ccm0, _ccm1, _ccm2;
quit;
 
%put ### DONE . ; %put ;
options notes;
%MEND CCM;

%CCM(INSET=funda1,DATEVAR=datadate,OUTSET=ccm1,LINKTYPE=LULC,REMDUPS=1,OVERLAP=0);
/*Extract dataset from WRDS*/
PROC DOWNLOAD DATA=ccm1 OUT=ccm1;
RUN;
ENDRSUBMIT;
/* ********************************************************************************* */

/* standardize conm*/
data crsp_comp_reduced ;
set ccm1;
gvkey_1 = input(gvkey, best12.);
drop gvkey;
label permco = "permco";
run;


/* Standardize company names*/
DATA crsp_comp_reduced_1;
	SET crsp_comp_reduced;
	rename gvkey_1 = gvkey;
	formatted_conm  = COMPRESS(UPCASE(conm),".");
	formatted_conm  = TRANWRD(formatted_conm,"EMC CORP/MA",'EMC');										
	formatted_conm  = TRANWRD(formatted_conm,"&",' AND ');
	formatted_conm  = TRANWRD(formatted_conm,"+",' AND ');
	formatted_conm  = TRANSLATE(formatted_conm,' ',"!(),/:?-");
	formatted_conm  = TRANWRD(formatted_conm,' LLC',"");
	formatted_conm  = TRANWRD(formatted_conm,' LP','');
	formatted_conm  = TRANWRD(formatted_conm,'THE ','');
	formatted_conm  = TRANWRD(formatted_conm,'FINANCIAL','FINL');
	formatted_conm  = TRANWRD(formatted_conm,' INTERNATIONAL',' INTL');
	formatted_conm  = TRANWRD(formatted_conm,' COMPANY',' CO');
	formatted_conm  = TRANWRD(formatted_conm,' CORPORATION',' CORP');
	formatted_conm  = TRANWRD(formatted_conm,' INCORP','');
	formatted_conm  = TRANWRD(formatted_conm,' INC','');
	formatted_conm  = TRANWRD(formatted_conm,' LIMITED','');
	/*formatted_conm  = TRANWRD(formatted_conm,' INDUSTRIES','');*/
	formatted_conm  = TRANWRD(formatted_conm,' CC','');
	formatted_conm  = TRANWRD(formatted_conm,' LTD','');
	formatted_conm  = TRANWRD(formatted_conm,'L L C','');
	formatted_conm  = TRANWRD(formatted_conm,' AG ','');
	formatted_conm  = TRANWRD(formatted_conm,' PLC ','');
	formatted_conm  = TRANWRD(formatted_conm,' SYSTEMS','S');
	formatted_conm  = TRANWRD(formatted_conm,' LIMITED PARTNERSHIP','');
	formatted_conm  = TRANWRD(formatted_conm,')','');
	formatted_conm  = TRANWRD(formatted_conm," INT'L",'INTL');
	formatted_conm  = TRANWRD(formatted_conm," ET AL",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANIES",'COS');
	formatted_conm  = TRANWRD(formatted_conm," US ",'');
	formatted_conm  = TRANWRD(formatted_conm," ORPORATED",'CORP');
	formatted_conm  = TRANWRD(formatted_conm," SOLTNS",' SOLUTIONS');
	formatted_conm  = TRANWRD(formatted_conm," SYS ",' S ');
	formatted_conm  = TRANWRD(formatted_conm," PRODUCTS",' PROD');
	formatted_conm  = TRANWRD(formatted_conm,"'S",'S');
	formatted_conm  = TRANWRD(formatted_conm," LABORATORY",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," LABORATORIES",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," LABORATO",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTICALS",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTICAL",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTIC",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUT",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm,' TECHNOLOGIES',' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHNOLOGY",' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHNOL",' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHN",' TECH');
	formatted_conm  = TRANWRD(formatted_conm,"'",'');
	formatted_conm  = TRANWRD(formatted_conm," CL A",'');
	formatted_conm  = TRANWRD(formatted_conm," CL B",'');
	formatted_conm  = TRANWRD(formatted_conm," REDH ",'');
	formatted_conm  = TRANWRD(formatted_conm," CORPP",'');
	formatted_conm  = TRANWRD(formatted_conm," CORP",'');
	formatted_conm  = TRANWRD(formatted_conm," COR",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANIES",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANY",'');
	formatted_conm  = TRANWRD(formatted_conm," COS ",'');
	formatted_conm  = TRANWRD(formatted_conm," CO ",'');
	formatted_conm  = TRANWRD(formatted_conm," OLD ",'');
	formatted_conm  = TRANWRD(formatted_conm," HLDGS",'');
	formatted_conm  = TRANWRD(formatted_conm," INTL",'');
	formatted_conm  = TRANWRD(formatted_conm," GROUP",'');
	formatted_conm  = TRANWRD(formatted_conm," GBR",'');
	if find(formatted_conm, 'INTL BUSINESS MACHINES') then formatted_conm="INTL BUSINESS MACHINES";
	if find(formatted_conm, 'NORTEL NETWORKS') then formatted_conm="NORTEL NETWORKS";
	if find(formatted_conm, 'UNITED TECH') then formatted_conm="UNITED TECH";
	if find(formatted_conm, "DISNEY  WALT") then formatted_conm="WALT DISNEY";
RUN;


PROC SQL;
	CREATE TABLE matched_stoffman_2 AS
	SELECT *
	FROM matched_stoffman_1  AS l LEFT JOIN crsp_comp_reduced_1 AS r
	ON	l.permno_s = r.permno AND l.fyear_s=r.fyear;
QUIT;

data matched_stoffman_3;
retain application_number examiner_number examiner_id_art examiner_art_unit filing_date invention_subject_matter examiner_id uspc_class appl_status_code patent_number patent_issue_date abandon_date disposal_type  small_entity_indicator application_number_1  rf_id ee_name grant_doc_num granted_pat permno gvkey fyear formatted_conm match permco;
set matched_stoffman_2;
drop app_y fdate appno_doc_num fyear_s permno_s permco_s;
rename formatted_conm=conm;
if not missing(permno);
match="stoffman";
label granted_pat = utility_patent_number;
drop datadate;
run;

data full_data;
 set matched_python_1 matched_stoffman_3 matched_perfect_1 ;
 if granted_pat=0 then  granted_pat=.;
 drop grant_doc_num;
 rename granted_pat = utility_patent_number;
run;

proc sort data = full_data out =  full_data ; by application_number filing_date permno; run;

proc sort nodupkey data = full_data out =  full_applic ; by application_number filing_date permno; run;

/* Add citations from Stoffman 2019*/
PROC IMPORT
	DATAFILE="R:\ps664\Data\KPSS Patent Data and Scaled Cites\KPSS_2019_public.csv"  
	DBMS=csv
	OUT=stoffman2019 
	REPLACE;
RUN;


/* SCALE CITATION COUNTS*/
/* scale citations by the average citations by granted patents from the same tech class*/
/* scale number of granted patents by the average number of patents granted in that year and tech class*/
/* scale number of applications by the average number of application in that year and tech class*/


PROC IMPORT OUT= WORK.app_scale (keep=  uspc_class uspc_subclass patent_number filing_date) 
DATAFILE= "R:\ps664\Patent Examiner Data\2019 data\application_data.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;


data stoffman2019_1;
 set stoffman2019;
patent_num_1 = input(patent_num, $25.);
run;

			data app_scale (keep=  uspc_class uspc_subclass patent_number filing_date) ;
			 set app_data ;
			run;

data app_scale_1 (drop= filing_date) ;
 set app_scale ;
 f_year = year(filing_date);
run;

PROC SQL;
	CREATE TABLE stoffman2019_scaled AS
	SELECT *
	FROM app_scale_1  AS l LEFT JOIN stoffman2019_1 AS r
	ON	l.patent_number = r.patent_num_1 ;
QUIT;

proc sql;
create table stoffman2019_scaled_1 as
  select *, (cites/mean(cites)) as cites_scaled
  from stoffman2019_scaled
  group by f_year, uspc_class;
quit;

data stoffman2019_scaled_2 (keep = patent_num patent_num_1 cites_scaled);
 set stoffman2019_scaled_1 ;
 if not missing(patent_num);
run;

PROC SQL;
	CREATE TABLE stoffman2019_scaled_3 AS
	SELECT *
	FROM stoffman2019_1  AS l LEFT JOIN stoffman2019_scaled_2 AS r
	ON	l.patent_num = r.patent_num ;
QUIT;

/* Merge Scaled Stoffman data with scaled citations*/

PROC SQL;
	CREATE TABLE full_application_data AS
	SELECT *
	FROM full_applic  AS l LEFT JOIN stoffman2019_scaled_3 AS r
	ON	l.utility_patent_number = r.patent_num ;
QUIT;


data full_application_data (drop= application_number_1 patent_num_1 patent_num) ;
 set full_application_data ;
run;


/* Export Patent Application Data*/
LIBNAME comp 'R:\ps664\Data\Patent Application Data';
DATA comp.full_application_data ;
  SET full_application_data;
RUN;
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

PROC EXPORT 	DATA=full_application_data	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\full_application_data.dta'	REPLACE; RUN;

PROC EXPORT 	DATA=full_application_data	DBMS=csv
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\full_application_data.csv'	REPLACE; RUN;
DATA comp.full_application_data ;
  SET full_application_data;
RUN;





/*/////////////////// Mark green patents based on CPC / IPC class ////////////////////////*/

LIBNAME comp 'R:\ps664\Data\Patent Application Data';

DATA full_application_data ;
  SET comp.full_application_data;
RUN;

LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

/* Match data from Python back */
PROC IMPORT	DATAFILE= 'R:\ps664\Patent Examiner Data\CPC patent class data\cpc_appl_data.csv'	DBMS=csv
	OUT=cpc_appl_data (keep = application_number publication_number cpc_section cpc_class cpc_subclass cpc_main_group cpc_subgroup)	REPLACE; RUN;
 

	/* MARK GREEN BASED ON CPC CODES FIRST*/

DATA cpc_appl_data_1 ;
  SET cpc_appl_data;
  rename cpc_section = section;
  rename cpc_class = ipc_class;
  rename cpc_subclass = subclass;
  rename cpc_main_group = main_group;
  rename cpc_subgroup = subgroup;
  drop VAR1 publication_number kind_code cpc_class_version_date cpc_sumbol_position cpc_class_value_code cpc_set_group_number cpc_set_rank_number;
RUN;


DATA cpc_appl_data_2 ;
  SET cpc_appl_data_1;
  subgroup_ = substr(cat(subgroup), 1, 4);
  subgroup_1 = input(subgroup_, BEST12.);
  drop subgroup_ subgroup;
RUN;


/* Classification is from: */
/* http://www.oecd.org/environment/consumption-innovation/ENV-tech%20search%20strategies,%20version%20for%20OECDstat%20(2016).pdf*/ 
DATA cpc_appl_data_3 ;
  SET cpc_appl_data_2;
  /*1.1.1*/
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1>=34 AND subgroup_1<=72 then green=1;
  if section="F" AND ipc_class=23 AND subclass="G" AND  main_group=7 AND subgroup_1=6 then green=1;
  if section="F" AND ipc_class=23 AND subclass="J" AND  main_group=15 then green=1;
  if section="F" AND ipc_class=27 AND subclass="B" AND  main_group=1 AND subgroup_1=18 then green=1;
  if section="C" AND ipc_class=21 AND subclass="B" AND  main_group=7 AND subgroup_1=22 then green=1;
  if section="C" AND ipc_class=21 AND subclass="C" AND  main_group=5 AND subgroup_1=38 then green=1;
  if section="F" AND ipc_class=23 AND subclass="B" AND  main_group=80 then green=1;
  if section="F" AND ipc_class=23 AND subclass="C" AND  main_group=9 then green=1;
  if section="F" AND ipc_class=23 AND subclass="C" AND  main_group=10 then green=1;
  /*1.1.2*/
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1=92 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1=94 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1=96 then green=1;
  if section="B" AND ipc_class=1 AND subclass="J" AND  main_group=23 AND subgroup_1>=38 AND subgroup_1<=46 then green=1;
  if section="F" AND ipc_class=1 AND subclass="M" AND  main_group=13 AND subgroup_1>=2 AND subgroup_1<=4 then green=1;
  if section="F" AND ipc_class=2 AND subclass="B" AND  main_group=47 AND subgroup_1>=8 AND subgroup_1<=10 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=21 AND subgroup_1>=6 AND subgroup_1<=10 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=25 AND subgroup_1=7 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=15 AND subgroup_1=10 then green=1;

  if section="F" AND ipc_class=2 AND subclass="B" AND  main_group=47 AND subgroup_1=6 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=41 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=43 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=45 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=3 AND subgroup_1>=2 AND subgroup_1<=55 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=23 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=25 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=27 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=31 AND subgroup_1>=2 AND subgroup_1<=18 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND main_group>=39 AND main_group<=71 then green=1;
  if section="F" AND ipc_class=2 AND subclass="P" AND  main_group=5 then green=1;
  /*1.1.3*/
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=46 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=47 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=49 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=50 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=51 then green=1;
  if section="B" AND ipc_class=3 AND subclass="C" AND  main_group=3 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=3 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=5 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=7 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=13 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=9 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=11 then green=1;
  if section="C" AND ipc_class=10 AND subclass="L" AND  main_group=10 AND subgroup_1=2 then green=1;
  if section="C" AND ipc_class=10 AND subclass="L" AND  main_group=10 AND subgroup_1=6 then green=1;

  /*1.2.1*/
  if section="B" AND ipc_class=63 AND subclass="J" AND  main_group=4 then green=1;
  if section="C" AND ipc_class=2 AND subclass="F" then green=1;
  if section="C" AND ipc_class=9 AND subclass="K" AND  main_group=3 AND subgroup_1=32 then green=1;
  if section="E" AND ipc_class=3 AND subclass="C" AND  main_group=1 AND subgroup_1=12 then green=1;
  if section="E" AND ipc_class=3 AND subclass="F" then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=7 then green=1;
  if section="E" AND ipc_class=2 AND subclass="B" AND  main_group=15 AND subgroup_1>=4 AND subgroup_1<=10 then green=1;
  if section="B" AND ipc_class=63 AND subclass="B" AND  main_group=35 AND subgroup_1=32 then green=1;
  if section="C" AND ipc_class=9 AND subclass="K" AND  main_group=3 AND subgroup_1=32 then green=1;

  /*1.3.1*/
  if section="E" AND ipc_class=1 AND subclass="H" AND  main_group=15 then green=1;
  if section="B" AND ipc_class=65 AND subclass="F" then green=1;
  /*1.3.2*/
  if section="A" AND ipc_class=23 AND subclass="K" AND  main_group=1 AND subgroup_1>=6 AND subgroup_1<=10 then green=1;
  if section="A" AND ipc_class=43 AND subclass="B" AND  main_group=1 AND subgroup_1=12 then green=1;
  if section="A" AND ipc_class=43 AND subclass="B" AND  main_group=21 AND subgroup_1=14 then green=1;
  if section="B" AND ipc_class=3 AND subclass="B" AND  main_group=9 AND subgroup_1=6 then green=1;
  if section="B" AND ipc_class=22 AND subclass="F" AND  main_group=8 then green=1;
  if section="B" AND ipc_class=29 AND subclass="B" AND  main_group=7 AND subgroup_1=66 then green=1;
  if section="B" AND ipc_class=29 AND subclass="B" AND  main_group=17 then green=1;
  if section="B" AND ipc_class=30 AND subclass="B" AND  main_group=9 AND subgroup_1=32 then green=1;
  if section="B" AND ipc_class=62 AND subclass="D" AND  main_group=67 then green=1;
  if section="B" AND ipc_class=65 AND subclass="H" AND  main_group=73 then green=1;
  if section="B" AND ipc_class=65 AND subclass="D" AND  main_group=65 AND subgroup_1=46 then green=1;
  if section="C" AND ipc_class=3 AND subclass="B" AND  main_group=1 AND subgroup_1=2 then green=1;
  if section="C" AND ipc_class=3 AND subclass="C" AND  main_group=6 AND subgroup_1=2 then green=1;
  if section="C" AND ipc_class=3 AND subclass="C" AND  main_group=6 AND subgroup_1=8 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=7 AND subgroup_1>=24 AND subgroup_1<=30 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=11 AND subgroup_1=26 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=18 AND subgroup_1>=4 AND subgroup_1<=10 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=33 AND subgroup_1=132 then green=1;
  if section="C" AND ipc_class=8 AND subclass="J" AND  main_group=11 then green=1;
  if section="C" AND ipc_class=9 AND subclass="K" AND  main_group=11 AND subgroup_1=1 then green=1;
  if section="C" AND ipc_class=10 AND subclass="M" AND  main_group=175 then green=1;
  if section="C" AND ipc_class=22 AND subclass="B" AND  main_group=7 then green=1;
  if section="C" AND ipc_class=22 AND subclass="B" AND  main_group=19 AND subgroup_1>=28 AND subgroup_1<=30 then green=1;
  if section="C" AND ipc_class=22 AND subclass="B" AND  main_group=25 AND subgroup_1=6 then green=1;
  if section="D" AND ipc_class=1 AND subclass="G" AND  main_group=11 then green=1;
  if section="D" AND ipc_class=21 AND subclass="B" AND  main_group=19 AND subgroup_1>=8 AND subgroup_1<=10 then green=1;
  if section="D" AND ipc_class=21 AND subclass="B" AND  main_group=19 AND subgroup_1=32 then green=1;
  if section="D" AND ipc_class=21 AND subclass="C" AND  main_group=5 AND subgroup_1=2 then green=1;
  if section="D" AND ipc_class=21 AND subclass="H" AND  main_group=17 AND subgroup_1=1 then green=1;
  if section="H" AND ipc_class=1 AND subclass="B" AND  main_group=15 then green=1;
  if section="H" AND ipc_class=1 AND subclass="J" AND  main_group=9 AND subgroup_1=52 then green=1;
  if section="H" AND ipc_class=1 AND subclass="M" AND  main_group=6 AND subgroup_1=52 then green=1;
  if section="H" AND ipc_class=1 AND subclass="M" AND  main_group=6 AND subgroup_1=54 then green=1;
  /*1.3.3*/
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=1 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=5 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=7 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=9 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=17 then green=1;
  /*1.3.4*/
  if section="C" AND ipc_class=10 AND subclass="L" AND  main_group=5 AND subgroup_1>=46 AND subgroup_1<=48 then green=1;
  if section="F" AND ipc_class=23 AND subclass="G" AND  main_group=5 then green=1;
  if section="F" AND ipc_class=23 AND subclass="G" AND  main_group=7 then green=1;
  /*1.3.6*/
  if section="B" AND ipc_class=9 AND subclass="B" then green=1;
  if section="C" AND ipc_class=10 AND subclass="G" AND  main_group=1 AND subgroup_1=10 then green=1;
  if section="A" AND ipc_class=61 AND subclass="L" AND  main_group=11 then green=1;

  /*1.4.1*/
  if section="B" AND ipc_class=9 AND subclass="C" then green=1;

  /*1.5*/
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=11 then green=1;
  if section="G" AND ipc_class=8 AND subclass="B" AND  main_group=21 AND subgroup_1>=12 AND subgroup_1<=14 then green=1;

  /*2.1.1*/
  if section="F" AND ipc_class=16 AND subclass="K" AND  main_group=21 AND subgroup_1>=6 AND subgroup_1<=12 then green=1;
  if section="F" AND ipc_class=16 AND subclass="K" AND  main_group=21 AND subgroup_1>=16 AND subgroup_1<=20 then green=1;
  if section="F" AND ipc_class=16 AND subclass="L" AND  main_group=55 AND subgroup_1=7 then green=1;
  if section="E" AND ipc_class=3 AND subclass="C" AND  main_group=1 AND subgroup_1=84 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=3 AND subgroup_1=12 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=3 AND subgroup_1=14 then green=1;
  if section="A" AND ipc_class=47 AND subclass="K" AND  main_group=11 AND subgroup_1=12 then green=1;
  if section="A" AND ipc_class=47 AND subclass="K" AND  main_group=11 AND subgroup_1=2 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=13 AND subgroup_1=7 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=5 AND subgroup_1=16 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=1 AND subgroup_1=41 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="B" AND  main_group=40 AND subgroup_1=46 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="B" AND  main_group=40 AND subgroup_1=56 then green=1;
  /*2.1.2*/
  if section="A" AND ipc_class=1 AND subclass="G" AND  main_group=25 AND subgroup_1=2 then green=1;
  if section="A" AND ipc_class=1 AND subclass="G" AND  main_group=25 AND subgroup_1=6 then green=1;
  if section="A" AND ipc_class=1 AND subclass="G" AND  main_group=25 AND subgroup_1=16 then green=1;
  if section="C" AND ipc_class=12 AND subclass="N" AND  main_group=15 AND subgroup_1=8273 then green=1;
  /*2.1.3*/
  if section="F" AND ipc_class=1 AND subclass="K" AND  main_group=23 AND subgroup_1>=8 AND subgroup_1<=10 then green=1;
  if section="F" AND ipc_class=1 AND subclass="D" AND  main_group=11  then green=1;
  /*2.1.4*/
  if section="F" AND ipc_class=17 AND subclass="D" AND  main_group=5 AND subgroup_1=2 then green=1;
  if section="F" AND ipc_class=16 AND subclass="L" AND  main_group=55 AND subgroup_1=16 then green=1;
  if section="E" AND ipc_class=3 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=8 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=14 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=18 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=22 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=28 then green=1;

  /*2.2.1*/
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=5 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1>=6 AND subgroup_1<=26 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=9 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1>=28 AND subgroup_1<=38 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=4 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=2 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=3 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=40 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=11 then green=1;

  /*4.1*/
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=10 AND subgroup_1>=70 AND subgroup_1<=766 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=10 AND subgroup_1>=40 AND subgroup_1<=47 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=10 AND subgroup_1>=50 AND subgroup_1<=58 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=50 AND subgroup_1>=10 AND subgroup_1<=18 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=50 AND subgroup_1>=30 AND subgroup_1<=346 then green=1;

  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=20 AND subgroup_1>=10 AND subgroup_1<=366 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=30 AND subgroup_1>=10 AND subgroup_1<=18 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=30 AND subgroup_1>=30 AND subgroup_1<=40 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=60 AND subgroup_1<=69 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=10 AND subgroup_1<=18 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=20 AND subgroup_1<=26 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=30 AND subgroup_1<=34 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1=40 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1=50 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1=70 then green=1;

  /*4.6*/
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1>=10 AND subgroup_1<=17 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1>=30 AND subgroup_1<=566 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1=70 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1>=70 AND subgroup_1<=7892 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=70 then green=1;

  /*5*/
  if section="Y" AND ipc_class=2 AND subclass="C" AND  main_group=10 AND subgroup_1>=0 AND subgroup_1<=14 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="C" AND  main_group=20 AND subgroup_1>=0 AND subgroup_1<=30 then green=1;

  /*6*/
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=10 AND subgroup_1>=10 AND subgroup_1<=56 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=10 AND subgroup_1>=62 AND subgroup_1<=7094 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=10 AND subgroup_1=62 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=30 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=50 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=70 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=90 then green=1;

  /*7*/
  if section="Y" AND ipc_class=2 AND subclass="B" then green=1;
  /*8*/
  if section="Y" AND ipc_class=2 AND subclass="W" then green=1;
  /*9*/
  if section="Y" AND ipc_class=2 AND subclass="P" then green=1;

RUN;


/* keep only green applications now (unlike IPC data, CPC data is for both aplications and granted patents, and does not need extrapolation)*/
DATA cpc_appl_data_4 ;
  SET cpc_appl_data_3;
  if green=1;
  rename green = green_cpc;
RUN;


/* try the initial patent applicaiton data instead to have USPC subclass*/
PROC IMPORT OUT= WORK.app_data (keep= application_number patent_number uspc_class uspc_subclass) 
DATAFILE= "R:\ps664\Patent Examiner Data\2019 data\application_data.csv" 
            DBMS=csv REPLACE;
     GETNAMES=YES;
RUN;


DATA app_data_2 (keep = application_number patent_number uspc_class uspc_subclass);
  SET app_data;
RUN;


/* merge CPC data to applications data on application number*/
PROC SQL;
	CREATE TABLE merge_first AS
	SELECT *
	FROM app_data   AS l LEFT JOIN cpc_appl_data_4 AS r
	ON	l.application_number = r.application_number;
QUIT;

DATA merge_first_ ;
  SET merge_first;
  if not missing(application_number); 
RUN;

DATA merge_first_1 ;
  SET merge_first_;
  rename  section = cpc_section;
  rename  ipc_class = cpc_class;
  rename subclass = cpc_subclass;
  rename main_group = cpc_main_group;
  rename subgroup = cpc_subgroup;
RUN;


   /* DO THE SAME EXERCISE WITH IPC CODES - IDENTIF GREEN WITH IPC CODES*/

/* Match data from Python back */

/*
PROC IMPORT	DATAFILE= 'R:\ps664\Data\PatentViews - patent text\ipcr.csv'	DBMS=csv
	OUT=ipc_1 (keep = patent_id classification_level section  ipc_class subclass main_group subgroup)	REPLACE; RUN;
*/
	/* OR*/

  data WORK.IPC_1    ;
  %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
  infile 'R:\ps664\Patent Examiner Data\IPC data from PatentViews\ipcr.csv' delimiter =
',' MISSOVER DSD lrecl=32767 firstobs=2 ;
     informat uuid $25. ;
     informat patent_id best32. ;
     informat classification_level $10. ;
     informat section $10. ;
     informat ipc_class best32. ;
     informat subclass $10. ;
     informat main_group best32. ;
     informat subgroup best32. ;
     informat symbol_position $1. ;
     informat classification_value $1. ;
     informat classification_status $1. ;
     informat classification_data_source $1. ;
     informat action_date $1. ;
     informat ipc_version_indicator $1. ;
     informat sequence best32. ;
     format uuid $25. ;
     format patent_id best12. ;
     format classification_level $1. ;
     format section $1. ;
     format ipc_class best12. ;
     format subclass $1. ;
     format main_group best12. ;
     format subgroup best12. ;
     format symbol_position $1. ;
     format classification_value $1. ;
     format classification_status $1. ;
     format classification_data_source $1. ;
     format action_date $1. ;
     format ipc_version_indicator $1. ;
     format sequence best12. ;
  input
              uuid  $
              patent_id
              classification_level  $
              section  $
              ipc_class
              subclass  $
              main_group
              subgroup
              symbol_position  $
              classification_value  $
              classification_status  $
              classification_data_source  $
              action_date  $
              ipc_version_indicator  $
              sequence
  ;
  if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
  run;

DATA merge_first_2 (drop = patent_number);
  SET merge_first_1;
  patent_num = input(patent_number, best12.);
RUN;

/* Mark a list of green patents from */
DATA ipc_full ;
  SET ipc_1;
  subgroup_=tranwrd(subgroup, "/", "");
  subgroup_1 = input(subgroup_, best12.);
  subgroup_1 = input(subgroup_, best12.);
  if not missing(patent_id);
drop subgroup_ subgroup ;
RUN;



/* Classification is from: */
/* http://www.oecd.org/environment/consumption-innovation/ENV-tech%20search%20strategies,%20version%20for%20OECDstat%20(2016).pdf*/ 
DATA ipc_full_1 ;
  SET ipc_full;
  /*1.1.1*/
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1>=34 AND subgroup_1<=72 then green=1;
  if section="F" AND ipc_class=23 AND subclass="G" AND  main_group=7 AND subgroup_1=6 then green=1;
  if section="F" AND ipc_class=23 AND subclass="J" AND  main_group=15 then green=1;
  if section="F" AND ipc_class=27 AND subclass="B" AND  main_group=1 AND subgroup_1=18 then green=1;
  if section="C" AND ipc_class=21 AND subclass="B" AND  main_group=7 AND subgroup_1=22 then green=1;
  if section="C" AND ipc_class=21 AND subclass="C" AND  main_group=5 AND subgroup_1=38 then green=1;
  if section="F" AND ipc_class=23 AND subclass="B" AND  main_group=80 then green=1;
  if section="F" AND ipc_class=23 AND subclass="C" AND  main_group=9 then green=1;
  if section="F" AND ipc_class=23 AND subclass="C" AND  main_group=10 then green=1;
  /*1.1.2*/
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1=92 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1=94 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=53 AND subgroup_1=96 then green=1;
  if section="B" AND ipc_class=1 AND subclass="J" AND  main_group=23 AND subgroup_1>=38 AND subgroup_1<=46 then green=1;
  if section="F" AND ipc_class=1 AND subclass="M" AND  main_group=13 AND subgroup_1>=2 AND subgroup_1<=4 then green=1;
  if section="F" AND ipc_class=2 AND subclass="B" AND  main_group=47 AND subgroup_1>=8 AND subgroup_1<=10 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=21 AND subgroup_1>=6 AND subgroup_1<=10 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=25 AND subgroup_1=7 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=15 AND subgroup_1=10 then green=1;

  if section="F" AND ipc_class=2 AND subclass="B" AND  main_group=47 AND subgroup_1=6 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=41 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=43 then green=1;
  if section="F" AND ipc_class=2 AND subclass="D" AND  main_group=45 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=3 AND subgroup_1>=2 AND subgroup_1<=55 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=23 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=25 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=27 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND  main_group=31 AND subgroup_1>=2 AND subgroup_1<=18 then green=1;
  if section="F" AND ipc_class=2 AND subclass="M" AND main_group>=39 AND main_group<=71 then green=1;
  if section="F" AND ipc_class=2 AND subclass="P" AND  main_group=5 then green=1;
  /*1.1.3*/
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=46 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=47 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=49 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=50 then green=1;
  if section="B" AND ipc_class=1 AND subclass="D" AND  main_group=51 then green=1;
  if section="B" AND ipc_class=3 AND subclass="C" AND  main_group=3 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=3 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=5 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=7 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=13 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=9 then green=1;
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=11 then green=1;
  if section="C" AND ipc_class=10 AND subclass="L" AND  main_group=10 AND subgroup_1=2 then green=1;
  if section="C" AND ipc_class=10 AND subclass="L" AND  main_group=10 AND subgroup_1=6 then green=1;

  /*1.2.1*/
  if section="B" AND ipc_class=63 AND subclass="J" AND  main_group=4 then green=1;
  if section="C" AND ipc_class=2 AND subclass="F" then green=1;
  if section="C" AND ipc_class=9 AND subclass="K" AND  main_group=3 AND subgroup_1=32 then green=1;
  if section="E" AND ipc_class=3 AND subclass="C" AND  main_group=1 AND subgroup_1=12 then green=1;
  if section="E" AND ipc_class=3 AND subclass="F" then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=7 then green=1;
  if section="E" AND ipc_class=2 AND subclass="B" AND  main_group=15 AND subgroup_1>=4 AND subgroup_1<=10 then green=1;
  if section="B" AND ipc_class=63 AND subclass="B" AND  main_group=35 AND subgroup_1=32 then green=1;
  if section="C" AND ipc_class=9 AND subclass="K" AND  main_group=3 AND subgroup_1=32 then green=1;

  /*1.3.1*/
  if section="E" AND ipc_class=1 AND subclass="H" AND  main_group=15 then green=1;
  if section="B" AND ipc_class=65 AND subclass="F" then green=1;
  /*1.3.2*/
  if section="A" AND ipc_class=23 AND subclass="K" AND  main_group=1 AND subgroup_1>=6 AND subgroup_1<=10 then green=1;
  if section="A" AND ipc_class=43 AND subclass="B" AND  main_group=1 AND subgroup_1=12 then green=1;
  if section="A" AND ipc_class=43 AND subclass="B" AND  main_group=21 AND subgroup_1=14 then green=1;
  if section="B" AND ipc_class=3 AND subclass="B" AND  main_group=9 AND subgroup_1=6 then green=1;
  if section="B" AND ipc_class=22 AND subclass="F" AND  main_group=8 then green=1;
  if section="B" AND ipc_class=29 AND subclass="B" AND  main_group=7 AND subgroup_1=66 then green=1;
  if section="B" AND ipc_class=29 AND subclass="B" AND  main_group=17 then green=1;
  if section="B" AND ipc_class=30 AND subclass="B" AND  main_group=9 AND subgroup_1=32 then green=1;
  if section="B" AND ipc_class=62 AND subclass="D" AND  main_group=67 then green=1;
  if section="B" AND ipc_class=65 AND subclass="H" AND  main_group=73 then green=1;
  if section="B" AND ipc_class=65 AND subclass="D" AND  main_group=65 AND subgroup_1=46 then green=1;
  if section="C" AND ipc_class=3 AND subclass="B" AND  main_group=1 AND subgroup_1=2 then green=1;
  if section="C" AND ipc_class=3 AND subclass="C" AND  main_group=6 AND subgroup_1=2 then green=1;
  if section="C" AND ipc_class=3 AND subclass="C" AND  main_group=6 AND subgroup_1=8 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=7 AND subgroup_1>=24 AND subgroup_1<=30 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=11 AND subgroup_1=26 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=18 AND subgroup_1>=4 AND subgroup_1<=10 then green=1;
  if section="C" AND ipc_class=4 AND subclass="B" AND  main_group=33 AND subgroup_1=132 then green=1;
  if section="C" AND ipc_class=8 AND subclass="J" AND  main_group=11 then green=1;
  if section="C" AND ipc_class=9 AND subclass="K" AND  main_group=11 AND subgroup_1=1 then green=1;
  if section="C" AND ipc_class=10 AND subclass="M" AND  main_group=175 then green=1;
  if section="C" AND ipc_class=22 AND subclass="B" AND  main_group=7 then green=1;
  if section="C" AND ipc_class=22 AND subclass="B" AND  main_group=19 AND subgroup_1>=28 AND subgroup_1<=30 then green=1;
  if section="C" AND ipc_class=22 AND subclass="B" AND  main_group=25 AND subgroup_1=6 then green=1;
  if section="D" AND ipc_class=1 AND subclass="G" AND  main_group=11 then green=1;
  if section="D" AND ipc_class=21 AND subclass="B" AND  main_group=19 AND subgroup_1>=8 AND subgroup_1<=10 then green=1;
  if section="D" AND ipc_class=21 AND subclass="B" AND  main_group=19 AND subgroup_1=32 then green=1;
  if section="D" AND ipc_class=21 AND subclass="C" AND  main_group=5 AND subgroup_1=2 then green=1;
  if section="D" AND ipc_class=21 AND subclass="H" AND  main_group=17 AND subgroup_1=1 then green=1;
  if section="H" AND ipc_class=1 AND subclass="B" AND  main_group=15 then green=1;
  if section="H" AND ipc_class=1 AND subclass="J" AND  main_group=9 AND subgroup_1=52 then green=1;
  if section="H" AND ipc_class=1 AND subclass="M" AND  main_group=6 AND subgroup_1=52 then green=1;
  if section="H" AND ipc_class=1 AND subclass="M" AND  main_group=6 AND subgroup_1=54 then green=1;
  /*1.3.3*/
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=1 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=5 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=7 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=9 then green=1;
  if section="C" AND ipc_class=5 AND subclass="F" AND  main_group=17 then green=1;
  /*1.3.4*/
  if section="C" AND ipc_class=10 AND subclass="L" AND  main_group=5 AND subgroup_1>=46 AND subgroup_1<=48 then green=1;
  if section="F" AND ipc_class=23 AND subclass="G" AND  main_group=5 then green=1;
  if section="F" AND ipc_class=23 AND subclass="G" AND  main_group=7 then green=1;
  /*1.3.6*/
  if section="B" AND ipc_class=9 AND subclass="B" then green=1;
  if section="C" AND ipc_class=10 AND subclass="G" AND  main_group=1 AND subgroup_1=10 then green=1;
  if section="A" AND ipc_class=61 AND subclass="L" AND  main_group=11 then green=1;

  /*1.4.1*/
  if section="B" AND ipc_class=9 AND subclass="C" then green=1;

  /*1.5*/
  if section="F" AND ipc_class=1 AND subclass="N" AND  main_group=11 then green=1;
  if section="G" AND ipc_class=8 AND subclass="B" AND  main_group=21 AND subgroup_1>=12 AND subgroup_1<=14 then green=1;

  /*2.1.1*/
  if section="F" AND ipc_class=16 AND subclass="K" AND  main_group=21 AND subgroup_1>=6 AND subgroup_1<=12 then green=1;
  if section="F" AND ipc_class=16 AND subclass="K" AND  main_group=21 AND subgroup_1>=16 AND subgroup_1<=20 then green=1;
  if section="F" AND ipc_class=16 AND subclass="L" AND  main_group=55 AND subgroup_1=7 then green=1;
  if section="E" AND ipc_class=3 AND subclass="C" AND  main_group=1 AND subgroup_1=84 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=3 AND subgroup_1=12 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=3 AND subgroup_1=14 then green=1;
  if section="A" AND ipc_class=47 AND subclass="K" AND  main_group=11 AND subgroup_1=12 then green=1;
  if section="A" AND ipc_class=47 AND subclass="K" AND  main_group=11 AND subgroup_1=2 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=13 AND subgroup_1=7 then green=1;
  if section="E" AND ipc_class=3 AND subclass="D" AND  main_group=5 AND subgroup_1=16 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=1 AND subgroup_1=41 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="B" AND  main_group=40 AND subgroup_1=46 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="B" AND  main_group=40 AND subgroup_1=56 then green=1;
  /*2.1.2*/
  if section="A" AND ipc_class=1 AND subclass="G" AND  main_group=25 AND subgroup_1=2 then green=1;
  if section="A" AND ipc_class=1 AND subclass="G" AND  main_group=25 AND subgroup_1=6 then green=1;
  if section="A" AND ipc_class=1 AND subclass="G" AND  main_group=25 AND subgroup_1=16 then green=1;
  if section="C" AND ipc_class=12 AND subclass="N" AND  main_group=15 AND subgroup_1=8273 then green=1;
  /*2.1.3*/
  if section="F" AND ipc_class=1 AND subclass="K" AND  main_group=23 AND subgroup_1>=8 AND subgroup_1<=10 then green=1;
  if section="F" AND ipc_class=1 AND subclass="D" AND  main_group=11  then green=1;
  /*2.1.4*/
  if section="F" AND ipc_class=17 AND subclass="D" AND  main_group=5 AND subgroup_1=2 then green=1;
  if section="F" AND ipc_class=16 AND subclass="L" AND  main_group=55 AND subgroup_1=16 then green=1;
  if section="E" AND ipc_class=3 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=8 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=14 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=18 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=22 then green=1;
  if section="G" AND ipc_class=1 AND subclass="M" AND  main_group=3 AND subgroup_1=28 then green=1;

  /*2.2.1*/
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=5 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1>=6 AND subgroup_1<=26 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=9 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1>=28 AND subgroup_1<=38 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=4 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=2 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=3 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=3 AND subgroup_1=40 then green=1;
  if section="E" AND ipc_class=3 AND subclass="B" AND  main_group=11 then green=1;

  /*4.1*/
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=10 AND subgroup_1>=70 AND subgroup_1<=766 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=10 AND subgroup_1>=40 AND subgroup_1<=47 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=10 AND subgroup_1>=50 AND subgroup_1<=58 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=50 AND subgroup_1>=10 AND subgroup_1<=18 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=50 AND subgroup_1>=30 AND subgroup_1<=346 then green=1;

  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=20 AND subgroup_1>=10 AND subgroup_1<=366 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=30 AND subgroup_1>=10 AND subgroup_1<=18 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=30 AND subgroup_1>=30 AND subgroup_1<=40 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=60 AND subgroup_1<=69 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=10 AND subgroup_1<=18 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=20 AND subgroup_1<=26 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1>=30 AND subgroup_1<=34 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1=40 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1=50 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=40 AND subgroup_1=70 then green=1;

  /*4.6*/
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1>=10 AND subgroup_1<=17 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1>=30 AND subgroup_1<=566 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1=70 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=60 AND subgroup_1>=70 AND subgroup_1<=7892 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="E" AND  main_group=70 then green=1;

  /*5*/
  if section="Y" AND ipc_class=2 AND subclass="C" AND  main_group=10 AND subgroup_1>=0 AND subgroup_1<=14 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="C" AND  main_group=20 AND subgroup_1>=0 AND subgroup_1<=30 then green=1;

  /*6*/
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=10 AND subgroup_1>=10 AND subgroup_1<=56 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=10 AND subgroup_1>=62 AND subgroup_1<=7094 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=10 AND subgroup_1=62 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=30 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=50 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=70 then green=1;
  if section="Y" AND ipc_class=2 AND subclass="T" AND  main_group=90 then green=1;

  /*7*/
  if section="Y" AND ipc_class=2 AND subclass="B" then green=1;
  /*8*/
  if section="Y" AND ipc_class=2 AND subclass="W" then green=1;
  /*9*/
  if section="Y" AND ipc_class=2 AND subclass="P" then green=1;

RUN;

/* !!! sas says insufficient space for this merge*/
PROC SQL;
	CREATE TABLE merge_second AS
	SELECT *
	FROM merge_first_2  AS l LEFT JOIN ipc_full_1 AS r
	ON	l.patent_num = r.patent_id;
QUIT;

/* Export data on IPC and CPC codes to Stata (to check how CPC and IPC are consistent with each other)*/
/*
PROC EXPORT 	DATA=merge_second	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\More Data\applic_cpc_ipc_classes.dta'	REPLACE; RUN;
*/

/* keep only patent application, patent number and green_cpc and green_ipc*/
DATA green_pat (keep = application_number patent_num green_cpc green);
  SET merge_second;
  if missing(green_cpc) then green_cpc=0;
  if missing(green) then green=0;
RUN;

/* mark applications as green if at least 1 class is green*/
proc sort data = green_pat out =  green_pat_1 ; by application_number patent_num descending  green_cpc descending green; run;
proc sort nodupkey data = green_pat out =  green_pat_1 ; by application_number patent_num descending  green_cpc descending green; run;

DATA green_pat_2 ;
  SET green_pat_1;
  if green_cpc=1 | green=1;
  rename application_number = application_n;
RUN;


/* merge back a list of green patents and patent applications to companies' patents data-set*/
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

DATA full_application_data ;
  SET comp.full_application_data;
  rename fyear=year;
RUN;

PROC SQL;
	CREATE TABLE full_applic_green AS
	SELECT *
	FROM full_application_data  AS l LEFT JOIN green_pat_2 AS r
	ON	l.application_number = r.application_n;
QUIT;

/* Export all patent applications with a green dummy */
PROC EXPORT 	DATA=full_applic_green	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\full_applic_green.dta'	REPLACE; RUN;

PROC EXPORT 	DATA=full_applic_green	DBMS=csv
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\full_applic_green.csv'	REPLACE; RUN;
DATA comp.full_applic_green ;
  SET full_applic_green;
RUN;

/*/////////////////////////// END OF GREEN DUMMY CODE /////////////////////////////*/




				/* Summary Stats tables - Patent Applications */

/* Add CRSP-Compustat financial data to application data*/
LIBNAME comp 'R:\ps664\Patent Applications - Michelle Michela';

DATA full_applic_green ;
  SET comp.full_applic_green;
  rename fyear=year;
RUN;

RSUBMIT;
/*Extract data from Compustat FUNDA master file*/
DATA funda1 (DROP = indfmt consol popsrc datafmt cshpri);
	SET comp.funda (KEEP =  conm gvkey DLTT DLC LCT LT EMOL  datadate csho  ceq teq prcc_c fyear BKVLPS oiadp sich sic:  gp rect invt aco ppent intan ao ap lco lo indfmt consol popsrc datafmt ni at oibdp capx prcc_f cshpri FIC naicsh sale XRD XRDP ACQINTAN AQC BKVLPS CH DVPD DVPSP_F EBITDA EMP EPSFI FIC NITS OPITI PPEGT REVT);
	WHERE fyear <= 2021;
	IF indfmt='INDL' AND consol='C' AND popsrc='D' AND datafmt='STD';
	mkt_value = prcc_f*cshpri;
RUN;
PROC DOWNLOAD DATA=funda1 OUT=funda1;
RUN;
ENDRSUBMIT;


/* Get permno from CRSP + merge with Compustat */
RSUBMIT;
%MACRO CCM (INSET=,DATEVAR=DATADATE,OUTSET=,LINKTYPE=LULC,REMDUPS=1,OVERLAP=0);
 
/* Check Validity of CCM Library Assignment */
%if (%sysfunc(libref(CCM))) %then %do; libname CCM ("/wrds/crsp/sasdata/q_ccm/"); %end;
%if (%sysfunc(libref(CCM))) %then %do; libname CCM ("/wrds/crsp/sasdata/a_ccm/") ; %end;
%put; %put ### START. ;
 
/* Convert the overlap distance into months */
%let overlap=%sysevalf(12*&overlap.);
 
options nonotes;
/* Make sure first that the input dataset has no duplicates by GVKEY-&DATEVAR */
proc sort data=&INSET out=_ccm0 nodupkey; by GVKEY &DATEVAR; run;
 
/* Add Permno to Compustat sample */
proc sql;
create table _ccm1 as
select distinct b.lpermno as PERMNO " ", a.*, b.linkprim, b.linkdt
from _ccm0 as a, crsp.ccmxpf_linktable as b
where a.gvkey=b.gvkey and index("&linktype.",strip(b.linktype))>0
and (a.&datevar>= intnx("month",b.linkdt   ,-&overlap.,"b") or missing(b.linkdt)   )
and (a.&datevar<= intnx("month",b.linkenddt, &overlap.,"e") or missing(b.linkenddt));
quit;
proc sort data=_ccm1;
  by &datevar permno descending linkprim descending linkdt gvkey;
run;
 
/* it ties in the linkprim, then use most recent link or keep all */
data _ccm2;
set _ccm1;
by &datevar permno descending linkprim descending linkdt gvkey;
if first.permno;
%if &REMDUPS=0 %then %do; drop linkprim linkdt; %end;
run;
  
%if &REMDUPS=1 %then
 %do;
   proc sort data=_ccm2; by &datevar gvkey descending linkprim descending linkdt;
   data _ccm2;
   set _ccm2;
   by &datevar gvkey descending linkprim descending linkdt;
   if first.gvkey;
   drop linkprim linkdt;
   run;
   %put ## Removed Multiple PERMNO Matches per GVKEY ;
 %end;
 
/* Sanity Check -- No Duplicates -- and Save Output Dataset */
proc sort data=_ccm2 out=&OUTSET nodupkey; by gvkey &datevar permno; run;
%put ## &OUTSET Linked Table Created;
 
/* House Cleaning */
proc sql;
 drop table _ccm0, _ccm1, _ccm2;
quit;
 
%put ### DONE . ; %put ;
options notes;
%MEND CCM;

%CCM(INSET=funda1,DATEVAR=datadate,OUTSET=ccm1,LINKTYPE=LULC,REMDUPS=1,OVERLAP=0);
/*Extract dataset from WRDS*/
PROC DOWNLOAD DATA=ccm1 OUT=ccm1;
RUN;
ENDRSUBMIT;
/* ********************************************************************************* */

data funda1_1 ;
set ccm1;
gvkey_1 = input(gvkey, best12.);
drop gvkey ;
rename conm=crsp_comp_name;
k_datatdate = datadate - 365;
run;

proc sort nodupkey data = funda1_1   out =  funda1_1 ; by gvkey_1 fyear; run;

data funda1_1 (drop = k_datatdate);
set funda1_1;
by gvkey_1 fyear;
if first.gvkey_1 then age=0;
if first.fyear then age + 1;
if fyear>=1999 ;
format this_datatdate YYMMDD10.;
format l_datatdate YYMMDD10.;
informat this_datatdate YYMMDD10.;
informat l_datatdate YYMMDD10.;

this_datatdate =  input(put(datadate, YYMMDD10.),YYMMDD10.);
l_datatdate =  input(put(k_datatdate,YYMMDD10.),YYMMDD10.);
run;

PROC SQL;
	CREATE TABLE appl_stats AS
	SELECT *
	FROM funda1_1  AS l LEFT JOIN full_applic_green AS r
	/*ON	l.gvkey_1 = r.gvkey AND l.fyear = r.year;*/
	ON l.gvkey_1 = r.gvkey AND r.filing_date>l.l_datatdate AND r.filing_date<l.this_datatdate;
QUIT;


data appl_stats ;
set appl_stats;
drop gvkey year;
rename gvkey_1=gvkey;
run;

proc sort nodupkey data = appl_stats   out =  appl_stats ; by gvkey fyear application_number; run;

/* Export data to Stata (!! THIS DATA IS NOT A COMPLETE PYTHON SEARCH)*/
PROC EXPORT 	DATA=appl_stats	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\appl_stats.dta'	REPLACE; RUN;








/* ************************** Lobbying Data and CRSP-Compustat ****************************** */

       data WORK.LOBBY    ;
       %let _EFIERR_ = 0; /* set the ERROR detection macro variable */
       infile 'R:\ps664\Data\Lobbying Data\lobbying_data.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
          informat VAR1 best32. ;
          informat ID $36. ;
          informat Year best32. ;
          informat Received anydtdtm40. ;
          informat Amount best32. ;
          informat Type $32. ;
          informat Period $26. ;
          informat RegistrantID best32. ;
          informat RegistrantName $54. ;
          informat GeneralDescription $47. ;
          informat Address $60. ;
          informat RegistrantCountry $3. ;
          informat RegistrantPPBCountry $3. ;
          informat VAR14 $60. ;
          informat ClientName $54. ;
          informat VAR16 $1. ;
          informat ClientID best32. ;
          informat SelfFiler $5. ;
          informat ContactFullname $21. ;
          informat IsStateOrLocalGov $5. ;
          informat ClientCountry $6. ;
          informat ClientPPBCountry $6. ;
          informat ClientState $20. ;
          informat ClientPPBState $20. ;
          informat LobbyistName $31. ;
          informat LobbyistCoveredGovPositionIndica $7. ;
          informat OfficialPosition $3. ;
          informat Code $33. ;
		  informat SpecificIssue $1. ;
          informat AffiliatedOrgName $1. ;
          informat AffiliatedOrgCountry $1. ;
          informat AffiliatedOrgPPBCcountry $1. ;
          informat GovEntityName $43. ;
          informat file_number yymmdd10. ;
          informat date_filed yymmdd10. ;
          format VAR1 best12. ;
          format ID $36. ;
          format Year best12. ;
          format Received datetime. ;
          format Amount best12. ;
          format Type $32. ;
          format Period $26. ;
          format RegistrantID best12. ;
          format RegistrantName $54. ;
          format GeneralDescription $47. ;
          format Address $60. ;
          format RegistrantCountry $3. ;
          format RegistrantPPBCountry $3. ;
          format VAR14 $60. ;
          format ClientName $54. ;
          format VAR16 $1. ;
          format ClientID best12. ;
          format SelfFiler $5. ;
          format ContactFullname $21. ;
          format IsStateOrLocalGov $5. ;
          format ClientCountry $6. ;
          format ClientPPBCountry $6. ;
          format ClientState $20. ;
          format ClientPPBState $20. ;
          format LobbyistName $31. ;
          format LobbyistCoveredGovPositionIndica $7. ;
          format OfficialPosition $3. ;
          format Code $33. ;
          format SpecificIssue $1. ;
          format AffiliatedOrgName $1. ;
          format AffiliatedOrgCountry $1. ;
          format AffiliatedOrgPPBCcountry $1. ;
          format GovEntityName $43. ;
          format file_number yymmdd10. ;
          format date_filed yymmdd10. ;
       input
                   VAR1
                   ID  $
                   Year
                   Received
                   Amount
                   Type  $
                   Period  $
                   RegistrantID
                   RegistrantName  $
                   GeneralDescription  $
                   Address  $
                   RegistrantCountry  $
                  RegistrantPPBCountry  $
                  VAR14  $
                  ClientName  $
                  VAR16  $
                  ClientID
                  SelfFiler  $
                  ContactFullname  $
                  IsStateOrLocalGov  $
                  ClientCountry  $
                  ClientPPBCountry  $
                  ClientState  $
                  ClientPPBState  $
                  LobbyistName  $
                  LobbyistCoveredGovPositionIndica  $
                  OfficialPosition  $
                  Code  $
                  SpecificIssue  $
                  AffiliatedOrgName  $
                  AffiliatedOrgCountry  $
                  AffiliatedOrgPPBCcountry  $
                  GovEntityName  $
                  file_number
                  date_filed
      ;
      if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
      run;





/* Lobbying Data*/
PROC IMPORT	DATAFILE= 'R:\ps664\Data\Lobbying Data\lobbying_data.csv'	DBMS=csv
	OUT=lobby 	REPLACE; RUN;



					/* Data sent to Michelle and Michela*/
					data lobby_1;
					 set lobby ;
					 drop VAR1 VAR14;
					if RegistrantName="American Petroleum Institute" | RegistrantName="AMERICAN PETROLEUM INSTITUTE";
					run;


					data lobby_1;
					 set lobby ;
					 drop VAR1 VAR14;
					if year=2015;
					run;

					/* Export data to Stata (!! THIS DATA IS NOT A COMPLETE PYTHON SEARCH)*/
					PROC EXPORT 	DATA=lobby_1	DBMS=xlsx
						OUTFILE='R:\ps664\Patent Applications - Michelle Michela\More Data\lobbying_2015.xlsx'	REPLACE; RUN;



data lobby_1;
 set lobby ;
 drop VAR1 VAR14;
rename GeneralDescription = GeneralDescription_Cl;
run;


/* Standardize client (firm) names */


DATA lobby_2;
	SET lobby_1;
	formatted_conm  = COMPRESS(UPCASE(ClientName),".");
	formatted_conm  = TRANWRD(formatted_conm,"EMC CORP/MA",'EMC');										
	formatted_conm  = TRANWRD(formatted_conm,"&",' AND ');
	formatted_conm  = TRANWRD(formatted_conm,"+",' AND ');
	formatted_conm  = TRANSLATE(formatted_conm,' ',"!(),/:?-");
	formatted_conm  = TRANWRD(formatted_conm,' LLC',"");
	formatted_conm  = TRANWRD(formatted_conm,' LP','');
	formatted_conm  = TRANWRD(formatted_conm,'THE ','');
	formatted_conm  = TRANWRD(formatted_conm,'FINANCIAL','FINL');
	formatted_conm  = TRANWRD(formatted_conm,' INTERNATIONAL',' INTL');
	formatted_conm  = TRANWRD(formatted_conm,' COMPANY',' CO');
	formatted_conm  = TRANWRD(formatted_conm,' CORPORATION',' CORP');
	formatted_conm  = TRANWRD(formatted_conm,' INCORP','');
	formatted_conm  = TRANWRD(formatted_conm,' INC','');
	formatted_conm  = TRANWRD(formatted_conm,' LIMITED','');
	/*formatted_conm  = TRANWRD(formatted_conm,' INDUSTRIES','');*/
	formatted_conm  = TRANWRD(formatted_conm,' CC','');
	formatted_conm  = TRANWRD(formatted_conm,' LTD','');
	formatted_conm  = TRANWRD(formatted_conm,'L L C','');
	formatted_conm  = TRANWRD(formatted_conm,' AG ','');
	formatted_conm  = TRANWRD(formatted_conm,' PLC ','');
	formatted_conm  = TRANWRD(formatted_conm,' SYSTEMS','S');
	formatted_conm  = TRANWRD(formatted_conm,' LIMITED PARTNERSHIP','');
	formatted_conm  = TRANWRD(formatted_conm,')','');
	formatted_conm  = TRANWRD(formatted_conm," INT'L",'INTL');
	formatted_conm  = TRANWRD(formatted_conm," ET AL",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANIES",'COS');
	formatted_conm  = TRANWRD(formatted_conm," US ",'');
	formatted_conm  = TRANWRD(formatted_conm," ORPORATED",'CORP');
	formatted_conm  = TRANWRD(formatted_conm," SOLTNS",' SOLUTIONS');
	formatted_conm  = TRANWRD(formatted_conm," SYS ",' S ');
	formatted_conm  = TRANWRD(formatted_conm," PRODUCTS",' PROD');
	formatted_conm  = TRANWRD(formatted_conm,"'S",'S');
	formatted_conm  = TRANWRD(formatted_conm," LABORATORY",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," LABORATORIES",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," LABORATO",' LAB');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTICALS",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTICAL",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUTIC",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm," PHARMACEUT",' PHARMA');
	formatted_conm  = TRANWRD(formatted_conm,' TECHNOLOGIES',' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHNOLOGY",' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHNOL",' TECH');
	formatted_conm  = TRANWRD(formatted_conm," TECHN",' TECH');
	formatted_conm  = TRANWRD(formatted_conm,"'",'');
	formatted_conm  = TRANWRD(formatted_conm," CL A",'');
	formatted_conm  = TRANWRD(formatted_conm," CL B",'');
	formatted_conm  = TRANWRD(formatted_conm," REDH ",'');
	formatted_conm  = TRANWRD(formatted_conm," CORPP",'');
	formatted_conm  = TRANWRD(formatted_conm," CORP",'');
	formatted_conm  = TRANWRD(formatted_conm," COR",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANIES",'');
	formatted_conm  = TRANWRD(formatted_conm," COMPANY",'');
	formatted_conm  = TRANWRD(formatted_conm," COS ",'');
	formatted_conm  = TRANWRD(formatted_conm," CO ",'');
	formatted_conm  = TRANWRD(formatted_conm," OLD ",'');
	formatted_conm  = TRANWRD(formatted_conm," HLDGS",'');
	formatted_conm  = TRANWRD(formatted_conm," INTL",'');
	formatted_conm  = TRANWRD(formatted_conm," GROUP",'');
	formatted_conm  = TRANWRD(formatted_conm," GBR",'');
	if find(formatted_conm, 'INTL BUSINESS MACHINES') then formatted_conm="INTL BUSINESS MACHINES";
	if find(formatted_conm, 'NORTEL NETWORKS') then formatted_conm="NORTEL NETWORKS";
	if find(formatted_conm, 'UNITED TECH') then formatted_conm="UNITED TECH";
	if find(formatted_conm, "DISNEY  WALT") then formatted_conm="WALT DISNEY";
RUN;

/* Perfect match with CRSP-Compustat*/
data crsp_comp_reduced_2;
 set crsp_comp_reduced_1 ;
rename formatted_conm = crsp_comp_name;
run;

/* Merge on fiscal year*/
PROC SQL;
	CREATE TABLE lob_match_perfect AS
	SELECT *
	FROM lobby_2  AS l LEFT JOIN crsp_comp_reduced_2 AS r
	ON	l.formatted_conm = r.crsp_comp_name AND r.datadate - 365 <= l.date_filed <= r.datadate;
QUIT;

					/* Merge on just year instead of a copmany's fiscal year*/
					/*
					PROC SQL;
						CREATE TABLE lob_match_perfect AS
						SELECT *
						FROM lobby_2  AS l LEFT JOIN crsp_comp_reduced_2 AS r
						ON	l.formatted_conm = r.crsp_comp_name AND r.fyear = l.year  ;
					QUIT;
					*/

/* mark green/brown lobbying based on lobbying issue code*/
data lob_match_perfect_1;
 set lob_match_perfect ;
if not missing(crsp_comp_name);
drop year;
run;

/* mark green/brown lobbying based on lobbying issue code*/
data lob_match_perfect_1;
 set lob_match_perfect ;
if not missing(crsp_comp_name);
drop year;
if findw(code, 'ACCOUNTING')>0 then ACC=1; 
if findw(code, 'ADVERTISING')>0 then ADV=1; 
if findw(code, 'ALCOHOL')>0 then ALC=1; 
if findw(code, 'APPAREL')>0 then APP=1; 
if findw(code, 'ENTERTAINMENT')>0 then ART=1; 
if findw(code, 'AUTOMOTIVE')>0 then AUT=1; 
if findw(code, 'BANKING')>0 then BAN=1; 
if findw(code, 'BANKRUPTCY')>0 then BNK=1; 
if findw(code, 'BEVERAGE')>0 then BEV=1; 
if findw(code, 'BUDGET')>0 then BUD=1; 
if findw(code, 'COMMODITIES')>0 then CDT=1; 
if findw(code, 'CIVIL')>0 then CIV=1; 
if findw(code, 'COMMUNICATIONS')>0 then COM=1; 
if findw(code, 'COMPUTER')>0 then CPI=1; 
if findw(code, 'CONSUMER')>0 then CSP=1; 
if findw(code, 'CONSTITUTION')>0 then CON=1; 
if findw(code, 'COPYRIGHT')>0 then CPT=1; 
if findw(code, 'DEFENSE')>0 then DEF=1; 
if findw(code, 'COLUMBIA')>0 then DOC=1; 
if findw(code, 'DISASTER')>0 then DIS=1; 
if findw(code, 'ECONOMICS')>0 then ECN=1; 
if findw(code, 'EDUCATION')>0 then EDU=1; 
if findw(code, 'FAMILY')>0 then FAM=1; 
if findw(code, 'FIREARMS')>0 then FIR=1; 
if findw(code, 'FINANCIAL')>0 then FIN=1; 
if findw(code, 'FOOD')>0 then FOO=1; 
if findw(code, 'FOREIGN')>0 then FOR=1; 
if findw(code, 'GAMING')>0 then GAM=1; 
if findw(code, 'GOVERNMENT')>0 then GOV=1; 
if findw(code, 'HEALTH')>0 then HCR=1; 
if findw(code, 'HOMELAND')>0 then HOM=1; 
if findw(code, 'HOUSING')>0 then HOU=1; 
if findw(code, 'IMMIGRATION')>0 then IMM=1; 
if findw(code, 'INDIAN')>0 then IND=1; 
if findw(code, 'INSURANCE')>0 then INS=1; 
if findw(code, 'LABOR')>0 then LBR=1; 
if findw(code, 'INTELLIGENCE')>0 then INT=1; 
if findw(code, 'CRIME')>0 then LAW=1; 
if findw(code, 'MEDICAL')>0 then MED=1; 
if findw(code, 'MEDIA ')>0 then MIA=1; 
if findw(code, 'MEDICARE')>0 then MMM=1; 
if findw(code, 'MINTING')>0 then MON=1; 
if findw(code, 'PHARMACY')>0 then PHA=1; 
if findw(code, 'POSTAL')>0 then POS=1; 
if findw(code, 'RAILROADS')>0 then RRR=1; 
if findw(code, 'RELIGION')>0 then REL=1; 
if findw(code, 'RETIREMENT')>0 then RET=1; 
if findw(code, 'ROADS')>0 then ROD=1; 
if findw(code, 'SMALL BUSINESS')>0 then SMB=1; 
if findw(code, 'SPORTS')>0 then SPO=1; 
if findw(code, 'TARIFF')>0 then TAR=1; 
if findw(code, 'TELECOMMUNICATION')>0 then TEC=1; 
if findw(code, 'TOBACCO')>0 then TOB=1; 
if findw(code, 'TORTS')>0 then TOR=1; 
if findw(code, 'TRADE')>0 then TRD=1; 
if findw(code, 'TRAVEL')>0 then TOU=1; 
if findw(code, 'URBAN')>0 then URB=1; 
if findw(code, 'UNEMPLOYMENT')>0 then UNM=1; 
if findw(code, 'UTILITIES')>0 then UTI=1; 
if findw(code, 'VETERAN')>0 then VET=1; 
if findw(code, 'WELFARE')>0 then WEL=1; 

if findw(code,'OIL')>0 then  brown_lob = 1;
if findw(code,'ENERGY')>0 then brown_lob = 1;
if findw(code,'ENVIRON')>0 then green_lob = 1;
if findw(code,'ENVIRONMENT')>0 then green_lob = 1;
ENV = green_lob;

if findw(code,'ENERGY/NUCLEAR')>0 then ENG = 1;
if findw(code,'FUEL')>0 then FUE = 1;
if findw(code,'OIL')>0 then FUE = 1;
if findw(code,'CLEAN AIR AND WATER')>0 then CAW = 1;
if findw(code,'WASTE')>0 then WAS = 1;

if findw(code,'AEROSPACE')>0 then AER = 1;
if findw(code,'AGRICULTURE')>0 then AGR = 1;
if findw(code,'ANIMALS')>0 then ANI = 1;
if findw(code,'AVIATION')>0 then AVI = 1;
if findw(code,'CHEMICALS')>0 then CHM = 1;
if findw(code,'MANUFACTURING')>0 then MAN = 1;
if findw(code,'MARINE')>0 then MAR = 1;
if findw(code,'NATURAL RESOURCES')>0 then NAT = 1;
if findw(code,'REAL ESTATE')>0 then RES = 1;
if findw(code,'SCIENCE')>0 then SCI = 1;
if findw(code,'TRANSPORTATION')>0 then TRA = 1;
if findw(code,'TAXATION')>0 then TAX = 1;
if findw(code,'SHIPPING')>0 then TRU = 1;

if not missing(code) then has_code = 1;

run;



*mark if one of this lobbying transaction codes' was green or brown;
proc sql;
create table lob_match_perfect_2 as
  select *, max(green_lob) as green_lobby, max(brown_lob) as brown_lobby, max(ENG) as code_ENG, max(ENV) as code_ENV,
 max(FUE) as code_FUE,
 max(CAW) as code_CAW,
 max(WAS) as code_WAS,
 max(AER) as code_AER,
 max(AGR) as code_AGR,
 max(ANI) as code_ANI,
 max(AVI) as code_AVI,
 max(CHM) as code_CHM,
 max(MAN) as code_MAN,
 max(MAR) as code_MAR,
 max(NAT) as code_NAT,
 max(RES) as code_RES,
 max(SCI) as code_SCI,
 max(TRA) as code_TRA,
 max(TAX) as code_TAX,
 max(TRU) as code_TRU,
 max(ACC) as code_ACC, 
max(ADV) as code_ADV, 
max(ALC) as code_ALC, 
max(APP) as code_APP, 
max(ART) as code_ART, 
max(AUT) as code_AUT, 
max(BAN) as code_BAN, 
max(BNK) as code_BNK, 
max(BEV) as code_BEV, 
max(BUD) as code_BUD, 
max(CDT) as code_CDT, 
max(CIV) as code_CIV, 
max(COM) as code_COM, 
max(CPI) as code_CPI, 
max(CSP) as code_CSP, 
max(CON) as code_CON, 
max(CPT) as code_CPT, 
max(DEF) as code_DEF, 
max(DOC) as code_DOC, 
max(DIS) as code_DIS, 
max(ECN) as code_ECN, 
max(EDU) as code_EDU, 
max(FAM) as code_FAM, 
max(FIR) as code_FIR, 
max(FIN) as code_FIN, 
max(FOO) as code_FOO, 
max(FOR) as code_FOR, 
max(GAM) as code_GAM, 
max(GOV) as code_GOV, 
max(HCR) as code_HCR, 
max(HOM) as code_HOM, 
max(HOU) as code_HOU, 
max(IMM) as code_IMM, 
max(IND) as code_IND, 
max(INS) as code_INS, 
max(LBR) as code_LBR, 
max(INT) as code_INT, 
max(LBR) as code_LBR,  
max(LAW) as code_LAW, 
max(MED) as code_MED, 
max(MIA) as code_MIA, 
max(MMM) as code_MMM, 
max(MON) as code_MON, 
max(PHA) as code_PHA, 
max(POS) as code_POS, 
max(RRR) as code_RRR, 
max(REL) as code_REL, 
max(RET) as code_RET, 
max(ROD) as code_ROD, 
max(SMB) as code_SMB, 
max(SPO) as code_SPO, 
max(TAR) as code_TAR, 
max(TEC) as code_TEC, 
max(TOB) as code_TOB, 
max(TOR) as code_TOR, 
max(TRD) as code_TRD, 
max(TOU) as code_TOU, 
max(URB) as code_URB, 
max(UNM) as code_UNM, 
max(UTI) as code_UTI, 
max(VET) as code_VET, 
max(WEL) as code_WEL,
 max(has_code) as  code_has 
from work.lob_match_perfect_1
  group by ID;
quit;






				/* Lobbyists List - Python export*/

/* Export Dataset with all lobbyists' names and transactions with them (each transactions can have >1 lobbyist involved*/
proc sort  data = lob_match_perfect_2 out =  lob_match_perfect_2 ; by ID LobbyistName; run;

data lobbyists_list (keep = LobbyistName);
 set lob_match_perfect_2 ;
run;

proc sort nodupkey data = lobbyists_list out =  lobbyists_list ; by LobbyistName; run;


PROC EXPORT 	DATA=lobbyists_list	DBMS=xlsx
	OUTFILE='R:\ps664\Data\Lobbying_OpenSecrets\lobbyists_list.xlsx'	REPLACE; RUN;


/* send summary stats on lobbyists that didn't get through Python to Michelle and Michela */

/* import lobbyist not processed*/


/* Lobbying Data*/
PROC IMPORT	DATAFILE= 'R:\ps664\Data\Lobbying_OpenSecrets\party_contrib_all_aggr.csv'	DBMS=csv
	OUT=party_contrib 	REPLACE; RUN;

	/*
data lobbyists_stats (keep = ID fyear Amount Type ClientName LobbyistName LobbyistCoveredGovPositionIndica OfficialPosition GovEntityName RegistrantName GeneralDescription_Cl IsStateOrLocalGov ClientState);
 set lob_match_perfect_2 ;
run;
*/

	/*
data lob_match_perfect_3 ;
set lob_match_perfect_2 ;
 rename LobbyistName = LobbyistName_original;
run;
*/

PROC SQL;
	CREATE TABLE lobbyists_stats_1 AS
	SELECT *
	FROM lob_match_perfect_2  AS l LEFT JOIN party_contrib AS r
	ON	l.LobbyistName = r.lobbyistname ;
QUIT;


/* Lobbying Data*/
PROC IMPORT	DATAFILE= 'R:\ps664\Data\Lobbying_OpenSecrets\party_contrib_all_yearly.csv'	DBMS=csv
	OUT=party_contrib_yearly 	REPLACE; RUN;


PROC SQL;
	CREATE TABLE lobbyists_stats_2 AS
	SELECT *
	FROM lobbyists_stats_1  AS l LEFT JOIN party_contrib_yearly AS r
	ON	l.LobbyistName = r.lobbyistname & year(l.date_filed)=r.year;
QUIT;


data lobbyists_stats_3  ;
set lobbyists_stats_2 ;
 if not missing(LobbyistName);
run;

/* firm-transaction-lobbyists level: this sample shows stats on how many lobbyists per transaction there are */
PROC EXPORT 	DATA=lobbyists_stats_3	DBMS=xlsx
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\More Data\lobbyists_details.xlsx'	REPLACE; RUN;

proc sort nodupkey data = lobbyists_stats_2 out =  lobbyists_stats_3 ; by ID LobbyistName; run;

data lobbyists_stats_4  ;
set lobbyists_stats_3 ;
 n=1;
 if not missing(Cont_to_R) | not missing(Cont_to_D) then k=1;
 drop year;
run;

/* aggregate lobbyists' contributions into a transaction level (firm-transaction)*/
proc sql;
create table lobbyists_stats_5 as
  select * , sum(Cont_to_R_y) as all_lobb_cont_R_y , sum(Cont_to_D_y) as all_lobb_cont_D_y , sum(Cont_to_R) as all_lobb_cont_R, sum(Cont_to_D) as all_lobb_cont_D,  sum(n) as n_lobbyyists,  sum(k) as n_lobbyyists_w_data
  from lobbyists_stats_4
  group by ID;
quit;

data lobbyists_stats_6 (keep = gvkey fyear ID LobbyistName Amount LobbyistCoveredGovPositionIndica OfficialPosition Cont_to_R Cont_to_D  all_lobb_cont_R all_lobb_cont_D n_lobbyyists n_lobbyyists_w_data );
set lobbyists_stats_5 ;
run;

/* firm-transaction-lobbyists level: this sample shows stats on how many lobbyists per transaction there are */
PROC EXPORT 	DATA=lobbyists_stats_6	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\More Data\transaction_data.dta'	REPLACE; RUN;


proc sort nodupkey data = lobbyists_stats_5 out =  lob_count ; by ID; run;




/* Merge lobbyists back to transactions by LobbyistName and fyear to file lob_match_perfect_2*/
/* Also define transaction as green if mostif >50% of money from lobbyists working on this transaction goes to democrats*/

				/* Summary Stats tables - Lobbying */

/* delete all duplicates from the same lobbying transaction (area code, lobbyists etc) */
/* count how many lobbying transaction merged*/


/* Perfect match with CRSP-Compustat*/
data lob_count_1 (keep = year fyear code_: inhouse amount all_lobb_cont_D_y all_lobb_cont_R_y all_lobb_cont_D all_lobb_cont_R n_lobbyyists  n_lobbyyists_w_data  RegistrantName inhouse type brown_lobby green_lobby id date_filed permno gvkey conm GovEntityName IsStateOrLocalGov clientid );
 set lob_count ;
if amount=0 then  amount=.;
if UPCASE(ClientName) = UPCASE(RegistrantName) then inhouse=1;
rename fyear = year;
run;

/* Get CRSP-Compustat financial data */
/* restrict to after 2000 due to PatEx data being reliable only after 2000 as the law made patent applications public*/
RSUBMIT;
/*Extract data from Compustat FUNDA master file*/
DATA funda1 (DROP = indfmt consol popsrc datafmt cshpri);
	SET comp.funda (KEEP = conm gvkey DLTT DLC LCT LT EMOL CSHR  datadate csho ceq teq prcc_c fyear BKVLPS oiadp sich sic:  gp rect invt aco ppent intan ao ap lco lo indfmt consol popsrc datafmt ni at oibdp capx prcc_f cshpri FIC naicsh sale XRD XRDP ACQINTAN AQC BKVLPS CH DVPD DVPSP_F EBITDA EMP EPSFI FIC NITS OPITI PPEGT REVT);
	WHERE fyear <= 2020;
	IF indfmt='INDL' AND consol='C' AND popsrc='D' AND datafmt='STD';
	mkt_value = prcc_f*cshpri;
RUN;
PROC DOWNLOAD DATA=funda1 OUT=funda1;
RUN;
ENDRSUBMIT;


/* Get permno from CRSP + merge with Compustat */
RSUBMIT;
%MACRO CCM (INSET=,DATEVAR=DATADATE,OUTSET=,LINKTYPE=LULC,REMDUPS=1,OVERLAP=0);
 
/* Check Validity of CCM Library Assignment */
%if (%sysfunc(libref(CCM))) %then %do; libname CCM ("/wrds/crsp/sasdata/q_ccm/"); %end;
%if (%sysfunc(libref(CCM))) %then %do; libname CCM ("/wrds/crsp/sasdata/a_ccm/") ; %end;
%put; %put ### START. ;
 
/* Convert the overlap distance into months */
%let overlap=%sysevalf(12*&overlap.);
 
options nonotes;
/* Make sure first that the input dataset has no duplicates by GVKEY-&DATEVAR */
proc sort data=&INSET out=_ccm0 nodupkey; by GVKEY &DATEVAR; run;
 
/* Add Permno to Compustat sample */
proc sql;
create table _ccm1 as
select distinct b.lpermno as PERMNO " ", a.*, b.linkprim, b.linkdt
from _ccm0 as a, crsp.ccmxpf_linktable as b
where a.gvkey=b.gvkey and index("&linktype.",strip(b.linktype))>0
and (a.&datevar>= intnx("month",b.linkdt   ,-&overlap.,"b") or missing(b.linkdt)   )
and (a.&datevar<= intnx("month",b.linkenddt, &overlap.,"e") or missing(b.linkenddt));
quit;
proc sort data=_ccm1;
  by &datevar permno descending linkprim descending linkdt gvkey;
run;
 
/* it ties in the linkprim, then use most recent link or keep all */
data _ccm2;
set _ccm1;
by &datevar permno descending linkprim descending linkdt gvkey;
if first.permno;
%if &REMDUPS=0 %then %do; drop linkprim linkdt; %end;
run;
  
%if &REMDUPS=1 %then
 %do;
   proc sort data=_ccm2; by &datevar gvkey descending linkprim descending linkdt;
   data _ccm2;
   set _ccm2;
   by &datevar gvkey descending linkprim descending linkdt;
   if first.gvkey;
   drop linkprim linkdt;
   run;
   %put ## Removed Multiple PERMNO Matches per GVKEY ;
 %end;
 
/* Sanity Check -- No Duplicates -- and Save Output Dataset */
proc sort data=_ccm2 out=&OUTSET nodupkey; by gvkey &datevar permno; run;
%put ## &OUTSET Linked Table Created;
 
/* House Cleaning */
proc sql;
 drop table _ccm0, _ccm1, _ccm2;
quit;
 
%put ### DONE . ; %put ;
options notes;
%MEND CCM;

%CCM(INSET=funda1,DATEVAR=datadate,OUTSET=ccm1,LINKTYPE=LULC,REMDUPS=1,OVERLAP=0);
/*Extract dataset from WRDS*/
PROC DOWNLOAD DATA=ccm1 OUT=ccm1;
RUN;
ENDRSUBMIT;
/* ********************************************************************************* */


data funda1_1 ;
set ccm1;
*gvkey_1 = input(gvkey, best12.);
gvkey_1 = gvkey;
drop gvkey ;
rename conm=crsp_comp_name;
run;

proc sort nodupkey data = funda1_1   out =  funda1_1 ; by gvkey_1 fyear; run;

data funda1_2;
set funda1_1;
by gvkey_1 fyear;
if first.gvkey_1 then age=0;
if first.fyear then age + 1;
if fyear>=1999 ;
run;


PROC SQL;
	CREATE TABLE lob_stats AS
	SELECT *
	FROM funda1_2  AS l LEFT JOIN lob_count_1 AS r
	ON	l.gvkey_1 = r.gvkey AND l.fyear = r.year;
QUIT;


data lob_stats ;
set lob_stats;
drop gvkey year;
rename gvkey_1=gvkey;
run;

proc sort nodupkey data = lob_stats   out =  lob_stats_full ; by gvkey fyear ID; run;

/* Export data to Stata - all firm-years (!! THIS DATA HAS PERFECT NAME MATCHES ONLY )*/
PROC EXPORT 	DATA=lob_stats_full	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\lob_stats_full.dta'	REPLACE; RUN;

data lob_stats ; set lob_stats; if not missing(id); run;

/* Export data to Stata only lobbying firms-year (!! THIS DATA HAS PERFECT NAME MATCHES ONLY )*/
PROC EXPORT 	DATA=lob_stats	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\lob_stats.dta'	REPLACE; RUN;






/* Export data Compustata data 2000-2020 to a separarte file to add any extra variables later*/

data funda1_3 (keep=fyear gvkey gvkey_1 csho);
set funda1_2;
rename gvkey_1 = gvkey;
run;

run;PROC EXPORT 	DATA=funda1_3	DBMS=dta
	OUTFILE='R:\ps664\Patent Applications - Michelle Michela\Compustat_data.dta'	REPLACE; RUN;
