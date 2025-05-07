module sky_scalers
type all_sky_scaler
real :: oe_wvp(2)
real :: oe_emiss(2)
real :: oe_sk_temp(2)
real :: oe_sfc_air_temp(2)
real :: oe_sfc_qv(2)
real :: oe_vapor_dens(2)
real :: oe_ws_10m(2)
end type all_sky_scaler

type(all_sky_scaler) :: all_sky_scaler_land
type(all_sky_scaler) :: all_sky_scaler_ocean
contains
  subroutine init_all_sky_scalers(all_sky_scaler_land,all_sky_scaler_ocean)
    type(all_sky_scaler) :: all_sky_scaler_land
    type(all_sky_scaler) :: all_sky_scaler_ocean
    all_sky_scaler_land%oe_wvp=(/18.192,16.716/)
    all_sky_scaler_land%oe_emiss=(/ 0.907, 0.092/)
    all_sky_scaler_land%oe_sk_temp=(/282.645,14.484/)
    all_sky_scaler_land%oe_sfc_air_temp=(/282.694,12.846/)
    all_sky_scaler_land%oe_sfc_qv=(/ 8.210, 6.834/)
    all_sky_scaler_land%oe_vapor_dens=(/ 3.316, 4.915/)
    all_sky_scaler_land%oe_ws_10m=(/ 7.824, 4.502/)
    !-------------------------------------------!
    all_sky_scaler_ocean%oe_wvp=(/21.110,19.443/)           !1
    all_sky_scaler_ocean%oe_emiss=(/ 0.620, 0.201/)         !14
    all_sky_scaler_ocean%oe_sk_temp=(/283.710,13.646/)      !15
    all_sky_scaler_ocean%oe_sfc_air_temp=(/283.395,13.393/) !16
    all_sky_scaler_ocean%oe_sfc_qv=(/12.592,11.303/)        !17
    all_sky_scaler_ocean%oe_vapor_dens=(/ 3.580, 6.081/)    !27
    all_sky_scaler_ocean%oe_ws_10m=(/ 8.818, 4.512/)        !28
end subroutine init_all_sky_scalers
end module sky_scalers
