# -*- coding: utf-8 -*-

# some extra stuff to generate heat-maps of interventions in given district

#___________________________________________

import codecs
import colorsys
import csv
import math

#___________________________________________

INTERVENTIONS_FILE = "gen/parsed-poznan-mp-interventions-2013-06-17-2013-10-09.csv"

DISTRICTS_WGS_FILE      = "db/poznan-districts-wgs.csv"
DISTRICTS_CITIZENS_FILE = "db/poznan-districts-citizens.csv"

OUTPUT_DIR = "gen/"

CENTER_LAT = 52.407184
CENTER_LON = 16.926828

#___________________________________________

def rgb2hex(r,g,b):
    return '#%02x%02x%02x' % (r,g,b)
    
def hsv2hex(h,s,v):
    r,g,b = colorsys.hsv_to_rgb(h,s,v)
    return rgb2hex(int(r*255),int(g*255),int(b*255))
    
#___________________________________________

districts = {} # load districts boundary

with open(DISTRICTS_WGS_FILE) as f:
    header = f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')
    
    for line in content:
        name, coords = line
        
        coords = coords.split(" ")
        tmp = []
        for pair in coords:
            x,y = pair.split(";")
            tmp.append((float(x), float(y)))
            
        districts[name] = tmp
        
#___________________________________________
            
citizens = {} # load districts citizens

with open(DISTRICTS_CITIZENS_FILE) as f:
    header = f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')
    
    for line in content:
        name, num = line
            
        citizens[name] = num
        
#___________________________________________
            
interventions = {} # aggregate interventions per district

for key in districts:
    interventions[key] = 0
    
with open(INTERVENTIONS_FILE) as f:
    f.readline()
    content = csv.reader(f, delimiter=',', quotechar='"')
    
    for line in content:
        id,date,time,category,district,street,lat,lon = line
        interventions[district] += 1
        
# calc. interventions per citizen
interventions_per_citizen = interventions.copy()

for key in interventions_per_citizen:
    interventions_per_citizen[key] = interventions_per_citizen[key]/float(citizens[key])
        
#______________________________________________________________
        
# functions to generate HSV green-to-red color

def interv2hex_log(val, interventions):

    if val == 0:
        return hsv2hex(120/360.,1.,1.)
        
    MIN_LOG = 0
    mv = min(interventions.values())
    if mv != 0:
        MIN_LOG = math.log(mv)
    MAX_LOG = math.log(max(interventions.values()))

    val = math.log(val)
    val = (val-MIN_LOG)/(MAX_LOG-MIN_LOG)
    val = val*100
    h = (100 - val) * 120 / 100.
    
    return hsv2hex(h/360.,1.,1.)

def interv2hex(val, interventions):

    MIN = min(interventions.values())
    MAX = max(interventions.values())

    val = (val-MIN)/float(MAX-MIN)
    val = val*100
    h = (100 - val) * 120 / 100.
    
    if h < 0:
        h = abs(h)
    
    return hsv2hex(h/360.,1.,1.)
    
#_______________________________________________________________
    
HTML = """<!--
You are free to copy and use this sample in accordance with the terms of the
Apache license (http://www.apache.org/licenses/LICENSE-2.0.html)
-->

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml">
  <head>
    <style type="text/css">
        html {{ height: 100% }}
        body {{ height: 100%; margin: 0px; padding: 0px }}
        #container {{ width: 100%; height: 100% }}
        #nav {{ z-index: 100; position: absolute;
               margin: 10px 0px 0px 100px; background-color: #fff; 
               border: 1px #000 Solid; padding: 3px; font-size: x-small }}
        .labels {{
            color: black;
            background-color: white;
            font-size: 10px;
            font-weight: bold;
            text-align: center;
            border: 1px solid black;
            padding: 2px;
            white-space: nowrap;
        }}
        #map {{ width: 100%; height: 100% }}
    </style>
    <meta http-equiv="content-type" content="text/html; charset=utf-8"/>
    <title>{TITLE_HTML}</title>
    <script type="text/javascript" src="http://maps.google.com/maps/api/js?sensor=false"></script>
    <script type="text/javascript" src="http://google-maps-utility-library-v3.googlecode.com/svn/tags/markerwithlabel/1.1.9/src/markerwithlabel_packed.js"></script>
    <script type="text/javascript">
        function initialize()
        {{
            var mapOptions = {{
                center: new google.maps.LatLng({CENTER_LAT},{CENTER_LON}),
                mapTypeId: google.maps.MapTypeId.ROADMAP,
                zoom: 11
            }};     
            var map = new google.maps.Map(document.getElementById("map"), mapOptions);
        
            {DISTRICTS_POLYGONS}   
        }}

        google.maps.event.addDomListener(window, 'load', initialize);
    </script>
</head>
<body style="font-family: Arial; border: 0 none;">
    <div id="container">
        <div id="nav">
            <b>{TITLE_MAP}</b><br/>
            {DESCRIPTION}<br/>
            <a href="{SOURCE_URL}">{SOURCE_TXT}</a>
        </div>
        <div id="map"></div>
    </div>
</body>
</html>"""
            
DISTRICT_POLYGON_TMPL = """
            var paths_{0} = [{1}];
            
            var marker_{0} = new MarkerWithLabel({{
                position: new google.maps.LatLng(0,0),
                draggable: false,
                raiseOnDrag: false,
                map: map,
                labelContent: "{3} ({4})",
                labelAnchor: new google.maps.Point(30, 20),
                labelClass: "labels", // the CSS class for the label
                labelStyle: {{opacity: 1.0}},
                icon: "http://placehold.it/1x1",
                visible: false
             }});

            var shape_{0} = new google.maps.Polygon({{
                paths: paths_{0},
                strokeColor: '#000000',
                strokeOpacity: 0.5,
                strokeWeight: 1,
                fillColor: '{2}',
                fillOpacity: 0.35
            }});
            
            google.maps.event.addListener(shape_{0}, "mousemove", function(event) {{
                marker_{0}.setPosition(event.latLng);
                marker_{0}.setVisible(true);
            }});
            google.maps.event.addListener(shape_{0}, "mouseout", function(event) {{
                marker_{0}.setVisible(false);
            }});
              
            shape_{0}.setMap(map);
"""

#_______________________________________________________________

VISUALIZATIONS = [ {'filename' : 'poznan-mp-2013-06-17-2013-10-09-interventions.html',
                    'title_html': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09) - liczba interwencji w osiedlu.',
                    'title_map': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09)',
                    'description': 'Liczba interwencji w osiedlu.',
                    'source_url': 'http://otwartedane.kodujdlapolski.pl/dataset/poznan-straz-miejska-interwencje/resource/357876c2-0414-41a1-bca9-eeccc74a76af',
                    'source_txt': 'Źródła danych',
                    'color_func': interv2hex,
                    'color_func_par1': interventions
                    },
                    {'filename' : 'poznan-mp-2013-06-17-2013-10-09-log-interventions.html',
                    'title_html': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09) - log. liczba interwencji w osiedlu.',
                    'title_map': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09)',
                    'description': 'Log. liczba interwencji w osiedlu.',
                    'source_url': 'http://otwartedane.kodujdlapolski.pl/dataset/poznan-straz-miejska-interwencje/resource/357876c2-0414-41a1-bca9-eeccc74a76af',
                    'source_txt': 'Źródła danych',
                    'color_func': interv2hex_log,
                    'color_func_par1': interventions
                    },
                    {'filename' : 'poznan-mp-2013-06-17-2013-10-09-interventions-per-citizens.html',
                    'title_html': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09) - liczba interwencji na liczbę mieszkańców osiedla.',
                    'title_map': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09)',
                    'description': 'Liczba interwencji na liczbę mieszkańców osiedla.',
                    'source_url': 'http://otwartedane.kodujdlapolski.pl/dataset/poznan-straz-miejska-interwencje/resource/357876c2-0414-41a1-bca9-eeccc74a76af',
                    'source_txt': 'Źródła danych',
                    'color_func': interv2hex,
                    'color_func_par1': interventions_per_citizen
                    },
                    {'filename' : 'poznan-mp-2013-06-17-2013-10-09-log-interventions-per-citizens.html',
                    'title_html': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09) - log. liczba interwencji na liczbę mieszkańców osiedla.',
                    'title_map': 'Poznań - interwencje Straży Miejskiej (2013/06/17 - 2013/10/09)',
                    'description': 'Log. liczba interwencji na liczbę mieszkańców osiedla.',
                    'source_url': 'http://otwartedane.kodujdlapolski.pl/dataset/poznan-straz-miejska-interwencje/resource/357876c2-0414-41a1-bca9-eeccc74a76af',
                    'source_txt': 'Źródła danych',
                    'color_func': interv2hex_log,
                    'color_func_par1': interventions_per_citizen
                    }
]

#_______________________________________________________________

# generate html

for v in VISUALIZATIONS:

    with codecs.open(OUTPUT_DIR+v['filename'], 'w', "utf-8") as f:

        polygons = ""
                
        for i, key in enumerate(sorted(districts)):

            paths = ""
            
            for lat, lon in districts[key]:
                paths = paths + "new google.maps.LatLng({0},{1}),".format(lat,lon)
                
            paths = paths[:-1] # remove last comma
            
            color = v['color_func'](v['color_func_par1'][key], v['color_func_par1'])
            
            num = v['color_func_par1'][key]
            if isinstance(v['color_func_par1'][key], float):
                num = "%0.2f" % v['color_func_par1'][key]
            
            polygons = polygons + DISTRICT_POLYGON_TMPL.format(i, paths, color, key.decode("cp1250").encode("utf-8"), num) + "\r\n"
    
        html = HTML.format(TITLE_HTML = v['title_html'],
                            CENTER_LAT = CENTER_LAT,
                            CENTER_LON = CENTER_LON,
                            DISTRICTS_POLYGONS = polygons,
                            TITLE_MAP = v['title_map'],
                            DESCRIPTION = v['description'],
                            SOURCE_URL = v['source_url'],
                            SOURCE_TXT = v['source_txt'],
                            )
        f.write(html.decode("utf-8"))