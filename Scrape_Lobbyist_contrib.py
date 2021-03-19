# -*- coding: utf-8 -*-
"""
Created on Tue Jul 14 11:26:23 2020

@author: ps664
"""

import openpyxl
import re
import csv
import urllib
import os
from openpyxl import Workbook
from bs4 import BeautifulSoup
import pandas as pd
import string
import re
import requests
import random
from random import randint
import time
from time import sleep
import numpy as np
import xlrd
from googlesearch import search 


# Test a random package
#import gender_guesser.detector as gender
#d = gender.Detector()
#print(d.get_gender(u"Bob"))



os.chdir("C:\\My Work\\Data - Lobbying Opensecrets")
file = xlrd.open_workbook(r'C:\\My Work\\Data - Lobbying Opensecrets\\not_found_lobbyists.xlsx')
sheet = file.sheet_by_index(0)
a = sheet.cell_value(0, 0) 
print(a)

df_record = pd.DataFrame({'obs_number': 1, 'Total_to_R': None, 'Total_to_D' : None, 'Link' : None}, index =[0]) 
df_record_details = pd.DataFrame({'Recipient': 1, 'Affiliate': None, 'From Lobbyist' : None, 'From Family Members' : None, 'From Lobbyist + Family Members': None, 'To_Republicans': None, 'To_Democrats': None, 'Total_to_R': None, 'Total_to_D': None}, index =[0]) 

n_found=0

# DO NOT RUN THIS
# Create files where everything gets recorded
lobbyist_record = pd.DataFrame({'obs_number': 0, 'Total_to_R': 0, 'Total_to_D' : 0, 'Link' : "", 'LobbyistName': "", 'year' : ""}, index =[0])   
lobbyist_record.to_csv(r'C:\My Work\Data - Lobbying Opensecrets\party_contrib_1b.csv')
lobbyist_record.to_csv(r'C:\My Work\Data - Lobbying Opensecrets\party_contrib_2b.csv')


# RENEW HERE   

for i in range(2,8608): 
    #'Try' is a failsafe  #24140
    try:
        # this is the lobbyist's name that I'll use to merge back to Lobbying Transactions (SAS)
        # for Cathy Abernahty - sheet.cell_value(14, 0)
        
        ####### TEST ######
        i=2
        
        name_lobbyist = sheet.cell_value(i, 0)
        
        # fix the name of a lobbyist (switch last and first name)
        split=name_lobbyist.find(",")
        name_last=name_lobbyist[:split]
        name_first=name_lobbyist[split+2:]
        name_full= name_first + " " + name_last
        
        # Google the name of a lobbyist to get link to OpenSecrets
        print(name_full)
        # Sleep to request data from Google (total of 14,760)
        sleep_time = 1 + 1/ randint(1,10)
        time.sleep(sleep_time)
            
        google_find = list(search(name_full+" lobbyist", tld = 'com', num = 5, stop = 5, pause = 1.25))
        opensecret_link=""
        for link in google_find:
            if "opensecrets.org" in link:       
                if "lobbyists" in link:
                    if "industries" not in link:
                        opensecret_link = link                  
        
        # double-check that you have the right link
        if "www.opensecrets.org/federal-lobbying/lobbyists/" not in link:
            opensecret_link=""
        
        # try adjusting the Google search
        if opensecret_link=="":
            name_first = re.sub(' [A-Z][a-z]*','', name_first)
            name_first = re.sub(r'\([A-Z]*\)','', name_first)
            name_first = re.sub(r' [A-Z]','', name_first)
            name_first = re.sub(r' JR','', name_first)
            name_first = re.sub(r' III','', name_first)
            
            name_last = re.sub(r'\([A-Z]*\)','', name_last)            
            
            name_full = name_first + " " + name_last
            print(name_full)

            sleep_time = 1 + 1/ randint(1,10)
            time.sleep(sleep_time)
            # Try to adjust the Google search
            google_find = list(search(name_full+" site:https://www.opensecrets.org/federal-lobbying/", tld = 'com', num = 5, stop = 5, pause = 1.25))
            for link in google_find:
                if "www.opensecrets.org/federal-lobbying/lobbyists/" in link: 
                    opensecret_link = link                
            # If adjusting doesn't work, try navigating through transactions on OpenSecrets website
            if opensecret_link=="":
                for link in google_find:
                    
                    sleep_time = 1 + 1/ randint(1,10)
                    time.sleep(sleep_time)
                    
                    html = requests.get(link).content   
                    soup = BeautifulSoup(html, 'html.parser')
                    tags = soup.find_all(href=re.compile("federal-lobbying/lobbyists/"))    

                    for tag in tags:
                        find_lastname = re.search(name_last, str(tag), flags=re.IGNORECASE)
                        if find_lastname is not None:
                            link_looked_up = 'https://www.opensecrets.org' + str(tag.get('href', None))
                            print(link_looked_up)
                            opensecret_link = link_looked_up
                            continue
        
        
        if opensecret_link=="":
            print('Google does not have the person above')
            continue
        
        # Access Opensecrets website
        #print(opensecret_link)
        url = opensecret_link
        html = requests.get(url).content
        soup = BeautifulSoup(html,'lxml')
        
        # Get the web-page title
        page_titles = soup.select('title')
        page_title = str(page_titles[0].text).strip()
        #print(page_title)
        
        # Chieck if the page title refers to the lobbyists we're looking for
        if name_last.upper() in page_title.upper():
            found_lastn=1
        if name_first.upper() in page_title.upper():
            found_firstn=1

        contib_link= opensecret_link.replace("summary",'contributions') 
        years_list=["2000", "2001", "2002", "2003", "2004", "2005", "2006", "2007", "2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019"]
        
        if 'cycle=' in contib_link:
            year_start = contib_link.find('cycle=') + 6
            stable_link = contib_link[:year_start]
        else:    
            year_start = contib_link.find('contributions?') + 14
            stable_link = contib_link[:year_start] + "cycle="
            #print(stable_link)
            year_start = contib_link.find('contributions?') + 9
        
        #print(contib_link[:year_start])
        
        #year = "2018"
        found_data=0
        new_lobbyist_record=0
        
        for year in years_list:
                        
            link_this_year=stable_link+year+"&"+contib_link[year_start+5:]            
            
            #link_this_year = 'https://www.opensecrets.org/federal-lobbying/lobbyists/contributions?cycle=2012&id=Y0000021793L'
            #year=2012
                        
            #r = requests.get(link_this_year, allow_redirects=True)
            html = requests.get(link_this_year).content
            
            # Sleep when afor each year from Opensecrets (opening 18 links for each lobbyist)
            sleep_time = 2 + 1/randint(1,10)
            time.sleep(sleep_time)
            
            soup = BeautifulSoup(html,'lxml')
            #print(soup)
            
            # Check what year the link is actually for               
            y = soup.select_one('h2:contains("Political Contributions")')
            years_website=re.findall(r'20[0-9][0-9]',str(y))
            
            
            no_contributions=re.findall(r'No contributions made.*</b>',str(soup))
            year_no_contrib = re.findall(r'[0-9][0-9][0-9][0-9]', str(no_contributions))
            
            if str(year) in year_no_contrib:
                
                found_data=1
                n_found = n_found+1                
                new_lobbyist_record=new_lobbyist_record+1
                
                lobbyist_record = pd.DataFrame({'obs_number': i, 'Total_to_R': 0, 'Total_to_D' : 0, 'Link' : link_this_year, 'LobbyistName': name_lobbyist, 'year' : year}, index =[0])   
                
                if new_lobbyist_record==1:
                    df_record=lobbyist_record
                    #print("Recorded no contrib in", year, "for", name_lobbyist)
                    
                if new_lobbyist_record>1:
                    df_record=df_record.append(lobbyist_record, ignore_index=True)  
                    
                print("Recorded no contrib in", year, "for", name_lobbyist)
                with open('C:\My Work\Data - Lobbying Opensecrets\party_contrib_1b.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
                    lobbyist_record.to_csv(f, header=False)
                    
                
            
            # Scrape only those years where a lobbyist has data on contributions
            if year in years_website:
                                
                new_lobbyist_record=new_lobbyist_record+1
                found_data=1
                n_found = n_found+1
                                               
                #print(year, "correct link", name_full)
                                
                # try to extract a table => if there is not table (but the year link is there), then it is a lobbyist with no contribution
                try:
                    
                    # INSERT THE CODE FOR SRAPING TABLE HERE
                    all_tables = soup.select('table:contains("Lobbyist")')
    
                    first_table=pd.read_html(str(all_tables[0]))
                    comp_dataframe=first_table[0].fillna("0")
                    
    
                    df= comp_dataframe.replace({"[,$]":''}, regex=True)  
                    #df['Affiliate']= df['Affiliate'].to_string
                    
                    # Try to find calssify contributions into Republican and Democratic
                    # (some contributions are not attributable to either)
                        
                    #print(link_this_year)
                    # Mark Democrats and Republicans
                    df['To_Republicans']=  np.where( (df['Recipient'].str.contains("R-", regex=False)) | (df['Affiliate'].str.contains("R-", regex=False)) | (df['Recipient'].str.contains("Republican", regex=False)) | (df['Recipient'].str.contains("(R)", regex=False)) , 1, 0)                               
                    df['To_Democrats']=  np.where( (df['Recipient'].str.contains("D-", regex=False)) | (df['Affiliate'].str.contains("D-", regex=False))  | (df['Recipient'].str.contains("Democrat", regex=False)) | (df['Recipient'].str.contains("(D)", regex=False)), 1, 0)
                    
                    df['From Lobbyist'] = pd.to_numeric(df['From Lobbyist'],errors='coerce')
                    df['From Family Members'] = pd.to_numeric(df['From Family Members'],errors='coerce')
                    
                    # Count Total Contributions to Democrats & Republicans
                    df['Total_to_R'] = np.sum(df['From Lobbyist'] * df['To_Republicans'])
                    df['Total_to_D'] = np.sum(df['From Lobbyist'] * df['To_Democrats'])
                    
                    # This is Dataframe for One Lobbyist with all years
                    lobbyist_record = pd.DataFrame({'obs_number': i, 'Total_to_R': df['Total_to_R'], 'Total_to_D' : df['Total_to_D'], 'Link' : link_this_year, 'LobbyistName': name_lobbyist, 'year' : year}, index =[0])   
                    
                    # This dataframe creates the record for this One lobbyist
                    # If it's the first year record for this lobbyist, empty the record from previous lobbyist
                    if new_lobbyist_record==1:
                        df_record=lobbyist_record

                    # This dataframe appends all years for One Lobbyist
                    # (if this is not the first year for this lobbyists, then append the recors)
                    if new_lobbyist_record>1:
                        df_record=df_record.append(lobbyist_record, ignore_index=True)
                        
                    print("Recorded DOLLAR contrib in", year, "for", name_lobbyist)
                    with open('C:\My Work\Data - Lobbying Opensecrets\party_contrib_1b.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
                        lobbyist_record.to_csv(f, header=False)
                    
                    # This dataframe records all lobbyists data
                    df_record_details = df_record_details.append(df, ignore_index=True)
                                        
                except Exception as k:
                    print("No Record - no Dem or Rupbl contributions / bad link")
                    print(k)
                    errors_ = pd.DataFrame({'obs_number': i, 'Link' : link_this_year, 'error': k, 'error where':'Table issue / no contribution data'}, index =[0])
                    with open('C:\My Work\Data - Lobbying Opensecrets\errors.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
                        errors_.to_csv(f, header=False)
                    
                    
                      
    except Exception as e:
        print("Access issue / link issue", name_lobbyist)
        print(e)
        errors_ = pd.DataFrame({'obs_number': i, 'Link' : link_this_year, 'error': e, 'error where':'OpenSecrets link access / link created'}, index =[0])
        with open('C:\My Work\Data - Lobbying Opensecrets\errors.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
            errors_.to_csv(f, header=False)
    
       
    # Appending the excel file 
    if (n_found>1) & (found_data==1):
        print("Recorded full lobbyist dataframe for", name_lobbyist)
        print("Finished row #", i)
        with open('C:\My Work\Data - Lobbying Opensecrets\party_contrib_2b.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
            df_record.to_csv(f, header=False)
        #Reset
        found_data=0
                
           
        
#%%
              
    if (n_found==1) & (found_data==1):
        print("Recorded data for", name_lobbyist)
        df_record.to_csv(r'R:\ps664\Data\Lobbying_OpenSecrets\party_contrib_2.csv')
        #Reset
        found_data=0
        
        
# Initiate the appending Dataframe of all Lobbyists
df_record = pd.DataFrame({'obs_number': 1, 'Total_to_R': None, 'Total_to_D' : None}, index =[0])    


url = 'https://www.opensecrets.org/federal-lobbying/lobbyists/contributions?cycle=2016&id=Y0000044910L'


url = 'http://www.opensecrets.org/federal-lobbying/lobbyists/contributions?cycle=2008&id=Y0000020537L'


r = requests.get(url, allow_redirects=True)
html = requests.get(url).content
soup = BeautifulSoup(html,'lxml')
    
all_tables = soup.select('table:contains("Lobbyist")')

first_table=pd.read_html(str(all_tables[0]))
comp_dataframe=first_table[0]

df= comp_dataframe.replace({"[,$]":''}, regex=True)  

# Mark Democrats and Republicans
df['To_Republicans']=  np.where( (df['Recipient'].str.contains("R-")) | (df['Affiliate'].str.contains("R-")) | (df['Recipient'].str.contains("Republican")) | (df['Recipient'].str.contains("(R)")) , 1, 0)                               
df['To_Democrats']=  np.where( (df['Recipient'].str.contains("D-")) | (df['Affiliate'].str.contains("D-"))  | (df['Recipient'].str.contains("Democrat")) | (df['Recipient'].str.contains("(D)")), 1, 0)

df['From Lobbyist'] = pd.to_numeric(df['From Lobbyist'],errors='coerce')
df['From Family Members'] = pd.to_numeric(df['From Family Members'],errors='coerce')

# Count Total Contributions to Democrats & Republicans
df['Total_to_R'] = np.sum(df['From Lobbyist'] * df['To_Republicans'])
df['Total_to_D'] = np.sum(df['From Lobbyist'] * df['To_Democrats'])

# This is Dataframe for One Lobbyist
lobbyist_record = pd.DataFrame({'obs_number': 1, 'Total_to_R': df['Total_to_R'], 'Total_to_D' : df['Total_to_D']}, index =[0])    

# Append to All Lobbyists' Data
df_record=df_record.append(lobbyist_record, ignore_index=True)





#%%

for table in table1:   
    comp_dataframe=pd.read_html(str(table))
    contrib_table=comp_dataframe[0]
    contrib_table= contrib_table.replace({"\,\$":''}, regex=True)   
    contrib_table= contrib_table.replace({"\,":''}, regex=True)

    contrib_table= contrib_table.replace({"\$":''}, regex=True)



contrib_ta= contrib_table.replace({"[,]":''}, regex=True)  
contrib_table= contrib_table.replace({"\([0-9]\)":''}, regex=True)   



        table_start = contrib_table.iloc[:,0].str.contains(r'[Ll]obbyist', regex=True)

    
frame_full = pd.DataFrame({'file number': row[0], 'gvkey': row[1],  'year_file': row[2], 'year':  row[2],
         'firm name' : row[3], 'director name' : dir_names, 'salary': salary, 'bonus': bonus, 'stock': stock,
         'options': options, 'non equity' :  nonequity, 'pension' : pension, 'other comp' : other_comp,
         'total' :  total_comp, 'table found' : 0 , 'link' : row[6] }, index =[0])        
app_frame_full=app_frame_full.append(frame_full, ignore_index=True)

