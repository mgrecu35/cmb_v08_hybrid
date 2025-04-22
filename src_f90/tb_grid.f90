subroutine grid_chunk_tb(istart, iend, nfov, nch, gmi_lon_orig, gmi_lat_orig, tc_orig, &
    ndpr, nray, lon_dpr, lat_dpr, tb_resampled)
    implicit none
    integer :: istart, iend, nch, nfov, ndpr, nray
    real :: gmi_lon_orig(nfov,iend+1-istart), gmi_lat_orig(nfov,iend+1-istart)
    real :: tc_orig(nch,nfov,iend+1-istart)
    real :: tb_resampled(ndpr,nray, nch)
    real :: gmi_lon_trans(iend+1-istart,nfov),gmi_lat_trans(iend+1-istart,nfov)
    real :: tc_trans(iend+1-istart,nfov,nch)
    real :: lon_dpr(nray,ndpr), lat_dpr(nray,ndpr)
    real :: lon_dpr_trans(ndpr,nray), lat_dpr_trans(ndpr,nray)
    integer :: i, j, k, nlon, nlat, ngmi
    ngmi=iend+1-istart
    do i=1,iend+1-istart
        do j=1,nfov
            gmi_lat_trans(i,j)=gmi_lat_orig(j,i)
            gmi_lon_trans(i,j)=gmi_lon_orig(j,i)
            do k=1,nch
                tc_trans(i,j,k)=tc_orig(k,j,i)
            end do
        end do
    end do
    ! transpose the lon_dpr and lat_dpr arrays
    do i=1,ndpr
        do j=1,nray
            lon_dpr_trans(i,j)=lon_dpr(j,i)
            lat_dpr_trans(i,j)=lat_dpr(j,i)
        end do
     end do
     print*, ndpr, nray, ngmi, nfov, nch
     call grid_tb(tc_trans, gmi_lon_trans, gmi_lat_trans, lon_dpr_trans, lat_dpr_trans, &
        tb_resampled,ndpr, nray, ngmi, nfov, nch)
end subroutine grid_chunk_tb

subroutine grid_tb(tc_gmi_S1, lon_S1, lat_S1, lon, lat, &
    tc_resampled,ndpr, nray, ngmi, nfov, nchan)
    !use linear_interpolation_module
    use kdtree
    use iso_fortran_env, only: real64
    implicit none
    integer :: ndpr, nray, ngmi, nfov, nchan
    real :: tc_gmi_S1(ngmi,nfov,nchan), lon_S1(ngmi,nfov), lat_S1(ngmi,nfov)
    real :: lon(ndpr,nray), lat(ndpr,nray)
    real(kind=real64) :: gmi_lon_lat_points(2,ngmi*nfov)
    real(kind=real64) :: dpr_lon_lat_points(2,ndpr*nray)
    real :: tc_resampled(ndpr,nray,nchan)
    integer :: closest_points(ndpr*nray*4)
    real(kind=real64) :: dist(ndpr*nray*4)
    integer :: i, j, k, ngmi_points, ndpr_points
    integer :: iclosest(4)
    real(kind=real64) :: tc_resampled_temp(nchan)
    real(kind=real64) :: dist_temp(4)
    real :: weight, weight_sum
    type(kdtree_type) kdtree_
    integer :: ngb_idx(4), iloc, igmi, jgmi, k1
    do i=1,ngmi
        do j=1,nfov
            gmi_lon_lat_points(1,(i-1)*nfov+(j-1)+1) = lon_S1(i,j)
            gmi_lon_lat_points(2,(i-1)*nfov+(j-1)+1) = lat_S1(i,j)
        end do
    end do
    do i=1,ndpr
        do j=1,nray
            dpr_lon_lat_points(1,(i-1)*nray+(j-1)+1) = lon(i,j)
            dpr_lon_lat_points(2,(i-1)*nray+(j-1)+1) = lat(i,j)
        end do
     end do
     print*, ngmi, nfov, nray, nchan
     call kdtree_%build(gmi_lon_lat_points)
     ngmi_points=ngmi*nfov
     ndpr_points=ndpr*nray
!     return
     !call find_nearest(gmi_lon_lat_points, dpr_lon_lat_points, ngmi_points, ndpr_points, closest_points, dist)
     print*, shape(tc_resampled)
     print*, shape(tc_gmi_S1)
     do i=1,ndpr
        do j=1,nray
           iloc=(i-1)*nray+j

           call kdtree_%search(dpr_lon_lat_points(:,iloc), ngb_idx)
           print*, iloc, dpr_lon_lat_points(:,iloc), ngb_idx
           !iclosest=closest_points((i-1)*nray*4+(j-1)*4+1: (i-1)*nray*4+(j-1)*4+4)
           !dist_temp=dist((i-1)*nray*4+(j-1)*4+1: (i-1)*nray*4+(j-1)*4+4)
           !tc_resampled(i,j,:) = 0.0
           weight_sum=0
           do k=1,nchan
              tc_resampled(i,j,k) = 0.0
           end do
           do k=1,4
              igmi = ngb_idx(k)/nfov
              jgmi = mod(ngb_idx(k),nfov)
              print*, igmi, jgmi
              dist_temp(k) = sqrt((lon(i,j)-lon_S1(igmi,jgmi))**2 + &
                   (lat(i,j)-lat_S1(igmi,jgmi))**2)
              weight=1/(dist_temp(k)**2+0.01)
              do k1=1,nchan
                 tc_resampled(i,j,k1) = tc_resampled(i,j,k1) + &
                      tc_gmi_S1(igmi,jgmi,k1)*weight
              end do
              weight_sum=weight_sum+weight
           enddo
           do k=1,nchan
              tc_resampled(i,j,k) = tc_resampled(i,j,k)/weight_sum
           end do
        end do
     end do

end subroutine grid_tb
