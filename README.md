Municipal Police of Poznań - visualization of interventions
=======================

This repo contains scripts and data necessary to visualize on a map the interventions given by Municipal Police of Poznań. Statistics are presented for 2013-06-17 - 2013-10-09.

# Tableau

**Update**

I moved some results to Tableau. The packaged workbook file (v10.2) is stored in [Releases](https://github.com/andre-wojtowicz/poznan-mp-interventions/releases). Here is a screeshot of a generated dashboard:

![tableau](https://andre-wojtowicz.github.io/poznan-mp-interventions/tableau.png)

# District HTML heatmaps

Generated interventions heatmaps for districts:

* [no. interventions in districts](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-interventions.html),
* [log no. interventions in districts](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-log-interventions.html),
* [no. interventions per citizens in districts](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-interventions-per-citizens.html),
* [log no. interventions per citizens in districts](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-log-interventions-per-citizens.html).

# QGIS

Final maps are stored in [QGIS](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-pl-qgis.zip) format. Generated images of QGIS interventions heatmaps for districts:

![all](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-heatmap-all.png)

![alcohol](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-heatmap-alcohol.png)

![parking](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-heatmap-parking.png)

![disturbing public order](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-heatmap-disturbing.png)

# Other statistic

Generated statistics are stored as [XLSX](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-interventions-2013-06-17-2013-10-09-stats.xlsx).

Time of reports:

![time of reports](https://andre-wojtowicz.github.io/poznan-mp-interventions/poznan-mp-2013-06-17-2013-10-09-time-of-reports.png)

# Reproducibility

## Requirements 

* R 3.x with vwr library
* Python 2.6 with requests library

## How-to 

I assume you have your own raw copy of the list of MP interventions, i.e. `db/poznan-mp-interventions-2013-06-17-2013-10-09.csv`.

Execution goes as follows:

1. `extract_streets_and_places.R` - looks for name of street or place in description of intervention,
2. `add_lat_lon.py` - performs reverse geocoding using Google Maps API,
3. `clean_csv.py` - removes unnecessary columns,
4. `add_district.py` - adds name of district to intervention,
5. `create_html_visualizations.py` - generates nice html heat-maps for districts (in Polish).

### Notes for scripts 

* `add_lat_lon.py` - sometimes Google returns that there is no lon/lat for given address; then just re-run the script.
* `add_district.py` - some of coordinates given by Google may lay outside the districts boundaries; the script will output ids of such interventions.

# Sources of data

* list of streets in Poznań - [Poznań API](http://www.poznan.pl/api)
* list of streets, parks, bridges in Poznań - [GEOPOZ](http://sip.geopoz.pl/)
* [list of districts in Poznań](http://www.poznan.pl/mim/osiedla/list/) with their boundaries ([an example for Jeżyce](http://www.poznan.pl/mim/plan/services.html?co=gml&service=districts&districts_id=42))
* number of citizens in districts of Poznań - [GEOPOZ](http://sip.geopoz.pl/)
