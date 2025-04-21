

subroutine init_onnx()
    call models_details_c()
    call init_onnx_runtime()
end subroutine init_onnx

!-- 0 GMI_ONNX_Models/dense_autoencoder_land.onnx {'inputs': [{'name': 'input', 'shape': [1, 11], 'dtype': 'FLOAT32'}], 'outputs': [{'name': 'output', 'shape': [1, 11], 'dtype': 'FLOAT32'}]} 
!-- 1 GMI_ONNX_Models/dense_autoencoder_ocean.onnx {'inputs': [{'name': 'input', 'shape': [1, 11], 'dtype': 'FLOAT32'}], 'outputs': [{'name': 'output', 'shape': [1, 11], 'dtype': 'FLOAT32'}]} 

subroutine read_scaler_data()
    use scalers
    open(10,file="GMI_ONNX_Models/scaler_land_qv.bin",form="unformatted",status="old")
    read(10) scaler_land_qv%mean
    read(10) scaler_land_qv%std
    close(10)
    open(10,file="GMI_ONNX_Models/scaler_ocean_qv.bin",form="unformatted",status="old")
    read(10) scaler_ocean_qv%mean
    read(10) scaler_ocean_qv%std
    open(10,file="GMI_ONNX_Models/norm_param_150_land.bin",form="unformatted",status="old")
    read(10)scaler_land%tc
    read(10)scaler_land%sfc_type
    read(10)scaler_land%sk_temp
    read(10)scaler_land%oe_wvp
    read(10)scaler_land%near_sfc_precip
    read(10)scaler_land%xenc
    read(10)scaler_land%xenc_prec
    read(10)scaler_land%xenv_enc
    close(10)
    open(10,file="GMI_ONNX_Models/norm_param_150_ocean.bin",form="unformatted",status="old")
    read(10)scaler_ocean%tc
    read(10)scaler_ocean%sfc_type
    read(10)scaler_ocean%sk_temp
    read(10)scaler_ocean%oe_wvp
    read(10)scaler_ocean%near_sfc_precip
    read(10)scaler_ocean%xenc
    read(10)scaler_ocean%xenc_prec
    read(10)scaler_ocean%xenv_enc
    close(10)
end subroutine read_scaler_data

subroutine call_dense_qv(tskin,qv,isurf,x_output)
    use scalers
    implicit none
    real :: qv(10), tskin
    integer :: isurf
    real :: x_input(11)
    integer :: model_index, input_index, output_index
    real,intent(out) :: x_output(4)

    integer :: i
    !integer :: model_index, input_index
    !print*, "tskin", tskin
    !print*, "qv", qv
    !print*, "isurf", isurf
    !print*, "scaler_land_qv%mean", scaler_land_qv%mean
    !print*, "scaler_land_qv%std", scaler_land_qv%std
    !print*, "scaler_ocean_qv%mean", scaler_ocean_qv%mean
    !print*, "scaler_ocean_qv%std", scaler_ocean_qv%std
    
    if(isurf==1) then
        x_input(1)=(tskin-scaler_land_qv%mean(1))/scaler_land_qv%std(1)
        do i=1,10
            x_input(i+1)=(qv(i)-scaler_land_qv%mean(i+1))/scaler_land_qv%std(i+1)
        end do
    else
        x_input(1)=(tskin-scaler_ocean_qv%mean(1))/scaler_ocean_qv%std(1)
        do i=1,10
            x_input(i+1)=(qv(i)-scaler_ocean_qv%mean(i+1))/scaler_ocean_qv%std(i+1)
        end do
    end if
    !print*, "x_input", x_input
    !print*, isurf, model_index
    if (isurf==1) then
        model_index=4
    else
        model_index=5
    end if
    !print*, "x_input", x_input
    
    input_index=0
    output_index=0
    call set_input_data(model_index, input_index, x_input)
    !print*, "out of set_input_data"
    call call_onnx(model_index)
    !print*, input_index
    call get_output_data(model_index, output_index, x_output)
    !print*, "x_output", x_output
    return
end subroutine call_dense_qv


subroutine call_map_est(x_input,isurf,x_output,x_output_nat,x_input_scaled)
    use scalers
    implicit none
    real :: qv(10), tskin
    integer :: isurf
    real :: x_input(150,49,19)
    integer :: model_index, input_index, output_index
    real,intent(out) :: x_output(150,49,12)
    real,intent(out) :: x_output_nat(150,49,2)
    real,intent(out) :: x_input_scaled(150,49,19)
    real :: x_input_flat(150*49*19)
    real :: x_output_flat(150*49*12)
    integer :: i, ic, j, k
    !integer :: model_index, input_index
    !print*, "tskin", tskin
    !print*, "qv", qv
    !print*, "isurf", isurf
    !print*, "scaler_land_qv%mean", scaler_land_qv%mean
    !print*, "scaler_land_qv%std", scaler_land_qv%std
    !print*, "scaler_ocean_qv%mean", scaler_ocean_qv%mean
    !print*, "scaler_ocean_qv%std", scaler_ocean_qv%std
    print*, 'isurf=', isurf
    if(isurf==1) then
        do i=1,150
            do j=1,49
                x_input(i,j,1:13)=(x_input(i,j,1:13)-scaler_land%tc(1,i,j,1:13))/scaler_land%tc(2,i,j,1:13)
                x_input(i,j,14)=(x_input(i,j,14)-scaler_land%sfc_type(1,i,j))/scaler_land%sfc_type(2,i,j)
                x_input(i,j,15)=(x_input(i,j,15)-scaler_land%sk_temp(1,i,j))/scaler_land%sk_temp(2,i,j)
                x_input(i,j,16:19)=(x_input(i,j,16:19)-scaler_land%xenv_enc(1,i,j,1:4))/scaler_land%xenv_enc(2,i,j,1:4)
            end do
        end do
    else    
        do i=1,150
            do j=1,49
                x_input(i,j,1:13)=(x_input(i,j,1:13)-scaler_ocean%tc(1,i,j,1:13))/scaler_ocean%tc(2,i,j,1:13)
                x_input(i,j,14)=(x_input(i,j,14)-scaler_ocean%sfc_type(1,i,j))/scaler_ocean%sfc_type(2,i,j)
                x_input(i,j,15)=(x_input(i,j,15)-scaler_ocean%sk_temp(1,i,j))/scaler_ocean%sk_temp(2,i,j)
                x_input(i,j,16:19)=(x_input(i,j,16:19)-scaler_ocean%xenv_enc(1,i,j,1:4))/scaler_ocean%xenv_enc(2,i,j,1:4)
            end do
        end do
    end if
    x_input_scaled=x_input
    if (isurf==1) then
        model_index=6
    else
        model_index=7
    end if
    ic=0
    do k=1,19
        do i=1,150
            do j=1,49
                ic=ic+1
                x_input_flat(ic)=x_input(i,j,k)
            end do
        end do
    end do
    input_index=0
    call set_input_data(model_index, input_index, x_input_flat)
    call call_onnx(model_index)
    output_index=1
    call get_output_data(model_index, output_index, x_output_flat)
    !print*, "x_output", x_output
    ic=0
    do k=1,12
        do i=1,150
            do j=1,49
                ic=ic+1
                x_output(i,j,k)=x_output_flat(ic)
            end do
        end do
    end do
    do i=1,150
        do j=1,49
            if(isurf==1) then
                x_output_nat(i,j,1)=x_output(i,j,1)*scaler_land%oe_wvp(2,i,j)+scaler_land%oe_wvp(1,i,j)
                x_output_nat(i,j,2)=x_output(i,j,2)*scaler_land%near_sfc_precip(2,i,j)+scaler_land%near_sfc_precip(1,i,j)
            else
                x_output_nat(i,j,1)=x_output(i,j,1)*scaler_ocean%oe_wvp(2,i,j)+scaler_ocean%oe_wvp(1,i,j)
                x_output_nat(i,j,2)=x_output(i,j,2)*scaler_ocean%near_sfc_precip(2,i,j)+scaler_ocean%near_sfc_precip(1,i,j)
            end if
        end do
    end do
    return  
end subroutine call_map_est

subroutine set_input_data_unet(imodel, input_data, output_data, &
    ichan_in, ichan_out, n_x, n_y)
    integer, intent(in) :: imodel, ichan_in, n_x, n_y
    integer, intent(in) :: ichan_out
    real, intent(in) :: input_data(ichan_in, n_x, n_y)
    real, intent(out) :: output_data(ichan_out, n_x, n_y)

    
end subroutine set_input_data_unet

