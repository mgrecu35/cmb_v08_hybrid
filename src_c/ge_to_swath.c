
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "TKheaders.h"
#include "TK_2BCMB.h"
#ifdef GFOR 
extern int __nbinmod_MOD_imemb;
#define nbins __nbinmod_MOD_imemb
//begin  WSO 9/15/13 
extern float __missingmod_MOD_missing_r4;
#define missing_r4c __missingmod_MOD_missing_r4
extern short __missingmod_MOD_missing_i2;
#define missing_i2c __missingmod_MOD_missing_i2
extern long __missingmod_MOD_missing_i4;
#define missing_i4c __missingmod_MOD_missing_i4
extern int __nbinmod_MOD_ntransition;
#define ntransitions __nbinmod_MOD_ntransition
//end    WSO 9/15/13
#endif

#ifdef IFORT 
extern int nbinmod_mp_nbin_;
//begin  WSO 8/8/13
extern int nbinmod_mp_ntransition_;
//end    WSO 8/8/13
#define nbins nbinmod_mp_nbin_
//begin  WSO 8/8/13
#define ntransitions nbinmod_mp_ntransition_
//end    WSO 8/8/13
//begin  WSO 9/15/13
extern float missingmod_mp_missing_r4_;
#define missing_r4c missingmod_mp_missing_r4_
extern short missingmod_mp_missing_i2_;
#define missing_i2c missingmod_mp_missing_i2_
extern long  missingmod_mp_missing_i4_;
#define missing_i4c missingmod_mp_missing_i4_
//end    WSO 9/15/13
#endif

//begin WSO 04/07/2013
//Note that there were many structure/variable name changes in this
//version to be compatible with TKIO 3.50.8
//All S1 and S2 were changed to NS and MS, respectively
//The variable ending "Out" was removed because a separate Input structure
//was created
//end WSO 04/07/2013

extern TKINFO dprtkfile;
TKINFO ctkfile;
TKINFO ctkfileIn;

L2BCMB_SWATHS swath;
L2ADPR_SWATHS_7h0 dprswath;
L2ADPR_SWATHS_7h0 dprxswath;
L2BCMB_SWATHS swath1;
L2AKu_FS_7g0     L2AKuDataX;

void copy_geairtemperature_(float *GEairTemperature, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEairTemperature[*i][k]=GEairTemperature[k];
    }
}

void copy_gevapordensity_(float *GEvaporDensity, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEvaporDensity[*i][k]=GEvaporDensity[k];
    }
}

void copy_gecloudliqwatercont_(float *GEcloudLiqWaterCont, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEcloudLiqWaterCont[*i][k]=GEcloudLiqWaterCont[k];
    }
}

void copy_gesurfemissivity_(float *GEsurfEmissivity, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEsurfEmissivity[*i][k]=GEsurfEmissivity[k];
    }
}

void copy_gepreciptotwatercont_(float *GEprecipTotWaterCont, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEprecipTotWaterCont[*i][k]=GEprecipTotWaterCont[k];
    }
}

void copy_gepreciptotwatercontsigma_(float *GEprecipTotWaterContSigma, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEprecipTotWaterContSigma[*i][k]=GEprecipTotWaterContSigma[k];
    }
}

void copy_geprecipliqwatercont_(float *GEprecipLiqWaterCont, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEprecipLiqWaterCont[*i][k]=GEprecipLiqWaterCont[k];
    }
}

void copy_gepreciptotrate_(float *GEprecipTotRate, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEprecipTotRate[*i][k]=GEprecipTotRate[k];
    }
}

void copy_gepreciptotratesigma_(float *GEprecipTotRateSigma, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEprecipTotRateSigma[*i][k]=GEprecipTotRateSigma[k];
    }
}

void copy_geprecipliqrate_(float *GEprecipLiqRate, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEprecipLiqRate[*i][k]=GEprecipLiqRate[k];
    }
}

void copy_gepia_(float *GEpia, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEpia[*i][k]=GEpia[k];
    }
}

void copy_gesimulatedbrighttemp_(float *GEsimulatedBrightTemp, int *i, int *nbin)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  for(k=0;k<*nbin;k++)
    {
      swathx.GMI.GEsimulatedBrightTemp[*i][k]=GEsimulatedBrightTemp[k];
    }
}


void copy_gecolumnwatervapor_(float *GEcolumnWaterVapor, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEcolumnWaterVapor[*i]=*GEcolumnWaterVapor;
}

void copy_gecolumncloudliqwater_(float *GEcolumnCloudLiqWater, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEcolumnCloudLiqWater[*i]=*GEcolumnCloudLiqWater;
}

void copy_geskintemperature_(float *GEskinTemperature, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEskinTemperature[*i]=*GEskinTemperature;
}

void copy_gesurfaceairtemperature_(float *GEsurfaceAirTemperature, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEsurfaceAirTemperature[*i]=*GEsurfaceAirTemperature;
}

void copy_gesurfacevapordensity_(float *GEsurfaceVaporDensity, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEsurfaceVaporDensity[*i]=*GEsurfaceVaporDensity;
}

void copy_getenmeterwindspeed_(float *GEtenMeterWindSpeed, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEtenMeterWindSpeed[*i]=*GEtenMeterWindSpeed;
}

void copy_geestimsurfpreciptotrate_(float *GEestimSurfPrecipTotRate, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEestimSurfPrecipTotRate[*i]=*GEestimSurfPrecipTotRate;
}

void copy_geestimsurfpreciptotratesigma_(float *GEestimSurfPrecipTotRateSigma, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEestimSurfPrecipTotRateSigma[*i]=*GEestimSurfPrecipTotRateSigma;
}

void copy_geestimsurfprecipliqrate_(float *GEestimSurfPrecipLiqRate, int *i)
{
  int k;
  extern L2BCMB_SWATHS swathx;
  
  swathx.GMI.GEestimSurfPrecipLiqRate[*i]=*GEestimSurfPrecipLiqRate;
}
