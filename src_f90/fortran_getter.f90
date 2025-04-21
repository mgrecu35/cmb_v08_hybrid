! integer, dimension(:,:,:), pointer :: node         ! storm struct
! integer, dimension(:,:), pointer   :: rainType     ! rain type
! integer, dimension(:,:), pointer   :: BBbin        ! rain type
! real, dimension(:,:), pointer      :: freezH          ! freezingH
! integer, dimension(:,:), pointer   :: binRealSurface
! integer, dimension(:,:), pointer   :: binClutterFree
! integer, dimension(:,:), pointer   :: binZeroDegree
! real, dimension(:,:), pointer      :: localZenithAngle
! real, dimension(:,:), pointer      :: elevation


     
SUBROUTINE get_reflectivity_c_loc(zku_ptr,zka_ptr, type_ptr, node_ptr)
  use globalData
  USE ISO_C_BINDING
  REAL(C_FLOAT), POINTER :: zku_ptr(:,:,:)
  REAL(C_FLOAT), POINTER :: zka_ptr(:,:,:)
  zku_ptr => dprdata%zku1c21
  zka_ptr => dprdata%zka1c21
END SUBROUTINE get_reflectivity_c_loc

SUBROUTINE get_dprdata_c_loc(zku_ptr,zka_ptr, raintype_ptr, node_ptr, &
     binrealsurface_ptr, freezh_ptr, lon, lat)
  
  use globalData
  implicit none
  REAL :: zku_ptr(300*88*49)
  REAL :: zka_ptr(300*88*49)
  INTEGER :: raintype_ptr(300*49)
  INTEGER :: node_ptr(300*49*5)
  INTEGER :: binrealsurface_ptr(300*49)
  real :: lon(300*49), lat(300*49)
  REAL:: freezh_ptr(300*49)
  integer :: i,j,k1, ik
  real :: dummy
  print*, shape(dprdata%zku1c21)
  ik=0
  do i=1,300
     do j=1,49
        do k1=1,88
           ik=ik+1
           zku_ptr(ik) = dprdata%zku1c21(k1,j,i)
           zka_ptr(ik) = dprdata%zka1c21(k1,j,i)
        end do
     end do
  end do
  ik=0
  print*, shape(dprdata%rainType)
  do i=1,300
     do j=1,49
        ik=ik+1
        raintype_ptr(ik) = dprdata%rainType(j,i)
        lon(ik)=dprdata%xlon(j,i)
        lat(ik)=dprdata%xlat(j,i)
     end do
  end do
  ik=0
  do i=1,300
     do j=1,49
        do k1=1,5
           ik=ik+1
           node_ptr(ik) = dprdata%node(k1,j,i)
        end do
     end do
  end do

  !node_ptr => dprdata%node
  !binrealsurface_ptr => dprdata%binRealSurface
  !freezh_ptr => dprdata%freezH
END SUBROUTINE get_dprdata_c_loc
