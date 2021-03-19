# -*- coding: utf-8 -*-
"""
Created on Wed Dec  4 14:13:34 2019

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
from random import randint
from time import sleep
import numpy as np
from googlesearch import search 
import datetime
import io
from xml.etree import ElementTree as et
import os, os.path, sys
import glob
from xml.etree import ElementTree
import  csv
import xml.etree.cElementTree as ET
import time
from datetime import date



os.chdir("R:\\ps664\\Data\\Lobbying Data\\Full Data")


folder= "R:\ps664\Data\Lobbying Data\\Trial 4"
xml_files = glob.glob(folder + "/*.xml")
file_n=0
# I skipped one category from the lobbying filings - foreign entitity - it's rarely present and not related to the research question


df=pd.DataFrame(columns=[''])
frame0=pd.DataFrame(columns=[''])
frame1=pd.DataFrame(columns=[''])
frame2=pd.DataFrame(columns=[''])
frame3=pd.DataFrame(columns=[''])
frame4=pd.DataFrame(columns=[''])
frame5=pd.DataFrame(columns=[''])
frame6=pd.DataFrame(columns=[''])


# loop over every xml file in the folder
for xml_file in xml_files:    
    file_n=file_n+1
    print(file_n)
    print(xml_file)
    f_date = xml_file.split('_')
    f_year = int(f_date[0].split('\\')[5])
    f_quarter = int(xml_file.split('_')[1])
    f_month = int(xml_file.split('_')[2])
    f_day = int(f_date[3].split('.')[0])
    file_date = date(f_year, f_month, f_day)
    
    file_number=re.findall(r'\\([0-9]{4}.*).xml', xml_file)

    #mark which file was looped the last
    last_file_date=date(1999, 8, 2)
    if last_file_date>=file_date:
        continue
        
    
    
    xtree = et.parse(xml_file)
    xroot = xtree.getroot()
    rows = []
    
    dfcols = ['RegistrantID', 'email', 'phone', 'street']
    df_xml = pd.DataFrame(columns=dfcols)
    
    a=0
    obs=0
    
    
    #loop over every filing in an xml file
    for node in xroot: 
        #print(obs)
        
        #print(node.tag, node.attrib)
        #attr = node.attrib
        registr=[]
        client=[]
        lobby=[]
        aff_org=[]
        gov_ent=[]
    
        obs=obs+1
        name = node.attrib.get('name')
        
        filing_info=node.attrib
        if "TerminationEffectiveDate" in filing_info.keys(): 
            del(filing_info["TerminationEffectiveDate"])  
        if "RegistrationEffectiveDate" in filing_info.keys(): 
            del(filing_info["RegistrationEffectiveDate"])              
        frame0=filing_info
            
        #loop over every subsection of a filing
        for child in node:
            a=a+1
            tag_ = child.tag
           
            if "Registrant" in tag_:
                registr=child.attrib
                frame1=pd.DataFrame(registr, index=[1])  
                if "Address" in registr.keys(): 
                    r=0
                else:
                    registr['Address']=""
                    frame1=pd.DataFrame(registr, index=[1])
            
                frame1=frame1[['RegistrantID','RegistrantName','GeneralDescription','Address','RegistrantCountry','RegistrantPPBCountry','Address']]
                
            if "Client" in tag_:
                client=child.attrib
                frame2=pd.DataFrame(client, index=[1]) 
                i=0
                for elmnt in child:
                    i=i+1
                    client = elmnt.attrib
                    n=pd.DataFrame(client, index=[1])
                    if i==1:
                        frame2=n   
                    if i>1:    
                        frame2 = pd.concat([frame2, n], axis=0, sort=False)                   
                
            if "Lobbyists" in tag_:
                i=0
                for elmnt in child:
                    i=i+1
                    lobby = elmnt.attrib
                    if "ActivityInformation" in lobby.keys(): 
                        del(lobby["ActivityInformation"])
                    
                    k=pd.DataFrame(lobby, index=[1])
                    if i==1:
                        frame3=k   
                    if i>1:    
                        frame3 = pd.concat([frame3, k], axis=0, sort=False)
                        
                                        
            if "Issues" in tag_:
                i=0
                for elmnt in child:
                    i=i+1
                    issues = elmnt.attrib
                    m=pd.DataFrame(issues, index=[1])
                    if i==1:
                        frame4=m   
                    if i>1:    
                        frame4 = pd.concat([frame4, m], axis=0, sort=False)                   
                        p=frame4           
                                   
            if "AffiliatedOrgs" in tag_:
                i=0
                for elmnt in child:
                    i=i+1
                    aff_org = elmnt.attrib
                    f=pd.DataFrame(aff_org, index=[1])
                    if i==1:
                        frame5=f   
                    if i>1:    
                        frame5 = pd.concat([frame5, f], axis=0, sort=False)
                        p=frame5
              
            if "GovernmentEntities" in tag_:
                i=0
                for elmnt in child:
                    i=i+1
                    gov_ent = elmnt.attrib
                    j=pd.DataFrame(gov_ent, index=[1])
                    if i==1:
                        frame6=j   
                    if i>1:    
                        frame6 = pd.concat([frame6, j], axis=0, sort=False)
                                    
            if frame6.empty==True:
                gov_ent = { 'GovEntityName': ""} 
                frame6=pd.DataFrame(gov_ent, index=[1]) 
            if frame5.empty==True:
                aff_org = { 'AffiliatedOrgName': "", 'AffiliatedOrgCountry': "", 'AffiliatedOrgPPBCcountry': ""} 
                frame5=pd.DataFrame(aff_org, index=[1]) 
            if frame4.empty==True:
                issues = { 'Code': "", 'SpecificIssue': ""}            
                frame4=pd.DataFrame(issues, index=[1]) 
            if frame3.empty==True:
                lobby = {'LobbyistName' :"" , 'LobbyistCoveredGovPositionIndicator': "", 'OfficialPosition': ""}             
                frame3=pd.DataFrame(lobby, index=[1])
            if frame2.empty==True:
                client = {'GeneralDescription' :"" , 'ClientPPBState': "", 'ClientState': "", 'ClientPPBCountry': "", 'ClientCountry': "", 'IsStateOrLocalGov': ""}             
                frame2=pd.DataFrame(client, index=[1])
     
            frame0.drop_duplicates(inplace=True)
            frame1.drop_duplicates(inplace=True)
            frame2.drop_duplicates(inplace=True)
            frame3.drop_duplicates(inplace=True)
            frame4.drop_duplicates(inplace=True)
            frame5.drop_duplicates(inplace=True)
            frame6.drop_duplicates(inplace=True)         
            
            frame0.reset_index(drop=True, inplace=True)
            frame1.reset_index(drop=True, inplace=True)
            frame2.reset_index(drop=True, inplace=True)
            frame3.reset_index(drop=True, inplace=True)
            frame4.reset_index(drop=True, inplace=True)
            frame5.reset_index(drop=True, inplace=True)
            frame6.reset_index(drop=True, inplace=True)
    
            result = pd.concat([frame0, frame1, frame2, frame3, frame4, frame5, frame6], axis=1, join='outer', sort=False)        
            result = result.ffill()
            result.drop_duplicates(inplace=True)
                  
        frame0.drop(frame0.index, inplace=True)  
        frame1.drop(frame1.index, inplace=True)
        frame2.drop(frame2.index, inplace=True)
        frame3.drop(frame3.index, inplace=True)
        frame4.drop(frame4.index, inplace=True)
        frame5.drop(frame5.index, inplace=True)
        frame6.drop(frame6.index, inplace=True)
        
        result["file_number"] = file_number[0] 
        result["date_filed"] = file_date 
        
        if obs==1:
            df = result
        if obs>1:
            df = pd.concat([df, result], axis=0, sort=False) 
            
        df = df.replace(r'\\n',' ', regex=True) 
        df = df.replace(r'\n',' ', regex=True) 
        df = df.replace("\r",' ', regex=True) 
        df = df.replace("\n",' ', regex=True) 
            
    #record the full data from an xml file to a csv
    if file_n==1:
        df.to_csv(r'R:\ps664\Data\Lobbying Data\lobbying_data.csv')
    # Appending the excel file
    if file_n>1:
        with open('R:\ps664\Data\Lobbying Data\lobbying_data.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
            df.to_csv(f, header=False)
              
        
       
# Read CSV
            
data = pd.read_csv(r'R:\ps664\Data\Lobbying Data\lobbying_data.csv', error_bad_lines=False)            


























