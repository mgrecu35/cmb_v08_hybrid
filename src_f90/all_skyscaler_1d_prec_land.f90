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
type(all_sky_scaler) :: all_sky_scaler_land
all_sky_scaler_land%oe_wvp(2)=(/22.114,15.739/)
all_sky_scaler_land%oe_emiss(2)=(/ 0.894, 0.108/)
all_sky_scaler_land%oe_sk_temp(2)=(/287.867,12.579/)
all_sky_scaler_land%oe_sfc_air_temp(2)=(/286.603,11.042/)
all_sky_scaler_land%oe_sfc_qv(2)=(/ 9.608, 6.901/)
all_sky_scaler_land%oe_vapor_dens(2)=(/ 3.657, 4.988/)
all_sky_scaler_land%oe_ws_10m(2)=(/ 8.410, 5.227/)
all_sky_scaler_land%oe_air_temp(2)=(/255.384,29.159/)
end module sky_scalers
