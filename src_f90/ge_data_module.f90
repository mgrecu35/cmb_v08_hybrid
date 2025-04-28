module GE_module
  type :: ge_data_type
    integer :: nscan, nray, nBnEnv,nBnPSD, nemiss
   real, dimension(: ,: ,: ), pointer :: GEairTemperature 
   real, dimension(: ,: ,: ), pointer :: GEvaporDensity 
   real, dimension(: ,: ), pointer :: GEcolumnWaterVapor 
   real, dimension(: ,: ,: ), pointer :: GEcloudLiqWaterCont 
   real, dimension(: ,: ), pointer :: GEcolumnCloudLiqWater 
   real, dimension(: ,: ), pointer :: GEskinTemperature 
   real, dimension(: ,: ), pointer :: GEsurfaceAirTemperature 
   real, dimension(: ,: ), pointer :: GEsurfaceVaporDensity 
   real, dimension(: ,: ), pointer :: GEtenMeterWindSpeed 
   real, dimension(: ,: ,: ), pointer :: GEsurfEmissivity 
   real, dimension(: ,: ,: ), pointer :: GEprecipTotWaterCont 
   real, dimension(: ,: ,: ), pointer :: GEprecipTotWaterContSigma 
   real, dimension(: ,: ,: ), pointer :: GEprecipLiqWaterCont 
   real, dimension(: ,: ,: ), pointer :: GEprecipTotRate 
   real, dimension(: ,: ,: ), pointer :: GEprecipTotRateSigma 
   real, dimension(: ,: ,: ), pointer :: GEprecipLiqRate 
   real, dimension(: ,: ), pointer :: GEestimSurfPrecipTotRate 
   real, dimension(: ,: ), pointer :: GEestimSurfPrecipTotRateSigma 
   real, dimension(: ,: ), pointer :: GEestimSurfPrecipLiqRate 
   real, dimension(: ,: ,: ), pointer :: GEpia 
   real, dimension(: ,: ,: ), pointer :: GEsimulatedBrightTemp 
  
  end type ge_data_type
end module GE_module
subroutine allocate_ge_data(this, nscan, nray, nBnEnv, nBnPSD, nemiss)
    use GE_module
    type(ge_data_type) :: this
    this%nscan = nscan
    this%nray = nray
    this%nBnEnv = nBnEnv
    this%nBnPSD = nBnPSD
    this%nemiss = nemiss
    allocate(this%GEairTemperature(nscan, nray, nBnEnv)) 
    allocate(this%GEvaporDensity(nscan, nray, nBnEnv)) 
    allocate(this%GEcolumnWaterVapor(nscan, nray)) 
    allocate(this%GEcloudLiqWaterCont(nscan, nray, nBnPSD)) 
    allocate(this%GEcolumnCloudLiqWater(nscan, nray)) 
    allocate(this%GEskinTemperature(nscan, nray)) 
    allocate(this%GEsurfaceAirTemperature(nscan, nray)) 
    allocate(this%GEsurfaceVaporDensity(nscan, nray)) 
    allocate(this%GEtenMeterWindSpeed(nscan, nray)) 
    allocate(this%GEsurfEmissivity(nscan, nray, nemiss)) 
    allocate(this%GEprecipTotWaterCont(nscan, nray, nBnPSD)) 
    allocate(this%GEprecipTotWaterContSigma(nscan, nray, nBnPSD)) 
    allocate(this%GEprecipLiqWaterCont(nscan, nray, nBnPSD)) 
    allocate(this%GEprecipTotRate(nscan, nray, nBnPSD)) 
    allocate(this%GEprecipTotRateSigma(nscan, nray, nBnPSD)) 
    allocate(this%GEprecipLiqRate(nscan, nray, nBnPSD)) 
    allocate(this%GEestimSurfPrecipTotRate(nscan, nray)) 
    allocate(this%GEestimSurfPrecipTotRateSigma(nscan, nray)) 
    allocate(this%GEestimSurfPrecipLiqRate(nscan, nray)) 
    allocate(this%GEpia(nscan, nray, nKuKa)) 
    allocate(this%GEsimulatedBrightTemp(nscan, nray, nemiss)) 
    
end subroutine allocate_ge_data