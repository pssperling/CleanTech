
************************************************************************************************************ 
////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////         Lobbying + Patent Applications        ///////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
************************************************************************************************************

*1. fix truncation bias -> it is present in 18 month sfor applications and 3-4 years in grants?? (how to do it?)

					///* Lobbying + Patent Data Analysis *///

clear all
set maxvar 32767

cd "C:\Working Folder"
use lob_stats_full_yearly_90, replace


sort sic fyear
by sic fyear: egen t_sales=sum(sale)
gen prop_sale_sq=(sale/t_sales)*(sale/t_sales)
by sic fyear: egen new_hhi3=sum(prop_sale_sq)
drop t_sales prop_sale_sq
sort sich fyear
by sich fyear: egen t_sales=sum(sale)
gen prop_sale_sq=(sale/t_sales)*(sale/t_sales)
by sich fyear: egen new_hhi4=sum(prop_sale_sq)
drop t_sales prop_sale_sq
gen sic2 = floor(sic/10)
sort sic2 fyear
by sic2 fyear: egen t_sales=sum(sale)
gen prop_sale_sq=(sale/t_sales)*(sale/t_sales)
by sic2 fyear: egen new_hhi2=sum(prop_sale_sq)
drop t_sales prop_sale_sq
sum new_hhi2 new_hhi3 new_hhi4

rename hhi_3digit hhi 
drop l_hhi 
sort gvkey fyear 
by gvkey: gen l_hhi=hhi[_n-1]
label variable l_hhi "HHI"

* get cusip for all firms
drop cusip 
gen permno=PERMNO
replace year=fyear 
cd "R:\ps664\Dr_Becher - DirComp\7_add_controls\WRDS data"
merge m:1 permno year using WRDS_cusip_permno
drop if _merge==2
drop _merge
gen cusip=substr(cusip_8, 1,6)
drop year			


* adjust weird observations with negative net sales
drop if sale<0
drop if mb<0
replace sale=. if sale<0

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
merge 1:1 fyear gvkey using app_pat_yearly_updated_
keep if _merge==3 | _merge==1
drop _merge
cd "R:\ps664\Patent Applications - Michelle Michela"


* Merge with H&B fluidity measure
rename prodmktfluid prodmktfluid_17
cd "R:\ps664\Data\Fluidity"
merge m:1 gvkey year using fluidity_2019		
drop if _merge==2
drop _merge
label variable prodmktfluid "Fluidity"
cd "R:\ps664\Patent Applications - Michelle Michela"
rename prodmktfluid prodmktfluid_19
rename prodmktfluid_17 prodmktfluid

*sum total_grant_gr total_appl_gr 
*sum total_grant total_appl

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
by gvkey: gen l_capx  = capx[_n-1]
by gvkey: gen l_fluid  = prodmktfluid[_n-1]


by gvkey: gen l2_hhi=hhi[_n-2]
by gvkey: gen l2_xrd  = xrd[_n-2]
by gvkey: gen l2_ln_at  = ln_at[_n-2]
by gvkey: gen l2_ch  = ch[_n-2]
by gvkey: gen l2_mb  = mb[_n-2]
by gvkey: gen l2_roa  = roa[_n-2]
by gvkey: gen l2_capx  = capx[_n-2]
by gvkey: gen l2_fluid  = prodmktfluid[_n-2]

* Sales growth
by gvkey fyear: gen lag_sale=sale[_n-1]
gen sales_growth=(sale-lag_sale)/lag_sale
winsor2 sales_growth, cuts(1 99)  replace 
by gvkey: gen l_sales_growth  = sales_growth[_n-1]

*by gvkey: gen l_ebitda_at = ebitda[_n-1]/at[_n-1]
by gvkey: gen ebitda_at = ebitda/at

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
label variable l_capx "CAPX"

drop ffi
ffind sich, newvar(ffi) type(48)
ffind sich, newvar(ffi_12) type(12)

drop iyfe
egen iyfe=group(ffi fyear)
keep if !missing(sich)


global l_controls "l_fluid l_hhi l_ln_mkt_value l_ln_at l_xrd l_net_sales l_ch"
global l_controls_nohhi "l_fluid l_ln_mkt_value l_ln_at l_xrd l_net_sales l_ch"

cd "R:\ps664\Patent Applications - Michelle Michela\Reports\Report"


/////////////////////////////////////////////////////////////////////					
					
** Adjust all missing values from matching
					
* total_appl -  total number of applications filed by a firm this year
* total_appl_gr - total number of GREEN applications filed by a firm this year 
replace total_appl=0 if missing(total_appl)
replace total_appl_gr=0 if missing(total_appl_gr)
  
* total_grant - total n of patents filed this year  that WILL be granted 
* total_grant_gr - total n of GREEN patents filed this year  that WILL be granted
replace total_grant=0 if missing(total_grant)
replace total_grant_gr=0 if missing(total_grant_gr)

* total_grant_this_y - n of patents a firm recieved grant for this year 
* total_grant_gr_this_y - n of GREEN patents a firm recieved a grant for this year
replace total_grant_this_y=0 if missing(total_grant_this_y)
replace total_grant_gr_this_y=0 if missing(total_grant_gr_this_y)

gen total_appl_non_gr = total_appl - total_appl_gr
gen total_grant_non_gr = total_grant - total_grant_gr

			gen total_appl_other=total_appl-total_appl_gr
			gen total_grant_other=total_grant-total_grant_gr

					
* difference between total_grant_this_y and total_grant:
* total_grant_this_y - grants a firm recieved this year
* total_grant - patents a firm applied for that WILL be granted in the future (counted at application date)

* limits the sample for firms who apply for at least one green patent
gen ln_pat=log(1+total_appl)
gen ln_pat_gr=log(1+total_appl_gr)
gen ln_pat_non_gr=log(1+total_appl_non_gr)
gen ln_patgrant=log(1+total_grant)
gen ln_patgrant_gr=log(1+total_grant_gr)
gen ln_patgrant_non_gr=log(1+total_grant_non_gr)

replace did_grant_gr=0 if missing(did_grant_gr)
replace did_apply_gr=0 if missing(did_apply_gr)
replace did_apply=0 if missing(did_apply)
replace did_grant=0 if missing(did_grant)

* Use total_lob_w (for lobbying amount) and lobby_now (for whether a firm lobbied this year)

gen y = fyear - 2000

sort gvkey fyear
rename lobby lobby_ever
rename lobby_gb lobby_gb_ever
rename lobby_gb_text lobby_gb_text_ever
rename lobby_ lobby_now
rename lobby_gb_ lobby_gb_now
rename lobby_gb_text_ lobby_gb_text_now

* % of firms applying for a patent 
gen appl=1 if total_appl>0
replace appl=0 if missing(appl)
tab fyear, sum(appl)

* attrition rate (probability of a patent grant) based on firm size
gen attr=total_grant/total_appl
xtile size_q = at, nq(10)
tab size_q, sum(attr)

* separate green filers versus others
gen green=1 if total_appl_gr>0				
replace green=0 if missing(green)
gen non_green=1 if green==0 & appl==1
replace non_green=0 if missing(non_green)

* Scale Lobbying $ amount by Assets or Sales (mill/mill)
gen lobby_at=t_lob_w/at
gen lobby_gb_at=t_lob_gb_w/at
gen lobby_gb_text_at=t_lob_gb_text_w/at
gen lobby_sale=t_lob_w/sale
gen lobby_gb_sale=t_lob_gb_w/sale
gen lobby_gb_text_sale=t_lob_gb_text_w/sale
gen lobbying_probability= 1 if t_lob_w>0
replace lobbying_probability=0 if missing(lobbying_probability)

* Lags
by gvkey: gen l_lob_mktcap = t_lob_w[_n-1]/ (csho[_n-1]*prcc_f[_n-1])
by gvkey: gen l_lob_gb_mktcap = t_lob_gb_w[_n-1]/ (csho[_n-1]*prcc_f[_n-1])
by gvkey: gen l_lob_gb_text_mktcap = t_lob_gb_text_w[_n-1]/ (csho[_n-1]*prcc_f[_n-1])
by gvkey: gen l_lobby_at=lobby_at[_n-1]
by gvkey: gen l_lobby_gb_at=lobby_gb_at[_n-1]
by gvkey: gen l_lobby_gb_text_at=lobby_gb_text_at[_n-1]
by gvkey: gen l_lobby_sale=lobby_sale[_n-1]
by gvkey: gen l_lobby_gb_sale=lobby_gb_sale[_n-1]
by gvkey: gen l_lobby_gb_text_sale=lobby_gb_text_sale[_n-1]

by gvkey: gen l_t_lob_w=t_lob_w[_n-1]
by gvkey: gen l_t_lob_gb_w=t_lob_gb_w[_n-1]
by gvkey: gen l_t_lob_gb_text_w=t_lob_gb_text_w[_n-1]
by gvkey: gen l_ln_pat_gr = ln_pat_gr[_n-1]
by gvkey: gen l_ln_pat = ln_pat[_n-1]
by gvkey: gen l_ln_pat_non_gr = ln_pat_non_gr[_n-1]
by gvkey: gen l_age= age[_n-1]
by gvkey: gen l_at=at[_n-1]
by gvkey: gen l_sale=sale[_n-1]
by gvkey: gen l_total_appl=total_appl[_n-1]
by gvkey: gen l_total_grant_this_y=total_grant_this_y[_n-1]

by gvkey: gen l_total_appl_gr=total_appl_gr[_n-1]
by gvkey: gen l_total_appl_other=total_appl_other[_n-1]
by gvkey: gen l_total_grant_gr_this_y =total_grant_gr_this_y[_n-1]

* Label all variables 
label variable t_lob "Total lobbying (mill)"
label variable t_lob_gb "Total lobbying Green-Brown (mill)"
label variable t_lob_gb_text "Total lobbying Green-Brown (+ text) (mill)"
label variable ln_pat_gr "ln(1+#green patent apps)"
label variable ln_pat_non_gr "ln(1+#non-green patent apps)"
label variable l_ln_pat_gr "ln(1+#green patent apps)"
label variable l_ln_pat_non_gr "ln(1+#non-green patent apps)"
label variable l_age "Years Public"

label variable t_lob_w "Total lobbying (mill)"
label variable t_lob_gb_w "Total lobbying Green-Brown (mill)"
label variable t_lob_gb_text_w "Total lobbying Green-Brown (+ text) (mill)"
label variable l_t_lob_w "Total lobbying (mill)"
label variable l_t_lob_gb_w "Total lobbying Green-Brown (mill)"
label variable l_t_lob_gb_text_w "Total lobbying Green-Brown (+ text) (mill)"

label variable l_lobby_at "Lobbying/Assets"
label variable l_lobby_gb_at "Lobbying Green-Brown/Assets"
label variable l_lobby_gb_text_at "Lobbying Green-Brown (+ text)/Assets"
label variable l_lobby_sale "Lobbying/Sales"
label variable l_lobby_gb_sale "Lobbying Green-Brown/Sales"
label variable l_lobby_gb_text_sale "Lobbying Green-Brown (+ text)/Sales"


label variable l_age "Years Public"
label variable age "Years Public"
label variable at "Total Assets (mill)"
label variable l_at "Total Assets (mill)"
label variable sale "Sales (mill)"
label variable l_sale "Sales (mill)"

label variable ebitda_at "EBITDA/Assets"
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
label variable l_capx "CAPX"
label variable l_sale "Sales (mill)"

label variable total_appl "Patents Applied"
label variable total_appl_gr "Green Patents Applied"
label variable total_grant_this_y "Patents Granted"
label variable total_grant_gr_this_y "Green Patents Granted"
label variable total_appl_other "Other P. Applications"
label variable total_appl_gr "Green P. Applications"

label variable l_total_appl "Patents Applied"
label variable l_total_appl_gr "Green Patents Applied"
label variable l_total_grant_this_y "Patents Granted"
label variable l_total_grant_gr_this_y "Green Patents Granted"
label variable l_total_appl_other "Other P. Applications"
label variable l_total_appl_gr "Green P. Applications"



* Merge ESG data from Michela
* get cusip CRSP-Compustat firms 
cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
merge 1:1 gvkey fyear using ticker_formatted
drop if _merge==2
sort gvkey fyear
drop _merge 


* There are 8k duplicates for cusip-fyear (they're all from missing cusip => not a problem)
* Merge ESG on cusip and fyear
cd "R:\ps664\Data\ESG Data\Thompson_Reuters_sp1500"
merge m:1 cusip_8 fyear using sample_esg
drop if _merge==2 
drop _merge
rename enscore e_score_thompson

* Merge Bloomberg Data
* not a good match, only 50% with what Bloomberg says was in the S&P 1500
rename cusip cusip_6
rename cusip_8 cusip
cd "R:\ps664\Data\ESG Data\Bloomberg data"
merge m:1 cusip fyear using Bloomberg_raw_data
drop if _merge==2 
drop _merge


*** Limit all sample to S&P 1500 firms only

*keep if fyear<=2018
keep if fyear>=2000

sort gvkey fyear
by gvkey: gen l_log_sale=log(sale[_n-1])
label variable l_log_sale "log(Sales)"

by gvkey: gen l_ln_t_lob=log(t_lob_w[_n-1])
label variable l_ln_t_lob "log(Total lobbying)"
			
label variable l_t_lob_w "Total Lobbying ($)"

label variable ebitda_at "EBITDA/Assets"
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
label variable l_capx "CAPX/Assets"

sort gvkey fyear
by gvkey: gen l_green= green[_n-1]
by gvkey: gen l_lobby_now= lobby_now[_n-1]

by gvkey: gen l_apply_p=1 if l_total_appl>0
replace l_apply_p=0 if missing(l_apply_p)


global sum_stats "at ch mb roa xrd capx net_sales sale lobby_at lobby_sale total_lob_w total_appl total_appl_gr total_grant_this_y total_grant_gr_this_y prodmktfluid hhi"
global l_sum_stats "l_at l_ch l_mb l_roa l_xrd l_capx l_net_sales l_sale l_lobby_gb_at l_lobby_gb_text_at l_lobby_at l_lobby_gb_sale l_lobby_gb_text_sale l_lobby_sale l_lob_mktcap l_lob_gb_mktcap l_lob_gb_text_mktcap  l_t_lob_gb_w l_t_lob_gb_text_w l_t_lob_w l_total_appl l_total_appl_gr l_total_grant_this_y l_total_grant_gr_this_y l_fluid l_hhi"

gen my_sample2=1 if fyear>2000 & fyear<=2018 & !missing(l_capx) & sp_1500==1
replace my_sample2=0 if missing(my_sample2)

gen my_sample=1 if fyear>2000 & fyear<=2018 & !missing(l_fluid) & !missing(l_capx) & sp_1500==1
replace my_sample=0 if missing(my_sample)

gen my_sample_no1500=1 if fyear>2000 & fyear<=2018 & !missing(l_fluid) & !missing(l_capx) 
replace my_sample_no1500=0 if missing(my_sample_no1500)

gen my_sample19=1 if fyear>2000 & fyear<=2019 & !missing(l_capx) & sp_1500==1
replace my_sample19=0 if missing(my_sample2)


*keep if sp_1500==1

			sort fyear
			by fyear: egen all_gr_appl=sum(total_appl_gr)
			
			by fyear: egen all_gr_grant = sum(total_grant_gr_this_y)

			graph bar all_gr_appl all_gr_grant if y<19, over(y)  ytitle("N of patent applications") title("Total Green Applications by Public firms over time") legend( label(1 "Applied Green Patents") label(2 "Granted Green Patents") ) 
			
			
******************************* Summary Stats Tables *******************************


cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"	
	
		/* Graphs*/

keep if sp_1500==1	
/* Appendix figure A5*/		
gen bin=1 if total_appl==1 & !missing(total_appl)
replace bin=2 if total_appl>1 & total_appl<6 & !missing(total_appl)
replace bin=3 if total_appl>5 & total_appl<15 & !missing(total_appl)
replace bin=4 if total_appl>14 & total_appl<30 & !missing(total_appl)
replace bin=5 if total_appl>50 & total_appl<100 & !missing(total_appl)
replace bin=6 if total_appl>100 & total_appl<500 & !missing(total_appl)
replace bin=7 if total_appl>500 & !missing(total_appl)

gen category = "1 patent" if bin==1
replace category = "1-5 patents" if bin==2
replace category = "5-15 patents" if bin==3
replace category = "15-30 patents" if bin==4
replace category = "50-100 patents" if bin==5
replace category = "100-500 patents" if bin==6
replace category = ">500 patents" if bin==7

gen bin_gr=1 if total_appl_gr==1 & !missing(total_appl_gr)
replace bin_gr=2 if total_appl_gr>1 & total_appl_gr<6 & !missing(total_appl_gr)
replace bin_gr=3 if total_appl_gr>5 & total_appl_gr<15 & !missing(total_appl_gr)
replace bin_gr=4 if total_appl_gr>14 & total_appl_gr<30 & !missing(total_appl_gr)
replace bin_gr=5 if total_appl_gr>50 & total_appl_gr<100 & !missing(total_appl_gr)
replace bin_gr=6 if total_appl_gr>100 & total_appl_gr<500 & !missing(total_appl_gr)
replace bin_gr=7 if total_appl_gr>500 & !missing(total_appl_gr)

gen category_gr = "1 patent" if bin_gr==1
replace category_gr = "1-5 patents" if bin_gr==2
replace category_gr = "5-15 patents" if bin_gr==3
replace category_gr = "15-30 patents" if bin_gr==4
replace category_gr = "50-100 patents" if bin_gr==5
replace category_gr = "100-500 patents" if bin_gfr==6
replace category_gr = ">500 patents" if bin_gr==7


graph bar (count), over(category, lab(angle(45))) bar(1, color( navy)) ytitle("N of Firms Applying for Patents" " ") title("Patenting Frequency per Firm-Year")


graph bar (count), over(category_gr, lab(angle(45))) bar(1, color( navy)) ytitle("N of Firms Applying for Patents" " ") title("Green Patenting Frequency per Firm-Year")

		
/* Figure 1 - Size */

xtile quart_1 = l_ln_at, nq(10)
gen apply_p=1 if total_appl>0
replace apply_p=0 if missing(apply_p)

* Panel A - patenting ny decile
graph bar apply_p, over(quart_1)  ytitle("% of Firms Applying for Patents") title("Patenting by firm size decile")
graph bar total_appl, over(quart_1)  ytitle("N of Patent Applications") title("Patenting by firm size decile")


* Panel B - green patents by decile
graph bar green, over(quart_1)  ytitle("% of Firms Applying for Green Patents") title("Green patenting by firm size decile")
graph bar total_appl_gr, over(quart_1)  ytitle("N of Green Patent Applications") title("Green patenting by firm size decile")


* Panel C - lobbying by decile
graph bar lobby_gb_now, over(quart_1)  ytitle("% of Firms Lobbying") title("Firm Lobbying by firm size decile")
graph bar lobby_gb_text_now, over(quart_1)  ytitle("% of Firms Lobbying") title("Firm Lobbying by firm size decile")

graph bar t_lob_gb_w, over(quart_1)  ytitle("Firm Lobbying (mill)") title("Total $ Lobbying by firm size decile")
graph bar t_lob_gb_text_w, over(quart_1)  ytitle("Firm Lobbying (mill)") title("Total $ Lobbying by firm size decile")

/* Figure 2 - Competition */

* Relation between Competition and innovation is endogenous, we can't say anything without an exogenous shock to competition

xtile quart_comp1 = l_fluid, nq(10)
xtile quart_comp2 = (-1)*l_hhi, nq(10)

* A
graph bar apply_p, over(quart_comp2)  ytitle("% of Firms Applying for Patents") title("Patenting by Competition Decile")
graph bar total_appl, over(quart_comp2)  ytitle("N of Patent Applications") title("Patenting by Competition Decile")
* B
graph bar green, over(quart_comp2)  ytitle("% of Firms Applying for Green Patents") title("Green Patenting by Competition Decile")
graph bar total_appl_gr, over(quart_comp2)  ytitle("N of Green Patent Applications") title("Green Patenting by Competition Decile")
* C
graph bar lobby_gb_now, over(quart_comp2)  ytitle("% of Firms Lobbying") title("Firm Lobbying by Competition Decile")
graph bar lobby_gb_text_now, over(quart_comp2)  ytitle("% of Firms Lobbying") title("Firm Lobbying by Competition Decile")
graph bar t_lob_gb_w, over(quart_comp2)  ytitle("Firm Lobbying ($mill)") title("Firm Lobbying by Competition Decile")
graph bar t_lob_gb_text_w, over(quart_comp2)  ytitle("Firm Lobbying ($mill)") title("Firm Lobbying by Competition Decile")



/* Figure 3 - Fluidity */


* Panel A
*fluidity is only until 2015
graph bar apply_p if fyear<=2018, over(quart_comp1)  ytitle("% of Firms Applying for Patents") title("Patenting by Fluidity decile")
graph bar total_appl if fyear<=2018, over(quart_comp1)  ytitle("N of Patent Applications") title("Patenting by Fluidity decile")


* Panel B
*this graph doesn't show the slope -> I took the one from patenting data code instead
graph bar green if fyear<=2018, over(quart_comp1)  ytitle("% of Firms Applying for Green Patents") title("Green patenting by Fluidity decile")
graph bar total_appl_gr if fyear<=2018, over(quart_comp1)  ytitle("N of Green Patent Applications") title("Patenting by Fluidity decile")


* Panel C
graph bar lobby_gb_now if fyear<=2018, over(quart_comp1)  ytitle("% of Firms Lobbying") title("Firm Lobbying by Fluidity decile")
graph bar lobby_gb_text_now if fyear<=2018, over(quart_comp1)  ytitle("% of Firms Lobbying") title("Firm Lobbying by Fluidity decile")
graph bar t_lob_gb_w if fyear<=2018, over(quart_comp1)  ytitle("Firm Lobbying (mill)") title("Total $ Lobbying by firm Fluidity decile")
graph bar t_lob_gb_text_w if fyear<=2018, over(quart_comp1)  ytitle("Firm Lobbying (mill)") title("Total $ Lobbying by firm Fluidity decile")


			* Figure 1, Panel B
			
keep if sp_1500==1

graph bar total_appl_gr if fyear<=2018, over(fyear)  ytitle("% of Firms Applying for Green Patents") title("Green patenting by Fluidity decile")

			
hist green_contrib_year, xtitle("% of firm lobbyists' contribution to the Democratic Party")  title("Firm level Distribution" " of Lobbyists' Political Contributions")


hist green_contrib_year, percent ytitle("% of Firms")  fcolor(eltblue) xtitle("% of firm lobbyists' contribution to the Democratic Party")  title("Firm level Distribution" " of Lobbyists' Political Contributions")

hist green_contrib_year, frequency ytitle("N of Firms")  fcolor(eltblue) xtitle("% of firm lobbyists' contribution to the Democratic Party")  title("Firm level Distribution" " of Lobbyists' Political Contributions")

hist prop_D, percent	fcolor(eltblue) ytitle("% of Lobbyists")  xtitle("% of a Lobbyist's Contributions to the Democratic Party") title("Distribution of Lobbyists' Political Contributions")		

hist prop_D, frequency	fcolor(eltblue) ytitle("N of Lobbyists")  xtitle("% of a Lobbyist's Contributions to the Democratic Party") title("Distribution of Lobbyists' Political Contributions")		
			

		/* Table 4 - sample composition (right column) */

cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"	

sum l_t_lob

keep if sp_1500==1
sum l_t_lob

* line 15, lobby code
sum l_t_lob_w  if code_has==1
sum l_t_lob_w if lobby_green ==1
sum t_lob_w if  code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  
sum t_lob_w if lobby_green ==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  

* line 16, congress.gov
sum l_t_lob_w  if  bill_yes_year==1
sum l_t_lob_w if  green_cong_gov ==1
sum l_t_lob_w if maybe_green_cong_gov==1
sum l_t_lob_w if  green_cong_gov ==1 | maybe_green_cong_gov==1

* both 
sum l_t_lob_w if  green_cong_gov ==1 | lobby_green ==1
sum l_t_lob_w if  maybe_green_cong_gov ==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  
sum l_t_lob_w if green_cong_gov ==1 | lobby_green ==1 | maybe_green_cong_gov ==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  

* text
sum l_t_lob_w if  lobby_green_text ==1 & green_cong_gov ==0 &  lobby_green ==0
sum l_t_lob_w if lobby_green_text ==1  

* with patents 
sum l_t_lob_w if lobby_green_text ==1   & l_ln_pat_gr>0

*check
sum l_total_appl l_total_grant_this_y l_total_appl_gr l_total_grant_gr_this_y if my_sample==1 & l_apply_p==1
sum total_appl_gr total_grant_gr total_appl total_grant if my_sample==1 & l_apply_p==1


			
			/* Table 1 - Sum Green vs Other patents*/

cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"	

* # Lobbying transactions/year row
sum  total_ld2
sum  total_ld2 if total_appl>0
sum  total_ld2 if total_appl_gr>0
sum  total_ld2 if t_lob>0
sum  total_ld2 if t_lob_gb>0

* # Lobbying Green-Brown transactions/year row
sum  total_ld2_gb
sum  total_ld2_gb if total_appl>0
sum  total_ld2_gb if total_appl_gr>0
sum  total_ld2_gb if t_lob>0
sum  total_ld2_gb if t_lob_gb>0

 
* report in %
replace  l_lobby_at =l_lobby_at*1000000
replace  l_lobby_gb_at =l_lobby_gb_at*1000000
replace  l_lobby_gb_text_at =l_lobby_gb_text_at*1000000
replace  l_lobby_sale =l_lobby_sale*1000000
replace  l_lobby_gb_sale =l_lobby_gb_sale*1000000
replace  l_lobby_gb_text_sale =l_lobby_gb_text_sale*1000000
replace  l_lob_mktcap =l_lob_mktcap*1000000
replace  l_lob_gb_mktcap =l_lob_gb_mktcap*1000000
replace  l_lob_gb_text_mktcap =l_lob_gb_text_mktcap*1000000

* Full Sample
outreg2 using table_0.doc if my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel A - Firms that filed for ANY patents this year") sortvar($l_sum_stats) noni

* Any patent		
outreg2 using table_1a.doc if l_apply_p==1 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel A - Firms that filed for ANY patents this year") sortvar($l_sum_stats) noni
* Green patent
outreg2 using table_1b.doc if l_green==1 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel B - Firms that filed for GREEN patents this year") sortvar($l_sum_stats) noni

* No patent
outreg2 using table_1c.doc if l_apply_p==0 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel C - Firms that filed for NO patents this year") sortvar($l_sum_stats) noni

gen total_lob_assets = t_lob/at
gen total_lob_assets_gb = t_lob_gb/at
gen total_lob_assets_gb_text = t_lob_gb_text/at

by gvkey: gen l_lobbying_firm=1 if total_lob_assets[_n-1]>0
replace l_lobbying_firm=0 if missing(l_lobbying_firm)

by gvkey: gen l_lobbying_firm_gb=1 if total_lob_assets_gb[_n-1]>0
replace l_lobbying_firm_gb=0 if missing(l_lobbying_firm_gb)

by gvkey: gen l_lobbying_firm_gb_text=1 if total_lob_assets_gb_text[_n-1]>0
replace l_lobbying_firm_gb_text=0 if missing(l_lobbying_firm_gb_text)


* lobby 
outreg2 using table_2a.doc if l_lobbying_firm==1 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel A - Firms that lobby this year")  sortvar($l_sum_stats) noni
* lobby on green/brown +text
outreg2 using table_2b_text.doc if l_lobbying_firm_gb_text==1 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel A - Firms that lobby this year")  sortvar($l_sum_stats) noni
* lobby on green/brown 
outreg2 using table_2b.doc if l_lobbying_firm_gb==1 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel A - Firms that lobby this year")  sortvar($l_sum_stats) noni
* not lobbying
outreg2 using table_2c.doc if l_lobbying_firm==0 & my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel B - Firms that do NOT lobby this year")  sortvar($l_sum_stats) noni

drop total_lob_assets total_lob_assets total_lob_assets_gb_text 



			/* Table 3 - By Industry*/

global interesting " l_total_appl l_total_appl_gr l_total_grant_this_y l_total_grant_gr_this_y l_t_lob_w l_fluid l_hhi"			
tabstat $interesting if my_sample==1, by(ffi_12) stat(mean p50) nototal format(%9.1g)

* figure patenting and lobbying fraction per industry 

sort ffi_12 
gen p_applicant=1 if total_appl>0
gen ld2_applicant=1 if t_lob_w>0
replace p_applicant=0 if missing(p_applicant)
replace ld2_applicant=0 if missing(ld2_applicant)

gen p_applicant_g=1 if total_appl_gr>0
replace p_applicant_g=0 if missing(p_applicant_g)
gen ld2_applicant_g=1 if t_lob_gb_text>0
replace ld2_applicant_g=0 if missing(ld2_applicant_g)



gen ind="Consumer Non-Durables" if ffi_12==1
replace ind="Consumer Durables" if ffi_12==2
replace ind="Manufacturing" if ffi_12==3
replace ind="Oil, Gas, and Coal Extraction" if ffi_12==4
replace ind="Chemicals and Allied Products" if ffi_12==5
replace ind="Business Equipment" if ffi_12==6
replace ind="Telephone and Telecom" if ffi_12==7
replace ind="Wholesale, Retail, and Some Services" if ffi_12==9
replace ind="Healthcare, Med. Equipment, and Drug" if ffi_12==10
replace ind="Other" if ffi_12==12


label variable p_applicant "% of Firms that file Patents"
label variable ld2_applicant "% of Firms that lobby"

graph hbar p_applicant ld2_applicant  , over(ind, sort(1) descending  relabel(`r(ind)') label(labsize(small)) ) bar(1, color( gray)) bar( 2 ,color(eltblue)) title("Industry distribution of Lobbying and Patenting" " ", span size(medium))  legend(label(1 "% of firms filing patents") label(2 "% of firms lobbying") rows(1) stack size(small))  

keep if sp_1500==1

ssc install splitvallabels
splitvallabels ind
graph hbar p_applicant ld2_applicant  , over(ind, sort(1) descending  relabel(`r(ind)') label(labsize(small)) ) bar(1, color( gray)) bar( 2 ,color(eltblue)) title("Industry distribution of Lobbying and Patenting" " ", span size(medium))  legend(label(1 "% of firms filing patents") label(2 "% of firms lobbying") rows(1) stack size(small))  

graph hbar p_applicant_g ld2_applicant_g  , over(ind, sort(1) descending  relabel(`r(ind)') label(labsize(small))) bar(1, color( gray)) bar( 2 ,color(eltblue)) title("Industry distribution of Green/Brown Lobbying and Patenting" " ", span size(medium))  legend(label(1 "% of firms" "filing green patents") label(2 "% of firms" "lobbying green/brown") size(small)  rows(1) stack)
 rows(1) stack size(small)))  





			/* Table 4 - Overlap between lobbying and patents */

sort gvkey fyear 
by gvkey: gen l_csho = csho[_n-1]
by gvkey: gen l_prcc_f = prcc_f[_n-1]
by gvkey: gen l_green_contrib_year = green_contrib_year[_n-1]
by gvkey: gen l2_green = l_green[_n-1]
gen grant_green=1 if total_grant_gr>0 				
by gvkey: gen l_grant_green = grant_green[_n-1]
by gvkey: gen l2_grant_green = grant_green[_n-2]
replace l_grant_green=0 if missing(l_grant_green) 
replace l2_grant_green=0 if missing(l2_grant_green) 
* scaled by 1000
gen amount_mktcap = l_t_lob_gb_text_w *1000/(l_csho*l_prcc_f)

		gen amount_mktcap_dem = amount_mktcap if l_green_contrib_year>0.5 & !missing(l_green_contrib_year)
		gen amount_mktcap_rep = amount_mktcap if l_green_contrib_year<0.5 & !missing(l_green_contrib_year)

		gen dem_amount = t_lob_dem_gr  if l_green_contrib_year>0.5 & !missing(l_green_contrib_year)
		gen rep_amount = t_lob_rep_gr  if t_lob_rep_gr>0 & !missing(l_green_contrib_year)

*rop amount_mktcap amount_mktcap_dem amount_mktcap_rep dem_amount rep_amount 


* Columns 1-2 - any lobbying
* all firm-years that patent
sum l_t_lob_w if my_sample ==1  & l_ln_pat>0 
* all firm-years that lobby 
sum l_t_lob_w if my_sample ==1  & l_t_lob_w>0 
* all firm-years that patent and lobby
sum l_t_lob_w if my_sample ==1  & l_ln_pat>0 & l_t_lob_w>0


* firms that patent (sample size in Table 5)
sum l_t_lob_gb_text if my_sample ==1 & l_ln_pat_gr>0  
* firms that lobby 
sum l_t_lob_gb_text if my_sample ==1 & l_t_lob_gb_text>0  
* firms that patent and lobby (N of Dep vars)
sum l_t_lob_gb_text if my_sample ==1 & l_ln_pat_gr>0 & t_lob_gb_text>0

winsor2 t_lob_rep, cuts(1 99)  
winsor2 t_lob_dem, cuts(1 99)  
winsor2 t_lob_rep_gr, cuts(1 99)  
winsor2 t_lob_dem_gr, cuts(1 99)  

* Columns 1-2 - Dem versus Rep 
sum t_lob_dem_w if my_sample ==1  & l_ln_pat>0  
sum t_lob_dem_w if my_sample ==1  & t_lob_dem_w>0  
sum t_lob_dem_w if my_sample ==1 & l_ln_pat>0 & t_lob_dem_w>0 

sum t_lob_rep_w if my_sample ==1  & l_ln_pat>0  
sum t_lob_rep_w if my_sample ==1  & t_lob_rep_w>0  
sum t_lob_rep_w if my_sample ==1 & l_ln_pat>0 & t_lob_rep_w>0 

sum t_lob_dem_gr_w if my_sample ==1  & l_ln_pat_gr>0  
sum t_lob_dem_gr_w if my_sample ==1  & t_lob_dem_gr_w>0  
sum t_lob_dem_gr_w if my_sample ==1 & l_ln_pat_gr>0 & t_lob_dem_gr_w>0 

sum t_lob_rep_gr_w if my_sample ==1  & l_ln_pat_gr>0  
sum t_lob_rep_gr_w if my_sample ==1  & t_lob_rep_gr_w>0  
sum t_lob_rep_gr_w if my_sample ==1 & l_ln_pat_gr>0 & t_lob_rep_gr_w>0 


* firms that lobby and patent green 
sum l_t_lob_gb_text if my_sample ==1 & l_ln_pat_gr>0 & t_lob_gb_text>0


* Old table:

gen lob_yes_contrib=l_t_lob_gb_w if !missing(l_green_contrib_year)
gen am_mcap_yes_contrib=amount_mktcap if !missing(l_green_contrib_year)


* all
sum l_t_lob_gb_w lob_yes_contrib dem_amount rep_amount  amount_mktcap am_mcap_yes_contrib amount_mktcap_dem amount_mktcap_rep if l_lobbying_firm_gb_text==1 &  my_sample==1  

* cond on >1 green patent application in t
sum l_t_lob_gb_w lob_yes_contrib am_mcap_yes_contrib dem_amount rep_amount  amount_mktcap amount_mktcap_dem amount_mktcap_rep  if l_lobbying_firm_gb_text==1 & my_sample==1 & l_green==1
* cond on >1 green patent application in t-1
sum l_t_lob_gb_w dem_amount lob_yes_contrib am_mcap_yes_contrib rep_amount  amount_mktcap amount_mktcap_dem amount_mktcap_rep  if l_lobbying_firm_gb_text==1 & my_sample==1 & l2_green==1
* cond on >1 green patent grant in t
sum l_t_lob_gb_w dem_amount lob_yes_contrib am_mcap_yes_contrib rep_amount  amount_mktcap amount_mktcap_dem amount_mktcap_rep  if l_lobbying_firm_gb_text==1 & my_sample==1 & l_grant_green==1
* cond on >1 green patent grant in t-1
sum l_t_lob_gb_w dem_amount lob_yes_contrib am_mcap_yes_contrib  rep_amount  amount_mktcap amount_mktcap_dem amount_mktcap_rep  if l_lobbying_firm_gb_text==1 & my_sample==1 & l2_grant_green==1
*conditional on patent denial in t
sum l_t_lob_gb_w lob_yes_contrib am_mcap_yes_contrib  dem_amount rep_amount  amount_mktcap amount_mktcap_dem amount_mktcap_rep  if l_lobbying_firm_gb_text==1 & my_sample==1 & l_grant_green==0 & l_green==1
*conditional on patent denial in t-1
sum l_t_lob_gb_w lob_yes_contrib am_mcap_yes_contrib  dem_amount rep_amount  amount_mktcap amount_mktcap_dem amount_mktcap_rep  if l_lobbying_firm_gb_text==1 & my_sample==1 & l2_grant_green==0 & l2_green==1


*estpost tabstat $l_sum_stats if my_sample==1, by(ffi) statistics(mean) columns(statistics)
*esttab . using table_2_ffi.rtf, replace cells("mean(fmt(a3))") unstack 

* From % reported for tables back to decimals
replace  l_lobby_at =l_lobby_at/100
replace  l_lobby_gb_at =l_lobby_gb_at/100
replace  l_lobby_gb_text_at =l_lobby_gb_text_at/100
replace  l_lobby_sale =l_lobby_sale/100
replace  l_lobby_gb_sale =l_lobby_gb_sale/100
replace  l_lobby_gb_text_sale =l_lobby_gb_text_sale/100
replace  l_lob_mktcap =l_lob_mktcap/100
replace  l_lob_gb_mktcap =l_lob_gb_mktcap/100
replace  l_lob_gb_text_mktcap =l_lob_gb_text_mktcap/100



*** Email questions on Patents Distribution 

by gvkey: gen l_frac_approved = total_grant_gr[_n-1]/ total_appl_gr[_n-1] 
by gvkey: gen l_frac_approved_all= total_grant[_n-1]/ total_appl[_n-1]

by gvkey: gen t_granted_gr =  total_grant_gr[_n-1]
by gvkey: gen t_applied_gr =  total_appl_gr[_n-1]

by gvkey: gen t_granted =  total_grant[_n-1]
by gvkey: gen t_applied =  total_appl[_n-1]

label variable t_applied "Total Patent Applications"
label variable t_granted "Total Patent Grants"
label variable t_applied_gr "Total Green Patent Applications"
label variable t_granted_gr "Total Green Patent Grants"

*1 
hist t_applied if my_sample==1, percent
hist t_granted if my_sample==1, percent

hist t_applied_gr if my_sample==1, percent
hist t_granted_gr if my_sample==1, percent

sum t_granted t_applied if my_sample==1, detail
sum t_granted_gr t_applied_gr if my_sample==1 , detail

*2 
hist t_applied if my_sample==1 & t_applied>0, percent
hist t_granted if my_sample==1 & t_applied>0, percent
hist t_applied_gr if my_sample==1 & t_applied_gr>0, percent
hist t_granted_gr if my_sample==1 & t_applied_gr>0, percent

sum t_granted t_applied if my_sample==1 & t_applied>0, detail
sum t_granted_gr t_applied_gr if my_sample==1 & t_applied_gr>0, detail

*3

sum l_frac_approved l_frac_approved_all
sum t_granted_gr t_applied_gr

*sum total_grant_gr total_appl_gr 
*sum total_grant total_appl


			
******************************* Regressions *******************************

cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"	


			/* Table 5 - Determinants of Green Patenting*/


*sort gvkey fyear
*by gvkey: gen l_log_sale=log(sale[_n-1])
label variable l_log_sale "log(Sales)"


global l_controls "l_fluid l_hhi l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_nohhi "l_fluid l_xrd l_ln_at l_mb l_roa l_ch l_capx"

replace l_hhi = l_hhi * (-1)
label variable l_hhi "Competition"
label variable l_capx "CAPX/Assets"

egen m_hhi=median(l_hhi)
egen m_fluid=median(l_fluid)

gen high_hhi=1 if l_hhi>m_hhi 
replace high_hhi=0 if missing(high_hhi)

gen high_fluid=1 if l_fluid>m_fluid 
replace high_fluid=0 if missing(high_fluid)

label variable high_fluid "High Fluidity"
label variable high_hhi "High Comp."




* Table 5A - Determinants of patents  

* total_cites_scaled OR ln_pat

* 1
global l_controls_nofluid "l_hhi l_xrd l_ln_at l_mb l_roa l_ch l_capx"
replace total_cites_scaled_gr=0 if missing(total_cites_scaled_gr)

xtset fyear
xtreg ln_pat $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_4.doc, replace ctitle("ln(1+# Patents)") title("Table 4 - Determinants of Firm Patenting") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg ln_pat $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_4.doc, append ctitle("ln(1+# Patents)") keep( $l_controls_nohhi) sortvar(l_hhi $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg ln_pat $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_4.doc, append ctitle("ln(1+# Patents)")  keep($l_controls) sortvar(l_hhi high_hhi high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 4 

global h_controls_nohhi "high_fluid l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_nofluid  "high_hhi l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi high_fluid l_ln_at l_xrd l_mb l_roa l_ch l_capx"

xtset fyear
xtreg ln_pat $h_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_4.doc, append ctitle("ln(1+# Patents)")  keep($h_controls_nofluid)   addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 5
xtset fyear
xtreg ln_pat $h_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_4.doc, append ctitle("ln(1+# Patents)")  keep($h_controls_nohhi)   addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg ln_pat $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_4.doc, append ctitle("ln(1+# Patents)")  keep(l_hhi l_fluid high_hhi high_fluid $h_controls_both) sortvar(l_hhi l_fluid high_hhi high_fluid $h_controls_both)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 




* Table 5B - Determinants of Green patents  

* total_cites_scaled_gr OR ln_pat_gr
xtset fyear
xtreg ln_pat_gr $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_5.doc, replace ctitle("ln(1+#Green Patents)") title("Table 5 - Determinants of Green Patenting") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg ln_pat_gr $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("ln(1+#Green Patents)")  keep( $l_controls_nohhi) sortvar(l_hhi $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg ln_pat_gr $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("ln(1+#Green Patents)")  keep($l_controls) sortvar(l_hhi high_hhi high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 4 

global h_controls_nohhi "high_fluid l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_nofluid  "high_hhi l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi high_fluid l_ln_at l_xrd l_mb l_roa l_ch l_capx"

xtset fyear
xtreg ln_pat_gr $h_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("ln(1+#Green Patents)") keep($h_controls_nofluid)   addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 5
xtset fyear
xtreg ln_pat_gr $h_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("ln(1+#Green Patents)")  keep($h_controls_nohhi)   addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg ln_pat_gr $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("ln(1+#Green Patents)") keep(l_hhi l_fluid high_hhi high_fluid $h_controls_both) sortvar(l_hhi l_fluid high_hhi high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 


			/* Table 6 - Determinants of Lobbying*/

* !!!!!!!!!!!!!!!!!!
*keep if sp_1500==1			
			
*drop total_lob_assets_gb			
gen total_lob_assets_gb = t_lob_gb/at
gen total_lob_assets_gb_text = t_lob_gb_text/at
gen total_lob_assets = t_lob/at
gen total_lob_sale_gb = t_lob_gb/sale
gen total_lob_sale_gb_text = t_lob_gb_text/sale
gen total_lob_sale = t_lob/sale
gen total_lob_sale_gb_maybe = t_lob_gb_maybe/sale
gen total_lob_sale_gb_text_maybe = t_lob_gb_text_maybe/sale
gen total_lob_sale_not_gb = t_lob_not_gb/sale
gen total_lob_sale_not_maybe_gb = t_lob_not_maybe_gb/sale

			replace t_lob_rep_gr=t_lob_rep_gr/1000000
			replace t_lob_dem_gr=t_lob_dem_gr/1000000
			replace t_lob_mid_gr=t_lob_mid_gr/1000000
			
			*winsor2 t_lob_rep_gr, cuts(1 99) replace 
			*winsor2 t_lob_dem_gr, cuts(1 99) replace 
			*winsor2 t_lob_mid_gr, cuts(1 99) replace 


gen total_lob_sale_gb_rep = t_lob_rep_gr/sale
gen total_lob_sale_gb_dem = t_lob_dem_gr/sale
gen total_lob_sale_gb_mid = t_lob_mid_gr/sale
gen total_lob_sale_rep = t_lob_rep/sale
gen total_lob_sale_dem = t_lob_dem/sale
gen total_lob_sale_mid = t_lob_mid/sale

gen total_lob_assets_gb_rep = t_lob_rep_gr/at
gen total_lob_assets_gb_dem = t_lob_dem_gr/at
gen total_lob_assets_gb_mid = t_lob_mid_gr/at
gen total_lob_assets_gb_rep_y = t_lob_rep_gr_y/at
gen total_lob_assets_gb_dem_y = t_lob_dem_gr_y/at
gen total_lob_assets_gb_mid_y = t_lob_mid_gr_y/at
gen total_lob_assets_rep = t_lob_rep/at
gen total_lob_assets_dem = t_lob_dem/at
gen total_lob_assets_mid = t_lob_mid/at

gen total_lob_assets_rep_rep = t_lob_rep_rep/at
gen total_lob_assets_rep_dem = t_lob_rep_dem/at
gen total_lob_assets_dem_dem = t_lob_dem_dem/at
gen total_lob_assets_dem_rep = t_lob_dem_rep/at

gen total_lob_assets_rep_bill = t_lob_rep_bill/at
gen total_lob_assets_dem_bill = t_lob_dem_bill/at

gen total_lob_assets_rep_prop = prop_rep_amount/at
gen total_lob_assets_dem_prop = prop_dem_amount/at

gen total_lob_assets_dem_mid = t_lob_dem_mid/at
gen total_lob_assets_rep_mid = t_lob_rep_mid/at

*winsor2 total_lob_assets_rep_rep, cuts(1 99) replace 
*winsor2 total_lob_assets_rep_dem, cuts(1 99) replace 
*winsor2 total_lob_assets_dem_dem, cuts(1 99) replace 
*winsor2 total_lob_assets_dem_rep, cuts(1 99) replace 

winsor2 total_lob_assets_gb, cuts(1 99) replace 
winsor2 total_lob_assets_gb_text, cuts(1 99) replace 
winsor2 total_lob_assets, cuts(1 99) replace 
winsor2 total_lob_sale_gb, cuts(1 99) replace 
winsor2 total_lob_sale_gb_text, cuts(1 99) replace 
winsor2 total_lob_sale, cuts(1 99) replace 
winsor2 total_lob_sale_gb_maybe, cuts(1 99) replace 
winsor2 total_lob_sale_gb_text_maybe, cuts(1 99) replace 
winsor2 total_lob_sale_not_gb, cuts(1 99) replace 
winsor2 total_lob_sale_not_maybe_gb, cuts(1 99) replace 

winsor2 total_lob_assets_gb_rep, cuts(1 99) replace 
winsor2 total_lob_assets_gb_dem, cuts(1 99) replace 
winsor2 total_lob_assets_gb_mid, cuts(1 99) replace 

winsor2 total_lob_assets_gb_rep_y, cuts(1 99) replace 
winsor2 total_lob_assets_gb_dem_y, cuts(1 99) replace 
winsor2 total_lob_assets_gb_mid_y, cuts(1 99) replace 

			
*winsor2 total_lob_sale_rep, cuts(1 99) replace 
*winsor2 total_lob_sale_dem, cuts(1 99) replace 
*winsor2 total_lob_sale_mid, cuts(1 99) replace 

*winsor2 total_lob_assets_gb_rep, cuts(1 99) replace 
*winsor2 total_lob_assets_gb_dem, cuts(1 99) replace 
*winsor2 total_lob_assets_gb_mid, cuts(1 99) replace 
*winsor2 total_lob_assets_rep, cuts(1 99) replace 
*winsor2 total_lob_assets_dem, cuts(1 99) replace 
*winsor2 total_lob_assets_mid, cuts(1 99) replace 

replace total_lob_sale_gb=total_lob_sale_gb*100000
replace total_lob_sale_gb_text=total_lob_sale_gb_text*100000
replace total_lob_sale=total_lob_sale*100000
replace total_lob_sale_gb_maybe=total_lob_sale_gb_maybe*100000
replace total_lob_sale_gb_text_maybe=total_lob_sale_gb_text_maybe*100000
replace total_lob_sale_not_gb=total_lob_sale_not_gb*100000
replace total_lob_sale_not_maybe_gb=total_lob_sale_not_maybe_gb*100000

        
replace total_lob_assets_gb_text=total_lob_assets_gb_text*100000
replace total_lob_assets_gb=total_lob_assets_gb*100000
replace total_lob_assets=total_lob_assets*100000

replace total_lob_assets_gb_rep=total_lob_assets_gb_rep*100000
replace total_lob_assets_gb_dem=total_lob_assets_gb_dem*100000
replace total_lob_assets_gb_mid=total_lob_assets_gb_mid*100000


gen ln_rep = ln(1+total_lob_assets_gb_rep) 
gen ln_dem = ln(1+total_lob_assets_gb_dem)
gen ln_mid = ln(1+total_lob_assets_gb_mid)

gen ln_total_gb=ln(1+total_lob_assets_gb_text)
gen ln_total=ln(1+total_lob_assets)


*replace total_lob_sale_rep=total_lob_sale_rep*100000
*replace total_lob_sale_dem=total_lob_sale_dem*100000
*replace total_lob_sale_mid=total_lob_sale_mid*100000

* % of firms in industry with patent application this year 
sort ffi fyear
drop n
gen n=1
by ffi fyear: egen all_applicants = sum(did_apply)
by ffi fyear: egen all_firms = sum(n)
gen patenting_intens = all_applicants/all_firms
sort gvkey fyear 
by gvkey: gen l_patenting_intens=patenting_intens[_n-1]
drop n 

sort ffi fyear
by ffi fyear: egen all_applicants_g = sum(did_apply_gr)
sort gvkey fyear 
by gvkey: gen l_patenting_intens_g=all_applicants_g[_n-1]/all_firms[_n-1]


global l_controls_new  " l_ln_pat_gr l_ln_pat_non_gr l_fluid l_hhi  l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_new_nohhi  " l_ln_pat_gr l_ln_pat_non_gr l_fluid  l_ln_at l_xrd l_mb l_roa l_ch l_capx"
label variable l_ln_pat_non_gr "ln(1+ # other patent apps)"


global l_controls "l_fluid l_hhi l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_nohhi "l_fluid l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global l_controls_nofluid "l_hhi l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"

global h_controls_nohhi "high_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_nofluid  "high_hhi l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi high_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"

label variable l_patenting_intens "Patenting Intensity"
label variable l_patenting_intens_g "Green Patenting Intensity"
label variable high_fluid "High Fluidity"


* Table 6A - Determinants of lobbying  

sort gvkey fyear
by gvkey: gen l_new_hhi2=new_hhi2[_n-1]
by gvkey: gen l_new_hhi3=new_hhi3[_n-1]
by gvkey: gen l_new_hhi4=new_hhi4[_n-1]

replace l_new_hhi2= l_new_hhi2 * (-1)
replace l_new_hhi3= l_new_hhi3 * (-1)
replace l_new_hhi4= l_new_hhi4 * (-1)
label variable l_new_hhi3  "Competition"


egen m_hhi2=median(l_new_hhi2) if my_sample==1
egen m_hhi3=median(l_new_hhi3) if my_sample==1
egen m_hhi4=median(l_new_hhi4) if my_sample==1

gen high_hhi2=1 if l_new_hhi2>m_hhi2 
replace high_hhi2=0 if missing(high_hhi2)
gen high_hhi3=1 if l_new_hhi3>m_hhi3 
replace high_hhi3=0 if missing(high_hhi3)
gen high_hhi4=1 if l_new_hhi4>m_hhi4 
replace high_hhi4=0 if missing(high_hhi4)
drop m_hhi2 m_hhi3 m_hhi4

gen Grotteria=1 if ffi==11 | ffi==13 | ffi==26
replace Grotteria=0 if missing(Grotteria)


* Table 5 
global l_controls "l_new_hhi3 l_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi3 high_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"

xtset fyear
xtreg total_lob_assets $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, replace ctitle(Lobbying$ /Assets)  keep($l_controls) sortvar(l_new_hhi3 high_hhi3 high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

xtset fyear
xtreg total_lob_assets $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep(l_new_hhi2 l_fluid high_hhi2 high_fluid $h_controls_both) sortvar(l_new_hhi3 l_fluid high_hhi3 high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

global l_controls "l_new_hhi3 l_fluid l_patenting_intens_g l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi3 high_fluid l_patenting_intens_g l_ln_at l_xrd l_mb l_roa l_ch l_capx"
xtset fyear
xtreg total_lob_assets_gb_text $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Green-Brown Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($l_controls) sortvar($l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

xtset fyear
xtreg total_lob_assets_gb_text $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep(l_hhi l_fluid high_hhi high_fluid $h_controls_both) sortvar(l_hhi l_fluid high_hhi high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 


* New Table 5 - Michelle asked

sort ffi fyear 
by ffi fyear: egen ind_sales = sum(sale)
gen market_sh=sale / ind_sales
sort gvkey fyear 
by gvkey: gen l_market_sh=market_sh[_n-1]

* size has a negative effect on proportion of lobbying 

global m_controls "l_market_sh l_fluid l_ln_pat l_ln_at l_xrd l_mb l_roa l_ch l_capx"

xtset fyear
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)

xtset ffi
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)

xtset iyfe
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)

xtset gvkey
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)

label variable l_market_sh "Market Share"
label variable l_ln_pat "ln(1+# Pat. Appl.)"
label variable l_ln_pat_gr "ln(1+# Green Pat. Appl.)"
* Any
global m_controls " l_market_sh l_fluid l_ln_pat l_ln_at l_xrd l_mb l_roa l_ch l_capx"
xtset fyear
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M.doc, replace ctitle(Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($m_controls) sortvar($m_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   bdec(3) cdec(3) pdec(3) tdec(3) nocons 

xtset ffi
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M.doc, append ctitle(Lobbying$ /Assets)  keep( $m_controls) sortvar( $m_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   bdec(3) cdec(3) pdec(3) tdec(3) nocons 

xtset iyfe
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M.doc, append ctitle(Lobbying$ /Assets)  keep($m_controls) sortvar( $m_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  bdec(3) cdec(3) pdec(3) tdec(3)  nocons 

xtset gvkey
xtreg total_lob_assets $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M.doc, append ctitle(Lobbying$ /Assets)  keep( $m_controls) sortvar(m_controls) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  bdec(3) cdec(3) pdec(3) tdec(3)  nocons 

* Green / brown
global m_controls "l_market_sh l_fluid l_ln_pat_gr l_ln_at l_xrd l_mb l_roa l_ch l_capx"
xtset fyear
xtreg total_lob_assets_gb_text $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M_gb.doc, replace ctitle(Green-Brown Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($m_controls) sortvar($m_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   bdec(3) cdec(3) pdec(3) tdec(3) nocons 

xtset ffi
xtreg total_lob_assets_gb_text $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M_gb.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep( $m_controls) sortvar( $m_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  bdec(3) cdec(3) pdec(3) tdec(3)  nocons 

xtset iyfe
xtreg total_lob_assets_gb_text $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M_gb.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep($m_controls) sortvar( $m_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  bdec(3) cdec(3) pdec(3) tdec(3)  nocons 

xtset gvkey
xtreg total_lob_assets_gb_text $m_controls i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6_M_gb.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep( $m_controls) sortvar( $m_controls) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  bdec(3) cdec(3) pdec(3) tdec(3)  nocons 




* other specifications below:

*1
*SIC 3
xtset fyear
xtreg total_lob_assets_gb_text $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, replace ctitle(Green-Brown Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg total_lob_assets_gb_text $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep( $l_controls_nohhi) sortvar(l_hhi $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg total_lob_assets_gb_text $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep($l_controls) sortvar(l_hhi high_hhi high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg total_lob_assets_gb_text $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Green-Brown Lobbying$ /Assets)  keep(l_hhi l_fluid high_hhi high_fluid $h_controls_both) sortvar(l_hhi l_fluid high_hhi high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 



*SIC 2
global l_controls "l_fluid l_new_hhi2 l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_nohhi "l_fluid l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global l_controls_nofluid "l_new_hhi2 l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi2 high_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
xtset fyear
xtreg total_lob_assets $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, replace ctitle(Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg total_lob_assets $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep( $l_controls_nohhi) sortvar(l_new_hhi2 $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg total_lob_assets $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep($l_controls) sortvar(l_new_hhi2 high_hhi2 high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg total_lob_assets $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep(l_new_hhi2 l_fluid high_hhi2 high_fluid $h_controls_both) sortvar(l_new_hhi2 l_fluid high_hhi2 high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 


*SIC 3
global l_controls "l_fluid l_new_hhi3 l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_nohhi "l_fluid l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global l_controls_nofluid "l_new_hhi3 l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi3 high_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
xtset fyear
xtreg total_lob_assets $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, replace ctitle(Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg total_lob_assets $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep( $l_controls_nohhi) sortvar(l_new_hhi3 $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg total_lob_assets $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep($l_controls) sortvar(l_new_hhi3 high_hhi3 high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg total_lob_assets $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep(l_new_hhi2 l_fluid high_hhi2 high_fluid $h_controls_both) sortvar(l_new_hhi3 l_fluid high_hhi3 high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 



*SIC 4
global l_controls "l_fluid l_new_hhi4 l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_nohhi "l_fluid l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global l_controls_nofluid "l_new_hhi4 l_patenting_intens l_xrd l_ln_at l_mb l_roa l_ch l_capx"
global h_controls_both  "high_hhi4 high_fluid l_patenting_intens l_ln_at l_xrd l_mb l_roa l_ch l_capx"
xtset fyear
xtreg total_lob_assets $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, replace ctitle(Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg total_lob_assets $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep( $l_controls_nohhi) sortvar(l_new_hhi4 $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg total_lob_assets $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep($l_controls) sortvar(l_new_hhi4 high_hhi4 high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg total_lob_assets $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep(l_new_hhi4 l_fluid high_hhi4 high_fluid $h_controls_both) sortvar(l_new_hhi4 l_fluid high_hhi4 high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 




*1
xtset gvkey
xtreg total_lob_assets $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, replace ctitle(Lobbying$ /Assets) title("Table 6 - Determinants of Lobbying") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset gvkey
xtreg total_lob_assets $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep( $l_controls_nohhi) sortvar(l_hhi4 $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset gvkey
xtreg total_lob_assets $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep($l_controls) sortvar(l_hhi4 high_hhi high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset gvkey
xtreg total_lob_assets $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6a.doc, append ctitle(Lobbying$ /Assets)  keep(l_hhi4 l_fluid high_hhi high_fluid $h_controls_both) sortvar(l_hhi l_fluid high_hhi high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 



* Table 6B - Determinants of Green/Brown lobbying  

xtset fyear
xtreg total_lob_assets_gb_text $l_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6.doc, replace ctitle(Lobbying$ /Assets) title("Table 6 - Determinants of Green/Brown Lobbying") keep($l_controls_nofluid) sortvar($l_controls_nofluid)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

*2 
xtset fyear
xtreg total_lob_assets_gb_text $l_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6.doc, append ctitle(Lobbying$ /Assets)  keep( $l_controls_nohhi) sortvar(l_hhi $l_controls_nohhi)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 3
xtset fyear
xtreg total_lob_assets_gb_text $l_controls  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6.doc, append ctitle(Lobbying$ /Assets)  keep($l_controls) sortvar(l_hhi high_hhi high_fluid $l_controls)  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 4 
xtset fyear
xtreg total_lob_assets_gb_text $h_controls_nofluid  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6.doc, append ctitle(Lobbying$ /Assets) keep($h_controls_nofluid)   addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 5
xtset fyear
xtreg total_lob_assets_gb_text $h_controls_nohhi  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6.doc, append ctitle( Lobbying$ /Assets)  keep($h_controls_nohhi)   addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

* 6 
xtset fyear
xtreg total_lob_assets_gb_text $h_controls_both  i.fyear if my_sample==1, fe vce(robust)
outreg2 using table_6.doc, append ctitle(Lobbying$ /Assets)  keep(l_hhi l_fluid high_hhi high_fluid $h_controls_both) sortvar(l_hhi l_fluid high_hhi high_fluid $h_controls_both) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni   nocons 

				 


			/* Table ? - First Stage  */


/// IV regression ///


* TO DO : sum approval rates into firm-year for green patens only !!! 

* i. First Stage

* set-up variables
sort gvkey fyear
by gvkey: gen l_ln_patgrant_gr=ln_patgrant_gr[_n-1]
by gvkey: gen l_ln_patgrant=ln_patgrant[_n-1]
by gvkey: gen l_ln_patgrant_non_gr=ln_patgrant_non_gr[_n-1]
by gvkey: gen l_av_approval_gr=av_approval_gr[_n-1]
by gvkey: gen l_all_approval_gr=all_approval_gr[_n-1]
by gvkey: gen l_av_approval_nongr=av_approval_nongr[_n-1]
by gvkey: gen l_all_approval_nongr=all_approval_nongr[_n-1]

by gvkey: gen l_av_appr_tclass_gr=av_appr_tclass_gr[_n-1]
by gvkey: gen l_av_appr_tclass_year_gr=av_appr_tclass_year_gr[_n-1]
by gvkey: gen l_av_appr_art_gr=av_appr_art_gr[_n-1]
by gvkey: gen l_av_appr_art_year_gr=av_appr_art_year_gr[_n-1]
by gvkey: gen l_av_appr_tclass=av_appr_tclass[_n-1]
by gvkey: gen l_av_appr_tclass_year=av_appr_tclass_year[_n-1]
by gvkey: gen l_av_appr_art =av_appr_art[_n-1]
by gvkey: gen l_av_appr_art_year =av_appr_art_year[_n-1]

by gvkey: gen l2_av_appr_tclass_gr=av_appr_tclass_gr[_n-2]
by gvkey: gen l2_av_appr_tclass_year_gr=av_appr_tclass_year_gr[_n-2]
by gvkey: gen l2_av_appr_art_gr=av_appr_art_gr[_n-2]
by gvkey: gen l2_av_appr_art_year_gr=av_appr_art_year_gr[_n-2]
by gvkey: gen l2_av_appr_tclass=av_appr_tclass[_n-2]
by gvkey: gen l2_av_appr_tclass_year=av_appr_tclass_year[_n-2]
by gvkey: gen l2_av_appr_art =av_appr_art[_n-2]
by gvkey: gen l2_av_appr_art_year =av_appr_art_year[_n-2]

by gvkey: gen l_sum_appr_tclass_gr=sum_appr_tclass_gr[_n-1]
by gvkey: gen l_sum_appr_tclass_year_gr=sum_appr_tclass_year_gr[_n-1]
by gvkey: gen l_sum_appr_art_gr=sum_appr_art_gr[_n-1]
by gvkey: gen l_sum_appr_art_year_gr=sum_appr_art_year_gr[_n-1]
by gvkey: gen l_sum_appr_tclass=sum_appr_tclass[_n-1]
by gvkey: gen l_sum_appr_tclass_year=sum_appr_tclass_year[_n-1]
by gvkey: gen l_sum_appr_art =sum_appr_art[_n-1]
by gvkey: gen l_sum_appr_art_year =sum_appr_art_year[_n-1]



by gvkey: gen l_appr_rate_art_t_year_gr =appr_rate_art_tclass_year_gr[_n-1]
by gvkey: gen l_appr_rate_art_tclass_year =appr_rate_art_tclass_year[_n-1]

replace av_appr_tclass_gr=0 if missing(av_appr_tclass_gr)
replace av_appr_tclass_year_gr=0 if missing(av_appr_tclass_year_gr)
replace av_appr_art_gr=0 if missing(av_appr_art_gr)
replace av_appr_art_year_gr=0 if missing(av_appr_art_year_gr)
replace av_appr_tclass=0 if missing(av_appr_tclass)
replace av_appr_tclass_year=0 if missing(av_appr_tclass_year)
replace av_appr_art=0 if missing(av_appr_art)
replace av_appr_art_year=0 if missing(av_appr_art_year)


* Average (approval rates) - control group are all firms (those didn't apply and those that did apply for a green patent)
replace av_approval_gr=0 if missing(av_approval_gr)
by gvkey: gen l_av_approval_gr_c=av_approval_gr[_n-1]

by gvkey: gen l_ln_sale=ln(sale[_n-1])
*by gvkey: gen l_log_sale=log(sale[_n-1])
label variable l_log_sale "log(Sales)"
drop size_q
xtile size_q = l_ln_at, nq(10)
xtile size_q5 = l_ln_at, nq(5)

label variable ln_patgrant_gr "ln(1+#granted green patents)"
label variable l_ln_patgrant_gr "ln(1+#granted green patents)"
label variable ln_patgrant_non_gr "ln(1+#granted non-green patents)"
label variable l_ln_patgrant_non_gr "ln(1+#granted non-green patents)"
label variable l_log_sale "log(Sales)"

label variable ln_mkt_value "Market Cap"
label variable all_approval_gr "Green Approval Rate"
label variable all_approval_nongr "Non-Green Approval Rate"
label variable l_av_approval_gr "Av Appr Rate"
label variable l_av_approval_gr_c "Av Appr Rate"


global l_controls_new  "l_fluid l_hhi l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_new_nohhi  "l_fluid  l_ln_at l_xrd l_mb l_roa l_ch l_capx"

* try % of patents approved
by gvkey: gen l_frac_approved= total_grant_gr[_n-1]/ l_total_appl_gr 
by gvkey: gen l_frac_approved_all= total_grant[_n-1]/ l_total_appl

by gvkey: gen l2_frac_approved= total_grant_gr[_n-2]/ total_appl_gr 
by gvkey: gen l2_frac_approved_all= total_grant[_n-2]/ total_appl

sum l_frac_approved l_frac_approved_all

label variable l_frac_approved "% of Green Patents Approved"
label variable l_frac_approved_all "% of Patents Approved"
*hist l_frac_approved if l_ln_pat_gr>0  & my_sample==1, percent
*hist l_frac_approved_all if l_ln_pat>0  & my_sample==1, percent

sum l_frac_approved  if l_ln_pat_gr>0  & my_sample==1, detail 
sum l_frac_approved_all if l_ln_pat>0  & my_sample==1, detail 

label variable l_av_appr_art_year "Av Appr Rate"
label variable l_av_appr_tclass_year "Av Appr Rate"
label variable l_av_appr_art_year_gr "Av Green Appr Rate"
label variable l_av_appr_tclass_year_gr "Av Green Appr Rate"

* Table 1A
* Control group - firms that did apply for a green patent
* N of green patens is a function of green patent examiners' approval rates
* First stage for all patents
xtset ffi
xtreg l_frac_approved_all l_av_appr_art_year l_ln_pat $l_controls_new  i.fyear if l_ln_pat>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, replace ctitle("% Patents Approved") keep(l_av_appr_art_year l_ln_pat $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons
xtset iyfe
xtreg l_frac_approved_all l_av_appr_art_year l_ln_pat $l_controls_new_nohhi  i.fyear  if l_ln_pat>0 & fyear>2000 & my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Patents Approved") keep(l_av_appr_art_year l_ln_pat $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni  nocons
xtset gvkey
xtreg l_frac_approved_all l_av_appr_art_year l_ln_pat $l_controls_new  i.fyear if l_ln_pat>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Patents Approved") keep(l_av_appr_art_year l_ln_pat $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni  nocons
xtset ffi
xtreg l_frac_approved_all l_av_appr_tclass_year l_ln_pat $l_controls_new  i.fyear if l_ln_pat>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Patents Approved") keep(l_av_appr_tclass_year l_ln_pat $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons
xtset iyfe
xtreg l_frac_approved_all l_av_appr_tclass_year l_ln_pat $l_controls_new_nohhi  i.fyear  if l_ln_pat>0 & fyear>2000 & my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Patents Approved") keep(l_av_appr_tclass_year l_ln_pat $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni  nocons
xtset gvkey
xtreg l_frac_approved_all l_av_appr_tclass_year l_ln_pat $l_controls_new  i.fyear if l_ln_pat>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Patents Approved") keep(l_av_appr_tclass_year l_ln_pat $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni  nocons



* First stage for Green Patents approval rates
xtset ffi
xtreg l_frac_approved l_av_appr_art_year_gr l_ln_pat_gr $l_controls_new  i.fyear if l_ln_pat_gr>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, replace ctitle("% Green Patents Approved") keep(l_av_appr_art_year_gr l_ln_pat_gr $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons
xtset iyfe
xtreg l_frac_approved l_av_appr_art_year_gr l_ln_pat_gr $l_controls_new_nohhi  i.fyear  if l_ln_pat_gr>0 & fyear>2000 & my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Green Patents Approved") keep(l_av_appr_art_year_gr l_ln_pat_gr $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni  nocons
xtset gvkey
xtreg l_frac_approved l_av_appr_art_year_gr l_ln_pat_gr $l_controls_new  i.fyear if l_ln_pat_gr>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Green Patents Approved") keep(l_av_appr_art_year_gr l_ln_pat_gr $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni  nocons
xtset ffi
xtreg l_frac_approved l_av_appr_tclass_year_gr l_ln_pat_gr $l_controls_new  i.fyear if l_ln_pat_gr>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Green Patents Approved") keep(l_av_appr_tclass_year_gr l_ln_pat_gr $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons
xtset iyfe
xtreg l_frac_approved l_av_appr_tclass_year_gr l_ln_pat_gr $l_controls_new_nohhi  i.fyear  if l_ln_pat_gr>0 & fyear>2000 & my_sample==1, fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Green Patents Approved") keep(l_av_appr_tclass_year_gr l_ln_pat_gr $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni  nocons
xtset gvkey
xtreg l_frac_approved l_av_appr_tclass_year_gr l_ln_pat_gr $l_controls_new  i.fyear if l_ln_pat_gr>0 & fyear>2000 & my_sample==1 , fe vce(robust)
outreg2 using table_5.doc, append ctitle("% Green Patents Approved") keep(l_av_appr_tclass_year_gr l_ln_pat_gr $l_controls_new) bdec(3) cdec(3) pdec(3) tdec(3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni  nocons



**** Percentages


hist t_lob_rep_pct if t_lob_rep_pct>=0 & t_lob_rep_pct<=1 &   l_ln_pat_gr>0  & my_sample==1, frequency title("Distribution of Firm-Year Contributions") xtitle("Proportion of Republican LD-2s in a year")


replace t_lob_dem_pct=0 if missing(t_lob_dem_pct)
replace t_lob_dem_pct_all=0 if missing(t_lob_dem_pct_all)
replace t_lob_rep_pct=0 if missing(t_lob_rep_pct)
replace t_lob_rep_pct_all=0 if missing(t_lob_rep_pct_all)
replace t_lob_mid_pct_all=0 if missing(t_lob_mid_pct_all)


 

xtset ffi
xi: xtivreg2 t_lob_dem_pct  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_8_pct.doc, replace ctitle( Pct Dem Lobbying) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat)) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Lobbying") 
xtset iyfe
xi: xtivreg2 t_lob_dem_pct $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct.doc, append ctitle( Pct Dem Lobbying) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 t_lob_dem_pct $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct.doc, append ctitle( Pct Dem Lobbying) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 t_lob_dem_pct  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_8_pct.doc, append ctitle(Pct Dem Lobbying) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 t_lob_dem_pct $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct.doc, append ctitle(Pct Dem Lobbying) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 t_lob_dem_pct $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct.doc, append ctitle(Pct Dem Lobbying) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons

xtset ffi
xi: xtivreg2 t_lob_dem_pct_all  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_8_pct_all.doc, replace ctitle(Pct Dem Lobbying, all) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat)) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Lobbying") 
xtset iyfe
xi: xtivreg2 t_lob_dem_pct_all $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 t_lob_dem_pct_all $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 t_lob_dem_pct_all  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 t_lob_dem_pct_all $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 t_lob_dem_pct_all $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons



**** Logit 
* logit transformation doesn't work here because of a lot of ones and zeros in % of only Dem or Rep contributions
gen logit_dem_contrib= log((t_lob_dem_pct/(1-t_lob_dem_pct)))
gen logit_rep_contrib= log((t_lob_rep_pct/(1-t_lob_rep_pct)))
gen logit_rep_contrib_all= log((t_lob_rep_pct_all/(1-t_lob_rep_pct_all)))
gen logit_dem_contrib_all= log((t_lob_dem_pct_all/(1-t_lob_dem_pct_all)))
*replace logit_dem_contrib=0 if missing(logit_dem_contrib)
*replace logit_rep_contrib=0 if missing(logit_rep_contrib)
*replace logit_rep_contrib_all=0 if missing(logit_rep_contrib_all)
xtset ffi
xi: xtivreg2 logit_dem_contrib_all  $l_controls_new i.fyear  (l_frac_approved   = l_av_appr_art_year_gr)  if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_8_pct_all.doc, replace ctitle("log(pct/(1-pct))") keep(l_frac_approved_all $l_controls_new) addstat("F-stat", e(widstat)) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Lobbying") 
xtset iyfe
xi: xtivreg2 logit_rep_contrib_all $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved_all $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 logit_rep_contrib_all $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved_all $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 logit_rep_contrib_all  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved_all $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 logit_rep_contrib_all $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved_all $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 logit_rep_contrib_all $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_8_pct_all.doc, append ctitle(Pct Dem Lobbying, all) keep(l_frac_approved_all $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons




			/* Table 7 -  2SLS Determinants of lobbying as a function of whether green patent was granted*/

* ii. Second Stage - Green

* Average (approval rates) - control group are firms that didn't get a green patent granted

global l_controls_new  "l_fluid l_hhi l_ln_at l_xrd l_mb l_roa l_ch l_capx"
global l_controls_new_nohhi  "l_fluid  l_ln_at l_xrd l_mb l_roa l_ch l_capx"

global l2_controls_new  "l2_fluid l2_hhi l2_ln_at l2_xrd l2_mb l2_roa l2_ch l2_capx"
global l2_controls_new_nohhi  "l2_fluid  l2_ln_at l2_xrd l2_mb l2_roa l2_ch l2_capx"

global l_controls2  "l_ln_at l_xrd l_mb l_roa l_ch l_capx"

label variable l_ln_pat "ln(1+#patent apps)"

label variable l_frac_approved "% Green Patents Approved"
label variable l_frac_approved_all "% Patents Approved"

cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"

sort gvkey fyear
by gvkey: gen l_av_approval = av_approval[_n-1]
*by gvkey: gen l_ln_pat = ln_pat[_n-1]

by gvkey: gen l4_av_approval = av_approval[_n-4]
by gvkey: gen l4_ln_pat = ln_pat[_n-4]
by gvkey: gen l4_frac_approved_all = l_frac_approved_all[_n-3]
by gvkey: gen l6_av_approval = av_approval[_n-6]
by gvkey: gen l6_ln_pat = ln_pat[_n-6]
by gvkey: gen l3_frac_approved_all = l_frac_approved_all[_n-2]
by gvkey: gen l3_av_appr_tclass_year = l_av_appr_tclass_year[_n-2]

replace sponsor_dem_year=0 if missing(sponsor_dem_year) 
replace sponsor_rep_year =0 if missing(sponsor_rep_year)
gen sponsor_dem_amount=total_lob_assets_gb_text if sponsor_dem==1
gen sponsor_rep_amount=total_lob_assets_gb_text if sponsor_rep==1
replace sponsor_dem_amount=0 if missing(sponsor_dem_amount)
replace sponsor_rep_amount=0 if missing(sponsor_rep_amount)

by gvkey: gen l_total_lob_assets= total_lob_assets[_n-1]
by gvkey: gen l_total_lob_assets_gb_text= total_lob_assets_gb_text[_n-1]


by gvkey: gen l_ln_granted_gr_this_y = ln(1+total_grant_gr_this_y[_n-1])
replace l_ln_granted_gr_this_y=0 if missing(l_ln_granted_gr_this_y)
by gvkey: gen l_ln_granted_this_y = ln(1+total_grant_this_y[_n-1])
replace l_ln_granted_this_y=0 if missing(l_ln_granted_this_y)

by gvkey: gen l2_total_lob_assets_gb_dem = total_lob_assets_gb_dem[_n-2]
by gvkey: gen l_total_lob_assets_gb_dem = total_lob_assets_gb_dem[_n-1]
by gvkey: gen n1_total_lob_assets_gb_dem = total_lob_assets_gb_dem[_n+1]
by gvkey: gen n2_total_lob_assets_gb_dem = total_lob_assets_gb_dem[_n+2]
by gvkey: gen n3_total_lob_assets_gb_dem = total_lob_assets_gb_dem[_n+3]

by gvkey: gen l2_total_lob_assets_gb_rep = total_lob_assets_gb_rep[_n-2]
by gvkey: gen l_total_lob_assets_gb_rep = total_lob_assets_gb_rep[_n-1]
by gvkey: gen n1_total_lob_assets_gb_rep = total_lob_assets_gb_rep[_n+1]
by gvkey: gen n2_total_lob_assets_gb_rep = total_lob_assets_gb_rep[_n+2]
by gvkey: gen n3_total_lob_assets_gb_rep = total_lob_assets_gb_rep[_n+3]

by gvkey: gen l2_total_lob_assets_gb_dem_y = total_lob_assets_gb_dem_y[_n-2]
by gvkey: gen l_total_lob_assets_gb_dem_y = total_lob_assets_gb_dem_y[_n-1]
by gvkey: gen n1_total_lob_assets_gb_dem_y = total_lob_assets_gb_dem_y[_n+1]
by gvkey: gen n2_total_lob_assets_gb_dem_y = total_lob_assets_gb_dem_y[_n+2]
by gvkey: gen n3_total_lob_assets_gb_dem_y = total_lob_assets_gb_dem_y[_n+3]

by gvkey: gen l2_total_lob_assets_gb_rep_y = total_lob_assets_gb_rep_y[_n-2]
by gvkey: gen l_total_lob_assets_gb_rep_y = total_lob_assets_gb_rep_y[_n-1]
by gvkey: gen n1_total_lob_assets_gb_rep_y = total_lob_assets_gb_rep_y[_n+1]
by gvkey: gen n2_total_lob_assets_gb_rep_y = total_lob_assets_gb_rep_y[_n+2]
by gvkey: gen n3_total_lob_assets_gb_rep_y = total_lob_assets_gb_rep_y[_n+3]

gen diff = total_lob_assets_gb_rep-total_lob_assets_gb_dem
replace diff=0 if diff<0
gen abs_diff=abs(diff)

gen diff_d = total_lob_assets_gb_dem - total_lob_assets_gb_rep
replace diff_d=0 if diff_d<0

by gvkey: gen n1_diff=diff[_n+1]
by gvkey: gen n2_diff=diff[_n+2]
by gvkey: gen n1_diff_d=diff_d[_n+1]
by gvkey: gen n2_diff_d=diff_d[_n+2]


keep if sp_1500==1


xtset ffi
xtset iyfe 
xtset gvkey
xi: xtivreg2 diff_d  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 

xi: xtivreg2 n3_total_lob_assets_gb_rep  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 
cd "C:\Working Folder"

* ADJUSTED IV 
* av_appr_tclass_gr av_appr_tclass_year_gr av_appr_art_gr av_appr_art_year_gr av_appr_tclass av_appr_tclass_year av_appr_art av_appr_art_year


* Table 7A with Art and Tclass FEs - determinants of lobbying 
gen dummy_lob_any=1 if total_lob_sale>0
replace dummy_lob_any=0 if missing(dummy_lob_any)
gen dummy_lob_gr=1 if total_lob_sale_gb_text>0
replace dummy_lob_gr=0 if missing(dummy_lob_gr)

sort gvkey fyear 
by gvkey: gen n1_total_lob_assets = total_lob_assets[_n+1]
by gvkey: gen n2_total_lob_assets = total_lob_assets[_n+2]
by gvkey: gen n3_total_lob_assets = total_lob_assets[_n+3]
*by gvkey: gen l_total_lob_assets = total_lob_assets[_n-1]
by gvkey: gen l2_total_lob_assets = total_lob_assets[_n-2]
by gvkey: gen n1_total_lob_assets_gb_texts = total_lob_assets_gb_text[_n+1]
by gvkey: gen n2_total_lob_assets_gb_texts = total_lob_assets_gb_text[_n+2]
by gvkey: gen l_total_lob_assets_gb_texts = total_lob_assets_gb_text[_n-1]
by gvkey: gen l2_total_lob_assets_gb_texts = total_lob_assets_gb_text[_n-2]
by gvkey: gen l3_total_lob_assets_gb_texts = total_lob_assets_gb_text[_n-3]


* For Lobbying/ Sales use - total_lob_sale total_lob_sale_gb_text
* For Lobbying/ Assets use - total_lob_assets total_lob_assets_gb_text dummy_lob_gr dummy_lob_any

by gvkey: gen l2_ln_pat = ln_pat[_n-2]
by gvkey: gen l2_ln_pat_gr = ln_pat_gr[_n-2]

sort gvkey fyear
gen k=1 if l_ln_pat>0  & my_sample==1
by gvkey: egen years_present=sum(k)

gen p=1 if l_ln_pat_gr>0  & my_sample==1
by gvkey: egen years_present_gr=sum(p)

* Get Interquantile range
by gvkey: egen p75 = pctile(total_lob_assets), p(75)
by gvkey: egen p25 = pctile(total_lob_assets), p(25)
gen interq_r=p75-p25
by gvkey: egen p75_gr = pctile(total_lob_assets_gb_text), p(75)
by gvkey: egen p25_gr = pctile(total_lob_assets_gb_text), p(25)
gen interq_r_gr=p75_gr-p25_gr

by gvkey: egen p50 = pctile(total_lob_assets), p(50)
by gvkey: egen p50_gr = pctile(total_lob_assets_gb_text), p(50)

by gvkey: egen mean_ = mean(total_lob_assets) 
by gvkey: egen mean_gr = mean(total_lob_assets_gb_text) 

by gvkey: egen sd_ = sd(total_lob_assets) 
by gvkey: egen sd_gr = sd(total_lob_assets_gb_text) 

label variable interq_r "Interquantile Range"
label variable interq_r_gr "Interquantile Range"
label variable years_present_gr "N of Green Patenting Years"
label variable years_present "N of Patenting Years"
label variable sd_ "Lobbying SD"
label variable sd_gr "Green Lobbying SD"
label variable mean_ "Lobbying Mean"
label variable mean_gr "Green Lobbying Mean"
label variable p50 "Lobbying Median"
label variable p50_gr "Green Lobbying Median"

by gvkey: egen av_contrib=mean(total_lob_assets)
by gvkey: egen av_contrib_gb=mean(total_lob_assets_gb_text)
xtset gvkey
xi: xtivreg2 ln_total  l_ln_pat  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if l_ln_pat>0  & my_sample==1 & av_contrib >6, fe robust ffirst 
xi: xtivreg2 ln_total  l_ln_pat  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if l_ln_pat>0  & my_sample==1 & av_contrib >0.6, fe robust ffirst   
xi: xtivreg2 ln_total_gb l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1  & av_contrib >1, fe robust ffirst  
xi: xtivreg2 ln_total_gb l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1  & av_contrib >1 , fe robust ffirst  

* Dem/Rep (for 90% benchmark)
* Rep - 243 positive obs, 62 unique firms
* Rep - 181 positive obs, 51 unique firms
xtset gvkey
xi: xtivreg2 ln_rep l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 & av_contrib >4 , fe robust ffirst  
xi: xtivreg2 ln_dem l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 & av_contrib >4 , fe robust ffirst  


				* Count N of Time-Series Observations per firm
				duplicates drop gvkey, force
				
				sum interq_r if years_present>0
				sum interq_r_gr if years_present_gr>0
				hist interq_r if years_present>0, percent title("Lobbying Interquantile Range per unique firm")
				hist interq_r_gr if years_present_gr>0, percent title("Green Lobbying Interquantile Range per unique firm")
								
				hist sd_ if years_present>0, percent title("Lobbying SD per unique firm")
				sum sd_ if years_present>0
				hist sd_gr if years_present_gr>0, percent title("Green Lobbying SD per unique firm")
				sum sd_gr if years_present_gr>0
								
				hist mean_ if years_present>0, percent title("Lobbying Mean per unique firm")
				sum mean_ if years_present>0
				hist mean_gr if years_present_gr>0, percent title("Green Lobbying Mean per unique firm")
				sum mean_gr if years_present_gr>0
								
				hist p50 if years_present>0, percent title("Lobbying Median per unique firm")
				sum p50 if years_present>0
				hist p50_gr if years_present_gr>0, percent title("Green Lobbying Median per unique firm")
				sum p50_gr if years_present_gr>0
								
				*replace years_present=. if l_ln_pat==0  | my_sample!=1 
				*replace years_present_gr=. if l_ln_pat_gr==0  | my_sample!=1 
				*sum years_present if years_present>0
				*sum years_present_gr if years_present_gr>0
				
				hist years_present_gr if years_present_gr>0, percent title("Number of Years per unique firm")
				
				*hist years_present if years_present>0, percent title("Number of Years per unique firm")
				
unique(gvkey) if total_lob_assets>0 & l_ln_pat>0  & my_sample==1

* Economic Significance:
sort iyfe 
by iyfe: egen sd_iyfe = sd(l_frac_approved_all) if  l_ln_pat>0  & my_sample==1
sort gvkey fyear 
by gvkey: egen sd_firm=sd(l_frac_approved_all) if  l_ln_pat>0  & my_sample==1

sum total_lob_assets if  l_ln_pat>0  & my_sample==1
* use SD here:
sum l_frac_approved_all if l_ln_pat>0  & my_sample==1
* use mean here:
sum sd_iyfe if l_ln_pat>0  & my_sample==1
sum sd_firm if l_ln_pat>0  & my_sample==1
drop sd_iyfe sd_firm

* Art Class FE
*total_lob_assets
*ln_total

* Scaled number of applications: 
sort gvkey fyear 
by gvkey: gen l_ln_pat_sc = ln(1+total_appl_scaled[_n-1])
total_appl_scaled

gen ln2_total=ln(1+t_lob)
gen ln2_total_gb=ln(1+t_lob_gb_text)

xtset ffi
xi: xtivreg2  total_lob_assets l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7a_FE.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat)) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Lobbying") 
xtset iyfe
xi: xtivreg2 total_lob_assets  l_ln_pat $l_controls_new_nohhi i.fyear (l_frac_approved_all  = l_av_appr_art_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7a_FE.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets l_ln_pat  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year)   if l_ln_pat>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7a_FE.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 total_lob_assets  l_ln_pat  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7a_FE.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 total_lob_assets  l_ln_pat $l_controls_new_nohhi i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7a_FE.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year)   if l_ln_pat>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7a_FE.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons


* Where Firm FEs are concentrated:
unique(gvkey) if years_present<=10 & years_present>=5 & l_ln_pat>0 & my_sample==1
*355 unique firms with 5-10 years of green patenting 
xtset gvkey
xi: xtivreg2 ln_total l_ln_pat  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year)   if years_present<=10 & years_present>=5 & l_ln_pat>0 & my_sample==1 , fe robust ffirst  
xi: xtivreg2 ln_total  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year)   if years_present<=10 & years_present>=5 & l_ln_pat>0 & my_sample==1 , fe robust ffirst  

xi: xtivreg2 ln_total_gb l_ln_pat_gr ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if years_present>0 & years_present<10 &  l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
xi: xtivreg2 ln_total_gb l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if years_present>=15 & l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  


		* Table 7A - determinants of lobbying 

		xtset fyear
		xtivreg2 total_lob_sale  $l_controls_new (l_frac_approved_all  = l_av_approval) if l_ln_pat>0 & my_sample==1 , fe robust ffirst  
		outreg2 using table_7a.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
		xtset ffi
		xi: xtivreg2 total_lob_sale  $l_controls_new i.fyear (l_frac_approved_all  = l_av_approval) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   
		outreg2 using table_7a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
		xtset iyfe
		xtivreg2 total_lob_sale $l_controls_new_nohhi (l_frac_approved_all  = l_av_approval) if l_ln_pat>0  & my_sample==1 , fe robust ffirst  
		outreg2 using table_7a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
		xtset gvkey
		xi: xtivreg2 total_lob_sale $l_controls_new i.fyear (l_frac_approved_all  = l_av_approval)   if l_ln_pat>0 & my_sample==1 , fe robust ffirst  
		outreg2 using table_7a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni nocons

* Economic Significance:
sort iyfe 
by iyfe: egen sd_iyfe = sd(l_frac_approved) if  l_ln_pat_gr>0  & my_sample==1
sort gvkey fyear 
by gvkey: egen sd_firm=sd(l_frac_approved) if  l_ln_pat_gr>0  & my_sample==1

sum total_lob_assets_gb_text if  l_ln_pat_gr>0  & my_sample==1
* use SD here:
sum l_frac_approved if l_ln_pat_gr>0  & my_sample==1
* use mean here:
sum sd_iyfe if l_ln_pat_gr>0  & my_sample==1
sum sd_firm if l_ln_pat_gr>0  & my_sample==1
drop sd_iyfe sd_firm

* Table 7B with Art and Tclass FEs - determinants of Green/Brown lobbying 

	
* Art Class FE
*ln_total_gb
*total_lob_assets_gb_text
xtset ffi
xi: xtivreg2 total_lob_assets_gb_text l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr ) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7b_FE.doc, replace ctitle( Green/Brown Lobbying$ /Assets) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Green/Brown Lobbying")
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_text l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7b_FE.doc, append ctitle( Green/Brown Lobbying$ /Assets) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_text l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7b_FE.doc, append ctitle( Green/Brown Lobbying$ /Assets) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 total_lob_assets_gb_text l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7b_FE.doc, append ctitle( Green/Brown Lobbying$ /Assets) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_text l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7b_FE.doc, append ctitle( Green/Brown Lobbying$ /Assets) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_text l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7b_FE.doc, append ctitle( Green/Brown Lobbying$ /Assets) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons

	

			* Table 7B - determinants of Green/Brown lobbying 

			xtset fyear
			xtivreg2 total_lob_sale_gb_text $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
			outreg2 using table_7b.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
			xtset ffi
			xi: xtivreg2 total_lob_sale_gb_text $l_controls_new i.fyear (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
			outreg2 using table_7b.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
			xtset iyfe
			xtivreg2 total_lob_sale_gb_text $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
			outreg2 using table_7b.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
			xtset gvkey
			xi: xtivreg2 total_lob_sale_gb_text $l_controls_new i.fyear (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
			outreg2 using table_7b.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons

* UPDATED: Democratic Versus Republican 
* green/brown lobbying
xtset ffi
xi: xtivreg2 total_lob_sale_gb_rep  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 total_lob_sale_gb_rep  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 total_lob_sale_gb_rep  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   

xtset ffi
xi: xtivreg2 total_lob_sale_gb_dem  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 total_lob_sale_gb_dem  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 total_lob_sale_gb_dem  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   

xtset ffi
xi: xtivreg2 total_lob_sale_gb_mid  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 total_lob_sale_gb_mid  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 total_lob_sale_gb_mid  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   

* based on which bill is lobbied sponsors 

gen sponsor_rep_year_only =sponsor_rep_year if sponsor_dem_amount==0
gen sponsor_dem_year_only =sponsor_dem_year if sponsor_rep_year==0
replace sponsor_dem=0 if missing(sponsor_dem)
replace sponsor_rep=0 if missing(sponsor_rep)

xtset ffi
xi: xtivreg2 sponsor_rep  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & bill_yes_year==1, fe robust ffirst   
xtset iyfe
xi: xtivreg2 sponsor_rep  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1  & bill_yes_year==1, fe robust ffirst 
xtset gvkey
xi: xtivreg2 sponsor_rep  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1  & bill_yes_year==1, fe robust ffirst   

xtset ffi
xi: xtivreg2 sponsor_dem  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1  & bill_yes_year==1, fe robust ffirst   
xtset iyfe
xi: xtivreg2 sponsor_dem  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1  & bill_yes_year==1, fe robust ffirst   
xtset gvkey
xi: xtivreg2 sponsor_dem  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1  & bill_yes_year==1, fe robust ffirst   

xtset ffi
xi: xtivreg2 prop_inhouse  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 prop_inhouse  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 prop_inhouse  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   


*any lobbying
xtset ffi
xi: xtivreg2 total_lob_sale_rep  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year ) if l_ln_pat >0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 total_lob_sale_rep  $l_controls_new_nohhi i.fyear (l_frac_approved_all  = l_av_appr_art_year ) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 total_lob_sale_rep  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year ) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   

xtset ffi
xi: xtivreg2 total_lob_sale_dem  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 total_lob_sale_dem  $l_controls_new_nohhi i.fyear (l_frac_approved_all  = l_av_appr_art_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 total_lob_sale_dem  $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if l_ln_pat>0  & my_sample==1 , fe robust ffirst   

gen logit_dem_contrib= log((t_lob_dem_pct/(1-t_lob_dem_pct)))
gen logit_rep_contrib= log((t_lob_rep_pct/(1-t_lob_rep_pct)))
gen logit_rep_contrib_all= log((t_lob_rep_pct_all/(1-t_lob_rep_pct_all)))
replace logit_dem_contrib=0 if missing(logit_dem_contrib)
replace logit_rep_contrib=0 if missing(logit_rep_contrib)
replace logit_rep_contrib_all=0 if missing(logit_rep_contrib_all)
xtset ffi
xi: xtivreg2 logit_rep_contrib  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 logit_rep_contrib  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 logit_rep_contrib  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset ffi
xi: xtivreg2 logit_rep_contrib_all  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 logit_rep_contrib_all  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 logit_rep_contrib_all  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   

xtset ffi
xi: xtivreg2 logit_dem_contrib  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset iyfe
xi: xtivreg2 logit_dem_contrib  $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
xtset gvkey
xi: xtivreg2 logit_dem_contrib  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   


* Table 7C - determinants of Rep vs Dem lobbying 

* Split into lobbying FOR or AGAINST green/brown issues issues
* to avoid a small sample size, either do Green Lobby + 50% benchmark OR ANy Lobbying + 75% benchmark
* 75th percentile is .583337 and 25th is .2783201

gen mostly_dem_lobby=1 if green_contrib_year>0.5 & !missing(green_contrib_year)
gen mostly_rep_lobby=1 if green_contrib_year<0.5 & !missing(green_contrib_year)
replace mostly_dem_lobby=0 if missing(mostly_dem_lobby) 
replace mostly_rep_lobby=0 if missing(mostly_rep_lobby) 

gen dollar_dem_lobby = mostly_dem_lobby*total_lob_sale_gb_text
gen dollar_rep_lobby = mostly_rep_lobby*total_lob_sale_gb_text 

gen dummy_dem=1 if dollar_dem_lobby>0
gen dummy_rep=1 if dollar_rep_lobby>0
replace dummy_dem=0 if missing(dummy_dem)
replace dummy_rep=0 if missing(dummy_rep)

drop mostly_dem_lobby mostly_rep_lobby dollar_dem_lobby dollar_rep_lobby

*winsor2 dollar_dem_lobby, cuts(1 99)  replace
*winsor2 dollar_rep_lobby, cuts(1 99)  replace


* Logit transformation of % Contributions
* used to transform % data from 0 to 1 into more spread out data
gen logit_green_contrib_year= log((green_contrib_year/(1-green_contrib_year)))
replace logit_green_contrib_year=0 if missing(logit_green_contrib_year)

sum logit_green_contrib_year, detail

gen logit_dollar_rep_lobby= total_lob_sale_gb_text if logit_green_contrib_year<-2.113461  
gen logit_dollar_dem_lobby= total_lob_sale_gb_text if logit_green_contrib_year<1.763498
replace logit_dollar_rep_lobby=0 if missing(logit_dollar_rep_lobby)
replace logit_dollar_dem_lobby=0 if missing(logit_dollar_dem_lobby)

gen pp = green_contrib_year*total_lob_sale_gb_text
gen brown_contrib_year = 1-green_contrib_year
gen hh = brown_contrib_year*total_lob_sale_gb_text

/* specification below doesn't work due to sample size */

/* Republican Contributions with Art and Tclass FEs*/
gen dummy_rep_gr=1 if total_lob_sale_gb_rep>0
replace dummy_rep_gr=0 if missing(dummy_rep_gr)
gen dummy_dem_gr=1 if total_lob_sale_gb_dem>0
replace dummy_dem_gr=0 if missing(dummy_dem_gr)
gen dummy_mid = 1 if total_lob_sale_gb_mid>0
replace dummy_mid=0 if missing(dummy_mid)


* Lobby with Democrats on bills Sponsored by Democrats
gen lob_dem=total_lob_assets_gb_text if sponsor_dem_year>0.5  & !missing(sponsor_dem_year)
replace lob_dem=0 if missing(lob_dem)

gen lob_rep=total_lob_assets_gb_text if sponsor_rep_year>0.5  & !missing(sponsor_rep_year)
replace lob_rep=0 if missing(lob_rep)

* 4 options:
* Bill by Dem - Lobbied by Republicans (against)
* Bill by Dem - Lobbied by Democrats (for)

* Bill by Rep - Lobbied by Democrats (against)
* Bill by Rep - Lobbied by Republicans (for)




* Bill by Dem - Lobbied by Republicans (against)
gen lob_dem_rep=lob_dem if total_lob_sale_gb_rep>0 & !missing(total_lob_sale_gb_rep)
replace lob_dem_rep=0 if missing(lob_dem_rep)

* Bill by Dem - Lobbied by Democrats (for)
gen lob_dem_dem=lob_dem if total_lob_sale_gb_dem>0 & !missing(total_lob_sale_gb_dem)
replace lob_dem_dem=0 if missing(lob_dem_dem)

* Bill by Rep - Lobbied by Democrats (against)
gen lob_rep_dem=lob_rep if total_lob_sale_gb_dem>0 & !missing(total_lob_sale_gb_dem)
replace lob_rep_dem=0 if missing(lob_rep_dem)

* Bill by Rep - Lobbied by Republicans (for)
gen lob_rep_rep =lob_rep if total_lob_sale_gb_rep>0 & !missing(total_lob_sale_gb_rep)
replace lob_rep_rep=0 if missing(lob_rep_rep)


gen lob_rep_rep = total_lob_sale_gb_rep if sponsor_rep_year>0.5  & !missing(sponsor_rep_year)
replace lob_rep_rep=0 if missing(lob_rep_rep)

gen lob_rep_dem = total_lob_sale_gb_dem if sponsor_rep_year>0.5  & !missing(sponsor_rep_year)
replace lob_rep_dem=0 if missing(lob_rep_dem)

gen lob_dem_rep = total_lob_sale_gb_rep if sponsor_dem_year>0.5  & !missing(sponsor_dem_year)
replace lob_dem_rep=0 if missing(lob_dem_rep)

gen lob_dem_dem = total_lob_sale_gb_dem if sponsor_dem_year>0.5  & !missing(sponsor_dem_year)
replace lob_dem_dem=0 if missing(lob_dem_dem)

* Works for total_lob_assets_rep_rep VS total_lob_assets_dem_dem VS  

* total_lob_assets_rep_dem - hire democrats to go against Republican Bills 
* total_lob_assets_dem_rep - hire republicans to go against Democratic Bills 

* FINAL Result: 
* if we split LD-2s based on political affiliation of lobbyists working for LD-2 and on political affiliation of a bill proposed, then 
* we see that firms are more likely to lobby towards Democratic-sponsored bills after a green patent
* and less likely to lobby for republicans in favour of republican bills 
* we do a dobule split on Bill + on Lobbyists contribution to separate cases where an LD-2 is targeted to lobby againsts a certain proposition. 
* In cases where we observe a democratic lobbyists working on a democrat-sponsored bills, it is more likely that an LD-2 is targeted in favor of of what a political party stands for
* There is also a reslut from firm reducing their lobbying against brown issues using Democratic lobbyists once they obtain a green patent (total_lob_assets_rep_dem). This could be viewed as firms shifting their spending either towards a higher NPV lobbying like pro-green lobbying or towards a greater investment in R&D or infrustacture (should be testable)


* Tried:
* 1. Counting within transaction which LD-2s are D/R ->> total_lob_assets_gb_rep
* Percent of money of LD-2s that are D/R ->> t_lob_dem_pct
* 2. Countring within transaction + each bills are D/R ->> total_lob_assets_dem_dem, total_lob_assets_rep_dem, total_lob_assets_dem_rep, total_lob_assets_rep_rep
* 3. counting bills backed by D/R ->> total_lob_assets_rep_bill
* 4. Counting withing firn-year which years has more all lobbyists D/R ->> dollar_rep_lobby
* 5. Dummies on whether this firm-year hires >50% of D/R lobbyists ->> REP

gen rep_bills= total_lob_assets_rep_dem + total_lob_assets_rep_rep
gen dem_bills= total_lob_assets_dem_dem + total_lob_assets_dem_rep

sort gvkey fyear
gen u=1 if total_lob_assets_gb_rep>0
by gvkey: egen years_rep=sum(u)
drop u
gen u=1 if total_lob_assets_gb_dem>0
by gvkey: egen years_dem=sum(u)
drop u

gen both=total_lob_assets_gb_rep+total_lob_assets_gb_dem

label variable total_lob_assets_gb_text "All Green/Brown Lobbying"
graph bar both   total_lob_assets_gb_text, over(y) legend(label(1 "Dem/Rep Green Lobbying") label(2 "All Green/Brown Lobbying"))   title("Green Lobbying in 2000s")

* Economics Significance:
sort iyfe
by iyfe: egen sd_iyfe=sd(l_frac_approved) if l_ln_pat_gr>0  & my_sample==1
sort gvkey fyear
by gvkey: egen sd_firm=sd(l_frac_approved) if l_ln_pat_gr>0  & my_sample==1

sum total_lob_assets_gb_dem if  l_ln_pat_gr>0  & my_sample==1
* Use SD here:
sum l_frac_approved if  l_ln_pat_gr>0  & my_sample==1
* Use mean here:
sum sd_firm  if l_ln_pat_gr>0  & my_sample==1
sum sd_iyfe  if l_ln_pat_gr>0  & my_sample==1



/* Republican Contributions with Art and Tclass FEs*/
*ln_rep
*total_lob_assets_gb_rep
cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"
xtset ffi
xi: xtivreg2 total_lob_assets_gb_rep  l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if  l_ln_pat_gr>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_7_rep.doc, replace ctitle(Republican Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Green/Brown Lobbying")
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_7_rep.doc, append ctitle(Republican Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7_rep.doc, append ctitle(Republican Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7_rep.doc, append ctitle(Republican Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7_rep.doc, append ctitle( Republican Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7_rep.doc, append ctitle(Republican Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons


/* Democratic Contributions with Art and Tclass FEs*/
*ln_dem
*total_lob_assets_gb_dem
xtset ffi
xi: xtivreg2 total_lob_assets_gb_dem l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 
outreg2 using table_7_dem.doc, replace ctitle(Democratic Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Green/Brown Lobbying")
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_dem l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7_dem.doc, append ctitle(Democratic Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_dem l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7_dem.doc, append ctitle(Democratic Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 total_lob_assets_gb_dem l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7_dem.doc, append ctitle(Democratic Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_dem l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7_dem.doc, append ctitle(Democratic Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_dem  l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7_dem.doc, append ctitle(Democratic Lobbying$ /Assets) keep(l_frac_approved $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons


sort gvkey fyear 
by gvkey: gen cumul_innov=sum(l_total_grant_gr_this_y)
xtile innov_q = cumul_innov if l_ln_pat_gr>0  & my_sample==1, nq(2)

xtset ffi
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & innov_q==1, fe robust ffirst 
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & innov_q==1, fe robust ffirst 
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & innov_q==1, fe robust ffirst 
xtset ffi
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & innov_q==2, fe robust ffirst 
xtset iyfe
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & innov_q==2, fe robust ffirst 
xtset gvkey
xi: xtivreg2 total_lob_assets_gb_rep l_ln_pat_gr  $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 & innov_q==2, fe robust ffirst 



/* Middle Contributions with Art and Tclass FEs*/

gen center_gb=total_lob_assets_gb_text- total_lob_assets_gb_rep - total_lob_assets_gb_dem
replace center_gb=0 if missing(center_gb)

hist t_lob_rep_pct_all if dummy_mid==0 & l_ln_pat_gr>0  & my_sample==1

gen hired_dem=1 if total_lob_sale_gb_dem>0
replace hired_dem=0 if missing(hired_dem)
gen hired_rep=1 if total_lob_sale_gb_rep>0
replace hired_rep=0 if missing(hired_rep)
gen hired_mid=1 if total_lob_sale_gb_mid>0
replace hired_mid=0 if missing(hired_mid)

* Econ Significance within firm 
by gvkey: egen sd_firm=sd(l_frac_approved)
sum sd_firm  if l_ln_pat_gr>0  & my_sample==1
sum total_lob_assets_gb_mid if  l_ln_pat_gr>0  & my_sample==1
sum t_lob_mid_gr if  l_ln_pat_gr>0  & my_sample==1
sort iyfe
by iyfe: egen sd_iyfe=sd(l_frac_approved)
sum sd_firm  if l_ln_pat_gr>0  & my_sample==1

sum l_frac_approved if l_ln_pat_gr>0  & my_sample==1

*total_lob_assets_gb_mid
*center_gb
*ln_mid

xtset ffi
xi: xtivreg2 ln_mid l_ln_pat_gr   $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 
outreg2 using table_7_mid.doc, replace ctitle(Center Lobbying$ /Sales) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Green/Brown Lobbying")
xtset iyfe
xi: xtivreg2 ln_mid l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_art_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7_mid.doc, append ctitle(Center Lobbying$ /Sales) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
xtset gvkey
xi: xtivreg2 ln_mid l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_art_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7_mid.doc, append ctitle(Center Lobbying$ /Sales) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni nocons
* Tech Class FE
xtset ffi
xi: xtivreg2 ln_mid l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7_mid.doc, append ctitle(Center Lobbying$ /Sales) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni   nocons 
xtset iyfe
xi: xtivreg2 ln_mid l_ln_pat_gr $l_controls_new_nohhi i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst  
outreg2 using table_7_mid.doc, append ctitle(Center Lobbying$ /Sales) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons
xtset gvkey
xi: xtivreg2 ln_mid l_ln_pat_gr $l_controls_new i.fyear (l_frac_approved  = l_av_appr_tclass_year_gr)   if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst  
outreg2 using table_7_mid.doc, append ctitle(Center Lobbying$ /Sales) keep(l_frac_approved l_ln_pat_gr $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES, Art Class x Year FE, NO, Tech Class x Year FE, YES) label noni nocons



			/* Does innovation in all patents affects Dem/Rep contributions ? */
			
* Michelle & Michela said it may help interpret
*ln_rep
*total_lob_assets_gb_rep
*total_lob_assets_rep
xtset ffi
xi: xtivreg2 total_lob_assets_rep  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8a.doc, replace ctitle( Republican Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Republican Lobbying")
xtset iyfe
xi: xtivreg2 total_lob_assets_rep  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Republican Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset gvkey
xi: xtivreg2 total_lob_assets_rep  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Republican Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons 
xtset ffi
xi: xtivreg2 total_lob_assets_rep  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Republican Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset iyfe
xi: xtivreg2 total_lob_assets_rep  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Republican Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset gvkey
xi: xtivreg2 total_lob_assets_rep  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Republican Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  

*ln_dem
*total_lob_assets_gb_dem
*total_lob_assets_dem
xtset ffi
xi: xtivreg2 total_lob_assets_dem  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8b.doc, replace ctitle( Democratic Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons title("Table 6 IV for Determinants of Democratic Lobbying")
xtset iyfe
xi: xtivreg2 total_lob_assets_dem  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8b.doc, append ctitle( Democratic Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset gvkey
xi: xtivreg2 total_lob_assets_dem  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_art_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8b.doc, append ctitle( Democratic Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset ffi
xi: xtivreg2 total_lob_assets_dem  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8b.doc, append ctitle( Democratic Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset iyfe
xi: xtivreg2 total_lob_assets_dem  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8b.doc, append ctitle( Democratic Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  
xtset gvkey
xi: xtivreg2 total_lob_assets_dem  l_ln_pat $l_controls_new i.fyear (l_frac_approved_all  = l_av_appr_tclass_year) if  l_ln_pat>0  & my_sample ==1 , fe robust ffirst
outreg2 using table_8b.doc, append ctitle( Democratic Lobbying$ /Assets) keep(l_frac_approved_all l_ln_pat $l_controls_new) addstat("F-stat", e(widstat))  addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO, Art Class x Year FE, YES, Tech Class x Year FE, NO) label noni   nocons  























				/* Republican Contributions */
				xtset fyear
				xtivreg2 dollar_rep_lobby $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
				outreg2 using table_7rep.doc, replace ctitle( Republican Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
				xtset ffi
				xtivreg2 dollar_rep_lobby $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
				outreg2 using table_7rep.doc, append ctitle( Republican Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
				xtset iyfe
				xtivreg2 dollar_rep_lobby $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
				outreg2 using table_7rep.doc, append ctitle( Republican Lobbying$ /Sales) keep(l_frac_approved $l_controls_new_nohhi) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
				xtset gvkey
				xtivreg2 dollar_rep_lobby $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1, fe robust ffirst
				outreg2 using table_7rep.doc, append ctitle( Republican Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  title("Table 6 IV for Determinants of Lobbying") nocons

				/* Democratic Contributions */
				xtset fyear
				xtivreg2 dollar_dem_lobby $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
				outreg2 using table_7dem.doc, replace ctitle( Democarat Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
				xtset ffi
				xtivreg2 dollar_dem_lobby $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
				outreg2 using table_7dem.doc, append ctitle( Democarat Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
				xtset iyfe
				xtivreg2 dollar_dem_lobby $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
				outreg2 using table_7dem.doc, append ctitle( Democarat Lobbying$ /Sales) keep(l_frac_approved $l_controls_new_nohhi) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
				xtset gvkey
				xtivreg2 dollar_dem_lobby $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
				outreg2 using table_7dem.doc, append ctitle( Democarat Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  title("Table 6 IV for Determinants of Lobbying") nocons


drop dollar_dem_lobby dollar_rep_lobby  mostly_dem_lobby mostly_rep_lobby dummy_*



* Table 8A - determinants of Maybe Green/Brown lobbying 
xtset fyear
xtivreg2 total_lob_sale_gb_text_maybe   $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_8a.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 total_lob_sale_gb_text_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 total_lob_sale_gb_text_maybe $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 total_lob_sale_gb_text_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_8a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons

* Table 8B - determinants of Maybe Green/Brown lobbying 
gen dollar_dem_lobby_maybe = mostly_dem_lobby*total_lob_sale_gb_text_maybe
gen dollar_rep_lobby_maybe = mostly_rep_lobby*total_lob_sale_gb_text_maybe  

xtset fyear
xtivreg2 dollar_rep_lobby_maybe   $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_8rep.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 dollar_rep_lobby_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_8rep.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 dollar_rep_lobby_maybe $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_8rep.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 dollar_rep_lobby_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_8rep.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons

xtset fyear
xtivreg2 dollar_dem_lobby_maybe   $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_8dem.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 dollar_dem_lobby_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_8dem.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 dollar_dem_lobby_maybe $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_8dem.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 dollar_dem_lobby_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_8dem.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons

* Table 9 with NOT green/brown 
*some significance with total_lob_sale_not_maybe_gb
* Panel A
xtset fyear
xtivreg2 total_lob_sale_not_maybe_gb   $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_9a.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 total_lob_sale_not_maybe_gb $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_9a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 total_lob_sale_not_maybe_gb $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_9a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 total_lob_sale_not_maybe_gb $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_9a.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons

* Table 9B  
gen dollar_dem_lobby_not = mostly_dem_lobby*total_lob_sale_not_gb
gen dollar_rep_lobby_not = mostly_rep_lobby*total_lob_sale_not_gb  
gen dollar_dem_lobby_not_maybe = mostly_dem_lobby*total_lob_sale_not_maybe_gb
gen dollar_rep_lobby_not_maybe = mostly_rep_lobby*total_lob_sale_not_maybe_gb  

xtset fyear
xtivreg2 dollar_rep_lobby_not_maybe   $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_9rep.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 dollar_rep_lobby_not_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_9rep.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 dollar_rep_lobby_not_maybe $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_9rep.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 dollar_rep_lobby_not_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_9rep.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons

xtset fyear
xtivreg2 dollar_dem_lobby_not_maybe   $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_9dem.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 dollar_dem_lobby_not_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_9dem.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 dollar_dem_lobby_not_maybe $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
outreg2 using table_9dem.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 dollar_dem_lobby_not_maybe $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1 , fe robust ffirst
outreg2 using table_9dem.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons




* Table 10 - placebo test lobby(t) = B* patents(t+1)

* this placebo test doesn't work because our main regression uses patent APPlications instead of patent GRANTS in time t (CRSP-COmp merged on the date of patent application instead of a patent grant)
* this implies that the regression says that whenever a firm applies for a patent that is expected (?randomly through an examiner assignment) to be granted soon, then a firm decreases its lobbying 
*REDO main regressions using merge on patent GRANT date to say that whenever a firm gets a patent granted, it is reducing its lobbying (redo in SAS merge or STATA patent code, remerge there)

* ISSUE - merge on the filing date is only available for granted patents, we can't merge on grant date. then as a placebo we can use a bigger lag (5 years ?). does that change interpretation of results? LOOK AT HOW FARRE-MENSA ET AL INTERPRETED THEIR RESULTS OF PATENT GRANTS ON FINANCING, DID THEY TAKE A BIG LAG BETWEEN VARIABLES X ANY Y ??

global n_controls_new  "n_fluid n_hhi n_ln_at n_xrd n_mb n_roa n_ch n_capx"


sort gvkey fyear
by gvkey: gen n_frac_approved_all= total_grant[_n+5]/ total_appl[_n+5]
by gvkey: gen n_av_approval = av_approval[_n+5]
by gvkey: gen n_ln_pat = ln_pat[_n+5]

by gvkey: gen n_fluid = prodmktfluid[_n+5]
by gvkey: gen n_hhi = hhi[_n+5]
by gvkey: gen n_xrd = xrd[_n+5]
by gvkey: gen n_mb = mb[_n+5]
by gvkey: gen n_roa = roa[_n+5]
by gvkey: gen n_ch = ch[_n+5]
by gvkey: gen n_capx = capx[_n+5]
by gvkey: gen n_ln_at = ln_at[_n+5]

* to correct for autocorrelation, use tsset with bw(3)
tsset gvkey fyear

xtset fyear
xtivreg2 total_lob_sale  $n_controls_new (n_frac_approved_all  = n_av_approval) if n_ln_pat>0 & my_sample==1 , fe robust ffirst 
outreg2 using table_7b.doc, replace ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  title("Table 6 IV for Determinants of Lobbying") nocons
xtset ffi
xtivreg2 total_lob_sale  $n_controls_new (n_frac_approved_all  = n_av_approval) if n_ln_pat>0  & my_sample==1 , fe robust ffirst   
outreg2 using table_7b.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni   nocons
xtset iyfe
xtivreg2 total_lob_sale  $n_controls_new (n_frac_approved_all  = n_av_approval) if n_ln_pat>0  & my_sample==1 , fe  robust ffirst 
outreg2 using table_7b.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, NO, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni nocons
xtset gvkey
xtivreg2 total_lob_sale  $n_controls_new (n_frac_approved_all  = n_av_approval) if n_ln_pat>0 & my_sample==1 , fe  robust ffirst  
outreg2 using table_7b.doc, append ctitle( Lobbying$ /Sales) keep(l_frac_approved_all $l_controls_new) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  nocons






* Other specifications for Table 7C

gen gg=green_contrib_year_2 * total_lob_sale_gb
xtset fyear
xtivreg2 gg $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1  , fe robust ffirst
xtset ffi
xtivreg2 gg $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1, fe robust ffirst
xtset iyfe
xtivreg2 gg $l_controls_new_nohhi (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset gvkey
xtivreg2 gg $l_controls_new (l_frac_approved  = l_av_approval_gr) if l_ln_pat_gr>0 & my_sample==1, fe robust ffirst


/* sample size should be 1,425*/

/* DEM interaction Contributions - interaction then means $ to Democrats, and just approval rate is $ to Rep */
gen DEM =1 if green_contrib_year>0.5 & !missing(green_contrib_year)
replace DEM=0 if missing(DEM) 
gen l_frac_approved_DEM = DEM*l_frac_approved
gen l_av_approval_gr_DEM = DEM* l_av_approval_gr

* also works with total_lob_sale_gb
xtset fyear
xtivreg2 total_lob_sale_gb_text DEM $l_controls_new (l_frac_approved_DEM l_frac_approved = l_av_approval_gr_DEM l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset ffi
xtivreg2 total_lob_sale_gb_text DEM $l_controls_new (l_frac_approved_DEM l_frac_approved = l_av_approval_gr_DEM l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
xtset iyfe
xtivreg2 total_lob_sale_gb_text DEM $l_controls_new_nohhi (l_frac_approved_DEM l_frac_approved = l_av_approval_gr_DEM l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset gvkey
xtivreg2 total_lob_sale_gb_text DEM $l_controls_new (l_frac_approved_DEM l_frac_approved = l_av_approval_gr_DEM l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst


/* REP interaction Contributions - interaction then means $ to Democrats, and just approval rate is $ to Rep */
gen REP =1 if green_contrib_year<0.5 & !missing(green_contrib_year)
replace REP=0 if missing(REP) & !missing(green_contrib_year) 
gen l_frac_approved_REP = REP*l_frac_approved
gen l_av_approval_gr_REP = REP* l_av_approval_gr

* also works with total_lob_sale_gb
xtset fyear
xtivreg2 total_lob_sale_gb_text REP  $l_controls_new (l_frac_approved_REP l_frac_approved = l_av_approval_gr_REP l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset ffi
xtivreg2 total_lob_sale_gb_text REP $l_controls_new (l_frac_approved_REP l_frac_approved = l_av_approval_gr_REP l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst
xtset iyfe
xtivreg2 total_lob_sale_gb_text REP $l_controls_new_nohhi (l_frac_approved_REP l_frac_approved = l_av_approval_gr_REP l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset gvkey
xtivreg2 total_lob_sale_gb_text REP $l_controls_new (l_frac_approved_REP l_frac_approved = l_av_approval_gr_REP l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst


gen l_frac_approved_CONTR = green_contrib_year*l_frac_approved
gen l_av_approval_gr_CONTR = green_contrib_year* l_av_approval_gr



xtset fyear
xtivreg2 total_lob_sale_gb green_contrib_year $l_controls_new (l_frac_approved_CONTR l_frac_approved = l_av_approval_gr_CONTR l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset ffi
xtivreg2 total_lob_sale_gb green_contrib_year $l_controls_new (l_frac_approved_CONTR l_frac_approved = l_av_approval_gr_CONTR l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset iyfe
xtivreg2 total_lob_sale_gb green_contrib_year $l_controls_new (l_frac_approved_CONTR l_frac_approved = l_av_approval_gr_CONTR l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst
xtset gvkey
xtivreg2 total_lob_sale_gb green_contrib_year $l_controls_new (l_frac_approved_CONTR l_frac_approved = l_av_approval_gr_CONTR l_av_approval_gr) if l_ln_pat_gr>0  & my_sample==1, fe robust ffirst



drop DEM l_frac_approved_DEM l_av_approval_gr_DEM



****

gen REP=1 if total_lob_assets_gb_rep>0
replace REP=0 if missing(REP)
gen DEM=1 if total_lob_assets_gb_dem>0
replace DEM=0 if missing(DEM)

gen l_frac_approved_REP = REP*l_frac_approved
gen l_av_approval_gr_REP = REP* l_av_appr_art_year_gr
gen l_frac_approved_DEM = DEM*l_frac_approved
gen l_av_approval_gr_DEM = DEM* l_av_appr_art_year_gr


xtset ffi
xi: xtivreg2 total_lob_assets_gb_text REP  $l_controls_new i.fyear (l_frac_approved l_frac_approved_REP = l_av_appr_art_year_gr l_av_approval_gr_REP) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 


xtset ffi
xi: xtivreg2 total_lob_assets_gb_text DEM  $l_controls_new i.fyear (l_frac_approved l_frac_approved_DEM = l_av_appr_art_year_gr l_av_approval_gr_DEM) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 





*** Trial with % of Dem transactions ****
replace t_lob_dem_pct=0 if missing(t_lob_dem_pct)
gen pct_l_frac = t_lob_dem_pct * l_frac_approved
gen pct_l_av = t_lob_dem_pct * l_av_appr_art_year_gr

xtset ffi
xi: xtivreg2 total_lob_assets_gb_text t_lob_dem_pct  $l_controls_new i.fyear (l_frac_approved pct_l_frac = l_av_appr_art_year_gr pct_l_av) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 

gen pct_l_frac = t_lob_dem_pct * l_frac_approved
gen pct_l_av = t_lob_dem_pct * l_av_appr_art_year_gr



replace t_lob_rep_pct=0 if missing(t_lob_rep_pct)
gen rpct_l_frac = t_lob_rep_pct * l_frac_approved
gen rpct_l_av = t_lob_rep_pct * l_av_appr_art_year_gr

xtset ffi
xi: xtivreg2 total_lob_assets_gb_text t_lob_rep_pct  $l_controls_new i.fyear (l_frac_approved rpct_l_frac = l_av_appr_art_year_gr rpct_l_av) if l_ln_pat_gr>0  & my_sample==1 , fe robust ffirst 

*********************************************



















