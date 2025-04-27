!call get_qv_enc(skTemp((ichunk-1)*150+i,j),qv((ichunk-1)*150+i,j,:),itype,x_qv_enc,nbin,j)
subroutine get_qv_enc(tskin,qv_full,isurf,x_output,nbin,jray)
    use scalers
    implicit none
    integer :: nbin, jray, jray_mirror
    integer :: env_nodes(10)
    integer :: i, k
    real :: qv_full(nbin)
    real :: qv_env(10), tskin
    integer :: isurf
    real :: x_input_1D(11)
    integer :: model_index, input_index, output_index
    real :: x_output(4)
    real :: azimuthAngle(25)
    real :: env_levs(10), pi
    pi=3.14159265358979323846
    env_levs=(/18., 14., 10., 8., 6., 4., 2., 1., 0.5, 0./)
    azimuthAngle=(/18.189877,   17.43291,    16.671007,   15.9137535,  15.158456,   14.405092,&
    13.648316,   12.8897085,  12.130318,   11.377583,   10.617645,    9.862196,&
    9.108555,    8.352984,    7.597067,    6.8434463,   6.089454,    5.335081,&
    4.5808573,   3.8257294,   3.0702605,   2.3193207,   1.5647225,   0.8158924,&
    0.11826304/)
    do k = 1, 10
        if (jray <=25) then
            jray_mirror = jray
        else
            jray_mirror = 50 - jray
        end if
        env_nodes(k) = 88 - nint((env_levs(k)/cos(azimuthAngle(jray_mirror) * pi / 180.)) * 4.)
        qv_env(k) = qv_full(env_nodes(k))
     enddo
    if(isurf==1) then
        x_input_1D(1)=(tskin-scaler_land_qv%mean(1))/scaler_land_qv%std(1)
        do k=1,10
            x_input_1D(k+1)=(qv_env(k)-scaler_land_qv%mean(i+1))/scaler_land_qv%std(k+1)
        end do
    else
        x_input_1D(1)=(tskin-scaler_ocean_qv%mean(1))/scaler_ocean_qv%std(1)
        do k=1,10
            x_input_1D(k+1)=(qv_env(k)-scaler_ocean_qv%mean(k+1))/scaler_ocean_qv%std(k+1)
        end do
    end if
    if (isurf==1) then
        model_index=4
    else
        model_index=5
    end if
    input_index=0
    output_index=0
    !print*, x_input_1D, qv_env, tskin, isurf
    call set_input_data(model_index, input_index, x_input_1D)
    !print*, "out of set_input_data"
    call call_onnx(model_index)
    !print*, input_index
    call get_output_data(model_index, output_index, x_output)
end subroutine get_qv_enc

subroutine call_model_32(x_input,nscans,nrays,nfeat_in,nfeat_out,isurf,ndpr,&
     ioffset1,ioffset2,x_output_nat)
    use scalers
    implicit none
    real, intent(in) :: x_input(nscans,nrays,nfeat_in)
    integer :: nscans, nrays, nfeat_in, nfeat_out, ioffset1, ioffset2, ndpr
    integer :: isurf
    integer :: model_index, input_index, output_index
    real :: x_input_flat(nscans*nrays*nfeat_in)
    real :: x_output_flat(nscans*nrays*nfeat_out)
    real :: x_output(nscans,nrays,nfeat_out)
    real :: x_output_nat(ndpr,nrays,nfeat_out)
    integer :: i, ic, j, k

    if (isurf==1) then
        model_index=6
    else
        model_index=7
    end if
    ic=0
    do k=1,nfeat_in
        do i=1,nscans
            do j=1,nrays
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
    do k=1,nfeat_out
        do i=1,nscans
            do j=1,nrays
                ic=ic+1
                x_output(i,j,k)=x_output_flat(ic)
            end do
        end do
    end do
    
    do i=1,nscans
        do j=1,nrays
        if(isurf==1) then
            x_output_nat(ioffset1+i,j,1)=x_output(i,j,1)*scaler_land%oe_wvp(2,ioffset2+i,j)+scaler_land%oe_wvp(1,ioffset2+i,j)
            x_output_nat(ioffset1+i,j,2)=x_output(i,j,2)*scaler_land%near_sfc_precip(2,ioffset2+i,j)+scaler_land%near_sfc_precip(1,ioffset2+i,j)
        else
            x_output_nat(ioffset1+i,j,1)=x_output(i,j,1)*scaler_ocean%oe_wvp(2,ioffset2+i,j)+scaler_ocean%oe_wvp(1,i,j)
            x_output_nat(ioffset1+i,j,2)=x_output(i,j,2)*scaler_ocean%near_sfc_precip(2,ioffset2+i,j)+scaler_ocean%near_sfc_precip(1,ioffset2+i,j)
        end if
    end do
end do
end subroutine call_model_32

subroutine test_onnx(tb_resampled,surfaceType_f,skTemp_f,qv_f,ndpr,nray,nchan,nbin,&
     nfeat_in,nfeat_out,x_output_f)
    use scalers
    implicit none
    integer :: ndpr, nray, nbin, nchan
    real :: tb_resampled(ndpr,nray,nchan)
    integer :: surfaceType_f(nray,ndpr)
    real :: skTemp_f(nray,ndpr)
    real :: qv_f(nbin,nray,ndpr)
    integer :: surfaceType(ndpr,nray)
    real :: skTemp(ndpr,nray)
    real :: qv(ndpr,nray,nbin)
    real :: azimuthAngle(25)
    real :: x_input(ndpr,49,19)
    integer :: itype, n150, i, j, ichunk, icount, patch_type(ndpr)
    real :: x_qv_enc(4)
    integer :: istart, ioffset2, nfeat_in, nfeat_out, n_inp, n_calls, isurf
    real :: x_output(ndpr,nray,nfeat_out)
    real :: x_output_f(nfeat_out,nray,ndpr)
    real :: x_output_1d(62)
    n_inp=32
    !nfeat_in=19
    !nfeat_out=12
    
    azimuthAngle=(/18.189877,   17.43291,    16.671007,   15.9137535,  15.158456,   14.405092,&
    13.648316,   12.8897085,  12.130318,   11.377583,   10.617645,    9.862196,&
    9.108555,    8.352984,    7.597067,    6.8434463,   6.089454,    5.335081,&
    4.5808573,   3.8257294,   3.0702605,   2.3193207,   1.5647225,   0.8158924,&
    0.11826304/)
    n150=int(ndpr/150)+1
    do i=1,ndpr
        do j=1,nray
            surfaceType(i,j)=surfaceType_f(j,i)
            skTemp(i,j)=skTemp_f(j,i)
            qv(i,j,1:nbin)=qv_f(1:nbin,j,i)
        end do
    end do
    do ichunk=1,n150
        itype=0
        do i=1,min(150,ndpr-150*(ichunk-1))
            do j=1,49
                if (surfaceType((ichunk-1)*150+i,j)==0) then
                    icount=icount+1
                end if
            end do
        end do
        if (icount.lt.0.5*150*49) itype=1
        do i=1,min(150,ndpr-150*(ichunk-1))
            patch_type((ichunk-1)*150+i)=itype
            do j=1,49
                call get_qv_enc(skTemp((ichunk-1)*150+i,j),qv((ichunk-1)*150+i,j,:),itype,x_qv_enc,nbin,j)
                if (itype==1) then
                    x_input(150*(ichunk-1)+i,j,1:13)=&
                    (tb_resampled(150*(ichunk-1)+i,j,1:13)-scaler_land%tc(1,i,j,1:13))/scaler_land%tc(2,i,j,1:13)
                    x_input(150*(ichunk-1)+i,j,14)=&
                    (surfaceType(150*(ichunk-1)+i,j)-scaler_land%sfc_type(1,i,j))/scaler_land%sfc_type(2,i,j)
                    x_input(150*(ichunk-1)+i,j,15)=&
                    (skTemp(150*(ichunk-1)+i,j)-scaler_land%sk_temp(1,i,j))/scaler_land%sk_temp(2,i,j)
                    x_input(150*(ichunk-1)+i,j,16:19)=&
                    (x_qv_enc-scaler_land%xenv_enc(1,i,j,1:4))/scaler_land%xenv_enc(2,i,j,1:4)
                else
                    x_input(150*(ichunk-1)+i,j,1:13)=&
                    (tb_resampled(150*(ichunk-1)+i,j,1:13)-scaler_ocean%tc(1,i,j,1:13))/scaler_ocean%tc(2,i,j,1:13)
                    x_input(150*(ichunk-1)+i,j,14)=&
                    (surfaceType(150*(ichunk-1)+i,j)-scaler_ocean%sfc_type(1,i,j))/scaler_ocean%sfc_type(2,i,j)
                    x_input(150*(ichunk-1)+i,j,15)=&
                    (skTemp(150*(ichunk-1)+i,j)-scaler_ocean%sk_temp(1,i,j))/scaler_ocean%sk_temp(2,i,j)
                    x_input(150*(ichunk-1)+i,j,16:19)=&
                    (x_qv_enc-scaler_ocean%xenv_enc(1,i,j,1:4))/scaler_ocean%xenv_enc(2,i,j,1:4)
                end if
            end do
        end do
     end do
     n_calls=int(ndpr/n_inp)+1
     print*, 'ndpr=',ndpr, 'n_calls',n_calls, n_inp, nray
     do i=1,n_calls
        istart=(i-1)*n_inp+1
        if(istart+n_inp.gt.ndpr) then
           istart=ndpr-32+1
        endif
        ioffset2=modulo(istart,150)
        if(ioffset2==0) then
           ioffset2=1
        endif
        if(ioffset2.gt.150-32) then
           ioffset2=150-32
        endif
        if(sum(patch_type(istart:istart+n_inp-1)).gt.n_inp/2) then
           isurf=1
        else
           isurf=0
        endif
        print*, 'istart',istart, 'offset', ioffset2, i, n_calls
        call call_model_32(x_input(istart:istart+n_inp-1,:,:),n_inp,nray,nfeat_in,nfeat_out,isurf,ndpr,&
             istart-1,ioffset2,x_output)
     enddo
     do i=1,ndpr
        do j=1,nray
           x_output_f(:,j,i)=x_output(i,j,:)
        enddo
     enddo
end subroutine test_onnx

subroutine test_model_1d_onnx(tb_resampled,surfaceType_f,skTemp_f,&
     qv_f,ndpr,nray,nchan,nbin,&
     nfeat_in,nfeat_out,x_output_f,x_output_prof)
    use scalers
    implicit none
    integer :: ndpr, nray, nbin, nchan
    real :: tb_resampled(ndpr,nray,nchan)
    integer :: surfaceType_f(nray,ndpr)
    real :: skTemp_f(nray,ndpr)
    real :: qv_f(nbin,nray,ndpr)
    integer :: surfaceType(ndpr,nray)
    real :: skTemp(ndpr,nray)
    real :: qv(ndpr,nray,nbin)
    integer :: itype, n150, i, j, ichunk, icount, patch_type(ndpr)
    real :: x_qv_enc(4)
    integer :: istart, ioffset2, nfeat_in, nfeat_out, n_inp, n_calls, isurf
    real :: x_input_1d(16), x_output_1d(8), x_output_prof_1d(62)
    real,intent(out) :: x_output_f(nfeat_out,nray,ndpr)
    real,intent(out) :: x_output_prof(ndpr,nray,88)
    integer :: model_index, input_index, output_index
   
    do i=1,ndpr
        do j=1,nray
            surfaceType(i,j)=surfaceType_f(j,i)
            skTemp(i,j)=skTemp_f(j,i)
            qv(i,j,1:nbin)=qv_f(1:nbin,j,i)
        end do
    end do

    do i=1,ndpr
       do j=1,nray
          if(surfaceType(i,j)<1) then
             isurf=0
             model_index=9
          else
             isurf=1
             model_index=8
          end if
          !X_input=torch.tensor(np.concatenate((tc_scaled,sfc_type_scaled[:,np.newaxis],sk_temp_scaled[:,np.newaxis],qv_scaled[:,np.newaxis]),axis=-1),dtype=torch.float32)

          if(isurf==1) then
             x_input_1d(1:13)=(tb_resampled(i,j,1:13)-scaler_1d_land%tc_mean)/&
                  scaler_1d_land%tc_std
             x_input_1d(14)=(surfaceType(i,j)-scaler_1d_land%sfc_type_mean)/&
                  scaler_1d_land%sfc_type_std
             x_input_1d(15)=(skTemp(i,j)-scaler_1d_land%sk_temp_mean)/&
                  scaler_1d_land%sk_temp_std
             x_input_1d(16)=(qv(i,j,10)-scaler_1d_land%qv_mean)/&
                  scaler_1d_land%qv_std
          else
             x_input_1d(1:13)=(tb_resampled(i,j,1:13)-scaler_1d_ocean%tc_mean)/&
                  scaler_1d_ocean%tc_std
             x_input_1d(14)=(surfaceType(i,j)-scaler_1d_ocean%sfc_type_mean)/&
                  scaler_1d_ocean%sfc_type_std
             x_input_1d(15)=(skTemp(i,j)-scaler_1d_ocean%sk_temp_mean)/&
                  scaler_1d_ocean%sk_temp_std
             x_input_1d(16)=(qv(i,j,10)-scaler_1d_ocean%qv_mean)/&
                  scaler_1d_ocean%qv_std
          endif
          input_index=0
          output_index=0
          call set_input_data(model_index, input_index, x_input_1d)
          call call_onnx(model_index)
          call get_output_data(model_index, output_index, x_output_1d)
          model_index=model_index-2
          call set_input_data(model_index, input_index, x_input_1d)
          call call_onnx(model_index)
          call get_output_data(model_index, output_index, x_output_prof_1d)
          x_output_prof_1d=x_output_prof_1d*0.5+0.8
          x_output_prof_1d=0.1*(10**x_output_prof_1d-1)
          if(isurf==1) then
             x_output_1d(2)=x_output_1d(2)*scaler_1d_land%near_sfc_precip_std+&
                  scaler_1d_land%near_sfc_precip_mean
             x_output_prof(i,j,21:82)=x_output_prof_1d(1:62)
          else
             x_output_1d(2)=x_output_1d(2)*scaler_1d_ocean%near_sfc_precip_std+&
                  scaler_1d_ocean%near_sfc_precip_mean
             x_output_prof(i,j,23:84)=x_output_prof_1d(1:62)
          endif
          x_output_f(2,j,i)=0.1*(10**x_output_1d(2)-1)
        end do
    end do

end subroutine test_model_1d_onnx
