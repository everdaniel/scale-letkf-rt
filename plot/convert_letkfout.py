import numpy as np
import datetime as dt
from scale.letkf import letkfout_grads
import sys
import os

#--- use mpi4py
#from mpi4py import MPI
#comm = MPI.COMM_WORLD
#--- do not use mpi4py
comm = None
#---

letkfoutdir = sys.argv[1]
stimestr = sys.argv[2]

vcoor = 'p'
hcoor = ['o', 'l']
plevels = [100000., 92500., 85000., 70000., 50000., 30000., 20000., 10000., 5000., 2000., 1000., 500.]
dlon = 0.5
dlat = 0.5

varout_3d = ['u', 'v', 'w', 'tk', 'z', 'qv', 'dbz']
varout_2d = ['topo', 'slp', 'rain', 'snow', 'max_dbz']

proj = {
'type': 'LC',
'basepoint_lon': 135.,
'basepoint_lat': 35.,
'basepoint_x': None,
'basepoint_y': None,
'LC_lat1': 30.0,
'LC_lat2': 40.0
}
extrap = True

topofile = os.path.dirname(os.path.abspath(__file__)) + '/topo/topo'

stime = dt.datetime.strptime(stimestr, '%Y%m%d%H%M%S')
etime = stime
tint = dt.timedelta(hours=6)

outtype = ['gues', 'anal']
member = 0

letkfout_grads(letkfoutdir, topofile=topofile, proj=proj, stime=stime, etime=etime, tint=tint,
               outtype=outtype, member=member,
               vcoor=vcoor, hcoor=hcoor, plevels=plevels, dlon=dlon, dlat=dlat,
               varout_3d=varout_3d, varout_2d=varout_2d, extrap=extrap,
               comm=comm)
