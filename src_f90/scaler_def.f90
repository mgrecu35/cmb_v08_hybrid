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
! Fortran code to define a structure and read data from a file.


   TYPE  scaler_1d_data
    real :: tc_mean(13) 
    real :: tc_std(13) 
    real :: sfc_type_mean 
    real :: sfc_type_std 
    real :: sk_temp_mean 
    real :: sk_temp_std 
    real :: qv_mean 
    real :: qv_std 
    real :: oe_wvp_mean 
    real :: oe_wvp_std 
    real :: near_sfc_precip_mean 
    real :: near_sfc_precip_std 
    real :: x_enc_prec(6) 
    real :: x_enc_prec_std(6) 
  END TYPE scaler_1d_data
end module scaler_def

module scalers
    use scaler_def
    type(scaler_2d) :: scaler_land, scaler_ocean
    type(scaler_qv) :: scaler_land_qv, scaler_ocean_qv
    type(scaler_1d_data) :: scaler_1d_land, scaler_1d_ocean
end module scalers


subroutine read_scaler_1d(my_data,filename)
  USE scaler_def  ! Use the module to access the derived type.
  IMPLICIT NONE

  ! Declare a variable of the derived type.
  TYPE(scaler_1d_data) :: my_data
  CHARACTER(LEN=*) :: filename  ! Increased length for filename
  INTEGER :: i, io_status
  character(20) :: var_name
  ! Open the file.  Error handling is crucial.
  
  OPEN(UNIT=10, FILE=filename, STATUS='OLD', ACTION='READ', IOSTAT=io_status)
  IF (io_status /= 0) THEN
    WRITE( *, '(A,I0,A)' ) 'Error opening file "', io_status, '".  Exiting.'
    STOP  ! Use STOP for a more robust exit
  END IF
 
  read(10,*) var_name
  print*, var_name
  ! Read the data from the file into the structure.  Use descriptive names.
  READ(10, *, IOSTAT=io_status) my_data%tc_mean, my_data%tc_std
  IF (io_status /= 0) GOTO 20
  read(10,*) var_name
  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%sfc_type_mean, my_data%sfc_type_std
  IF (io_status /= 0) GOTO 20
  read(10,*) var_name
  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%sk_temp_mean, my_data%sk_temp_std
  IF (io_status /= 0) GOTO 20
  read(10,*) var_name
  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%qv_mean, my_data%qv_std
  IF (io_status /= 0) GOTO 20
  read(10,*) var_name
  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%oe_wvp_mean, my_data%oe_wvp_std
  IF (io_status /= 0) GOTO 20
  read(10,*) var_name
  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%near_sfc_precip_mean, my_data%near_sfc_precip_std
  IF (io_status /= 0) GOTO 20
  read(10,*) var_name
  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%x_enc_prec
  IF (io_status /= 0) GOTO 20
!  read(10,*) var_name
!  print*, var_name
  READ(10, *, IOSTAT=io_status) my_data%x_enc_prec_std ! Added read for standard deviations
  IF (io_status /= 0) GOTO 20
  print*, my_data%tc_mean, my_data%tc_std
  print*, my_data%sk_temp_mean, my_data%sk_temp_std
  print*, my_data%qv_mean, my_data%qv_std
  
  CLOSE(10)

  

  
  ! Exit normally.
  GO TO 30
  
20 continue
  WRITE( *, '(A,I0,A)' ) 'Error reading from file.  IOSTAT = ', io_status, '.'
  CLOSE(10)
  
30 continue
  WRITE(*,*) "Program completed."
END subroutine read_scaler_1d

 
