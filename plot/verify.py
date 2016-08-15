import numpy as np
import numpy.ma as ma
from numpy.ma import masked
import datetime as dt
import gradsio
import sys
#import os


#stimestr = sys.argv[1]
#etimestr = sys.argv[2]
#letkfoutdir = sys.argv[1]

#stime = dt.datetime.strptime(stimestr, '%Y%m%d%H%M%S')
#etime = dt.datetime.strptime(etimestr, '%Y%m%d%H%M%S')


letkfoutdir = "/data7/gylien/realtime/exp/ctl_d1"
gfsdir = '/data7/gylien/realtime/ncepgfs'
stime = dt.datetime(2016,  6, 22, 18,  0,  0)
etime = dt.datetime(2016,  6, 22, 18,  0,  0)
ave_cycle = 28


tint = dt.timedelta(hours=6)


plevels = [100000., 92500., 85000., 70000., 50000., 30000., 20000., 10000., 5000., 2000., 1000., 500.]
plevels_gfs = [100000., 92500., 85000., 70000., 50000., 30000., 20000., 10000., 5000., 2000., 1000.]

var_3d = ['u', 'v', 'w', 'tk', 'z', 'qv', 'rh', 'dbz']
var_2d = ['topo', 'u10', 'v10', 't2', 'q2', 'slp', 'rain', 'snow', 'max_dbz', 'olr', 'tsfc', 'sst']

var_3d_gfs = ['u', 'v', 'tk', 'z', 'rh']
var_2d_gfs = ['u10', 'v10', 't2', 'slp']

var_3d_idx = [0, 1, 3, 4, 6]
var_3d_gfs_idx = [0, 1, 2, 3, 4]

var_2d_idx = [1, 2, 3, 5]
var_2d_gfs_idx = [0, 1, 2, 3]

missing = np.float32(-9.99e33)

nv3d = len(var_3d)
nv2d = len(var_2d)
nv3d_gfs = len(var_3d_gfs)
nv2d_gfs = len(var_2d_gfs)
nv3do = len(var_3d_idx)
nv2do = len(var_2d_idx)

nt = 21

lon_s = 95.5
lon_e = 174.5
lat_s = 12.5
lat_e = 54.5
lon_int = 0.5
lat_int = 0.5

lono1d = np.arange(lon_s, lon_e+1.e-6, lon_int)
lato1d = np.arange(lat_s, lat_e+1.e-6, lat_int)
nx = len(lono1d)
ny = len(lato1d)
nz = len(plevels)
nz_gfs = len(plevels_gfs)
nzo = nz_gfs


lons = np.arange(lon_s, lon_e+1.e-3, lon_int)
lats = np.arange(lat_s, lat_e+1.e-3, lat_int)
lons_m, lats_m = np.meshgrid(lons, lats)
lats_m_cos = np.cos(np.radians(lats_m)).reshape(ny*nx)

X3d = ma.masked_all((nt, nv3do, nzo, ny, nx), dtype='f4')
X2d = ma.masked_all((nt, nv2do, ny, nx), dtype='f4')
X3d_gfs = ma.masked_all((nt, nv3do, nzo, ny, nx), dtype='f4')
X2d_gfs = ma.masked_all((nt, nv2do, ny, nx), dtype='f4')

X3d_bias = ma.zeros((nt, nv3do, nzo, ny, nx), dtype='f4')
X2d_bias = ma.zeros((nt, nv2do, ny, nx), dtype='f4')
X3d_rmse = ma.zeros((nt, nv3do, nzo, ny, nx), dtype='f4')
X2d_rmse = ma.zeros((nt, nv2do, ny, nx), dtype='f4')

X3d_h_bias = ma.zeros((nt, nv3do, nzo), dtype='f4')
X2d_h_bias = ma.zeros((nt, nv2do), dtype='f4')
X3d_h_rmse = ma.zeros((nt, nv3do, nzo), dtype='f4')
X2d_h_rmse = ma.zeros((nt, nv2do), dtype='f4')


#nta = 0
#time = stime
#while time <= etime:
#    time += tint
#    nta += 1
#print('nta =', nta)

time = stime
while time <= etime:
    timef = time.strftime('%Y%m%d%H%M%S')
    timef2 = time.strftime('%Y-%m-%d %H:%M:%S')
    timef3 = time.strftime('%Y%m%d%H')


#    fb = open('bias_h_tevol_{:s}_{:s}.grd'.format(stime.strftime('%Y%m%d%H%M%S'), etime.strftime('%Y%m%d%H%M%S')), 'wb')
#    fe = open('rmse_h_tevol_{:s}_{:s}.grd'.format(stime.strftime('%Y%m%d%H%M%S'), etime.strftime('%Y%m%d%H%M%S')), 'wb')


ita = 0
time = stime
while time <= etime:
    timef = time.strftime('%Y%m%d%H%M%S')
    timef2 = time.strftime('%Y-%m-%d %H:%M:%S')
    timef3 = time.strftime('%Y%m%d%H')

    print(timef2)


    f = open('{:s}/{:s}/fcstgpll/mean.grd'.format(letkfoutdir, timef), 'rb')
    for it in range(nt):
        for iv in range(nv3do):
            X3d[it,iv,:,:,:] = ma.masked_values(gradsio.readgrads(f, var_3d_idx[iv]+1, nv3d=nv3d, nv2d=nv2d, t=it+1, nx=nx, ny=ny, nz=nz, nt=nt, endian='<')[0:nzo], missing)
            if ma.min(X3d[it,iv,:,:,:]) == ma.max(X3d[it,iv,:,:,:]):
                raise ValueError('Wrong data:', timef, var_3d[var_3d_idx[iv]], 'constant', ma.min(X3d[it,iv,:,:,:]))
        for iv in range(nv2do):
            X2d[it,iv,:,:] = ma.masked_values(gradsio.readgrads(f, nv3d+var_2d_idx[iv]+1, nv3d=nv3d, nv2d=nv2d, t=it+1, nx=nx, ny=ny, nz=nz, nt=nt, endian='<'), missing)
            if ma.min(X2d[it,iv,:,:]) == ma.max(X2d[it,iv,:,:]):
                raise ValueError('Wrong data:', timef, var_2d[var_2d_idx[iv]], 'constant', ma.min(X2d[it,iv,:,:]))
    f.close()

    for it in range(nt):
        time_a = time + tint * it
        f = open('{:s}/{:s}/gfs.{:s}.grd'.format(gfsdir, time_a.strftime('%Y%m%d%H'), time_a.strftime('%Y%m%d%H%M%S')), 'rb')
        for iv in range(nv3do):
            X3d_gfs[it,iv,:,:,:] = ma.masked_values(gradsio.readgrads(f, var_3d_gfs_idx[iv]+1, nv3d=nv3d_gfs, nv2d=nv2d_gfs, nx=nx, ny=ny, nz=nz_gfs, endian='<')[0:nzo], missing)
        for iv in range(nv2do):
            X2d_gfs[it,iv,:,:] = ma.masked_values(gradsio.readgrads(f, nv3d_gfs+var_2d_gfs_idx[iv]+1, nv3d=nv3d_gfs, nv2d=nv2d_gfs, nx=nx, ny=ny, nz=nz_gfs, endian='<'), missing)
        f.close()

    X3d -= X3d_gfs
    X2d -= X2d_gfs



    X3d_xy = X3d.reshape(nt, nv3do, nzo, ny*nx)
    i_X3d_h_bias = ma.average(X3d_xy, axis=3, weights=lats_m_cos)
    i_X3d_h_rmse = ma.power(ma.average(X3d_xy*X3d_xy, axis=3, weights=lats_m_cos), 0.5)

    X2d_xy = X2d.reshape(nt, nv2do, ny*nx)
    i_X2d_h_bias = ma.average(X2d_xy, axis=2, weights=lats_m_cos)
    i_X2d_h_rmse = ma.power(ma.average(X2d_xy*X2d_xy, axis=2, weights=lats_m_cos), 0.5)

    for it in range(nt):
        for iv in range(nv3do):
            gradsio.writegrads(fb, ma.filled(i_X3d_h_bias[it,iv,:].reshape(nzo,1,1), fill_value=missing), iv+1, nv3d=nv3do, nv2d=nv2do, t=ita+1, e=it+1, nz=nzo, nt=nta, ne=nt, endian='<')
        for iv in range(nv2do):
            if i_X2d_h_bias[it,iv] is masked:
                gradsio.writegrads(fb, np.array([[missing]]), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=ita+1, e=it+1, nz=nzo, nt=nta, ne=nt, endian='<')
            else:
                gradsio.writegrads(fb, ma.filled(i_X2d_h_bias[it,iv].reshape(1,1), fill_value=missing), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=ita+1, e=it+1, nz=nzo, nt=nta, ne=nt, endian='<')
        for iv in range(nv3do):
            gradsio.writegrads(fe, ma.filled(i_X3d_h_rmse[it,iv,:].reshape(nzo,1,1), fill_value=missing), iv+1, nv3d=nv3do, nv2d=nv2do, t=ita+1, e=it+1, nz=nzo, nt=nta, ne=nt, endian='<')
        for iv in range(nv2do):
            if i_X2d_h_rmse[it,iv] is masked:
                gradsio.writegrads(fe, np.array([[missing]]), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=ita+1, e=it+1, nz=nzo, nt=nta, ne=nt, endian='<')
            else:
                gradsio.writegrads(fe, ma.filled(i_X2d_h_rmse[it,iv].reshape(1,1), fill_value=missing), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=ita+1, e=it+1, nz=nzo, nt=nta, ne=nt, endian='<')



    X3d_bias += X3d
    X2d_bias += X2d
    X3d_rmse += X3d * X3d
    X2d_rmse += X2d * X2d

    X3d_h_bias += i_X3d_h_bias
    X2d_h_bias += i_X2d_h_bias
    X3d_h_rmse += i_X3d_h_rmse
    X2d_h_rmse += i_X2d_h_rmse

    time += tint
    ita += 1


fb.close()
fe.close()


X3d_bias /= nta
X2d_bias /= nta
X3d_rmse = np.sqrt(X3d_rmse / nta)
X2d_rmse = np.sqrt(X2d_rmse / nta)

X3d_h_bias /= nta
X2d_h_bias /= nta
X3d_h_rmse /= nta
X2d_h_rmse /= nta

f = open('bias_{:s}_{:s}.grd'.format(stime.strftime('%Y%m%d%H%M%S'), etime.strftime('%Y%m%d%H%M%S')), 'wb')
for it in range(nt):
    for iv in range(nv3do):
        gradsio.writegrads(f, ma.filled(X3d_bias[it,iv,:,:,:], fill_value=missing), iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nx=nx, ny=ny, nz=nzo, nt=nt, endian='<')
    for iv in range(nv2do):
        gradsio.writegrads(f, ma.filled(X2d_bias[it,iv,:,:], fill_value=missing), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nx=nx, ny=ny, nz=nzo, nt=nt, endian='<')
f.close()

f = open('rmse_{:s}_{:s}.grd'.format(stime.strftime('%Y%m%d%H%M%S'), etime.strftime('%Y%m%d%H%M%S')), 'wb')
for it in range(nt):
    for iv in range(nv3do):
        gradsio.writegrads(f, ma.filled(X3d_rmse[it,iv,:,:,:], fill_value=missing), iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nx=nx, ny=ny, nz=nzo, nt=nt, endian='<')
    for iv in range(nv2do):
        gradsio.writegrads(f, ma.filled(X2d_rmse[it,iv,:,:], fill_value=missing), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nx=nx, ny=ny, nz=nzo, nt=nt, endian='<')
f.close()


f = open('bias_h_{:s}_{:s}.grd'.format(stime.strftime('%Y%m%d%H%M%S'), etime.strftime('%Y%m%d%H%M%S')), 'wb')
for it in range(nt):
    for iv in range(nv3do):
        gradsio.writegrads(f, ma.filled(X3d_h_bias[it,iv,:].reshape(nzo,1,1), fill_value=missing), iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nz=nzo, nt=nt, endian='<')
    for iv in range(nv2do):
        if X2d_h_bias[it,iv] is masked:
            gradsio.writegrads(f, np.array([[missing]]), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nz=nzo, nt=nt, endian='<')
        else:
            gradsio.writegrads(f, ma.filled(X2d_h_bias[it,iv].reshape(1,1), fill_value=missing), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nz=nzo, nt=nt, endian='<')
f.close()

f = open('rmse_h_{:s}_{:s}.grd'.format(stime.strftime('%Y%m%d%H%M%S'), etime.strftime('%Y%m%d%H%M%S')), 'wb')
for it in range(nt):
    for iv in range(nv3do):
        gradsio.writegrads(f, ma.filled(X3d_h_rmse[it,iv,:].reshape(nzo,1,1), fill_value=missing), iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nz=nzo, nt=nt, endian='<')
    for iv in range(nv2do):
        if X2d_h_rmse[it,iv] is masked:
            gradsio.writegrads(f, np.array([[missing]]), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nz=nzo, nt=nt, endian='<')
        else:
            gradsio.writegrads(f, ma.filled(X2d_h_rmse[it,iv].reshape(1,1), fill_value=missing), nv3do+iv+1, nv3d=nv3do, nv2d=nv2do, t=it+1, nz=nzo, nt=nt, endian='<')
f.close()

