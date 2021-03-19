# -*- coding: utf-8 -*-
"""
Created on Wed Oct 14 11:20:46 2020

@author: ps664
"""

import openpyxl
import re
import csv
#import unicodecsv as csv
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
import urllib
import tables
from tables import *
from lxml import html
from numpy import nan
import openpyxl
import re
import csv
import urllib
import os
from openpyxl import Workbook
from bs4 import BeautifulSoup

from flashtext import KeywordProcessor 
import spacy
from collections import Counter
from string import punctuation
import en_core_web_lg
nlp = en_core_web_lg.load()


def get_hotwords(text):
    result = []
    pos_tag = ['PROPN', 'ADJ', 'NOUN'] # 1
    doc = nlp(text.lower()) # 2
    for token in doc:
        # 3
        if(token.text in nlp.Defaults.stop_words or token.text in punctuation):
            continue
        # 4
        if(token.pos_ in pos_tag):
            result.append(token.text)                
    return result # 5

list_=[]
Dict = {} 
Dict_new={}


# CATEGORY 1: ENVIRONMENTAL PROTECTION
library="R:\\ps664\\Data\\Lobbying Data"
os.chdir(library)
file = open('lobbying_data.csv', encoding="raw_unicode_escape")
csv_f = csv.reader(file, delimiter=',')

i=1
for row in csv_f:
    i=i+1
    print(i)
    if i<4174015:
        continue
    try:
        text=row[28]
        code=row[27]    
        output=get_hotwords(text.lower())    
        
        if code in Dict:
            update = Dict[code] + output
            Dict[code]= update
            
        if code not in Dict:
            Dict[code]= output
            
        #print('Keywords:', output)
        list_ = list_+output
    except:
        continue
    
    
# Save a dictionary
# save as a pickle

# save as a csv file
import csv
w = csv.writer(open("R:\ps664\Data\Lobbying Data\dictonary_lob_issue_4174015.csv", "w"))
for key, val in Dict.items():
    w.writerow([key, val])
import pickle
f = open("R:\ps664\Data\Lobbying Data\dictonary_lob_issue_4174015.pkl","wb")
pickle.dump(Dict,f)
f.close()

# save as a txt file
f = open("R:\ps664\Data\Lobbying Data\dictonary_lob_issue_4174015.txt","w")
f.write( str(Dict) )
f.close()




# Save as a dataframe
for key in Dict:
     #Dict[key] = [Dict[key],val]
     str1 = ' '.join(str(e) for e in Dict[key])
     Dict_new[key]= str1

frame_full=pd.DataFrame(Dict_new, index=[0])  

# there are 4779580 rows total
frame_full.to_csv(r'R:\ps664\Data\Lobbying Data\lobbying_issues_dict_3152106.csv')


frame_full.to_csv(r'R:\ps664\Data\Lobbying Data\lobbying_issues_dict_2461779.csv')
frame_full.to_csv(r'R:\ps664\Data\Lobbying Data\lobbying_issues_dict_2040926.csv')
frame_full.to_csv(r'R:\ps664\Data\Lobbying Data\lobbying_issues_dict_1710628.csv')
frame_full.to_csv(r'R:\ps664\Data\Lobbying Data\lobbying_issues_dict_1400494.csv')







# Import back the data
# the computer crashed at obs 2481406, second chunk starts after that
path1="R:\ps664\Data\Lobbying Data\dictonary_lob_issue_2481406.csv"
path2="R:\ps664\Data\Lobbying Data\dictonary_lob_issue_3152106.csv"
df = pd.read_csv(path1, encoding='raw_unicode_escape')

# Get Keyword positions in exported data
x=0
while x<80:
    if df.iloc[x,0]=='WASTE (HAZARDOUS/SOLID/INTERSTATE/NUCLEAR)':
        waste_x =x 
    if df.iloc[x,0]=='ENERGY/NUCLEAR':
        energy_x =x 
    if df.iloc[x,0]=='ENVIRONMENT/SUPERFUND':
        env_x =x 
    if df.iloc[x,0]=='FUEL/GAS/OIL':
        fuel_x =x 
    if df.iloc[x,0]=='CLEAN AIR AND WATER (QUALITY)':
        air_x =x 
    if df.iloc[x,0]=='AEROSPACE':
        space_x =x 
    if df.iloc[x,0]=='AGRICULTURE':
        agr_x =x 
    if df.iloc[x,0]=='ANIMALS':
        animals_x =x 
    if df.iloc[x,0]=='AVIATION/AIRLINES/AIRPORTS':
        avia_x =x 
    if df.iloc[x,0]=='CHEMICALS/CHEMICAL INDUSTRY':
        chem_x =x 
    x=x+1    
        

for key in Dict:
     #Dict[key] = [Dict[key],val]
     str1 = ' '.join(str(e) for e in Dict[key])
     Dict_new[key]= str1
     
# Text Attributes
#df_ = df.replace({'[^A-Za-z0-9]':''}, regex=True)

# Green/Brown Issues
waste = df.iloc[waste_x,1] + Dict_new['WASTE (HAZARDOUS/SOLID/INTERSTATE/NUCLEAR)']
energy = df.iloc[energy_x,1] + Dict_new['ENERGY/NUCLEAR']
env = df.iloc[env_x,1] + Dict_new['ENVIRONMENT/SUPERFUND']
fuel = df.iloc[fuel_x,1] + Dict_new['FUEL/GAS/OIL']
air = df.iloc[air_x,1] + Dict_new['CLEAN AIR AND WATER (QUALITY)']

# Potentially Green/Brown
space = df.iloc[space_x,1] + Dict_new['AEROSPACE']
agr = df.iloc[agr_x,1] + Dict_new['AEROSPACE']
animals = df.iloc[animals_x,1] + Dict_new['AEROSPACE']
avia = df.iloc[avia_x,1] + Dict_new['AEROSPACE']
chem = df.iloc[chem_x,1] + Dict_new['AEROSPACE']
space = df.iloc[space_x,1] + Dict_new['AEROSPACE']
space = df.iloc[space_x,1] + Dict_new['AEROSPACE']




# Add all collected databrames together


from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt


# Green/Brown Issues
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(waste)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\waste.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(energy)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\energy.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(env)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\env.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(fuel)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\fuel.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(air)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\air.png")



# Potentially Green/Broan issues
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(space)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\space.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(agr)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\agr.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(animals)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\animals.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(avia)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("C:\My Work\CleanTech\Wordclouds\\avia.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(chem)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\lobbying_issue_clouds\\chem.png")


# how to do tf-idf:
# https://sites.temple.edu/tudsc/2017/03/30/measuring-similarity-between-texts-in-python/
# https://towardsdatascience.com/natural-language-processing-feature-engineering-using-tf-idf-e8b9d00e7e76


# easy td-idf computation example
# https://www.analyticsvidhya.com/blog/2020/02/quick-introduction-bag-of-words-bow-tf-idf/


# start with a simple case
all_transactions = ['first lobbying on security', 'lobbying on climate management', 'lobbying on green', 'green life matters', 'oil is the old energy source']
green_transactions = ['green', 'oil', 'climate']

# calculate td for each transaction first
td_1=[]
for element in all_transactions:
    frequency = []
    for word in element:
        proportion_i # = (n of time a word is ised) / total number of words
        frequency = frequency + str(proportion_i)
    td_1 = td_1 + frequency

#calculate td for green transactions (all mapped into one document like in Engle et al)
td_2=[]
for word in green_transactions:
    proportion_i # = (n of time a word is ised) / total number of words
    frequency = frequency + str(proportion_i)
td_2 = td_2 + frequency    

# calculate idf for all transaction words



# find the td-idf for each transaction and green transactions
# (create a 0/x matrix with rows for each transaction and columns for each possible words)








