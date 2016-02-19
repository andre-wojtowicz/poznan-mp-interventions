# -*- coding: utf-8 -*-

import csv

#____________________________________________

INPUT_OUTPUT_FILE = "gen/parsed-poznan-mp-interventions-2013-06-17-2013-10-09.csv"

#____________________________________________

to_write = []

with open(INPUT_OUTPUT_FILE) as f:

    header = f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')
    
    for line in content:
        row,id,date,time,category,description,department,district,street1_ref_id,street1_prefix,street1_name,street1_number,street2_ref_id,street2_prefix,street2_name,street2_number,street3_ref_id,street3_prefix,street3_name,street3_number,lat,lon = line
        
        if street1_name == '' or lat == '':
            continue
            
        street = "{0} {1}".format(street1_prefix, street1_name)
            
        to_write.append([id,date,time,category,district,street,lat,lon])
            

with open(INPUT_OUTPUT_FILE, "wb") as ofile:

    ofile.write('"id","date","time","category","district","street","lat","lon"\n')
    writer = csv.writer(ofile, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
    
    for row in to_write:
        writer.writerow(row)