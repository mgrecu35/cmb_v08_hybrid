!python -m numpy.f2py -c -m precip_align fortran_alignment.f90 

subroutine calc_correlation(array1, array2, nx, ny, corr)
    real, intent(in) :: array1(nx,ny), array2(nx,ny)
    real, intent(out) :: corr
    real :: array1_mean, array2_mean
    real :: array1_std, array2_std
    integer :: nx, ny
    integer :: i, j
    ! Compute correlation coefficient (placeholder for actual implementation)
    corr = 0.0
    !nx=size(array1, 1)
    !ny=size(array1, 2)
    array1_mean = sum(array1) / (nx * ny)
    array2_mean = sum(array2) / (nx * ny)
    array1_std = sqrt(sum((array1 - array1_mean)**2) / (nx * ny))+1e-9
    array2_std = sqrt(sum((array2 - array2_mean)**2) / (nx * ny))+1e-9
    do i=1,nx
        do j=1,ny
            corr = corr + (array1(i,j) - array1_mean) * (array2(i,j) - array2_mean)
        end do
    end do
    corr = corr / (nx * ny * array1_std * array2_std)
end subroutine calc_correlation

subroutine gaussian_filter(input, output, n, sigma)
    integer, intent(in) :: input(n)
    real, intent(out) :: output(n)
    integer, intent(in) :: sigma
    integer :: i, j, n
    real :: weight, weight_sum
    ! Apply Gaussian filter (placeholder for actual implementation)
    output = input
    do i=1+sigma, n-sigma
        weight_sum = 0.0
        do j=-sigma, sigma
            weight = exp(-j**2 / (2.0 * sigma**2))
            output(i) = output(i) + input(i+j) * weight
            weight_sum = weight_sum + weight
        end do
        output(i) = output(i) / weight_sum
    end do
end subroutine gaussian_filter

subroutine align_precip(precip_gmi_only, precip_corra, precip_gmi_only_shifted, filt_displacement,&
     n_size, n_ray)
    implicit none
    integer :: nw2, nmax, n_size, i, j, index, n_ray
    real :: precip_gmi_only(n_size,n_ray), precip_corra(n_size,n_ray)
    real, allocatable :: corr(:)
    integer, allocatable :: displacement(:)
    real, intent(out) :: filt_displacement(n_size)
    real, intent(out) :: precip_gmi_only_shifted(n_size,n_ray)
    integer :: sigma
    integer :: max_index
    !Initialize variables
    nw2 = 4
    nmax = 4

    allocate(displacement(n_size))
    !allocate(filt_displacement(n_size))
    !allocate(act_corr(0))
    !allocate(index_L(0, 2))
    allocate(corr(2 * nmax + 1))

! Main loop
    do i = nw2 + nmax+1, n_size - nw2 - nmax
        corr = 0.0
        do j = -nmax, nmax
            if (maxval(precip_gmi_only(i + j - nw2:i + j + nw2, :)) < 0.01 .or. &
                    maxval(precip_corra(i - nw2:i + nw2, :)) < 0.01) then
                corr(j + nmax + 1) = 0.0
            else
                call calc_correlation(precip_gmi_only(i + j - nw2:i + j + nw2, :), &
                    precip_corra(i - nw2:i + nw2, :),2*nw2+1,n_ray,corr(j + nmax + 1))
            end if
        end do
        max_index = maxloc(corr, dim=1)
        index = max_index - 1
        displacement(i) = index - 4
    end do
    deallocate(corr)


! Apply Gaussian filter (placeholder for actual implementation)
    sigma = 1
    call gaussian_filter(displacement, filt_displacement, n_size, sigma)

! Shift precip_gmi_only
    do i = 1, size(precip_gmi_only, 1)
        do j = 1, size(precip_gmi_only, 2)
            if (i + filt_displacement(i) > 0 .and. i + filt_displacement(i) <= size(precip_gmi_only, 1)) then
                precip_gmi_only_shifted(i, j) = precip_gmi_only(int(i + filt_displacement(i)), j)
            end if
        end do
     end do
     deallocate(displacement)
     !deallocate(corr)
end subroutine align_precip
