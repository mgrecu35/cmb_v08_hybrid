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
type (scaler_2d) :: scaler
character(100) :: fname,bin_fname
fname='GMI_ONNX_Models/norm_param_150_land.npz'
bin_fname='GMI_ONNX_Models/norm_param_150_land.bin'
call get_norm_param(scaler%tc,scaler%sfc_type,scaler%sk_temp,scaler%oe_wvp,scaler%near_sfc_precip,scaler%xenc,scaler%xenc_prec,scaler%xenv_enc,fname)
open(10,file=bin_fname,form='unformatted',status='unknown')
write(10)scaler%tc
write(10)scaler%sfc_type
write(10)scaler%sk_temp
write(10)scaler%oe_wvp
write(10)scaler%near_sfc_precip
write(10)scaler%xenc
write(10)scaler%xenc_prec
write(10)scaler%xenv_enc
close(10)