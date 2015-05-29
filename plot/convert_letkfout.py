import numpy as np
import datetime as dt
from scale.letkf import letkfout_grads
import sys
import os

letkfoutdir = sys.argv[1]
stimestr = sys.argv[2]
tstart = int(sys.argv[3])
tend = int(sys.argv[4])
tskip = int(sys.argv[5])

vcoor = 'p'
#plevels = [100000., 92500., 85000., 70000., 50000., 30000., 20000., 10000., 5000., 2000., 1000.]
plevels = [85000., 70000., 50000., 30000.]
#varout_3d = ['u', 'v', 'w', 'p', 'tk', 'theta', 'rho', 'momx', 'momy', 'momz', 'rhot', 'z', 'qv', 'qc', 'qr', 'qi', 'qs', 'qg', 'qhydro', 'dbz']
varout_3d = ['u', 'v', 'w', 'tk', 'z', 'rh', 'dbz']
varout_2d = ['topo', 'u10', 'v10', 't2', 'slp', 'rain', 'snow', 'max_dbz', 'olr', 'tsfc', 'sst']
proj = {
'type': 'LC',
'basepoint_lon': 135.,
'basepoint_lat': 35.,
'LC_lat1': 30.0,
'LC_lat2': 40.0
}
extrap = True
tskip = 6
#threads = 1

topofile = os.path.abspath(__file__) + '/topo/topo'

stime = dt.datetime.strptime(stimestr, '%Y%m%d%H%M%S')
etime = stime
tint = dt.timedelta(hours=6)

outtype = 'fcst'
member = 0


letkfout_grads(letkfoutdir, topofile=topofile, proj=proj, stime=stime, etime=etime, tint=tint,
               outtype=outtype, member=member,
               vcoor=vcoor, plevels=plevels, varout_3d=varout_3d, varout_2d=varout_2d, extrap=extrap,
               tstart=tstart, tend=tend, tskip=tskip) #, threads=threads)

