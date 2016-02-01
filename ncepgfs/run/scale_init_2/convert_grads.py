import numpy as np
import datetime as dt
from scale import *
from scale.grads import convert
import sys
import os

basename = sys.argv[1]
outdir = sys.argv[2]
year = int(sys.argv[3])
month = int(sys.argv[4])
day = int(sys.argv[5])
hour = int(sys.argv[6])

print(basename)

#vcoor = 'o'
vcoor = 'p'
#plevels = [100000., 92500., 85000., 70000., 50000., 30000., 20000., 10000., 5000., 2000., 1000.]
plevels = [85000., 70000., 50000., 30000.]
#varout_3d = ['u', 'v', 'w', 'p', 'tk', 'theta', 'rho', 'momx', 'momy', 'momz', 'rhot', 'z', 'qv', 'qc', 'qr', 'qi', 'qs', 'qg', 'qhydro', 'dbz']
varout_3d = ['u', 'v', 'w', 'tk', 'z', 'dbz']
varout_2d = ['topo', 'slp', 'rain', 'snow', 'max_dbz']
proj = {
'type': 'LC',
'basepoint_lon': 135.,
'basepoint_lat': 35.,
'LC_lat1': 30.0,
'LC_lat2': 40.0
}
extrap = True
#tskip = 6
#threads = 1

topofile = '/data7/gylien/realtime/ncepgfs/run/scale_init_2/topo'

time = dt.datetime(year, month, day,  hour,  0,  0)
timef = time.strftime('%Y%m%d%H%M%S')

convert(basename, topo=topofile, gradsfile=outdir+'/'+timef+'.grd', ctlfile=outdir+'/yyyymmddhhmmss.ctl', t=time,
        vcoor=vcoor, plevels=plevels, varout_3d=varout_3d, varout_2d=varout_2d, proj=proj)
