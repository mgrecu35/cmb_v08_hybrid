module sky_scalers
type all_sky_scaler
real :: oe_wvp(2)
real :: oe_emiss(2)
real :: oe_sk_temp(2)
real :: oe_sfc_air_temp(2)
real :: oe_sfc_qv(2)
real :: oe_vapor_dens(2)
real :: oe_ws_10m(2)
real :: oe_air_temp(2)
end all_sky_scaler
type(all_sky_scaler) :: all_sky_scaler_ocean
all_sky_scaler_ocean%oe_wvp(2)=(/24.797,21.506/)
all_sky_scaler_ocean%oe_emiss(2)=(/ 0.632, 0.200/)
all_sky_scaler_ocean%oe_sk_temp(2)=(/283.220,14.170/)
all_sky_scaler_ocean%oe_sfc_air_temp(2)=(/283.055,13.520/)
all_sky_scaler_ocean%oe_sfc_qv(2)=(/12.551,10.815/)
all_sky_scaler_ocean%oe_vapor_dens(2)=(/ 3.761, 6.090/)
all_sky_scaler_ocean%oe_ws_10m(2)=(/10.720, 6.249/)
all_sky_scaler_ocean%oe_air_temp(2)=(/250.492,30.270/)
end module sky_scalers
