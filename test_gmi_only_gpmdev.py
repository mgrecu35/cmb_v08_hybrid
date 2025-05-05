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
    srf_bin=f['KuKaGMI/Input/surfaceRangeBin'][:,:,0]
    qv=f['KuKaGMI/vaporDensity'][:]
    sk_temp=f['KuKaGMI/skinTemperature'][:]
    oe_wvp=f['KuKaGMI/OptEst/OEcolumnWaterVapor'][:]
    near_sfc_precip=f['KuKaGMI/nearSurfPrecipTotRate'][:]
    pRate=f['KuKaGMI/precipTotRate'][:]

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
for i in range(n1,n2):
    for j in range(49):
        if surf_type[i,j] == 0:
            xoutput_profs[i-n1,j,84:srf_bin[i,j]]=xoutput_profs[i-n1,j,83]
        else:
            xoutput_profs[i-n1,j,82:srf_bin[i,j]]=xoutput_profs[i-n1,j,81]
import matplotlib.pyplot as plt
import matplotlib
import cartopy.crs as ccrs

n_scans=near_sfc_precip.shape[0]
import precip_align as pal

#w1=np.random.randn(9,49)
#w2=0.6*w1+0.4*np.random.randn(9,49)
#corr_coeff=np.corrcoef(w1.flatten(),w2.flatten())[0,1]
#corr_coeff_f90=pal.calc_correlation(w1,w2)
#print(corr_coeff,corr_coeff_f90)
#precip_gmi_only_shifted = pal.align_precip(precip_gmi_only,precip_corra)
for i in range(0,n_scans,300):
    n1i=i
    n2i=i+300
    print(n1i,n2i)
    x_output_fi, xoutput_profsi = onnx_f90.test_model_1d_onnx(tb_resampled[n1i:n2i],surf_type[n1i:n2i].T,sk_temp[n1i:n2i].T,qv[n1i:n2i].T,nfeat_in,nfeat_out)
    precip_corra=near_sfc_precip[n1i:n2i,:]
    precip_gmi_only=x_output_fi[1,:,:].T
    precip_gmi_only_shifted = pal.align_precip(precip_gmi_only,precip_corra)
    cc1=np.corrcoef(near_sfc_precip[n1i:n2i,:].flatten(),x_output_fi[1,:,:].T.flatten())
    cc2=np.corrcoef(precip_gmi_only_shifted.flatten(),x_output_fi[1,:,:].T.flatten())
    print(cc1[0,1],cc2[0,1])
stop
plt.figure(figsize=(8,6))
n1=4800
n2=5100
ax=plt.subplot(1,2,1,projection=ccrs.PlateCarree())
# plot states and coastlines
x_output_f[1,:,:][x_output_f[1,:,:]<0.05]=0.0
plt.pcolormesh(lon[n1:n2,:],lat[n1:n2,:],x_output_f[1,:,:].T,cmap='jet',norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=100))
ax.coastlines()
import cartopy.feature as cfeature

# Add US states to the plot
ax.add_feature(cfeature.STATES, edgecolor='black', linewidth=0.5)
plt.title("GMI-only surface precipitation")
plt.colorbar(orientation='horizontal',pad=0.05,shrink=0.8)
ax=plt.subplot(1,2,2,projection=ccrs.PlateCarree())
plt.pcolormesh(lon[n1:n2,:],lat[n1:n2,:],near_sfc_precip[n1:n2,:] ,cmap='jet',norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=100))
ax.add_feature(cfeature.STATES, edgecolor='black', linewidth=0.5)
ax.coastlines()
plt.title("CORRA V07 surface precipitation")
plt.colorbar(orientation='horizontal',pad=0.05,shrink=0.8)
plt.tight_layout()
plt.savefig("GMI_only_precip_surface_map.png",dpi=300)

plt.figure(figsize=(8,6))
ax1=plt.subplot(2,1,1)
xoutput_profs[xoutput_profs<0.05]=0.0
plt.pcolormesh(lon[n1:n2,24],range(88),xoutput_profs[:,24,:].T,cmap='jet',norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=100))
plt.ylim(87,20)
plt.ylabel("Range bin")
ax1.xaxis.set_visible(False)
plt.colorbar()
plt.title("GMI-only precipitation")
plt.subplot(2,1,2)
plt.pcolormesh(lon[n1:n2,24],range(88),pRate[n1:n2,24,:].T,cmap='jet',norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=100))
plt.ylim(87,20)
plt.xlabel("Longitude")
plt.ylabel("Range bin")
plt.colorbar()
plt.title("CORRA V07 precipitation")
plt.tight_layout()
plt.savefig("GMI_only_precip_cross_section.png",dpi=300)
