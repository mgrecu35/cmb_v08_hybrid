import netCDF4 as nc
fname="2B.GPM.DPRGMI.CORRA2022.20230107-S023421-E040653.050333.V07A.01.HDF5"
fname="2BCMB_Output/2B.GPM.DPRGMI.20180625.024557.ITE763.HDF5"
n1,n2=4800,5100
n1,n2=1000,9000
#n1,n2=0,300
with nc.Dataset(fname) as fh:
    lon=fh['KuGMI/Longitude'][n1:n2]
    lat=fh['KuGMI/Latitude'][n1:n2]
    sfcPrecip=fh['GMI/GEestimSurfPrecipTotRate'][n1:n2]
    ge_skin_temp=fh['GMI/GEskinTemperature'][n1:n2]
    ge_w10=fh['GMI/GEtenMeterWindSpeed'][n1:n2]
    ge_sfc_qv=fh['GMI/GEsurfaceVaporDensity'][n1:n2]
    skin_temp=fh['KuKaGMI/skinTemperature'][n1:n2]
    vap_density=fh['KuKaGMI/vaporDensity'][n1:n2]
    prate3D=fh['GMI/GEprecipTotRate'][n1:n2]
    sfcPrecip_corra=fh['KuKaGMI/nearSurfPrecipTotRate'][n1:n2]


import matplotlib.pyplot as plt
import matplotlib
import cartopy.crs as ccrs
sfcPrecip[sfcPrecip<0.02]=0
plt.figure()
ax=plt.subplot(111,projection=ccrs.PlateCarree())
plt.pcolormesh(lon,lat,sfcPrecip,norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=30),cmap="jet")
ax.coastlines()

plt.figure()
ax=plt.subplot(111,projection=ccrs.PlateCarree())
plt.pcolormesh(lon,lat,ge_skin_temp,cmap="jet")
ax.coastlines()
plt.colorbar()


plt.figure()
ax=plt.subplot(111,projection=ccrs.PlateCarree())
plt.pcolormesh(lon,lat,skin_temp,cmap="jet")
ax.coastlines()
plt.colorbar()


print(sfcPrecip.sum(),sfcPrecip_corra.sum())

plt.figure()
prate3D[prate3D<0.05]=0
plt.pcolormesh(lon[:,24],range(88),prate3D[:,24,:].T,norm=matplotlib.colors.LogNorm(vmin=0.1,vmax=30),cmap="jet")
plt.ylim(87,27)
plt.show()

