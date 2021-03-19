# -*- coding: utf-8 -*-
"""
Created on Mon Nov  2 10:26:34 2020

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
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.feature_extraction.text import CountVectorizer
import pickle
from sklearn.metrics.pairwise import cosine_similarity    
from scipy import spatial




############################################################################
############################################################################
########################### Identify Hot Words  ############################
#######   (remove stopwords, punctuation, keep PROPN, ADJ, NOUN)   #########
############################################################################



########################### Get Green Vocabulary############################

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

issues_green = issues_green.replace(',', '')

# Add all collected databrames together


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

# Green/ Brown Bills
bills_green = env_prot+ energy_b

f = open(r"R:\ps664\Data\Lobbying Data\temp files\bills_green.pkl","wb")
pickle.dump(bills_green,f)
f.close()

f = open(r"R:\ps664\Data\Lobbying Data\temp files\issues_green.pkl","wb")
pickle.dump(issues_green,f)
f.close()


########################### Get Issues Vocabulary############################

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
all_issues3 = all_issues2.groupby('ID').sum()

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


all_issues4 = all_issues3.reset_index()
bagOfWords_all = []
i=0
transaction_id = list()
transaction_text = list()
for index, value in all_issues3['SpecificIssue'].items():
    #print(f"Index : {index}, Value : {value}")
    try:
        one_issue = get_hotwords(value)
        bagOfWords_all = bagOfWords_all + [one_issue]    
        transaction_id.append(all_issues4['ID'].iloc[i])
        transaction_text.append(all_issues4['SpecificIssue'].iloc[i])
    except:
        print('skipped')
        # skipped row all_issues3 in  #293, text "S. 625/H.R. 833, "Bankruptcy Reform Act of 1999""
        print(index)
        skipped_id = all_issues4.index
    i=i+1
    print(i)
    #if i>5:
    #    break


all_issues5 = pd.DataFrame({'ID': transaction_id, 'SpecificIssue' : transaction_text})
f = open(r"R:\ps664\Data\Lobbying Data\temp files\all_issues5.pkl","wb")
pickle.dump(all_issues5,f)
f.close()


f = open(r"R:\ps664\Data\Lobbying Data\temp files\bagOfWords_all.pkl","wb")
pickle.dump(bagOfWords_all,f)
f.close()


############################################################################
############################################################################
############################## Compute TF-IDF ##############################
############################################################################
############################################################################


    
with open(r'R:\ps664\Data\Lobbying Data\temp files\idf_all.pkl', 'rb') as f:
    idf_all = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\idfDict.pkl', 'rb') as f:
    idfDict = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\numOfWords_all.pkl', 'rb') as f:
    numOfWords_all = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\tfidf_green.pkl', 'rb') as f:
    tfidf_green = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\weighted_green_vocab.pkl', 'rb') as f:
    weighted_green_vocab = pickle.load(f)


with open(r'R:\ps664\Data\Lobbying Data\temp files\bills_green.pkl', 'rb') as f:
    bills_green = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\issues_green.pkl', 'rb') as f:
    issues_green = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\bagOfWords_all.pkl', 'rb') as f:
    bagOfWords_all = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\all_issues5.pkl', 'rb') as f:
    all_issues5 = pickle.load(f)

def create_document_term_matrix(message_list, vectorizer):
    doc_term_matrix=vectorizer.fit_transform(message_list)
    return pd.DataFrame(doc_term_matrix.toarray(), columns =vectorizer.get_feature_names())


# FIND TF FOR GREEN VOCABULARY, WEIGHTED
bagOfWords_bills = bills_green.split(', ')
bagOfWords_issues = issues_green.split(', ')
msg_1 = bagOfWords_issues + bagOfWords_bills
count_vect = CountVectorizer()
aa = create_document_term_matrix(msg_1, count_vect)
length_issues=sum(aa.iloc[0])
length_bills=sum(aa.iloc[1])
aa.iloc[0] = aa.iloc[0]/length_issues
aa.iloc[1] = aa.iloc[1]/length_bills
length_check_issues=sum(aa.iloc[0])
length_check_issues=sum(aa.iloc[1])
weighted_green_vocab = 0.5*aa.iloc[0] + 0.5*aa.iloc[1]
f = open(r'R:\ps664\Data\Lobbying Data\temp files\weighted_green_vocab.pkl', 'wb')
pickle.dump(weighted_green_vocab,f)
f.close()

bb_ = weighted_green_vocab.to_dict()
green_sentense = ''
for word, val in bb_.items():
    green_sentense = green_sentense + ' ' + (word+' ')*int(val*10000000)


            #### OR no 50%/50% weighting ####
            green_sentense = bagOfWords_bills[0] + ' ' + bagOfWords_issues[0]




# FIND TF FOR ALL WORDS
def listToString(s):  
    str1 = " " 
    return (str1.join(s)) 

all_docs=list()
for element in bagOfWords_all:
    all_docs.append(listToString(element))
all_docs.insert(0, green_sentense)

cv=CountVectorizer() 
word_count_vector=cv.fit_transform(all_docs)
word_count_vector.shape

# compute idf
from sklearn.feature_extraction.text import TfidfTransformer 
tfidf_transformer=TfidfTransformer(smooth_idf=True,use_idf=True) 
tfidf_transformer.fit(word_count_vector)
df_idf = pd.DataFrame(tfidf_transformer.idf_, index=cv.get_feature_names(),columns=["idf_weights"]) 
df_idf.sort_values(by=['idf_weights'])
 
# compute tf-idf 
count_vector=cv.transform(all_docs) 
tf_idf_vector=tfidf_transformer.transform(count_vector)
feature_names = cv.get_feature_names() 
first_document_vector=tf_idf_vector[0] 
df = pd.DataFrame(first_document_vector.T.todense(), index=feature_names, columns=["tfidf"]) 
df.sort_values(by=["tfidf"],ascending=False)

# compute cosine similrity between Green Vocab (obs #1) and all other transactions
first_document_vector=tf_idf_vector[0] 
green_vocab = pd.DataFrame(first_document_vector.T.todense(), index=feature_names, columns=["tfidf"])  


#test cos
first_document_vector=tf_idf_vector[3] 
transaction = pd.DataFrame(first_document_vector.T.todense(), index=feature_names, columns=["tfidf"]) 
cos_i = 1 - spatial.distance.cosine(green_vocab, transaction)


all_cos=list()
for i in range(1,len(all_issues5)):
    print(i)
    first_document_vector=tf_idf_vector[i] 
    transaction = pd.DataFrame(first_document_vector.T.todense(), index=feature_names, columns=["tfidf"]) 
    cos_i = 1 - spatial.distance.cosine(green_vocab, transaction)
    print(i)
    all_cos.append(cos_i)
    
#f = open(r"R:\ps664\Data\Lobbying Data\temp files\all_cos_2.pkl","wb")
f = open(r"R:\ps664\Data\Lobbying Data\temp files\all_cos_50_2.pkl","wb")
pickle.dump(all_cos,f)
f.close()

# save the dataset as pkl
# add back the skipped transaction 
#all_cos.insert(293, 0)

all_issues5['cosine_sim']=all_cos
final_set = all_issues5
#f = open(r"R:\ps664\Data\Lobbying Data\temp files\final_set_2.pkl","wb")
f = open(r"R:\ps664\Data\Lobbying Data\temp files\final_set_no50_2.pkl","wb")
pickle.dump(final_set,f)
f.close()


# save the dataset as csv
final_set = final_set.drop(['SpecificIssue'], axis=1)
#with open(r'R:\ps664\Data\Lobbying Data\temp files\final_set_2.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
#    final_set.to_csv(f, header=False)
with open(r'R:\ps664\Data\Lobbying Data\temp files\final_set_no50_2.csv', 'a', newline='', encoding="latin-1", errors="replace") as f:
    final_set.to_csv(f, header=False)


# histogram cos values
lk = pd.Series(all_cos)
lk.plot.hist(grid=True, bins=20, rwidth=0.9,
                   color='#607c8e')


# TRY NOT TO WEIGTH BILLS + ISSUES => THERE MIGHT BE DIFFERENT KEYWORDS
# try no tf-idf, just bag of words approach (tf)
# merge back to data, do Michela's validity check on Green cases based on Bills & Issues
# 


## For Summary Stats on The matching
    
# Top 10 text matches
with open(r'R:\ps664\Data\Lobbying Data\temp files\final_set_2.pkl', 'rb') as f:
    final_set = pickle.load(f)

# number of unique words coming from Issues and Bills - size of tf(green voc)
with open(r'R:\ps664\Data\Lobbying Data\temp files\bills_green.pkl', 'rb') as f:
    bills_green = pickle.load(f)
with open(r'R:\ps664\Data\Lobbying Data\temp files\issues_green.pkl', 'rb') as f:
    issues_green = pickle.load(f)

def create_document_term_matrix(message_list, vectorizer):
    doc_term_matrix=vectorizer.fit_transform(message_list)
    return pd.DataFrame(doc_term_matrix.toarray(), columns =vectorizer.get_feature_names())
bagOfWords_bills = bills_green.split(', ')
bagOfWords_issues = issues_green.split(', ')
msg_1 = bagOfWords_issues + bagOfWords_bills
count_vect = CountVectorizer()
aa = create_document_term_matrix(msg_1, count_vect)
length_issues=sum(aa.iloc[0])
length_bills=sum(aa.iloc[1])
    
# Wordcloud of all words in LD-2s ("corpus")
with open(r'R:\ps664\Data\Lobbying Data\temp files\bagOfWords_all.pkl', 'rb') as f:
    bagOfWords_all = pickle.load(f)
    
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(bagOfWords_all)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\\all_ld_2s.png")
    
# number of unique words from LD-2s (all words)    
with open(r'R:\ps664\Data\Lobbying Data\temp files\numOfWords_all.pkl', 'rb') as f:
    numOfWords_all = pickle.load(f)
   
    
# number of unique documents or LD-2s - 461,030    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
