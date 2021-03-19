# -*- coding: utf-8 -*-
"""
Created on Mon Oct 12 17:34:04 2020

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

# pip install spacy
# in command line run: python -m spacy download en_core_web_lg


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

str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\env_protection.png")



# CATEGORY 2: AGRICULTURAL FOOD
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Agr_food"
os.chdir(library)
file = open('113_116_.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Agr_food.png")

# CATEGORY 3: ANIMALS
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Animals"
os.chdir(library)
file = open('106_116.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Animals.png")

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
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Energy.png")

# CATEGORY 5: Health
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Health"
os.chdir(library)
file = open('112.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Health.png")

# CATEGORY 5: PUBLIC LANDS AND NATURAL RESOURCES
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Public_lands_nat_res"
os.chdir(library)
file = open('all_public.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Public_lands_nat_res.png")

# CATEGORY 6: SCIENCE TECH
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Science_tech"
os.chdir(library)
file = open('115_116.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Science_tech.png")

# CATEGORY 7: TAX
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Tax"
os.chdir(library)
file = open('115.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Tax.png")


# CATEGORY 8: TAX
library="R:\\ps664\\Data\\Lobbying Bills\\Congress gov\\Water_resource_dev"
os.chdir(library)
file = open('all_water.csv')
csv_f = csv.reader(file, delimiter=',')
i=1
list_=[]
for row in csv_f:
    text=row[4]
    output=get_hotwords(text.lower())
    list_ = list_+output
    i=i+1
str1 = ' '.join(str(e) for e in list_)
from wordcloud import WordCloud, STOPWORDS 
import matplotlib.pyplot as plt
wordcloud = WordCloud(width = 800, height = 400, 
                background_color ='white',  
                min_font_size = 10).generate(str1)
plt.figure(figsize = (8, 8), facecolor = None) 
plt.imshow(wordcloud) 
plt.axis("off") 
plt.tight_layout(pad = 0)   
plt.show()
wordcloud.to_file("R:\ps664\Patent Applications - Michelle Michela\Wordclouds\Bills_title_clouds\\Water_resource_dev.png")


# LDA models and machine leadning:
#https://www.kaggle.com/thebrownviking20/topic-modelling-with-spacy-and-scikit-learn
#https://towardsdatascience.com/topic-modeling-and-latent-dirichlet-allocation-in-python-9bf156893c24
#https://towardsdatascience.com/end-to-end-topic-modeling-in-python-latent-dirichlet-allocation-lda-35ce4ed6b3e0








    
    
    
    
    
    
    
    
    
    
    
    