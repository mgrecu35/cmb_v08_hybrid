path="/Users/mgrecu/GPM/ROSES2024/Data/"
import glob
fgmi=glob.glob(path+"1C*GMI*.HDF5")
fcmb=glob.glob(path+"2B.GPM*CORRA*ITE*.HDF5")
print(fgmi)
print(fcmb)
import netCDF4 as nc
with nc.Dataset(fgmi[0]) as f:
    lat_gmi_S1=f['S1/Latitude'][:]
    lon_gmi_S1=f['S1/Longitude'][:]
    tc_gmi_S1=f['S1/Tc'][:]
    lat_gmi_S2=f['S2/Latitude'][:]
    lon_gmi_S2=f['S2/Longitude'][:]
    tc_gmi_S2=f['S2/Tc'][:]

with nc.Dataset(fcmb[0]) as f:
    lat=f['KuKaGMI/Latitude'][:]
    lon=f['KuKaGMI/Longitude'][:]
    surf_type=f['KuKaGMI/Input/surfaceType'][:]
    qv=f['KuKaGMI/vaporDensity'][:]
    sk_temp=f['KuKaGMI/skinTemperature'][:]
    oe_wvp=f['KuKaGMI/OptEst/OEcolumnWaterVapor'][:]
    near_sfc_precip=f['KuKaGMI/nearSurfPrecipTotRate'][:]

print(lon.shape)
import numpy as np

import tb_resample 
tc_s1_resampled = tb_resample.grid_tb(tc_gmi_S1,lon_gmi_S1,lat_gmi_S1,lon,lat)
tc_s2_resampled = tb_resample.grid_tb(tc_gmi_S2,lon_gmi_S2,lat_gmi_S2,lon,lat)
tb_resampled = np.concatenate((tc_s1_resampled,tc_s2_resampled),axis=-1)
#tc_resampled = grid_tb(tc_gmi_s1,lon_s1,lat_s1,lon,lat)
import os
import sys
sys.path.append('/Users/mgrecu/PMMCCST/onnxruntime-osx-arm64-1.20.1/lib/')
os.environ['DYLD_LIBRARY_PATH'] = '/Users/mgrecu/PMMCCST/onnxruntime-osx-arm64-1.20.1/lib/'
os.environ['DYLD_LIBRARY_PATH'] = '/Users/mgrecu/PMMCCST/onnxruntime-osx-arm64-1.20.1/lib/'

print(os.environ['DYLD_LIBRARY_PATH'])

import onnx_f90
print(dir(onnx_f90))
onnx_f90.read_scaler_data()
onnx_f90.init_onnx()
nfeat_in=19
nfeat_out=8
#surf_type=f['KuKaGMI/Input/surfaceType'][:]
#qv=f['KuKaGMI/vaporDensity'][:]
#sk_temp=f['KuKaGMI/skinTemperature'][:]
n1=4800
n2=5100
print(tb_resampled[n1:n2].shape)
print(surf_type[n1:n2].T.shape)
print(sk_temp[n1:n2].T.shape)
print(qv[n1:n2].T.shape)

x_output_f, xoutput_profs = onnx_f90.test_model_1d_onnx(tb_resampled[n1:n2],surf_type[n1:n2].T,sk_temp[n1:n2].T,qv[n1:n2].T,nfeat_in,nfeat_out)

import matplotlib.pyplot as plt
import matplotlib
import cartopy.crs as ccrs

plt.figure(figsize=(10,10))
n1=4800
n2=5100
ax=plt.subplot(1,1,1,projection=ccrs.PlateCarree())
x_output_f[1,:,:][x_output_f[1,:,:]<0.1]=0.0
plt.pcolormesh(lon[n1:n2,:],lat[n1:n2,:],x_output_f[1,:,:].T,cmap='jet',norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=100))
ax.coastlines()

plt.figure()
xoutput_profs[xoutput_profs<0.1]=0.0
plt.pcolormesh(lon[n1:n2,24],range(88),xoutput_profs[:,24,:].T,cmap='jet',norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=100))
plt.ylim(87,20)
plt.colorbar()
