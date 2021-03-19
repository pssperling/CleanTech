

************************************************************************************************************ 
////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////         Patent Applications        /////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
************************************************************************************************************



cd "R:\ps664\Patent Applications - Michelle Michela\"
clear all 
use full_applic_green, replace

*event cods for First Action" FAIA, NCIR, MFAOO, MNCIR, MFAIA, FAOO, RFAI,


					///* Patent Applications - Tables for graph*///

* USPTO: Patent Publication occurs after expiration of an 18-month period following the earliest effective filing date
clear all
set maxvar 32767

cd "R:\ps664\Patent Applications - Michelle Michela"

use appl_stats, replace

* this variable is redundant, use application_number
drop application_n 
drop patent_num 

rename green green_ipc
replace green_ipc=0 if missing(green_ipc) & !missing(application_number)
replace green_cpc=0 if missing(green_cpc) & !missing(application_number)

//////////////////* Sample selection*////////////////////

* CAREFUL - THIS DATASET IS NOT FIRM-YEAR, ITS FIRM-YEAR-PATENT_APPLICATION

drop if fyear<2000
drop if at<10

* Ratios
gen mb=(prcc_c*csho) / ceq
gen roa= oibdp/at

* adjust weird observations with negative net sales
drop if sale<0
drop if mb<0
replace sale=. if sale<0

* Profit Margin	
gen net_sales=sale/at

* Return on Equity
gen roe= oibdp / teq

* Gross Profit Margin
gen gpm=gp/revt

* Market Cap
drop mkt_value
gen mkt_value = csho*prcc_f

replace xrd=0 if missing(xrd)
replace xrd=xrd/at
replace capx=capx/at
replace ni=ni/at
replace ch=ch/at

gen log_at = log(at)
gen ln_mkt_value = ln(mkt_value)
gen ln_at = ln(at)

keep if !missing(xrd)
keep if !missing(mkt_value)
keep if !missing(mb)
keep if !missing(ch)
keep if !missing(roa)
keep if !missing(net_sales)
keep if !missing(sich)

* winsorize all accounting ratios at 1% and 99%
winsor2 ch, cuts(1 99) replace 
winsor2 mkt_value, cuts(1 99) replace 
winsor2 capx, cuts(1 99)  replace 
winsor2 mb, cuts(1 99)  replace 
winsor2 roa, cuts(1 99)  replace 

sort gvkey fyear
by gvkey: gen l_ebitda_at = ebitda[_n-1]/at[_n-1]

label variable l_ebitda_at "EBITDA/Assets"
label variable at "Total Assets"
label variable xrd "R&D/Assets"
label variable mb "Market to Book"
label variable ch "Cash/Assets"
label variable net_sales "Net Sales/Assets"
label variable roa "ROA"
label variable mkt_value "Market Cap"

gen sic= floor(sich/10)		
* Drop financials
drop if sich>6000 & sich<6999
* Drop Utilities
drop if sich>=4900 & sich<=4949

/////////////////////////////////////////////////////////


rename PERMNO permno

rename utility_patent_number granted_pat
label variable granted_pat "utility_patent_number"

order gvkey permno fyear crsp_comp_name application_number granted_pat patent_number uspc_class
sort gvkey fyear crsp_comp_name application_number granted_pat patent_number
replace patent_number="" if patent_number=="None" 

* Merge Stoffman's patent value variable
cd "R:\ps664\Data\KPSS Patent Data and Scaled Cites"
rename granted_pat patnum
merge m:m patnum using patent_values_2019	
keep if _merge==3 | _merge==1
* there are duplicates from each patent assigned to multiple PERMCOs => drop those as I merge to CRSP-Compustat
sort gvkey fyear patnum filing_date_kpss
duplicates drop gvkey permno fyear crsp_comp_name application_number filing_date_kpss patnum uspc_class, force 
drop filing_date_kpss issue_date_kpss 
by gvkey fyear: egen xi_total = sum(xi_real)
drop _merge
rename  patnum granted_pat
cd "R:\ps664\Dr_Becher - DirComp\2_pull_exec_comp"


		* keep utility patents only
		*keep if invention_subject_matter=="UTL"

duplicates drop gvkey fyear crsp_comp_name application_number granted_pat patent_number uspc_class, force

gen app_year= year(filing_date)
gen grant_year= year(patent_issue_date)

* total firm application and granting by year
gen did_grant=1 if !missing(patent_number)
replace did_grant=0 if missing(patent_number)

gen did_apply=1 if !missing(application_number)
replace did_apply=0 if missing(did_apply)

by gvkey fyear: egen total_appl=sum(did_apply)
by gvkey fyear: egen total_grant=sum(did_grant)

* scaled total number of patents 
* scaled patent - bias is corrected by diving each patent by the average number of patents of all firms in the same year and tech class
* sort by firm year and class 
* sum total patents by firm and class 
* find the average of firm year class 
* get patents scaed by diving unscaled patents by the average

sort gvkey fyear uspc_class
by gvkey fyear uspc_class: egen f_appl_year_techclass = sum(did_apply)
by gvkey fyear uspc_class: egen f_grant_year_techclass = sum(did_grant)

		
*sort app_year uspc_class
*by app_year uspc_class: egen sum_appl_year_techclass = sum(did_apply)
*by app_year uspc_class: egen sum_grant_year_techclass = sum(did_grant)
*replace sum_appl_year_techclass=. if missing(uspc_class)
*replace sum_grant_year_techclass=. if missing(uspc_class)

*sort gvkey fyear crsp_comp_name application_number granted_pat patent_number uspc_class
*gen did_grant_scaled=did_grant/sum_grant_year_techclass
*gen did_apply_scaled=did_apply/sum_appl_year_techclass

*by gvkey fyear: egen total_appl_scaled=sum(did_apply_scaled)
*by gvkey fyear: egen total_grant_scaled=sum(did_grant_scaled)

*drop sum_appl_year_techclass sum_grant_year_techclass did_grant_scaled did_apply_scaled 

tab match if did_apply==1 
tab match if did_grant==1 

gen did_apply_gr=1 if green_ipc==1 | green_cpc==1
replace did_apply_gr=0 if missing(did_apply_gr)

gen did_grant_gr=1 if !missing(patent_number) & did_apply_gr==1
replace did_grant_gr=0 if missing(did_grant_gr)


			* Green Patents based on Carrion-Flores and Innes (2010)
			*gen p_class=uspc_class
			*gen did_apply_gr=1 if inlist(p_class, 242, 073, 180, 440, 340, 343, 422, 280, 104, 374, 137, 435, 165, 119, 210, 205, 405, 065, 405, 203, 210, 264, 201, 229, 460, 526, 106, 205, 425, 060, 075, 099, 100, 162, 164, 198, 210, 216, 266, 422, 431, 432, 502, 523, 525, 902, 204, 062, 228, 248, 425, 049, 428, 242, 222, 708, 976, 062, 425, 222, 060, 436, 123, 060, 110, 422, 015, 044, 423, 241, 239, 523, 588, 137, 122, 976, 405, 060, 137, 976, 239, 165, 241, 075, 422, 266, 118, 119, 435, 210, 405, 034, 122, 423, 205, 209, 065, 099, 162, 106, 203, 431)
			*replace did_apply_gr=0 if missing(did_apply_gr)
			*gen did_grant_gr=1 if !missing(patent_number) & did_apply_gr==1
			*replace did_grant_gr=0 if missing(did_grant_gr)




			///* Patents over time + Compare with Stoffman's data *///
			
			gen storffman_apl=1 if did_apply==1 & match=="stoffm"  
			gen storffman_gr=1 if did_grant==1 & match=="stoffm"
			replace storffman_gr=0 if missing(storffman_gr)
			replace storffman_apl=0 if missing(storffman_apl)

			* yearly n of patents that will eventually be granted
			sort app_year
			by app_year: egen y_appl_stoffman=sum(storffman_apl)
			by app_year: egen y_appl=sum(did_apply)
			by app_year: egen y_appl_gr=sum(did_apply_gr)

			sort grant_year
			by grant_year: egen y_grant_stoffman=sum(storffman_gr)
			by grant_year: egen y_grant=sum(did_grant)
			by grant_year: egen y_grant_gr=sum(did_grant_gr)
			
			
			* STOPPED: WHY DO APPLICATIONS GET TRUNCATED? BECAUSE MY DATA IS MOSTLY FROM STOFFMAN => TRUNCATION IN GRANTS BY APPLICATION DATE TRANSLATES INTO TRUNCATION OF APPLICATIONS?
			* WHY APPLICATIONS TRUNCATED, BUT NOT GRANTS
			
			keep if grant_year==app_year
			duplicates drop app_year, force
			gen y= grant_year-2000
			
			/* Graphs in Report 2-11-20*/
			graph bar y_appl_stoffman y_appl y_appl_gr, over(y)  ytitle("N of patent applications") title("Firms Applying for Patents in 2000s") legend( label(1 "Stoffman Data") label(2 "Extended Data") label(3 "Green Patents")) 
			
			graph bar y_grant_stoffman y_grant y_grant_gr , over(y)  ytitle("N of patent grants") title("Firms Granting Patents in 2000s") legend( label(1 "Stoffman Data") label(2 "Extended Data") label(3 "Green Patents")) 
			* year FE should account for the big drop 
			
			* Green N of Patents over time		
			graph bar y_appl_gr y_grant_gr, over(y)  ytitle("N of patent applications") title("Total Green Applications by Public firms over time") legend( label(1 "Applied Green Patents") label(2 "Granted Green Patents") ) 
			


 
 
*n of filed patents that WILL be granted - total_grant_gr
tab fyear, sum(did_apply_gr) freq
by gvkey fyear: egen total_appl_gr=sum(did_apply_gr)
by gvkey fyear: egen total_grant_gr=sum(did_grant_gr)

by gvkey fyear: egen total_cites_scaled=sum(cites_scaled)
by gvkey fyear: egen total_cites =sum(cites)

gen cites_scaled_gr = cites_scaled if green_cpc==1 | green_ipc==1
by gvkey fyear: egen total_cites_scaled_gr=sum(cites_scaled_gr)

* Count Number of Patens that a firm granted this year (and not )
sort gvkey grant_year
gen granted=1 if !missing(grant_year)
gen granted_gr=1 if !missing(grant_year) & green_cpc==1 | green_ipc==1

			*gen granted_gr=1 if !missing(grant_year) & inlist(p_class, 242, 073, 180, 440, 340, 343, 422, 280, 104, 374, 137, 435, 165, 119, 210, 205, 405, 065, 405, 203, 210, 264, 201, 229, 460, 526, 106, 205, 425, 060, 075, 099, 100, 162, 164, 198, 210, 216, 266, 422, 431, 432, 502, 523, 525, 902, 204, 062, 228, 248, 425, 049, 428, 242, 222, 708, 976, 062, 425, 222, 060, 436, 123, 060, 110, 422, 015, 044, 423, 241, 239, 523, 588, 137, 122, 976, 405, 060, 137, 976, 239, 165, 241, 075, 422, 266, 118, 119, 435, 210, 405, 034, 122, 423, 205, 209, 065, 099, 162, 106, 203, 431) 
			
replace granted=0 if missing(granted)
replace granted_gr=0 if missing(granted_gr)
by gvkey grant_year: egen total_grant_this_y=sum(granted)
by gvkey grant_year: egen total_grant_gr_this_y=sum(granted_gr)
drop granted granted_gr

//// For IV regression - first stage ///
* could only do this year's control variables

* find examiner's approval rate following Farre-Mensa
* approval rate (ijta) = # granted (jta) / # reviewed (jta)
*are the numbers of patents examiner j has reviewed and granted, respectively, prior to date t within art unit a

* Mark Green Patents ob IPC or CPC class
sort gvkey fyear
gen green = 1 if green_ipc==1 | green_cpc==1
replace green=0 if missing(green) & !missing(application_number)


* Find Examiners' Approval Rate
sort examiner_number examiner_art_unit filing_date
by examiner_number examiner_art_unit: gen all_granted = sum(did_grant)
gen n=1 if !missing(application_number)
by examiner_number examiner_art_unit: gen all_reviewed = sum(n)
*adjust to have approval rate up to a the previous year (t-1)
replace all_granted=all_granted-1 if all_granted>0
replace all_reviewed=all_reviewed-1 if all_reviewed>0
replace all_reviewed=. if missing(examiner_number)
replace all_granted=. if missing(examiner_number)

gen approval_rate=all_granted/all_reviewed
drop n all_granted all_reviewed 

* Find Green Examiners' Approval Rate
*gen approval_gr = approval_rate if green==1
gen approval_non_gr = approval_rate if green==0
sort green examiner_number examiner_art_unit filing_date
by green examiner_number examiner_art_unit: gen all_granted_gr = sum(did_grant)
gen n=1 if !missing(application_number)
by green examiner_number examiner_art_unit: gen all_reviewed_gr = sum(n)
replace all_granted_gr=all_granted_gr-1 if all_granted>0
replace all_reviewed_gr=all_reviewed_gr-1 if all_reviewed>0
replace all_granted_gr=. if missing(examiner_number) | green==0
replace all_reviewed_gr=. if missing(examiner_number) | green==0

gen approval_gr = all_granted_gr/all_reviewed_gr
drop n all_granted_gr all_reviewed_gr 


* Adjust Examiner FE to Tech Class FE and Art Class FE (by year)
gen n=1
sort app_year examiner_art_unit
by app_year examiner_art_unit: egen average_art_year = mean(approval_rate)
by app_year examiner_art_unit: egen firms_per_art = sum(n)
sort app_year uspc_class
by app_year uspc_class: egen average_tclass_year = mean(approval_rate)
by app_year uspc_class: egen firms_per_tclass = sum(n)
sort examiner_art_unit filing_date
by examiner_art_unit: gen average_art = sum(approval_rate) / _n 
sort uspc_class filing_date
by uspc_class: gen average_tclass = sum(approval_rate) / _n 
* both - tech-class FE and art-class FE


* Adjusted by Art x Year 
sort examiner_number examiner_art_unit filing_date
gen appr_rate_art_year = approval_rate - average_art_year
gen appr_rate_art = approval_rate - average_art
gen appr_rate_tclass_year = approval_rate - average_tclass_year
gen appr_rate_tclass = approval_rate - average_tclass 
gen appr_rate_art_tclass_year = approval_rate - average_art_year - average_tclass_year

* Adjusted Green FEs 

*gen appr_rate_art_year_gr = appr_rate_art_year if green==1
*gen appr_rate_art_gr = appr_rate_art if green==1
*gen appr_rate_tclass_year_gr = appr_rate_tclass_year if green==1
*gen appr_rate_tclass_gr = appr_rate_tclass if green==1

sort green app_year examiner_art_unit
by green app_year examiner_art_unit: egen average_art_year_gr = mean(approval_rate)
by green app_year examiner_art_unit: egen firms_per_art_gr = sum(n)
replace average_art_year_gr=. if green==0
replace firms_per_art_gr=. if green==0

sort green app_year uspc_class
by green app_year uspc_class: egen average_tclass_year_gr = mean(approval_rate)
by green app_year uspc_class: egen firms_per_tclass_gr = sum(n)
replace average_tclass_year_gr=. if green==0
replace firms_per_tclass_gr=. if green==0

sort green examiner_art_unit filing_date
by green examiner_art_unit: gen average_art_gr = sum(approval_rate) / _n 
replace average_art_gr=. if green==0

sort green uspc_class filing_date
by green uspc_class: gen average_tclass_gr = sum(approval_rate) / _n 
replace average_tclass_gr=. if green==0

sort examiner_number examiner_art_unit filing_date
gen appr_rate_art_year_gr = approval_gr - average_art_year_gr
gen appr_rate_art_gr = approval_gr - average_art_gr
gen appr_rate_tclass_year_gr = approval_gr - average_tclass_year_gr
gen appr_rate_tclass_gr = approval_gr - average_tclass_gr 
gen appr_rate_art_tclass_year_gr = approval_gr - average_art_year_gr -  average_tclass_year_gr


			* separate approval rates for green and non-green patents
			*gen green = 1 if  inlist(p_class, 242, 073, 180, 440, 340, 343, 422, 280, 104, 374, 137, 435, 165, 119, 210, 205, 405, 065, 405, 203, 210, 264, 201, 229, 460, 526, 106, 205, 425, 060, 075, 099, 100, 162, 164, 198, 210, 216, 266, 422, 431, 432, 502, 523, 525, 902, 204, 062, 228, 248, 425, 049, 428, 242, 222, 708, 976, 062, 425, 222, 060, 436, 123, 060, 110, 422, 015, 044, 423, 241, 239, 523, 588, 137, 122, 976, 405, 060, 137, 976, 239, 165, 241, 075, 422, 266, 118, 119, 435, 210, 405, 034, 122, 423, 205, 209, 065, 099, 162, 106, 203, 431) 
			*replace green=0 if !inlist(p_class, 242, 073, 180, 440, 340, 343, 422, 280, 104, 374, 137, 435, 165, 119, 210, 205, 405, 065, 405, 203, 210, 264, 201, 229, 460, 526, 106, 205, 425, 060, 075, 099, 100, 162, 164, 198, 210, 216, 266, 422, 431, 432, 502, 523, 525, 902, 204, 062, 228, 248, 425, 049, 428, 242, 222, 708, 976, 062, 425, 222, 060, 436, 123, 060, 110, 422, 015, 044, 423, 241, 239, 523, 588, 137, 122, 976, 405, 060, 137, 976, 239, 165, 241, 075, 422, 266, 118, 119, 435, 210, 405, 034, 122, 423, 205, 209, 065, 099, 162, 106, 203, 431) 



* Merge with H&B fluidity measure
cd "R:\ps664\Data\Fluidity"
gen year=fyear
merge m:1 gvkey year using fluidity		
drop if _merge==2
drop _merge
cd "R:\ps664\Patent Applications - Michelle Michela"


ffind sic, newvar(ffi) type(48)
egen iyfe=group(ffi fyear)
keep if !missing(sich)

global controls "ln_mkt_value roa xrd prodmktfluid"

				* NEW: Correct negative approval rates
				*replace appr_rate_art_year=approval_rate if appr_rate_art_year<0
				*replace appr_rate_art=approval_rate if appr_rate_art<0
				*replace appr_rate_tclass_year=approval_rate if appr_rate_tclass_year<0				
				*replace appr_rate_tclass=approval_rate if appr_rate_tclass<0				
				*replace appr_rate_art_tclass_year=approval_rate if appr_rate_art_tclass_year<0
				
				*replace appr_rate_art_year_gr=approval_gr if appr_rate_art_year_gr<0
				*replace appr_rate_art_gr=approval_gr if appr_rate_art_gr<0
				*replace appr_rate_tclass_year_gr=approval_gr if appr_rate_tclass_year_gr<0				
				*replace appr_rate_tclass=approval_gr if appr_rate_tclass_gr<0				
				*replace appr_rate_art_tclass_year_gr=approval_gr if appr_rate_art_tclass_year_gr<0

				
				
* Aggregated approval rates 
sort gvkey fyear
by gvkey fyear: egen all_approval = sum(approval_rate)
by gvkey fyear: egen all_approval_gr = sum(approval_gr)
by gvkey fyear: egen all_approval_nongr = sum(approval_non_gr)
by gvkey fyear: egen av_approval = mean(approval_rate)
by gvkey fyear: egen av_approval_gr = mean(approval_gr)
by gvkey fyear: egen av_approval_nongr = mean(approval_non_gr)

* Adjusted Approvals
by gvkey fyear: egen av_appr_art_year = mean(appr_rate_art_year)
by gvkey fyear: egen av_appr_art = mean(appr_rate_art)
by gvkey fyear: egen av_appr_tclass_year = mean(appr_rate_tclass_year)
by gvkey fyear: egen av_appr_tclass = mean(appr_rate_tclass)
by gvkey fyear: egen av_appr_art_tclass_year = mean(appr_rate_art_tclass_year)

* Adjusted  Green Approvals 
by gvkey fyear: egen av_appr_art_year_gr = mean(appr_rate_art_year_gr)
by gvkey fyear: egen av_appr_art_gr = mean(appr_rate_art_gr)
by gvkey fyear: egen av_appr_tclass_year_gr = mean(appr_rate_tclass_year_gr)
by gvkey fyear: egen av_appr_tclass_gr = mean(appr_rate_tclass_gr)
by gvkey fyear: egen av_appr_art_tclass_year_gr = mean(appr_rate_art_tclass_year_gr)

* Sum of Examiners' Adjusted Approvals
by gvkey fyear: egen sum_appr_art_year = sum(appr_rate_art_year)
by gvkey fyear: egen sum_appr_art = sum(appr_rate_art)
by gvkey fyear: egen sum_appr_tclass_year = sum(appr_rate_tclass_year)
by gvkey fyear: egen sum_appr_tclass = sum(appr_rate_tclass)
by gvkey fyear: egen sum_appr_art_tclass_year = sum(appr_rate_art_tclass_year)
by gvkey fyear: egen sum_appr_art_year_gr = sum(appr_rate_art_year_gr)
by gvkey fyear: egen sum_appr_art_gr = sum(appr_rate_art_gr)
by gvkey fyear: egen sum_appr_tclass_year_gr = sum(appr_rate_tclass_year_gr)
by gvkey fyear: egen sum_appr_tclass_gr = sum(appr_rate_tclass_gr)
by gvkey fyear: egen sum_appr_art_tclass_year_gr = sum(appr_rate_art_tclass_year_gr)



drop appr_rate_art_year appr_rate_art appr_rate_tclass_year appr_rate_tclass appr_rate_art_year_gr appr_rate_art_gr appr_rate_tclass_year_gr appr_rate_tclass_gr   




drop ffi iyfe prodmktfluid  approval_rate approval_gr approval_non_gr green

* finish patents scaled variables 

duplicates drop gvkey fyear uspc_class, force
sort fyear uspc_class
by fyear uspc_class: egen av_appl_techclass=mean(f_appl_year_techclass)
by fyear uspc_class: egen av_grant_techclass=mean(f_grant_year_techclass)
gen total_appl_scaled = total_appl/av_appl_techclass
gen total_grant_scaled = total_grant/av_grant_techclass

drop av_appl_techclass av_grant_techclass



duplicates drop gvkey fyear , force

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
sa app_pat_yearly_updated_, replace

/////////////////////////////////////////


////////// Tables on Patenting ///////////////

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
clear all
use app_pat_yearly_updated_
* % of firms applying for a patent 
gen appl=1 if total_appl>0
replace appl=0 if missing(appl)
tab fyear, sum(appl)

* attrition rate based on firm size
gen attr=total_grant/total_appl
xtile size_q = at, nq(10)
tab size_q, sum(attr)
 
 
* FACT: in 2009 USPTO Accelerated Review of Green Technology Patent Applications (program to incentivize more green patents) 
* OR
		* total green patents per year
		sort fyear gvkey 
		by fyear: egen year_appl_gr=sum(total_appl_gr)
		by fyear: egen year_grant_gr=sum(total_grant_gr)	

		duplicates drop fyear year_appl_gr year_grant_gr , force

		gen y=fyear-2000
		graph bar year_appl_gr , over(y)  ytitle("Total Firms' Patent Application") title("Firm GREEN Patent Applications in 2000s")
		graph bar year_grant_gr , over(y)  ytitle("Total Firms' Patent Grant") title("Firm GREEN Patent Grant in 2000s")


		
* OR
		* total all firms' lobbying per year
		sort fyear gvkey 
		by fyear: egen year_appl=sum(total_appl)
		by fyear: egen year_grant=sum(total_grant)
		by fyear: egen year_appl_gr_stoffman=sum(total_appl_stoffman)
		by fyear: egen year_grant_gr_stoffman=sum(total_grant_stoffman)	

		duplicates drop fyear year_appl year_grant year_appl_gr_stoffman, force

		gen y=fyear-2000
		graph bar year_appl , over(y)  ytitle("Total Firms' Patent Application") title("Firm Patent Applications in 2000s")
		graph bar year_grant , over(y)  ytitle("Total Firms' Patent Grant") title("Firm Patent Grant in 2000s")
		graph bar year_appl_gr_stoffman , over(y)  ytitle("Total Firms' Patent Application") title("Firm Patent Applications in 2000s")


* OR
		* drop years subject to truncation for summ stats
		drop if fyear>=2015
		egen all_appl=sum(did_apply)
		egen all_grant=sum(did_grant)
		gen a=all_grant/all_appl
		* attrition rate for patetn applications


/////////////////////////////////////////////// Patent Data Reports //////////////////////////////////////

				///* Sum Stats for Green patent filers on Carrion-Flores and Innes (2010)*///


cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
clear all
use app_pat_yearly_updated_

* adjust weird observations with negative net sales
drop if sale<0
drop if mb<0
replace sale=. if sale<0

				
* separate green filers versus others
gen green=1 if total_appl_gr>0				
replace green=0 if missing(green)


* non-green are those who applied for any patent that is no green (excludes firms that applied only for green, but includes who applied for both)
gen non_green=1 if total_appl>0 & total_appl-total_appl_gr>0 
*BEFORE: firms that applied for anything other than green patent
*gen non_green=1 if green==0 & total_appl>0
replace non_green=0 if missing(non_green)


cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Working Folder 1"
merge m:1 permno fyear using obsolescence_123		
drop if _merge==2
drop _merge

* Merge with H&B fluidity measure
cd "R:\ps664\Data\Fluidity"
drop year
gen year=fyear
merge m:1 gvkey year using fluidity		
drop if _merge==2
drop _merge
cd "R:\ps664\Patent Applications - Michelle Michela"


* Merge with HHI data
cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\hhi data"
merge 1:1 gvkey fyear using hhi_data_4digitSIC
keep if _merge==3
drop _merge
rename HHI hhi_4digit
sort gvkey fyear
by gvkey: gen l_hhi=hhi_4digit[_n-1]
label variable l_hhi "HHI"

merge 1:1 gvkey fyear using hhi_data_3digitSIC
keep if _merge==3
drop _merge
rename HHI hhi_3digit
label variable hhi_3digit "HHI"
cd "R:\ps664\Patent Applications - Michelle Michela"


ffind sic, newvar(ffi) type(48)
ffind sic, newvar(ffi_12) type(12)

egen iyfe=group(ffi fyear)
keep if !missing(sich)

gen sic= floor(sich/10)		
* Drop financials
drop if sich>6000 & sich<6999
* Drop Utilities
drop if sich>=4900 & sich<=4949



						* Summary stats

gen total_appl_other=total_appl-total_appl_gr
gen total_grant_other=total_grant-total_grant_gr

label variable total_appl_other "Other P. Applications"
label variable total_appl_gr "Green P. Applications"
label variable mkt_value "Market Cap"
label variable net_sales "Net Sales/Assets"

sum at net_sales mb roa mkt_value xrd net_sales if green==1
sum at net_sales mb roa mkt_value xrd net_sales if non_green==1
sum at net_sales mb roa mkt_value xrd net_sales if green==0 & non_green==0

sum total_appl_other total_appl_gr at ch mb roa xrd net_sales if green==1
sum total_appl_other total_appl_gr at ch mb roa xrd net_sales if non_green==1
sum total_appl_other total_appl_gr at ch mb roa xrd net_sales if green==0 & non_green==0

cd "R:\ps664\Patent Applications - Michelle Michela\Reports\Report"
outreg2 using table_1p.doc if green==1, replace sum(detail) eqkeep(N mean p50 sd min max) keep(total_appl_other total_appl_gr mkt_value at ch mb roa xrd net_sales) label title("Table 1A - Green Firms (applied for 1+ green patent this year)")
outreg2 using table_2p.doc if non_green==1, replace sum(detail) eqkeep(N mean p50 sd min max) keep(total_appl_other total_appl_gr mkt_value at ch mb roa xrd net_sales) label title("Table 1B - Non-green Firms (applied for 1+ non-green patent this year)")
outreg2 using table_3p.doc if green==0 & non_green==0, replace sum(detail) eqkeep(N mean p50 sd min max) keep(total_appl_other total_appl_gr mkt_value at ch mb roa xrd net_sales) label title("Table 1C - Non-patenting Firms (applied for 0 patents this year)")


* separate firms that filed at least one patent ever
sort gvkey fyear
by gvkey: egen all_p=sum(total_appl)
by gvkey: gen yes_p=1 if all_p>0
gen other_patenter=1 if yes_p==1 & green==0
replace other_patenter=0 if missing(other_patenter)
*outreg2 using table_3p.doc if other_patenter==1, replace sum(log) keep(total_appl_other total_appl_gr at ch mb roa xrd net_sales) label title("Table 1C - Other Firms that will ever patent")


					///* Quantile Analysis *///
					
* Green patent application by firm size
xtile quart_1 = at, nq(10)
xtile quart_2 = xrd, nq(10)
xtile quart_4 = prodmktfluid, nq(10)

xtile quart_5 = mb, nq(10)
xtile quart_7 = roa, nq(10)
xtile quart_8 = ch, nq(10)
xtile quart_3 = obs_3year, nq(10)

* Used in proposal 
graph bar green, over(quart_4)  ytitle("% of Firms Applying for Green Patents") title("Green Patenting by Fluidity decile")  


* report 

graph bar green non_green, over(quart_1)  ytitle("% of firms applying for patents") title("Patenting by firm size quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 

graph bar green non_green, over(quart_2)  ytitle("% of firms filing for other patents") title("Patenting by firm R&D/Assets spending quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 

graph bar green non_green, over(quart_4)  ytitle("% of firms filing for other patents") title("Patenting by firm Pr. Market Competition (fluidity) quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 

graph bar green, over(quart_4)  ytitle("% of firms filing for other patents") title("Patenting by firm Pr. Market Competition (fluidity) quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 

* other
graph bar total_appl_gr total_appl_other, over(quart_1)  ytitle("Total Firm Lobbying in millions") title("Firm Lobbying by firm size quantile")

graph bar green non_green, over(quart_7)  ytitle("% of firms filing for other patents") title("Patenting by firm ROA quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 

graph bar green non_green, over(quart_8)  ytitle("% of firms filing for other patents") title("Patenting by firm Cash/Assets quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 

graph bar green non_green, over(quart_3)  ytitle("% of firms filing for other patents") title("Patenting by firm Obsolescence of Patent Portfolio quantile") legend( label(1 "Green Applications") label(2 "Other Applications")) 




					///* Regressions *///

///////////////// Create Regression Variables ////////////////////////////				

* all values are winsorized already
sort gvkey fyear
by gvkey: gen l_ln_mkt_value  = ln_mkt_value[_n-1]
by gvkey: gen l_ln_at  = ln_at[_n-1]
by gvkey: gen l_xrd  = xrd[_n-1]
by gvkey: gen l_net_sales  = net_sales[_n-1]
by gvkey: gen l_ch  = ch[_n-1]
by gvkey: gen l_mb  = mb[_n-1]
by gvkey: gen l_roa  = roa[_n-1]

by gvkey: gen l_fluid  = prodmktfluid[_n-1]

* Sales growth
by gvkey fyear: gen lag_sale=sale[_n-1]
gen sales_growth=(sale-lag_sale)/lag_sale
winsor2 sales_growth, cuts(1 99)  replace 
by gvkey: gen l_sales_growth  = sales_growth[_n-1]

by gvkey: gen l_ebitda_at = ebitda[_n-1]/at[_n-1]

label variable l_ebitda_at "EBITDA/Assets"
label variable l_fluid "Fluidity"
label variable l_ln_at "ln(Total Assets)"
label variable l_xrd "R&D/Assets"
label variable l_mb "Market to Book"
label variable l_ch "Cash/Assets"
label variable l_net_sales "Net Sales/Assets"
label variable l_roa "ROA"
label variable l_ln_mkt_value "Market Cap"
label variable l_fluid "Fluidity"
label variable l_sales_growth "Sales Growth"


global l_controls "l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd l_net_sales l_ch"
global l_controls_nohhi "l_fluid l_ln_mkt_value l_ln_at l_xrd l_net_sales l_ch"

cd "R:\ps664\Patent Applications - Michelle Michela\Reports\Report\Patent data"

/////////////////////////////////////////////////////////////////////					
					
					
* difference between total_grant_this_y and total_grant:
* total_grant_this_y - grants a firm recieved this year
* total_grant - patents a firm applied for that WILL be granted in the future (counted at application date)

gen total_appl_non_gr = total_appl - total_appl_gr
gen total_grant_non_gr = total_grant - total_grant_gr


* WORKS for firm FE 
* limits the sample for firms who apply for at least one green patent
gen ln_pat_gr=log(1+total_appl_gr)
gen ln_pat_non_gr=log(1+total_appl_non_gr)
gen ln_patgrant_gr=log(1+total_grant_gr)
gen ln_patgrant_non_gr=log(1+total_grant_non_gr)
xtset gvkey
xtreg ln_pat_gr $l_controls  i.fyear  , fe vce(robust)
xtreg ln_pat_non_gr $l_controls  i.fyear  , fe vce(robust)
xtreg ln_patgrant_gr $l_controls  i.fyear  , fe vce(robust)
xtreg ln_patgrant_non_gr $l_controls  i.fyear  , fe vce(robust)


* Green Patents determinants
cd "R:\ps664\Patent Applications - Michelle Michela\Reports\Report\Patent data"
xtset fyear
xtreg total_appl_gr $l_controls  i.fyear  , fe vce(robust)
outreg2 using reg_p1.doc, replace ctitle(#Green Patents) keep( l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  

xtset ffi
xtreg total_appl_gr $l_controls  i.fyear  , fe vce(robust)
outreg2 using reg_p1.doc, append ctitle(#Green Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  

xtset iyfe
xtreg total_appl_gr $l_controls_nohhi  i.fyear  , fe vce(robust)
outreg2 using reg_p1.doc, append ctitle(#Green Patents) keep(l_fluid  l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  

xtset gvkey
xtreg total_appl_gr $l_controls  i.fyear  , fe vce(robust)
outreg2 using reg_p1.doc, append ctitle(#Green Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  

			* log(1+#patents)
			xtset fyear
			xtreg ln_pat_gr $l_controls  i.fyear  , fe vce(robust)
			outreg2 using reg_p1_log.doc, replace ctitle(#Green Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  

			xtset ffi
			xtreg ln_pat_gr $l_controls  i.fyear  , fe vce(robust)
			outreg2 using reg_p1_log.doc, append ctitle(#Green Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  

			xtset iyfe
			xtreg ln_pat_gr $l_controls_nohhi  i.fyear  , fe vce(robust)
			outreg2 using reg_p1_log.doc, append ctitle(#Green Patents) keep(l_fluid  l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  

			xtset gvkey
			xtreg ln_pat_gr $l_controls  i.fyear  , fe vce(robust)
			outreg2 using reg_p1_log.doc, append ctitle(#Green Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  




* Non-Green Patents determinants
xtset fyear
xtreg total_appl_non_gr $l_controls  i.fyear  , fe vce(robust)
outreg2 using reg_p2.doc, replace ctitle(#Non-gr Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  

xtset ffi
xtreg total_appl_non_gr $l_controls  i.fyear  , fe vce(robust)
outreg2 using reg_p2.doc, append ctitle(#Non-gr Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  

xtset iyfe
xtreg total_appl_non_gr $l_controls_nohhi  i.fyear  , fe vce(robust)
outreg2 using reg_p2.doc, append ctitle(#Non-gr Patents) keep(l_fluid  l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni 

xtset gvkey
xtreg total_appl_non_gr $l_controls  i.fyear  , fe vce(robust)
outreg2 using reg_p2.doc, append ctitle(#Non-gr Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni 


			* log(1+#non-green patents)
			xtset fyear
			xtreg ln_pat_non_gr $l_controls  i.fyear  , fe vce(robust)
			outreg2 using reg_p2_log.doc, replace ctitle(#Non-gr Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  

			xtset ffi
			xtreg ln_pat_non_gr $l_controls  i.fyear  , fe vce(robust)
			outreg2 using reg_p2_log.doc, append ctitle(#Non-gr Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  

			xtset iyfe
			xtreg ln_pat_non_gr $l_controls_nohhi  i.fyear  , fe vce(robust)
			outreg2 using reg_p2_log.doc, append ctitle(#Non-gr Patents) keep(l_fluid  l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  

			xtset gvkey
			xtreg ln_pat_non_gr $l_controls  i.fyear  , fe vce(robust)
			outreg2 using reg_p2_log.doc, append ctitle(#Non-gr Patents) keep(l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd  l_net_sales l_ch) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  

* Other stuff
tab fyear green, sum(at) means format(%9.1f)
tabstat at net_sales mb roa roe xrd, by(green) stat(mean) nototal format(%9.1g)
sum at net_sales mb roa roe xrd if green==1
tab fyear, sum(green_p) freq
tab fyear, sum(green_p) freq

local myx "x1 x2 x3 x4 x5 x6 x7 x8 x9 x10"
gen green_p=1 if p_class==242

twoway (scatter  total_appl_gr fyear), by(green)
graph bar y tempjuly, over(green)

* Average green versus other patent applications by firms
gen y=fyear-2000
graph bar total_appl_gr total_appl_other, over(y) legend( label(1 "Green Applications") label(2 "Other Applications")) title("Average Patent Application per firm in 2000s")
graph bar total_grant_gr total_grant_other, over(y) legend( label(1 "Green Grants") label(2 "Other Grants")) title("Average Patent Grants per firm in 2000s")
