************************************************************************************************************ 
////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////         Lobbying        ////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////
************************************************************************************************************


					///* Lobbyists' contribution data - OpenSecret *///	

clear all

cd "R:\ps664\Data\Lobbying_OpenSecrets" 					
import excel "R:\ps664\Data\Lobbying_OpenSecrets\party_contrib_all.xlsx", sheet("party_contrib_2") firstrow
Cont_to_R Cont_to_D lobbyistname cont_green	

drop page_title I J A obs_number

rename LobbyistName  lobbyistname
sort lobbyistname year

drop if missing(lobbyistname)

by 	lobbyistname: gen Cont_to_R_y = sum(Total_to_R)			
by 	lobbyistname: gen Cont_to_D_y = sum(Total_to_D)	
drop Total_to_R Total_to_D Link

cd "R:\ps664\Data\Lobbying_OpenSecrets"
export delimited using party_contrib_all_yearly.csv, replace





clear all

cd "R:\ps664\Data\Lobbying_OpenSecrets" 					
import excel "R:\ps664\Data\Lobbying_OpenSecrets\party_contrib_all.xlsx", sheet("party_contrib_2") firstrow

drop if missing(LobbyistName)
drop A obs_number
sort Link year LobbyistName

*outreg2 using table_0.doc if my_sample==1, replace sum(detail) eqkeep(N mean p50 sd) keep($l_sum_stats) label title("Panel A - Firms that filed for ANY patents this year") sortvar($l_sum_stats) noni

duplicates drop year Link, force
duplicates drop LobbyistName, force

* total of 10,168 unique names (dupl names = 11428 - 10168 = 1,260 )
* total 10,557 = 11,858 - 10,557 = 1,301 duplicates





* or 
clear all
cd "R:\ps664\Data\Lobbying_OpenSecrets" 					
use lobbyists_list
rename LobbyistName lobbyistname

* 14759 lobbyists exist, 11873 we found on OpenSecret (80%)

* don't use obs_number, use unique lobbyist's name as an identifier
merge 1:m lobbyistname using party_contrib_all
keep if _merge==3


sort lobbyistname year 
by lobbyistname: gen l_Total_to_D=Total_to_D[_n-1]
by lobbyistname: gen l_Total_to_R=Total_to_R[_n-1]
corr l_Total_to_D Total_to_D
corr l_Total_to_R Total_to_R

* find average autocorrelation among (corr (Rep t , Rep t+1))
sort  lobbyistname year
by  lobbyistname: egen aut_corr = corr(l_Total_to_D Total_to_D)
by  lobbyistname: egen aut_corr_R = corr(l_Total_to_R Total_to_R)

replace aut_corr=1 if missing(aut_corr) & !missing(l_Total_to_D) & !missing(Total_to_D)
replace aut_corr_R=1 if missing(aut_corr_R) & !missing(l_Total_to_R) & !missing(Total_to_R)



egen c = corr(l_Total_to_D Total_to_D)

.pwcorr l_Total_to_D Total_to_D


* Table 4 
sort  lobbyistname year
duplicates drop lobbyistname year, force

gen total_per_year=Total_to_D+Total_to_R
replace total_per_year=. if total_per_year==0
by lobbyistname: egen av_per_year=mean(total_per_year)


gen positive=1 if total_per_year>0 & !missing(total_per_year)
replace positive=0 if missing(positive)
by lobbyistname: egen years_active=sum(positive)

gen n=1
gen donated = 1 if Total_to_R>0 | Total_to_D>0
by lobbyistname: egen has_years = sum(n)
by lobbyistname: egen has_years_donated = sum(donated)

by lobbyistname: egen total_to_R= sum(Total_to_R)
gen donates_to_R=1 if total_to_R>0
replace donates_to_R=0 if missing(donates_to_R)
by lobbyistname: egen year_average_to_R= mean(Total_to_R) if donates_to_R==1

by lobbyistname: egen total_to_D= sum(Total_to_D)
gen donates_to_D=1 if total_to_D>0
replace donates_to_D=0 if missing(donates_to_D)
by lobbyistname: egen year_average_to_D= mean(Total_to_D) if donates_to_D==1

by lobbyistname: gen total= total_to_R+total_to_D
gen t=Total_to_R+Total_to_D
by lobbyistname: egen year_average_any= mean(t)

sum av_per_year if av_per_year>0, detail
label variable has_years "# Years in which lobbyist is recorded in OpenSecrets"
label variable has_years_donated "# Years in which lobbyist has positive Contributions"

label variable total "Total $ Donated"
label variable year_average_any "Average Yearly $ Amount Donated"
label variable av_per_year "Avg Amount Donated by Lobbyist per year, among years with positive donations"

label variable total_to_R "Lifetime Total Donations to Republicans"
label variable donates_to_R "  Pct of people who donate to Republicans"
label variable year_average_to_R "  Avg donations, among people who donate to Republicans"

label variable total_to_D "Lifetime Total Donations to Democrats"
label variable donates_to_D "  Pct of people that donate to Democrats"
label variable year_average_to_D "  Avg donations, among people who donate to Democrats"

* correlation bw D and R
keep if total_per_year>0
corr Total_to_D Total_to_R

sort Link year lobbyistname
duplicates drop lobbyistname, force


* New Table 
keep if total>0
sum has_years, detail
sum av_per_year, detail
sum total_to_D, detail
sum year_average_to_D, detail
sum total_to_R, detail
sum year_average_to_R, detail

* % of lobbyists making >90% to Rep 
gen prop_R=total_to_R/(total_to_D+total_to_R)
* % of lobbyists making >90% to Rep 
gen prop_D=total_to_D/(total_to_D+total_to_R)



hist prop, percent
sum year if prop_R>0.9 & !missing(prop_R)
sum year if prop_D>0.9 & !missing(prop_D)
* 2,389/11,873 = 20.12
* 2,354/11,873 = 19.83

cd "R:\ps664\Patent Applications - Michelle Michela\Fall Tables"	
global sum_lobbyists "has_years has_years_donated total year_average_any total_to_R donates_to_R year_average_to_R total_to_D donates_to_D year_average_to_D"

outreg2 using table_lobbyists.doc , replace sum(detail) eqkeep(N mean p25 p50 p75 sd) keep($sum_lobbyists) label title("Lobbyists' Political Contributions") sortvar($l_sum_stats) noni


sum n has_years min_year max_year total_to_R year_average_to_R total_to_D  year_average_to_D total year_average_any

sort year
by year: egen lobbyists_available=sum(has_years)
duplicates drop year, force

gen y = year-2000
graph bar lobbyists_available, over(y)  ytitle("N of Lobbyists") title("Number of Lobbyists with Political Contributions in 2000s")

* Total unique names found: 10168/(10168+3333) = 75 % 
* Total unique names found: 10557/(10557+2902) = 78 % 




clear all
cd "R:\ps664\Patent Applications - Michelle Michela\More Data\"
use transaction_data

duplicates drop  gvkey fyear ID LobbyistName, force

gen prop_rep = Cont_to_R / (Cont_to_D+Cont_to_R)
gen democrat=1 if prop_rep<0.5 & !missing(prop_rep)
gen republican=1 if prop_rep>0.5 & !missing(prop_rep)
replace democrat=0 if republican==1
replace republican=0 if democrat==1
sort gvkey fyear ID
by gvkey fyear ID: egen n_of_democrats=sum(democrat)
by gvkey fyear ID: egen n_of_republicans=sum(republican)
by gvkey fyear ID: egen pct_democrats = mean(democrat)
by gvkey fyear ID: egen pct_republicans = mean(republican)

gen official_lobbyist=1 if LobbyistCoveredGovPositionIndica=="COVERED"
by gvkey fyear ID: egen official_lobbyists = max(official_lobbyist)
replace official_lobbyists=0 if missing(official_lobbyists)

keep  gvkey fyear ID n_of_democrats n_of_republicans pct_democrats pct_republicans  official_lobbyists 

duplicates drop  gvkey fyear ID, force

destring gvkey, replace
sa transaction_data_aggr, replace


					///* Lobbying - Transaction-level data, Plot time trend of firm lobbying in Dollar amount (inflation unadjusted)*///							

clear all
cd "R:\ps664\Patent Applications - Michelle Michela"
use lob_stats, replace

* were 138,484 obs with crsp-compustat
* 358,444 with compustat only

				* Figure 1 and Figure 2	
				replace Amount=5000 if missing(Amount)
				winsor2 Amount, cuts(1 99)  				
				sort fyear gvkey conm Amount ID
				by fyear: egen year_lob_w=sum(Amount_w)
				gen h=1 
				by fyear: egen year_ld2s = sum(h)

				* graph without outliers
				duplicates drop fyear , force
				gen y=fyear-2000
				replace year_lob_w=year_lob_w/1000000

				set scheme s1mono

				graph bar year_ld2s if y>=0, over(y)  bar(1, fcolor(eltblue)) ytitle("Total N of LD-2s ") title("Distribution of the number of transactions (LD-2s)" "per year in 2000s")
				graph bar  year_lob_w if y>=0, over(y)  bar(1, fcolor(eltblue)) ytitle("Total Firm Lobbying in millions") title("Distribution of dollars spent lobbying," "per year in 2000s")



*drop if missing(Amount)
 drop green_lobby
gen green_lobby=1 if code_ENG==1 | code_ENV==1 | code_FUE==1 | code_CAW==1 | code_WAS==1 
replace green_lobby=0 if missing(green_lobby)

* calculate Market Cap in mill 

//////////////////* Sample selection*////////////////////

* CAREFUL - THIS DATASET IS NOT FIRM-YEAR, ITS FIRM-YEAR-Lobbying_transaction

label variable mkt_value "Market Cap in mill"

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

* Following Huneeus & Kim (2019) I dropped dupliates from Amended reports
drop if strpos(Type, "AMEND")
drop if strpos(Type, "AMENDMENT")

/////////////////////////////////////////////////////////



* merge with bills

cd "R:\ps664\Data\Lobbying Bills\OpenSecrets"
rename ID uniqid
merge 1:m uniqid using transaction_bills
drop if _merge==2
drop _merge 
cd "R:\ps664\Patent Applications - Michelle Michela"

* merge with CAP codes 
gen bill_short = subinstr( bill_name , ".","",.)

cd "R:\ps664\Data\Lobbying Bills\Congr Bills Project"
merge m:1 congno bill_short using bill_CAP_code_used
drop if _merge==2
drop _merge
* 100 - democrat, 200 - republican
rename party sponsor_party
rename minor CAP_minor
rename major CAP_major
cd "R:\ps664\Patent Applications - Michelle Michela"

* merge with Congress.gov data
* Environmental protection total bills = 2894
cd "R:\ps664\Data\Lobbying Bills\Congress gov\Env_protection"
merge m:1 congno bill_short using all_env_prot_short
gen cong_gov_code="env_protection" if _merge==3
drop if _merge==2
drop _merge

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Energy"
merge m:1 congno bill_short using all_energy_short
replace cong_gov_code="energy" if _merge==3
drop if _merge==2
drop _merge
gen green_env_energy= max(green_cong_gov, energy)
replace green_env_energy=0 if missing(green_env_energy)
replace green_cong_gov=0 if missing(green_cong_gov)

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Public_lands_nat_res"
merge m:1 congno bill_short using all_public
replace cong_gov_code="public_land" if _merge==3
drop if _merge==2
drop _merge
replace green_cong_gov=0 if missing(green_cong_gov)

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Water_resource_dev"
merge m:1 congno bill_short using all_water_short
replace cong_gov_code="water" if _merge==3
drop if _merge==2
drop _merge
replace green_cong_gov=0 if missing(green_cong_gov)

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Animals"
merge m:1 congno bill_short using all_animals_short
replace cong_gov_code="animals" if _merge==3
drop if _merge==2
drop _merge

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Agr_food"
merge m:1 congno bill_short using all_agr_short
replace cong_gov_code="agriculture" if _merge==3
drop if _merge==2
drop _merge

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Science_tech"
merge m:1 congno bill_short using all_science_short
replace cong_gov_code="science" if _merge==3
drop if _merge==2
drop _merge

cd "R:\ps664\Data\Lobbying Bills\Congress gov\Tax"
merge m:1 congno bill_short using all_tax_short
replace cong_gov_code="tax" if _merge==3
drop if _merge==2
drop _merge

* Merge with Cosine Similarity Data
cd "R:\ps664\Data\Lobbying Data\temp files"
rename uniqid transaction_id
merge m:1 transaction_id  using final_set_no50_2
*merge m:1 transaction_id  using final_set_2
*merge m:1 transaction_id  using final_set_no50_3
*merge m:1 transaction_id  using final_set
*merge m:1 transaction_id  using final_set_no50
drop if _merge==2
drop _merge
				
ffind sich, newvar(ffi) type(48)
ffind sich, newvar(ffi_12) type(12)

			///* Textual Cosine Similarity Part *///
			
			* test whether cosine similarity with climate vocabulary of green transactions is sign higher than cos of other transactions
			* cosine is available for about 28k/65k or 43% of data
			gen green_bil = 1 if green_env_energy==1
			replace green_bil=0 if missing(green_bil)
			sort transaction_id 
			by transaction_id: egen green_bill=max(green_bil)
			
			duplicates drop transaction_id, force 
			replace green_lobby=0 if missing(green_lobby)
			gen green_bill_issue=1 if green_bill==1 | green_lobby==1
			replace green_bill_issue=0 if missing(green_bill_issue)
			ttest cosine, by(green_bill)
			ttest cosine, by(green_lobby)
			ttest cosine, by(green_bill_issue)

			* use median (50%) and 75% as benchmark
			sum cosine if green_bill_issue==1, detail
			gen bench_50=1 if cosine>.1856358 & green_bill_issue==0 & !missing(cosine) & !missing(transaction_id)
			gen bench_75=1 if cosine>.2803609 & green_bill_issue==0 & !missing(cosine) & !missing(transaction_id)
			gen bench_mean=1 if cosine>.205433 & green_bill_issue==0 & !missing(cosine) & !missing(transaction_id)
			* 50th percentile adds 1,900 observations (from 8,940 it is a 21% increase in the sample size)
			tab bench_50
			* 50th percentile adds 327 observations (from 8,940 it is a 3.6% increase in the sample size)
			tab bench_75
			* keep first 20 obs after the benchmark
			sort bench_50 cosine
			by bench_50: gen after_50=_n if bench_50==1 & _n<21
			gsort -bench_50 cosine
			sort bench_75 cosine
			by bench_75: gen after_75=_n if bench_75==1 & _n<21
			gsort -bench_75 cosine			
			sort bench_mean cosine
			by bench_mean: gen after_mean=_n if bench_mean==1 & _n<21
			gsort -bench_mean cosine			
			keep if !missing(after_75)| !missing(after_50) | !missing(after_mean)
			keep after_75 after_50 after_mean transaction_id cosine
			rename transaction_id ID
			cd "R:\ps664\Patent Applications - Michelle Michela"
			export delimited using after_benchmark.csv, replace
			
			hist cosine  if green_bill==1
			hist cosine  if green_bill==0
			hist cosine  if green_lobby==1
			hist cosine  if green_lobby==0
			hist cosine  if green_bill_issue==1
			hist cosine  if green_bill_issue==0
			
			sum cosine if green_bill==1
			sum cosine if green_bill==0
			sum cosine if green_lobby==1
			sum cosine if green_lobby==0
			sum cosine if green_bill_issue==1
			sum cosine if green_bill_issue==0
			

			* After including extended transactions
			gen bench_50=1 if cosine>.1856358 & green_bill_issue==0 & !missing(cosine) & !missing(transaction_id)
			gen bench_75=1 if cosine>.2803609 & green_bill_issue==0 & !missing(cosine) & !missing(transaction_id)
			gen bench_mean=1 if cosine>.205433 & green_bill_issue==0 & !missing(cosine) & !missing(transaction_id)
			replace bench_50=0 if missing(bench_50)
			replace bench_75=0 if missing(bench_75)
			replace bench_mean=0 if missing(bench_mean)
			* before
			sum cosine if green_bill_issue==1
			sum cosine if green_bill_issue==0
			
			sum cosine if green_bill_issue==1 
			sum cosine if bench_50==1
			sum cosine if green_bill_issue==0 & bench_50==0

			sum cosine if green_bill_issue==1 
			sum cosine if bench_75==1
			sum cosine if green_bill_issue==0 & bench_75==0
			
			sum cosine if green_bill_issue==1 
			sum cosine if bench_mean==1
			sum cosine if green_bill_issue==0 & bench_mean==0
			
			
			hist cosine  if green_bill_issue==1
			hist cosine  if green_bill_issue==0

			hist cosine  if green_bill_issue==1 | bench_50==1
			hist cosine  if green_bill_issue==0 & bench_50==0

			hist cosine  if green_bill_issue==1 | bench_75==1
			hist cosine  if green_bill_issue==0 & bench_75==0
			
			hist cosine  if green_bill_issue==1 | bench_mean==1
			hist cosine  if green_bill_issue==0 & bench_mean==0

			replace bench_50=1 if green_bill_issue==1
			replace bench_75=1 if green_bill_issue==1
			replace bench_mean=1 if green_bill_issue==1			
			ttest cosine, by(green_bill_issue)
			ttest cosine, by(bench_50)
			ttest cosine, by(bench_75)
			ttest cosine, by(bench_mean)
			
			gen extended_75 = 1 if bench_75==1
			gen extended_50 = 1 if bench_50==1 
			gen extended_main = 1 if bench_mean==1 
			replace extended_75=0 if green_bill_issue==1
			replace extended_main=0 if green_bill_issue==1
			replace extended_50=0 if green_bill_issue==1
			ttest cosine, by(extended_50)
			ttest cosine, by(extended_75)
			ttest cosine, by(extended_main)
			
			drop y
			gen y = fyear - 2000
			graph bar green_bill_issue  , over(y)  ytitle("% of green LD-2s") title("Green Lobbying over time")		
			
* data is on gvkey-year-transaction-bills level (average of 6 bills per trns, conditioning on bill info present)

* total of 120,967 out of 139,122 bills have CAP codes (87% of all bills have CAP codes) 
* out of all bills mentioned, 4.9% of bills are green (there can be 6 bills per transaction)
* table on all mentioned bills' CAP categories
tab CAP_major if !missing(bill_short)
rename transaction_id uniqid

sort gvkey fyear uniqid bill_short

* aggregate bill presence
gen bill_yes_bill=1 if !missing(bill_name)
replace bill_yes_bill=0 if missing(bill_yes_bill)
by gvkey fyear uniqid: egen bill_yes=max(bill_yes_bill)
replace bill_yes=0 if missing(bill_yes)
by gvkey fyear: egen bill_yes_year=max(bill_yes)
replace bill_yes_year=0 if missing(bill_yes_year)

* aggregate CAP codes for table 2 Panel d
gen cap_=1 if CAP_major==7
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_7=max(cap_)
drop cap_ 
gen cap_=1 if CAP_major==8
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_8=max(cap_)
drop cap_ 
gen cap_=1 if CAP_major==4
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_4=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==405
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_405=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==408
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_408=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==498
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_498=max(cap_)
drop cap_ 

gen cap_=1 if CAP_major==10
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_10=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1001
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1001=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1002
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1002=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1003
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1003=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1005
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1005=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1007
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1007=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1010
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1010=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1098
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1098=max(cap_)
drop cap_ 

gen cap_=1 if CAP_major==17
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_17=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1700
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1700=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==1798
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_1798=max(cap_)
drop cap_ 

gen cap_=1 if CAP_major==21
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_21=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==2100
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_2100=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==2103
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_2103=max(cap_)
drop cap_ 
gen cap_=1 if CAP_minor==2104
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen cap_2104=max(cap_)
drop cap_ 

* aggregate congress.gov codes for table 2 Panel d
gen congress_=1 if cong_gov_code=="agriculture"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_agr=max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="animals"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_animals=max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="energy"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_energy=max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="env_protection"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_envprot=max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="public_land"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_publand=max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="science"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_science=max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="tax"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_tax =max(congress_)
drop congress_ 
gen congress_=1 if cong_gov_code=="water"
sort gvkey fyear uniqid 
by gvkey fyear uniqid: egen congress_water =max(congress_)
drop congress_ 

* aggregate bill sponsort (party democrat or republican) for Table 3 Panel A
gen sponsor_dem_=1 if sponsor_party=="100"
gen sponsor_rep_=1 if sponsor_party=="200"
by gvkey fyear uniqid: egen sponsor_dem =sum(sponsor_dem_)
by gvkey fyear uniqid: egen sponsor_rep =sum(sponsor_rep_)
by gvkey fyear: gen sponsor_dem_year = sponsor_dem/n_of_bills_per_trans
by gvkey fyear: gen sponsor_rep_year =sponsor_rep/n_of_bills_per_trans
drop sponsor_dem sponsor_rep
by gvkey fyear uniqid: egen sponsor_dem =max(sponsor_dem_)
by gvkey fyear uniqid: egen sponsor_rep =max(sponsor_rep_) 
gen sponsor_yes_ = 1 if missing(sponsor_party)
by gvkey fyear uniqid: egen sponsor_yes = max(sponsor_yes_)
drop sponsor_rep_  sponsor_dem_ sponsor_yes_
 
* Create Green/Brown Bill dummies (CAP, issue, congress.gov)
* CAP codes
sort gvkey fyear uniqid bill_short
gen green_cap_tr_bill =1 if CAP_major==7
replace green_cap_tr_bill =1 if CAP_major==8
replace green_cap_tr_bill=0 if missing(green_cap_tr_bill)
by gvkey fyear uniqid: egen green_cap_tr = max(green_cap_tr_bill)
replace green_cap_tr=0 if missing(green_cap_tr)
by gvkey fyear: egen green_cap = max(green_cap_tr)
replace green_cap=0 if missing(green_cap)

gen maybe_green_cap_tr_bill =1 if CAP_major==4 | CAP_major==10 | CAP_major==17 | CAP_major==21
replace maybe_green_cap_tr_bill=0 if missing(maybe_green_cap_tr_bill)
by gvkey fyear uniqid: egen maybe_green_cap_tr = max(maybe_green_cap_tr_bill)
replace maybe_green_cap_tr=0 if missing(maybe_green_cap_tr)
by gvkey fyear: egen maybe_green_cap = max(maybe_green_cap_tr)
replace maybe_green_cap=0 if missing(maybe_green_cap)

* LD-2 issue code (line 15)
by gvkey fyear uniqid: egen green_issue_tr = max(green_lobby)
replace green_issue_tr=0 if missing(green_issue_tr)
by gvkey fyear: egen green_issue = max(green_lobby)
replace green_issue=0 if missing(green_issue)

* Congress.gov individual codes
gen cong_envprot=1 if cong_gov_code=="env_protection"
gen cong_energy=1 if cong_gov_code=="energy"
gen cong_publand=1 if cong_gov_code=="public_land"
gen cong_water=1 if cong_gov_code=="water"

by gvkey fyear uniqid: egen green_ENV_PROT_tr = max(cong_envprot)
replace green_ENV_PROT_tr=0 if missing(green_ENV_PROT_tr)
by gvkey fyear uniqid: egen green_ENV_PROT = max(green_cong_gov)
replace green_ENV_PROT=0 if missing(green_ENV_PROT)

by gvkey fyear uniqid: egen green_ENERG_tr = max(cong_energy)
replace green_ENERG_tr=0 if missing(green_ENERG_tr)
by gvkey fyear uniqid: egen green_ENERG = max(cong_energy)
replace green_ENERG=0 if missing(green_ENERG)

by gvkey fyear uniqid: egen green_PUBLAND_tr = max(cong_publand)
replace green_PUBLAND_tr=0 if missing(green_PUBLAND_tr)
by gvkey fyear uniqid: egen green_PUBLAND = max(cong_publand)
replace green_PUBLAND=0 if missing(green_PUBLAND)

by gvkey fyear uniqid: egen green_WATER_tr = max(cong_water)
replace green_WATER_tr=0 if missing(green_WATER_tr)
by gvkey fyear uniqid: egen green_WATER = max(cong_water)
replace green_WATER=0 if missing(green_WATER)

* Congress.gov green/brown
drop green_cong_gov
gen green_cong_gov_ = 1 if cong_envprot==1 | cong_energy==1
replace green_cong_gov_=0 if missing(green_cong_gov_)
by gvkey fyear uniqid: egen green_cong_gov_tr = max(green_cong_gov_)
by gvkey fyear: egen green_cong_gov = max(green_cong_gov_tr)

gen maybe_green_cong_gov_ = 1 if congress_animals==1 | congress_agr==1 | congress_science==1 | congress_tax==1 
replace maybe_green_cong_gov_=0 if missing(maybe_green_cong_gov_)
by gvkey fyear uniqid: egen maybe_green_cong_gov_tr = max(maybe_green_cong_gov_)
by gvkey fyear: egen maybe_green_cong_gov = max(maybe_green_cong_gov_tr)

* Green Lobbying = congress.gov + LD-2 line 15 
rename green_lobby green_line15
gen lobby_green_ = 1 if cong_envprot==1 | cong_energy==1 | green_line15==1
replace lobby_green_=0 if missing(lobby_green_)
by gvkey fyear uniqid: egen lobby_green_tr = max(lobby_green_)
by gvkey fyear: egen lobby_green = max(lobby_green_)

* Green Lobbying = congress.gov + LD-2 line 15 + LD-2 line 16 (we use mean of a green cosine distribution as a benchmark)
gen lobby_green_text_ = lobby_green_
replace lobby_green_text_=1 if cosine>.205433 & lobby_green_text_==0 & !missing(cosine) & !missing(uniqid)
replace lobby_green_text_=0 if missing(lobby_green_text_)
by gvkey fyear uniqid: egen lobby_green_text_tr = max(lobby_green_text_)
by gvkey fyear: egen lobby_green_text = max(lobby_green_text_)

* with LD-2 line 16 text, % of green LD-2s out of all LD-2s increase from 13.7% (8,940) to 16.63% (10,840 bench 50%)

			/* For Graph below - Green lobbying over time */
			gen green_bil = 1 if green_env_energy==1
			replace green_bil=0 if missing(green_bil)
			sort transaction_id 
			by transaction_id: egen green_bill=max(green_bil)
			
			duplicates drop transaction_id, force 
			replace green_lobby=0 if missing(green_lobby)
			gen green_bill_issue=1 if green_bill==1 | green_lobby==1
			replace green_bill_issue=0 if missing(green_bill_issue)

			drop y
			gen y = fyear - 2000
			graph bar lobby_green green_cong_gov green_issue, over(y)  ytitle("% of green LD-2s") title("Green Lobbying over time")			
			graph bar lobby_green_tr, over(y)  ytitle("% of green LD-2s") title("Green Lobbying over time")

* No CAP code
gen no_maj = 1 if missing(CAP_major)
by gvkey fyear uniqid: egen no_major = max(no_maj)
replace no_major=0 if missing(no_major)

/* transaction level sum stats (average of 19 lobbying transactions per firm, max 1228)*/

* aggregate data into gvkey-year-transaction
* drop duplicates fro same transactions targeting >1 bill 
sort gvkey fyear uniqid
duplicates drop gvkey fyear uniqid, force 

gen code_other = 1 if code_has==1 & missing(code_ENG) & missing(code_ENV) & missing(code_FUE) & missing(code_CAW) & missing(code_WAS) & missing(code_AER) & missing(code_AGR) & missing(code_ANI) & missing(code_AVI) & missing(code_CHM) & missing(code_MAN) & missing(code_MAR) & missing(code_NAT) & missing(code_RES) & missing(code_SCI) & missing(code_TRA) & missing(code_TAX) & missing(code_TRU) 

gen neither=1 if green_cap_tr==0 & maybe_green_cap_tr==0 & green_cong_gov_tr==0 & maybe_green_cong_gov_tr==0

* csho reported in mill and Amount not
gen amount_mktcap = Amount/ (csho*100000*prcc_f)

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
sa lob_additional_data, replace



			//* Merge lobbying firms to all firms *//
			destring gvkey, replace
			keep gvkey fyear uniqid bill_yes_year sponsor_dem_year sponsor_rep_year green_cap maybe_green_cap green_issue green_cong_gov maybe_green_cong_gov lobby_green lobby_green_text  /* LD-2 level data*/ bill_yes sponsor_dem sponsor_rep green_cap_tr maybe_green_cap_tr green_issue_tr green_cong_gov_tr maybe_green_cong_gov_tr lobby_green_tr lobby_green_text_tr n_of_bills_per_trans   green_ENV_PROT_tr 
			cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
			sa lob_details, replace


			
			
			
			
			

*********************** Tables *************************

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
clear all
use lob_additional_data, replace

destring gvkey, replace

cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\SP_500"
* Merge with S&P500
merge m:1 gvkey fyear using data_sp500
drop if _merge==2
drop _merge
replace sp_500=0 if missing(sp_500)

* Merge with S&P1500
merge m:1 gvkey fyear using data_sp1500
drop if _merge==2
drop _merge 
replace sp_1500=0 if missing(sp_1500)


keep if fyear>=2000
keep if fyear<=2018

drop amount_mktcap
* csho reported in mill and Amount not
gen amount_mktcap = Amount/ (csho*100000*prcc_f)

replace Amount=5000 if missing(Amount) & !missing(uniqid)
winsor2 Amount, cuts(1 99)	

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
merge m:1 fyear gvkey using app_pat_yearly_updated_
keep if _merge==3 | _merge==1
drop _merge
cd "R:\ps664\Patent Applications - Michelle Michela"

cd "R:\ps664\Patent Applications - Michelle Michela\Winter Tables"	


* Figure 1 
sort fyear gvkey uniqid
gen h=1
by fyear: egen all_ld2s=sum(h)
drop h
by fyear: egen all_ld2s_sp_1500=sum(sp_1500)
gen y_ld2_filed=year(date_filed) - 2000

gen Amount_sp1500=Amount if sp_1500==1
by fyear: egen ld2_amount_sp_1500=sum(Amount_sp1500)
by fyear: egen ld2_amount=sum(Amount_w)
replace ld2_amount =ld2_amount/1000000 

graph bar all_ld2s if y_ld2_filed>=0, over(y_ld2_filed)  ytitle("") title("Distribution of the number of transactions (LD-2s)" "per year in 2000s")
*graph bar all_ld2s_sp_1500 if y_ld2_filed>=0, over(y_ld2_filed)  ytitle("") title("Distribution of the number of transactions (LD-2s)" "per year in 2000s")

graph bar ld2_amount if y_ld2_filed>=0, over(y_ld2_filed)  ytitle("$ Million") title("Distribution of dollars spent lobbying" "per year in 2000s")


		/* Table 4 - sample composition */
		

sum Amount_w amount_mktcap 

* Overall
keep if sp_1500==1

sum Amount_w amount_mktcap 

* line 15, lobby code
sum Amount_w amount_mktcap if code_has==1
sum Amount if lobby_green_tr==1
sum Amount_w if  code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  
sum Amount if lobby_green_tr==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  

* line 16, congress.gov
sum Amount_w if !missing(bill_name) | !missing(cosine)
unique(gvkey fyear) if  !missing(bill_name) | !missing(cosine)
sum Amount_w amount_mktcap if  bill_yes==1
sum Amount_w if  green_cong_gov_tr==1
sum Amount_w if maybe_green_cong_gov_tr==1
sum Amount_w if  green_cong_gov_tr==1 | maybe_green_cong_gov_tr==1

* both 
sum Amount_w if  green_cong_gov_tr==1 | lobby_green_tr==1
sum Amount_w if maybe_green_cong_gov_tr==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  
sum Amount_w if green_cong_gov_tr==1 | lobby_green_tr==1 |maybe_green_cong_gov_tr==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  

* text
sum Amount_w if  lobby_green_text_tr==1 & green_cong_gov_tr==0 &  lobby_green_tr==0
sum Amount_w if lobby_green_text_tr==1 
sum Amount_w if lobby_green_text_tr==1 & total_appl_gr>0

* potentially g/b line 16
* potentially g/b line 15
* potentially both



			/* Table 1 - (table's bottom row for n of LD-2s) */

gen my_sample=1 if fyear>2000 & fyear<=2018 & !missing(l_fluid) & !missing(l_capx) & sp_1500==1
replace my_sample=0 if missing(my_sample)

* Full Sample 
sum Amount_w 
* Any patent		
sum Amount_w if total_appl>0
* Green patent
sum Amount_w if total_appl_gr>0
* No patent
sum Amount_w if total_appl_gr==0
* lobby 
sum Amount_w  
* lobby on green/brown +text
sum Amount_w if lobby_green_text_tr==1
* lobby on green/brown 
sum Amount_w if lobby_green_tr==1
* not lobbying
* it's 0 


sort gvkey fyear
gen tr=1 if !missing(uniqid)
by gvkey fyear: egen total_ld2 = sum(tr)

drop tr 
gen tr=1 if total_appl>0
by gvkey fyear: egen total_ld2_pat = sum(tr)

drop tr 
gen tr=1 if total_appl_gr>0
by gvkey fyear: egen total_ld2_pat_gr = sum(tr)

drop tr 
gen tr=1 if total_appl_gr==0
by gvkey fyear: egen total_ld2_no_pat = sum(tr)

drop tr 
gen tr=1 if lobby_green_text_tr==1
by gvkey fyear: egen total_ld2_gb = sum(tr)

drop tr 
duplicates drop gvkey fyear, force

* # of Lobbying transactions / year row 
* Full Sample 
sum total_ld2
* Any patent		
sum total_ld2_pat if total_appl>0
* Green patent
sum total_ld2_pat_gr if total_appl_gr>0
* lobby 
sum total_ld2  
* lobby on green/brown +text
sum total_ld2_gb  

* # of Lobbying Green-Brown transactions / year row 

sum total_ld2_gb if total_ld2>0

sum total_ld2_gb if total_ld2_pat>0
sum total_ld2_gb if total_ld2_pat_gr>0
sum total_ld2_gb if total_ld2>0



		/* Table 2 - Issue Codes */

keep if sp_1500==1

*gen n=1 
gen obs_line16=1 if !missing(bill_name) | !missing(cosine)
* transfer lobbying $ into mill and then find it as % of total assets 
gen amount_at = (Amount_w/1000000)/at *1000000

 
* New Panel A
* 1
sum n obs_line16 Amount amount_at amount_mktcap 

sum code_ENG code_ENV code_FUE code_CAW code_WAS 
sum code_ENG code_ENV code_FUE code_CAW code_WAS  if !missing(cosine)
* 2 

* use unvinsorized values here because we winsorize at firm-year level
sum n obs_line16 Amount amount_at amount_mktcap if code_ENG==1
sum n obs_line16 Amount amount_at amount_mktcap if code_ENV==1
sum n obs_line16 Amount amount_at amount_mktcap if code_FUE==1
sum n obs_line16 Amount amount_at amount_mktcap if code_CAW==1
sum n obs_line16 Amount amount_at amount_mktcap if code_WAS==1

sum n obs_line16 Amount amount_at amount_mktcap if cap_7==1
sum n obs_line16 Amount amount_at amount_mktcap if cap_8==1

sum n obs_line16 Amount amount_at amount_mktcap if congress_envprot==1
sum n obs_line16 Amount amount_at amount_mktcap if congress_energy==1
sum n obs_line16 Amount amount_at amount_mktcap if congress_publand==1
sum n obs_line16 Amount amount_at amount_mktcap if congress_water==1

sum n obs_line16 Amount amount_at amount_mktcap if lobby_green_text_tr==1 & lobby_green_tr==0


* 3 

* With CAP codes:
gen definitely_green=1 if green_issue_tr==1 | green_cong_gov_tr==1 | lobby_green_text_tr==1
replace definitely_green=0 if missing(definitely_green)

gen potentially_green=1 if (green_issue_tr==0 & green_cong_gov_tr==0 & lobby_green_text_tr==0) & (maybe_green_cong_gov_tr==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  )

replace potentially_green=0 if missing(potentially_green)

* Without CAP codes: 
*gen definitely_green=1 if  code_ENG==1 | code_ENV==1 | code_FUE==1 | code_CAW==1 | code_WAS==1 |  congress_envprot==1 | congress_energy==1 | congress_publand==1 |  congress_water==1
*replace definitely_green=0 if missing(definitely_green)
*gen potentially_green=1 if (definitely_green==0) & (maybe_green_cong_gov_tr==1 | code_AER==1 | code_AGR==1 | code_ANI==1 | code_AVI==1 | code_CHM==1 | code_MAN==1 | code_MAR==1 | code_NAT==1 | code_RES==1 | code_SCI==1 | code_TRA==1 | code_TAX==1 | code_TRU==1  )
*replace potentially_green=0 if missing(potentially_green)

gen not_green = 1 if definitely_green==0 & potentially_green==0


sum n obs_line16 Amount_w amount_at amount_mktcap if definitely_green==1
sum n obs_line16 Amount_w amount_at amount_mktcap if potentially_green==1
sum n obs_line16 Amount_w amount_at amount_mktcap if not_green==1

sum n obs_line16 Amount_w amount_at amount_mktcap 


* Median column 
sum Amount , detail
sum Amount if code_ENG==1, detail
sum Amount if code_ENV==1, detail
sum Amount if code_FUE==1, detail
sum Amount if code_CAW==1, detail
sum Amount if code_WAS==1, detail

sum Amount if congress_envprot==1, detail
sum Amount if congress_energy==1, detail
sum Amount if congress_publand==1, detail
sum Amount if congress_water==1, detail

sum Amount if lobby_green_text_tr==1 & lobby_green_tr==0, detail

sum Amount  if definitely_green==1, detail
sum Amount  if potentially_green==1, detail
sum Amount  if not_green==1, detail

* New Panel B
ffind sich, newvar(ffi) type(48)
ffind sich, newvar(ffi_12) type(12)


tabstat n, by(ffi_12) stat(N) 
tabstat n if definitely_green==1, by(ffi_12) stat(N) 
tabstat n if potentially_green==1, by(ffi_12) stat(N) 
tabstat n if not_green==1, by(ffi_12) stat(N) 

sum Amount  if code_ENG==1 |  code_ENV==1 | code_FUE==1 | code_CAW==1 | code_WAS==1 | congress_envprot==1 | congress_energy==1 | congress_publand==1 | congress_water==1  | lobby_green_text_tr==1, detail





* Pabel A

sum code_ENG code_ENV code_FUE code_CAW code_WAS 
sum code_ENG code_ENV code_FUE code_CAW code_WAS  if !missing(cosine)

sum code_AER code_AGR code_ANI code_AVI code_CHM code_MAN code_MAR code_NAT code_RES code_SCI code_TRA code_TAX code_TRU code_has code_other
sum code_AER code_AGR code_ANI code_AVI code_CHM code_MAN code_MAR code_NAT code_RES code_SCI code_TRA code_TAX code_TRU code_has code_other if !missing(cosine)

sum code_has
sum code_has if !missing(cosine)

sum Amount_w amount_mktcap if code_ENG==1
sum Amount_w amount_mktcap if code_ENV==1
sum Amount_w amount_mktcap if code_FUE==1
sum Amount_w amount_mktcap if code_CAW==1
sum Amount_w amount_mktcap if code_WAS==1

sum Amount_w amount_mktcap if code_AER==1
sum Amount_w amount_mktcap if code_AGR==1
sum Amount_w amount_mktcap if code_ANI==1
sum Amount_w amount_mktcap if code_AVI==1
sum Amount_w amount_mktcap if code_CHM==1
sum Amount_w amount_mktcap if code_MAN==1
sum Amount_w amount_mktcap if code_MAR==1
sum Amount_w amount_mktcap if code_NAT==1
sum Amount_w amount_mktcap if code_RES==1
sum Amount_w amount_mktcap if code_SCI==1
sum Amount_w amount_mktcap if code_TRA==1
sum Amount_w amount_mktcap if code_TAX==1
sum Amount_w amount_mktcap if code_TRU==1
sum Amount_w amount_mktcap if code_other==1

* Panel B - transpose in excel
tabstat code_*, by(ffi_12) stat(N) 

tabstat code_* if ffi_12==12, by(ffi) stat(N) 


* Panel C
tabstat amount_mktcap if code_ENG==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_ENV==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_FUE==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_CAW==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_WAS==1, by(ffi_12) stat(mean) 

tabstat amount_mktcap if code_AER==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_AGR==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_ANI==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_AVI==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_CHM==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_MAN==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_MAR==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_NAT==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_RES==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_SCI==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_TRA==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_TAX==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_TRU==1, by(ffi_12) stat(mean) 
tabstat amount_mktcap if code_other==1, by(ffi_12) stat(mean) 

tabstat amount_mktcap , by(ffi_12) stat(mean) 

* Panel D
sum Amount amount_mktcap if cap_7==1
sum Amount amount_mktcap if cap_8==1

sum Amount amount_mktcap if congress_envprot==1
sum Amount amount_mktcap if congress_energy==1
sum Amount amount_mktcap if congress_publand==1
sum Amount amount_mktcap if congress_water==1

sum Amount amount_mktcap if cap_4==1
sum Amount amount_mktcap if cap_405==1
sum Amount amount_mktcap if cap_408==1
sum Amount_w amount_mktcap if cap_498==1
sum Amount amount_mktcap if cap_10==1
sum Amount amount_mktcap if cap_1001==1
sum Amount amount_mktcap if cap_1002==1
sum Amount amount_mktcap if cap_1003==1
sum Amount amount_mktcap if cap_1005==1
sum Amount amount_mktcap if cap_1007==1
sum Amount amount_mktcap if cap_1010==1
sum Amount amount_mktcap if cap_1098==1
sum Amount amount_mktcap if cap_17==1
sum Amount amount_mktcap if cap_1700==1
sum Amount amount_mktcap if cap_1798==1
sum Amount amount_mktcap if cap_21==1
sum Amount amount_mktcap if cap_2100==1
sum Amount amount_mktcap if cap_2103==1
sum Amount amount_mktcap if cap_2104==1

sum Amount amount_mktcap if congress_agr==1
sum Amount amount_mktcap if congress_animals==1
sum Amount amount_mktcap if congress_science==1
sum Amount amount_mktcap if congress_tax==1


* Table 3
* This table is for transactions with a bill nubmer (conditional on bill number mentioned, 27,166 LD-2s or 35% of the sample)

* Classified as green by CAP code - green_cap_tr   
* Classified as green by Congress.gov code - green_cong_gov_tr
* Classified as green by line15 or issue code - green_line15

* Panel A

sum code_* if bill_yes==1
sum code_* if  green_cap_tr==1 & bill_yes==1
sum code_* if  green_cong_gov_tr==1 & bill_yes==1
sum code_* if  maybe_green_cap_tr==1 & bill_yes==1
sum code_* if  maybe_green_cong_gov_tr==1 & bill_yes==1
sum code_* if  neither==1 & bill_yes==1

tab sponsor_dem  if green_cap_tr==1 & bill_yes==1 
tab sponsor_rep  if green_cap_tr==1 & bill_yes==1 
sum fyear if green_cap_tr==1 & bill_yes==1

tab sponsor_dem  if green_cong_gov_tr==1 & bill_yes==1 
tab sponsor_rep  if green_cong_gov_tr==1 & bill_yes==1
sum fyear if green_cong_gov_tr==1 & bill_yes==1

tab sponsor_dem  if maybe_green_cap_tr==1 & bill_yes==1 
tab sponsor_rep  if maybe_green_cap_tr==1 & bill_yes==1
sum fyear if maybe_green_cap_tr==1 & bill_yes==1

tab sponsor_dem  if maybe_green_cong_gov_tr==1 & bill_yes==1 
tab sponsor_rep  if maybe_green_cong_gov_tr==1 & bill_yes==1
sum fyear if maybe_green_cong_gov_tr==1 & bill_yes==1

tab sponsor_dem  if neither==1 & bill_yes==1 
tab sponsor_rep  if neither==1 & bill_yes==1 
sum fyear if neither==1 & bill_yes==1

tab sponsor_dem  if bill_yes==1 
tab sponsor_rep  if bill_yes==1 
sum fyear if bill_yes==1


* 35% of all lobbying public firms' transactions with non-missing amount info have bills information 
tab bill_yes 
tab no_major if bill_yes==1

* we have lobbyists' contribtuion data for 97% of all transaction 
* within each transaction, on average, we have 96%  (3.23/3.38) all mentioned lobbyists' contribtuions 
replace n_lobbyyists=0 if missing(n_lobbyyists)
replace n_lobbyyists=0 if missing(n_lobbyyists_w_data)
sum n_lobbyyists n_lobbyyists_w_data

gen lobbyists_known = n_lobbyyists_w_data/n_lobbyyists
hist lobbyists_known

tabstat Amount, by(cong_gov_code) stat(mean N) 

* count % of money contributed to democrats from all firm-year transactions 

* On the transaction level

* CAP green: environment, energy
* Lobby ISSUE green: oil, energy, environment, clean
* 10% of all transactions are green CAP - environment (if at least of the bills mentioned is green, then transaction is green)hist green_contrib, frequency title(Distibution of Lobbyists' Political Contributions) xtitle(% of a lobbyist's contribtions to the Democratic Party)  ytitle(Number of Lobbyists)

* 20% of all transactions are green CAP - energy or environment (if at least of the bills mentioned is green, then transaction is green)
* 14% of all transactions are green ISSUE - (if at least of the bills mentioned is green, then transaction is green)
* 12% of all transactions are green Congress.gov - environmental protection (if at least of the bills mentioned is green, then transaction is green)
* 19% of all transactions are green Congress.gov - energy or environmental protection (if at least of the bills mentioned is green, then transaction is green)

* correlation between the 2 measures on transaction level is 49%
* 73%
tab green_cap_tr if bill_yes==1
tab green_issue_tr if bill_yes==1
tab green_ENV_PROT_tr if bill_yes==1
tab green_ENV_ENERG_tr if bill_yes==1

corr green_issue_tr green_cap_tr green_ENV_PROT_tr green_ENV_ENERG_tr if bill_yes==1 & no_major==0


* there are 65,306 transactions with non-missing Amount info
tab fyear 


* firms lobby on 6 bills per transaction, conditional on mentioning bill informaiton
replace n_of_bills_per_trans=0 if missing(n_of_bills_per_trans)
sum n_of_bills_per_trans
sum n_of_bills_per_trans if n_of_bills_per_trans>0

gen y=fyear-2000
graph bar bill_yes , over(y)  ytitle("% of transactions with bills") title("Disclosure of bills in lobying transactions")



/* firm-year level sum stats */ 
duplicates drop gvkey fyear, force



graph bar lobby_green green_cong_gov green_issue, over(y)  ytitle("% of green LD-2s") title("Green Lobbying over time")

* 42% of all firm-years that lobbied have bill info (49% for S&P 1500 and 56% for S&P 500)
tab bill_yes_year

sum green_contrib_year
hist green_contrib_year
graph bar green_contrib_year, over(y) legend(label(1 "CAP green lobbying") label(2 "Issue code green lobbying"))  ytitle("% of firms lobbying green")  title("Green lobbying over time")


* 31% of all firm-years that lobbied are green (out of those that have bill info) (1238 firm-years)
* 24% of all firm-years that lobbied are green (out of those that have bill info) ISSUE (964 firm-years)
* 12% of all firm-years that lobbied are green (out of those that have bill info) (1238 firm-years)
* 20% of all firm-years that lobbied are green (out of those that have bill info) (1238 firm-years)

tab green_cap if bill_yes_year==1
tab green_issue if bill_yes_year==1
tab green_ENV_PROT if bill_yes==1
tab green_ENV_ENERG if bill_yes==1

* correlation between two measures is 49% (among the sample where both ISSUE and CAP is available)
corr green_issue green_cap green_ENV_PROT green_ENV_ENERG if bill_yes==1 & no_major==0


graph bar green_cap green_issue if bill_yes_year==1, over(y) legend(label(1 "CAP green lobbying") label(2 "Issue code green lobbying"))  ytitle("% of firms lobbying green")  title("Green lobbying over time")

graph bar green_cap green_issue green_ENV_PROT green_ENV_ENERG if bill_yes_year==1, over(y) legend(label(1 "CAP green lobbying") label(2 "Issue code green lobbying") label(3 "Env Prot green lobbying") label(4 "Env Prot & Energy green lobbying"))  ytitle("% of firms lobbying green")  title("Green lobbying over time")



/////////////////////////////////////////////////////////


replace inhouse=0 if missing(inhouse) & !missing(ID)
									 
order gvkey fyear conm Amount date_filed Type ID
sort gvkey fyear conm Amount ID



* Following Huneeus & Kim (2019) I dropped dupliates from Amended reports
drop if strpos(Type, "AMEND")
drop if strpos(Type, "AMENDMENT")


* unique lobbyists name 
* unique lobbyists firm  


* top 10 government lobbying where firms lobby 
					 

				* Sammury Stats table	
				
				winsor2 Amount, cuts(1 99)			
				sum Amount_w inhouse
				sort gvkey fyear

				by gvkey fyear: egen yearly_lob=sum(Amount_w)					 
				by gvkey: egen all_years_lob=sum(Amount_w)					 

				duplicates drop gvkey fyear, force
				sum yearly_lob if yearly_lob>0
				
				by gvkey: egen mean_yearly_lob=mean(yearly_lob)					 
				duplicates drop gvkey, force
				sum all_years_lob if all_years_lob>0
				gsort - all_years_lob

duplicates drop gvkey fyear conm Amount ID, force



* I further DO NOT DROP all reports with NO ACTIVITY
* (these are reports that are frequently duplicated too)
* I don't drop them because this is still money transfer from client (company eg Apple) 
* to lobbying firm even if the lobbying firm didn't lobby with these money
* Huneeus & Kim (2019) don't mention no activity reports
* https://lobbyingdisclosure.house.gov/ldaguidance.pdf



* total firm lobbying by year
sort gvkey fyear
by gvkey fyear: egen total_lob=sum(Amount)
duplicates drop gvkey fyear , force

* graph with outliers
plot  total_lob fyear



* for dollar amount lobbied, drop cases with no amount (as its recorded as infinity)
sort total_lob
drop if total_lob==0

winsor2 total_lob, cuts(0.1 99.9)
winsor2 total_lob, cuts(1 99) suffix(_w1)
* graph without outliers
plot  total_lob_w fyear

		
* total all firms' lobbying per year
sort fyear gvkey conm Amount ID
by fyear: egen year_lob_w=sum(total_lob_w)
by fyear: egen year_lob_w1=sum(total_lob_w1)
by fyear: egen year_lob=sum(total_lob)

gen portion= total_lob/year_lob


		
		
					
* graph without outliers
duplicates drop fyear , force
gen y=fyear-2000
replace year_lob=year_lob/1000000
replace year_lob_w=year_lob_w/1000000
replace year_lob_w1=year_lob_w1/1000000
graph bar year_lob , over(y)  ytitle("Total Firm Lobbying in millions") title("Firm Lobbying in 2000s")
graph bar year_lob_w, over(y)  ytitle("Total Firm Lobbying in millions") title("Firm Lobbying in 2000s - Winsorized at 0.1%")

* for proposal slides
graph bar year_lob_w1 if y>=0, over(y)  ytitle("$ millions") title("Total Firm Lobbying in 2000s")



*ylabel(2000(5)2015)

*yscale(range(2000 (5) 2015) titlegap(5))
*xscale(range(2000 2015) titlegap(5))

/////////////////* Get text o Democraticf transactions driving result *///////////////////

clear all
cd "R:\ps664\Patent Applications - Michelle Michela"

* CURRENT FILE RESTRICTS ON NON-MISSING PERMNO AND GVKEY
use lob_stats_full, replace

* missing amount in transactions indicates value less than 5000
replace Amount=5000 if missing(Amount) & !missing(ID)

destring gvkey, replace


* Drop financials
drop if sich>6000 & sich<6999
* Drop Utilities
drop if sich>=4900 & sich<=4949

ffind sich, newvar(ffi) type(12)

keep gvkey ffi fyear ID Amount Amount_gb_text all_lobb_cont_R all_lobb_cont_D n_lobbyyists  n_lobbyyists_w_data 

* Mark Democratic/Republican LD-2s
gen brown_contrib = all_lobb_cont_R/( all_lobb_cont_D+ all_lobb_cont_R)
gen green_contrib = all_lobb_cont_D/( all_lobb_cont_D+ all_lobb_cont_R)
gen rep_ld2=1 if brown_contrib>0.66 & brown_contrib<=1 & !missing(all_lobb_cont_R)
gen dem_ld2=1 if green_contrib>0.66 & green_contrib<=1 & !missing(all_lobb_cont_D)
gen middle_ld2=1 if green_contrib>=0.33 & green_contrib<=0.66 & !missing(all_lobb_cont_D)


cd "R:\ps664\Patent Applications - Michelle Michela\More Data"

merge m:1 gvkey fyear using drives_result

keep if _merge==3
drop _merge

replace rep_ld2=0 if missing(rep_ld2)
replace dem_ld2=0 if missing(dem_ld2)
replace middle_ld2=0 if missing(middle_ld2)

keep if !missing(ID)



tab ffi
tabstat rep_ld2 dem_ld2 middle_ld2 sponsor_dem_year sponsor_rep_year , by(ffi ) stat(mean) 


cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
export delimited using main_gb_sample.csv, replace

 


/////////////////* Lobbying - Make firm-year panel from firm-year-LD2 panel - Tables for lobbying firms*///////////////////

clear all
cd "R:\ps664\Patent Applications - Michelle Michela"

* CURRENT FILE RESTRICTS ON NON-MISSING PERMNO AND GVKEY
use lob_stats_full, replace

* missing amount in transactions indicates value less than 5000
replace Amount=5000 if missing(Amount) & !missing(ID)

destring gvkey, replace


//////////////////* Sample selection*////////////////////

* CAREFUL - THIS DATASET IS NOT FIRM-YEAR, ITS FIRM-YEAR-Lobbying_transaction

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

label variable at "Total Assets"
label variable xrd "R&D/Assets"
label variable mb "Market to Book"
label variable ch "Cash/Assets"
label variable net_sales "Net Sales/Assets"
label variable roa "ROA"
label variable mkt_value "Market Cap"
label variable age "Years Public"


gen sic= floor(sich/10)		
* Drop financials
drop if sich>6000 & sich<6999
* Drop Utilities
drop if sich>=4900 & sich<=4949

ffind sic, newvar(ffi) type(48)
egen iyfe=group(ffi fyear)

* Following Huneeus & Kim (2019) I dropped dupliates from Amended reports
drop if strpos(Type, "AMEND")
drop if strpos(Type, "AMENDMENT")


/////////////////////////////////////////////////////////


order gvkey fyear crsp_comp_name Amount ID
sort gvkey fyear crsp_comp_name Amount ID
duplicates drop gvkey fyear crsp_comp_name Amount ID, force

///////////////// Merge with Green/Brown lobbying transaction Dummy//////////////////////

*rename ID uniqid
cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
rename  ID uniqid
merge 1:1 gvkey fyear uniqid using lob_details
rename uniqid ID
drop if _merge==2
drop _merge

						* Histograms for Michelle's email
						* keep if sp_1500==1
						*label variable n_lobbyyists "N of lobbyists per LD2"
						*hist n_lobbyyists, percent
						*hist n_lobbyyists if lobby_green_text_tr==1, percent

						*sort gvkey fyear 
						*by gvkey fyear: egen all_lobbb = sum(n_lobbyyists)
						*by gvkey fyear: egen all_lobbb_g = sum(n_lobbyyists) if lobby_green_text_tr==1
						*by gvkey fyear: egen all_lobbb_gb = max(all_lobbb_g)

						*duplicates drop gvkey fyear, force

						*label variable all_lobbb_gb "N of lobbyists firm-year"
						*label variable all_lobbb "N of lobbyists firm-year"
						*hist all_lobbb , percent
						*hist all_lobbb_gb, percent





sort gvkey fyear ID

gen Amount_gb=Amount if lobby_green_tr==1
gen Amount_gb_text=Amount if lobby_green_text_tr==1

gen Amount_gb_maybe=Amount if maybe_green_cap_tr==1 | maybe_green_cong_gov_tr==1
gen Amount_gb_text_maybe=Amount if maybe_green_cap_tr==1 | maybe_green_cong_gov_tr==1

gen Amount_not_gb=Amount if lobby_green_text_tr!=1
gen Amount_not_maybe_gb=Amount if lobby_green_text_tr!=1 &  maybe_green_cap_tr!=1 & maybe_green_cong_gov_tr!=1


by gvkey fyear: egen t_lob_gb=sum(Amount_gb) 
by gvkey fyear: egen t_lob_gb_text=sum(Amount_gb_text) 
by gvkey fyear: egen t_lob=sum(Amount)

by gvkey fyear: egen t_lob_gb_maybe=sum(Amount_gb_maybe) 
by gvkey fyear: egen t_lob_gb_text_maybe=sum(Amount_gb_text_maybe) 

by gvkey fyear: egen t_lob_not_gb=sum(Amount_not_gb) 
by gvkey fyear: egen t_lob_not_maybe_gb =sum(Amount_not_maybe_gb) 

replace inhouse=0 if missing(inhouse)
by gvkey fyear: egen prop_inhouse =mean(inhouse) 


* Mark Democratic/Republican LD-2s
gen brown_contrib = all_lobb_cont_R/( all_lobb_cont_D+ all_lobb_cont_R)
gen green_contrib = all_lobb_cont_D/( all_lobb_cont_D+ all_lobb_cont_R)

* allowing for lobbyists to switch working for/contributing to different parties
gen brown_contrib_y = all_lobb_cont_R_y/( all_lobb_cont_D_y+ all_lobb_cont_R_y)
gen green_contrib_y = all_lobb_cont_D_y/( all_lobb_cont_D_y+ all_lobb_cont_R_y)



* sum all bills sponsored by republicans versus democrats 
gen bill_rep_ld2=1 if sponsor_rep_year>=0.9 & !missing(sponsor_rep_year) & sponsor_rep_year<=1 
gen bill_dem_ld2=1 if sponsor_dem_year>=0.9 & !missing(sponsor_dem_year) & sponsor_dem_year<=1 
gen bill_rep_amount = Amount_gb_text if bill_rep_ld2==1
gen bill_dem_amount = Amount_gb_text if bill_dem_ld2==1


* try middle transactions that are unclear
gen rep_mid_ld2=1 if sponsor_rep_year>=0.9 & !missing(sponsor_dem_year) & sponsor_dem_year<=1 & brown_contrib>=0.33 & brown_contrib<=0.66 & !missing(all_lobb_cont_R)
gen dem_mid_ld2=1 if sponsor_dem_year>=0.9 & !missing(sponsor_dem_year) & sponsor_dem_year<=1 & green_contrib>=0.33 & green_contrib<=0.66 & !missing(all_lobb_cont_D)
gen rep_mid_amount_gr = Amount_gb_text if rep_mid_ld2==1
gen dem_mid_amount_gr = Amount_gb_text if dem_mid_ld2==1


* try to scale each transaction's amount by the % of Democratic or Republican Affiliations involved
gen prop_rep = sponsor_rep_year*brown_contrib
gen prop_dem = sponsor_dem_year*green_contrib
gen prop_rep_amount = Amount_gb_text*prop_rep
gen prop_dem_amount = Amount_gb_text*prop_dem

cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
sa data_for_affil, replace

						
cd "R:\ps664\Data\Lobbying_OpenSecrets"		
merge m:m ID using ld2_m_lobbyist_contr				
drop if _merge==2
drop _merge



* Figure 4
gen h=1 if !missing(lobbyistname)
sort fyear lobbyistname
duplicates drop fyear lobbyistname, force
by fyear: egen all_lobbyists=sum(h) 
drop h
gen h=1 if (cont_to_r+cont_to_d)>0
by fyear: egen all_lobbyists_contr=sum(h) 

hist h, frequency title(Distibution of Lobbyists' Political Contributions) xtitle(% of a lobbyist's contribtions to the Democratic Party)  ytitle(Number of Lobbyists)
gen y = fyear-2000
graph bar all_lobbyists, over(y) bar(1, fcolor(eltblue)) ytitle("N of Lobbyists") title("Number of lobbyists with nonzero political contributions in 2000s")
graph bar all_lobbyists_contr, over(y) bar(1, fcolor(eltblue))  ytitle("N of Lobbyists") title("Number of lobbyists" "with positive political contributions in 2000s")

duplicates drop lobbyistname, force

gen prop_D = cont_to_d/(cont_to_r+cont_to_d)
gen prop_R = cont_to_r/(cont_to_r+cont_to_d)

hist prop_D, percent	fcolor(eltblue) ytitle("% of Lobbyists")  xtitle("% of a Lobbyist's Contributions to the Democratic Party") title("Distribution of Lobbyists' Political Contributions")		

hist prop_D, frequency	fcolor(eltblue) ytitle("N of Lobbyists")  xtitle("% of a Lobbyist's Contributions to the Democratic Party") title("Distribution of Lobbyists' Political Contributions")		

			
cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
clear all
use data_for_affil, replace 												
						
						
						cd "R:\ps664\Data\Lobbying_OpenSecrets"		
						merge m:m ID using ld2_m_lobbyist_contr				
						drop if _merge==2
						drop _merge
						

						gen prop_D = cont_to_d/(cont_to_r+cont_to_d)
						gen prop_R = cont_to_r/(cont_to_r+cont_to_d)

						gen democrat=1 if prop_D>=0.9 & !missing(prop_D)
						replace democrat=0 if missing(democrat) & !missing(prop_D)

						gen republican=1 if prop_R>=0.9 & !missing(prop_R)
						replace republican=0 if missing(republican) & !missing(prop_D)
						
						gen center=1 if prop_D<0.9 & prop_D>0.1 & !missing(prop_D)
						replace center=0 if missing(center) & !missing(prop_D)
						replace republican=. if center==1
						replace democrat=. if center==1
						
						sort RegistrantName
						duplicates drop RegistrantName lobbyistname, force
						
						* weoght lobbyists by the dollar amount
						by RegistrantName: egen all_Dem_dollar=sum(cont_to_d)
						by RegistrantName: egen all_Rep_dollar=sum(cont_to_r)							
						by RegistrantName: gen person_w_D = cont_to_d/all_Dem_dollar
						by RegistrantName: gen person_w_R = cont_to_r/all_Rep_dollar
						replace person_w_D=. if missing(democrat)
						replace person_w_R=. if missing(republican)
						
						* weighted
						by RegistrantName: egen w_av_affiliation=mean(democrat*person_w_D)
						by RegistrantName: egen w_av_affiliation_rep=mean(republican*person_w_R)
						
						* Another way to weight based on the sum(dollar contrib)
						gen percent_dem=all_Dem_dollar/(all_Dem_dollar+all_Rep_dollar)
						gen percent_rep=1-percent_dem
						
						* unweighted
						by RegistrantName: egen av_affiliation=mean(democrat)
						by RegistrantName: egen av_affiliation_rep=mean(republican)
						by RegistrantName: egen av_affiliation_center=mean(center)
						gen n=1
						sort RegistrantName lobbyistname			
						by RegistrantName: egen firm_workers=sum(n)

						* total of 2400 lobbying firms
						* with average company size 6 people
						drop n
						duplicates drop RegistrantName, force			
						hist av_affiliation, percent title("Lobbying Firms' Political Affiliation") xtitle("Proportion of Democrats in a firm")
						hist av_affiliation if firm_workers>2 , percent title("Lobbying Firms' Political Affiliation" "(firms with >2 lobbyists)") xtitle("Proportion of Democrats in a firm")
						
						keep RegistrantName av_affiliation firm_workers av_affiliation_center av_affiliation_rep w_av_affiliation w_av_affiliation_rep percent_dem percent_rep
						drop if missing(RegistrantName)
						cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
						sa lob_firm_affil_90_2, replace
			
						
						
						
						
			cd "R:\ps664\Data\Lobbying_OpenSecrets"		
			merge m:m ID using ld2_m_lobbyist_contr				
			drop if _merge==2
			drop _merge

			duplicates drop gvkey fyear ID lobbyistname, force						
			
			cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
			merge m:m RegistrantName using lob_firm_affil_90_2
			drop if _merge==2
			drop _merge

			sort gvkey fyear lobbyistname
			gen prop_D = cont_to_d/(cont_to_r+cont_to_d)
			gen prop_R = cont_to_r/(cont_to_r+cont_to_d)
			
			
			replace prop_D=1 if (av_affiliation>=0.9) & !missing(percent_dem) & !missing(lobbyistname) & missing(prop_D)
			replace prop_R=1 if (av_affiliation_rep>=0.9) & !missing(percent_rep) & !missing(lobbyistname) & missing(prop_R) 
			
			
			*centrists working in a Dem/Rep firm
			*replace prop_D=1 if (av_affiliation>=0.9) & (prop_D<0.66 & prop_D>0.33) & !missing(percent_dem) & !missing(lobbyistname) 
			*replace prop_R=1 if (av_affiliation_rep>=0.9) & (prop_R<0.66 & prop_R>0.33) & !missing(percent_rep) & !missing(lobbyistname) 
			
			* NO
			*replace prop_D=1 if (av_affiliation>av_affiliation_rep) & !missing(av_affiliation) & !missing(lobbyistname) & missing(prop_D)
			*replace prop_R=1 if (av_affiliation<av_affiliation_rep) & !missing(av_affiliation_rep) & !missing(lobbyistname) & missing(prop_R)
			
			
			*gen prop_R_1= prop_R
			*gen prop_R_2= prop_R
			*replace prop_R_2=av_affiliation_rep if av_affiliation_rep>=0.9 & !missing(av_affiliation_rep) & !missing(lobbyistname) & missing(prop_R)
			*replace prop_R_1=1-av_affiliation if ((1-av_affiliation)>=0.9) & !missing(av_affiliation) & !missing(lobbyistname) & missing(prop_R)			
			*replace prop_R_1=. if prop_R_2==prop_R_1
			
			*replace prop_D=av_affiliation if !missing(av_affiliation) & !missing(lobbyistname) & missing(prop_D)
			*replace prop_R=1-av_affiliation if !missing(av_affiliation) & !missing(lobbyistname) & missing(prop_R)
			
			
			gen democrat=1 if prop_D>=0.9 & !missing(prop_D)
			replace democrat=0 if missing(democrat) & !missing(prop_D)

			gen republican=1 if prop_R>=0.9 & !missing(prop_R)
			replace republican=0 if missing(republican) & !missing(prop_D)

			gen center=1 if prop_D<0.9 & prop_D>0.1 & !missing(prop_D)
			replace center=1 if prop_R<0.9 & prop_R>0.1 & !missing(prop_R)
			replace center=1 if av_affiliation_center>=0.9 & !missing(av_affiliation_center) 
			replace center=0 if missing(center) & !missing(prop_D) & !missing(prop_D)
			*replace republican=. if center==1
			*replace democrat=. if center==1


						* find the major contributor per LD-2
						sort gvkey fyear ID 
						by gvkey fyear ID: gen contr_all_lobbyist=(cont_to_d+cont_to_r)
						by gvkey fyear ID: egen max_contr=max(contr_all_lobbyist)
						
						* top 3 lobbyists
						gsort gvkey fyear ID -contr_all_lobbyist 
						by gvkey fyear ID: gen main_lobbyist=1 if _n<=3
						keep if main_lobbyist==1
						

						
			sort gvkey fyear ID
			by gvkey fyear ID: egen prop_Democrats=mean(democrat)
			by gvkey fyear ID: egen prop_Republicans=mean(republican)
			by gvkey fyear ID: egen prop_Center=mean(center)

			gen dem_ld2=1 if prop_Democrats>=0.9 & !missing(prop_Democrats)
			gen rep_ld2=1 if prop_Republicans>=0.9 & !missing(prop_Republicans)
			gen middle_ld2=1 if prop_Center>=0.9 & !missing(prop_Center)
						
			duplicates drop gvkey fyear ID, force	
			
			gen EPA =  strpos(GovEntityName, "(EPA)") > 0
			
			*Environmental Protection Agency (EPA)

			* mark each LD-2 as Dem or Rep based on Lobbyists' contributions
			*gen rep_ld2=1 if brown_contrib>0.5 & brown_contrib<=1 & !missing(all_lobb_cont_R)
			*gen dem_ld2=1 if green_contrib>0.5 & green_contrib<=1 & !missing(all_lobb_cont_D)
			*gen middle_ld2=1 if green_contrib>=0.33 & green_contrib<=0.66 & !missing(all_lobb_cont_D)
			
			*replace green_ENV_PROT_tr=0 if missing(green_ENV_PROT_tr)
			*replace rep_ld2=0 if green_ENV_PROT_tr==0
			*replace dem_ld2=0 if green_ENV_PROT_tr==0
			*replace middle_ld2=0 if green_ENV_PROT_tr==0
			
			replace crsp_comp_name=upper(crsp_comp_name)
			replace RegistrantName=upper(RegistrantName)
			replace crsp_comp_name = subinstr(crsp_comp_name, " CORP", "",.)
			replace RegistrantName = subinstr(RegistrantName, " CORP", "",.)
			
			* FIX INHOUSE LOBBYING
			*matchit crsp_comp_name RegistrantName
			*strdist crsp_comp_name RegistrantName 
			*replace strdist=. if missing(RegistrantName)
			*replace  similscore=. if missing(RegistrantName)
			*replace inhouse=1 if similscore>0.8 | strdist<4
			*replace inhouse=. if missing(RegistrantName)
			*drop similscore  strdist	
			*replace rep_ld2=0 if inhouse==1
			*replace dem_ld2=0 if inhouse==1
			*replace middle_ld2=0 if inhouse==1

						
			* mark each LD-2 as Dem or Rep based on Lobbyists' contributions
			gen rep_rep_ld2=1 if sponsor_rep_year>=0.75 & !missing(sponsor_rep_year) & sponsor_rep_year<=1 & brown_contrib>=0.9 & brown_contrib<=1 & !missing(all_lobb_cont_R)
			gen rep_dem_ld2=1 if sponsor_rep_year>=0.75 & !missing(sponsor_rep_year) & sponsor_rep_year<=1 & green_contrib>=0.9 & green_contrib<=1 & !missing(all_lobb_cont_D)
			gen dem_dem_ld2=1 if sponsor_dem_year>=0.75 & !missing(sponsor_dem_year) & sponsor_dem_year<=1 & green_contrib>=0.9 & green_contrib<=1 & !missing(all_lobb_cont_D)
			gen dem_rep_ld2=1 if sponsor_dem_year>=0.75 & !missing(sponsor_dem_year) & sponsor_dem_year<=1 & brown_contrib>=0.9 & brown_contrib<=1 & !missing(all_lobb_cont_R)

			gen rep_rep_amount_gr = Amount_gb_text if rep_rep_ld2==1
			gen rep_dem_amount_gr = Amount_gb_text if rep_dem_ld2==1
			gen dem_dem_amount_gr = Amount_gb_text if dem_dem_ld2==1
			gen dem_rep_amount_gr = Amount_gb_text if dem_rep_ld2==1
				
			* Assuming that a lobbyists can switch parties 

			gen rep_ld2_y=1 if brown_contrib_y>0.5 & brown_contrib_y<=1 & !missing(all_lobb_cont_R_y)
			gen dem_ld2_y=1 if green_contrib_y>0.5 & green_contrib_y<=1 & !missing(all_lobb_cont_D_y)
			gen middle_ld2_y=1 if brown_contrib_y>=0.33 & brown_contrib_y<=0.66 & !missing(all_lobb_cont_R_y)

			*replace rep_ld2_y=0 if inhouse==1 
			*replace dem_ld2_y=0 if inhouse==1
			*replace middle_ld2_y=0 if inhouse==1 


*gen middle_ld2=1 if brown_contrib>=0.33 & brown_contrib<=0.66 & all_lobb_cont_R>0 & !missing(all_lobb_cont_R)

* classify an LD-2 dollar amount as Dem or Rep 
gen rep_amount_gr = Amount_gb_text if rep_ld2==1
gen dem_amount_gr = Amount_gb_text if dem_ld2==1
gen middle_amount_gr = Amount_gb_text if middle_ld2==1
gen rep_amount = Amount if rep_ld2==1
gen dem_amount = Amount if dem_ld2==1
gen middle_amount = Amount if middle_ld2==1
gen EPA_amount=Amount_gb_text if EPA==1

gen rep_amount_gr_y = Amount_gb_text if rep_ld2_y==1
gen dem_amount_gr_y = Amount_gb_text if dem_ld2_y==1
gen middle_amount_gr_y = Amount_gb_text if middle_ld2_y==1
gen rep_amount_y = Amount if rep_ld2_y==1
gen dem_amount_y = Amount if dem_ld2_y==1
gen middle_amount_y = Amount if middle_ld2_y==1


			* Merge with Cosine Similarity Data
			

* aggregate Dem and Rep LD-2s into firm-year
sort gvkey fyear ID
by gvkey fyear: egen t_lob_rep_gr=sum(rep_amount_gr)
by gvkey fyear: egen t_lob_dem_gr=sum(dem_amount_gr)
by gvkey fyear: egen t_lob_mid_gr=sum(middle_amount_gr)
by gvkey fyear: egen t_lob_rep=sum(rep_amount)
by gvkey fyear: egen t_lob_dem=sum(dem_amount)
by gvkey fyear: egen t_lob_mid=sum(middle_amount)

by gvkey fyear: egen t_lob_rep_gr_y=sum(rep_amount_gr_y)
by gvkey fyear: egen t_lob_dem_gr_y=sum(dem_amount_gr_y)
by gvkey fyear: egen t_lob_mid_gr_y=sum(middle_amount_gr_y)
by gvkey fyear: egen t_lob_rep_y=sum(rep_amount_y)
by gvkey fyear: egen t_lob_dem_y=sum(dem_amount_y)
by gvkey fyear: egen t_lob_mid_y=sum(middle_amount_y)

by gvkey fyear: egen t_lob_rep_rep=sum(rep_rep_amount_gr)
by gvkey fyear: egen t_lob_rep_dem=sum(rep_dem_amount_gr)
by gvkey fyear: egen t_lob_dem_dem=sum(dem_dem_amount_gr)
by gvkey fyear: egen t_lob_dem_rep=sum(dem_rep_amount_gr)

by gvkey fyear: egen t_lob_rep_bill=sum(bill_rep_amount)
by gvkey fyear: egen t_lob_dem_bill=sum(bill_dem_amount)
by gvkey fyear: egen t_EPA_gr=sum(EPA_amount)


by gvkey fyear: egen t_lob_rep_mid=sum(rep_mid_amount_gr)
by gvkey fyear: egen t_lob_dem_mid=sum(dem_mid_amount_gr)

by gvkey fyear: egen t_lob_dem_prop=sum(prop_dem_amount)
by gvkey fyear: egen t_lob_rep_prop=sum(prop_rep_amount)

* find % Dem and Rep lobbying for a firm-year
by gvkey fyear: gen t_lob_dem_pct= t_lob_dem_gr/ (t_lob_rep_gr+t_lob_dem_gr)
by gvkey fyear: gen t_lob_dem_pct_all= t_lob_dem_gr / t_lob_gb_text
by gvkey fyear: gen t_lob_rep_pct= t_lob_rep_gr/ (t_lob_rep_gr+t_lob_dem_gr)
by gvkey fyear: gen t_lob_rep_pct_all= t_lob_rep_gr / t_lob_gb_text
by gvkey fyear: gen t_lob_mid_pct_all= t_lob_mid_gr / t_lob_gb_text


*Method 1
by gvkey fyear: egen brown_contrib_year = mean(brown_contrib)
by gvkey fyear: egen green_contrib_year = mean(green_contrib)
by gvkey fyear: egen green_contrib_year_y = mean(green_contrib_y)
*Method 2
replace green_contrib = 0.5 if missing(green_contrib) & all_lobb_cont_D==0
replace green_contrib_y = 0.5 if missing(green_contrib_y) & all_lobb_cont_D_y==0
by gvkey fyear: egen green_contrib_year_2 = mean(green_contrib)
by gvkey fyear: egen green_contrib_year_2_y = mean(green_contrib_y)
*Method 3
by gvkey fyear: egen total_lobb_cont_D = sum(all_lobb_cont_D)
by gvkey fyear: egen total_lobb_cont_R = sum(all_lobb_cont_R)
by gvkey fyear: egen total_lobb_cont_D_y = sum(all_lobb_cont_D_y)
by gvkey fyear: egen total_lobb_cont_R_y = sum(all_lobb_cont_R_y)
gen green_contrib_year_3 = total_lobb_cont_D / (total_lobb_cont_D+total_lobb_cont_R)
gen green_contrib_year_3_y = total_lobb_cont_D_y / (total_lobb_cont_D_y+total_lobb_cont_R_y)


drop rep_amount dem_amount rep_ld2 dem_ld2 brown_contrib green_contrib all_lobb_cont*

winsor2 t_lob_gb, cuts(1 99)
winsor2 t_lob, cuts(1 99)
winsor2 t_lob_gb_text, cuts(1 99)

drop Amount*

//////////////////////////////////////////////////////////////////////////////////////////


duplicates drop gvkey fyear , force


* Report Lobbying amount in mills
replace t_lob_gb=t_lob_gb/1000000
replace t_lob_gb_w=t_lob_gb_w/1000000
replace t_lob_gb_text=t_lob_gb_text/1000000
replace t_lob_gb_text_w=t_lob_gb_text_w/1000000
replace t_lob=t_lob/1000000
replace t_lob_w=t_lob_w/1000000
replace t_lob_gb_maybe=t_lob_gb_maybe/1000000
replace t_lob_gb_text_maybe=t_lob_gb_text_maybe/1000000
replace t_lob_not_gb=t_lob_not_gb/1000000
replace t_lob_not_maybe_gb=t_lob_not_maybe_gb/1000000

* Did a firm lobby at all this year?
gen lobby_=1 if !missing(ID)
replace lobby_=0 if missing(lobby_)

* Did a firm lobby green/brown this year?
gen lobby_gb_=1 if !missing(ID)
replace lobby_gb_=0 if missing(lobby_gb_)
gen lobby_gb_text_=1 if !missing(ID)
replace lobby_gb_text_=0 if missing(lobby_gb_text_)

* Has a firm EVER lobbied?
by gvkey: egen lobby=max(lobby_)
replace lobby=0 if missing(lobby)

* Has a firm EVER lobbied green?
by gvkey: egen lobby_gb=max(lobby_gb_)
replace lobby_gb=0 if missing(lobby_gb)
by gvkey: egen lobby_gb_text=max(lobby_gb_text_)
replace lobby_gb_text=0 if missing(lobby_gb_text)

* Stats: 6.89% out of all firm-year observations
*replace lobby_=0 if missing(lobby_)
*tab lobby_		
* Stats: 8.67% of firms have ever lobbied
*duplicates drop gvkey, force
*tab lobby

* Merge with H&B fluidity measure
cd "R:\ps664\Data\Fluidity"
gen year=fyear
merge m:1 gvkey year using fluidity		
drop if _merge==2
drop _merge
label variable prodmktfluid "Fluidity"
cd "R:\ps664\Patent Applications - Michelle Michela"

cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\SP_500"
* Merge with S&P500
merge 1:1 gvkey fyear using data_sp500
drop if _merge==2
drop _merge
replace sp_500=0 if missing(sp_500)

* Merge with S&P1500
merge 1:1 gvkey fyear using data_sp1500
drop if _merge==2
drop _merge 
replace sp_1500=0 if missing(sp_1500)


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
							
				
*cd "R:\ps664\Patent Applications - Michelle Michela\More Data"
cd "C:\Working Folder"
sa lob_stats_full_yearly_90_2, replace

//////////////////////////////








///// Tables on Lobbying //////
clear all
use lob_stats_full_yearly

* Merge Patent Applications Data
cd "R:\ps664\Patent Applications - Michelle Michela"
merge m:1 gvkey fyear using app_pat_yearly_updated_		
drop if _merge==2	
drop _merge
label variable total_appl "Total Patent Applications"
label variable total_grant "Total Patents Granted"
label variable total_appl_gr "Total Green Patent Applications"
label variable total_grant_gr "Total Green Patents Granted"
cd "R:\ps664\Patent Applications - Michelle Michela\Reports"

replace total_appl=0 if missing(total_appl)
replace total_grant=0 if missing(total_grant)
replace total_appl_gr=0 if missing(total_appl_gr)
replace total_grant_gr=0 if missing(total_grant_gr)

sum total_lob, detail

* Financials Stats
sum total_lob_w at ch mb roa xrd net_sales if lobby==1
sum total_lob_w  at ch mb roa xrd net_sales if lobby==0

sum total_lob_w at ch mb roa xrd net_sales if lobby==1 & high_tech==1
sum total_lob_w  at ch mb roa xrd net_sales if lobby==0 & high_tech==1

* Innovation Stats
sum xrd obs_3year prodmktfluid scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation total_appl_gr total_grant_gr if lobby==1
sum xrd obs_3year prodmktfluid scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation total_appl_gr total_grant_gr if lobby==0

sum xrd obs_3year prodmktfluid scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation total_appl_gr total_grant_gr if lobby==1 & high_tech==1
sum xrd obs_3year prodmktfluid scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation total_appl_gr total_grant_gr if lobby==0 & high_tech==1

hist total_lob_w if total_lob>0


cd "R:\ps664\Patent Applications - Michelle Michela\Reports\Report\Lobbying Data"

* For Sample restricted by non-missing permno & gvkey
outreg2 using table_1.doc if lobby==1, replace sum(detail) eqkeep(N mean p50 sd min max) keep(at age ch mb roa xrd net_sales sale xrd obs_3year prodmktfluid total_appl total_grant total_appl_gr total_grant_gr scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation) label title("Table 1A - Lobbying Firms") sortvar(at age ch mb roa xrd sale net_sales xrd total_appl total_grant total_appl_gr total_grant_gr prodmktfluid obs_3year scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation)

outreg2 using table_2.doc if lobby==0, replace sum(detail) eqkeep(N mean p50 sd min max) keep(at age ch mb roa xrd net_sales sale xrd obs_3year prodmktfluid total_appl total_grant total_appl_gr total_grant_gr scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation) label title("Table 1B - NOT Lobbying Firms") sortvar(at age ch mb roa xrd sale net_sales xrd total_appl total_grant total_appl_gr total_grant_gr prodmktfluid obs_3year scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation)

* lobbying firm-years vs not
outreg2 using table_3.doc if lobby_==1, replace sum(detail) eqkeep(N mean p50 sd min max) keep(at age ch mb roa xrd net_sales sale xrd obs_3year prodmktfluid total_appl total_grant total_appl_gr total_grant_gr scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation) label title("Table 2A - Lobbying Firm-Year") sortvar(at age ch mb roa xrd sale net_sales xrd total_appl total_grant total_appl_gr total_grant_gr prodmktfluid obs_3year scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation)

outreg2 using table_4.doc if lobby_==0, replace sum(detail) eqkeep(N mean p50 sd min max) keep(at age ch mb roa xrd net_sales sale xrd obs_3year prodmktfluid total_appl total_grant total_appl_gr total_grant_gr scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation) label title("Table 2B - NOT Lobbying Firm-Year") sortvar(at age ch mb roa xrd sale net_sales xrd total_appl total_grant total_appl_gr total_grant_gr prodmktfluid obs_3year scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation)


sort gvkey fyear
by gvkey: gen l_lobby_=lobby_[_n-1]

xtset gvkey
xtreg lobby_ l_lobby_ i.fyear, fe vce(robust)

* Regression - what causes firms to start lobbying for the first time
sort gvkey fyear
by gvkey: gen l_ln_mkt_value  = ln_mkt_value[_n-1]
by gvkey: gen l_ln_at  = ln_at[_n-1]
by gvkey: gen l_xrd  = xrd[_n-1]
by gvkey: gen l_net_sales  = net_sales[_n-1]
by gvkey: gen l_ch  = ch[_n-1]
by gvkey: gen l_mb  = mb[_n-1]
by gvkey: gen l_roa  = roa[_n-1]
by gvkey: gen l_fluid  = prodmktfluid[_n-1]
by gvkey: gen l_age  = age[_n-1]
label variable l_fluid "Fluidity"
label variable l_ln_at "ln(Total Assets)"
label variable l_xrd "R&D/Assets"
label variable l_mb "Market to Book"
label variable l_ch "Cash/Assets"
label variable l_net_sales "Net Sales/Assets"
label variable l_roa "ROA"
label variable l_ln_mkt_value "Market Cap"
label variable l_fluid "Fluidity"

by gvkey: gen sum_lobby=sum(lobby_)
gen lobby_first=1 if sum_lobby==1
replace lobby_first=0 if missing(lobby_first)
drop sum_lobby

xtset gvkey
xtreg lobby_first l_age l_ln_mkt_value l_ln_at l_xrd l_net_sales l_ch l_mb l_fluid l_roa   i.fyear, fe vce(robust)



* Lobbying firms decide to or not to lobby this year
replace lobby_=0 if missing(lobby_)
sum total_lob_w at ch mb roa xrd net_sales if lobby_==1 & lobby==1
sum total_lob_w  at ch mb roa xrd net_sales if lobby_==0 & lobby==1

sum xrd obs_3year prodmktfluid obs_3year total_appl_gr total_grant_gr scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation if lobby_==1 & lobby==1
sum xrd obs_3year prodmktfluid obs_3year total_appl_gr total_grant_gr scaled_n_patents mean_scaled_generality mean_scaled_originality mean_scaled_citation if lobby_==0 & lobby==1



* Breakdown - Firm Size
xtile quart_1 = at, nq(10)
xtile quart_22 = sale, nq(10)
xtile quart_2 = mean_scaled_citation, nq(10)
xtile quart_3 = scaled_n_patents, nq(10)
xtile quart_5 = mb, nq(10)
xtile quart_6 = obs_3year, nq(10)
xtile quart_7 = roa, nq(10)
xtile quart_8 = ch, nq(10)
xtile quart_9 = mean_scaled_originality, nq(10)
xtile quart_10 = mean_scaled_generality, nq(10)
xtile quart_4 = xrd, nq(10)
gen xrd_sale = xrd/sale
xtile quart_11 = xrd_sale, nq(10)

xtile quart_12 = total_appl_gr if total_appl_gr>0, nq(10)
xtile quart_13 = total_grant_gr if total_grant_gr>0, nq(10)
xtile quart_14 = total_appl if total_appl>0, nq(10)
xtile quart_15 = total_grant if total_appl>0, nq(10)

* at is not winsorized or slaced => can divide
gen total_lob_assets = total_lob/at
gen total_lob_sale = total_lob/sale

graph bar total_lob, over(quart_1)  ytitle("Firm Lobbying (mill)") title("Firm Lobbying by firm size quantile")
graph bar total_lob, over(quart_22)  ytitle("Firm Lobbying (mill)") title("Firm Lobbying by firm sales quantile")

* Table 1
graph bar total_lob_assets, over(quart_1)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firm size quantile")
graph bar total_lob_assets, over(quart_5)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firm Market to Book quantile")
graph bar total_lob_assets, over(quart_7)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firms' ROA quantile")
graph bar total_lob_assets, over(quart_8)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firms' Cash/Assets quantile")

* Table 2
graph bar total_lob_assets, over(quart_11)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firms' R&D/Sales quantile")
graph bar total_lob_assets, over(quart_4)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firms' R&D/Assets quantile")
graph bar total_lob_assets, over(quart_14)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by N of Patent Applications (N>0) quantile")
graph bar total_lob_assets, over(quart_15)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by N of Patent Grants (N>0) quantile")
graph bar total_lob_assets, over(quart_12)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by N of Green Patent Applications (N>0) quantile")
graph bar total_lob_assets, over(quart_13)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by N of Green Patent Grants (N>0) quantile")

* Table 3
graph bar total_lob_assets, over(quart_2)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firm Patent Citations quantile")
graph bar total_lob_assets, over(quart_3)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firms' Scaled N of Patents quantile")
graph bar total_lob_assets, over(quart_9)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firm Patent Originality quantile")
graph bar total_lob_assets, over(quart_10)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firm Patent Generality quantile")
graph bar total_lob_assets, over(quart_6)  ytitle("Total Firm Lobbying / Total Assets") title("Firm Lobbying by firm Patents' Obsolescence quantile")


//////////////////* Regressions - Lobbying Report *//////////////////


* Merge with HHI data
cd "C:\Users\ps664\OneDrive - Drexel University\2nd Year Paper - Work\Data\hhi data"
merge 1:1 gvkey fyear using hhi_data
keep if _merge==3
drop _merge
rename HHI hhi
sort gvkey fyear
by gvkey: gen l_hhi=hhi[_n-1]
label variable l_hhi "HHI"
cd "R:\ps664\Patent Applications - Michelle Michela\Reports\Report\Lobbying Data"

gen total_appl_non_gr = total_appl - total_appl_gr
gen total_grant_non_gr = total_grant - total_grant_gr

gen ln_any_pat_appl=ln(1+total_appl)
gen ln_pat_gr=log(1+total_appl_gr)
gen ln_pat_non_gr=log(1+total_appl_non_gr)
gen ln_patgrant_gr=log(1+total_grant_gr)
gen ln_patgrant_non_gr=log(1+total_grant_non_gr)

by gvkey: gen l_ln_any_pat_appl = ln_any_pat_appl[_n-1]
by gvkey: gen l_ln_pat_gr = ln_pat_gr[_n-1]
by gvkey: gen l_ln_pat_non_gr = ln_pat_non_gr[_n-1]
by gvkey: gen l_citation = mean_scaled_citation[_n-1]
by gvkey: gen l_general = mean_scaled_generality[_n-1]
by gvkey: gen l_original = mean_scaled_originality[_n-1]
by gvkey: gen l_obsoles = obs_3year[_n-1]

label variable ln_any_pat_appl "ln(1+#total patent apps)"
label variable ln_pat_gr "ln(1+#green patent apps)"
label variable ln_pat_non_gr "ln(1+#non-green patent apps)"
label variable l_ln_any_pat_appl "ln(1+#total patent apps)"
label variable l_ln_pat_gr "ln(1+#green patent apps)"
label variable l_ln_pat_non_gr "ln(1+#non-green patent apps)"
label variable l_age "Age"
label variable l_citation "Scaled Citations (Stoffman)"
label variable l_original "Scaled Originality (Stoffman)"
label variable l_general "Scaled Generality (Stoffman)"
label variable l_obsoles "Obsolescence (Stoffman)"

* scaling issues !!
replace total_lob_assets=total_lob_assets*100000

global l_controls1 "l_age l_ln_mkt_value l_roa l_xrd l_fluid l_ln_any_pat_appl"
global l_controls2 "l_age l_ln_mkt_value l_roa l_xrd l_fluid l_ln_pat_gr l_ln_pat_non_gr"
global l_controls3 "l_age l_ln_mkt_value l_roa l_xrd l_fluid l_ln_pat_gr l_ln_pat_non_gr l_citation l_general l_original l_obsoles"

winsor2 total_lob_assets , cuts(1 99)

unique(gvkey)

* Table 1
xtset fyear
xtreg total_lob_assets $l_controls1   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, replace ctitle(Lobbying) keep($l_controls1) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  pdec(3) dec(3)
xtset ffi
xtreg total_lob_assets $l_controls1   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls1) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni  
xtset iyfe
xtreg total_lob_assets $l_controls1   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls1) addtext(Year FE, YES, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  
xtset gvkey
xtreg total_lob_assets $l_controls1   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls1) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  


* Table 2
xtset fyear
xtreg total_lob_assets $l_controls2   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, replace ctitle(Lobbying) keep($l_controls2) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  pdec(3) dec(3)
xtset ffi
xtreg total_lob_assets $l_controls2   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls2) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni
xtset iyfe
xtreg total_lob_assets $l_controls2   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls2) addtext(Year FE, YES, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  
xtset gvkey
xtreg total_lob_assets $l_controls2   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls2) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  


* Table 3
xtset fyear
xtreg total_lob_assets $l_controls3   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, replace ctitle(Lobbying) keep($l_controls3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, NO) label noni  pdec(3) dec(3)
xtset ffi
xtreg total_lob_assets $l_controls3   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls3) addtext(Year FE, YES, Industry FE, YES, Industry x Year, NO, Firm FE, NO) label noni
xtset iyfe
xtreg total_lob_assets $l_controls3   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, YES, Firm FE, NO) label noni  
xtset gvkey
xtreg total_lob_assets $l_controls3   i.fyear, fe vce(robust)
outreg2 using reg_L1.doc, append ctitle(Lobbying) keep($l_controls3) addtext(Year FE, YES, Industry FE, NO, Industry x Year, NO, Firm FE, YES) label noni  


