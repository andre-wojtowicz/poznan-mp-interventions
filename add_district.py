# -*- coding: utf-8 -*-

import csv

#____________________________________________

INPUT_OUTPUT_FILE = "gen/parsed-poznan-mp-interventions-2013-06-17-2013-10-09.csv"
DISTRICTS_FILE = "db/poznan-districts-wgs.csv"

#____________________________________________

def point_inside_polygon(x,y,poly):

    n = len(poly)
    inside =False

    p1x,p1y = poly[0]
    for i in range(n+1):
        p2x,p2y = poly[i % n]
        if y > min(p1y,p2y):
            if y <= max(p1y,p2y):
                if x <= max(p1x,p2x):
                    if p1y != p2y:
                        xinters = (y-p1y)*(p2x-p1x)/(p2y-p1y)+p1x
                    if p1x == p2x or x <= xinters:
                        inside = not inside
        p1x,p1y = p2x,p2y

    return inside
    
#____________________________________________

d = {}

with open(DISTRICTS_FILE) as f:
    header = f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')
    
    for line in content:
        name, coords = line
        
        coords = coords.split(" ")
        tmp = []
        for pair in coords:
            x,y = pair.split(";")
            tmp.append((float(x), float(y)))
            
        d[name] = tmp
        
header = None
to_write = []
with open(INPUT_OUTPUT_FILE) as f:
    header = f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')

    
    for line in content:
        id,date,time,category,district,street,lat,lon = line
        
        f_lat, f_lon = float(lat), float(lon)
        
        for key in d:
            if point_inside_polygon(f_lat,f_lon, d[key]):
                district = key
                break
        else:
            print id # print ids of places which are not in any district; 
                     # they should be corrected manualy or rechecked by modified add_lat_lon.py script because
                     # sometimes it's better not to include street prefix - Google may return street in neighbouring village!
        
        to_write.append([id,date,time,category,district,street,lat,lon])
            
with open(INPUT_OUTPUT_FILE, "wb") as ofile:
    ofile.write(header)
    writer = csv.writer(ofile, delimiter=',', quotechar='"', quoting=csv.QUOTE_ALL)
    
    for row in to_write:
        writer.writerow(row)