# -*- coding: utf-8 -*-
"""
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


# Import back the data
# the computer crashed at obs 2481406, second chunk starts after that
path1="R:\ps664\Data\Lobbying Data\dictonary_lob_issue_2481406.csv"
path2="R:\ps664\Data\Lobbying Data\dictonary_lob_issue_4174015.csv"

df1 = pd.read_csv(path1, encoding='raw_unicode_escape')
df2 = pd.read_csv(path2, encoding='raw_unicode_escape')

# Get Keyword positions in exported data
x=0
while x<80:
    if df1.iloc[x,0]=='ENERGY/NUCLEAR':
        energy_x1 =x 
    if df1.iloc[x,0]=='ENVIRONMENT/SUPERFUND':
        env_x1 =x 
    if df1.iloc[x,0]=='FUEL/GAS/OIL':
        fuel_x1 =x 
    if df1.iloc[x,0]=='CLEAN AIR AND WATER (QUALITY)':
        air_x1 =x 
    if df1.iloc[x,0]=='WASTE (HAZARDOUS/SOLID/INTERSTATE/NUCLEAR)':
        waste_x1 =x         
    x=x+1    
        
# Get Keyword positions in exported data
x=0
while x<79:
    if df2.iloc[x,0]=='ENERGY/NUCLEAR':
        energy_x2 =x 
    if df2.iloc[x,0]=='ENVIRONMENT/SUPERFUND':
        env_x2 =x 
    if df2.iloc[x,0]=='FUEL/GAS/OIL':
        fuel_x2 =x 
    if df2.iloc[x,0]=='CLEAN AIR AND WATER (QUALITY)':
        air_x2 =x 
    if df2.iloc[x,0]=='WASTE (HAZARDOUS/SOLID/INTERSTATE/NUCLEAR)':
        waste_x2 =x 
    x=x+1  
    
# Text Attributes
#df_ = df.replace({'[^A-Za-z0-9]':''}, regex=True)

# Green/Brown Issues
energy = df1.iloc[energy_x1,1] + df1.iloc[energy_x2,1]
env = df1.iloc[env_x1,1] + df1.iloc[env_x2,1]
fuel = df1.iloc[fuel_x1,1] + df1.iloc[fuel_x2,1] 
air = df1.iloc[air_x1,1] + df1.iloc[air_x2,1] 
waste = df1.iloc[waste_x1,1] + df1.iloc[waste_x2,1]

issues_green = energy+env+fuel+air+waste
issues_green= issues_green.replace("'","")


from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt


# Green/Brown Issues Combined
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(issues_green)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\\issues_green_brown.png")

# Add all collected databrames together


from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt


# Green/Brown Issues One by One
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(waste)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Lobbying_issue\\waste.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(energy)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Lobbying_issue\\energy.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(env)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Lobbying_issue\\env.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(fuel)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Lobbying_issue\\fuel.png")
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(air)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Lobbying_issue\\air.png")




######### Get words from Bills (env. protection + energy) ##########
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


# CATEGORY 1: ENVIRONMENTAL PROTECTION
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Env_protection"
os.chdir(library)
file = open('all_env_prot.csv')
csv_f = csv.reader(file, delimiter=',')

i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    #print(text)
    #print('Keywords:', output)
    list_ = list_+output
    i=i+1
    #if i==5:
    #    break

env_prot = ' '.join(str(e) for e in list_)
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(env_prot)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\env_protection.png")

# CATEGORY 4: ENERGY
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Energy"
os.chdir(library)
file = open('all_energy.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
energy_b = ' '.join(str(e) for e in list_)
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(energy_b)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Energy.png")

# Green/ Brown Bills
bills_green = env_prot+ energy_b
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(bills_green)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\\bills_green_brown.png")



# Bills + Issues Dictionary
issues_green = issues_green.replace(',', '')
all_green_words = bills_green + issues_green

wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(all_green_words)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\\all_green_words.png")


######### Combine Bills and Issue words into one dictionary ##########

# Combine Green/Brown Issues AND Bills
# use 50% * bills_green + 50% * issues_green

# count number of unique words first
bagOfWords_bills = bills_green.split(', ')
bagOfWords_issues = issues_green.split(', ')
uniqueWords = set(bagOfWords_bills).union(set(bagOfWords_issues))
numOfWords_bills = dict.fromkeys(uniqueWords, 0)
for word in bagOfWords_bills:
    numOfWords_bills[word] += 1
numOfWords_issues = dict.fromkeys(uniqueWords, 0)
for word in bagOfWords_issues:
    numOfWords_issues[word] += 1
    
# find the weight all words 
length_bills=len(bagOfWords_bills)
for word in uniqueWords:
    numOfWords_bills[word] = numOfWords_bills[word]/length_bills
length_issues=len(bagOfWords_issues)
for word in uniqueWords:
    numOfWords_issues[word] = numOfWords_issues[word]/length_issues


######### Compute TF ##########3

# find tf (term frequency) of Bills and Issues
def computeTF(wordDict, bagOfWords):
    tfDict = {}
    bagOfWordsCount = len(bagOfWords)
    for word, count in wordDict.items():
        tfDict[word] = count / float(bagOfWordsCount)
    return tfDict

tf_bills = computeTF(numOfWords_bills, bagOfWords_bills)
tf_issues = computeTF(numOfWords_issues, bagOfWords_issues)    
    
# combine bills and issues
# find the average weight of each word between issues and bills
tf_green = dict.fromkeys(uniqueWords, 0)
for word in uniqueWords:
    tf_green[word] = 0.5*tf_bills[word] + 0.5*tf_issues[word]

######### Compute IDF ##########3
    
# import all transactions for idf
library="R:\\ps664\\Data\\Lobbying Data"
os.chdir(library)
file = open('lobbying_data.csv', encoding="raw_unicode_escape")
csv_f = csv.reader(file, delimiter=',')

path1="R:\ps664\Data\Lobbying Data\lobbying_data.csv"
data_df = pd.read_csv(path1, encoding='raw_unicode_escape')
all_issues = data_df[['SpecificIssue', 'ID']]
all_issues1 = all_issues.drop_duplicates('SpecificIssue')

all_issues2 = all_issues1.drop_duplicates('SpecificIssue')
all_issues2['SpecificIssue'] = all_issues2['SpecificIssue']+' '
all_issues3 = all_issues1.groupby('ID').sum()

# add bill's words to the based of idf
all_issues4 = all_issues3.append({'bills_text': bills_green},ignore_index=True)


# now remove stop words from issues
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




bagOfWords_all = []
i=0
for index, value in all_issues4['SpecificIssue'].items():
    #print(f"Index : {index}, Value : {value}")
    try:
        one_issue = get_hotwords(value)
        bagOfWords_all = bagOfWords_all + [one_issue]
    except:
        print('skipped')
    i=i+1
    print(i)
    #if i>5:
    #    break

# get a dictionary of unique words
uniqueWords_all={}
for element in bagOfWords_all:
    uniqueWords_all = set(uniqueWords_all).union(set(element))
numOfWords_all = dict.fromkeys(uniqueWords_all, 0)


# Compute idf = log(N of docs with a word / total docs)
N = len(bagOfWords_all)
idfDict = dict.fromkeys(uniqueWords_all, 0)

for transaction in bagOfWords_all:
    for word in idfDict:
        if word in transaction:
            idfDict[word] += 1
import math
for word, val in idfDict.items():
    idfDict[word] = math.log(N / (float(val)+1))
idf_all = idfDict
# this idf will scale up rarely used words and scale down words with high frequency
    
######### Compute TF-IDF for Green issues/bills ##########3
 
def computeTFIDF(tfBagOfWords, idfs):
    tfidf = {}
    for word, val in tfBagOfWords.items():
        tfidf[word] = val * idfs[word]
    return tfidf

tfidf_green = computeTFIDF(tf_green, idf_all)
    
######### Compute TF-IDF for every other transaction to compute similarity ##########3

tf_bills = computeTF(numOfWords_bills, bagOfWords_bills)
   
tf_all = [] 
for transaction in bagOfWords_all:
    uniqueWords = set(transaction)
    numOfWords_i = numOfWords_all 
    for word in transaction:
        numOfWords_i[word] += 1
    tf_i = computeTF(numOfWords_i,transaction)
    tf_all.append(tf_i)

tfidf_all=[]
for transaction in tf_all:
    tfidf_i = computeTFIDF(transaction, idf_all)
    tfidf_all.append(tfidf_i)
    
######### Compute TF-IDF cos similarity between green and each transaction ##########
    
from sklearn.metrics.pairwise import cosine_similarity    
from scipy import spatial

frame_idf=pd.DataFrame(idf_all, index=[0])
frame_tf_all=pd.DataFrame(tf_all)
frame_tfidf_all=pd.DataFrame(tfidf_all)

frame_idf=frame_idf.transpose()
frame_tf_all=frame_tf_all.transpose()
frame_tfidf_all=frame_tfidf_all.transpose()

#cos_i = cosine_similarity(frame_tfidf_all[1], frame_tfidf_all[2])

cos_i = 1 - spatial.distance.cosine(frame_tfidf_all[1], frame_tfidf_all[2])

i=0
cos_all=[]
while i<5:
    i=i+1
    cos_i = 1 - spatial.distance.cosine(frame_tfidf_all[1], frame_tfidf_all[2])
    cos_all = cos_all


cos_all = {}
for (columnName, columnData) in frame_tfidf_all.iteritems(): 
    cos_i = nan
    #print('Colunm Name : ', columnName)     
    cos_i = 1 - spatial.distance.cosine(columnData.values, frame_tfidf_all[3])
    cos_all[columnName] = cos_i

# map ID of all transactions back to corr numbers






    
        
################################
    
docs_cos = {'ID' : all_issues3['SpecificIssue'], cos_all : cos_all}

frame_full = pd.DataFrame({'file number': row[0], 'gvkey': row[1],  'year_file': row[2], 'year':  row[2],
         'firm name' : row[3], 'director name' : None, 'salary': None, 'bonus': None, 'stock': None,
         'options': None, 'non equity' :  None, 'pension' : None, 'other comp' : None,
         'total' :  None, 'table found' : 0 , 'link' : row[6] }, index =[0]) 

    
    
    
numOfWords_all = []
for sentense in bagOfWords_all:
    numOfWords_sentence = dict.fromkeys(uniqueWords_all, 0)
    for word in bagOfWords_all[sentense]:
        numOfWords_sentence[word] += 1
    numOfWords_all=numOfWords_all+ [numOfWords_sentence]

#### EXAMPLE
uniqueWords = set(bagOfWordsA).union(set(bagOfWordsB))
numOfWordsA = dict.fromkeys(uniqueWords, 0)
for word in bagOfWordsA:
    numOfWordsA[word] += 1
    
    
idfs = computeIDF([numOfWordsA, numOfWordsB])

def computeIDF(documents):
    import math
    N = len(documents)
    
    idfDict = dict.fromkeys(documents[0].keys(), 0)
    for document in documents:
        for word, val in document.items():
            if val > 0:
                idfDict[word] += 1
    
    for word, val in idfDict.items():
        idfDict[word] = math.log(N / float(val))
    return idfDict



# how to do tf-idf:
# https://sites.temple.edu/tudsc/2017/03/30/measuring-similarity-between-texts-in-python/
# https://towardsdatascience.com/natural-language-processing-feature-engineering-using-tf-idf-e8b9d00e7e76


# easy td-idf computation example
# https://www.analyticsvidhya.com/blog/2020/02/quick-introduction-bag-of-words-bow-tf-idf/




################################

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

import pandas as pd
from sklearn.feature_extraction.text import TfidfVectorizer
documentA = 'the man went out for a walk'
documentB = 'the children sat around the fire'
bagOfWordsA = documentA.split(' ')
bagOfWordsB = documentB.split(' ')
uniqueWords = set(bagOfWordsA).union(set(bagOfWordsB))
numOfWordsA = dict.fromkeys(uniqueWords, 0)
for word in bagOfWordsA:
    numOfWordsA[word] += 1
numOfWordsB = dict.fromkeys(uniqueWords, 0)

for word in bagOfWordsB:
    numOfWordsB[word] += 1


# weight each word

from nltk.corpus import stopwords
stopwords.words('english')
def computeTF(wordDict, bagOfWords):
    tfDict = {}
    bagOfWordsCount = len(bagOfWords)
    for word, count in wordDict.items():
        tfDict[word] = count / float(bagOfWordsCount)
    return tfDict

tfA = computeTF(numOfWordsA, bagOfWordsA)
tfB = computeTF(numOfWordsB, bagOfWordsB)

def computeIDF(documents):
    import math
    N = len(documents)
    
    idfDict = dict.fromkeys(documents[0].keys(), 0)
    for document in documents:
        for word, val in document.items():
            if val > 0:
                idfDict[word] += 1
    
    for word, val in idfDict.items():
        idfDict[word] = math.log(N / float(val))
    return idfDict

idfs = computeIDF([numOfWordsA, numOfWordsB])
def computeTFIDF(tfBagOfWords, idfs):
    tfidf = {}
    for word, val in tfBagOfWords.items():
        tfidf[word] = val * idfs[word]
    return tfidf
tfidfA = computeTFIDF(tfA, idfs)
tfidfB = computeTFIDF(tfB, idfs)
df = pd.DataFrame([tfidfA, tfidfB])
vectorizer = TfidfVectorizer()
vectors = vectorizer.fit_transform([documentA, documentB])
feature_names = vectorizer.get_feature_names()
dense = vectors.todense()
denselist = dense.tolist()
df = pd.DataFrame(denselist, columns=feature_names)








documentA = 'the man went out for a walk'
bagOfWordsA = documentA.split(' ')
uniqueWords = set(bagOfWordsA).union(set(bagOfWordsB))
numOfWordsA = dict.fromkeys(uniqueWords, 0)
for word in bagOfWordsA:
    numOfWordsA[word] += 1

# weight each word

from nltk.corpus import stopwords
stopwords.words('english')

def computeTF(wordDict, bagOfWords):
    tfDict = {}
    bagOfWordsCount = len(bagOfWords)
    for word, count in wordDict.items():
        tfDict[word] = count / float(bagOfWordsCount)
    return tfDict

tfA = computeTF(numOfWordsA, bagOfWordsA)


