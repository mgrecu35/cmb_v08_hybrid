module scaler_def
    TYPE scaler_2d
    real :: tc(2,150,49,13)
    real :: sfc_type(2,150,49)
    real :: sk_temp(2,150,49)
    real :: oe_wvp(2,150,49)
    real :: near_sfc_precip(2,150,49)
    real :: xenc(2,150,49,4)
    real :: xenc_prec(2,150,49,6)
    real :: xenv_enc(2,150,49,4)
    END TYPE scaler_2d
    !-----------------------------------------!
    type scaler_qv 
    real :: mean(11)
    real :: std(11)
    end type scaler_qv
end module scaler_def

module scalers
    use scaler_def
    type(scaler_2d) :: scaler_land, scaler_ocean
    type(scaler_qv) :: scaler_land_qv, scaler_ocean_qv
end module scalers
