# -*- coding: utf-8 -*-

# INFO: it's good to re-run this script several times because Google sometimes (very rarely) returns no result for query

import csv
import requests
from xml.dom import minidom

#____________________________________________

INPUT_OUTPUT_FILE = "gen/parsed-poznan-mp-interventions-2013-06-17-2013-10-09.csv"

START_FROM_ID = 1 # set if you have to restart getting lat/lon after breaking Google limit

USE_PROXY = False # set to True if you want to forget about Google limit
HTTP_PROXY  = "http://41.207.116.249:3128"

#____________________________________________

proxyDict = {}
if USE_PROXY:
    proxyDict = {"http"  : HTTP_PROXY}
    
header = None

to_write = []
        
with open(INPUT_OUTPUT_FILE) as f:
    header = f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')

    for line in content:
        row,id,date,time,category,description,department,district,street1_ref_id,street1_prefix,street1_name,street1_number,street2_ref_id,street2_prefix,street2_name,street2_number,street3_ref_id,street3_prefix,street3_name,street3_number,lat,lon = line
        
        if int(id) < START_FROM_ID:
            continue
        
        if street1_name != "" and lat == "": # ignore street2 and street3, maybe they will be used in the future; also omit rows with already gathered lat/lon

            ref_id,prefix,name,number = street1_ref_id,street1_prefix,street1_name,street1_number
            
                        
            try:
                city = "Poznań".decode("utf-8")
                address = "{0} {1}".format(prefix, name)
                query = city + ", " + address.decode("cp1250")

                if number != "":
                    query = query+" "+str(number)
                
                results = requests.get("http://maps.googleapis.com/maps/api/geocode/xml", 
                                  params={'address': query, 
                                          'sensor': 'true'}, 
                                  headers={'Accept': "application/xml"}, 
                                  proxies=proxyDict
                                  )
                                  
                xmldoc = minidom.parseString(results.text.encode("utf-8"))
                
                lat = xmldoc.getElementsByTagName('lat')[0].firstChild.nodeValue
                lon = xmldoc.getElementsByTagName('lng')[0].firstChild.nodeValue
                
                print id + " " + query + " - " + lat + " " + lon
            
            except Exception as e:
                print id, e
            
        to_write.append([row,id,date,time,category,description,department,district,street1_ref_id,street1_prefix,street1_name,street1_number,street2_ref_id,street2_prefix,street2_name,street2_number,street3_ref_id,street3_prefix,street3_name,street3_number,lat,lon])

        
with open(INPUT_OUTPUT_FILE, "wb") as ofile:

    ofile.write(header)
    writer = csv.writer(ofile, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
        
    for row in to_write:
        writer.writerow(row)
