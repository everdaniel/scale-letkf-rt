import netCDF4
import datetime
import pytz
import numpy
from os import path, makedirs
import pytz
from pytz import timezone
import sys
from argparse import ArgumentParser

##### Utility functions
def _to_str(dt):
    return dt.strftime("%Y%m%d%H%M%S")

def _to_dt(s):
    dt = datetime.datetime.strptime(s, "%Y%m%d%H%M%S")
    return dt.replace(tzinfo=timezone('UTC'))

##### Parse command line arguments
parser = ArgumentParser()
                   
parser.add_argument("-s", "--start", dest="start", required=True,
                    help="The starting date-time identifier (e.g., 20150901000000).")

parser.add_argument("-e", "--end",  dest="end", required=True,
                    help="The ending date-time identifier (e.g., 20160131180000).")  
                    
parser.add_argument("-t", "--observation-file", dest="observation_file", required=True, metavar="FILE",
                    help="File containing observation." )
               
parser.add_argument("-f", "--feature-dir", dest="feature_dir",
                    help="Directory to output feature database (default directory is /data9/gulan/ann/features/).")
                    
parser.add_argument("-q", "--quiet", action="store_false", required=False, dest="verbose", default=True, 
                    help="don't print status messages to stdout.")
                                       
args = parser.parse_args()


##### Constants and Variables
DIFF = 273.15
DEFAULT_FEATURE_DIR="/data9/gulan/ann/features/"
TEMPLATES=["/data7/gylien/realtime/exp/EastAsia_18km_48p_part1/{}/fcst/mean/history.pe000020.nc",
		   "/data9/gylien/realtime/exp/EastAsia_18km_48p/{}/fcst/mean/history.pe000020.nc"]

verbose = args.verbose
observation_file = args.observation_file
feature_dir = args.feature_dir if args.feature_dir and path.exists(args.feature_dir) else DEFAULT_FEATURE_DIR
dt_start = _to_dt(args.start)
dt_end = _to_dt(args.end)

OB = {} # Observation table
NC = [] # nc file list

##### Validity check
assert path.exists(feature_dir), "ERROR: Directory not found! ({})".format(feature_dir)
assert path.exists(observation_file), "ERROR: File not found! ({})".format(observation_file)
assert dt_start <= dt_end, "ERROR: Invalid data-time range!"

##### Load observation
if verbose: print ("Loading real temperatures.")
with open(args.observation_file, "r") as input:
    lines = input.readlines()
    for line in lines:
        cols = line.strip().split("\t")
        dt = datetime.datetime.strptime(cols[0], "%m/%d/%Y %H:%M")
        dt = dt.replace(tzinfo=timezone('UTC'))
        dt = _to_str(dt)
        temperture = float(cols[1])
        OB[dt] = temperture

##### Collecting nc files of range: dt_start ~ dt_end
if verbose: print("Collecting nc file list...")
dt_cur = dt_start
while dt_cur <= dt_end:
	dt_cur_str = _to_str(dt_cur)
	candidates = [t.format(dt_cur_str) for t in TEMPLATES if path.exists(t.format(dt_cur_str))]
	assert len(candidates) == 1, "ERROR: File not found for {}".format(dt_cur_str)
	nc_file = candidates[0]
	NC.append((nc_file, dt_cur_str))
	dt_cur = dt_cur + datetime.timedelta(hours=6)


##### Extract features
X_data = numpy.zeros((len(NC), 121, 14))
y_data = numpy.zeros((len(NC), 121, 1))
inter_data = numpy.zeros((len(NC), 121, 1))
date_table = [] # list of initial date of nc files

if verbose: print("Extracting features...")
for idx1, nc in enumerate(NC):
    nc_file = nc[0]
    nc_dt_str = nc[1]
    dataset = netCDF4.Dataset(nc_file, "r")
    var_time =  dataset.variables["time"]
    var_T, var_U, var_V =  dataset.variables["T"], dataset.variables["U"], dataset.variables["V"]

    #if idx1 == 5: 
    #    break      
    # Loop 121 times
    since = datetime.datetime(_to_dt(nc_dt_str).year, 1, 1, 0, 0, 0, 0, tzinfo=pytz.utc) 
    for idx2 in range(0, len(var_time)):
        sec = var_time[idx2]
        dt = since + datetime.timedelta(seconds=sec)
        dt_str = _to_str(dt)
        if idx2 == 0: date_table.append(dt_str)
        real_temperture = OB[dt_str]

        #features
        forecast_time = idx2
        time_of_day = dt.hour
        t1, t2, t3, t4 = var_T[idx2, 0, 37, 0] - DIFF, var_T[idx2, 0, 38, 0] - DIFF, var_T[idx2, 0, 37, 1] - DIFF, var_T[idx2, 0, 38, 1] - DIFF   
        u1, u2, u3, u4 = var_U[idx2, 0, 37, 0], var_U[idx2, 0, 38, 0], var_U[idx2, 0, 37, 1], var_U[idx2, 0, 38, 1]
        v1, v2, v3, v4 = var_V[idx2, 0, 37, 0], var_V[idx2, 0, 38, 0], var_V[idx2, 0, 37, 1], var_V[idx2, 0, 38, 1]
        model_temperture = t1 * 0.804172 + t2 * 0.124810 + t3 * 0.061477 + t4 * 0.009541

        X_data[idx1, idx2] = (forecast_time, time_of_day, t1, t2, t3, t4, u1, u2, u3, u4, v1, v2, v3, v4)
        y_data[idx1, idx2] = real_temperture #+ DIFF
        inter_data[idx1, idx2] = model_temperture
    if verbose: print("{0} / {1}\r".format(idx1+1, len(NC)), end= "")

if verbose: print("Writing features...")
X_data.dump(path.join(feature_dir, "X_data"))
y_data.dump(path.join(feature_dir, "y_data"))
inter_data.dump(path.join(feature_dir, "inter_data"))
with open(path.join(feature_dir, "date_table"), "w") as f: 
    f.write("\n".join(date_table))
if verbose: print("Feature data has been saved to directory: {}".format(feature_dir)) 
