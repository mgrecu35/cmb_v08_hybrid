program test
use iso_c_binding
real :: cqv_mean(11), cqv_std(11)
integer(kind=c_int) :: n1
character(len=*), parameter :: fname_land= "GMI-models/scaler_land_qv.npz"
character(len=*), parameter :: fname_ocean= "GMI-models/scaler_ocean_qv.npz"
print*, fname
n1=11
call npz_interface_qv(cqv_mean,cqv_std,n1,fname_land)
print*, cqv_mean
print*, n1
!save cqv_mean, cqv_std in binary file
open(10,file="GMI-models/scaler_land_qv.bin",form="unformatted",status="replace")
write(10) cqv_mean
write(10) cqv_std
print*, cqv_mean
print*, cqv_std
close(10)
call npz_interface_qv(cqv_mean,cqv_std,n1,fname_ocean)
print*, cqv_mean
print*, n1
!save cqv_mean, cqv_std in binary file
open(10,file="GMI-models/scaler_ocean_qv.bin",form="unformatted",status="replace")
write(10) cqv_mean  
write(10) cqv_std
print*, cqv_mean
print*, cqv_std
close(10)
end program test
