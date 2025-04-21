subroutine init_onnx_f90()
    call init_onnx_runtime()
    print*, 'here'
end subroutine init_onnx_f90
!call_onnx_(float *input_data, int *lengths_data, float *output_data, int *batch_size, int *seq_len, int *input_size, int *output_size)

subroutine call_onnx_f90(input_data,actual_seq_len,n_input,n_seq,n_batch,&
    n_output,output_data)
    real :: input_data(n_input,n_seq,n_batch)
    integer :: actual_seq_len(n_batch)
    real,intent(out) :: output_data(n_output,n_seq,n_batch)
    print*, n_input, n_seq, n_batch, n_output
    call call_onnx(input_data, actual_seq_len, output_data, n_batch, & 
         n_seq, n_input, n_output)
end subroutine call_onnx_f90

subroutine onnx_retrieval_ku_f90(z_ku_meas, p_type, bin_nodes, n_scans, onnx_precip_rate, &
     onnx_dm, &
     near_surf_onnx_precip_rate,xlon,xlat,n_batch, n_seq, n_input,n_output)
    integer :: n_scans
    real :: z_ku_meas(88,49,n_scans)
    integer :: p_type(49,n_scans) , bin_nodes(5,49,n_scans)
    real, intent(out) :: onnx_precip_rate(88,49,n_scans)
    real, intent(out) :: onnx_dm(88, 49,n_scans)
    integer :: n_batch, n_seq, n_input, n_output
    real :: input_data(n_input,n_seq,n_batch)
    integer :: actual_seq_len(n_batch)
    real :: output_data(n_output,n_seq,n_batch)
    integer :: i, j, k, ic
    real :: z_ku_scaled, bin_scaled
    real, intent(out) :: near_surf_onnx_precip_rate(49,n_scans)
    integer :: n_points=1
    real :: xlon(49,n_scans), xlat(49,n_scans), wrfract
    integer :: im, nseq1
    ic=1
    !print*, n_points,n_batch,n_seq,n_input,n_output
    !print*, n_scans
    onnx_dm=0
    onnx_precip_rate=0
    near_surf_onnx_precip_rate=0
    
    do i=1,n_scans
        do j=1,49
           if (p_type(j,i) > 0) then
              !print*, p_type(j,i), bin_nodes(:,j,i)
                do k=bin_nodes(1,j,i),bin_nodes(5,j,i)
                    z_ku_scaled=z_ku_meas(k,j,i)
                    if (z_ku_scaled<0) z_ku_scaled=0
                    z_ku_scaled=(z_ku_scaled-12)/8
                    bin_scaled=(k-bin_nodes(3,j,i))/8.0
                    if (k+1-bin_nodes(1,j,i) <= n_seq) then
                        input_data(1,k+1-bin_nodes(1,j,i),ic)=z_ku_scaled
                        input_data(2,k+1-bin_nodes(1,j,i),ic)=bin_scaled
                    end if
                end do
                actual_seq_len(ic)=bin_nodes(5,j,i)-bin_nodes(1,j,i)+1
                call getwfraction(xlat(j,i),&
                     xlon(j,i),wfractPix)
                im=0
                if(p_type(j,i)/100==2) im=1
                if(wfractPix<50) im=im+2
                !print*, i, j, ic, actual_seq_len(ic)
                if (actual_seq_len(ic)>1) then
                   n_seq1=n_seq
                   if(wrfactPix>50) n_seq1=n_seq-1
                   call call_onnx(input_data, actual_seq_len, output_data, n_points, & 
                        n_seq1, n_input, n_output,im)
                endif
                do k=bin_nodes(1,j,i),bin_nodes(5,j,i)
                    onnx_precip_rate(k,j,i)=0.1*(10**output_data(1,k+1-bin_nodes(1,j,i),ic)-1)
                    onnx_dm(k,j,i)=output_data(2,k+1-bin_nodes(1,j,i),ic)
                    if(k==bin_nodes(5,j,i)-1) then
                        near_surf_onnx_precip_rate(j,i)=0.1*(10**output_data(1,k+1-bin_nodes(1,j,i),ic)-1)
                    end if
                end do
            end if
            
        end do
    end do
    print*, n_input, n_seq, n_batch, n_output
    print*, ic
    
end subroutine onnx_retrieval_ku_f90

subroutine onnx_retrieval_f90(z_ku_meas, z_ka_meas, p_type, bin_nodes, n_scans, onnx_precip_rate, onnx_dm, &
    near_surf_onnx_precip_rate,n_batch, n_seq, n_input,n_output)
    integer :: n_scans
    real :: z_ku_meas(88,49,n_scans)
    real :: z_ka_meas(88,49,n_scans)
    integer :: p_type(49,n_scans) , bin_nodes(5,49,n_scans)
    real, intent(out) :: onnx_precip_rate(88,49,n_scans)
    real, intent(out) :: onnx_dm(88, 49,n_scans)
    integer :: n_batch, n_seq, n_input, n_output
    real :: input_data(n_input,n_seq,n_batch)
    integer :: actual_seq_len(n_batch)
    real :: output_data(n_output,n_seq,n_batch)
    integer :: i, j, k, ic
    real :: z_ku_scaled, z_ka_scaled, bin_scaled
    real, intent(out) :: near_surf_onnx_precip_rate(49,n_scans)
    integer :: n_points=1
    ic=1
    print*, n_points,n_batch,n_seq,n_input,n_output
    do i=1,n_scans
        do j=1,49
            if (p_type(j,i) > 0) then
                do k=bin_nodes(1,j,i),bin_nodes(5,j,i)
                    z_ku_scaled=z_ku_meas(k,j,i)
                    if (z_ku_scaled<0) z_ku_scaled=0
                    z_ku_scaled=(z_ku_scaled-12)/8
                    z_ka_scaled=z_ka_meas(k,j,i)
                    if (z_ka_scaled<0) z_ka_scaled=0
                    z_ka_scaled=(z_ka_scaled-12)/8
                    bin_scaled=(k-bin_nodes(3,j,i))/8.0
                    if (k+1-bin_nodes(1,j,i) <= n_seq) then
                        input_data(1,k+1-bin_nodes(1,j,i),ic)=z_ku_scaled
                        input_data(2,k+1-bin_nodes(1,j,i),ic)=z_ka_scaled
                        input_data(3,k+1-bin_nodes(1,j,i),ic)=bin_scaled
                    end if
                end do
                actual_seq_len(ic)=bin_nodes(5,j,i)-bin_nodes(1,j,i)+1
                !print*, i, j, ic, actual_seq_len(ic)
                if (actual_seq_len(ic)>1) then
                    call call_onnx(input_data, actual_seq_len, output_data, n_points, & 
                    n_seq, n_input, n_output)
                endif
                do k=bin_nodes(1,j,i),bin_nodes(5,j,i)
                    onnx_precip_rate(k,j,i)=0.1*(10**output_data(1,k+1-bin_nodes(1,j,i),ic)-1)
                    onnx_dm(k,j,i)=output_data(2,k+1-bin_nodes(1,j,i),ic)
                    if(k==bin_nodes(5,j,i)-1) then
                        near_surf_onnx_precip_rate(j,i)=0.1*(10**output_data(1,k+1-bin_nodes(1,j,i),ic)-1)
                    end if
                end do
            end if
            
        end do
    end do
    print*, n_input, n_seq, n_batch, n_output
    print*, ic
    
end subroutine onnx_retrieval_f90

subroutine onnx_retrieval_1d_f90(z_ku_meas, z_ka_meas,  bin_nodes, n_scans, onnx_precip_rate, onnx_dm, &
    near_surf_onnx_precip_rate,n_batch, n_seq, n_input,n_output)
    implicit none
    integer :: n_scans
    real :: z_ku_meas(88,n_scans)
    real :: z_ka_meas(88,n_scans)
    integer ::  bin_nodes(5,n_scans)
    real, intent(out) :: onnx_precip_rate(88,n_scans)
    real, intent(out) :: onnx_dm(88, n_scans)
    integer :: n_batch, n_seq, n_input, n_output
    real :: input_data(n_input,n_seq,n_batch)
    integer :: actual_seq_len(n_batch)
    real :: output_data(n_output,n_seq,n_batch)
    integer :: i,  k, ic
    real :: z_ku_scaled, z_ka_scaled, bin_scaled
    real, intent(out) :: near_surf_onnx_precip_rate(n_scans)
    integer :: n_points=1

    ic=1
    print*, n_points,n_batch,n_seq,n_input,n_output
    do i=1,n_scans
        do k=bin_nodes(1,i),bin_nodes(5,i)
            z_ku_scaled=z_ku_meas(k,i)
            if (z_ku_scaled<0) z_ku_scaled=0
            z_ku_scaled=(z_ku_scaled-12)/8
            z_ka_scaled=z_ka_meas(k,i)
            if (z_ka_scaled<0) z_ka_scaled=0
            z_ka_scaled=(z_ka_scaled-12)/8
            bin_scaled=(k-bin_nodes(3,i))/8.0
            if (k+1-bin_nodes(1,i) <= n_seq) then
                input_data(1,k+1-bin_nodes(1,i),ic)=z_ku_scaled
                input_data(2,k+1-bin_nodes(1,i),ic)=z_ka_scaled
                input_data(3,k+1-bin_nodes(1,i),ic)=bin_scaled
            end if
        end do
        actual_seq_len(ic)=bin_nodes(5,i)-bin_nodes(1,i)+1
                !print*, i, j, ic, actual_seq_len(ic)
        if (actual_seq_len(ic)>1) then
            call call_onnx(input_data, actual_seq_len, output_data, n_points, & 
                n_seq, n_input, n_output)
        endif
        do k=bin_nodes(1,i),bin_nodes(5,i)
            onnx_precip_rate(k,i)=0.1*(10**output_data(1,k+1-bin_nodes(1,i),ic)-1)
            onnx_dm(k,i)=output_data(2,k+1-bin_nodes(1,i),ic)
            if(k==bin_nodes(5,i)) then
                near_surf_onnx_precip_rate(i)=0.1*(10**output_data(1,k+1-bin_nodes(1,i),ic)-1)
            end if
        end do
    end do
    
    
end subroutine onnx_retrieval_1d_f90
