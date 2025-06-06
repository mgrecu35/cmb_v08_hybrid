subroutine radarRetSub4_FS(nmu2,  nmfreq2,   icL, tbRgrid,               &
      dprrain,ichunk,orbNumb,ialg,idir,nscans_c)
!  SFM  end    12/13/2013
  use local_RD_var
  use globalData
  use f90DataTypes
  use f90Types
  use cldclass
  use ran_mod
  use geophysEns
  use nbinMod
  !use tables2
  use weight
  Use BMCVparameters
  use emissMod
!begin  MG 10/29/15 add gEnv module
  use gEnv
!end    MG 10/29/15
!begin  WSO 9/14/13 incorporate missing flags
  use missingMod
!end    WSO 9/14/13
!begin  WSO 6/5/18 add limits to output variables
  use outputminmax
!end    WSO 6/5/18
  use LUT_def !SJM 7/9/2015
  use oetbs
  implicit none
!  type (geoDataType) :: geoData
!  type (gridEnvDataType) :: gridEnvData
!  type (dPRDataType)     :: dPRData
!  type (dPRRetType)      :: dPRRet
!  type (gmi2GridType)    :: gmi2Grid
!  type (cgMIDataType)     :: gmiData
  integer :: nmu2, nmfreq2
  integer*4 :: ichunk
!  integer :: st_2adpr              ! file open status for 2adpr file
  real :: tbRgrid(14,49,9300), dprrain(49,300)
 ! integer :: tbRgridIn(9,49,9300)

  real                   :: meansfcRain,stddevSfcRain, tbout(14)
  !type (radarRetType)    :: radarRet
  !type (radarDataType)   :: radarData
  type (retParamType)    :: retParam
  real :: xin363(363)
 
  integer :: ii, jj, iGMI, jGMI
  integer :: di(8), dj(8)  
  integer :: i, j, ig, jg, ntpw, nmemb1, itop, irand
  real    :: pia13m, rms1, rms2,  unSortedRR(200), corrcoef, sfcRain2, tpw_ij
  integer :: iy(200), kflag, it
  real    :: sysdNl, pia13mean
  integer :: iLandSea(5,5), i1, j1, igetlandsea, ic2, nobs, iit
  real :: a0(2,8), emiss(2), tb19v, tb19h, tb37v, tb37h, tb22v, tb85v, tb85h
  real :: meanTb85
  real :: stdTb85,kgain,kgain37, ymean(3)
!...Ensemble parameters
  !real, allocatable ::  Yens(:,:), Xens(:,:), Yobs(:), Xup(:)
  integer :: ibatch
  real    :: stddev, srtpiaf
  real    :: FWHMx, FWHMy, tbconv(2), tbconvEns(2,100)
  integer :: dnx,dny, ik
  !real, allocatable :: ndn(:), ndnp(:,:), xscalev(:), logdNwf(:), randemiss(:), dwind(:)
  !real, allocatable  :: rhPCij(:,:), cldwPCij(:,:)
  real :: cldw(nlayer), rh(nlayer), pia13s
  integer :: nx,ny, icount, imin
  real ::  xm1,xs,rmsmin, prob, probtot, rmstot
  real :: piaR(100), fPIA, z13m
  integer :: ntbpix, ntbpix2
  real :: emtbm(9)
  real :: zminsc
  real :: realOut(49)
  !real :: w10(49,300), w10_out_NS(49,300), w10_out_MS(49,300), w10_min, w10_max, emis, relAz
  !real :: w10_rms_NS(49,300), emis_rms_NS(49,300,13), w10_rms_MS(49,300), emis_rms_MS(49,300,13)
  !real :: dZms(49,300) !! MS addition Feb 10, 2017
  !integer :: msFlag(49, 300) !!WSO addition Feb 11, 2017
!begin  WSO 2/8/17 new variables
  integer :: multiscatcalc_NS(49, 300), multiscatcalc_MS(49, 300)
  integer :: algotype_NS(49, 300), algotype_MS(49, 300)
  integer :: profclass_NS(49, 300), profclass_MS(49, 300)
  real :: subfootvariability_NS(49, 300), subfootvariability_MS(49, 300)
  real :: multiscatsurface_NS(49, 300), multiscatsurface_MS(49, 300)
  real :: skintempsigma_NS(49, 300), skintempsigma_MS(49, 300)
  real :: columnvaporsigma_NS(49, 300), columnvaporsigma_MS(49, 300)
  real :: columncloudliqsigma_NS(49, 300), columncloudliqsigma_MS(49, 300)
  real :: errorofdatafit_NS(49, 300), errorofdatafit_MS(49, 300)
  real :: initnw_NS(nbin, 49, 300), initnw_MS(nbin, 49, 300) 
  real :: princomp_NS(5, 49, 300), princomp_MS(5, 49, 300)
  real :: surfprecipbiasratio_NS(49, 300), surfprecipbiasratio_MS(49, 300)
!end    WSO 2/8/17 
  integer :: l, ipias(2)
  character*3 :: ifdpr, iftest
  character*90 :: outfile
  integer :: ink
  DOUBLE PRECISION input(6)
  DOUBLE PRECISION output(2)
  real :: wfract(5,5), wfractm, wfractsd
  real                    emissv(n_chan)
  real                    emissh(n_chan)
  real                    emissv_std(n_chan)
  real                    emissh_std(n_chan)
  integer :: stype!SJM 7/9/2015
  real  :: vLand(18,18), vOcean(10,10)
  real  :: pMLand(18), pMOcean(10)
  real  :: mTbLand(9), mTbOcean(9)
  real  :: stTbLand(9), stTbOcean(9)
  double precision  :: xin(18), xpred(18), yout(9)
  !real, allocatable :: emissoutL(:,:,:), emis_out_NS(:,:,:), emis_out_MS(:,:,:) !sjm 8/10/15
!begin  WSO 8/19/13 change Nw variable name (not dN) and add mu
  real :: cldwprof(88), cldiprof(88), log10NwMean(88), mu_mean_prof(88)
  integer *2 :: env_nodes(10, 49)
  real :: env_levs(10), ray_angle, pi
!end    WSO 8/19/13
  real :: lFract(49,300), sprobs, probs(100), rmsS(100)
  real :: covar, xf
  integer  :: orbNumb
  !begin SJM 7/25/14
  real :: s0Ku, s0Ka, s0stdKu, s0stdKa, s0corr, ds0Ku, ds0Ka
  !real :: sigmaZeroVarKu(49,300), sigmaZeroVarKa(49,300), sigmaZeroCov(49,300)
  !end SJM 7/25/2014
!begin WSO 8/8/13
  real :: gatelength
  real :: depthBB, depthML, depth
  real :: mu_mean(49, 300)
  real :: mu_meanMS(49, 300)
!  real :: scLatPR(49,300),scLonPR(49,300),wfmap(49,300), fpmap(49,300,15), fpmapN(49,300,15)
  !real :: S1eiaPR(49,300), S2eiaPR(49,300)
  real :: mlwc_frac(10, 49, 300)
  real :: mrate_frac(10, 49, 300)
  real :: mlwc_fracMS(10, 49, 300)
  real :: mrate_fracMS(10, 49, 300)
  real :: sfcRainLiqFrac(49, 300)
  real :: sfcRainLiqFracMS(49, 300)
  real :: tbMax1(15), tbMin1(15)

!  SFM  begin  07/29/2014; for M.Grecu  eliminate NANs
!  SFM  begin  06/22/2014
  real :: wfractPix, windPert(100), windPertU(100), windPertV(100), qvPert(100), dnqv
!  SFM  end    06/22/2014
!  SFM  end    07/29/2014
!end   WSO 8/8/13
  

  integer :: actOb(49,300), iactOb
  integer :: jk, nf
  integer :: dig               ! SFM  04/16/2014  for M.Grecu
  real   :: cl(9,25), xin25(25),dtb(9)
  real   :: ebar, minl

  !integer*4 :: istart, iend
  integer :: iconv, ialg, icL
  real :: nubfc, stdpia35

  integer,parameter :: nscans=300, npixs=49, nlev=88, nchans=13
  integer :: nfreq, idir, nscans_c
  integer :: pType(nscans,npixs)
  real :: sfcTemp(nscans,npixs), cldw3d(nscans,npixs,nlev)
  integer :: clutFree(nscans,npixs)
  real :: pRate(nscans,npixs,nlev), swc3d(nscans,npixs,nlev), tbobsT(nscans,npixs,nchans)
  real :: z13(nscans,npixs,nlev),emiss2d(nscans,npixs,nchans)
  real :: nw3d(nscans,npixs,nlev), press3d(nscans,npixs,nlev), &
       airTemp3d(nscans,npixs,nlev),qv3d(nscans,npixs,nlev)
  integer :: binNodes(nscans,npixs,5)
  integer :: envNode(nscans,npixs,10)
  real    :: pRateOut(nscans,npixs,nlev), swcOut(nscans,npixs,nlev), nwOut(nscans,npixs,nlev)
  integer :: sfcBin(nscans,npixs)
  real    :: tbsim(nscans,npixs,nchans)
  integer :: flagScanPattern, flagScanPattern_0
  real    :: dm3d_a(nbin,49,300), dm3dMS_a(nbin,49,300), log10NwMean_a(nbin), &
       nw3d_a(nbin,49,300), nw3dms_a(nbin,49,300)

  data env_levs/18., 14., 10., 8., 6., 4., 2., 1., 0.5, 0./
  iconv=1
  nmemb1=nmemb
  nscans_c=dPRData%n1c21
  ifreqG(1:13)=(/1,1,2,2,3,4,4,5,5,6,6,7,8/)
  ipolG(1:13)=(/1,2,1,2,1,1,2,1,2,1,2,1,1/)

!begin WSO 2/8/17 initialize new output variables
  multiscatcalc_NS = missing_i4
  algotype_NS = missing_i4
  subfootvariability_NS = missing_r4
  multiscatsurface_NS = missing_r4
  skintempsigma_NS = missing_r4
  columnvaporsigma_NS = missing_r4
  columncloudliqsigma_NS = missing_r4
  errorofdatafit_NS = missing_r4
  multiscatcalc_MS = missing_i4
  algotype_MS = missing_i4
  subfootvariability_MS = missing_r4
  multiscatsurface_MS = missing_r4
  skintempsigma_MS = missing_r4
  columnvaporsigma_MS = missing_r4
  columncloudliqsigma_MS = missing_r4
  errorofdatafit_MS = missing_r4
  profclass_NS = missing_i4
  initnw_NS = missing_r4
  princomp_NS = missing_r4
  surfprecipbiasratio_NS = missing_r4
  profclass_MS = missing_i4
  initnw_MS = missing_r4
  princomp_MS = missing_r4
  surfprecipbiasratio_MS = missing_r4
!end WSO 2/8/17
!begin WSO 9/15/13 set to flag instead of 0
!begin  WSO 8/8/13
  mlwc_frac = missing_r4
  mrate_frac = missing_r4
  mlwc_fracMS = missing_r4
  mrate_fracMS = missing_r4
  sfcRainLiqFrac = missing_r4
  sfcRainLiqFracMS = missing_r4

  !print*, tbObs(:,:,1)
  print*, 'out2d', icL
  do i=12,37
     !print*,i
     !print*, tbout2D(i,:,1)
  end do
  print*, maxval(tbout2D), maxval(tbout2dnoocean)
  !stop
  if(iconv==1) then
   call updateTbs(dPRData%n1c21,tbObs(:,:,1:9),&
        tbout2D(:,:,1:9),tb(:,:,1:9),fpmap(:,:,1:9),ialg)
   call updateTbsL(dPRData%n1c21,tbObs(:,:,1:9),tbout2DNoOcean(:,:,1:9),&
        tbNoOcean(:,:,1:9),fpmapN(:,:,1:9),ialg)
  
!begin  MG 9/17/18 added following code to adjust deconvolution
   if(ialg==2) then
      do i=1,2
         call updateTbs(dPRData%n1c21,tbObs(:,:,1:9),&
              tbout2D(:,:,1:9),tb(:,:,1:9),fpmap(:,:,1:9),ialg)
         call updateTbsL(dPRData%n1c21,tbObs(:,:,1:9),tbout2DNoOcean(:,:,1:9),&
              tbNoOcean(:,:,1:9),fpmapN(:,:,1:9),ialg)
      enddo
   endif
!end    MG 9/17/18
endif
!print*,tbObs(24,:,1)
!stop
print*,'ialg=',ialg
print*, maxval(dprret%tb)
print*, maxval(tb)
!stop
tb0=tb
print*, 'after update'

do j=3,-dPRData%n1c21-3
   do i=3,49-2
      if(dPRData%raintype(i,j)>0 .and. minval(tbout2d(i,j,1:9))>0 .and. &
         minval(tbRgrid(1:9,i,ic+j))>0.) then
         call setemtbm(emtbm(1:9),dPRRet%emtb(i,j,:,:,1:nmemb1),nmfreq2,nmemb1)
         call dboux2(tb(i,j,1:9),tb0(i,j,1:9),&
              emtbm,ifreqG,ipolG,fem)

         rms1=1e7
         do jk=1,7
            fem(jk)=fem(jk)/10.
            dPRRet%tb(i,j,ipolG(jk),ifreqG(jk),:)= &
                 fem(jk)*dPRRet%emtb(i,j,ipolG(jk),ifreqG(jk),:)+&
                 (1-fem(jk))*dPRRet%tb(i,j,ipolG(jk),ifreqG(jk),:)
         enddo

         !do ik=1,nmemb1
         !   rms2=0
            
         !   do jk=1,5
         !      rms2=rms2+(tb(i,j,jk)- &
         !           dPRRet%tb(i,j,ipolG(jk),ifreqG(jk),ik))**2
         !   enddo
         !
         !   rmsS(ik)=rms2
         !   if(rms2<rms1) then
         !      rms1=rms2
         !      do jk=1,9
         !         tb0(i,j,jk)= &
         !              dPRRet%tb(i,j,ipolG(jk),ifreqG(jk),ik)
         !      enddo
         !   end if
         !enddo
         !tb0(i,j,1:9)=tb(i,j,1:9)
      else
         if (minval(tbRgrid(1:9,i,ic+j))>0.) then
            tb0(i,j,1:9)=tb(i,j,1:9)
         endif
      endif
   enddo
enddo





!do j=3,dPRData%n1c21-3
!   do i=3,49-2
!      if(dPRData%raintype(i,j)>0 .and. minval(tbout2d(i,j,:))>0 .and. &
!           minval(tbRgrid(:,i,ic+j))>0.) then
!         write(*,131) tbRgrid(1:9,i,j+icL),tbout2d(i,j,1:9)
!      endif
!   enddo
!enddo
!call endtbs()
!call closeascii()
132 format(10(F6.2,1x),I3)
105 format(51(F6.2,1x))

close(10)
close(20)
103 format(13(F8.3,1x))
104 format(50(F7.2,1x))
itcount=itcount+ntbpix
!include 'convolveTbs.f90'
!print*, maxval(dPRRet%convtb)
!  SFM  begin  07/29/2014; for M. Grecu, elminate NANs


do j=1,dPRData%n1c21
   do i=1,49
      !write(34) j,i,dPRdata%xlat(i,j), DPRData%xlon(i,j), tb(i,j,:)
      if(dPRData%rainType(i,j)>=100) then
         do k=max(1,1+dPRData%node(1,i,j)-10),1+dPRData%node(5,i,j)
            if(maxval(dPRRet%rrate(1:nmemb1,k,i,j))>0.01 .and. &
                 minval(dPRRet%rrate(1:nmemb1,k,i,j))<0) then
               do imemb=1,nmemb1
                  if(dPRRet%rrate(imemb,k,i,j)<0) then
                     dPRRet%rrate(imemb,k,i,j)=0.
                     dPRRet%pwc(imemb,k,i,j)=0.
                     dPRRet%d0(imemb,k,i,j)=0.
                     dPRRet%z35mod0(imemb,k,i,j)=0.
                  endif
               enddo
            endif
         enddo
         !print*, minval(dPRRet%rrate(:,dPRData%node(5,i,j):dPRData%node(5,i,j),i,j)),  maxval(dPRRet%rrate(:,dPRData%node(5,i,j):dPRData%node(5,i,j),i,j))
      endif
   enddo
enddo
!close(34)

!  SFM  end    07/29/2014
dPRRet%MS%pwc=dPRRet%pwc
dPRRet%MS%rrate=dPRRET%rrate
dPRRet%MS%d0=dPRRet%d0
dPRRet%MS%log10dNw=dPRRet%log10dNw
dPRRet%MS%sfcRainEns=dPRRet%sfcRainEns
dPRRet%MS%zkuEns=dPRRet%z13c
dPRRet%MS%zkaEns=dPRRet%z35
dPRRet%MS%convtb=dPRRet%convtb
dPRRet%MS%tb=dPRRet%tb
dPRRet%MS%pia13mod=dPRRet%pia13mod
dPRRet%MS%pia35mod=dPRRet%pia35mod
!Start SJM 12/9/2014
dPRRet%MS%sfcWindEns=dPRRet%sfcWindEns
dPRRet%MS%simSigmaZeroKu=dPRRet%simSigmaZeroKu
dPRRet%MS%simSigmaZeroKa=dPRRet%simSigmaZeroKa
dPRRet%MS%emis=dPRRet%emis
!end SJM 12/9/2014

!  SFM  begin  06/22/2014; for M.Grecu  (unknown justification)
print*, maxval(dprret%tb)
print*, 'before Kalman'
tb0MS=tb0
tbNoOceanMS=tbNoOcean
nx=30+nbin*7
!begin  MG 9/18/13 changed 110 to 130
ny=130
!
!tb=-999
!hfreqPRg=-999
!
print*, ic
print*, maxval(hFreqPRg(:,:,1))
!print*, maxval(dprRet%emis), maxval(dprRet%MS%emis)
print*,shape(yobs), nx, ny
dm3d_a=missing_r4
dm3dms_a=missing_r4
nw3d_a=missing_r4
nw3dms_a=missing_r4
do j=1,dPRData%n1c21
   do i=1,49
!  SFM  begin  07/29/2014; for M.Grecu, elminate NANs
      do i1=1,5
         do j1=1,5
            eLon=dPRData%xlon(i,j)
            eLat=dPRData%xlat(i,j)
            call getwfraction(eLat+(i1-2)*0.15,&
                 eLon+(j1-2)*0.15,wfract(i1,j1))
            if(i1.eq.2.and.j1.eq.2) then
               wfmap(i1,j1)=wfract(i1,j1)/100.
            endif
         enddo
      enddo
      wfractm=sum(wfract(:,:))/25.
!      if(i .eq. 25) write(*, '("scan: ", i5, "  lat: ", f10.4, "  lon: ", f10.4, &
!        "  wfractm: ", f10.4)'), j, dPRData%xlat(i,j), dPRData%xlon(i,j), wfractm
      tbRgrid(10:13,i,j+icL)= hFreqPRg(i,j,1:4)
      !stype = LUT%land_class_map(mod(floor((dPRData%xlon(i,j)+180.)/360.*5760.),5760)+1, 2880-floor((dPRData%xlat(i,j)+90.)/180.*2880.)) !SJM 9/9/15
      jj=2880-floor((DPRData%xlat(i,j)+90.)/180.*2880.)
      if(jj .lt. 1) jj=1
      if(jj .gt. 2880) jj = 2880
      ii=floor((DPRData%xlon(i,j)+180.)/360.*5760.)+1
      if(ii .lt. 1) ii = 1
      if(ii .gt. 5760) ii = 5760
      if(dPRData%snowIceCover(i,j) .eq. 0) then
        stype = LUT%land_class_map_bare(ii,jj) !SJM 9/9/15
      else
        stype = LUT%land_class_map_snow(ii,jj) !SJM 9/9/15
      endif
      if( dPRData%rainType(i,j)>0) then ! &
 !          .and. j>0 .and. j<dPRData%n1c21-2 )           &
!      then
         if(dPRData%node(1, i, j).gt.dPRData%node(5, i, j)) then
            dPRData%node(1, i, j)=dPRData%node(5, i, j)
         endif
         ntbpix2=ntbpix2+1
         !print*, i, j
         do k=max(1,dPRData%node(1, i, j)),min(dPRData%node(5, i, j)+1,88)
            dm3D_a(k,i,j)=sum(dPRRet%d0(1:nmemb1,k,i,j))/nmemb1
            dm3Dms_a(k,i,j)=sum(dPRRet%ms%d0(1:nmemb1,k,i,j))/nmemb1
            nw3d_a(k,i,j)=sum(dPRRet%log10dNw(1:nmemb1,k,i,j))/nmemb1
            nw3d_a(k,i,j)=sum(dPRRet%MS%log10dNw(1:nmemb1,k,i,j))/nmemb1
         enddo

         if(ifdpr(1:1)=='Y') goto 30
      !tbout(10)=sum(dPRRet%tb(i,j,1,6,1:1*nmemb1))/(nmemb1)
      !tbout(11)=sum(dPRRet%tb(i,j,2,6,1:1*nmemb1))/(nmemb1)
      !tbout(12)=sum(dPRRet%tb(i,j,1,7,1:1*nmemb1))/(nmemb1)
      !tbout(13)=sum(dPRRet%tb(i,j,1,8,1:1*nmemb1))/(nmemb1)
      !do k=10,13
      !   tbout(k)=hFreqPRg(i,j,k-9)
      !enddo
!          write(31) i,j,ichunk,dPRData%sigmaZeroKu(i,j), dPRData%sigmaZeroKa(i,j), sigmaZeroVarKu(i,j),sigmaZeroVarKa(i,j),sigmaZeroCov(i,j), tb(i,j,1:9),hFreqPRg(i,j,:), &!tbRgrid(1:9,i,j+icL), &!scan/ray number, observed sigma_zero
!          dPRRet%sfcRainEns(i,j,1:nmemb1), & !Sfc rain for each ens member
!          dPRRet%sfcd0Ens(i,j,1:nmemb1), & !Sfc D0 for each ens member
!          dPRRet%sfcNwEns(i,j,1:nmemb1), &!Sfc Nw for each ens member
!          dPRRet%sfcWindEns(i,j,1:nmemb1), &!wind for each ens member
!          dPRRet%pia13mod(i,j,1:nmemb1), &!PIAKu for each ens member
!          dPRRet%pia35mod(i,j,1:nmemb1), &!PIAKa for each end member
!          dPRRet%simSigmaZeroKu(i,j,1:nmemb1), &!sigma_zero_Ku for each ens member
!          dPRRet%simSigmaZeroKa(i,j,1:nmemb1), &!sigma_zero_Ka for each ens member
!          dPRRet%tb(i,j,:,:,1:nmemb1), &!Pixel Tb for each ens member (10-19, at least)
!          dPRRet%emis(i,j,:,:,1:nmemb1)
!filterUpNS(dPRData,dPRRet, Xens,Yens,Yobs,Xup,tb,&
!     dprRain,sfcRain,nmemb1,ic,i,j,&
!     nxu,nyu,wfractm,s0KuVar,s0KaVar,s0Cov,hFreqTb)

         if(wfractm>99 .and. stype .eq. 1) then
            call filterUpNS(dPRData,dPRRet, Xens,Yens,Yobs,Xup,  &
                 tb,dprRain,sfcRain,nmemb1,ic,i,j,nx,ny,wfractm,&
                 sigmaZeroVarKu, sigmaZeroVarKa, sigmaZeroCov,&
                 hFreqPRg(i,j,:))
            do k=1,9
               tb0(i,j,k)=sum(dPRRet%tb(i,j,ipolG(k),ifreqG(k),1:nmemb1))/nmemb1 
            enddo
            !print*, tb0(i,j,1:9)

         else
            call filterUpNSLand(dPRData,dPRRet, Xens,Yens,Yobs,Xup,  &
                 tbNoOcean,dprRain,sfcRain,nmemb1,ic,i,j,nx,ny,wfractm,&
                 sigmaZeroVarKu, sigmaZeroVarKa, sigmaZeroCov,&
                 hFreqPRg(i,j,:))
            do k=1,9
               tbNoOcean(i,j,k)=&
                    sum(dPRRet%tb(i,j,ipolG(k),ifreqG(k),1:nmemb1))/nmemb1
            enddo
            !print*, tbNoOcean(i,j,1:9)
            
         endif
         if(i.eq.6.and.j.eq.117) then
            print*, dprdata%node(:,i,j)
            print*, dPRRet%sfcRainEns(i,j,1:nmemb1)
            print*,'--------------------------------------'
            print*, dPRRet%rrate(1:nmemb1,dPRData%node(5,i,j),i,j)
            print*,'--------------------------------------'
            print*, dPRRet%rrate(1:nmemb1,dPRData%node(5,i,j)-1,i,j)
            !stop
         endif
!                   write(32) i,j,ichunk,dPRData%sigmaZeroKu(i,j), dPRData%sigmaZeroKa(i,j), dPRData%srtPIAKu(i,j), dPRData%dsrtPIAKu(i,j), dPRData%dsrtPIAKa(i,j), tb(i,j,1:9),hFreqPRg(i,j,:), &!tbRgrid(1:9,i,j+icL), &!scan/ray number, observed sigma_zero
!          dPRRet%sfcRainEns(i,j,1:nmemb1), & !Sfc rain for each ens member
!          dPRRet%sfcd0Ens(i,j,1:nmemb1), & !Sfc D0 for each ens member
!          dPRRet%sfcNwEns(i,j,1:nmemb1), &!Sfc Nw for each ens member
!          dPRRet%sfcWindEns(i,j,1:nmemb1), &!wind for each ens member
!          dPRRet%pia13mod(i,j,1:nmemb1), &!PIAKu for each ens member
!          dPRRet%pia35mod(i,j,1:nmemb1), &!PIAKa for each end member
!          dPRRet%simSigmaZeroKu(i,j,1:nmemb1), &!sigma_zero_Ku for each ens member
!          dPRRet%simSigmaZeroKa(i,j,1:nmemb1), &!sigma_zero_Ka for each ens member
!          dPRRet%tb(i,j,:,:,1:nmemb1), &!Pixel Tb for each ens member (10-19, at least)
!          dPRRet%emis(i,j,:,:,1:nmemb1)
         
         if(i>=2 .and. i<=48) then
            stdpia35=0.
            if(j>1 .and. j<dPRData%n1c21 .and. pia35m(i,j)>0.1) then
               nubfc= 1./srtpiaf(pia35m(i-1:i+1,j-1:j+1),9)
            else
               nubfc=1.
            endif
!begin  WSO 2/10/17 assigne 1/nubfc to output variable
            subfootvariability_MS(i, j) = 1./nubfc 
!end    WSO 2/10/17
            !nubfc=1
            !print*, i,j,nubfc
            do k=0,nmemb1-1
              if(dPRRet%simSigmaZeroKa(i,j,k+1) .ne. -99.) dPRRet%simSigmaZeroKa(i,j,k+1) = dPRRet%simSigmaZeroKa(i,j,k+1)-dPRRet%pia35mod(i,j,k+1)/nubfc!+ds0Ka 
              !print '(I3,13F8.3,2F8.2)', k, radarRet%tb(k*2*nmfreq2+1:k*2*nmfreq2+13), radarRet%simSigmaZeroKu(k+1), radarRet%simSigmaZeroKa(k+1)
            end do
            !nubfc=0.1-0.45*stdpia35+0.42*stdpia35*stdpia35
            !print*, dPRData%dsrtPIAka(i,j),nubfc
            if (nubfc*dPRData%dsrtPIAka(i,j)<50 .and. nubfc>=1.) then
               !dPRData%dsrtPIAka(i,j)=dPRData%dsrtPIAka(i,j)*1.1*nubfc
            endif
            call filterUpMS(dPRData,dPRRet, Xens,Yens,Yobs,Xup,  &
                 tb,dprRain,sfcRain,nmemb1,ic,i,j,nx,ny,wfractm,&
                 sigmaZeroVarKu, sigmaZeroVarKa, sigmaZeroCov,&
                 hFreqPRg(i,j,:),nubfc)
            if(i.eq.6.and.j.eq.117) then
               print*,'MS'
               print*, dprdata%node(:,i,j)
               print*, dPRRet%MS%sfcRainEns(i,j,1:nmemb1)
               print*,'--------------------------------------'
               print*, dPRRet%MS%rrate(1:nmemb1,dPRData%node(5,i,j),i,j)
               print*,'--------------------------------------'
               print*, dPRRet%MS%rrate(1:nmemb1,dPRData%node(5,i,j)-1,i,j)
               !stop
            endif
            do k=1,9
               tb0MS(i,j,k)=sum(dPRRet%MS%tb(i,j,ipolG(k),&
                    ifreqG(k),1:nmemb1))/nmemb1
               tbNoOceanMS(i,j,k)=sum(dPRRet%MS%tb(i,j,ipolG(k),&
                    ifreqG(k),1:nmemb1))/nmemb1
            enddo
         endif
         !  SFM  end    07/29/2014
30       continue
         !  SFM  begin  07/29/2014; for M.Gecu, elminate NANs
      else

      end if
   enddo
enddo
print*, 'maxval=',maxval(dPRRet%log10dNw)
print*, minval(dPRRet%log10dNw)
print*, 'Nw_MS vals=',maxval(dPRRet%MS%log10dNw), minval(dPRRet%MS%log10dNw)
!stop
!call closeenkffile2()
! close(31)
! close(32)
! close(33)
print*, 'after filtering'
print*, maxval(dprret%tb)
!print*, maxval(dprRet%emis), maxval(dprRet%MS%emis)
!stop
!print*, maxval(dPRRet%convtb)
31 format(53(F7.2,1x))
!  SFM  end    06/22/2014
do j=1,dPRData%n1c21
   do i=1,49
      if(dPRData%rainType(i,j)>=100) then
!diagnostic
!       write(*, '("early scan: ", i5, "  scene: ", i5, "  nodes: ", 5i5)') j, i, dPRData%node(1:5, i, j)
!end diagnostic
         do k=max(1,dPRData%node(1,i,j)),1+dPRData%node(5,i,j)
!            if(k < 1 .or. k > 88) write(*, '("bad k at: ", 3i10, "  min k: ", i10, "  max k: ", i10)') &
!             i, j, k, 1+dPRData%node(1,i,j), 1+dPRData%node(5,i,j)
            rrate3D(k,i,j)=sum(dPRRet%rrate(1:nmemb1,k,i,j))/nmemb1
            rrate3Dstd(k,i,j)=sqrt(sum((dPRRet%rrate(1:nmemb1,k,i,j)-          &
                 rrate3D(k,i,j))**2)/(nmemb1-1))
            pwc3D(k,i,j)=sum(dPRRet%pwc(1:nmemb1,k,i,j))/nmemb1
            d03D(k,i,j)=sum(dPRRet%d0(1:nmemb1,k,i,j))/nmemb1
            pwc3Dstd(k,i,j)=sqrt(sum((dPRRet%pwc(1:nmemb1,k,i,j)-              &
                 pwc3D(k,i,j))**2)/(nmemb1-1))
            zcKu3D(k,i,j)=sum(dPRRet%z13c(1:nmemb1,k,i,j))/nmemb1
!begin  WSO 8/28/14 if rrate3D is -99 then
            if(abs(rrate3D(k, i, j) - (-99)) < 1.) then
              rrate3D(k, i, j) = 0.
              rrate3Dstd(k, i, j) =  0.
              pwc3D(k, i, j) = 0.
              pwc3Dstd(k, i, j) = 0.
            endif
!end    WSO 8/28/14
         enddo
!begin  WSO 9/15/13 set to missing instead of -99
!diagnostic
!       write(*, '("early scan: ", i5, "  scene: ", i5, "  nbin: ", i5)') nbin
!end diagnostic
!         if(2+dPRData%node(5,i,j) < 1 .or. 2+dPRData%node(5,i,j) > 88) &
!          write(*, '("bad node 5+2at: ", 2i10, "  node5+2: ", i10, "  nbin: ", i10, "  nodes: ", 5i10)') &
!             i, j, 2+dPRData%node(5,i,j), nbin, (dPRData%node(l, i, j), l=1,5)
         rrate3D(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         rrate3Dstd(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         pwc3D(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         pwc3Dstd(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         d03D(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
!end    WSO 9/15/13
         pia13m=sum(dPRRet%pia13mod(i,j,1:nmemb1))/nmemb1
         pia13s=(sum((dPRRet%pia13mod(i,j,1:nmemb1)-pia13m)**2)/nmemb1)**.5
         sfcRain(i,j)=sum(dPRRet%sfcRainEns(i,j,1:nmemb1))/nmemb1
         sfcRainStd(i,j)=sqrt(sum((dPRRet%sfcRainEns(i,j,1:nmemb1)-            &
              sfcRain(i,j))**2)/(nmemb1-1))
!begin SJM 12/4/2014
         w10_out_NS(i,j) = sum(dPRRet%sfcWindEns(i,j,1:nmemb1))/nmemb1
         w10_rms_NS(i,j) = sqrt(sum((dPRRet%sfcWindEns(i,j,1:nmemb1)-w10_out_NS(i,j))**2)/nmemb1)
         !print*, i,j, w10_out_NS(i,j), w10_rms_NS(i,j)
         !w10_rms_NS(i,j) = sqrt(sum((dPRRet%sfcWindEns(i,j,1:nmemb1)-)/nmemb1
         !print '(2I5,2F8.2)', i,j,dPRData%envSfcWind(i,j), w10_out_NS(i,j)
!end SJM 12/4/2014

!begin  WSO 8/28/14 if sfcRain is -99, set sfcRain and its uncertainty to zero
         if(abs(sfcRain(i, j) - (-99)) < 1.) then
           sfcRain(i, j) = 0.
           sfcRainStd(i, j) = 0.
         endif
!end    WSO 8/28/24 
         piaOut(i,j)=pia13m

!begin  WSO 8/7/13 add liquid fractions in transition layer
         gatelength = 250.
!begin  WSO 12/30/13 set mu_mean = 2 regardless of values
!since all tables represent only mu = 2
!         mu_mean(i, j) = sum(mu_tab(radarRet%imu(1:nmemb1)))/nmemb1
         mu_mean(i, j) = 2.
!end    WSO 12/30/13

         if(dPRData%node(5, i, j) > dPRData%node(4,i,j)) then   !rain at surface

           sfcRainLiqFrac(i, j) = 1.0

         else if(dPRData%node(5, i, j) < dPRData%node(2,i,j)) then !snow at surface

           sfcRainLiqFrac(i, j) = 0.

         endif
         do  k=1+dPRData%node(2,i,j),1+dPRData%node(4,i,j)
!begin  WSO 9/5/13 add logic to account for lowest bin in mixed-phase layer
           if(k .le. 1 + dPRData%node(5, i, j)) then  !valid mixed-phase bin
!end    WSO 9/5/13
             depthBB = (dPRData%node(3,i,j) - dPRData%node(2,i,j)) * gatelength
             depthML = (dPRData%node(4,i,j) - dPRData%node(2,i,j)) * gatelength
             depth = (k - 1 - dPRData%node(2,i,j)) * gatelength

             if(dPRData%rainType(i,j)<200) then  !stratiform
                call interp_melt_percentages(depthBB, depthML, &
                     mu_mean(i, j), d03D(k, i, j), depth, mlwc_frac(k - dPRData%node(2,i,j), i, j), &
                     mrate_frac(k - dPRData%node(2,i,j), i, j))
             else  !convective or undefined
                mlwc_frac(k - dPRData%node(2,i,j), i, j) = depth / depthML
                mrate_frac(k - dPRData%node(2,i,j), i, j) = depth / depthML
             endif

             if(k == 1 + dPRData%node(5,i,j)) then
               sfcRainLiqFrac(i, j) = mrate_frac(k - dPRData%node(2,i,j), i, j)

               go to 200

             endif

           endif

         enddo
  200    continue

!end  WSO 8/7/13
      else

!begin  WSO 9/22/13 set to missing in clutter zone
!diagnostic
!       write(*, '("later scan: ", i5, "  scene: ", i5, "  nodes: ", 5i5, "  nbin: ", i5)') &
!        j, i, dPRData%node(1:5, i, j), nbin
!end diagnostic

         !Change from MG, 5/2/18
         !if(dPRData%badRayFlag(i,j) == 0)
         if(dPRData%badRayFlag(i,j) == 0 .and. &
             2+dPRData%node(5,i,j)>1) & 
         then   !valid non-raining point

!           if(2+dPRData%node(5,i,j) < 1 .or. 2+dPRData%node(5,i,j) > 88) &
!             write(*, '("bad node 5+2at: ", 2i10, "  node5+2: ", i10, "  nbin: ", i10, " nodes: ", 5i10, "  lat/lon: ", 2f10.4)') &
!             i, j, 2+dPRData%node(5,i,j), nbin, (dPRData%node(l, i, j), l=1,5), dPRData%xlat(i,j), dPRData%xlon(i,j)
           rrate3D(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
           rrate3Dstd(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
           pwc3D(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
           pwc3Dstd(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
           d03D(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         else                               !invalid nodes
           sfcRain(i,j)=missing_r4
           sfcRainStd(i,j)=missing_r4
           rrate3D(1:nbin,i,j) = missing_r4
           rrate3Dstd(1:nbin,i,j) = missing_r4
           pwc3D(1:nbin,i,j) = missing_r4
           pwc3Dstd(1:nbin,i,j) = missing_r4
           d03D(1:nbin,i,j) = missing_r4
         endif

!end    WSO 9/22/13

      endif
   end do
end do
print*, 'before mlw'

do j=1,dPRData%n1c21
   do i=1,49
      if(dPRData%rainType(i,j)>=100) then
         do k=max(1,dPRData%node(1,i,j)),1+dPRData%node(5,i,j)
            rrate3DMS(k,i,j)=sum(dPRRet%MS%rrate(1:nmemb1,k,i,j))/nmemb1
            rrate3DstdMS(k,i,j)=sqrt(sum((dPRRet%MS%rrate(1:nmemb1,k,i,j)-     &
                 rrate3DMS(k,i,j))**2)/(nmemb1-1))
            pwc3DMS(k,i,j)=sum(dPRRet%MS%pwc(1:nmemb1,k,i,j))/nmemb1
            d03DMS(k,i,j)=sum(dPRRet%MS%d0(1:nmemb1,k,i,j))/nmemb1
            pwc3DstdMS(k,i,j)=sqrt(sum((dPRRet%pwc(1:nmemb1,k,i,j)-            &
                 pwc3D(k,i,j))**2)/(nmemb1-1))
            zcKu3DMS(k,i,j)=sum(dPRRet%MS%zkuEns(1:nmemb1,k,i,j))/nmemb1
            zcKa3DMS(k,i,j)=sum(dPRRet%MS%zkaEns(1:nmemb1,k,i,j))/nmemb1
            !zcKa3DMS(k,i,j)=sum(dPRRet%z35mod0(1:nmemb1,k,i,j))/nmemb1
!begin  WSO 8/28/14 if rrate3DMS is -99 then
            if(abs(rrate3DMS(k, i, j) - (-99)) < 1.) then
              rrate3DMS(k, i, j) = 0.
              rrate3DstdMS(k, i, j) =  0.
              pwc3DMS(k, i, j) = 0.
              pwc3DstdMS(k, i, j) = 0.
            endif
!end    WSO 8/28/14
         enddo
!begin  WSO 9/15/13 set to missing instead of -99
         rrate3DMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         rrate3DstdMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         pwc3DMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         pwc3DstdMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
         d03DMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
!end    WSO 9/15/13
         sfcRainMS(i,j)=sum(dPRRet%MS%sfcRainEns(i,j,1:nmemb1))/nmemb1
         sfcRainStdMS(i,j)=sqrt(sum((dPRRet%MS%sfcRainEns(i,j,1:nmemb1)-       &
           sfcRainMS(i,j))**2)/(nmemb1-1))
!begin  WSO 8/28/14 if sfcRainMS is -99, set to sfcRainMS and its uncertainty to zero
         if(abs(sfcRainMS(i, j) - (-99)) < 1.) then
           sfcRainMS(i, j) = 0.
           sfcRainStdMS(i, j) = 0.
         endif
!end    WSO 8/28/14
         piaOutKuMS(i,j)=sum(dPRRet%MS%pia13mod(i,j,1:nmemb1))/nmemb1
         piaOutKaMS(i,j)=sum(dPRRet%MS%pia35mod(i,j,1:nmemb1))/nmemb1
         w10_out_MS(i,j) = sum(dPRRet%MS%sfcWindEns(i,j,1:nmemb1))/nmemb1 !SJM 2/5/15
         w10_rms_MS(i,j) = sqrt(sum((dPRRet%MS%sfcWindEns(i,j,1:nmemb1)-w10_out_MS(i,j))**2)/nmemb1)
         !print*, i,j, w10_out_MS(i,j), w10_rms_MS(i,j)
!begin  WSO 8/7/13 add liquid fractions in transition layer
         gatelength = 250.
!begin  WSO 12/30/13 set mu_meanMS = 2, since
!all tables only represent mu = 2
!         mu_meanMS(i, j) = sum(mu_tab(radarRet%imu(1:nmemb1)))/nmemb1
         mu_meanMS(i, j) = 2.
!end    WSO 12/30/13

         if(dPRData%node(5, i, j) > dPRData%node(4,i,j)) then   !rain at surface

           sfcRainLiqFracMS(i, j) = 1.0


         else if(dPRData%node(5, i, j) < dPRData%node(2,i,j)) then !snow at surface

           sfcRainLiqFracMS(i, j) = 0.

         endif
         do  k=1+dPRData%node(2,i,j),1+dPRData%node(4,i,j)
!begin  WSO 9/5/13 add logic to account for lowest bin in mixed-phase layer
           if(k .le. 1 + dPRData%node(5, i, j)) then  !valid mixed-phase bin
!end    WSO 9/5/13

             depthBB = (dPRData%node(3,i,j) - dPRData%node(2,i,j)) * gatelength
             depthML = (dPRData%node(4,i,j) - dPRData%node(2,i,j)) * gatelength
             depth = (k - 1 - dPRData%node(2,i,j)) * gatelength

             if(dPRData%rainType(i,j)<200) then  !stratiform
               call interp_melt_percentages(depthBB, depthML, &
                mu_meanMS(i, j), d03DMS(k, i, j), depth, mlwc_fracMS(k - dPRData%node(2,i,j), i, j), &
                mrate_fracMS(k - dPRData%node(2,i,j), i, j))
             else  !convective or undefined
                mlwc_fracMS(k - dPRData%node(2,i,j), i, j) = depth / depthML
                mrate_fracMS(k - dPRData%node(2,i,j), i, j) = depth / depthML
             endif


             if(k - 1 == dPRData%node(5,i,j)) then
               sfcRainLiqFracMS(i, j) = mrate_fracMS(k - dPRData%node(2,i,j), i, j)

               go to 300

             endif

           endif

         enddo
  300    continue

!end  WSO 8/7/13
      else

!begin  WSO 9/22/13 set to missing instead of -99

        !Change from MG, 5/2/18
        !if(dPRData%badRayFlag(i,j) == 0) 
         if(dPRData%badRayFlag(i,j) == 0 .and. &
             2+dPRData%node(5,i,j)>1) &
        then    !valid non-raining footprint


          rrate3DMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
          rrate3DstdMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
          pwc3DMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
          pwc3DstdMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
          d03DMS(2+dPRData%node(5,i,j):nbin,i,j) = missing_r4
        else
          sfcRainMS(i,j)=missing_r4
          sfcRainStdMS(i,j)=missing_r4
          rrate3DMS(1:nbin,i,j) = missing_r4
          rrate3DstdMS(1:nbin,i,j) = missing_r4
          pwc3DMS(1:nbin,i,j) = missing_r4
          pwc3DstdMS(1:nbin,i,j) = missing_r4
          d03DMS(1:nbin,i,j) = missing_r4
        endif
!end    WSO 9/22/13

      endif
   enddo
enddo
print*, 'before out'


40 format(14(F7.2,1x))
!print*, tb0(24,:,1)
!print*, tbMean(24,:,1)
!stop
nf=9


print*, 'ialg=',ialg
!  SFM  begin  12/13/2013; conditional to rewind dpr
call rewind_fs(ic)
IF (st_2adpr .EQ. 0) call rewind_dpr_fs(ic)

 
do i=1,49
   do j=1,dPRData%n1c21
      emiss2d(j,i,1) = sum(dprRet%MS%emis(i,j,1,1,1:nmemb1))/nmemb1
      emiss2d(j,i,2) = sum(dprRet%MS%emis(i,j,2,1,1:nmemb1))/nmemb1
      emiss2d(j,i,3) = sum(dprRet%MS%emis(i,j,1,2,1:nmemb1))/nmemb1
      emiss2d(j,i,4) = sum(dprRet%MS%emis(i,j,2,2,1:nmemb1))/nmemb1
      emiss2d(j,i,5) = sum(dprRet%MS%emis(i,j,1,3,1:nmemb1))/nmemb1
      emiss2d(j,i,6) = sum(dprRet%MS%emis(i,j,1,4,1:nmemb1))/nmemb1
      emiss2d(j,i,7) = sum(dprRet%MS%emis(i,j,2,4,1:nmemb1))/nmemb1
      emiss2d(j,i,8) = sum(dprRet%MS%emis(i,j,1,5,1:nmemb1))/nmemb1
      emiss2d(j,i,9) = sum(dprRet%MS%emis(i,j,2,5,1:nmemb1))/nmemb1
      emiss2d(j,i,10) = sum(dprRet%MS%emis(i,j,1,6,1:nmemb1))/nmemb1
      emiss2d(j,i,11) = sum(dprRet%MS%emis(i,j,2,6,1:nmemb1))/nmemb1
      emiss2d(j,i,12)=emiss2d(j,i,10)
      emiss2d(j,i,13)=emiss2d(j,i,10)
      pRate(j,i,:)=rrate3DMS(:,i,j)
      swc3D(j,i,:)=pwc3DMS(:,i,j)
      airTemp3D(j,i,:)=dPRData%envTemp(:,i,j)
      sfcTemp(j,i)=dPRData%envSfcTemp(i,j)
      press3D(j,i,:)=dPRData%envPress(:,i,j)
      qv3D(j,i,:)=dPRData%envQv(:,i,j)
      z13(j,i,:)=zcKu3DMS(:,i,j)
      do k=1,88
         if(dPRData%rainType(i,j)>=100) then
            if(k>=dPRData%node(1,i,j).and.k<=dPRData%node(5,i,j)) then
               nw3d(j,i,k)=sum(dPRRet%MS%log10dNw(1:nmemb1,k,i,j))/nmemb1
            else
               nw3d(j,i,k)=-0.5
            endif
         else
            nw3d(j,i,k)=-0.5
         endif
      enddo
      sfcBin(j,i)= dprData%binRealSurface(i,j)
      cldw3d(j,i,:)=0.
      if(dPRData%rainType(i,j)>=100) then
         call getcldwfromcoeff(dPRRet%cldwcoeff(i,j,:,:),                      &
              dPRData%freezH(i,j)/1000.,cldwprof, dPRData%node(:,i,j),         &
              radarData%dr,dPRData%localZenithAngle(i,j),nmemb1)
         do k = 1, 88
           if(cldwprof(k) < 0.) then
               cldwprof(k) = 0.
            endif
         enddo
         cldw3d(j,i,:)=cldwprof
      endif
      tbobsT(j,i,1:9)=tbobs(i,j,1:9)
      tbobsT(j,i,10:13)=hFreqPRg(i,j,1:4)
      pType(j,i)=dPRData%rainType(i,j)
      binNodes(j,i,:)=dPRData%node(:,i,j)
      clutFree(j,i)=binNodes(j,i,5)
      do k = 1, 10
         envNode(j,i,k)= 88 - nint((env_levs(k)/&
              cos(dPRData%localZenithAngle(i, j) * pi / 180.)) * 4.)-1
      enddo
   enddo
enddo
nfreq=8
i=24
j=1
do k = 1, 10
   env_nodes(k, i) = 88 - nint((env_levs(k)/cos(dPRData%localZenithAngle(i, j) * pi / 180.)) * 4.)
   !       write(*, '("i: ", i5, "  k: ", i5, "  zenangl: ", f8.4, "  env_node: ", &
   !        i5)') i, k, dPRData%localZenithAngle(i, j), env_nodes(k, i)
enddo
do k=1,10
   print*, maxval(dPRData%envTemp(env_nodes(k,24),:,:)), minval(dPRData%envTemp(env_nodes(k,24),:,:)), env_nodes(k,24)
enddo
!stop
!idir=1
print*, 'idir_inside=', idir
!idir=-idir
!print*, maxval(nw3d)
!print*, minval(nw3d)
!stop
print*,iiad
if(iiad==1) then
   call frteprep(binNodes,pRate,swc3d,pRateOut,swcOut,nwOut,z13,emiss2d,&
        envNode,pType,&
        qv3D,press3D,airTemp3D,nw3d,tbsim,nscans,npixs,nlev,nchans,idir,&
        sfcBin,sfcTemp,cldw3d,tbobsT,nfreq,clutFree,dPRData%n1c21)
   
   do i=2,48
      do j=1,dPRData%n1c21
         do k=1,13
            oe_tbs(j,i,k,4)=sum(dPRRet%MS%tb(i,j,ipolG(k),ifreqG(k),1:1*nmemb1))/(nmemb1)
         end do
         if(oe_tbs(j,i,1,2)>50) then
            do k=1,13
               dPRRet%MS%tb(i,j,ipolG(k),ifreqG(k),1:1*nmemb1)=oe_tbs(j,i,k,2)
               tb0MS(i,j,k)=sum(dPRRet%MS%tb(i,j,ipolG(k),&
                    ifreqG(k),1:nmemb1))/nmemb1
               tbNoOceanMS(i,j,k)=sum(dPRRet%MS%tb(i,j,ipolG(k),&
                    ifreqG(k),1:nmemb1))/nmemb1
            end do
         end if
      end do
   end do
   do i=2,48
      do j=1,dPRData%n1c21
         do k=1,min(binNodes(j,i,5),binNodes(j,i,4))+1
            rrate3DMS(k,i,j)=pRateOut(j,i,k)
            pwc3DMS(k,i,j)=swcOut(j,i,k)
         enddo
         do k=min(binNodes(j,i,5),binNodes(j,i,2))+1,&
              min(binNodes(j,i,5),binNodes(j,i,3))+1
            !xf=1-(k-binNodes(j,i,2)-1.)/(binNodes(j,i,3)-binNodes(j,i,2)+1e-5)
            !rrate3DMS(k,i,j)=xf*pRateOut(j,i,k)+(1-xf)*pRate(j,i,k)
            !pwc3DMS(k,i,j)=xf*swcOut(j,i,k)+(1-xf)*swc3D(j,i,k)
         enddo
         do k=1,88
            if(dPRData%rainType(i,j)>=100) then
               dPRRet%MS%log10dNw(1:nmemb1,k,i,j)=&
                    dPRRet%MS%log10dNw(1:nmemb1,k,i,j)!-nw3d(j,i,k)+nwOut(j,i,k)
            endif
         enddo
      enddo
   enddo
endif

if(iconv==1) then
   call convallfreq(actOb,tb0(:,:,1:9),tbMean(:,:,1:9),&
        invCovTb(:,:,1:9,1:9),&
        tbObs(:,:,1:9),tbout2D(:,:,1:9),dfdtb(:,:,1:9),49,dPRData%n1c21,&
        dPRData%xlat(:,1:dPRData%n1c21), dPRData%xlon(1:49,1:dPRData%n1c21),&
        scLonPR(1:49,1:dPRData%n1c21),scLatPR(1:49,1:dPRData%n1c21),&
        wfmap(1:49,1:dPRData%n1c21),&
        fpmap(1:49,1:dPRData%n1c21,1:9), &
        nf,fobj,ifreqG,sfcRain(1:49,1:dPRData%n1c21),ialg)
   !print*, 'tbout2d_nadir'
   !print*, tbout2D(24,:,1)
   !stop
   call convallfreq(actOb,tbNoOcean(:,:,1:9),tbNoOcean(:,:,1:9),&
        invCovTb(:,:,1:9,1:9),&
        tbObs(:,:,1:9),tbout2DNoOcean(:,:,1:9),dfdtb(:,:,1:9),&
        49,dPRData%n1c21,&
        dPRData%xlat(:,1:dPRData%n1c21), dPRData%xlon(1:49,1:dPRData%n1c21),&
        scLonPR(1:49,1:dPRData%n1c21),scLatPR(1:49,1:dPRData%n1c21),&
        wfmap(1:49,1:dPRData%n1c21),&
        fpmapN(1:49,1:dPRData%n1c21,1:9), &
        nf,fobj,ifreqG(1:9),sfcRain(1:49,1:dPRData%n1c21),ialg)
   
   call convallfreq(actOb,tb0MS(:,:,1:9),tbMean(:,:,1:9),&
        invCovTb(:,:,1:9,1:9),&
        tbObs(:,:,1:9),tbout2DMS(:,:,1:9),dfdtb(:,:,1:9),49,dPRData%n1c21,&
        dPRData%xlat(:,1:dPRData%n1c21), dPRData%xlon(1:49,1:dPRData%n1c21),&
        scLonPR(1:49,1:dPRData%n1c21),scLatPR(1:49,1:dPRData%n1c21),&
        wfmap(1:49,1:dPRData%n1c21),&
       fpmap(1:49,1:dPRData%n1c21,1:9), &
        nf,fobj,ifreqG,sfcRain(1:49,1:dPRData%n1c21),ialg)
   
   call convallfreq(actOb,tbNoOceanMS(:,:,1:9),tbNoOceanMS(:,:,1:9),&
        invCovTb(:,:,1:9,1:9),&
        tbObs(:,:,1:9),tbout2DNoOceanMS(:,:,1:9),dfdtb(:,:,1:9),&
        49,dPRData%n1c21,&
        dPRData%xlat(:,1:dPRData%n1c21), dPRData%xlon(1:49,1:dPRData%n1c21),&
        scLonPR(1:49,1:dPRData%n1c21),scLatPR(1:49,1:dPRData%n1c21),&
        wfmap(1:49,1:dPRData%n1c21),&
        fpmapN(1:49,1:dPRData%n1c21,1:9), &
        nf,fobj,ifreqG(1:9),sfcRain(1:49,1:dPRData%n1c21),ialg)
endif

print*, 'oe_tbs'
!print*, oe_tbs(:,24,7,1:2)
!stop

!stop
print*, dPRData%n1c21
do j=1,dPRData%n1c21
   if(ialg==2) then
      call frominputt(st_2adpr)
      call copyscantimet(j-1)
      !call writescant()
   else
      !print*, j, j+icL, ichunk
      call frominput_fs(st_2adpr,flagScanPattern)
      !print*, 'FSP=',j, flagScanPattern
      flagScanPattern_0=flagScanPattern
      call copyscantime_fs(j-1)
      !--fs_300--!
      !call frominput_fs_300(j-1,st_2adpr)
      !call copyscantime_fs_300(j-1,j-1)
      !--fs_300--!
      !call writescan_fs()
   endif
   if(flagScanPattern.eq.0) then
      do i=1,12
         sfcRainMS(i,j)=missing_r4
         sfcRainStdMS(i,j)=missing_r4
         rrate3DMS(:,i,j) = missing_r4
         rrate3DstdMS(:,i,j) = missing_r4
         pwc3DMS(:,i,j) = missing_r4
         pwc3DstdMS(:,i,j) = missing_r4
         d03DMS(:,i,j) = missing_r4
         dm3dms_a(:,i,j)=missing_r4
      enddo
      do i=38,49
         sfcRainMS(i,j)=missing_r4
         sfcRainStdMS(i,j)=missing_r4
         rrate3DMS(:,i,j) = missing_r4
         rrate3DstdMS(:,i,j) = missing_r4
         pwc3DMS(:,i,j) = missing_r4
         pwc3DstdMS(:,i,j) = missing_r4
         d03DMS(:,i,j) = missing_r4
         dm3dms_a(:,i,j)=missing_r4
      enddo
   endif
   if(ialg==1) then
      do i=1,49
         call copyw10small_fs(w10_out_MS(i,j),i-1) !SJM 12/9/2014
         call copyw10smallsigma_fs(w10_rms_MS(i,j),i-1) !SJM 12/9/2014
         !call copyw10small_fs_300(j-1,w10_out_MS(i,j),i-1) !SJM 12/9/2014
         !call copyw10smallsigma_fs_300(j-1,w10_rms_MS(i,j),i-1) !SJM 12/9/2014
      enddo
   endif
   if(ialg==2) then
      call setlatlons1t( dPRData%xlat(:,j), dPRData%xlon(:,j),                &
           sfcRain(:,j),sfcRainStd(:,j),piaOut(:,j))
   else
      call setlatlons1_fs( dPRData%xlat(:,j), dPRData%xlon(:,j),                &
           sfcRain(:,j),sfcRainStd(:,j),piaOut(:,j))
      call setlatlons2_fs( dPRData%xlat(:,j), dPRData%xlon(:,j),                 &
           sfcRainMS(:,j),sfcRainStdMS(:,j),piaOutKuMS(:,j),piaOutKaMS(:,j),&
           flagScanPattern)
      !call setlatlons1_fs_300(j-1, dPRData%xlat(:,j), dPRData%xlon(:,j),          &
      !     sfcRain(:,j),sfcRainStd(:,j),piaOut(:,j))
      !call setlatlons2_fs_300(j-1, dPRData%xlat(:,j), dPRData%xlon(:,j),             &
      !     sfcRainMS(:,j),sfcRainStdMS(:,j),piaOutKuMS(:,j),piaOutKaMS(:,j))
   endif
   if(flagScanPattern_0.ne.flagScanPattern) then
      print*, 'line', 1038
      stop
   end if

   do i=1,49
      if(ialg==1) then
         !begin  WSO 9/28/13 added rain flag that includes bad scan as missing
         call copyrainflags1_fs(dPRData%rainFlagBad(i,j), i-1)
         call copyioqualitys1_fs(dPRData%ioqualityflagku(i,j), i-1)
         call copysnowices1_fs(dPRData%snowIceCover(i,j), i-1)
         !---fs_300--!
         !call copyrainflags1_fs_300(j-1,dPRData%rainFlagBad(i,j), i-1)
         !call copyioqualitys1_fs_300(j-1,dPRData%ioqualityflagku(i,j), i-1)
         !call copysnowices1_fs_300(j-1,dPRData%snowIceCover(i,j), i-1)
         !--fs_300--!
         !begin  WSO 2/8/17 new output variables
         call copyinitnws1_fs(initnw_NS(:, i, j), dPRRet%n9(:, i, j), i-1)
         call copyprincomps1_fs(princomp_NS(:, i, j), i-1)
         call copyprofclasss1_fs(profclass_NS(i, j), i-1)
         call copysurfprecipbiasratios1_fs(surfprecipbiasratio_NS(i, j), i-1)
         call copysubfootvariabilitys1_fs(subfootvariability_NS(i, j), i-1)
         call copymultiscatcalcs1_fs(multiscatcalc_NS(i, j), i-1)
         call copymultiscatsurfaces1_fs(multiscatsurface_NS(i, j), i-1)
         call copymultiscatcalcs1_fs(msFlag(i, j), i-1)
         call copymultiscatsurfaces1_fs(dZms(i, j), i-1)
         !--fs_300--!
         !call copyinitnws1_fs_300(j-1,initnw_NS(:, i, j), dPRRet%n9(:, i, j), i-1)
         !call copyprincomps1_fs_300(j-1,princomp_NS(:, i, j), i-1)
         !call copyprofclasss1_fs_300(j-1,profclass_NS(i, j), i-1)
         !call copysurfprecipbiasratios1_fs_300(j-1,surfprecipbiasratio_NS(i, j), i-1)
         !call copysubfootvariabilitys1_fs_300(j-1,subfootvariability_NS(i, j), i-1)
         !call copymultiscatcalcs1_fs_300(j-1,multiscatcalc_NS(i, j), i-1)
         !call copymultiscatsurfaces1_fs_300(j-1,multiscatsurface_NS(i, j), i-1)
         !--fs_300--!
         !end    WSO 2/8/17
      else
         call copyrainflags1t(dPRData%rainFlagBad(i,j), i-1)
         call copyioqualitys1t(dPRData%ioqualityflagku(i,j), i-1)
         call copysnowices1t(dPRData%snowIceCover(i,j), i-1)
         call copyinitnws1t(initnw_NS(:, i, j), dPRRet%n9(:, i, j), i-1)
         call copyprincomps1t(princomp_NS(:, i, j), i-1)
         call copyprofclasss1t(profclass_NS(i, j), i-1)
         call copysurfprecipbiasratios1t(surfprecipbiasratio_NS(i, j), i-1)
         call copysubfootvariabilitys1t(subfootvariability_NS(i, j), i-1)
         call copymultiscatcalcs1t(multiscatcalc_NS(i, j), i-1)
         call copymultiscatsurfaces1t(multiscatsurface_NS(i, j), i-1)
      endif
      !begin  WSO 9/19/13 more accurate environmental bin calculation
      do k = 1, 10
         env_nodes(k, i) = 88 - nint((env_levs(k)/cos(dPRData%localZenithAngle(i, j) * pi / 180.)) * 4.)
         !       write(*, '("i: ", i5, "  k: ", i5, "  zenangl: ", f8.4, "  env_node: ", &
         !        i5)') i, k, dPRData%localZenithAngle(i, j), env_nodes(k, i)
      enddo
      !end    WSO 9/19/13
      
      if(ialg==2) then
         call copysigmapias1t(dPRData%srtsigmaPIAku(i, j), i-1)
         call copysigmazeros1t(dPRData%sigmaZeroKu(i, j), i-1)
      else
         call copysigmapias1_fs(dPRData%srtsigmaPIAku(i, j), i-1)
         call copysigmazeros1_fs(dPRData%sigmaZeroKu(i, j), i-1)
         !--fs_300--!
         !call copysigmapias1_fs_300(j-1,dPRData%srtsigmaPIAku(i, j), i-1)
         !call copysigmazeros1_fs_300(j-1,dPRData%sigmaZeroKu(i, j), i-1)
         !--fs_300--!
      endif

      if(dPRData%rainType(i,j)>=100) then
         !print*,minval(dPRRet%cldwcoeff(i,j,:,:))  !MG 09/26/13
         call getcldwfromcoeff(dPRRet%cldwcoeff(i,j,:,:),                      &
              dPRData%freezH(i,j)/1000.,cldwprof, dPRData%node(:,i,j),         &
              radarData%dr,dPRData%localZenithAngle(i,j),nmemb1)
!begin  WSO 9/17/13 remove negative cloud water contents and standardize missing
!                  values
        do k = 1, 88
          if(cldwprof(k) < 0. .and. cldwprof(k) > -90.) then
            cldwprof(k) = 0.
          else if(cldwprof(k) < -90.) then
            cldwprof(k) = missing_r4
          endif
        end do
!end    WSO 9/17/13
      else
         cldwprof=0
      endif
      if(ialg==2) then
         call copycldwaters1t(cldwprof,i-1)
         !begin  WSO 9/15/13 add missing for cloud ice profiles
         cldiprof = missing_r4
         call copycldices1t(cldiprof,i-1)
         !end  WSO 9/15/13 
         call copyrrates1t(rrate3D(:,i,j),rrate3Dstd(:,i,j),i-1)
         call copypwcs1t(pwc3D(:,i,j),pwc3Dstd(:,i,j),i-1)
         !begin  WSO 8/7/13
         call copylwcfracs1t(mlwc_frac(:,i,j),mrate_frac(:,i,j),i-1)
         call copysfcrainliqfracs1t(sfcRainLiqFrac(i, j), i-1)
         !end    WSO 8/7/13
         call copyd0s1t(d03D(:,i,j),i-1)
         call copyzckus1t(zcKu3D(:,i,j),i-1)
         call copynodess1t(dPRData%node(:,i,j),i-1)
      else
         call copycldwaters1_fs(cldwprof,i-1)
         cldiprof = missing_r4
         call copycldices1_fs(cldiprof,i-1)
         call copyrrates1_fs(rrate3D(:,i,j),rrate3Dstd(:,i,j),i-1)
         call copypwcs1_fs(pwc3D(:,i,j),pwc3Dstd(:,i,j),i-1)
         call copy_tot_to_liqrate_ku(i-1, rrate3D(:,i,j), dPRData%node(:,i,j))
         call copy_tot_to_liqwatercont_ku(i-1, pwc3D(:,i,j), dPRData%node(:,i,j))
         call copylwcfracs1_fs(mlwc_frac(:,i,j),mrate_frac(:,i,j),i-1)
         if(sfcRain(i,j).ge.-0.001) then
            call copysfcrainliqfracs1_fs(sfcRain(i,j)*sfcRainLiqFrac(i, j), i-1)
         else
            call copysfcrainliqfracs1_fs(missing_r4, i-1)
         endif
         call copyd0s1_fs(d03D(:,i,j),i-1)
         call copyd0s1_a_fs(dm3d_a(:,i,j),i-1)  ! apriori dm
         call copyd0s2_a_fs(dm3dms_a(:,i,j),i-1)  ! apriori dm
         call copyzckus1_fs(zcKu3D(:,i,j),i-1)
         call copynodess1_fs(dPRData%node(:,i,j),i-1)
         !--fs_300--!
         !call copycldwaters1_fs_300(j-1,cldwprof,i-1)
         !cldiprof = missing_r4
         !call copycldices1_fs_300(j-1,cldiprof,i-1)
         !call copyrrates1_fs_300(j-1,rrate3D(:,i,j),rrate3Dstd(:,i,j),i-1)
         !call copypwcs1_fs_300(j-1,pwc3D(:,i,j),pwc3Dstd(:,i,j),i-1)
         !call copylwcfracs1_fs_300(j-1,mlwc_frac(:,i,j),mrate_frac(:,i,j),i-1)
         !call copysfcrainliqfracs1_fs_300(j-1,sfcRainLiqFrac(i, j), i-1)
         !call copyd0s1_fs_300(j-1,d03D(:,i,j),i-1)
         !call copyzckus1_fs_300(j-1,zcKu3D(:,i,j),i-1)
         !call copynodess1_fs_300(j-1,dPRData%node(:,i,j),i-1)
         !--fs_300--!
         call estimated_sfc_precip1(i-1, rrate3D(:,i,j),rrate3Dstd(:,i,j),&
              sfcRain(i,j), dprData%binRealSurface(i,j), &
              dprData%binZeroDegree(i,j), dprData%binClutterFree(i,j),&
              pType(j,i),sfcRainLiqFrac(i, j))
      endif
         
!begin  WSO 8/19/13 change dNw to Nw and add mu
      if(dPRData%rainType(i,j)>=100) then
         do k=1,88
            if(k>=dPRData%node(1,i,j).and.k<=dPRData%node(5,i,j)) then
               log10NwMean(k)=sum(dPRRet%log10dNw(1:nmemb1,k,i,j))/nmemb1 + &
                    log10(8.e+6)
               log10NwMean_a(k)=nw3d_a(k,i,j) + &
                    log10(8.e+6)
               mu_mean_prof(k) = mu_mean(i, j)
            else
               log10NwMean(k) = missing_r4
               log10NwMean_a(k) = missing_r4
               mu_mean_prof(k) = missing_r4
            end if
         enddo
         !print*, 'log10Nw',log10NwMean
         !print*, dPRData%node(:,i,j)
         !print*, dPRData%zku1c21(dPRData%node(1,i,j):dPRData%node(5,i,j),i,j)
      else
         log10NwMean = missing_r4
         log10NwMean_a = missing_r4
         mu_mean_prof = missing_r4
      endif

!end    WSO 8/19/13
      !print*, dPRRet%n9(:,i,j)
      if(ialg==2) then 
         call copylognws1t( log10NwMean,dPRRet%n9(:,i,j),i-1)
         call copymus1t( mu_mean_prof, dPRRet%n9(:,i,j),i-1)
         call copypreciptypet(dPRData%raintype(i,j),i-1)
         call copyw10t(w10_out_NS(i,j),i-1) !modified SJM 12/4/2014
         call copyw10sigmat(w10_rms_NS(i,j),i-1) !modified SJM 12/4/2014
         !begin  WSO 8/30/13 update to specify environmental nodes
         call copyenvtemps1t(dPRData%envTemp(:,i,j),env_nodes(:,i),i-1)
         call copysfcairtemps1t(dPRData%envSfcTemp(i,j),i-1)
         call copyenvpresss1t(dPRData%envPress(:,i,j),env_nodes(:,i),i-1)
         call copysfcairpresss1t(dPRData%envSfcPress(i,j),i-1)
         call copyenvqvs1t(dPRData%envQv(:,i,j),env_nodes(:,i),i-1)
         call copyenvsfqvs1t(dPRData%envQv(:,i,j),i-1)
         call copyskintemps1t(dPRData%envSknTemp(i,j),i-1)
         call copyskintempsigmas1t(skintempsigma_NS(i, j), i-1)
         call copycolumnvaporsigmas1t(columnvaporsigma_NS(i, j), i-1)
         call copycolumncloudliqsigmas1t(columncloudliqsigma_NS(i, j), i-1)
         call copyalgotypes1t(algotype_NS(i, j), i-1)
         call copyerrorofdatafits1t(errorofdatafit_NS(i, j), i-1)
      else
         !call copylognws1_fs( log10NwMean,dPRRet%n9(:,i,j),i-1)
         call copynws1_fs(log10NwMean, i-1)
         call copynws1_a_fs(log10NwMean_a, i-1)  ! apriori
         call copynws2_a_fs(log10NwMean_a, i-1)  ! apriori
         call copymus1_fs( mu_mean_prof, dPRRet%n9(:,i,j),i-1)
         call copypreciptype(dPRData%raintype(i,j),i-1)
         call copyw10_fs(w10_out_NS(i,j),i-1) !modified SJM 12/4/2014
         call copyw10sigma_fs(w10_rms_NS(i,j),i-1) !modified SJM 12/4/2014
         call copyenvtemps1_fs(dPRData%envTemp(:,i,j),env_nodes(:,i),i-1)
         call copysfcairtemps1_fs(dPRData%envSfcTemp(i,j),i-1)
         call copyenvpresss1_fs(dPRData%envPress(:,i,j),env_nodes(:,i),i-1)
         call copysfcairpresss1_fs(dPRData%envSfcPress(i,j),i-1)
         call copyenvqvs1_fs(dPRData%envQv(:,i,j),env_nodes(:,i),i-1)
         call copyenvsfqvs1_fs(dPRData%envQv(:,i,j),i-1)
         call copyskintemps1_fs(dPRData%envSknTemp(i,j),i-1)
         call copyskintempsigmas1_fs(skintempsigma_NS(i, j), i-1)
         call copycolumnvaporsigmas1_fs(columnvaporsigma_NS(i, j), i-1)
         call copycolumncloudliqsigmas1_fs(columncloudliqsigma_NS(i, j), i-1)
         call copyalgotypes1_fs(algotype_NS(i, j), i-1)
         call copyerrorofdatafits1_fs(errorofdatafit_NS(i, j), i-1)
! insert new IO here
         call copy_oepianonrain_kugmi(dPRData%OEpiaNonRain(:,i,j), i-1)
         call copy_oecloudliqpath_kugmi(dPRData%OECloudLiqPath(i,j), i-1)
         call copy_oecloudicepath_kugmi(dPRData%OECloudLiqPath(i,j), i-1)
         call copy_oeqv_kugmi(dPRData%OEQv(:,i,j),env_nodes(:,i), i-1)
         call copy_oetemp_kugmi(dPRData%OETemp(:,i,j),env_nodes(:,i), i-1)
         call copy_oecloud_kugmi(dPRData%OECloud(:,i,j), i-1)
         call copy_oecloudliqsigma_kugmi(dPRData%OEcloudLiqSigma(i,j), i-1)
         call copy_oesfcwind_kugmi(dPRData%OESfcWind(i,j), i-1)
         call copy_oesfcwindsigma_kugmi(dPRData%OESfcWindSigma(i,j), i-1)
         call copy_oeskntemp_kugmi(dPRData%OESknTemp(i,j), i-1)
         call copy_oeskintempsigma_kugmi(dPRData%OEskinTempSigma(i,j), i-1)
         call copy_oesfctemp_kugmi(dPRData%OESfcTemp(i,j), i-1)
         call copy_oesfcqv_kugmi(dPRData%OESfcQv(i,j), i-1)
         call copy_oetpw_kugmi(dPRData%OEtpw(i,j), i-1)
         call copy_oetpwsigma_kugmi(dPRData%OEtpwSigma(i,j), i-1)
         call copy_oechisq_kugmi(dPRData%OEchiSq(i,j), i-1)
         call copy_oesimtbnonrain_kugmi(dPRData%OEsimTbNonRain(:,i,j), i-1)
         call copy_oeemis_kugmi(dPRData%OEemis(:,i,j), i-1)
         call copy_oeemissigma_kugmi(dPRData%OEemisSigma(:,i,j), i-1)
         call copy_oeemisa_kugmi(dPRData%OEemisA(:,i,j), i-1)
         call copy_oestype_kugmi(dPRData%OEstype(i,j), i-1)
         !print*, flagScanPattern, i, ((flagScanPattern.eq.0).and.(i.le.12.or.i.ge.38)) 


         !call copy_oepianonrain_kukagmi(dPRData%OEpiaNonRain(:,i,j), i-1)
         !call copy_oeqv_kukagmi(dPRData%OEQv(:,i,j),env_nodes(:,i), i-1)
         !call copy_oetemp_kukagmi(dPRData%OETemp(:,i,j),env_nodes(:,i), i-1)
         !call copy_oecloud_kukagmi(dPRData%OECloud(:,i,j), i-1)
         !call copy_oecloudicepath_kukagmi(dPRData%OECloudLiqPath(i,j), i-1)
         !call copy_oecloudliqpath_kukagmi(dPRData%OECloudLiqPath(i,j), i-1)
         !call copy_oecloudliqsigma_kukagmi(dPRData%OEcloudLiqSigma(i,j), i-1)
         !call copy_oesfcwind_kukagmi(dPRData%OESfcWind(i,j), i-1)
         !call copy_oesfcwindsigma_kukagmi(dPRData%OESfcWindSigma(i,j), i-1)
         !call copy_oeskntemp_kukagmi(dPRData%OESknTemp(i,j), i-1)
         !call copy_oeskintempsigma_kukagmi(dPRData%OEskinTempSigma(i,j), i-1)
         !call copy_oesfctemp_kukagmi(dPRData%OESfcTemp(i,j), i-1)
         !call copy_oesfcqv_kukagmi(dPRData%OESfcQv(i,j), i-1)
         !call copy_oetpw_kukagmi(dPRData%OEtpw(i,j), i-1)
         !call copy_oetpwsigma_kukagmi(dPRData%OEtpwSigma(i,j), i-1)
         !call copy_oechisq_kukagmi(dPRData%OEchiSq(i,j), i-1)
         !call copy_oesimtbnonrain_kukagmi(dPRData%OEsimTbNonRain(:,i,j), i-1)
         !call copy_oeemis_kukagmi(dPRData%OEemis(:,i,j), i-1)
         !call copy_oeemissigma_kukagmi(dPRData%OEemisSigma(:,i,j), i-1)
         !call copy_oeemisa_kukagmi(dPRData%OEemisA(:,i,j), i-1)
         !call copy_oestype_kukagmi(dPRData%OEstype(i,j), i-1)
         !

         !--fs_300--!
         !call copylognws1_fs_300(j-1, log10NwMean,dPRRet%n9(:,i,j),i-1)
         !call copymus1_fs_300(j-1, mu_mean_prof, dPRRet%n9(:,i,j),i-1)
         !call copypreciptype(dPRData%raintype(i,j),i-1)
         !call copyw10_fs_300(j-1,w10_out_NS(i,j),i-1) !modified SJM 12/4/2014
         !call copyw10sigma_fs_300(j-1,w10_rms_NS(i,j),i-1) !modified SJM 12/4/2014
         !call copyenvtemps1_fs_300(j-1,dPRData%envTemp(:,i,j),env_nodes(:,i),i-1)
         !call copysfcairtemps1_fs_300(j-1,dPRData%envSfcTemp(i,j),i-1)
         !call copyenvpresss1_fs_300(j-1,dPRData%envPress(:,i,j),env_nodes(:,i),i-1)
         !call copysfcairpresss1_fs_300(j-1,dPRData%envSfcPress(i,j),i-1)
         !call copyenvqvs1_fs_300(j-1,dPRData%envQv(:,i,j),env_nodes(:,i),i-1)
         !call copyenvsfqvs1_fs_300(j-1,dPRData%envQv(:,i,j),i-1)
         !call copyskintemps1_fs_300(j-1,dPRData%envSknTemp(i,j),i-1)
         !call copyskintempsigmas1_fs_300(j-1,skintempsigma_NS(i, j), i-1)
         !call copycolumnvaporsigmas1_fs_300(j-1,columnvaporsigma_NS(i, j), i-1)
         !call copycolumncloudliqsigmas1_fs_300(j-1,columncloudliqsigma_NS(i, j), i-1)
         !call copyalgotypes1_fs_300(j-1,algotype_NS(i, j), i-1)
         !call copyerrorofdatafits1_fs_300(j-1,errorofdatafit_NS(i, j), i-1)
         !--fs_300--!
      endif
!end    WSO 8/30/13
      !stype = LUT%land_class_map(mod(floor((DPRData%xlon(i,j)+180.)/360.*5760.),5760)+1, 2880-floor((DPRData%xlat(i,j)+90.)/180.*2880.)) !SJM 9/9/15'
      jj=2880-floor((DPRData%xlat(i,j)+90.)/180.*2880.)
      if(jj .lt. 1) jj=1
      if(jj .gt. 2880) jj = 2880
      ii=floor((DPRData%xlon(i,j)+180.)/360.*5760.)+1
      if(ii .lt. 1) ii = 1
      if(ii .gt. 5760) ii = 5760
      if(dPRData%snowIceCover(i,j) .eq. 0) then
        stype = LUT%land_class_map_bare(ii,jj) !SJM 9/9/15
      else
        stype = LUT%land_class_map_snow(ii,jj) !SJM 9/9/15
      endif
      if(dprRet%emis(i,j,1,1,1) .gt. 0.) then
         !print*, dprRet%emis(i,j,1,1,1:nmemb1)
         emissoutL(i,j,1) = sum(dprRet%emis(i,j,1,1,1:nmemb1))/nmemb1
         emissoutL(i,j,2) = sum(dprRet%emis(i,j,2,1,1:nmemb1))/nmemb1
         emissoutL(i,j,3) = sum(dprRet%emis(i,j,1,2,1:nmemb1))/nmemb1
         emissoutL(i,j,4) = sum(dprRet%emis(i,j,2,2,1:nmemb1))/nmemb1
         emissoutL(i,j,5) = sum(dprRet%emis(i,j,1,3,1:nmemb1))/nmemb1
         emissoutL(i,j,6) = sum(dprRet%emis(i,j,1,4,1:nmemb1))/nmemb1
         emissoutL(i,j,7) = sum(dprRet%emis(i,j,2,4,1:nmemb1))/nmemb1
         emissoutL(i,j,8) = sum(dprRet%emis(i,j,1,5,1:nmemb1))/nmemb1
         emissoutL(i,j,9) = sum(dprRet%emis(i,j,2,5,1:nmemb1))/nmemb1
         emissoutL(i,j,10) = sum(dprRet%emis(i,j,1,6,1:nmemb1))/nmemb1
         emissoutL(i,j,11) = sum(dprRet%emis(i,j,2,6,1:nmemb1))/nmemb1
         emissoutL(i,j,12:13) = emissoutL(i,j,10)
         
         emis_rms_NS(i,j,1) = sqrt(sum((dprRet%emis(i,j,1,1,1:nmemb1)-emissoutL(i,j,1))**2)/nmemb1)
         emis_rms_NS(i,j,2) = sqrt(sum((dprRet%emis(i,j,2,1,1:nmemb1)-emissoutL(i,j,2))**2)/nmemb1)
         emis_rms_NS(i,j,3) = sqrt(sum((dprRet%emis(i,j,1,2,1:nmemb1)-emissoutL(i,j,3))**2)/nmemb1)
         emis_rms_NS(i,j,4) = sqrt(sum((dprRet%emis(i,j,2,2,1:nmemb1)-emissoutL(i,j,4))**2)/nmemb1)
         emis_rms_NS(i,j,5) = sqrt(sum((dprRet%emis(i,j,1,3,1:nmemb1)-emissoutL(i,j,5))**2)/nmemb1)
         emis_rms_NS(i,j,6) = sqrt(sum((dprRet%emis(i,j,1,4,1:nmemb1)-emissoutL(i,j,6))**2)/nmemb1)
         emis_rms_NS(i,j,7) = sqrt(sum((dprRet%emis(i,j,2,4,1:nmemb1)-emissoutL(i,j,7))**2)/nmemb1)
         emis_rms_NS(i,j,8) = sqrt(sum((dprRet%emis(i,j,1,5,1:nmemb1)-emissoutL(i,j,8))**2)/nmemb1)
         emis_rms_NS(i,j,9) = sqrt(sum((dprRet%emis(i,j,2,5,1:nmemb1)-emissoutL(i,j,9))**2)/nmemb1)
         emis_rms_NS(i,j,10) = sqrt(sum((dprRet%emis(i,j,1,6,1:nmemb1)-emissoutL(i,j,10))**2)/nmemb1)
         emis_rms_NS(i,j,11) = sqrt(sum((dprRet%emis(i,j,2,6,1:nmemb1)-emissoutL(i,j,11))**2)/nmemb1)
         emis_rms_NS(i,j,12:13) = emis_rms_NS(i,j,10)
         !print*, 'emis_std',emis_rms_NS(i,j,:)
         !print '(2i5, 13F8.3)', i, j, emis_rms_NS(i,j,1:13)
      endif

      !print*, DPRData%xlon(i,j), DPRData%xlat(i,j), stype
      if(w10_out_NS(i,j)>0 .and. stype .eq. 1) then!wfmap(i,j)>0.9) then
         call calc_relAz(sclonPR(i,j), sclatPR(i,j), DPRData%xlon(i,j), DPRData%xlat(i,j), dprData%envSfcWindU(i,j), dprData%envSfcWindV(i,j), relAz)
         !print*, i,j,w10_out_NS(i,j),'4'
         do jk=1,9
            !begin  WSO 10/14/15 flip polarization indices
            !            !ipolG(jk),ifreqG(jk)
            !            call intplte_emis(ifreqG(jk),1-(ipolG(jk)-1),dPRData%envSknTemp(i,j),w10_out_NS(i,j),emissout(i,j,jk),ebar)
            !ipolG(jk),ifreqG(jk)
            call intplte_emis(ifreqG(jk),ipolG(jk)-1,dPRData%envSknTemp(i,j),w10_out_NS(i,j),relAz,S1eiaPR(i,j),emissoutL(i,j,jk),ebar)
            !end    WSO 10/14/14
         enddo
         call intplte_emis(ifreqG(10),0,dPRData%envSknTemp(i,j),w10_out_NS(i,j),relAz,S2eiaPR(i,j),emissoutL(i,j,10),ebar)
         call intplte_emis(ifreqG(11),1,dPRData%envSknTemp(i,j),w10_out_NS(i,j),relAz,S2eiaPR(i,j),emissoutL(i,j,11),ebar)
         !          if(dPRData%rainType(i,j)<1 .and.  abs(dPRData%xlat(i, j))>55) then
         !             call setEnv(dPRData%envQv(:,i,j),dPRData%envTemp(:,i,j),&
         !                  dPRData%envPress(:,i,j),dPRData%envSfcTemp(i,j),&
         !                  dPRData%envSknTemp(i,j))
         !             call getemissout2(tbRgrid(1:9,i,j+icL),emissout(i,j,1:9))
         !             emissout(i,j,10)=emissout(i,j,8)
         !             emissout(i,j,11)=emissout(i,j,9)
         !             emissout(i,j,12)=emissout(i,j,8)
         !             emissout(i,j,13)=emissout(i,j,8)
         !          endif
         !begin  WSO 10/14/15 replicate emissivities to HF
         emissoutL(i,j,12:13)=emissoutL(i,j,10)
         !end    WSO 10/14/15
      else if(dprRet%emis(i,j,1,1,1) .gt. 0.) then
         !print*, dprRet%emis(i,j,1,1,1:nmemb1)
         emissoutL(i,j,1) = sum(dprRet%emis(i,j,1,1,1:nmemb1))/nmemb1
         emissoutL(i,j,2) = sum(dprRet%emis(i,j,2,1,1:nmemb1))/nmemb1
         emissoutL(i,j,3) = sum(dprRet%emis(i,j,1,2,1:nmemb1))/nmemb1
         emissoutL(i,j,4) = sum(dprRet%emis(i,j,2,2,1:nmemb1))/nmemb1
         emissoutL(i,j,5) = sum(dprRet%emis(i,j,1,3,1:nmemb1))/nmemb1
         emissoutL(i,j,6) = sum(dprRet%emis(i,j,1,4,1:nmemb1))/nmemb1
         emissoutL(i,j,7) = sum(dprRet%emis(i,j,2,4,1:nmemb1))/nmemb1
         emissoutL(i,j,8) = sum(dprRet%emis(i,j,1,5,1:nmemb1))/nmemb1
         emissoutL(i,j,9) = sum(dprRet%emis(i,j,2,5,1:nmemb1))/nmemb1
         emissoutL(i,j,10) = sum(dprRet%emis(i,j,1,6,1:nmemb1))/nmemb1
         emissoutL(i,j,11) = sum(dprRet%emis(i,j,2,6,1:nmemb1))/nmemb1
         emissoutL(i,j,12:13) = emissoutL(i,j,10)
      end if

      !endif
      !if(maxval(emissout(i,j,1:13)) .gt. 2.) then 
      !  print'(A6,2I5,13F8.3)', 'NS Out', i,j,emissout(i,j,1:13)
      !  print*, dprRet%emis(i,j,1,1,1:nmemb1)
      !endif
      !print '(2I5,13F8.3)',i,j,emissout(i,j,1:13)
      !begin  WSO 6/5/18 limit emissivities
      do k = 1, 13
         if(emissoutL(i,j,k) .gt. missing_r4) then
            emissoutL(i,j,k) = min(max(emissoutL(i,j,k), surfEmissivity_min), surfEmissivity_max)
         endif
      enddo
      !end    WSO 6/5/18 
      if(ialg==2) then
         call copysfcemissouts1t(emissoutL(i,j,:),i-1)
         call copysfcemissouts1sigmat(emis_rms_NS(i,j,:),i-1)
      else
         call copysfcemissouts1_fs(emissoutL(i,j,:),i-1)
         !print*, 'emis_std3',emis_rms_NS(i,j,:)
         call copysfcemissouts1sigma_fs(emis_rms_NS(i,j,:),i-1)
      endif
      !print*, flagScanPattern, i, j, rrate3DMS(:,i,j) 
      if((flagScanPattern.eq.0).and.(i.le.12.or.i.ge.38)) then
         dPRData%rainFlagBad(i,j)=missing_r4
         dPRData%ioqualityflagdpr(i,j)=missing_r4
         dPRData%snowIceCover(i,j)=missing_r4
         initnw_MS(:, i, j)=missing_r4
         princomp_MS(:, i, j)=missing_r4
         profclass_MS(i, j)=missing_i2
         surfprecipbiasratio_MS(i, j)=missing_r4
         subfootvariability_MS(i, j)=missing_r4
         multiscatcalc_MS(i, j)=missing_r4
         multiscatsurface_MS(i, j)=missing_r4
         msFlag(i, j)=missing_i2
         dZms(i, j)=missing_r4
         cldwprof=missing_r4
         cldiprof=missing_r4
         zcKu3DMS(:,i,j)=missing_r4
         dPRData%dsrtsigmaPIAku(i, j)=missing_r4
         dPRData%sigmaZeroKu(i, j)=missing_r4
         dPRData%sigmaZeroKa(i, j)=missing_r4
         !dPRData%dsrtsigmaPIAku(i, j)=missing_r4
         dPRData%dsrtsigmaPIAka(i, j)=missing_r4
         !dPRData%sigmaZeroKu(i, j)=missing_r4
         log10NwMean=missing_r4
         mu_mean_prof=missing_r4
         
         rrate3DMS(:,i,j)=missing_r4
         rrate3DstdMS(:,i,j)=missing_r4
         pwc3DMS(:,i,j)=missing_r4
         pwc3DstdMS(:,i,j)=missing_r4
         mlwc_fracMS(:,i,j)=missing_r4
         sfcRainMS(i,j)=missing_r4
         d03DMS(:,i,j)=missing_r4
         
         dPRData%envTemp(:,i,j)=missing_r4
         dPRData%envSfcTemp(i,j)=missing_r4
         dPRData%envPress(:,i,j)=missing_r4
         dPRData%envSfcPress(i,j)=missing_r4
         dPRData%envQv(:,i,j)=missing_r4
         dPRData%envQv(:,i,j)=missing_r4
         dPRData%envSknTemp(i,j)=missing_r4
         skintempsigma_MS(i, j)=missing_r4
         columnvaporsigma_MS(i, j)=missing_r4
         columncloudliqsigma_MS(i, j)=missing_r4
         algotype_MS(i, j)=missing_r4
         errorofdatafit_MS(i, j)=missing_r4
         tbout=missing_r4
         emissoutL(i,j,:)=missing_r4
      endif
      if(i>0 .and. i<50 .and. ialg==1) then
!begin  WSO 9/28/13 add rain flag including missing for bad scans
        call copyrainflags2_fs(dPRData%rainFlagBad(i,j), i-1, flagScanPattern)
        if(flagScanPattern_0.ne.flagScanPattern) then
           print*, 'line',1470
           stop
        end if
        call copyioqualitys2_fs(dPRData%ioqualityflagdpr(i,j), i-1)
        call copysnowices2_fs(dPRData%snowIceCover(i,j), i-1)
        call copyinitnws2_fs(initnw_MS(:, i, j), dPRRet%n9(:, i, j), i-1)
        call copyprincomps2_fs(princomp_MS(:, i, j), i-1)
        call copyprofclasss2_fs(profclass_MS(i, j), i-1)
        call copysurfprecipbiasratios2_fs(surfprecipbiasratio_MS(i, j), i-1)
        call copysubfootvariabilitys2_fs(subfootvariability_MS(i, j), i-1)
        call copymultiscatcalcs2_fs(multiscatcalc_MS(i, j), i-1)
        call copymultiscatsurfaces2_fs(multiscatsurface_MS(i, j), i-1)
        if((i.gt.12 .and. i.lt.38).or.(flagScanPattern.eq.1)) then
           call copymultiscatcalcs2_fs(msFlag(i, j), i-1)
           call copymultiscatsurfaces2_fs(dZms(i, j), i-1)
        endif
        call copycldwaters2_fs(cldwprof, i-1)
        cldiprof = missing_r4
        call copycldices2_fs(cldiprof,i-1)
        call copyzckus2_fs(zcKu3DMS(:,i,j), zcKa3DMS(:,i,j), i-1)
        call copysigmapias2_fs(dPRData%dsrtsigmaPIAku(i, j), dPRData%dsrtsigmaPIAka(i, j), i-1)
        call copysigmazeros2_fs(dPRData%sigmaZeroKu(i, j), dPRData%sigmaZeroKa(i, j), i-1)
!begin  WSO 8/19/13 change dNw to Nw and add mu
        if(dPRData%rainType(i,j)>=100) then
            do k=1,88
               if(k>=dPRData%node(1,i,j).and.k<=dPRData%node(5,i,j)+1) then
                  log10NwMean(k)=sum(dPRRet%MS%log10dNw(1:nmemb1,k,i,j))/nmemb1 + &
                       log10(8.e+6)
                  mu_mean_prof(k) = mu_meanMS(i, j)
               else
                  log10NwMean(k)= missing_r4
                  mu_mean_prof(k) = missing_r4
               end if
            enddo
         else
            log10NwMean = missing_r4
            mu_mean_prof = missing_r4
         endif
         if(flagScanPattern.eq.0) then
            if(i<=12.or.i>37) then
               log10NwMean = missing_r4
               mu_mean_prof = missing_r4
            endif
         endif
!end     WSO 8/19/13
         !call copylognws2_fs( log10NwMean,dPRRet%n9(:,i,j),i-1)
         call copynws2_fs(log10NwMean, i-1)
         call copymus2_fs( mu_mean_prof,dPRRet%n9(:,i,j),i-1)
         call copyrrates2_fs(rrate3DMS(:,i,j),rrate3DstdMS(:,i,j),i-1)
         call copynodess2_fs(dPRData%node(:,i,j),i-1)
         call estimated_sfc_precip2(i-1, rrate3DMS(:,i,j),rrate3DstdMS(:,i,j),&
              sfcRainMS(i,j), dprData%binRealSurface(i,j), &
              dprData%binZeroDegree(i,j), dprData%binClutterFree(i,j),&
              pType(j,i),flagScanPattern,sfcRainLiqFrac(i, j))
         if(flagScanPattern_0.ne.flagScanPattern) then
            print*, 'line',1524
            stop
         end if
         call copypwcs2_fs(pwc3DMS(:,i,j),pwc3DstdMS(:,i,j),i-1)
         call copylwcfracs2_fs(mlwc_fracMS(:,i,j),mrate_fracMS(:,i,j),i-1)
         if(sfcRainMS(i,j).ge.-0.001) then
            call copysfcrainliqfracs2_fs(sfcRainMS(i,j)*sfcRainLiqFracMS(i, j), i-1)
         else
            call copysfcrainliqfracs2_fs(missing_r4, i-1)
         end if
         
         call copy_tot_to_liqrate_kuka(i-1, rrate3DMS(:,i,j), &
              dPRData%node(:,i,j),flagScanPattern)
         if(flagScanPattern_0.ne.flagScanPattern) then
            print*, 'line',1538
            stop
         end if
         call copy_tot_to_liqwatercont_kuka(i-1, pwc3DMS(:,i,j), &
              dPRData%node(:,i,j),flagScanPattern)
         if(flagScanPattern_0.ne.flagScanPattern) then
            print*, 'line',1544
            stop
         end if
         call copyd0s2_fs(d03DMS(:,i,j),i-1)
         call copyenvtemps2_fs(dPRData%envTemp(:,i,j), env_nodes(:,i), i-1)
         call copysfcairtemps2_fs(dPRData%envSfcTemp(i,j),i-1)
         call copyenvpresss2_fs(dPRData%envPress(:,i,j), env_nodes(:,i), i-1)
         call copysfcairpresss2_fs(dPRData%envSfcPress(i,j),i-1)
         call copyenvsfqvs2_fs(dPRData%envQv(:,i,j),i-1)
         call copyskintemps2_fs(dPRData%envSknTemp(i,j),i-1)
         call copyskintempsigmas2_fs(skintempsigma_MS(i, j), i-1)
         call copycolumnvaporsigmas2_fs(columnvaporsigma_MS(i, j), i-1)
         call copycolumncloudliqsigmas2_fs(columncloudliqsigma_MS(i, j), i-1)
         call copyalgotypes2_fs(algotype_MS(i, j), i-1)
         call copyerrorofdatafits2_fs(errorofdatafit_MS(i, j), i-1)
!end    WSO 8/30/13
         if(dprRet%MS%emis(i,j,1,1,1) .gt. 0.) then
           emissoutL(i,j,1) = sum(dprRet%MS%emis(i,j,1,1,1:nmemb1))/nmemb1
           emissoutL(i,j,2) = sum(dprRet%MS%emis(i,j,2,1,1:nmemb1))/nmemb1
           emissoutL(i,j,3) = sum(dprRet%MS%emis(i,j,1,2,1:nmemb1))/nmemb1
           emissoutL(i,j,4) = sum(dprRet%MS%emis(i,j,2,2,1:nmemb1))/nmemb1
           emissoutL(i,j,5) = sum(dprRet%MS%emis(i,j,1,3,1:nmemb1))/nmemb1
           emissoutL(i,j,6) = sum(dprRet%MS%emis(i,j,1,4,1:nmemb1))/nmemb1
           emissoutL(i,j,7) = sum(dprRet%MS%emis(i,j,2,4,1:nmemb1))/nmemb1
           emissoutL(i,j,8) = sum(dprRet%MS%emis(i,j,1,5,1:nmemb1))/nmemb1
           emissoutL(i,j,9) = sum(dprRet%MS%emis(i,j,2,5,1:nmemb1))/nmemb1
           emissoutL(i,j,10) = sum(dprRet%MS%emis(i,j,1,6,1:nmemb1))/nmemb1
           emissoutL(i,j,11) = sum(dprRet%MS%emis(i,j,2,6,1:nmemb1))/nmemb1
           emissoutL(i,j,12:13) = emissoutL(i,j,10)
           
           emis_rms_MS(i,j,1) = sqrt(sum((dprRet%MS%emis(i,j,1,1,1:nmemb1)-emissoutL(i,j,1))**2)/nmemb1)
           emis_rms_MS(i,j,2) = sqrt(sum((dprRet%MS%emis(i,j,2,1,1:nmemb1)-emissoutL(i,j,2))**2)/nmemb1)
           emis_rms_MS(i,j,3) = sqrt(sum((dprRet%MS%emis(i,j,1,2,1:nmemb1)-emissoutL(i,j,3))**2)/nmemb1)
           emis_rms_MS(i,j,4) = sqrt(sum((dprRet%MS%emis(i,j,2,2,1:nmemb1)-emissoutL(i,j,4))**2)/nmemb1)
           emis_rms_MS(i,j,5) = sqrt(sum((dprRet%MS%emis(i,j,1,3,1:nmemb1)-emissoutL(i,j,5))**2)/nmemb1)
           emis_rms_MS(i,j,6) = sqrt(sum((dprRet%MS%emis(i,j,1,4,1:nmemb1)-emissoutL(i,j,6))**2)/nmemb1)
           emis_rms_MS(i,j,7) = sqrt(sum((dprRet%MS%emis(i,j,2,4,1:nmemb1)-emissoutL(i,j,7))**2)/nmemb1)
           emis_rms_MS(i,j,8) = sqrt(sum((dprRet%MS%emis(i,j,1,5,1:nmemb1)-emissoutL(i,j,8))**2)/nmemb1)
           emis_rms_MS(i,j,9) = sqrt(sum((dprRet%MS%emis(i,j,2,5,1:nmemb1)-emissoutL(i,j,9))**2)/nmemb1)
           emis_rms_MS(i,j,10) = sqrt(sum((dprRet%MS%emis(i,j,1,6,1:nmemb1)-emissoutL(i,j,10))**2)/nmemb1)
           emis_rms_MS(i,j,11) = sqrt(sum((dprRet%MS%emis(i,j,2,6,1:nmemb1)-emissoutL(i,j,11))**2)/nmemb1)
           emis_rms_MS(i,j,12:13) = emis_rms_MS(i,j,10)
           !print '(2i5, 13F8.3)', i, j, emis_rms_MS(i,j,1:13)
         endif

         if(w10_out_MS(i,j)>0 .and. wfmap(i,j)>0.9) then
            !print*, i,j,w10_out_MS(i,j),'5'
            call calc_relAz(sclonPR(i,j),sclatPR(i,j), DPRData%xlon(i,j), DPRData%xlat(i,j), dprData%envSfcWindU(i,j), dprData%envSfcWindV(i,j), relAz)
            do jk=1,9
               call intplte_emis(ifreqG(jk),&
                    ipolG(jk)-1,dPRData%envSknTemp(i,j),&
                    w10_out_MS(i,j),relAz,S1eiaPR(i,j),emissoutL(i,j,jk),ebar)
            enddo
            call intplte_emis(ifreqG(10),0,dPRData%envSknTemp(i,j),w10_out_NS(i,j),relAz,S2eiaPR(i,j),emissoutL(i,j,10),ebar)
            call intplte_emis(ifreqG(11),1,dPRData%envSknTemp(i,j),w10_out_NS(i,j),relAz,S2eiaPR(i,j),emissoutL(i,j,11),ebar)
!begin  WSO 10/14/15 replicate emissivities at HF
            emissoutL(i,j,12:13)=emissoutL(i,j,10)
!end    WSO 10/14/15
         else if(dprRet%MS%emis(i,j,1,1,1) .gt. 0.) then
           emissoutL(i,j,1) = sum(dprRet%MS%emis(i,j,1,1,1:nmemb1))/nmemb1
           emissoutL(i,j,2) = sum(dprRet%MS%emis(i,j,2,1,1:nmemb1))/nmemb1
           emissoutL(i,j,3) = sum(dprRet%MS%emis(i,j,1,2,1:nmemb1))/nmemb1
           emissoutL(i,j,4) = sum(dprRet%MS%emis(i,j,2,2,1:nmemb1))/nmemb1
           emissoutL(i,j,5) = sum(dprRet%MS%emis(i,j,1,3,1:nmemb1))/nmemb1
           emissoutL(i,j,6) = sum(dprRet%MS%emis(i,j,1,4,1:nmemb1))/nmemb1
           emissoutL(i,j,7) = sum(dprRet%MS%emis(i,j,2,4,1:nmemb1))/nmemb1
           emissoutL(i,j,8) = sum(dprRet%MS%emis(i,j,1,5,1:nmemb1))/nmemb1
           emissoutL(i,j,9) = sum(dprRet%MS%emis(i,j,2,5,1:nmemb1))/nmemb1
           emissoutL(i,j,10) = sum(dprRet%MS%emis(i,j,1,6,1:nmemb1))/nmemb1
           emissoutL(i,j,11) = sum(dprRet%MS%emis(i,j,2,6,1:nmemb1))/nmemb1
           emissoutL(i,j,12:13) = emissoutL(i,j,10)
           
           emis_rms_MS(i,j,1) = sqrt(sum((dprRet%MS%emis(i,j,1,1,1:nmemb1)-emissoutL(i,j,1))**2)/nmemb1)
           emis_rms_MS(i,j,2) = sqrt(sum((dprRet%MS%emis(i,j,2,1,1:nmemb1)-emissoutL(i,j,2))**2)/nmemb1)
           emis_rms_MS(i,j,3) = sqrt(sum((dprRet%MS%emis(i,j,1,2,1:nmemb1)-emissoutL(i,j,3))**2)/nmemb1)
           emis_rms_MS(i,j,4) = sqrt(sum((dprRet%MS%emis(i,j,2,2,1:nmemb1)-emissoutL(i,j,4))**2)/nmemb1)
           emis_rms_MS(i,j,5) = sqrt(sum((dprRet%MS%emis(i,j,1,3,1:nmemb1)-emissoutL(i,j,5))**2)/nmemb1)
           emis_rms_MS(i,j,6) = sqrt(sum((dprRet%MS%emis(i,j,1,4,1:nmemb1)-emissoutL(i,j,6))**2)/nmemb1)
           emis_rms_MS(i,j,7) = sqrt(sum((dprRet%MS%emis(i,j,2,4,1:nmemb1)-emissoutL(i,j,7))**2)/nmemb1)
           emis_rms_MS(i,j,8) = sqrt(sum((dprRet%MS%emis(i,j,1,5,1:nmemb1)-emissoutL(i,j,8))**2)/nmemb1)
           emis_rms_MS(i,j,9) = sqrt(sum((dprRet%MS%emis(i,j,2,5,1:nmemb1)-emissoutL(i,j,9))**2)/nmemb1)
           emis_rms_MS(i,j,10) = sqrt(sum((dprRet%MS%emis(i,j,1,6,1:nmemb1)-emissoutL(i,j,10))**2)/nmemb1)
           emis_rms_MS(i,j,11) = sqrt(sum((dprRet%MS%emis(i,j,2,6,1:nmemb1)-emissoutL(i,j,11))**2)/nmemb1)
           emis_rms_MS(i,j,12:13) = emis_rms_MS(i,j,10)
           !print '(2i5, 13F8.3)', i, j, emis_rms_MS(i,j,1:13)
         endif

         do k = 1, 13
           if(emissoutL(i,j,k) .gt. missing_r4) then
             emissoutL(i,j,k) = min(max(emissoutL(i,j,k), surfEmissivity_min), surfEmissivity_max)
           endif
         enddo
         if((flagScanPattern.eq.0).and.(i.le.12.or.i.ge.38)) then
            tbout=missing_r4
            emissoutL(i,j,:)=missing_r4
            emis_rms_MS(i,j,:)=missing_r4
         endif
         call copysfcemissouts2_fs(emissoutL(i,j,:),i-1)
         call copysfcemissouts2sigma_fs(emis_rms_MS(i,j,:),i-1)
         !--fs_300--!
         !call copysfcemissouts2_fs_300(j-1,emissoutL(i,j,:),i-1)
         !call copysfcemissouts2sigma_fs_300(j-1,emis_rms_MS(i,j,:),i-1)
         !--fs_300--!
      endif

      do k=1,9
         if(tbout2d(i,j,k)>0) then
            tbout(k)=tbout2d(i,j,k)!-tbRgrid(k,i,j+icL)
         else
            tbout(k)=tbout2dNoOcean(i,j,k)!-tbRgrid(k,i,j+icL)
         endif
      enddo
      tbout(10)=sum(dPRRet%tb(i,j,1,6,1:1*nmemb1))/(nmemb1)
      tbout(11)=sum(dPRRet%tb(i,j,2,6,1:1*nmemb1))/(nmemb1)
      tbout(12)=sum(dPRRet%tb(i,j,1,7,1:1*nmemb1))/(nmemb1)
      tbout(13)=sum(dPRRet%tb(i,j,1,8,1:1*nmemb1))/(nmemb1)
      do k=10,13
         !tbout(k)=hFreqPRg(i,j,k-9)
      enddo
      !print*, tbout
      if(dPRData%rainType(i,j)>=100) then
         !print*, tbout
      endif
      if(tbout(7)>0 .and. tbRgrid(7,i,j+icL)>0) then
         !write(*,10) tbout(6:9), tbRgrid(6:9,i,j+icL)
      endif
      !if(i==24) print*, tbout
      if(ialg==2) then
         call copytbouts1t(tbout,i-1)
      else
         call copytbouts1_fs(tbout,i-1)
         !call copytbouts1_fs_300(j-1,tbout,i-1)
      endif
!!begin MG 09172013
      if(i>=1 .and. i<=49) then
         do k=1,9
            if(tbout2dMS(i,j,k)>0) then
               tbout(k)=tbout2dMS(i,j,k)!-tbRgrid(k,i,j+icL)
            else
               tbout(k)=tbout2dNoOceanMS(i,j,k)!-tbRgrid(k,i,j+icL)
            endif
         enddo
         tbout(10)=sum(dPRRet%MS%tb(i,j,1,6,1:1*nmemb1))/(nmemb1)
         tbout(11)=sum(dPRRet%MS%tb(i,j,2,6,1:1*nmemb1))/(nmemb1)
         tbout(12)=sum(dPRRet%MS%tb(i,j,1,7,1:1*nmemb1))/(nmemb1)
         tbout(13)=sum(dPRRet%MS%tb(i,j,1,8,1:1*nmemb1))/(nmemb1)
         if((flagScanPattern.eq.0).and.(i.le.12.or.i.ge.38)) then
            tbout=missing_r4
         endif
         call copytbouts2_fs(tbout,i-1)
         !--fs_300--!
         !call copytbouts2_fs_300(j-1,tbout,i-1)
         !--fs_300--!
      endif
      if ((flagScanPattern.eq.0).and.(i.le.12.or.i.ge.38)) then
         dPRData%OEQv(:,i,j)=missing_r4
         dPRData%OETemp(:,i,j)=missing_r4
         dPRData%OEcloudLiqSigma(i,j)=missing_r4
         dPRData%OEcloudLiqPath(i,j)=missing_r4
         dPRData%OEcloud(:,i,j)=missing_r4
         dPRData%OESfcWind(i,j)=missing_r4
         dPRData%OESfcWindSigma(i,j)=missing_r4
         dPRData%OESknTemp(i,j)=missing_r4
         dPRData%OEskinTempSigma(i,j)=missing_r4
         dPRData%OESfcTemp(i,j)=missing_r4
         dPRData%OESfcQv(i,j)=missing_r4
         dPRData%OEtpw(i,j)=missing_r4
         dPRData%OEtpwSigma(i,j)=missing_r4
         dPRData%OEchiSq(i,j)=missing_r4
         dPRData%OEsimTbNonRain(:,i,j)=missing_r4
         dPRData%OEemisA(:,i,j)=missing_r4
         dPRData%OEemis(:,i,j)=missing_r4
         dPRData%OEemisSigma(:,i,j)=missing_r4
         dPRData%OEstype(i,j)=missing_r4
         dPRData%dsrtsigmaPIAka(i, j)=missing_r4
         dPRData%OECloudLiqPath(i,j)=missing_r4
         dPRData%OEpiaNonRain(:,i,j)=missing_r4
      endif
      if ((flagScanPattern.eq.0).and.(i.le.12.or.i.ge.38)) then
         dPRRet%n9(:,i,j)=missing_i4
         dPRData%node(:,i,j)=missing_i4
         env_nodes(:,i)=missing_i4
      endif
      call copyenvqvs2_fs(dPRData%envQv(:,i,j), env_nodes(:,i), i-1)
      
      call copy_oepianonrain_kukagmi(dPRData%OEpiaNonRain(:,i,j), i-1)
      call copy_oeqv_kukagmi(dPRData%OEQv(:,i,j),env_nodes(:,i), i-1)
      call copy_oetemp_kukagmi(dPRData%OETemp(:,i,j),env_nodes(:,i), i-1)
      call copy_oecloud_kukagmi(dPRData%OECloud(:,i,j), i-1)
      call copy_oecloudicepath_kukagmi(dPRData%OECloudLiqPath(i,j), i-1)
      call copy_oecloudliqpath_kukagmi(dPRData%OECloudLiqPath(i,j), i-1)
      call copy_oecloudliqsigma_kukagmi(dPRData%OEcloudLiqSigma(i,j), i-1)
      call copy_oesfcwind_kukagmi(dPRData%OESfcWind(i,j), i-1)
      call copy_oesfcwindsigma_kukagmi(dPRData%OESfcWindSigma(i,j), i-1)
      call copy_oeskntemp_kukagmi(dPRData%OESknTemp(i,j), i-1)
      call copy_oeskintempsigma_kukagmi(dPRData%OEskinTempSigma(i,j), i-1)
      call copy_oesfctemp_kukagmi(dPRData%OESfcTemp(i,j), i-1)
      call copy_oesfcqv_kukagmi(dPRData%OESfcQv(i,j), i-1)
      call copy_oetpw_kukagmi(dPRData%OEtpw(i,j), i-1)
      call copy_oetpwsigma_kukagmi(dPRData%OEtpwSigma(i,j), i-1)
      call copy_oechisq_kukagmi(dPRData%OEchiSq(i,j), i-1)
      call copy_oesimtbnonrain_kukagmi(dPRData%OEsimTbNonRain(:,i,j), i-1)
      call copy_oeemis_kukagmi(dPRData%OEemis(:,i,j), i-1)
      call copy_oeemissigma_kukagmi(dPRData%OEemisSigma(:,i,j), i-1)
      call copy_oeemisa_kukagmi(dPRData%OEemisA(:,i,j), i-1)
      call copy_oestype_kukagmi(dPRData%OEstype(i,j), i-1)
      call copy_oe_missing_staff(i-1);
      !!end MG 09172013
   enddo
   if(ialg==2) then
      call writescant()
   else
      !print*, i-1, 'write scan'
      call writescan_fs()
   endif
   !print*, 'FSP2', j, flagScanPattern

enddo
end subroutine radarRetSub4_FS
