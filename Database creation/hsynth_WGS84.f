      program synth
c
c-----------------------------------------------------------------------
c
c  A FORTRAN PROGRAM TO COMPUTE GEOID HEIGHTS WITH RESPECT TO WGS84 
c  BY SPHERICAL HARMONIC SYNTHESIS.
c
c  HARMONIC_SYNTH_WGS84 (Version 06/03/2008)
c
c  Simon A. Holmes and Nikolaos K. Pavlis
c
c
c  DISCLAIMER
c
c  The FORTRAN 77 program "HARMONIC_SYNTH_WGS84" that is described
c  below has been developed for research purposes. Although every
c  effort has been made to ensure the correct function of this
c  the authors and the distributors of "HARMONIC_SYNTH_WGS84" make
c  no claim, explicit or implicit, as to whether the program
c  "HARMONIC_SYNTH_WGS84" is free of errors.
c
c   
c  PROGRAM DESCRIPTION
c
c  HARMONIC_SYNTH_WGS84 is a Fortran 77 program to compute geoid 
c  heights by very-high-degree spherical harmonic synthesis. 
c  Coordinates of the points for which geoid heights are required are
c  read from an input ASCII file. HARMONIC_SYNTH_WGS84 computes 
c  geoid heights for each set of input coordinates using a three-step
c  computation. 
c
c  First, HARMONIC_SYNTH_WGS84 computes the quasi height anomaly (zeta*)
c  by spherical harmonic synthesis of the input gravitational 
c  potential model:
c
c       "EGM2008_to2190_TideFree".
c
c  Spherical harmonic synthesis of zeta* extends from Nmin=2 to 
c  Nmax=2190. Zeta* is computed for a point residing on the surface
c  of the WGS84 ellipsoid (geodetic height = zero). 
c
c  Second, HARMONIC_SYNTH_WGS84 adds to this zeta* value the NGA's 
c  best estimate of the zero-degree term for the height anomaly, which 
c  in this case is equal to -41cm. 
c
c  Lastly, HARMONIC_SYNTH_WGS84 computes a correction term to convert 
c  the zeta* (plus -41cm) directly to the corresponding geoid height. 
c  HARMONIC_SYNTH_WGS84 computes this correction term by spherical 
c  harmonic syntheis of the input correction model:
c
c       "Zeta-to-N_to2160_egm2008"
c
c  Spherical harmonic synthesis of the correction term extends from 
c  Nmin=0 to Nmax=2160. This correction term is then added to the value
c  for zeta* (plus -41cm) to yield a geoid height with respect to WGS84. 
c
c  Note that HARMONIC_SYNTH_WGS84 almost mimicks the functionality of 
c  the Fortran 77 program HARMONIC_SYNTH (Simon Holmes and Nikos Pavlis) 
c  when the latter is executed according to the paramater settings: 
c  lmin=2, lmax=2190, jmin=0, jmax=2160, isw=82, igrid=0. 
c  The major difference between the function of HARMONIC_SYNTH_WGS84 and 
c  of HARMONIC_SYNTH (when executed as above) is that HARMONIC_SYNTH 
c  does not add a zero-degree term to zeta*.
c
c
c  INPUT/OUTPUT FORMAT
c
c  The ASCII input file containing the geographical coordinates of
c  the scattered points should contain one record for each point. Each 
c  record contains the geodetic latitude and then the longitude 
c  in decimal degrees for its respective point. 
c
c  (decimal degrees)   (decimal degrees)
c   geodetic latitude       longitude
c
c  These data are read using free FORMAT. Geodetic coordinates should
c  refer to the WGS84.
c
c  The ASCII output file containing the geoid height values for the
c  scattered points also contains one record for each point. Each 
c  record contains the WGS84 geodetic latitude and longitude in decimal 
c  degrees, followed by the computed geoid height for that point.
c
c
c  INPUT PARAMATERS
c
c  The FIVE input parameters for HARMONIC_SYNTH_WGS84 are:
c 
c  path_mod: is the path to the directory containing the two harmonic
c            models (1) "EGM2008_to2190_TideFree"
c                   (2) "Zeta-to-N_to2160_EGM2008".
c
c  path_pnt: is the path to the directory containing the ASCII input
c            file of coordinate information for the scattered points.
c
c  name_pnt: is the name of the ASCII input file containing the
c            coordinate information for the scattered points.
c
c  path_out: is the path to the directory in which the ASCII output file
c            containing the geoid heights is to be placed.
c
c  name_out: is the name of the ASCII output file containing the geoid
c            heights.
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 j2z
      external dj2n
      character*120 path_mod,pmodl,name_mod,nmodl
      character*120 name_hgt,nhght,name_cnv,nconv
      character*120 path_pnt,ppnts,name_pnt,npnts
      character*120 path_out,pout,name_out,nout
      character*120 fnu01,fnu02,fnu03,fnu12,fnu10
c
c-----------------------------------------------------------------------
c
c     INPUT PARAMETERS
c
c-----------------------------------------------------------------------
c
      parameter(path_mod = './',
     &          path_pnt = './',
     &          name_pnt = 'INPUT.DAT',
     &          path_out = './',
     &          name_out = 'OUTPUT.DAT')
c
c-----------------------------------------------------------------------
c
c     NON-INPUT PARAMETERS
c
c-----------------------------------------------------------------------
      parameter(iumi     = 1,
     &          lmin     = 2,
     &          lmax     = 2190,
     &          name_mod = 'EGM2008_to2190_TideFree',
     &          aegm     = 6378136.3d0,
     &          gmegm    = 0.3986004415d20,
     &          isub     = 1,
     &          igrid    = 0,
     &          isw      = 82,
     &          exclud   = 9999.d0)
c-----------------------------------------------------------------------
c
c     NON-INPUT PARAMETERS FOR SCATTERED POINT COMPUTATIONS
c
c-----------------------------------------------------------------------
      parameter(iusc     = 12,
     &          maxpt    = 1000000)
c-----------------------------------------------------------------------
c
c     NON-INPUT PARAMETERS FOR SPECIALISED COMPUTATIONS
c
c-----------------------------------------------------------------------
      parameter(iuci     = 3,
     &          jmin     = 0000,
     &          jmax     = 2160,
     &          name_cnv = 'Zeta-to-N_to2160_egm2008')
c-----------------------------------------------------------------------
c
c     NON-INPUT PARAMETERS DEFINING ARRAY DIMENSIONS
c
c-----------------------------------------------------------------------
      parameter(maxr=100)
c-----------------------------------------------------------------------
c
c     MISCELLANEOUS NON-INPUT PARAMETERS
c
c-----------------------------------------------------------------------
c     parameter(iglob    = 1-(int(((deast-dwest)/360.d0) + 1.d-5)),
c    &          ncols    = nint((deast-dwest)/dlon)
c    &                                     +(1-icell)*(1-iflag)*iglob,
c    &          nrows    = nint((dnorth-dsouth)/dlat)
c    &                                     +(1-icell)*(1-iflag),
c    &          mmax0    = max(lmax,kmax),
c    &          nmax0    = max(mmax0,jmax),
c    &          nmax01   = nmax0+1,
c    &          nmax02   = nmax0+2,
c    &          jcol     = nint(360.d0/dlon),
c    &          jfft     = max(jcol,nmax01))
c-----------------------------------------------------------------------
      parameter(ncols    = 1,
     &          nrows    = 1,
     &          nmax0    = max(lmax,jmax),
     &          nmax01   = nmax0+1,
     &          nmax02   = nmax0+2,
     &          jcol     = 1,
     &          jfft     = 1)
c-----------------------------------------------------------------------
      parameter(zeta0    = -41.d0/100.d0)
c-----------------------------------------------------------------------
c
c     NON-INPUT PARAMETERS FOR THE WGS84 GEOD. REF. SYSTEM
c
c-----------------------------------------------------------------------
c
      parameter(ae       =  6378137.d0,         
     &          gm       =  0.3986004418d20,  
     &          omega    =  7292115.d-11,
     &          c20      =  -0.484166774985d-03,
     &          rf       =  0.d0)
c
c-----------------------------------------------------------------------
c
      real*8 zonals(10),cz(20),da(5)
      real*8 batch(ncols*maxr),grsv(15)
      real*8 cnm(nmax01,nmax01),snm(nmax01,nmax01)
      real*8 scrd(ncols,2),statd(22),ddlon(ncols)
      real*8 flat(maxr),flon(maxr),dist(maxr),pt(maxr)
      real*8 pt_a(maxpt),ga(maxpt),zeta(maxpt),corr(maxpt)
      real*8 flat_a(maxpt),flon_a(maxpt),dist_a(maxpt),horth_a(maxpt)
c
      real*8 uc(maxr),tc(maxr),uic(maxr),uic2(maxr)
      real*8 cotc(maxr),thet2(maxr),thet1(maxr),thetc(maxr)
c
      real*8 pmm_a(nmax01,maxr+1),pmm_b(nmax01,maxr),f_n(maxr),f_s(maxr)
      real*8 p(nmax02,maxr),p1(nmax02,maxr),p2(nmax02,maxr)
      real*8 c_ev(nmax01,maxr),s_ev(nmax01,maxr),kk(nmax01,maxr)
      real*8 c_od(nmax01,maxr),s_od(nmax01,maxr)
      real*8 cr1(jfft),sr1(jfft),cr2(jfft),sr2(jfft)
      real*8 aux(2*jcol),wrkfft(2*jcol),factn(nmax01),k(nmax01)
      real*8 cml(nmax01),sml(nmax01)
c
      real*4 data(ncols,nrows)
      integer*4 it(maxr),it_a(maxpt),iex(maxr),zero(maxr+1)
c
c-----------------------------------------------------------------------
c     time0=secife()
c-----------------------------------------------------------------------
c
      write(6,5000)
      write(6,4000)
 4000 format(30x,'Execution')
c
      imod = 0
      ihgt = 0
      icor = 0
      iehm = 0
      igrs = 1
c
      if (isw.ne.2.and.isw.ne.5)    imod = 1
      if (isw.eq.2.or.isw.eq.81)    ihgt = 1
      if (isw.eq.5.or.isw.eq.82)    icor = 1
      if (isw.eq.100.or.isw.eq.101) iehm = 1
      if (igrid.eq.1.and.isw.eq.2.and.iell.eq.0) igrs = 0
c
      call error(lmin,lmax,kmin,kmax,jmin,jmax,isub,igrid,iglat,isw,
     &                      iflag,iell,icell,dnorth,dsouth,dwest,deast)
c
      exc = exclud
c
      icent = icell
      if (iflag.eq.1) icent = 1
c
c-----------------------------------------------------------------------
c
c     ASSEMBLE PATH AND NAME FOR DATA OUTPUT
c
c-----------------------------------------------------------------------
c
      call extract_name(path_out,pout,nchr_pout)
      call extract_name(name_out,nout,nchr_nout)
      fnu10=pout(1:nchr_pout)//nout(1:nchr_nout)
c
c-----------------------------------------------------------------------
c
c     INITIALISE GEODETIC PARAMETERS
c
c-----------------------------------------------------------------------
c
      if (igrs.eq.1) then
c
        grat   = gmegm/gm
        arat   = aegm/ae
        arati  = 1.d0/arat
c
        c20_z  = c20
        revf   = rf
        j2z    = 0.d0
        if (rf.eq.0.d0) j2z  = -c20_z *dsqrt(5.d0)
c
        call grs(ae,revf,j2z,gm,omega,b,e2,e21,geqt,gpol,dk,fm,q0,
     &                                                     zonals,da)
c
        if (c20.eq.0) c20_z  = -j2z   /dsqrt(5.d0)
c
        dc20 = 0.d0
c       if (imod.eq.1.and.iehm.eq.0) then
c         dc20   = 3.11080d-8*0.3d0/dsqrt(5.d0)
c       endif  !  imod;iehm
c
        grsv(1)  = ae
        grsv(2)  = revf
        grsv(3)  = gm
        grsv(4)  = omega
        grsv(5)  = b
        grsv(6)  = e2
        grsv(7)  = e21
        grsv(8)  = geqt
        grsv(9)  = gpol
        grsv(10) = dk
        grsv(11) = fm
        grsv(12) = q0
        grsv(13) = dk
c
        do n = 2, 20, 2
          cz(n) = -zonals(n/2)/sqrt(2.d0*n+1.d0)
          if (n.lt.lmin.or.n.gt.lmax) cz(n) = 0.d0
        enddo  !  n
c
c-----------------------------------------------------------------------
c
        write(6,5000)
        write(6,6011)
 6011   format(15x,'Constants Used in the Expansion',/
     &         15x,'-------------------------------',//)
        write(6,5001)
 5001   format(15x,'Defining Constants for the GRS:',/)
c
        write(6,6012) ae
        if (rf.eq.0.d0) write(6,5005) c20_z
        if (rf.ne.0.d0) write(6,5006) revf
        write(6,5007) gm*1.d-5,omega
 6012   format(15x,'ae     = ',d20.12,'   (m)')
 5005   format(15x,'C(2,0) = ',d20.12,'          zero value')
 5006   format(15x,'1/f    = ',d20.12,'          inverse flattening')
 5007   format(15x,'gm     = ',d20.12,'   (m**3/S**2)'/,
     &         15x,'omega  = ',d20.12,'   (rad/s)'//)
c
        write(6,6015)
 6015   format(15x,'Derived Constants for the Zero-Type Ellipsoid:',/)
        write(6,6016) j2z
        if (rf.eq.0.d0) write(6,5008) revf
        if (rf.ne.0.d0) write(6,5009) c20_z
        write(6,5010) b,e2,geqt,gpol,dk,fm
 6016   format(15x,'J2     = ',d20.12,'          zero value')
 5008   format(15x,'1/f    = ',d20.12,'          inverse flattening')
 5009   format(15x,'C(2,0) = ',d20.12,'          zero value')
 5010   format(15x,'b      = ',d20.12,'   (m)    semi-minor axis'/,
     &         15x,'e2     = ',d20.12,'          first eccentricity',
     &                                        ' squared'/,
     &         15x,'geqt   = ',d20.12,'   (mGal) equatorial gravity'/,
     &         15x,'gpol   = ',d20.12,'   (mGal)      polar gravity'/,
     &         15x,'k      = ',d20.12,/,
     &         15x,'m      = ',d20.12)
c
c-----------------------------------------------------------------------
c
        if (isub.eq.1.and.imod.eq.1.and.iehm.eq.0)
     &                              write(6,6017) (cz(n),n = 2, 20, 2)
 6017   format(//15x,'Ref. Gravity Potential Even Zonal Terms (C-form)',
     &          /15x,'Subtracted From the Input Coefficients:',//,
     &           15x,'C( 2,0) = ',d20.12,/,
     &           15x,'C( 4,0) = ',d20.12,/,
     &           15x,'C( 6,0) = ',d20.12,/,
     &           15x,'C( 8,0) = ',d20.12,/,
     &           15x,'C(10,0) = ',d20.12,/,
     &           15x,'C(12,0) = ',d20.12,/,
     &           15x,'C(14,0) = ',d20.12,/,
     &           15x,'C(16,0) = ',d20.12,/,
     &           15x,'C(18,0) = ',d20.12,/,
     &           15x,'C(20,0) = ',d20.12)
c
        if (isub.eq.0.and.imod.eq.1.and.iehm.eq.0) write(6,6007)
 6007   format(//15x,'Ref. Values Are Not Subtracted From Even Zonals.')
c
      endif  !  igrs
c
c-----------------------------------------------------------------------
c
      write(6,5000)
      write(6,6001)
 6001 format(15x,'Output Quantity',/,
     &       15x,'---------------',//)
      write(6,5011) isw
 5011 format(15x,'Computation for isw = ',i3,':',//)
      if (isw.eq.0) write(6,6002)
 6002 format(15x,'Height Anomaly ..............................(m).')
      if (isw.eq.1) write(6,6003)
 6003 format(15x,'Spherical BVP Gravity Anomaly ............(mGal).')
      if (isw.eq.2) write(6,6004)
 6004 format(15x,'Elevation ...................................(m).')
      if (isw.eq.3) write(6,6041)
 6041 format(15x,'Radial Anomaly Gradient ...............(mGal/km).')
      if (isw.eq.4) write(6,6042)
 6042 format(15x,'Radial Height Anom. Gradient .............(m/km).')
      if (isw.eq.5) write(6,6043)
 6043 format(15x,'Gravity Anomaly Syst. Bias ...............(mGal).')
      if (isw.eq.6) write(6,6044)
 6044 format(15x,'Gravity Anom. 2nd Deriv. w.r.t Radial (mGal/km^2).')
      if (isw.eq.7) write(6,6045)
 6045 format(15x,'Vertical Deflection (xi) ...........(arcseconds).')
      if (isw.eq.8) write(6,6046)
 6046 format(15x,'Vertical Deflection (eta) ..........(arcseconds).')
      if (isw.eq.9) write(6,6047)
 6047 format(15x,'Gravity Disturbance (d_r) ................(mGal).')
      if (isw.eq.10) write(6,6048)
 6048 format(15x,'Gravity Disturbance (d_psi) ..............(mGal).')
      if (isw.eq.11) write(6,6049)
 6049 format(15x,'Gravity Disturbance (d_lambda) ...........(mGal).')
      if (isw.eq.12) write(6,6050)
 6050 format(15x,'Radial Second Deriv. of T (Trr) .. (Eotvos unit).')
      if (isw.eq.13) write(6,6051)
 6051 format(15x,'Lat_nl Second Deriv. of T (Tyy) .. (Eotvos unit).')
      if (isw.eq.14) write(6,6052)
 6052 format(15x,'Long_l Second Deriv. of T (Txx) .. (Eotvos unit).')
      if (isw.eq.50) write(6,6054)
 6054 format(15x,'Linearised BVP Gravity Anomaly ...........(mGal).')
      if (isw.eq.80.or.isw.eq.81.or.isw.eq.82) write(6,6057)
c-----------------------------------------------------------------------
c6057 format(15x,'Height Anomaly and Geoid Undulation .........(m).')
c-----------------------------------------------------------------------
 6057 format(15x,'Geoid Undulation ............................(m).')
      if (isw.eq.100) write(6,6053)
 6053 format(15x,'Gravity Anomalies From Ell. Harmonics ... (mGal).')
      if (isw.eq.101) write(6,6056)
 6056 format(15x,'Surface Ellipsoidal Harmonics .............. (m).')
c
      write(6,5012) exclud
 5012 format(//,15x,'Excluded Data Flag = ',f12.2)
c
c-----------------------------------------------------------------------
c
c     -EXTRACT NON-BLANK CHARACTERS FROM PATHNAMES AND FILENAMES
c     -READ SPHERICAL HARMONIC GEOPOTENTIAL MODELS ONLY
c
c-----------------------------------------------------------------------
c
      call extract_name(path_mod,pmodl,nchr_pmodl)
c
      if (imod.eq.1) then
c
        call extract_name(name_mod,nmodl,nchr_nmodl)
        fnu01=pmodl(1:nchr_pmodl)//nmodl(1:nchr_nmodl)
        write(6,6202) nmodl,lmin,lmax,aegm,gmegm
 6202   format(//,15x,'Gravitational Model: ',a40,
     &         //,15x,'(Lmin = ',i4,5x,'Lmax = ',i4,').',
     &         //,15x,'aegm  = ',d20.12,'   (m)',
     &          /,15x,'gmegm = ',d20.12,'   (m**3/S**2)')
c
        if (iehm.eq.0) then
          open(iumi,file=fnu01,form='formatted',status='old',iostat=ios)
          if (ios.ne.0) then
            write(6,1001) fnu01
            write(6,5000)
            stop
          endif  !  ios  
          call dhcsin(1,iumi,lmin,lmax,isub,cz,grat,arat,dc20,cnm,snm,
     &                egm_tf,egm_zt,nmax0)
          close(iumi)
        endif  !  iehm
      endif  !  imod
c
      if (ihgt.eq.1) then
c
        call extract_name(name_hgt,nhght,nchr_nhght)
        fnu02=pmodl(1:nchr_pmodl)//nhght(1:nchr_nhght)
        write(6,6203) nhght,kmin,kmax
 6203   format(//,15x,'Elevation Model: ',a40,
     &         //,15x,'(Kmin = ',i4,5x,'Kmax = ',i4,').')
c
      endif  !  ihgt
c
      if (icor.eq.1) then
c
        call extract_name(name_cnv,nconv,nchr_nconv)
        fnu03=pmodl(1:nchr_pmodl)//nconv(1:nchr_nconv)
        write(6,6204) nconv,jmin,jmax
 6204   format(//,15x,'Correction Model: ',a40,
     &         //,15x,'(Jmin = ',i4,5x,'Jmax = ',i4,').')
c
      endif  !  icor
c
      if (igrid.eq.0) then
c
        if (isw.eq.80) then
          write(6,6211)
          write(6,6212)
        elseif (isw.eq.81) then
          write(6,6211)
          write(6,6213)
        elseif (isw.eq.82) then
          write(6,6214)
        endif  !  isw
c
 6211   format(//,15x,'Correction to height anomaly computed from ',
     &                'free-air ',
     &          /,15x,'anomaly and orthometric height.')
 6212   format(//,15x,'Orthometric height read from coordinate file.')
 6213   format(//,15x,'Orthometric height from spherical harmonic ',
     &                'elevation model.')
 6214   format(//,15x,'Correction to height anomaly computed from ',
     &                'spherical',/15x,'harmonic model.')
c
      endif  !  0
c
c-----------------------------------------------------------------------
c
c     GRIDDED COMPUTATION OPTION STARTS HERE
c
c-----------------------------------------------------------------------
c
      if (igrid.eq.1) then
c
        write(6,5000)
        write(6,5002)
 5002   format(15x,'Output on a Regular Lat-long Grid',/,
     &         15x,'---------------------------------',//)
c
        if (iflag.eq.0) write(6,6005)
 6005   format(15x,'Point Value Computations - Point Values of Pnm.',//)
        if (iflag.eq.1) write(6,6006)
 6006   format(15x,'Mean Value Computations - Integrals of Pnm.',//)
c
        if (iflag.eq.1) then
          do nr = 1, nrows
            phi1 = dnorth - (nr-1)*dlat
            phi2 = dnorth - (nr  )*dlat
            if (phi1.gt.1.d-10.and.phi2.lt.-1.d-10) then
              write(6,1000)
              stop
            endif  !  phi1, phi2
          enddo  !  nr
        endif  !  iflag
c
 1000   format(15x,''//
     &         15x,'A  band  of  geographic rectangles is straddling'/,
     &         15x,'the equator. This program will not evaluate area'/,
     &         15x,'means  for  such  rectangles.  To  rectify  this'/,
     &         15x,'problem,  ensure  that the latitudinal blocksize'/,
     &         15x,'(dlat) of your grid is an integer divisor of the'/,
     &         15x,'latitude of your northern grid boundary (dnorth).'/)
c
c-----------------------------------------------------------------------
c
        if (iell.eq.0) then
          rcmp = rme + alt
          write(6,6023) rcmp,alt
        endif  !  iell
c
        if(iell.eq.1) then
          write(6,6024)
          if (iglat.eq.0) write(6,6026)
          if (iglat.eq.1) write(6,6027)
          if (iglat.eq.2) write(6,6028)
        endif  !  iell
c
 6026   format(15x,'The grid is in terms of GEODETIC latitude.',//)
 6027   format(15x,'The grid is in terms of GEOCENTRIC latitude.',//)
 6028   format(15x,'The grid is in terms of REDUCED latitude.',//)
c
 6023   format(15x,'Computed values refer to the surface of a sphere',/
     $         15x,'of radius ',f12.3,'m (Altitude = ',f9.3,'m).',///
     $         15x,'The grid is in terms of GEOCENTRIC latitude.',//)
 6024   format(15x,'Computed values refer to the surface of the ',/
     $         15x,'reference ellipsoid.',//)
c
c-----------------------------------------------------------------------
c
        dsth = dnorth - (nint((dnorth-dsouth)/dlat))*dlat
        dest = dwest  + (nint((deast - dwest)/dlon))*dlon
c
        write(6,6025) dnorth,dsth,dwest,dest,dlat*60.d0,dlon*60.d0,
     $              nrows,ncols
 6025   format(15x,'Grid Geometry:',//,
     $  15x,'Latitude  of Northern most    row = ',f8.3,' (Degrees).',/,
     $  15x,'Latitude  of Southern most    row = ',f8.3,' (Degrees).',/,
     $  15x,'Longitude of  Western most column = ',f8.3,' (Degrees).',/,
     $  15x,'Longitude of  Eastern most column = ',f8.3,' (Degrees).',/,
     $  15x,'                 Latitude spacing = ',f8.3,' (Minutes).',/,
     $  15x,'                Longitude spacing = ',f8.3,' (Minutes).',/,
     $//15x,i6,' Rows x ',i6,' Columns of values output.')
c
c-----------------------------------------------------------------------
c
c       READ NON-SPHERICAL-HARMONIC-GEOPOTENTIAL COEFFICIENT FILES
c
c-----------------------------------------------------------------------
c
        if (imod.eq.1.and.iehm.eq.1) then
          open(iumi,file=fnu01,form='formatted',status='old',iostat=ios)
          if (ios.ne.0) then
            write(6,1001) fnu01
            write(6,5000)
            stop
          endif  !  ios  
          call dhcsin(0,iumi,lmin,lmax,0,cz,grat,arati,0.d0,cnm,snm,
     &                egm_tf,egm_zt,nmax0)
          close(iumi)
        endif  !  imod;iehm
c
        if (ihgt.eq.1) then
          open(iuhi,file=fnu02,form='formatted',status='old',iostat=ios)
          if (ios.ne.0) then
            write(6,1001) fnu02
            write(6,5000)
            stop
          endif  !  ios  
          call dhcsin(0,iuhi,kmin,kmax,0,cz,1.d0,1.d0,0.d0,cnm,snm,
     &         egm_tf,egm_zt,nmax0)
          close(iuhi)
        endif  !  ihgt
c
        if (icor.eq.1) then
          open(iuci,file=fnu03,form='formatted',status='old',iostat=ios)
          if (ios.ne.0) then
            write(6,1001) fnu03
            write(6,5000)
            stop
          endif  !  ios  
          call dhcsin(0,iuci,jmin,jmax,0,cz,1.d0,1.d0,0.d0,cnm,snm,
     &                egm_tf,egm_zt,nmax0)
          close(iuci)
        endif  !  icor
c
c-----------------------------------------------------------------------
c
c       SYNTHESIS OF GRIDDED VALUES
c
c-----------------------------------------------------------------------
c       call flush(6)
c       timesy0 = secife()
c-----------------------------------------------------------------------
        nloop = int(nrows/maxr)
        if (nloop*maxr.lt.nrows) nloop = nloop + 1
c
        nrdat = 0
        do loop = 1, nloop
c
          nrbch = maxr
          if (loop.eq.nloop) nrbch = nrows - (loop-1)*maxr
          xnrth = dnorth - (loop-1)*maxr*dlat
c
          if (imod.eq.1) then
c
            call hsynth(xnrth,nrbch,dwest,ncols,dlat,dlon,batch,pt,
     &                  lmin,lmax,cnm,snm,cz,igrid,iglat,iflag,isw,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
          elseif (ihgt.eq.1) then
c
            call hsynth(xnrth,nrbch,dwest,ncols,dlat,dlon,batch,pt,
     &                  kmin,kmax,cnm,snm,cz,igrid,iglat,iflag,isw,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
          elseif (icor.eq.1) then
c
            call hsynth(xnrth,nrbch,dwest,ncols,dlat,dlon,batch,pt,
     &                  jmin,jmax,cnm,snm,cz,igrid,iglat,iflag,isw,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
          endif  !  imod;ihgt
c
          do nr = 1, nrbch
            nrdat = nrdat + 1
            ndat = ncols*(nr-1)
c
            do nc = 1, ncols
              data(nc,nrdat) = batch(ndat+nc)
            enddo  !  nc
          enddo  !  nr
c
cc          write(11,*) 'synthesis to row ',nrdat
c         call flush(11)
cc          close(8)
c
        enddo  !  loop
c
c-----------------------------------------------------------------------
c
c       ADD ZERO-DEGREE TERMS TO HT. ANOMALIES AND GEOID HTS. ONLY
c
c-----------------------------------------------------------------------
c
        if (isw.eq.0) then
          do i = 1, nrows
            do j = 1, ncols
              data(j,i) = data(j,i) + zeta0
            enddo  !  j
          enddo  !  i
        endif  !  isw
c
c-----------------------------------------------------------------------
c       timesy1 = secife()
c       xtimesy = timesy1 - timesy0
c-----------------------------------------------------------------------
c
c       PRINT SAMPLE OUTPUT FOR GLOBAL COMPUTATIONS.
c
c-----------------------------------------------------------------------
c
        write(6,5000)
        write(6,5003)
 5003   format(15x,'Sample Output',/,
     &         15x,'-------------')
c
        do j = 1 ,ncols
          ddlon(j) = dwest +(j-1)*dlon +(dlon/2.d0)*icent
        enddo  !   j
c
        do i = 1, nrows
c
          xflat = dnorth -(i-1+icent)*dlat
          flatc = dnorth -(i-1)*dlat -(dlat/2.d0)*icent
          flatn = flatc +dlat/2.d0
          flats = flatc -dlat/2.d0
c
          if (dmod(xflat,30.d0).eq.0.d0) then
            if (iflag.eq.1) then
              write(6,6019) flatn,flats
            else
              write(6,6021) flatc
            endif  !  iflag
c
            write(6,6022) (ddlon(j),data(j,i),j=1,ncols)
c
          endif  !  xflat
c
        enddo  !  i
c
 6019   format(//,3x,'Latitude Belt From ',f10.5,' to ',
     &                             f10.5,' Deg.',//)
 6021   format(//,3x,'Latitude = ',f10.5,' Deg.',//)
 6022   format(6(2x,f6.2,2x,f10.3))
c
c-----------------------------------------------------------------------
c
c       WRITE RESULTS TO UNIT 10
c
c-----------------------------------------------------------------------
c
        xlmin  = lmin   *1.d0
        xlmax  = lmax   *1.d0
        xisub  = isub   *1.d0
        xisw   = isw    *1.d0
        xiglat = iglat  *1.d0
        xiflag = iflag  *1.d0
        xiell  = iell   *1.d0
        xicell = icell  *1.d0
        xkmin  = kmin   *1.d0
        xkmax  = kmax   *1.d0
        xjmin  = jmin   *1.d0
        xjmax  = jmax   *1.d0
        xncols = ncols  *1.d0
        xnrows = nrows  *1.d0
c
        close(10)
        open(10,file=fnu10,form='unformatted',status='new',iostat=ios)
        if (ios.ne.0) then
          write(6,1001) fnu10
          write(6,5000)
          stop
        endif  !  ios  
c
        write(10) xlmin,xlmax,aegm,gmegm,xisub,xisw,exclud,ae,gm,omega,
     &            c20,rf,xiglat,xiflag,xiell,xicell,dlat,dlon,dwest,
     &            deast,dnorth,dsouth,rme,alt,xkmin,xkmax,xjmin,xjmax,
     &            xncols,xnrows,c20_z,revf,j2z,b,e2,geqt,gpol,dk,fm,
     &            cz(2),cz(4),cz(6),cz(8),cz(10),cz(12),cz(14),cz(16),
     &            cz(18),cz(20),egm_tf,egm_zt,dc20,j2z
c
c-----------------------------------------------------------------------
c
        write(6,5000)
        write(6,6039)
 6039   format(15x,'Statistics of Output Values',//)
        do i = 1, nrows
          do j = 1, ncols
            scrd(j,1) = data(j,i)
            scrd(j,2) = 1.d0
          enddo  !  j
          write(10) (data(j,i),j=1,ncols)
          call stats(dnorth,dwest,i,dlat,dlon,nrows,ncols,scrd,exclud,
     &               0,statd,icent)
        enddo  !  i
c
        close(10)
c
c-----------------------------------------------------------------------
c       write(6,5000)
c       time1 = secife()
c       xtime = time1-time0
c       write(6,6040) xtime
c6040   format(15x,'Total Time     = ',f10.3,'  CPU seconds.',//)
c       write(6,6038) xtimesy
c6038   format(15x,'Synthesis Time = ',f10.3,'  CPU seconds.')
c-----------------------------------------------------------------------
        write(6,5000)
        write(6,5016) nout
 5016   format(15x,'Binary Output File : ',a80)
        write(6,5000)
        write(6,6925)
        write(6,5000)
c
c-----------------------------------------------------------------------
c
c     SCATTERED POINT COMPUTATIONS
c
c-----------------------------------------------------------------------
c
      elseif (igrid.eq.0) then
c
        pi   = 4.d0*datan(1.d0)
        dtr  = pi/180.d0
c
        write(6,5000)
        write(6,5004)
 5004   format(15x,'Output at Scattered Points',/,
     &         15x,'--------------------------',//)
c-----------------------------------------------------------------------
c       timesy = 0.0
c-----------------------------------------------------------------------
        call extract_name(path_pnt,ppnts,nchr_ppnts)
        call extract_name(name_pnt,npnts,nchr_npnts)
        fnu12=ppnts(1:nchr_ppnts)//npnts(1:nchr_npnts)
        write(6,6100) npnts
 6100   format(15x,'Scattered Coordinate File: ',a40/)
c
        close(10)
        open(10,file=fnu10,form='formatted',status='new',iostat=ios)
        if (ios.ne.0) then
          write(6,1001) fnu10
          write(6,5000)
          stop
        endif  !  ios  
c
c-----------------------------------------------------------------------
c
        if (isw.eq.2.or.isw.eq.5.or.isw.eq.100.or.isw.eq.101) then
          write(10,6081)
          write(6,6081)
        elseif (isw.eq.80.or.isw.eq.81) then
          write(10,6082)
          write(6,6082)
        elseif (isw.eq.82) then
c-----------------------------------------------------------------------
c         write(10,6083)
          write(6,6083)
c-----------------------------------------------------------------------
        else
          write(10,6084)
          write(6,6084)
        endif  !  isw
c
 6081   format(/15x,'it ','     Lat.    ','    Lon.    ','  Value   ',/)
 6082   format(/15x,'it ','     Lat.    ','    Lon.    ','  h or r  ',
     &           '    Horth  ',
     &           '    zeta  ','      C    ','    N    ',/)
c-----------------------------------------------------------------------
c6083   format(/15x,'it ','     Lat.    ','    Lon.    ',
c    &           '    zeta*  ','     C     ','   N     ',/)
c-----------------------------------------------------------------------
 6083   format(/15x,'     Lat.    ','    Lon.    ','       N     ',/)
 6084   format(/15x,'it ','     Lat.    ','    Lon.    ','  h or r  ',
     &           '    value  ',/)
c
c-----------------------------------------------------------------------
c
c       READ ALL INPUT COORDINATES FROM CONTROL FILE
c
c-----------------------------------------------------------------------
c
        open(iusc,file=fnu12,form='formatted',status='old',iostat=ios)
        if (ios.ne.0) then
          write(6,1001) fnu12
          write(6,5000)
          stop
        endif  !  ios  
c
        if (isw.eq.2.or.isw.eq.5.or.isw.eq.82.or.
     &                                    isw.eq.100.or.isw.eq.101) then
          ir = 1
        elseif (isw.eq.80) then
          ir = 2
        else
          ir = 3
        endif  !  isw
c
        ic   = 0
c
        itx = 1
c
        do nr = 1, maxpt
c
          if (ir.eq.1) read(iusc,*,end=1010) xflat,xflon
          if (ir.eq.2) read(iusc,*,end=1010) xflat,xflon,xdist,
     &                                                          xhorth
          if (ir.eq.3) read(iusc,*,end=1010) xflat,xflon,xdist
c
          if (itx.ne.1.and.itx.ne.2) then
            write(6,6089)
 6089       format(///,10x,'Inadmissible IT - Execution Stopped.',//)
            stop
          endif  !  itx
c
          if (ir.eq.1) then
            xdist = 0.d0
            if (itx.eq.2) then
              t_c = dcos(xflat*dtr)
              xdist = ae*dsqrt(e21)/dsqrt(1.d0-e2*t_c*t_c)
            endif  !  itx
          endif   !  ir
c
          ic = ic + 1
          it_a(nr)    = itx
          flat_a(nr)  = xflat
          flon_a(nr)  = xflon
          dist_a(nr)  = xdist
          horth_a(nr) = xhorth
c
        enddo  !  maxpt
c
 1010   continue
        close(iusc)
c
c-----------------------------------------------------------------------
c
c       PERFORM ALL SYNTHESIS TASKS REQUIRING GEOPOTENTIAL COEFFICIENTS
c
c-----------------------------------------------------------------------
c
        if (imod.eq.1) then
c
          if (iehm.eq.1) then
            open(iumi,file=fnu01,form='formatted',status='old',
     &           iostat=ios)
            if (ios.ne.0) then
              write(6,1001) fnu01
              write(6,5000)
              stop
            endif  !  ios  
            call dhcsin(0,iumi,lmin,lmax,0,cz,grat,arati,0.d0,cnm,snm,
     &                  egm_tf,egm_zt,nmax0)
            close(iumi)
          endif  !  iehm
c
          nrall = 0
 3000     continue
c
            nrfn = 0
            do nr = 1, maxr
c
              nrfn  = nrfn  + 1
              nrall = nrall + 1
c
              it(nr)   = it_a(nrall)
              flat(nr) = flat_a(nrall)
              flon(nr) = flon_a(nrall)
              dist(nr) = dist_a(nrall)
c
              if (nrall.eq.ic) goto 3010
c
            enddo  !  nr
c
 3010     continue
c-----------------------------------------------------------------------
c         timesy0 = secife()
c-----------------------------------------------------------------------
          if (isw.lt.80.or.isw.ge.100) then
c
            call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  lmin,lmax,cnm,snm,cz,igrid,iglat,0,isw,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
            nrdif = nrall - nrfn
            do nr = 1, nrfn
              pt_a(nr+nrdif) = pt(nr)
            enddo  !  nr
c
          endif  !  isw
c
          if (isw.ge.80.and.isw.le.82) then
c
            call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  lmin,lmax,cnm,snm,cz,igrid,iglat,0,0,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
            nrdif = nrall - nrfn
            do nr = 1, nrfn
              zeta(nr+nrdif) = pt(nr)
            enddo  !  nr
c
            if (isw.eq.80.or.isw.eq.81) then
c
              call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  lmin,lmax,cnm,snm,cz,igrid,iglat,0,1,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
              nrdif = nrall - nrfn
              do nr = 1, nrfn
                ga(nr+nrdif) = pt(nr)
              enddo  !  nr
c
            endif  !  isw
c
          endif  !  isw
c-----------------------------------------------------------------------
c         timesy1 = secife()
c         dtimesy = timesy1 - timesy0
c         timesy  = timesy + dtimesy
c-----------------------------------------------------------------------
cc          write(11,*) 'potential synthesis to point ',nrall
c         call flush(11)
cc          close(8)
c
          if (nrall.lt.ic) goto 3000
c
        endif  !  imod
c
c-----------------------------------------------------------------------
c
c       PERFORM ALL SYNTHESIS TASKS REQUIRING HEIGHT COEFFICIENTS
c
c-----------------------------------------------------------------------
c
        if (ihgt.eq.1) then
c
          open(iuhi,file=fnu02,form='formatted',status='old',iostat=ios)
          if (ios.ne.0) then
            write(6,1001) fnu02
            write(6,5000)
            stop
          endif  !  ios  
          call dhcsin(0,iuhi,kmin,kmax,0,cz,1.d0,1.d0,0.d0,cnm,snm,
     &                egm_tf,egm_zt,nmax0)
          close(iuhi)
c
c-----------------------------------------------------------------------
c
          nrall = 0
 3020     continue
c
            nrfn = 0
            do nr = 1, maxr
c
              nrfn  = nrfn  + 1
              nrall = nrall + 1
c
              it(nr)   = it_a(nrall)
              flat(nr) = flat_a(nrall)
              flon(nr) = flon_a(nrall)
              dist(nr) = dist_a(nrall)
c
              if (nrall.eq.ic) goto 3030
c
            enddo  !  nr
c
 3030     continue
c-----------------------------------------------------------------------
c         timesy0 = secife()
c-----------------------------------------------------------------------
          if (isw.lt.80) then
c
            call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  kmin,kmax,cnm,snm,cz,igrid,iglat,0,isw,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
            nrdif = nrall - nrfn
            do nr = 1, nrfn
              pt_a(nr+nrdif) = pt(nr)
            enddo  !  nr
c
          endif  !  isw
c
          if (isw.eq.81) then
c
            call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  kmin,kmax,cnm,snm,cz,igrid,iglat,0,2,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
            nrdif = nrall - nrfn
            do nr = 1, nrfn
              horth_a(nr+nrdif) = pt(nr)
            enddo  !  nr
c
          endif  !  isw
c-----------------------------------------------------------------------
c         timesy1 = secife()
c         dtimesy = timesy1 - timesy0
c         timesy = timesy + dtimesy
c-----------------------------------------------------------------------
cc          write(11,*) 'height synthesis to point ',nrall
c         call flush(11)
cc          close(8)
c
          if (nrall.lt.ic) goto 3020
c
        endif  !  ihgt
c
c-----------------------------------------------------------------------
c
c       PERFORM ALL SYNTHESIS TASKS REQUIRING CORRECTION COEFFICIENTS
c
c-----------------------------------------------------------------------
c
        if (icor.eq.1) then
c
          open(iuci,file=fnu03,form='formatted',status='old',iostat=ios)
          if (ios.ne.0) then
            write(6,1001) fnu03
            write(6,5000)
            stop
          endif  !  ios  
          call dhcsin(0,iuci,jmin,jmax,0,cz,1.d0,1.d0,0.d0,cnm,snm,
     &                egm_tf,egm_zt,nmax0)
          close(iuci)
c
c-----------------------------------------------------------------------
c
          nrall = 0
 3040     continue
c
            nrfn = 0
            do nr = 1, maxr
c
              nrfn  = nrfn  + 1
              nrall = nrall + 1
c
              it(nr)   = it_a(nrall)
              flat(nr) = flat_a(nrall)
              flon(nr) = flon_a(nrall)
              dist(nr) = dist_a(nrall)
c
              if (nrall.eq.ic) goto 3050
c
            enddo  !  nr
c
 3050     continue
c-----------------------------------------------------------------------
c         timesy0 = secife()
c-----------------------------------------------------------------------
          if (isw.lt.80) then
c
            call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  jmin,jmax,cnm,snm,cz,igrid,iglat,0,isw,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
            nrdif = nrall - nrfn
            do nr = 1, nrfn
              pt_a(nr+nrdif) = pt(nr)
            enddo  !  nr
c
          endif  !  isw
c
          if (isw.eq.82) then
c
            call hsynth(dnorth,nrfn,dwest,ncols,dlat,dlon,batch,pt,
     &                  jmin,jmax,cnm,snm,cz,igrid,iglat,0,2,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
            nrdif = nrall - nrfn
            do nr = 1, nrfn
              corr(nr+nrdif) = pt(nr)
            enddo  !  nr
c
          endif  !  isw
c-----------------------------------------------------------------------
c         timesy1 = secife()
c         dtimesy = timesy1 - timesy0
c         timesy = timesy + dtimesy
c-----------------------------------------------------------------------
cc          write(11,*)'correction synthesis to point ',nrall
c         call flush(11)
cc          close(8)
c
          if (nrall.lt.ic) goto 3040
c
        endif  !  icor
c
c-----------------------------------------------------------------------
c
        call ptsynth(ic,flat_a,flon_a,dist_a,horth_a,pt_a,ga,zeta,corr,
     &               rme,grsv,it_a,isw,zeta0)
        close(10)
c
c-----------------------------------------------------------------------
c       write(6,5000)
c       time1 = secife()
c       xtime = time1-time0
c       write(6,6040) xtime
c       write(6,6038) timesy
c-----------------------------------------------------------------------
c       tpp = timesy/dfloat(ic)
c       write(6,6923) ic,tpp
c6923   format(//15x,'Total number of points    = ',i6,///
c    $           15x,'Execution time per point  = ',f6.3,1x,'seconds')
c-----------------------------------------------------------------------
        write(6,5000)
        write(6,6923) ic
 6923   format(15x,'Total number of points    = ',i6)
        write(6,5000)
        write(6,5017) nout
 5017   format(15x,'ASCII Output File : ',a80)
        write(6,5000)
        write(6,6925)
 6925   format(27x,'Normal Termination')
        write(6,5000)
      endif  !  igrid
c
 1001 format(//,5x,'FILE ERROR: PROBLEM WITH ',a120)           
 5000 format(//,'c',71('-'),//)
c
      stop
      end
c
c-----------------------------------------------------------------------
c
      SUBROUTINE STATS(TOPLAT,WSTLON,I,GRDN,GRDE,is,NCOLS,DATA,
     $                 EXCLUD,ISIG,STAT,icent)
C-----------------------------------------------------------------------
      IMPLICIT REAL*8(A-H,O-Z)
      CHARACTER*20 DLABEL(14)
      CHARACTER*20 SLABEL( 8)
      DIMENSION DATA(NCOLS,2)
      DOUBLE PRECISION DEXCLUD,DG,SD,STAT(22)
      SAVE
      data ix/0/
      DATA PI/3.14159265358979323846D+00/
      DATA DLABEL/'    Number of Values','  Percentage of Area',
     $            '       Minimum Value',' Latitude of Minimum',
     $            'Longitude of Minimum','       Maximum Value',
     $            ' Latitude of Maximum','Longitude of Maximum',
     $            '     Arithmetic Mean','  Area-Weighted Mean',
     $            '      Arithmetic RMS','   Area-Weighted RMS',
     $            '   Arithmetic S.Dev.','Area-Weighted S.Dev.'/
      DATA SLABEL/'       Minimum Sigma',' Latitude of Minimum',
     $            'Longitude of Minimum','       Maximum Sigma',
     $            ' Latitude of Maximum','Longitude of Maximum',
     $            'Arithmetic RMS Sigma','Area-wghtd RMS Sigma'/
C-----------------------------------------------------------------------
      IF(ix.EQ.0) THEN
        ix = 1
        DEXCLUD=EXCLUD
        DTR=PI/180.D0
        FOURPI=4.D0*PI
        DPR=GRDN*DTR
        DLR=GRDE*DTR
        CAREA=2.D0*DLR*SIN(DPR/2.D0)
        DO 10 K=1,22
        STAT(K)=0.D0
   10   CONTINUE
        STAT( 3)= DEXCLUD
        STAT( 6)=-DEXCLUD
        STAT(15)= DEXCLUD
        STAT(18)= 0.D0
      ENDIF  !  ix
C-----------------------------------------------------------------------
c
      dlat = toplat -(i-1.d0)*grdn - (grdn/2.d0)*icent
      COLATC=(90.D0-DLAT)*DTR
      AREA=CAREA*SIN(COLATC)
c
c   The following statement avoids over-estimating the total area
c   covered by the grid (of POINT values) when the pole(s) are part
c   of the grid.
c
      if(abs(dlat).eq.90.d0) area=2.d0*dlr*sin(dpr/4.d0)**2
c
C-----------------------------------------------------------------------
      DO 110 J=1,NCOLS
      DLON=WSTLON+(J-1.D0)*GRDE+GRDE/2.D0
      DG=DATA(J,1)
      SD=DATA(J,2)
      IF(DG.LT.DEXCLUD) THEN
C-----------------------------------------------------------------------
      STAT( 1)=STAT( 1)+1.D0
      STAT( 2)=STAT( 2)+AREA
      IF(DG.LE.STAT( 3)) THEN
      STAT( 3)=DG
      STAT( 4)=DLAT
      STAT( 5)=DLON
      ENDIF
      IF(DG.GE.STAT( 6)) THEN
      STAT( 6)=DG
      STAT( 7)=DLAT
      STAT( 8)=DLON
      ENDIF
      STAT( 9)=STAT( 9)+DG
      STAT(10)=STAT(10)+DG*AREA
      STAT(11)=STAT(11)+DG**2
      STAT(12)=STAT(12)+DG**2*AREA
      IF(SD.LE.STAT(15)) THEN
      STAT(15)=SD
      STAT(16)=DLAT
      STAT(17)=DLON
      ENDIF
      IF(SD.GE.STAT(18)) THEN
      STAT(18)=SD
      STAT(19)=DLAT
      STAT(20)=DLON
      ENDIF
      STAT(21)=STAT(21)+SD**2
      STAT(22)=STAT(22)+SD**2*AREA
C-----------------------------------------------------------------------
      ENDIF
  110 CONTINUE
C-----------------------------------------------------------------------
      IF(I.NE.is) RETURN
      IF(STAT(1).GT.0.D0) THEN
      STAT( 9)=STAT( 9)/STAT( 1)
      STAT(10)=STAT(10)/STAT( 2)
      STAT(11)=SQRT(STAT(11)/STAT( 1))
      STAT(12)=SQRT(STAT(12)/STAT( 2))
      STAT(13)=SQRT(STAT(11)**2-STAT( 9)**2)
      STAT(14)=SQRT(STAT(12)**2-STAT(10)**2)
      STAT(21)=SQRT(STAT(21)/STAT( 1))
      STAT(22)=SQRT(STAT(22)/STAT( 2))
      STAT( 2)=STAT( 2)/FOURPI*100.D0
      ELSE
      DO 120 J=3,22
      STAT(J)=DEXCLUD
  120 CONTINUE
      ENDIF
C=======================================================================
      NUM=INT(STAT(1))
      WRITE(6,6001) DLABEL(1),NUM
 6001 FORMAT(5X,A20,3X,I11)
      DO 210 K=2,14
      WRITE(6,6002) DLABEL(K),STAT(K)
 6002 FORMAT(5X,A20,3X,F15.3)
  210 CONTINUE
      WRITE(6,6003)
 6003 FORMAT(' ')
      IF(ISIG.EQ.1) THEN
      DO 220 K=1,8
      WRITE(6,6002) SLABEL(K),STAT(K+14)
  220 CONTINUE
      ENDIF
C=======================================================================
      RETURN
      END
c
c-----------------------------------------------------------------------
c
      SUBROUTINE GRS(A,RF,J2,GM,OMEGA,B,E2,E21,GEQT,GPOL,DK,FM,Q0,
     $               ZONALS,DA)
C-----------------------------------------------------------------------
C
C   SUBROUTINE TO COMPUTE VARIOUS DERIVED CONSTANTS FOR ANY
C   GEODETIC REFERENCE SYSTEM DEFINED BY FOUR FUNDAMENTAL (INPUT)
C   CONSTANTS:
C
C        A = SEMI-MAJOR AXIS .....................(m)
C       RF = INVERSE FLATTENING
C   OR, J2 = SECOND DEGREE ZONAL HARMONIC
C       GM = GEOCENTRIC GRAVITATIONAL CONSTANT ...(m^3/s^2)*1.d5
C    OMEGA = ROTATIONAL RATE .....................(rad/s)
C
C   NOTE THAT DEPENDING ON WHICH ONE OF (RF,J2) IS USED IN THE
C   DEFINITION OF THE SYSTEM, THE OTHER ONE SHOULD BE SET TO
C   ZERO WHEN THE S/R IS CALLED. THE S/R WILL RETURN ITS DERIVED
C   VALUE.
C
C   THE SUBROUTINE RETURNS :
C
C       RF = INVERSE FLATTENING
C        B = SEMI-MINOR AXIS .....................(m)
C       E2 = FIRST ECCENTRICITY SQUARED
C      E21 = 1.D0 - E2
C     GEQT = NORMAL GRAVITY AT THE EQUATOR .......(mGal)
C     GPOL = NORMAL GRAVITY AT THE POLE ..........(mGal)
C       DK = B*GPOL/(A*GEQT)-1.D0
C       Q0 = [Heiskanen & Moritz, 1967, p. 66, eq. (2-58)]
C   ZONALS = EVEN ZONALS OF THE CORRESPONDING SOMIGLIANA-PIZZETTI
C            NORMAL FIELD  (N=1,2,...,10 ==> J2,J4,...,J20)
C       DA = COEFFICIENTS FOR THE TRANSFORMATION OF THE GRAVITY
C            ANOMALY FROM THE SYSTEM (1) (SEE THE CHOICES BELOW)
C            TO THE SYSTEM (2) WHOSE DEFINITION IS MADE THROUGH
C            THE FOUR (INPUT) CONSTANTS IN THE CALLING STATEMENT
C            DA (N=0,4) ..........................(mGal/rad**2n)
C
C   THE SUBROUTINE REQUIRES THE EXTERNAL FUNCTION "DJ2N" FOR THE
C   COMPUTATION OF THE EVEN ZONALS.
C   ALL COMPUTATIONS ARE MADE IN ACCORDANCE TO THE RECOMMENDATIONS
C   OF MORITZ (1984) GIVEN IN THE SPECIAL PUBLICATION OF B.G. FOR
C   THE GRS80.
C
C-----------------------------------------------------------------------
C           S/R WRITTEN BY : NIKOS K. PAVLIS  IN JUNE 1988
C         LAST MODIFIED BY : NIKOS K. PAVLIS  IN APR. 2002
C-----------------------------------------------------------------------
C     CONVERTED TO 8-BYTE FORTRAN:                SIMON HOLMES, AUG 2005
C-----------------------------------------------------------------------
      IMPLICIT REAL*8(A-H,O-Z)
      REAL*8 A,RF,GM,OMEGA,B,E2,E21,GEQT,GPOL,DK,FM,ZONALS(10),DA(5)
      REAL*8 Q0
      REAL*8 J2,J2I(2)
      DIMENSION AEI(2),RFI(2),GMI(2),OMI(2),
     $          F(2),BI(2),FMI(2),EP(2),EP2(2),TWOQ0(2),Q0P(2),F1(2),
     $          GEQTI(2),GPOLI(2),DKI(2),E2I(2),E21I(2),GA(2,4)
C------- GRS 1967 ------------------------------
C
C     AEI(1)=6378160.D0
C     J2I(1)=108270.D-8
C     GMI(1)=0.398603D20
C     OMI(1)=7292115.1467D-11
C     RFI(1)=0.D0
CDRVD RFI(1)=298.247167427D0
C
C------- GRS 1980 ------------------------------
C
      AEI(1)=6378137.D0
      J2I(1)=108263.D-8
      GMI(1)=0.3986005D20
      OMI(1)=7292115.D-11
      RFI(1)=0.D0
CDRVD RFI(1)=298.257222101D0
C
C------- WGS 1984 ------------------------------
C
C     AEI(1)=6378137.D0
C     J2I(1)=-484.16685D-6*(-DSQRT(5.D0))
C     GMI(1)=0.3986005D20
C     OMI(1)=7292115.D-11
C     RFI(1)=0.D0
CDRVD RFI(1)=298.257223563D0
C
C------- WGS 1984 (G873) -----------------------
C
C     AEI(1)=6378137.0D0
C     J2I(1)=0.D0
C     GMI(1)=0.3986004418D20
C     OMI(1)=7292115.D-11
C     RFI(1)=298.257223563D0
CDRVD J2I(1)=-484.166774985D-6*(-DSQRT(5.D0))
C
C------- GEM-T1/T2 -----------------------------
C
C     AEI(1)=6378137.D0
C     J2I(1)=0.D0
C     RFI(1)=298.257D0
C     GMI(1)=0.398600436D20
C     OMI(1)=7292115.D-11
C
C------- TOPEX/Poseidon ------------------------
C
C     AEI(1)=6378136.3D0
C     J2I(1)=0.D0
C     RFI(1)=298.257D0
C     GMI(1)=0.3986004415D20
C     OMI(1)=7292115.D-11
C
C------- EGM96 ---------------------------------
C
C     AEI(1)=6378136.3D0
C     J2I(1)=-484.165476700D-6*(-DSQRT(5.D0))
C    $       -(-3.11080D-8*0.3D0)
C     RFI(1)=0.D0
C     GMI(1)=0.3986004415D20
C     OMI(1)=7292115.D-11
CDRVD RFI(1)=298.256415099D0
C
C-----------------------------------------------------------------------
      TOL=1.D-20
      AEI(2)=A
      J2I(2)=J2
      RFI(2)=RF
      GMI(2)=GM
      OMI(2)=OMEGA
      DO 10 I=1,2
      IF(RFI(I).GT.0.D0) THEN
      F(I)=1.D0/RFI(I)
      E2I(I)=2.D0*F(I)-F(I)**2
      ELSE
      CE2=3.D0*J2I(I)
c
      iter = 0
c
   20 E2I(I)=3.D0*J2I(I)+CE2
c
      iter = iter + 1
c
      EP(I)=DSQRT(E2I(I)/(1.D0-E2I(I)))
      EP2(I)=EP(I)**2
      TWOQ0(I)=(1.D0+3.D0/EP2(I))*DATAN(EP(I))-3.D0/EP(I)
      CE2=4.D0/15.D0*OMI(I)**2*AEI(I)**3*E2I(I)**1.5/
     $              (GMI(I)*TWOQ0(I))*1.D5
c
      IF(DABS(E2I(I)-3.D0*J2I(I)-CE2).LT.TOL.or.iter.ge.10) THEN
c
      E2I(I)=3.D0*J2I(I)+CE2
      F(I)=1.D0-DSQRT(1.D0-E2I(I))
      RFI(I)=1.D0/F(I)
      GO TO 30
      ELSE
      GO TO 20
      ENDIF
      ENDIF
   30 E21I(I)=1.D0-E2I(I)
      BI(I)=AEI(I)*(1.D0-F(I))
      FMI(I)=OMI(I)**2*AEI(I)**2*BI(I)/GMI(I)*1.D5
      EP(I)=DSQRT((AEI(I)**2-BI(I)**2)/BI(I)**2)
      EP2(I)=EP(I)**2
      TWOQ0(I)=(1.D0+3.D0/EP2(I))*DATAN(EP(I))-3.D0/EP(I)
      Q0P(I)=3.D0*(1.D0+1.D0/EP2(I))*(1.D0-1.D0/EP(I)*
     $       DATAN(EP(I)))-1.D0
      F1(I)=2.D0*EP(I)*Q0P(I)/TWOQ0(I)
      GEQTI(I)=GMI(I)/(AEI(I)*BI(I))*(1.D0-FMI(I)-FMI(I)/6.D0*F1(I))
      GPOLI(I)=GMI(I)/AEI(I)**2*(1.D0+FMI(I)/3.D0*F1(I))
      DKI(I)=BI(I)*GPOLI(I)/(AEI(I)*GEQTI(I))-1.D0
      GA(I,1)=GEQTI(I)*(.5D0*E2I(I)+DKI(I))
      GA(I,2)=GEQTI(I)*( 3.D0/  8.D0*E2I(I)**2+
     $                   .5D0*       E2I(I)*DKI(I))
      GA(I,3)=GEQTI(I)*( 5.D0/ 16.D0*E2I(I)**3+
     $                   3.D0/  8.D0*E2I(I)**2*DKI(I))
      GA(I,4)=GEQTI(I)*(35.D0/128.D0*E2I(I)**4+
     $                   5.D0/ 16.D0*E2I(I)**3*DKI(I))
   10 CONTINUE
      B=BI(2)
      E2=E2I(2)
      E21=E21I(2)
      GEQT=GEQTI(2)
      GPOL=GPOLI(2)
      DK=DKI(2)
      FM=FMI(2)
      Q0=.5D0*TWOQ0(2)
      IF(RF.GT.0.D0) THEN
      J2=E2/3.D0*(1.D0-4.D0/15.D0*FMI(2)*EP(2)/TWOQ0(2))
      ELSE
      RF=RFI(2)
      ENDIF
      ZONALS(1)=J2
          DA(1)=GEQTI(1)-GEQTI(2)
      DO 40 I=2,10
      ID=I
      ZONALS(I)=DJ2N(ID,E2,J2)
      IF(I.LE.5)
     $    DA(I)=GA(1,I-1)-GA(2,I-1)
   40 CONTINUE
      RETURN
      END
c
c-----------------------------------------------------------------------
c
      REAL*8 FUNCTION DJ2N(N,E2,J2)
      IMPLICIT REAL*8(A-H,O-Z)
      REAL*8 J2
      REAL*8 E2,XN
      XN=DFLOAT(N)
      DJ2N=(-1.D0)**(N+1)*3.D0*E2**N/((2.D0*XN+1.D0)*(2.D0*XN+3.D0))*
     $     (1.D0-XN+5.D0*XN*J2/E2)
      RETURN
      END
c
c-----------------------------------------------------------------------
c
      subroutine extract_name (old_name,name,n)
      implicit none
      integer*4 i,n
      character old_name*120,name*120,char*1
c
      n = 0
      do i = 1, 120
        char = old_name(i:i)
        if (char .ne. ' ') then
          n = n + 1
          name(n:n) = char
        endif  !  char
      enddo  !  i
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine dhcsin(ie,iu,nmin,nmax,isub,cz,grat,arat,dc20,cnm,snm,
     &                  egm_tf,egm_zt,nmax0)
c
c-----------------------------------------------------------------------
c     MODIFIED:                                   SIMON HOLMES, JUL 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     MODIFIED:                                   SIMON HOLMES, JUL 2005
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8(a-h,o-z)
      real*8 cz(20),cnm(nmax0+1,nmax0+1),snm(nmax0+1,nmax0+1)
      real*8 fact(nmax0+1)
c
      nmax1 = nmax+1
c
      do n1 = 1, nmax0+1
        do m1 = 1, n1
          cnm(n1,m1) = 0.d0
          snm(n1,m1) = 0.d0
        enddo  !  m1
      enddo  !  n1
c
  100 continue
        read(iu,*,end=200) n,m,c,s
        if (n.lt.nmin.or.n.gt.nmax) goto 100
        cnm(n+1,m+1) = c
        snm(n+1,m+1) = s
        goto 100
  200 continue
c
c-----------------------------------------------------------------------
c
c     RE-SCALE THE INPUT COEFFICIENTS TO MAKE THEM CONSISTENT WITH THE
c     "GM" AND "A" VALUES OF THE ADOPTED REFERENCE ELLIPSOID.
c
c-----------------------------------------------------------------------
c
      if (ie.eq.1) then
        fact(1) = grat
        do n1 = 2, nmax1
          fact(n1) = fact(n1-1)*arat
        enddo  !  n1
      else
        do n1 = 1, nmax1
          fact(n1) = grat*arat
        enddo  !  n1
      endif  !  ie
c
      nmin1 = nmin+1
      nmax1 = nmax+1
      do n1 = nmin1, nmax1
        fct = fact(n1)
        do m1 = 1, n1
          cnm(n1,m1) = cnm(n1,m1)*fct
          snm(n1,m1) = snm(n1,m1)*fct
        enddo  !  m1
      enddo  !  n1
c
c-----------------------------------------------------------------------
c
c     CONVERT 'TIDE-FREE' INPUT C20 TO 'ZERO-TIDE' VALUE
c     (FOR SPHERICAL HARMONIC GEOPOTENTIAL COMPUTATIONS ONLY).
c
c-----------------------------------------------------------------------
c
        if (ie.eq.1.and.nmin.le.2.and.nmax.ge.2) then
          egm_tf   = cnm(3,1)
          cnm(3,1) = cnm(3,1) - dc20
          egm_zt   = cnm(3,1)
c
          write(6,500) egm_tf,egm_zt,dc20
 500      format(/,15x,'Tide Free C(2,0) = ',d20.12,
     &                                         ' (Input from File)',/,
     &             15x,'Zero Tide C(2,0) = ',d20.12,
     &                                       ' (Used in Synthesis)',/,
     &             15x,'    Delta C(2,0) = ',d20.12,
     &                                            ' (Transformation)')
        endif  !  lmin;lmax
c
c-----------------------------------------------------------------------
c
c     MODIFY THE INPUT COEFFICIENTS ACCORDING TO THE VALUE OF "ISUB"
c
c-----------------------------------------------------------------------
c
      minref = max(2,nmin)
      maxref = min(20,nmax)
      if(((minref/2)*2).ne.minref) minref = minref + 1
      if(((maxref/2)*2).ne.maxref) maxref = maxref - 1
c
      do n = minref, maxref, 2
        n1 = n+1
        cnm(n1,1) = cnm(n1,1) - cz(n)*isub
      enddo  !  n
c
c-----------------------------------------------------------------------
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine error(lmin,lmax,kmin,kmax,jmin,jmax,isub,igrid,iglat,
     &                 isw,iflag,iell,icell,dnorth,dsouth,dwest,deast)
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, JUL 2005
c     MODIFIED:                                   SIMON HOLMES, AUG 2005
c     lmin MUST BE GREATER THAN 2 FOR SHEGM:      SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      ierr = 0
c
      if (isw.ne.2.and.isw.ne.5.and.
     &(lmin.gt.lmax.or.lmin.lt.0.or.lmax.gt.2700)) then
        write(6,1000)
      elseif (isw.ne.2.and.isw.ne.5.and.isw.ne.100.and.isw.ne.101.
     &        and.lmin.lt.2) then
        write(6,1000)
      elseif (isw.eq.2.and.
     &(kmin.gt.kmax.or.kmin.lt.0.or.kmax.gt.2700)) then
        write(6,1000)
      elseif (isw.eq.5.and.
     &(jmin.gt.jmax.or.jmin.lt.0.or.jmax.gt.2700)) then
        write(6,1000)
      elseif (isub.ne.0.and.isub.ne.1) then
        write(6,1001)
      elseif (igrid.ne.0.and.igrid.ne.1) then
        write(6,1002)
      elseif(isw.ne.0.and.isw.ne.1.and.isw.ne.2.and.isw.ne.3
     &  .and.isw.ne.5.and.isw.ne.6.and.isw.ne.7.and.isw.ne.8
     &  .and.isw.ne.9.and.isw.ne.10.and.isw.ne.11.and.isw.ne.12
     &  .and.isw.ne.13.and.isw.ne.14.and.isw.ne.50.and.isw.ne.60
     &  .and.isw.ne.100.and.isw.ne.4.and.isw.ne.80.and.isw.ne.81
     &  .and.isw.ne.82.and.isw.ne.101) then
          write(6,1014)
      elseif (isub.eq.1.and.(isw.eq.2.or.isw.eq.5.or.isw.eq.100
     &  .or.isw.eq.101)) then
        write(6,1008)
      else
        ierr = ierr+1
      endif  !  ...
c
      if (igrid.eq.0) then
c
        if (isw.eq.81.and.(kmin.gt.kmax.or.kmin.lt.0.
     &  or.kmax.gt.2700)) then
          write(6,1000)
        elseif (isw.eq.82.and.(jmin.gt.jmax.or.jmin.lt.0.
     &  or.jmax.gt.2700)) then
          write(6,1000)
        else
          ierr = ierr+1
        endif  !  flags
c
      elseif (igrid.eq.1)  then
c
        if (iglat.ne.0.and.iglat.ne.1.and.iglat.ne.2) then
          write(6,1003)
        elseif (iflag.ne.0.and.iflag.ne.1) then
          write(6,1004)
        elseif (iell.ne.0.and.iell.ne.1) then
          write(6,1005)
        elseif (iell.eq.0.and.(isw.eq.100.or.isw.eq.101)) then
          write(6,1009)
        elseif (iflag.eq.1.and.
     &    (isw.eq.7.or.isw.eq.8.or.isw.eq.10.or.isw.eq.11.or.
     &     isw.eq.13.or.isw.eq.14.or.isw.eq.50)) then
          write(6,1010)
        elseif (iflag.eq.0.and.icell.ne.0.and.icell.ne.1) then
          write(6,1015)
        elseif (dabs(dnorth).gt.90.d0.or.dabs(dsouth).gt.90.d0
     &    .or.dsouth.gt.dnorth) then
          write(6,1011)
        elseif (dwest.gt.deast) then
          write(6,1012)
        elseif (iell.eq.0.and.iglat.ne.1) then
          write(6,1013)
        elseif (isw.eq.80.or.isw.eq.81.or.isw.eq.82) then
          write(6,1017)
        else
          ierr = ierr+1
        endif  !  flags
      endif  !  igrid
c
      if (ierr.ne.2) then
        write(6,2000)
        stop
      endif  !  ierr
c
 1000 format(//15x,'Error: Check maximum and minimum degree')
 1001 format(//15x,'Error: ISUB value must be 0 or 1')
 1002 format(//15x,'Error: IGRID value must be 0 or 1')
 1003 format(//15x,'Error: IGLAT value must be 0, 1 or 2')
 1004 format(//15x,'Error: IFLAG value must be 0 or 1')
 1005 format(//15x,'Error: IELL value must be 0 or 1')
 1014 format(//15x,'Error: ISW value is unassigned')
 1015 format(//15x,'Error: ICELL value must be 0 or 1')
 1008 format(//15x,'Error: ISUB cannot be 1 for ISW = ',
     &                     '2, 5, 100 or 101')
 1009 format(//15x,'Error: IELL cannot be 0 for ISW = 100 or 101')
 1010 format(//15x,'Error: IFLAG cannot be 1 for ISW = ',
     &                    '7, 8, 10, 11, 13, 14 or 50')
 1011 format(//15x,'Error: Check northern and southern boundaries')
 1012 format(//15x,'Error: Check eastern and western boundaries')
 1013 format(//15x,'Error: IGLAT must be 1 for IELL = 0')
 1017 format(//15x,'Error: IGRID must be 0 for ISW = 80, 81 or 82')
 2000 format(//15x,'*** Execution Terminated Abnormally ***',//)
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine hsynth(dnorth,nrows,dwest,ncols,dlat,dlon,batch,ptdata,
     &                  nmin,nmax,cc,cs,cz,igrid,iglat,iflag,iswp,iell,
     &                  icent,exc,grsv,rcmp,flat,flon,dist,it,zero,kk,
     &                  uc,tc,uic,uic2,cotc,thet2,thet1,thetc,pmm_a,
     &                  pmm_b,f_n,f_s,p,p1,p2,c_ev,s_ev,c_od,s_od,iex,
     &                  cr1,cr2,sr1,sr2,aux,wrkfft,nmax0,jcol,jfft,
     &                  factn,k,cml,sml)
c
c-----------------------------------------------------------------------
c
c     HSYNTH PROVIDES EFFICIENT SPHERICAL HARMONIC SYNTHESIS OF GRAVI-
c     METRIC QUANTITIES FROM DEGREE NMIN TO NMAX. SYNTHESIS CAPABILITY
c     EXTENDS TO DEGREE AND ORDER 2700.
c
c     DERIVATIVES OF GEOCENTRIC LATITUDE OR LONGITUDE ARE NOT DEFINED AT
c     THE POLES FOR POINT COMPUTATIONS. IN THESE CASES, HSYNTH RETURNS
c     THE "exclud" VALUE IN PLACE OF A COMPUTED VALUE.
c
c-----------------------------------------------------------------------
c     ORIGINAL SUBROUTINE BY:                    OSCAR COLOMBO, FEB 1980
c     UNDERFLOWING VERSION BY:                    SIMON HOLMES, JAN 2004
c     MODIFIED BY:                                SIMON HOLMES, JUN 2004
c     ORDER (M) OUTER LOOP BY:                    SIMON HOLMES, OCT 2004
c     MODIFIED FOR USE WITH v120104 ALFS:         SIMON HOLMES, DEC 2004
c     MODIFIED FOR SCATTERED POINT COMPS:         SIMON HOLMES, JUL 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 cc(nmax0+1,nmax0+1),cs(nmax0+1,nmax0+1),cz(*),ptdata(*)
      real*8 grsv(*),k(*),factn(*),kk(nmax0+1,*),batch(*)
      real*8 am(nmax0+1),bm(nmax0+1),cm(nmax0+1),dm(nmax0+1)
      real*8 thet2(*),thet1(*),thetc(*),f_n(*),f_s(*)
      real*8 pmm_a(nmax0+1,*),pmm_b(nmax0+1,*)
      real*8 p(nmax0+2,*),p1(nmax0+2,*),p2(nmax0+2,*)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
      real*8 c_od(nmax0+1,*),s_od(nmax0+1,*)
      real*8 cr1(*),sr1(*),cr2(*),sr2(*),aux(*),wrkfft(*)
      real*8 uc(*),tc(*),uic(*),uic2(*),cotc(*),flat(*),flon(*),dist(*)
      real*8 cml(nmax0+1),sml(nmax0+1)
      integer*4 iex(*),it(*),zero(*)
c
c-----------------------------------------------------------------------
c
      iexc = 0
      isw  = 0
      pi   = 4.d0*datan(1.d0)
      dtr  = pi/180.d0
      pi2  = 0.5d0 * pi
c
      gs = 1.d260
      gsi = 1.d0/gs
      nmin1 = nmin+1
      nmin2 = nmin+2
      nmax1 = nmax+1
c
      do nr = 1, nrows
        iex(nr) = 0
      enddo  !  nr
c
c-----------------------------------------------------------------------
c
      if (igrid.eq.1) then
c
        xwest = dwest
        rlon = dlon*dtr
        rlat = dlat*dtr
c
        do nx = 1, nrows*ncols
          batch(nx) = 0.d0
        enddo  !  nx
c
        do j = 1, jfft
          cr1(j) = 0.d0
          sr1(j) = 0.d0
          cr2(j) = 0.d0
          sr2(j) = 0.d0
        enddo  !  j
c
        do j = 1, 2*jcol
          aux(j)    = 0.d0
          wrkfft(j) = 0.d0
        enddo  !  j
c
      else  !  igrid = 0
c
        do nr = 1, nrows
          ptdata(nr) = 0.d0
        enddo  !
c
      endif  !  igrid
c
c-----------------------------------------------------------------------
c
      call hemisph(dnorth,nrows,dlat,icent,iflag,igrid,npnth,npequ,np,
     &             nrnth,nrsth)
c
c-----------------------------------------------------------------------
c
c     FOR COMPOSITE FUNCTIONALS THAT REQUIRE SYNTHESIS OF MORE THAN ONE
c     COMPONENT, HSYNTH WILL BEGIN COMPUTING EACH COMPONENT HERE.
c
c-----------------------------------------------------------------------
c
  100 continue
c
      call flag(iswp,isw,ider,ilong,ipole,loop)
c
      if (igrid.eq.1) then
        call prefft(dlon,xwest,iflag,ilong,icent,nmax,am,bm,cm,dm,nmax0)
      endif  !  igrid
c
      iparal = 0
      isingl = 0
c
c-----------------------------------------------------------------------
c
c     BEGINNING OF FIRST LOOP OVER PAIRED LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
      do nr = npnth, npequ
c
        iparal = 1
c
cc        write(8,*) 'FIRST LOOP: double row = ',nr
c       call flush(8)
c
        call latf(dnorth,nr,rlat,rlon,rcmp,nmax,gs,cz,grsv,igrid,icent,
     &            iflag,isw,ider,ipole,iell,iglat,xlat,xdist,itx,thc,
     &            th1,th2,k,factn,fin_n,fin_s,iexc,nmax0)
c
        thet2(nr) = th2
        thet1(nr) = th1
        thetc(nr) = thc
        f_n(nr) = fin_n
        f_s(nr) = fin_s
        if (iexc.ne.0) iex(nr) = iexc
        do n1 = 1, nmax1
          kk(n1,nr) = k(n1)
        enddo  !  n1
c
        do m1 = 1, nmax1
          c_ev(m1,nr) = 0.d0
          s_ev(m1,nr) = 0.d0
          c_od(m1,nr) = 0.d0
          s_od(m1,nr) = 0.d0
        enddo  !  m1
c
      enddo  !  nr
c
c-----------------------------------------------------------------------
c
c     END OF FIRST LOOP OVER PAIRED LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
c     BEGINNING OF FIRST LOOP OVER SINGLE LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
      do nr = nrnth, nrsth
c
        isingl = 1
c
cc        write(8,*) 'FIRST LOOP: single row = ',nr
c       call flush(8)
c
        if (igrid.eq.0) then
          xlat  = flat(nr) *dtr
          xdist = dist(nr)
          itx   =   it(nr)
c
        endif  !  igrid
c
        call latf(dnorth,nr,rlat,rlon,rcmp,nmax,gs,cz,grsv,igrid,icent,
     &            iflag,isw,ider,ipole,iell,iglat,xlat,xdist,itx,thc,
     &            th1,th2,k,factn,fin_n,fin_s,iexc,nmax0)
c
        thet2(nr) = th2
        thet1(nr) = th1
        thetc(nr) = thc
        f_n(nr) = fin_n
        iex(nr) = iexc
        do n1 = 1, nmax1
          kk(n1,nr) = k(n1)
        enddo  !  n1
c
        do m1 = 1, nmax1
          c_ev(m1,nr) = 0.d0
          s_ev(m1,nr) = 0.d0
        enddo  !  m1
c
      enddo  !  nr
c
c-----------------------------------------------------------------------
c
c     END OF FIRST LOOP OVER SINGLE LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
c     COMPUTE ALL THE LEGENDRE SECTORIALS
c
c-----------------------------------------------------------------------
c
      if (iflag.eq.1) then
c
        call alfisct(npnth,npequ,thet1,thet2,nmax,gs,pmm_a,pmm_b,zero,
     &               nmax0)
        call alfisct(nrnth,nrsth,thet1,thet2,nmax,gs,pmm_a,pmm_b,zero,
     &               nmax0)
c
      else
c
        call alfpsct(npnth,npequ,thetc,nmax,gs,ider,pmm_a,pmm_b,zero,
     &               nmax0)
        call alfpsct(nrnth,nrsth,thetc,nmax,gs,ider,pmm_a,pmm_b,zero,
     &               nmax0)
c
      endif  !  iflag
c
c-----------------------------------------------------------------------
c
      if (iparal.eq.1) then
c
c-----------------------------------------------------------------------
c
c       BEGINNING OF FIRST LOOP OVER ORDER FOR PAIRED LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
        do m1 = 1, nmin1
c
cc          write(8,*) 'SECOND LOOP: order = ',m1-1
c         call flush(8)
c
          if (iflag.eq.1) call alfiord(npnth,npequ,thet1,thet2,m1-1,
     &                                 nmax,pmm_a,pmm_b,p,p1,p2,nmax0)
c
          if (iflag.eq.0) call alfpord(npnth,npequ,thetc,m1-1,nmax,ider,
     &                                 pmm_a,pmm_b,p,p1,p2,uc,tc,uic,
     &                                 uic2,cotc,nmax0)
c
          call fftcf_p1(npnth,npequ,m1,cc,cs,kk,p,p1,p2,nmin,nmax,iflag,
     &                  ider,c_ev,s_ev,c_od,s_od,nmax0)
c
        enddo  !  m1
c
c-----------------------------------------------------------------------
c
c       END OF FIRST LOOP OVER ORDER FOR PAIRED LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
c       BEGINNING OF SECOND LOOP OVER ORDER FOR PAIRED LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
        do m1 = nmin2, nmax1
c
cc          write(8,*) 'SECOND LOOP: order = ',m1-1
c         call flush(8)
c
          if (iflag.eq.1) call alfiord(npnth,npequ,thet1,thet2,m1-1,
     &                                  nmax,pmm_a,pmm_b,p,p1,p2,nmax0)
c
          if (iflag.eq.0) call alfpord(npnth,npequ,thetc,m1-1,nmax,
     &                                 ider,pmm_a,pmm_b,p,p1,p2,uc,tc,
     &                                 uic,uic2,cotc,nmax0)
c
          call fftcf_p2(npnth,npequ,m1,cc,cs,kk,p,p1,p2,nmin,nmax,iflag,
     &                  ider,c_ev,s_ev,c_od,s_od,nmax0)
c
        enddo  !  m1
c
c-----------------------------------------------------------------------
c
c       END OF SECOND LOOP OVER ORDER FOR PAIRED LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
      endif  !  iparal
c
c-----------------------------------------------------------------------
c
      if (isingl.eq.1) then
c
c-----------------------------------------------------------------------
c
c       BEGINNING OF FIRST LOOP OVER ORDER FOR SINGLE LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
        do m1 = 1, nmin1
c
cc          write(8,*) 'SECOND LOOP: order = ',m1-1
c         call flush(8)
c
          if (iflag.eq.1) call alfiord(nrnth,nrsth,thet1,thet2,m1-1,
     &                                 nmax,pmm_a,pmm_b,p,p1,p2,nmax0)
c
          if (iflag.eq.0) call alfpord(nrnth,nrsth,thetc,m1-1,nmax,ider,
     &                                 pmm_a,pmm_b,p,p1,p2,uc,tc,uic,
     &                                 uic2,cotc,nmax0)
c
          call fftcf_s1(nrnth,nrsth,m1,cc,cs,kk,p,p1,p2,nmin,nmax,iflag,
     &                  ider,c_ev,s_ev,nmax0)
c
        enddo  !  m1
c
c-----------------------------------------------------------------------
c
c       END OF FIRST LOOP OVER ORDER FOR SINGLE LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
c       BEGINNING OF SECOND LOOP OVER ORDER FOR SINGLE LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
        do m1 = nmin2, nmax1
c
cc          write(8,*) 'SECOND LOOP: order = ',m1-1
c         call flush(8)
c
          if (iflag.eq.1) call alfiord(nrnth,nrsth,thet1,thet2,m1-1,
     &                                 nmax,pmm_a,pmm_b,p,p1,p2,nmax0)
c
          if (iflag.eq.0) call alfpord(nrnth,nrsth,thetc,m1-1,nmax,ider,
     &                                 pmm_a,pmm_b,p,p1,p2,uc,tc,uic,
     &                                 uic2,cotc,nmax0)
c
          call fftcf_s2(nrnth,nrsth,m1,cc,cs,kk,p,p1,p2,nmin,nmax,iflag,
     &                  ider,c_ev,s_ev,nmax0)
c
        enddo  !  m1
c
c-----------------------------------------------------------------------
c
c       END OF SECOND LOOP OVER ORDER FOR SINGLE LATITUDE 'ROWS'
c
c-----------------------------------------------------------------------
c
      endif  !  isingl
c
c-----------------------------------------------------------------------
c
  300 continue
c
c-----------------------------------------------------------------------
c
c     BEGINNING OF SECOND LOOP OVER PAIRED LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
      do nr = npnth, npequ
c
cc        write(8,*) 'THIRD LOOP: double row = ',nr
c       call flush(8)
c
        call fft_p(nmax1,c_ev,s_ev,c_od,s_od,am,bm,cm,dm,dlon,ncols,
     &             cr1,cr2,sr1,sr2,aux,wrkfft,nr,np,f_n,f_s,batch,nmax0)
c
        iexc = iex(nr)
        if (iexc.eq.1) call exclude(1,ncols,nr,np,iexc,exc,batch)
c
      enddo  !  nr
c
c-----------------------------------------------------------------------
c
c     END OF SECOND LOOP OVER PAIRED LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
c     BEGINNING OF SECOND LOOP OVER SINGLE LATITUDINAL 'ROWS'
c
c-----------------------------------------------------------------------
c
      do nr = nrnth, nrsth
c
cc        write(8,*) 'THIRD LOOP: single row = ',nr
c       call flush(8)
c
        iexc = iex(nr)
c
        if (igrid.eq.1) then
c
          call fft_s(nmax1,c_ev,s_ev,am,bm,cm,dm,cr1,sr1,aux,wrkfft,
     &               dlon,ncols,nr,f_n,batch,nmax0)
c
          if (iexc.eq.1) call exclude(0,ncols,nr,np,iexc,exc,batch)
c
        else  !  igrid = 0
c
          xflon = flon(nr)
          call ptsy(xflon,nmax1,ilong,c_ev,s_ev,nr,f_n,ptdata,nmax0,
     &              cml,sml)
c
          if (iexc.eq.1) ptdata(nr) = exc
c
        endif  !  igrid
c
      enddo  !  nr
c
c-----------------------------------------------------------------------
c
c     END OF SECOND LOOP OVER PAIRED SINGLE 'ROWS'
c
c-----------------------------------------------------------------------
c
      if (loop.eq.1) goto 100
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine hemisph(dnorth,nrows,dlat,icent,iflag,igrid,npnth,
     &                   npequ,np,nrnth,nrsth)
c
c-----------------------------------------------------------------------
c
c     DIVIDES THE GRID INTO THOSE LATITUDINAL ROWS THAT CAN BE COMPUTED
c     IN EQUATORIALLY SYMMETRIC PAIRS AND THOSE ROWS THAT MUST BE
c     COMPUTED SINGLY.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
c
      npnth = 0
      npequ = -1
      npsth = -2
      nrnth = 1
      nrsth = nrows
      ipt = (1-icent)*(1-iflag)*igrid
c
      if (igrid.eq.0) return
c
      dsouth = dnorth- dlat*(nrows-ipt)
c
      if (dsouth.gt.-1.d-10.or.dnorth.lt.1.d-10)  return
      if (dabs(mod(dnorth,dlat)).ge.1.d-10)       return
      if (dabs(mod(dsouth,dlat)).ge.1.d-10)       return
c
      if (dnorth.gt.dabs(dsouth)) then
        nrnth = 1
        nrsth = nint((dnorth + dsouth)/dlat)
        npnth = nrsth + 1
        npequ = nint(dnorth/dlat) +ipt
        npsth = nrows
      elseif(dnorth.lt.dabs(dsouth)) then
        npnth = 1
        npequ = nint(dnorth/dlat) +ipt
        npsth = npequ + nint(dnorth/dlat)
        nrnth = npsth +1
        nrsth = nrows
      else
        npnth = 1
        npequ = nint(dnorth/dlat) +ipt
        npsth = nrows
        nrnth = 1
        nrsth = -1
      endif  !  dnorth
c
      np = npsth + npnth
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine flag(iswp,isw,ider,ilong,ipole,loop)
c
c-----------------------------------------------------------------------
c
c     PROVIDES SWITCHING & CONTROL FOR INTERNAL FLAGS
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c-----------------------------------------------------------------------
c
      loop = 0
c
      if (iswp.eq.4) then
        if (isw.eq.0) isw = -4
        if (isw.eq.4) isw = 22
      elseif (iswp.eq.13) then
        if (isw.eq.0) isw = -20
        if (isw.eq.20) isw = 21
      elseif (iswp.eq.14) then
        if (isw.eq.0) isw = -20
        if (isw.eq.20) isw = -23
        if (isw.eq.23) isw = 24
      elseif (iswp.eq.50) then
        if (isw.eq.0) isw = -50
        if (isw.eq.50) isw = -51
        if (isw.eq.51) isw = 52
      else
        isw = iswp
      endif  !  isw
c
      if (isw.lt.0) then
        isw = -isw
        loop = 1
      endif  !  isw
c
      ilong = 0
      ider = 0
      ipole = 0
c
      if (isw.eq.7.or.isw.eq.10.or.isw.eq.24) ider = 1
      if (isw.eq.52)                          ider = 1
      if (isw.eq.21)                          ider = 2
      if (isw.eq.8.or.isw.eq.11)              ilong = 1
      if (isw.eq.23)                          ilong = 2
c
      if (ider.ne.0.or.ilong.ne.0) ipole = 1
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine prefft(dlon,dwest,iflag,ilong,icent,nmax,am,bm,cm,dm,
     &                  nmax0)
c
c-----------------------------------------------------------------------
c
c     COMPUTES SCALING AND PHASE-SHIFT FACTORS TO PREPARE HARMONIC
c     FOURIER COEFFICIENTS FOR FFT OVER LONGITUDE.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
c
      real*8 am(nmax0+1),bm(nmax0+1),cm(nmax0+1),dm(nmax0+1)
      real*8 phza(nmax0+1),phzb(nmax0+1)
c
c-----------------------------------------------------------------------
c
      pi = 4.d0*datan(1.d0)
      dtr = pi/180.d0
      nmax1 = nmax+1
c
      rlon = dlon*dtr
      rwest = dwest*dtr + (1-iflag)*icent*0.5d0*rlon
c
      if (iflag.eq.1) then
        phza(1) = rlon
        phzb(1) = 0.d0
        do m1 = 2, nmax1
          xm = dfloat(m1-1)
          xmi = 1.d0/xm
          xmwl = xm*(rwest+rlon)
          xmrw = xm*rwest
          phza(m1) =  (dsin(xmwl) - dsin(xmrw))*xmi
          phzb(m1) =  (dcos(xmwl) - dcos(xmrw))*xmi
        enddo  !  m1
c
      elseif (iflag.eq.0) then
        do m1 = 1, nmax1
          xm = dfloat(m1-1)
          xmrw = xm*rwest
          phza(m1) =  dcos(xmrw)
          phzb(m1) = -dsin(xmrw)
        enddo  !  m
      endif  !  iflag
c
      if (ilong.eq.1) then
        do m1 = 1, nmax1
          xm = dfloat(m1-1)
          am(m1) =  phzb(m1) *xm
          bm(m1) = -phza(m1) *xm
          cm(m1) =  phza(m1) *xm
          dm(m1) =  phzb(m1) *xm
        enddo  !  m
      else
        do m = 0, nmax
          m1 = m+1
          am(m1) =  phza(m1)
          bm(m1) =  phzb(m1)
          cm(m1) = -phzb(m1)
          dm(m1) =  phza(m1)
        enddo  !  m
      endif   !  isw
c
      if (ilong.eq.2) then
        do m1 = 1, nmax1
          xm2 = -dfloat(m1-1)*dfloat(m1-1)
          am(m1) = am(m1) *xm2
          bm(m1) = bm(m1) *xm2
          cm(m1) = cm(m1) *xm2
          dm(m1) = dm(m1) *xm2
        enddo  !  m
      endif  !  isw
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine latf(dnorth,nr,rlat,rlon,rcmp,nmax,gs,cz,grsv,igrid,
     &                icent,iflag,isw,ider,ipole,iell,iglat,xlat,xdist,
     &                itx,thc,th1,th2,k,factn,fin_n,fin_s,iexc,nmax0)
c
c-----------------------------------------------------------------------
c
c     COMPUTES ALL NON-LEGENDRE COMPONENTS OF LATITUDINAL ARGUMENT
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     SCATTERED POINT FUNCTIONALITY               SIMON HOLMES, JUL 2005
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 cz(20),k(*),factn(*),cvl(0:2,0:2),grsv(*)
      real*8 gammae(2),gammag(2),gammad(2)
      data ix/0/
c
      if (ix.eq.0) then
c
        ix = 1
        igbas = 1                                !  spherical harm
        if (isw.eq.100.or.isw.eq.101) igbas = 2  !  ellipsoidal harm
c
        igrs = 1
        if (igrid.eq.1.and.isw.eq.2.and.iell.eq.0) igrs  = 0
c
        cv    = 1.d0
        cvgc  = 1.d0
        cvgd  = 1.d0
c
        pi    = 4.d0*datan(1.d0)
        dtr   = pi/180.d0
        rts   = 3600.d0/dtr
        pi2   = 0.5d0 * pi
        rlat2 = rlat/2.d0
c
        if (igrs.eq.1) then
c
          ae    = grsv(1)
          b     = grsv(5)
          gm    = grsv(3)
          omega = grsv(4)
          e2    = grsv(6)
          e21   = grsv(7)
          q0    = grsv(12)
          rte21 = dsqrt(e21)
c
          cvl(0,0) = 1.d0         !  geodetic to geodetic
          cvl(0,1) = e21          !  geodetic to geocentric
          cvl(0,2) = rte21        !  geodetic to reduced
c
          cvl(1,0) = 1.d0/e21     !  geocentric to geodetic
          cvl(1,1) = 1.d0         !  geocentric to geocentric
          cvl(1,2) = 1.d0/rte21   !  geocentric to reduced
c
          cvl(2,0) = 1.d0/rte21   !  reduced to geodetic
          cvl(2,1) = rte21        !  reduced to geocentric
          cvl(2,2) = 1.d0         !  reduced to reduced
c
          cv   = cvl(iglat,igbas)
          cvgc = cvl(iglat,1    )
          cvgd = cvl(iglat,0    )
c
        endif  !  igrs
c
        isw_old = -1
c
      endif  !  ix
c
      if (isw.ne.isw_old) then
c
        isw_old = isw
c
        do n = 0, nmax
          n1 = n+1
          n2 = n+2
          ns1 = n-1
                          factn(n1) = 1.d0
          if (isw.eq.1)   factn(n1) = 1.d0*ns1
          if (isw.eq.3)   factn(n1) = 1.d0*ns1*n2
          if (isw.eq.4)   factn(n1) = 1.d0*n1
          if (isw.eq.5)   factn(n1) = 1.d0            !  * CUSTOM FUNCTION HERE
          if (isw.eq.6)   factn(n1) = 1.d0*ns1*n2*(n+3)
          if (isw.eq.9)   factn(n1) = 1.d0*n1
          if (isw.eq.12)  factn(n1) = 1.d0*n1*n2
          if (isw.eq.20)  factn(n1) = 1.d0*n1
          if (isw.eq.51)  factn(n1) = 1.d0*n1
          if (isw.eq.100.and.n.gt.1) factn(n1) = 1.d0*ns1
        enddo  !  n
c
      endif  !  isw
c
      nmax1 = nmax+1
c
      if (igrid.eq.1) then
c
        rnrth = dnorth*dtr
c
        phic = (rnrth-(nr-1)*rlat)- rlat2*icent
        argc = phic
        gclc = phic
        gdlc = phic
        if (dabs(dcos(phic)).gt.1.d-10) then
          if (iell.eq.1) then
            argc = datan(cv  *dtan(phic))
            gclc = datan(cvgc*dtan(phic))
            gdlc = datan(cvgd*dtan(phic))
          else
            argc = phic
            gclc = phic
            if (igrs.eq.1) call gc2gd(gclc,rcmp,ae,b,gdlc,xxx)
          endif  !  iell
        endif  !  phic
c
        if (iell.eq.1) re = ae*rte21/dsqrt(1.d0-e2*dcos(gclc)**2)
        if (iell.eq.0) re = rcmp
c
      else  !  igrid = 0
c
        if (itx.eq.1) then
          gdlc = xlat
          call gd2gc(gdlc,xdist,ae,b,gclc,re)
        else
          gclc = xlat
          re = xdist
          call gc2gd(gclc,re,ae,b,gdlc,ht)
        endif  !  itx
c
        argc = gclc
        if (isw.eq.100.or.isw.eq.101) then
          if (dabs(dcos(gclc)).gt.1.d-10) then
            argc = datan(cvl(1,2)*dtan(gclc))
          endif  !  gclc
        endif  !  isw
c
      endif  !  igrid
c
      thc = pi2 - argc
      uc = dsin(thc)
      tc = dcos(thc)
c
      if (igbas.eq.1.and.igrs.eq.1) then
        alpha = gdlc - gclc
        cosa = dcos(alpha)
        sina = dsin(alpha)
      endif
c
c-----------------------------------------------------------------------
c
      if (igrs.eq.1) then
        call radgrav(2,1,1,1,ae,e2,e21,q0,gm,omega,xx1,xx2,gclc,re,xx3,
     &               xx4,gammae,gammag,gammad,gv,u0,gvh,gvr)
      endif  !  igrs
c
c-----------------------------------------------------------------------
c
c     COMPUTE SPHERICAL HARMONIC COMPONENT THAT IS INDEPENDENT OF
c     DEGREE (n) OR ORDER (m).
c
c-----------------------------------------------------------------------
c
      if (isw.eq.0)   temp = gm/(re*gv)
      if (isw.eq.1)   temp = gm/(re*re)
      if (isw.eq.3)   temp = -1.d3*gm/(re*re*re)
      if (isw.eq.4)   temp = -1.d3*gm/(re*re*gv)
      if (isw.eq.5)   temp = -gm/(re*re)             !  *1.d-2
      if (isw.eq.6)   temp = 1.d6*gm/(re*re*re*re)
      if (isw.eq.7)   temp = rts*gm/(re*re*gv)
      if (isw.eq.8)   temp = -rts*gm/(re*re*gv)
      if (isw.eq.9)   temp = -gm/(re*re)
      if (isw.eq.10)  temp = -gm/(re*re)
      if (isw.eq.11)  temp = gm/(re*re)
      if (isw.eq.12)  temp = 1.d4*gm/(re*re*re)
      if (isw.eq.20)  temp = -1.d4*gm/(re*re*re)
      if (isw.eq.21)  temp = 1.d4*gm/(re*re*re)
      if (isw.eq.22)  temp = -1.d3*gm*gvr/(re*gv*gv)
      if (isw.eq.23)  temp = 1.d4*gm/(re*re*re)
      if (isw.eq.24)  temp = 1.d4*gm/(re*re*re)
c
      if (isw.eq.50)  temp = (gm/re)*(gvh/gv)
      if (isw.eq.51)  temp = gm/(re*re) * cosa
      if (isw.eq.52)  temp = gm/(re*re) * sina
c
      if (isw.eq.100) temp = gm/(re*ae)
c
      iexc = 0
      if (iflag.eq.0) then
        if (dabs(uc).lt.1.d-10.and.ipole.eq.1) then
          temp = 0.d0
          iexc = 1
          uc = 1
        endif
        if (isw.eq.8) temp = temp/uc
        if (isw.eq.11) temp = temp/uc
        if (isw.eq.23) temp = temp/(uc*uc)
        if (isw.eq.24) temp = temp*(tc/uc)
      endif  !  iflag
c
c-----------------------------------------------------------------------
c
c     COMPUTE TERMS THAT ARE DEPENDENT ON DEGREE (n) BUT INDEPENDENT
c     OF ORDER (m)
c
c-----------------------------------------------------------------------
c
      if (isw.ne.2.and.isw.ne.5.and.isw.ne.100.and.isw.ne.101) then
c
        ar = ae/re
        k(1) = temp
        do n1 = 2, nmax1
          k(n1) = k(n1-1)*ar
        enddo  !  n1
c
        do n1 = 1, nmax1
          k(n1) = k(n1)*factn(n1)
        enddo  !  n1
c
      elseif (isw.eq.2.or.isw.eq.101) then
        do n1 = 1, nmax1
          k(n1) = 1.d0
        enddo  !  n1
      elseif (isw.eq.5.or.isw.eq.100) then
        do n1 = 1, nmax1
          k(n1) = temp*factn(n1)
        enddo  !  n1
      endif  !  isw
c
c-----------------------------------------------------------------------
c
      if (igrid.eq.1) then
        if (iflag.eq.1) then
          phi2 = rnrth - (nr-1)*rlat
          phi1 = rnrth - (nr  )*rlat
          arg2 = phi2
          arg1 = phi1
          if (dabs(dcos(phi2)).gt.1.d-10) arg2 = datan(cv*dtan(phi2))
          if (dabs(dcos(phi1)).gt.1.d-10) arg1 = datan(cv*dtan(phi1))
          th2 = pi2 - arg2
          th1 = pi2 - arg1
          fin_n = (0.5d0/((dsin(arg2)-dsin(arg1))*rlon))/gs
          fin_s = fin_n
        else  !  iflag
          fin_n = 0.5d0/gs
          fin_s = fin_n
        endif
      else  !  igrid = 0
        fin_n = 1.d0/gs
      endif  !  igrid
c
      if (isw.eq.24.or.isw.eq.52)              fin_s = -fin_s
      if (ider.eq.1)                           fin_s = -fin_s
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine fftcf_p1(npnth,npequ,m1,cc,cs,kk,p,p1,p2,nmin,nmax,
     &                    iflag,ider,c_ev,s_ev,c_od,s_od,nmax0)
c
c-----------------------------------------------------------------------
c
c     COMBINES COMPONENTS OF MATCHING ORDER AND PARALLEL BAND. THE
c     RESULTING QUANTITIES CAN BE COMBINED TO YIELD TWO COMPLETE SETS
c     OF FOURIER COEFFICIENTS, ONE FOR EACH OF TWO EQUATORIALLY
c     SYMMETRIC PARALLEL BANDS.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     MODIFIED FOR USE WITH v120104 ALFS          SIMON HOLMES, DEC 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 cc(nmax0+1,nmax0+1),cs(nmax0+1,nmax0+1)
      real*8 p(nmax0+2,*),p1(nmax0+2,*),p2(nmax0+2,*),kk(nmax0+1,*)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
      real*8 c_od(nmax0+1,*),s_od(nmax0+1,*)
c
      nmin1 = nmin+1
      nmin2 = nmin+2
      nmax1 = nmax+1
c
      n1e = nmin1
      n1o = nmin2
      nsubm = nmin1-m1
      if ((nsubm/2)*2.ne.nsubm) then
        n1e = nmin2
        n1o = nmin1
      endif  !  nsubm
c
      if (iflag.eq.1) then
c
        do nr = npnth, npequ
c
          do n1 = n1e, nmax1, 2
            tx = p(n1,nr)*kk(n1,nr)
            c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
            s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
          enddo  !  n1
c
          do n1 = n1o, nmax1, 2
            tx = p(n1,nr)*kk(n1,nr)
            c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
            s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
          enddo  !  n1
c
        enddo  !  nr
c
      else
c
        if (ider.eq.0) then
c
          do nr = npnth, npequ
c
            do n1 = n1e, nmax1, 2
              tx = p(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
            do n1 = n1o, nmax1, 2
              tx = p(n1,nr)*kk(n1,nr)
              c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
              s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.1) then  !  ider
c
          do nr = npnth, npequ
c
            do n1 = n1e, nmax1, 2
              tx = p1(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
            do n1 = n1o, nmax1, 2
              tx = p1(n1,nr)*kk(n1,nr)
              c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
              s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.2) then  !  ider
c
          do nr = npnth, npequ
c
            do n1 = n1e, nmax1, 2
              tx = p2(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
            do n1 = n1o, nmax1, 2
              tx = p2(n1,nr)*kk(n1,nr)
              c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
              s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        endif  !  ider
c
      endif  !  iflag
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine fftcf_p2(npnth,npequ,m1,cc,cs,kk,p,p1,p2,nmin,nmax,
     &                    iflag,ider,c_ev,s_ev,c_od,s_od,nmax0)
c
c-----------------------------------------------------------------------
c
c     COMBINES COMPONENTS OF MATCHING ORDER AND PARALLEL BAND. THE
c     RESULTING QUANTITIES CAN BE COMBINED TO YIELD TWO COMPLETE SETS
c     OF FOURIER COEFFICIENTS, ONE FOR EACH OF TWO EQUATORIALLY
c     SYMMETRIC PARALLEL BANDS.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     MODIFIED FOR USE WITH v120104 ALFS          SIMON HOLMES, DEC 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 cc(nmax0+1,nmax0+1),cs(nmax0+1,nmax0+1)
      real*8 p(nmax0+2,*),p1(nmax0+2,*),p2(nmax0+2,*),kk(nmax0+1,*)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
      real*8 c_od(nmax0+1,*),s_od(nmax0+1,*)
c
      nmax1 = nmax+1
c
      if (iflag.eq.1) then
        do nr = npnth, npequ
c
          do n1 = m1, nmax1, 2
            tx = p(n1,nr)*kk(n1,nr)
            c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
            s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
          enddo  !  n1
c
          do n1 = m1+1, nmax1, 2
            tx = p(n1,nr)*kk(n1,nr)
            c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
            s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
          enddo  !  n1
c
        enddo  !  nr
c
      else
c
        if (ider.eq.0) then
c
          do nr = npnth, npequ
c
            do n1 = m1, nmax1, 2
              tx = p(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
            do n1 = m1+1, nmax1, 2
              tx = p(n1,nr)*kk(n1,nr)
              c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
              s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.1) then  !  ider
c
          do nr = npnth, npequ
c
            do n1 = m1, nmax1, 2
              tx = p1(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
            do n1 = m1+1, nmax1, 2
              tx = p1(n1,nr)*kk(n1,nr)
              c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
              s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.2) then  !  ider
c
          do nr = npnth, npequ
c
            do n1 = m1, nmax1, 2
              tx = p2(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
            do n1 = m1+1, nmax1, 2
              tx = p2(n1,nr)*kk(n1,nr)
              c_od(m1,nr) = c_od(m1,nr) + tx*cc(n1,m1)
              s_od(m1,nr) = s_od(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        endif  !  ider
c
      endif  !  iflag
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine fft_p(nmax1,c_ev,s_ev,c_od,s_od,am,bm,cm,dm,dlon,ncols,
     &                 cr1,cr2,sr1,sr2,aux,wrkfft,nr,np,f_n,f_s,batch,
     &                 nmax0)
c
c-----------------------------------------------------------------------
c
c     COMBINES PRE-FOURIER COEFFICIENTS AND PHASE-SHIFTS THEM TO YIELD
c     TWO COMPLETE SETS OF FFT-READY FOURIER COEFFICIENTS, ONE FOR EACH
c     OF TWO EQUATORIALLY SYMMETRIC PARALLEL BANDS. FOR LONGITUDINAL
c     SYNTHESIS OVER EACH PARALLEL BAND, THE FFT IS APPLIED TO BOTH SETS
c     OF COEFFICIENTS SIMULTANEOUSLY.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 aux(*),wrkfft(*),batch(*),cr1(*),sr1(*),cr2(*),sr2(*)
      real*8 c1(nmax0+1),c2(nmax0+1),s1(nmax0+1),s2(nmax0+1)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
      real*8 c_od(nmax0+1,*),s_od(nmax0+1,*)
      real*8 am(nmax0+1),bm(nmax0+1),cm(nmax0+1),dm(nmax0+1)
      real*8 f_n(*),f_s(*)
      integer*4 nsiz(1)
      data ix/0/
c
c-----------------------------------------------------------------------
c
      if (ix.eq.0) then
        ix = 1
        nc = nint(360.d0/dlon)
        nc2 = nc/2
        nc2p = nc2+1
        ncp = nc+1
        nsiz(1) = nc
      endif  !  ix
c
      do m1 = 1, nmax1
        c1(m1) = c_ev(m1,nr) + c_od(m1,nr)
        s1(m1) = s_ev(m1,nr) + s_od(m1,nr)
        c2(m1) = c_ev(m1,nr) - c_od(m1,nr)
        s2(m1) = s_ev(m1,nr) - s_od(m1,nr)
c
        amm1 = am(m1)
        bmm1 = bm(m1)
        cmm1 = cm(m1)
        dmm1 = dm(m1)
c
        cr1(m1) = c1(m1) *amm1 + s1(m1) *cmm1
        cr2(m1) = c2(m1) *amm1 + s2(m1) *cmm1
        sr1(m1) = s1(m1) *dmm1 + c1(m1) *bmm1
        sr2(m1) = s2(m1) *dmm1 + c2(m1) *bmm1
      enddo  !  m1
c
      cr1(1) = 2.d0*cr1(1)
      cr2(1) = 2.d0*cr2(1)
c
      if (nmax1.gt.nc2) then
        do m1 = 1, nc2p
          ma =  m1
          mb = -m1+2
          do kk = 1, nmax1
            ma = ma+nc
            mb = mb+nc
            if (mb.le.nmax1) then
              if (ma.le.nmax1) then
                cr1(m1) = cr1(m1) + cr1(ma)+cr1(mb)
                cr2(m1) = cr2(m1) + cr2(ma)+cr2(mb)
                sr1(m1) = sr1(m1) + sr1(ma)-sr1(mb)
                sr2(m1) = sr2(m1) + sr2(ma)-sr2(mb)
              else
                cr1(m1) = cr1(m1)          +cr1(mb)
                cr2(m1) = cr2(m1)          +cr2(mb)
                sr1(m1) = sr1(m1)          -sr1(mb)
                sr2(m1) = sr2(m1)          -sr2(mb)
              endif  !  ma
            endif  !  mb
          enddo  !  kk
        enddo  !  m1
      endif  !  nmax1
c
      do m1 = 1, nc
        m12 = 2*m1
        if(m1.le.nc2p) then
          aux(m12-1) =  cr1(m1) - sr2(m1)
          aux(m12  ) =  sr1(m1) + cr2(m1)
        else
          mx = nc-m1+2
          aux(m12-1) =  cr1(mx) + sr2(mx)
          aux(m12  ) = -sr1(mx) + cr2(mx)
        endif  !  m1
      enddo  !  m1
c
      call fourt(aux,nsiz,1,-1,1,wrkfft,nc*2,nc*2)
c
      nrs = np-nr
c
      ndat  = ncols*(nr -1)
      ndats = ncols*(nrs-1)
c
      if (nrs.ne.nr) then
        do j = 1, ncols
          k1 = 2*j-1
          k2 = 2*j
          batch(ndat +j) = batch(ndat +j) + aux(k1)*f_n(nr)
          batch(ndats+j) = batch(ndats+j) + aux(k2)*f_s(nr)
        enddo  !  j
      else  !  nrs;nr
        do j = 1, ncols
          k1 = 2*j-1
          batch(ndat +j) = batch(ndat +j) + aux(k1)*f_n(nr)
        enddo  !  j
      endif  !  nrs;nr
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine fftcf_s1(nrnth,nrsth,m1,cc,cs,kk,p,p1,p2,nmin,nmax,
     &                    iflag,ider,c_ev,s_ev,nmax0)
c
c-----------------------------------------------------------------------
c
c     COMBINES COMPONENTS OF MATCHING ORDER AND PARALLEL BAND. THE
c     RESULTING QUANTITIES CAN BE COMBINED TO YIELD A COMPLETE SET
c     OF FOURIER COEFFICIENTS FOR A SINGLE PARALLEL BAND.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     MODIFIED FOR USE WITH v120104 ALFS          SIMON HOLMES, DEC 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 cc(nmax0+1,nmax0+1),cs(nmax0+1,nmax0+1)
      real*8 p(nmax0+2,*),p1(nmax0+2,*),p2(nmax0+2,*),kk(nmax0+1,*)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
c
      nmin1 = nmin+1
      nmax1 = nmax+1
c
      if (iflag.eq.1) then
        do nr = nrnth, nrsth
c
          do n1 = nmin1, nmax1
            tx = p(n1,nr)*kk(n1,nr)
            c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
            s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
          enddo  !  n1
c
        enddo  !  nr
c
      else  ! iflag
c
        if (ider.eq.0) then
c
          do nr = nrnth, nrsth
c
            do n1 = nmin1, nmax1
              tx = p(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.1) then  !  ider
c
          do nr = nrnth, nrsth
c
            do n1 = nmin1, nmax1
              tx = p1(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.2) then  !  ider
c
          do nr = nrnth, nrsth
c
            do n1 = nmin1, nmax1
              tx = p2(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        endif  !  ider
c
      endif  !  iflag
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine fftcf_s2(nrnth,nrsth,m1,cc,cs,kk,p,p1,p2,nmin,nmax,
     &                    iflag,ider,c_ev,s_ev,nmax0)
c
c-----------------------------------------------------------------------
c
c     COMBINES COMPONENTS OF MATCHING ORDER AND PARALLEL BAND. THE
c     RESULTING QUANTITIES CAN BE COMBINED TO YIELD A COMPLETE SET
c     OF FOURIER COEFFICIENTS FOR A SINGLE PARALLEL BAND.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     MODIFIED FOR USE WITH v120104 ALFS          SIMON HOLMES, DEC 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 cc(nmax0+1,nmax0+1),cs(nmax0+1,nmax0+1)
      real*8 p(nmax0+2,*),p1(nmax0+2,*),p2(nmax0+2,*),kk(nmax0+1,*)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
c
      nmax1 = nmax+1
c
      if (iflag.eq.1) then
        do nr = nrnth, nrsth
c
          do n1 = m1, nmax1
            tx = p(n1,nr)*kk(n1,nr)
            c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
            s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
          enddo  !  n1
c
        enddo  !  nr
c
      else
c
        if (ider.eq.0) then
c
          do nr = nrnth, nrsth
c
            do n1 = m1, nmax1
              tx = p(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.1) then  !  ider
c
          do nr = nrnth, nrsth
c
            do n1 = m1, nmax1
              tx = p1(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        elseif (ider.eq.2) then  !  ider
c
          do nr = nrnth, nrsth
c
            do n1 = m1, nmax1
              tx = p2(n1,nr)*kk(n1,nr)
              c_ev(m1,nr) = c_ev(m1,nr) + tx*cc(n1,m1)
              s_ev(m1,nr) = s_ev(m1,nr) + tx*cs(n1,m1)
            enddo  !  n1
c
          enddo  !  nr
c
        endif  !  ider
c
      endif  !  iflag
c
      return
      end
c
c
c-----------------------------------------------------------------------
c
      subroutine fft_s(nmax1,c_ev,s_ev,am,bm,cm,dm,cr1,sr1,aux,wrkfft,
     &                 dlon,ncols,nr,f_n,batch,nmax0)
c
c-----------------------------------------------------------------------
c
c     COMBINES PRE-FOURIER COEFFICIENTS AND PHASE-SHIFTS THEM TO YIELD
c     A COMPLETE SET OF FFT-READY FOURIER COEFFICIENTS FOR A SINGLE
c     PARALLEL BAND. THE FFT IS THEN USED FOR LONGITUDINAL SYNTHESIS
c     OVER THIS PARALLEL BAND.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c     MODIFIED:                                   SIMON HOLMES, OCT 2004
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*)
      real*8 cr1(*),sr1(*),aux(*),wrkfft(*),batch(*)
      real*8 am(nmax0+1),bm(nmax0+1),cm(nmax0+1),dm(nmax0+1)
      real*8 f_n(*)
      integer*4 nsiz(1)
      data ix/0/
c
c-----------------------------------------------------------------------
c
      if (ix.eq.0) then
        ix = 1
        nc = nint(360.d0/dlon)
        nc2 = nc/2
        nc2p = nc2+1
        ncp = nc+1
        nsiz(1) = nc
      endif  !  ix
c
      do m1 = 1, nmax1
        cr1(m1) = c_ev(m1,nr) *am(m1) + s_ev(m1,nr) *cm(m1)
        sr1(m1) = s_ev(m1,nr) *dm(m1) + c_ev(m1,nr) *bm(m1)
      enddo  !  m1
c
      cr1(1) = 2.d0*cr1(1)
c
      if (nmax1.gt.nc2) then
        do m1 = 1, nc2p
          ma =  m1
          mb = -m1+2
          do kk = 1, nmax1
            ma = ma+nc
            mb = mb+nc
            if (mb.le.nmax1) then
              if (ma.le.nmax1) then
                cr1(m1) = cr1(m1) + cr1(ma)+cr1(mb)
                sr1(m1) = sr1(m1) + sr1(ma)-sr1(mb)
              else
                cr1(m1) = cr1(m1)          +cr1(mb)
                sr1(m1) = sr1(m1)          -sr1(mb)
              endif  !  ma
            endif  !  mb
          enddo  !  kk
        enddo  !  m1
c
      endif  !  nmax1
c
      do m1 = 1, nc
        k1 = 2*m1-1
        k2 = 2*m1
        if (m1.le.nc2p) then
          aux(k1)= cr1(m1)
          aux(k2)= sr1(m1)
        else
          mx = nc-m1+2
          aux(k1)= cr1(mx)
          aux(k2)=-sr1(mx)
        endif
c
      enddo  !  m1
c
      call fourt(aux,nsiz,1,-1,1,wrkfft,nc*2,nc*2)
c
      ndat = ncols*(nr-1)
      do j = 1, ncols
        batch(ndat+j) = batch(ndat+j) + aux(2*j-1)*f_n(nr)
c
      enddo  !  i
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine ptsy(flon,nmax1,ilong,c_ev,s_ev,nr,f_n,ptdata,nmax0,
     &                cml,sml)
c
c-----------------------------------------------------------------------
c
c     SYNTHESIS OF FOURIER COEFFICIENTS FOR SINGLE POINT
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUL 2005
c     nmax0 VALUE PASSED IN CALL STATEMENT        SIMON HOLMES, NOV 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 c_ev(nmax0+1,*),s_ev(nmax0+1,*),cml(nmax0+1),sml(nmax0+1)
      real*8 temp(nmax0+1),f_n(*),ptdata(*),tmp(nmax0+1)
c
      pi = 4.d0*datan(1.d0)
      dtr = pi/180.d0
c
      xlon = flon*dtr
c
      m1_2 = 1
      cml(m1_2) = 1.d0
      sml(m1_2) = 0.d0
c
      m1_1 = 2
      cml(m1_1) = dcos(xlon)
      sml(m1_1) = dsin(xlon)
c
      cosl = 2.d0*dcos(xlon)
      do m1 = 3, nmax1
        cml(m1) = cosl *cml(m1_1) - cml(m1_2)
        sml(m1) = cosl *sml(m1_1) - sml(m1_2)
        m1_2 = m1_1
        m1_1 = m1
      enddo  !  m1
c
      if (ilong.eq.1) then
        do m1 = 1, nmax1
          xm = dfloat(m1-1)
          tmp(m1) =  cml(m1)
          cml(m1) = -sml(m1) *xm
          sml(m1) =  tmp(m1) *xm
        enddo  !  m
      endif  !  ilong
c
      if (ilong.eq.2) then
        do m1 = 1, nmax1
          xm = -dfloat(m1-1)*dfloat(m1-1)
          cml(m1) = cml(m1) *xm
          sml(m1) = sml(m1) *xm
        enddo  !  m1
      endif  !  ilong
c
      do m1 = 1, nmax1
        temp(m1) = (c_ev(m1,nr)*cml(m1) +s_ev(m1,nr)*sml(m1))
      enddo  !  m1
c
      val = 0.d0
      do m1 = 1, nmax1
        val = val + temp(m1)
      enddo  !  i
c
      ptdata(nr) = ptdata(nr) + val * f_n(nr)
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine exclude(ip,ncols,nr,np,iexc,exc,batch)
c
c-----------------------------------------------------------------------
c
c     WRITES DESIGNATED VALUES TO TO DATA ARRAY TO FLAG NON-EXISTANT OR
c     NON-COMPUTED VALUES.
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUN 2004
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
      real*8 batch(*)
c
      ndat  = ncols*(nr-1)
      do j = 1, ncols
        batch(ndat+j) = exc
      enddo  !  j
c
      if (ip.eq.1) then
        nrs = np-nr
        ndats = ncols*(nrs-1)
        do j = 1, ncols
          batch(ndats+j) = exc
        enddo  !  j
      endif  !  ip
c
      iexc = 0
c
      return
      end
c
c-----------------------------------------------------------------------
c
      SUBROUTINE RADGRAV(IFORM,ISKIP,IREP,ITYP,A,E2,E21,Q0,GM,OMEGA,
     &                   PHI,H,PSI,R,BETA,U,GAMMAE,GAMMAG,GAMMAD,GAMMA,
     &                   upot,gam_sh,gam_sr)
C-----------------------------------------------------------------------
C
C  Subroutine to perform coordinate transformations on the meridian
C  plane and to compute the components of normal gravity/gravitation
C  vector (in ellipsoidal, geocentric, and geodetic coordinates),
C  and the magnitude of the normal gravity/gravitation vector.
C
C  An equipotential ellipsoid of revolution and its associated
C  Somigliana-Pizzetti normal gravity field underlie all computations.
C
C  The location of the computation point is input through either its
C  geodetic latitude and geodetic (ellipsoidal) height if IFORM=1, or
C  its geocentric latitude and geocentric distance if IFORM=2.
C  Due to rotational symmetry, no longitude information is necessary.
C
C  This subroutine uses closed expressions that yield precise results
C  regardless of the point's geodetic height.
C
C  Note: The components gamma_u, gamma_r, gamma_h are positive
C        outwards, and the components gamma_beta, gamma_psi, gamma_phi
C        are positive northwards.
C
C
C  Input
C  =====
C
C  IFORM: Flag such that: IFORM=1 ==> input are geodetic coordinates
C                         IFORM=2 ==> input are geocentric coordinates
C
C  ISKIP: If ISKIP=0 then GAMMAG and GAMMAD computations are skipped
C
C   IREP: Flag that should equal 0 the first time this s/r is called
C
C   ITYP: Flag such that:  ITYP=0 ==> normal gravitation computations
C                          ITYP=1 ==> normal gravity computations
C
C      A: Semi-major axis (m)
C     E2: First eccentricity squared
C    E21: 1-E2
C     Q0: Term defined in [Heiskanen & Moritz, 1967, p. 66, eq. (2-58)]
C     GM: Geocentric gravitational constant (m^3/s^2)*1.d5
C  OMEGA: Rotational rate (rad/s)
C
C    PHI: Geodetic latitude (rad)                    if IFORM=1
C      H: Geodetic (ellipsoidal) height (m)          if IFORM=1
C
C    PSI: Geocentric latitude (rad)                  if IFORM=2
C      R: Geocentric distance (m)                    if IFORM=2
C
C
C  Output
C  ======
C
C        PHI: Geodetic latitude (rad)                if IFORM=2
C          H: Geodetic (ellipsoidal) height (m)      if IFORM=2
C
C        PSI: Geocentric latitude (rad)              if IFORM=1
C          R: Geocentric distance (m)                if IFORM=1
C
C       BETA: Reduced latitude (rad)
C          U: Semi-minor axis of confocal ellipsoid (m)
C
C  GAMMAE(1): gamma_u    (mGal)
C  GAMMAE(2): gamma_beta (mGal)
C  GAMMAG(1): gamma_r    (mGal)                      if ISKIP .ne. 0
C  GAMMAG(2): gamma_psi  (mGal)                      if ISKIP .ne. 0
C  GAMMAD(1): gamma_h    (mGal)                      if ISKIP .ne. 0
C  GAMMAD(2): gamma_phi  (mGal)                      if ISKIP .ne. 0
C
C      GAMMA: magnitude of normal gravity vector (mGal)
c
c-----------------------------------------------------------------------
c     CLOSED EXPR. 4 pot'l,d(gam)/dh,d(gam)/dr:   SIMON HOLMES, JUL 2004
c-----------------------------------------------------------------------
c
      implicit real*8(a-h,o-z)
      dimension gammae(2),gammag(2),gammad(2)
      save
      data pi/3.14159265358979323846d+00/,eps/1.d-10/,iter_max/2/
      data ix/0/
c
c-----------------------------------------------------------------------
c
c     if(irep.eq.0) then
c
      if (ix.eq.0) then
        ix     = 1
        dtr    = pi/180.d0
        asqr   = a*a
        omega2 = omega*omega
        Esqr   = asqr*e2
        E      = sqrt(Esqr)
        cst    = sqrt(e21)
        b      = sqrt(asqr-Esqr)
        f13 = 1.d0/3.d0
      endif  !  ix
c
C-----------------------------------------------------------------------
c
      if(iform.eq.1) then  ! (input are geodetic coordinates)
        sphi  = sin(phi)
        cphi  = cos(phi)
        sphi2 = sphi*sphi
        dn    = a/sqrt(1.d0-e2*sphi2)
        p     = (dn    +h)*cphi
        z     = (dn*e21+h)*sphi
        z2    = z*z
C
C  Compute geocentric distance (m).
C
        r = sqrt(p*p+z2)
C
C  Test for critical locations (Poles and Equator).
C
        test = dabs(phi)-90.d0*dtr
        if(dabs(test).lt.eps.or.dabs(phi).lt.eps) then
          psi  = phi
          beta = phi
C
        else  ! Point not at Poles or Equator
C
C  Compute geocentric latitude (rad).
C
          psi  = atan(z/p)
C
C  Compute reduced latitude (rad).
C
          beta = atan(cst*sphi/cphi)
        endif  ! Poles and Equator when iform=1
C
C  Compute terms needed for normal gravity/gravitation computation.
C
        spsi   = sin(psi)
        cpsi   = cos(psi)
        sbeta  = sin(beta)
        sbeta2 = sbeta*sbeta
        cbeta  = cos(beta)
C
      else  ! iform=2 (input are geocentric coordinates)
C
C  Test for critical locations (Poles and Equator).
C
        test = dabs(psi)-90.d0*dtr
        if(dabs(test).lt.eps.or.dabs(psi).lt.eps) then
c
          phi    = psi
          beta   = psi
          spsi   = sin(psi)
          cpsi   = cos(psi)
          p      = r*cpsi
          z      = r*spsi
          z2     = z*z
          sbeta  = spsi
          sbeta2 = sbeta*sbeta
          cbeta  = cpsi
          cbeta2 = cbeta*cbeta
          sphi   = spsi
          cphi   = cpsi
          h      = (p-a*cbeta)*cphi+(z-b*sbeta)*sphi
C
        else  ! Point not at Poles or Equator
C
          spsi     = sin(psi)
          cpsi     = cos(psi)
          p        = r*cpsi
          z        = r*spsi
          z2       = z*z
          ap       = a*p
          bp       = b*p
          az       = a*z
          bz       = b*z
          rprim    = sqrt(ap*ap+bz*bz)
          cmega    = atan2(bz,ap)
          c        = Esqr/rprim
          beta0    = atan2(az,bp)
          iter_num = 0
C
C  Compute iteratively reduced latitude (rad).
C
    1     twobeta0 = 2.d0*beta0
          s2beta0  = sin(twobeta0)
          c2beta0  = cos(twobeta0)
          diff     = beta0-cmega
          sdiff    = sin(diff)
          cdiff    = cos(diff)
          beta     = beta0-(sdiff-0.5d0*c*s2beta0)/(cdiff-c*c2beta0)
          iter_num = iter_num + 1
          if(iter_num.lt.iter_max) then
            beta0    = beta
            goto 1
          endif  ! Finish iterative calculation of beta
C
C  Compute auxilliary terms and geodetic latitude (rad).
C
          sbeta  = sin(beta)
          sbeta2 = sbeta*sbeta
          cbeta  = cos(beta)
          cbeta2 = cbeta*cbeta
          csbeta = cbeta*sbeta
          phi    = atan(a*sbeta/(b*cbeta))
          sphi   = sin(phi)
          cphi   = cos(phi)
C
C  Compute geodetic (ellipsoidal) height (m).
C
          h      = (p-a*cbeta)*cphi+(z-b*sbeta)*sphi
C
        endif  ! Poles and Equator when iform=2
C
      endif  ! All iform cases considered
C
C  Compute semi-minor axis of confocal ellipsoid (m).
C
      dummy   = r*r-Esqr
      usqr    = .5d0*dummy*(1.d0+sqrt(1.d0+4.d0*Esqr*z2/(dummy*dummy)))
      u       = sqrt(usqr)
c
c-----------------------------------------------------------------------
c
      uE     = usqr + Esqr
      uEi    = 1.d0/uE
      uE2i   = 1.d0/(uE*uE)
      uErt   = dsqrt(uE)
      uErti  = 1.d0/uErt
      uEb    = usqr + Esqr*sbeta2
      uEbrt  = dsqrt(uEb)
      uEbrti = 1.d0/dsqrt(uEb)
c
      ui     = 1.d0/u
      u3     = u*u*u
      Ei     = 1.d0/E
      E3     = E*E*E
      uoE    = u/E
      uoE2   = uoE*uoE
      Eou    = E/u
      Eou2   = Eou*Eou
      atEu   = datan(Eou)
      frac   = 1.d0/(1.d0 + Eou2)
      const  = omega2*a*a*E/q0
      const2 = const*Ei
      fnb    = (0.5d0*sbeta2 - 1.d0/6.d0)
c
      q    = 0.5d0*((1.d0 + 3.d0*uoE2)*atEu - 3.d0*uoE)
      q1   = 3.d0*(1.d0 + uoE2)*(1.d0 - uoE*atEu) - 1.d0
      w = uEbrt/uErt
      wi = 1.d0/w
      q1uEi = q1*uEi
c
c-----------------------------------------------------------------------
c
      fu    = 1.d-5*gm*uEi + const*fnb*q1uEi - ityp*omega2*cbeta2*u
      gamu  = 1.d5*(-wi*fu)
c
      fb   = (-const2*q*uErti + ityp*omega2*uErt)
      gamb = 1.d5*(-wi*fb*csbeta)
c
c-----------------------------------------------------------------------
c
      dwi   = u*(1.d0/(uErt*uEbrt) - uErt/(uEbrt**3))
      dq1u  = 3.d0*(ui*frac - Ei*atEu + (2.d0*u/Esqr)
     &                      - 3.d0*uoE2*Ei*atEu + (u/Esqr)*frac)
      duEi   = -2.d0*u*uE2i
      dq1uEi = dq1u*uEi + q1*duEi
      dfu    = 1.d-5*gm*duEi +const*fnb*dq1uEi - ityp*omega2*cbeta2
      dq = -0.5d0*((Eou*ui + 3.d0*Ei)*frac -6.d0*uoE*Ei*atEu + 3.d0*Ei)
      dfb = (-const2*(dq*uErti - q*u*uErti**3) + ityp*omega2*u*uErti)
      dfudb = const*q1uEi*csbeta + 2.d0*csbeta*ityp*omega2*u
      dwidb = -wi*Esqr*csbeta/uEb
c
c-----------------------------------------------------------------------
c
      dgudu  = -wi*dfu -dwi*fu
      dgbdu  = (-wi*dfb - dwi*fb)*csbeta
      dgudb  = -wi*dfudb - dwidb*fu
      dgbdb  = fb*(-dwidb*csbeta - wi*(cbeta2 - sbeta2))
c
      dgudu_s  =     wi *dgudu *1.d5
      dgbdu_s  =     wi *dgbdu *1.d5
      dgudb_s  = uEbrti *dgudb *1.d5
      dgbdb_s  = uEbrti *dgbdb *1.d5
c
      cent = 5.d4*ityp*omega2*uE*cbeta2
      upot = (GM/E)*atEu +5.d4*const2*q*(sbeta2-f13) + cent
c
c-----------------------------------------------------------------------
c
C  Compute normal gravity/gravitation components and magnitude (mGal).
C
C-- Ellipsoidal System -------------------------------------------------
C
      gammae(1) = gamu
      gammae(2) = gamb
      gamma     = sqrt(gammae(1)*gammae(1) + gammae(2)*gammae(2))
c
      gam_su = (gamu*dgudu_s + gamb*dgbdu_s)/gamma
      gam_sb = (gamu*dgudb_s + gamb*dgbdb_s)/gamma
c
      if(iskip.eq.0) goto 99
C
C-- Geocentric System --------------------------------------------------
C
      dummy     = u/uErt
      gammag(1) = wi*((dummy*cbeta*cpsi + sbeta*spsi)*gammae(1) +
     $                (dummy*cbeta*spsi - sbeta*cpsi)*gammae(2))
      gammag(2) = wi*((sbeta*cpsi - dummy*cbeta*spsi)*gammae(1) +
     $                (sbeta*spsi + dummy*cbeta*cpsi)*gammae(2))
c
      gam_sr = wi*((dummy*cbeta*cpsi + sbeta*spsi)*gam_su +
     &                (dummy*cbeta*spsi - sbeta*cpsi)*gam_sb)
      gam_sy = wi*((sbeta*cpsi - dummy*cbeta*spsi)*gam_su +
     &                (sbeta*spsi + dummy*cbeta*cpsi)*gam_sb)
C
C-- Geodetic System ----------------------------------------------------
C
      alfa    = phi - psi
      salfa   = sin(alfa)
      calfa   = cos(alfa)
      gammad(1) =  gammag(1)*calfa + gammag(2)*salfa
      gammad(2) = -gammag(1)*salfa + gammag(2)*calfa
c
      gam_sh =  gam_sr*calfa + gam_sy*salfa
      gam_st = -gam_sr*salfa + gam_sy*calfa
c
   99 return
      end
c
c-----------------------------------------------------------------------
c
      subroutine gd2gc(phi,ht,ae,b,phig,re)
c
c-----------------------------------------------------------------------
c
c     CONVERTS COORDINATES FROM GEODETIC TO GEOCENTRIC
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUL 2003
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
c
      e2 = (ae*ae-b*b)/(ae*ae)
      u = dsin(phi)
      t = dcos(phi)
      en = ae/dsqrt(1.d0-e2*u*u)
c
      rho = (en + ht)*t
      z = (en*(1.d0-e2) + ht)*u
      phig = datan(z/(rho))
      re = dsqrt(rho*rho + z*z)
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine gc2gd(phig,re,ae,b,phi,h1)
c
c-----------------------------------------------------------------------
c
c     CONVERTS COORDINATES FROM GEOCENTRIC TO GEODETIC
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                           SIMON HOLMES, JUL 2003
c     MODIFIED FOR POLAR COMPS                    SIMON HOLMES, JUL 2005
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
c
      pi2 = 2.d0*datan(1.d0)
c
      theta = pi2 - phig
      u = dsin(theta)
      t = dcos(theta)
      if (dabs(u).lt.1.d-10) then
        if (t.gt.0.d0) phi =  pi2
        if (t.lt.0.d0) phi = -pi2
        h1 = re - b
        return
      endif  !  u
c
      e2 = (ae*ae-b*b)/(ae*ae)
      p = re*dcos(phig)
      zop = (dsin(phig)/dcos(phig))
      phi = datan(zop/(1-e2))
      h0 = 0.d0
c
      do i = 1, 100
        t = dcos(phi)
        u = dsin(phi)
        ewrad = (ae*ae)/(dsqrt(ae*ae*t*t + b*b*u*u))
        h1 = (p/t) - ewrad
        if (dabs(h1-h0).lt.1.d-6) goto 100
        phi = datan(zop/(1.d0-e2*ewrad/(ewrad+h1)))
        h0 = h1
      enddo  !  i
c
  100 continue
c
      return
      end
c
c-----------------------------------------------------------------------
c
      subroutine ptsynth(npt,flat,flon,dist,horth,ptdata,ga,zeta,corr,
     &                   rme,grsv,it,isw,zeta0)
c
c-----------------------------------------------------------------------
c
c     SUBROUTINE FOR COMPUTING GEOID RELATED QUANTITIES AT SCATTERED
c     POINTS
c
c-----------------------------------------------------------------------
c     ORIGINAL PROGRAM:                               R H RAPP, AUG 1982
c     MODIFIED:                                     N K PAVLIS, DEC 1996
c     MODIFIED:                                     N K PAVLIS, JUN 2002
c     REWRITTEN:                                  SIMON HOLMES, JUL 2003
c     MODIFIED:                                   SIMON HOLMES, JUN 2004
c     OUTER-LOOP PARALLELISED:                    SIMON HOLMES, OCT 2004
c     NON-HORNER VERSION:                         SIMON HOLMES, DEC 2004
c     MODIFIED FOR USE WITH v120104 ALFS:         SIMON HOLMES, DEC 2004
c     RAM-FRIENDLY VERSION:                       SIMON HOLMES, JUL 2005
c     ADDS ZETA0 T0 GEOID HTS. AND HT. ANOM.      SIMON HOLMES, MAY 2008
c-----------------------------------------------------------------------
c
      implicit real*8 (a-h,o-z)
c
      real*8 grsv(*),ptdata(*),ga(*),zeta(*),corr(*)
      real*8 horth(*),flat(*),flon(*),dist(*),h,ht
      integer*4 it(*)
      data ik/0/
c
      pi = 4.d0*datan(1.d0)
      dtr = pi/180.d0
c
      ae    = grsv(1)
      b     = grsv(5)
      rf    = grsv(2)
      gm    = grsv(3)
      e2    = grsv(6)
      fm    = grsv(11)
      geqt  = grsv(8)
      dk    = grsv(10)
c
      do nr = 1, npt
c
        ik = ik+1
c
        itx    = it(nr)
        dflat  = flat(nr)
        dflon  = flon(nr)
        xflat  = flat(nr) *dtr
        xflon  = flon(nr) *dtr
        xdist  = dist(nr)
        data   = ptdata(nr)
        xcorr  = corr(nr)
        xga    = ga(nr)
        xzeta  = zeta(nr) + zeta0
c
        if (itx.eq.1) then
          gd   = xflat
          h    = xdist
          dlin = xdist
        else
          gc   = xflat
          re   = xdist
          dlin = (xdist-rme)/1000.d0
          if (isw.eq.80.or.isw.eq.81) call gc2gd(gc,re,ae,b,gd,h)
        endif  !  itx
c
        if (isw.ge.80.and.isw.le.82) then
          if (isw.eq.80.or.isw.eq.81) then
c
            ugd = dsin(gd)
            ugd2 = ugd*ugd
            gv0 = geqt*(1.d0+dk*ugd2)/dsqrt(1.d0-e2*ugd2)
c
            ht = horth(nr)
            f = 1.d0/rf
            hova = h/ae
            ug = dsin(gd)
            coeff = 1.d0+f+fm-2.d0*f*ug*ug
            gv_bar = gv0*(1.d0-coeff*hova+hova*hova)
            alt = 0.d0
            if (ht.ne.0.d0) alt = max(ht,0.d0)
            bga = xga - 0.1119d0*alt
            xcorr = (bga/gv_bar)*alt
c
          endif  !  isw
c
          undu = xzeta + xcorr
c
        endif  !  isw
c
        if (isw.eq.0) data = data + zeta0
c
        if (isw.ne.80.and.isw.ne.81.and.isw.ne.82) then
c
          if (isw.ne.2.and.isw.ne.5.and.isw.ne.100.and.isw.ne.101) then
            write(10,1000) itx,dflat,dflon,dlin,data
            if (ik.le.10) write(6,1000)
     &                     itx,dflat,dflon,dlin,data
          else
            write(10,1000) itx,dflat,dflon,data
            if (ik.le.10) write(6,1000)
     &                     itx,dflat,dflon,data
          endif  !  isw
c
        else
c
          if (isw.eq.80.or.isw.eq.81) then
            write(10,1020) itx,dflat,dflon,dlin,ht,xzeta,xcorr,undu
            if (ik.le.10) write(6,1020)
     &                     itx,dflat,dflon,dlin,ht,xzeta,xcorr,undu
          else
            write(10,990) dflat,dflon,undu
            if (ik.le.10) write(6,995) dflat,dflon,undu
c-----------------------------------------------------------------------
c           write(10,1030) itx,dflat,dflon,xzeta,xcorr,undu
c           if (ik.le.10) write(6,1030)
c    &                     itx,dflat,dflon,xzeta,xcorr,undu
c-----------------------------------------------------------------------
          endif  !  isw
c
        endif  !  isw
c
  990   format(2(f12.6),f11.3)
  995   format(17x,2(f12.6),f11.3)
 1000   format(14x,i2,1x,2f12.6,f11.3,f10.3)
 1020   format(14x,i2,1x,2f12.6,2f11.3,3f10.3)
 1030   format(14x,i2,1x,2f12.6,3f10.3)
c
      enddo  !  nr
c
      return
      end
c
c-----------------------------------------------------------------------
c
      SUBROUTINE FOURT(DATT,NN,NDIM,ISIGN,IFORM,WORK,IDIM1,IDIM2)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C                                                                      C
C                             F O U R T                                C
C                            ===========                               C
C                                                                      C
C                                                                      C
C               THE COOLEY-TUKEY FAST FOURIER TRANSFORM                C
C              =========================================               C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     TRANSFORM(J1,J2,,,,) = SUM(DATT(I1,I2,,,,) * W1**((I1-1)*J1-1))  C
C                            * W2**((I2-1)*(J2-1)) * ,,,,) ,           C
C                                                                      C
C     WHERE I1 AND J1 RUN FROM 1 TO NN(1) AND W1=EXP(ISIGN*2*PI*       C
C     SQRT(-1)/NN(1) ), ETC.                                           C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     THERE IS NO LIMIT IN THE DIMENSIONALITY (NUMBER OF SUBSCRIPTS)   C
C     OF THE DATA ARRAY. IF AN INVERSE TRANSFORM (ISIGN=+1) IS         C
C     PERFORMED UPON AN ARRAY OF TRANSFORMED DATA (ISIGN=-1), THE      C
C     ORIGINAL DATA MULTIPLIED BY NN(1)*NN(2)*,,,, WILL REAPPEAR.      C
C                                                                      C
C     THE TRANSFORM VALUES ARE ALWAYS COMPLEX AND ARE RETURNED IN THE  C
C     ORIGINAL ARRAY OF DATT, REPLACING THE INPUT DATA. THE LENGTH OF  C
C     EACH DIMENSION OF THE DATA ARRAY MAY BE ANY INTEGER. THE PROGRAM C
C     RUNS FASTER ON COMPOSITE INTEGERS THAN ON PRIMES, AND IS         C
C     PARTICULARLY FAST ON NUMBERS RICH IN FACTORS OF TWO.             C
C                                                                      C
C     DETAILS ABOUT THE TIMING DEPENDING ON THE USED DIMENSIONS        C
C     MAY BE FOUND IN THE OPEN FILE REPORT 83-237 FROM THOMAS G.       C
C     HILDENBRAND (SEE BELOW).                                         C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     INPUT PARAMETER DESCRIPTION...                                   C
C     ==============================                                   C
C                                                                      C
C     DATT...      IS THE ARRAY USED TO HOLD THE REAL AND IMAGINARY    C
C                  PARTS OF THE DATA ON INPUT AND THE TRANSFORM VALUES C
C                  ON OUTPUT. IT IS A MULTIDIMENSIONAL FLOATING POINT  C
C                  ARRAY, WITH THE REAL AND IMAGINARY PARTS OF A DATUM C
C                  STORED IMMEDIATELY ADJACENT IN STORAGE (SUCH AS     C
C                  FORTRAN PLACES THEM). NORMAL FORTRTAN ORDERING IS   C
C                  EXPECTED, THE FIRST SUBSCRIPT CHANGING FASTEST.     C
C     NN...        THIS ARRAY OF LENGTH NDIM CONTAINS THE DIMENSIONS   C
C                  OF THE MULTIVARIATE DATA.                           C
C     NDIM...      NDIM SPECIFIES THE NUMBER OF DIMENSIONS IN THE      C
C                  MULTIVARIATE DATA                                   C
C     ISIGN...     ISIGN = -1 INDICATES A FORWARD TRANSFORM (EXPONEN-  C
C                  TIAL SIGN IS -) AND +1 AN INVERSE TRANSFORM (SIGN   C
C                  IS +).                                              C
C     IFORM...     IS +1 IF THE DATA ARE COMPLEX AND 0 IF THE DATA ARE C
C                  REAL. IF IT IS 0, THE IMAGINARY PARTS OF THE DATA   C
C                  MUST BE SET TO ZERO.                                C
C     WORK...      ARRAY USED FOR WORKING STORAGE. IT IS ONE-          C
C                  DIMENSIONAL AND HAS TO BE AT LEAST OF LENGTH        C
C                  EQUAL TO TWICE THE LARGEST ARRAY DIMENSION NN(I)    C
C                  THAT IS NOT A POWER OF TWO. IF ALL NN(I) ARE POWERS C
C                  OF TWO, IT IS NOT NEEDED AND MAY BE REPLACED BY ZEROC
C                  IN THE CALLING SEQUENCE. THUS, FOR A ONE-DIMENSIONALC
C                  ARRAY, NN(1) ODD,  WORK OCCUPIES AS MANY STORAGE    C
C                  LOCATIONS AS DATT.                                  C
C     IDIM1...     DIMENSION OF ARRAY DATT AS DECLARED IN THE CALLING  C
C                  PROGRAM                                             C
C     IDIM2...     DIMENSION OF ARRAY WORK AS DECLARED IN THE CALLING  C
C                  PROGRAM                                             C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     EXAMPLE...                                                       C
C     ==========                                                       C
C                                                                      C
C     THREE-DIMENSIONAL FORWARD FOURIER TRANSFORM OF A COMPLEX ARRAY   C
C     DIMENSIONED 32 BY 25 BY 13 IN FORTRAN.                           C
C                                                                      C
C                                                                      C
C     DIMENSION DATA(32,25,13), WORK(50), NN(3)                        C
C     COMPLEX DATA                                                     C
C     DATA NN/32,25,13/                                                C
C     IDIM1=2*32*25*13                                                 C
C     IDIM2=50                                                         C
C     DO 1 I=1,32                                                      C
C     DO 1 J=1,25                                                      C
C     DO 1 K=1,13                                                      C
C   1 DATA(I,J,K)=COMPLEX VALUE                                        C
C     CALL FOURT(DATA,NN,3,-1,1,WORK,IDIM1,IDIM2)                      C
C                                                                      C
C     OR...                                                            C
C                                                                      C
C     DIMENSION DATA(2,32,25,13), WORK(50), NN(3)                      C
C     DATA NN/32,25,13/                                                C
C     IDIM1=2*32*25*13                                                 C
C     IDIM2=50                                                         C
C     DO 1 I=1,32                                                      C
C     DO 1 J=1,25                                                      C
C     DO 1 K=1,13                                                      C
C     DATA(1,I,J,K)=REAL PART                                          C
C   1 DATA(2,I,J,K)=IMAGINARY PART                                     C
C     CALL FOURT(DATA,NN,3,-1,1,WORK,IDIM1,IDIM2)                      C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     THIS SUBROUTINE HAS BEEN KINDLY PROVIDED BY RENE FORSBERG FROM   C
C     DANISH GEODETIC INSTITUTE, COPENHAGEN. THE CODE IS IN LARGE PARTSC
C     IDENTICAL WITH A SUBROUTINE PUBLISHED BY THOMAS G. HILDENBRAND:  C
C     "FFTFIL: A FILTERING PROGRAM BASED ON TWO-DIMENSIONAL FOURIER    C
C     ANALYSIS OF GEOPHYSICAL DATA", UNITED STATES DEPARTMENT OF THE   C
C     INTERIOR, US GEOLOGICAL SURVEY, OPEN FILE REPORT 83-237. THE     C
C     MAIN DIFFERENCE OF THE TWO VERSIONS ARE OCCURING IN THE PART     C
C     "MAIN LOOP FOR FACTORS NOT EQUAL TO TWO".                        C
C                                                                      C
C     THE SUBROUTINE HAS BEEN TESTED AGAINST A SIMILAR ROUTINE FROM    C
C     THE NAG LIBRARY FOR DIMENSIONS UP TO THREE. NO DIFFERENCES WERE  C
C     FOUND. THIS SUBROUTINE IS RUNNING FASTER THAN THE NAG-ROUTINE    C
C     WHEN DIMENSIONS ARE POWERS OF TWO, BUT IT MAY BE A FACTOR OF     C
C     2 ... 4 SLOWER THAN THE NAG-ROUTINE IF NO GOOD PRIME             C
C     FACTORIZATION IS POSSIBLE.                                       C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     PROGRAM TEST PERFORMED BY    H. DENKER                27/10/1986 C
C     =========================    INSTITUT FUER ERDMESSUNG            C
C                                  UNIVERSITAET HANNOVER               C
C                                  NIENBURGER STRASSE 6                C
C                                  D-3000 HANNOVER 1                   C
C                                                                      C
C     LAST MODIFICATION BY         H. DENKER                26/07/2001 C
C                                  (CONSTANTS CHANGED TO DOUBLE)       C
C                                                                      C
C----------------------------------------------------------------------C
C                                                                      C
C     COMMENT FROM RENE FORSBERG                                       C
C        VERSION=740301                                                C
C        PROGRAM DESCRIPTION NORSAR N-PD9 DATED 1 JULY 1970            C
C        AUTHOR N M BRENNER                                            C
C        FURTHER DESCRIPTION    THREE FORTRAN PROGRAMS ETC.            C
C        ISSUED BY LINCOLN LABORATORY, MIT, JULY 1967                  C
C        TWO CORRECTIONS BY HJORTENBERG 1974                           C
C     THE FAST FOURIER TRANSFORM IN USASI BASIC FORTRAN                C
C                                                                      C
C     MODIFIED TO RC FORTRAN RF JUNE 84                                C
C                                                                      C
C**********************************************************************C
      implicit real*8(a-h,o-z)
      DIMENSION DATT(IDIM1),NN(NDIM),IFACT(32),WORK(IDIM2)
C     LEVEL 2,DATT
      NP0=0
      NPREV=0
      TWOPI=8.d0*ATAN(1.d0)
      RTHLF=1.d0/SQRT(2.d0)
      IF(NDIM-1)920,1,1
1     NTOT=2
      DO 2 IDIM=1,NDIM
      IF(NN(IDIM))920,920,2
2     NTOT=NTOT*NN(IDIM)
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     MAINLOOP FOR EACH DIMENSION                                      C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      NP1=2
      DO 910 IDIM=1,NDIM
      N=NN(IDIM)
      NP2=NP1*N
      IF(N-1)920,900,5
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     IS N A POWER OF TWO AND IF NOT, WHAT ARE ITS FACTORS             C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
5     M=N
      NTWO=NP1
      IF=1
      IDIV=2
10    IQUOT=M/IDIV
      IREM=M-IDIV*IQUOT
      IF(IQUOT-IDIV)50,11,11
11    IF(IREM)20,12,20
12    NTWO=NTWO+NTWO
      IFACT(IF)=IDIV
      IF=IF+1
      M=IQUOT
      GO TO 10
20    IDIV=3
      INON2=IF
30    IQUOT=M/IDIV
      IREM=M-IDIV*IQUOT
      IF(IQUOT-IDIV)60,31,31
31    IF(IREM)40,32,40
32    IFACT(IF)=IDIV
      IF=IF+1
      M=IQUOT
      GO TO 30
40    IDIV=IDIV+2
      GO TO 30
50    INON2=IF
      IF(IREM)60,51,60
51    NTWO=NTWO+NTWO
      GO TO 70
60    IFACT(IF)=M
70    NON2P=NP2/NTWO
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     SEPARATE FOUR CASES---                                           C
C        1. COMPLEX TRANSFORM                                          C
C        2. REAL TRANSFORM FOR THE 2ND, 3ND, ETC. DIMENSION.  METHOD-- C
C           TRANSFORM HALF THE DATT, SUPPLYING THE OTHER HALF BY CON-  C
C           JUGATE SYMMETRY.                                           C
C        3. REAL TRANSFORM FOR THE 1ST DIMENSION,N ODD.  METHOD--      C
C           SET THE IMAGINARY PARTS TO ZERO                            C
C        4. REAL TRANSFORM FOR THE 1ST DIMENSION,N EVEN.METHOD--       C
C           TRANSFORM A COMPLEX ARRAY OF LENGHT N/2 WHOSE REAL PARTS   C
C           ARE THE EVEN NUMBERD REAL VALUES AND WHOSE IMAGINARY PARTS C
C           ARE THE ODD NUMBEREDREAL VALUES.  SEPARATE AND SUPPLY      C
C           THE SECOND HALF BY CONJUGATE SUMMETRY.                     C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
      ICASE=1
      IFMIN=1
      I1RNG=NP1
      IF(IDIM-4)74,100,100
74    IF(IFORM)71,71,100
71    ICASE=2
      I1RNG=NP0*(1+NPREV/2)
      IF(IDIM-1)72,72,100
72    ICASE=3
      I1RNG=NP1
      IF(NTWO-NP1)100,100,73
73    ICASE=4
      IFMIN=2
      NTWO=NTWO/2
      N=N/2
      NP2=NP2/2
      NTOT=NTOT/2
      I=1
      DO 80 J=1,NTOT
      DATT(J)=DATT(I)
80    I=I+2
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     SHUFFLE DATT BY BIT REVERSAL, SINCE N=2**K.  AS THE SHUFFLING    C
C     CAN BE DONE BY SIMPLE INTERCHANGE, NO WORKING ARRAY IS NEEDED    C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
100   IF(NON2P-1)101,101,200
101   NP2HF=NP2/2
      J=1
      DO 150 I2=1,NP2,NP1
      IF(J-I2)121,130,130
121   I1MAX=I2+NP1-2
      DO 125 I1=I2,I1MAX,2
      DO 125 I3=I1,NTOT,NP2
      J3=J+I3-I2
      TEMPR=DATT(I3)
      TEMPI=DATT(I3+1)
      DATT(I3)=DATT(J3)
      DATT(I3+1)=DATT(J3+1)
      DATT(J3)=TEMPR
125   DATT(J3+1)=TEMPI
130   M=NP2HF
140   IF(J-M)150,150,141
141   J=J-M
      M=M/2
      IF(M-NP1)150,140,140
150   J=J+M
      GO TO 300
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     SHUFFLE DATT BY DIGIT REVERSAL FOR GENERAL N                     C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
200   NWORK=2*N
      DO 270 I1=1,NP1,2
      DO 270 I3=I1,NTOT,NP2
      J=I3
      DO 260 I=1,NWORK,2
      IF(ICASE-3)210,220,210
210   WORK(I)=DATT(J)
      WORK(I+1)=DATT(J+1)
      GO TO 240
220   WORK(I)=DATT(J)
      WORK(I+1)=0.d0
240   IFP2=NP2
      IF=IFMIN
250   IFP1=IFP2/IFACT(IF)
      J=J+IFP1
      IF(J-I3-IFP2)260,255,255
255   J=J-IFP2
      IFP2=IFP1
      IF=IF+1
      IF(IFP2-NP1)260,260,250
260   CONTINUE
      I2MAX=I3+NP2-NP1
      I=1
      DO 270 I2=I3,I2MAX,NP1
      DATT(I2)=WORK(I)
      DATT(I2+1)=WORK(I+1)
270   I=I+2
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     MAIN LOOP FOR FACTORS OF TWO                                     C
C     W=EXP(ISIGN*2*PI*SQRT(-1)*M/(4*MMAX)). CHECK FOR W=ISIGN*SQRT(-1)C
C     AND REPEAT FOR W=W*(1+ISIGN*SQRT(-1))/SQRT(2)                    C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
300   IF(NTWO-NP1)600,600,305
305   NP1TW=NP1+NP1
      IPAR=NTWO/NP1
310   IF(IPAR-2)350,330,320
320   IPAR=IPAR/4
      GO TO 310
330   DO 340 I1=1,I1RNG,2
      DO 340 K1=I1,NTOT,NP1TW
      K2=K1+NP1
      TEMPR=DATT(K2)
      TEMPI=DATT(K2+1)
      DATT(K2)=DATT(K1)-TEMPR
      DATT(K2+1)=DATT(K1+1)-TEMPI
      DATT(K1)=DATT(K1)+TEMPR
340   DATT(K1+1)=DATT(K1+1)+TEMPI
350   MMAX=NP1
360   IF(MMAX-NTWO/2)370,600,600
370   LMAX=MAX(NP1TW,MMAX/2)
      DO 570 L=NP1,LMAX,NP1TW
      M=L
      IF(MMAX-NP1)420,420,380
380   THETA=-TWOPI*L/(4.d0*MMAX)
      IF(ISIGN)400,390,390
390   THETA=-THETA
400   WR=COS(THETA)
      WI=SIN(THETA)
410   W2R=WR*WR-WI*WI
      W2I=2.d0*WR*WI
      W3R=W2R*WR-W2I*WI
      W3I=W2R*WI+W2I*WR
420   DO 530 I1=1,I1RNG,2
      KMIN=I1+IPAR*M
      IF(MMAX-NP1)430,430,440
430   KMIN=I1
440   KDIF=IPAR*MMAX
450   KSTEP=4*KDIF
      IF(KSTEP-NTWO)460,460,530
460   DO 520 K1=KMIN,NTOT,KSTEP
      K2=K1+KDIF
      K3=K2+KDIF
      K4=K3+KDIF
      IF(MMAX-NP1)470,470,480
470   U1R=DATT(K1)+DATT(K2)
      U1I=DATT(K1+1)+DATT(K2+1)
      U2R=DATT(K3)+DATT(K4)
      U2I=DATT(K3+1)+DATT(K4+1)
      U3R=DATT(K1)-DATT(K2)
      U3I=DATT(K1+1)-DATT(K2+1)
      IF(ISIGN)471,472,472
471   U4R=DATT(K3+1)-DATT(K4+1)
      U4I=DATT(K4)-DATT(K3)
      GO TO 510
472   U4R=DATT(K4+1)-DATT(K3+1)
      U4I=DATT(K3)-DATT(K4)
      GO TO 510
480   T2R=W2R*DATT(K2)-W2I*DATT(K2+1)
      T2I=W2R*DATT(K2+1)+W2I*DATT(K2)
      T3R=WR*DATT(K3)-WI*DATT(K3+1)
      T3I=WR*DATT(K3+1)+WI*DATT(K3)
      T4R=W3R*DATT(K4)-W3I*DATT(K4+1)
      T4I=W3R*DATT(K4+1)+W3I*DATT(K4)
      U1R=DATT(K1)+T2R
      U1I=DATT(K1+1)+T2I
      U2R=T3R+T4R
      U2I=T3I+T4I
      U3R=DATT(K1)-T2R
      U3I=DATT(K1+1)-T2I
      IF(ISIGN)490,500,500
490   U4R=T3I-T4I
      U4I=T4R-T3R
      GO TO 510
500   U4R=T4I-T3I
      U4I=T3R-T4R
510   DATT(K1)=U1R+U2R
      DATT(K1+1)=U1I+U2I
      DATT(K2)=U3R+U4R
      DATT(K2+1)=U3I+U4I
      DATT(K3)=U1R-U2R
      DATT(K3+1)=U1I-U2I
      DATT(K4)=U3R-U4R
520   DATT(K4+1)=U3I-U4I
      KDIF=KSTEP
      KMIN=4*(KMIN-I1)+I1
      GO TO 450
530   CONTINUE
      M=M+LMAX
      IF(M-MMAX)540,540,570
540   IF(ISIGN)550,560,560
550   TEMPR=WR
      WR=(WR+WI)*RTHLF
      WI=(WI-TEMPR)*RTHLF
      GO TO 410
560   TEMPR=WR
      WR=(WR-WI)*RTHLF
      WI=(TEMPR+WI)*RTHLF
      GO TO 410
570   CONTINUE
      IPAR=3-IPAR
      MMAX=MMAX+MMAX
      GO TO 360
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     MAIN LOOP FOR FACTOERS NOT EQUAL TO TWO                          C
C     W=EXP(ISIGN*2*PI*SQRT(-1)*(J1+J2-I3-1)/IFP2)                     C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
600   IF(NON2P-1)700,700,601
601   IFP1=NTWO
      IF=INON2
610   IFP2=IFACT(IF)*IFP1
      THETA=-TWOPI/IFACT(IF)
      IF(ISIGN)612,611,611
611   THETA=-THETA
612   WSTPR=COS(THETA)
      WSTPI=SIN(THETA)
      DO 650 J1=1,IFP1,NP1
      THETM=-TWOPI*(J1-1.d0)/IFP2
      IF(ISIGN)614,613,613
613   THETM=-THETM
614   WMINR=COS(THETM)
      WMINI=SIN(THETM)
      I1MAX=J1+I1RNG-2
      DO 650 I1=J1,I1MAX,2
      DO 650 I3=I1,NTOT,NP2
      I=1
      WR=WMINR
      WI=WMINI
      J2MAX=I3+IFP2-IFP1
      DO 640 J2=I3,J2MAX,IFP1
      TWOWR=WR+WR
      J3MAX=J2+NP2-IFP2
      DO 630 J3=J2,J3MAX,IFP2
      JMIN=J3-J2+I3
      J=JMIN+IFP2-IFP1
      SR=DATT(J)
      SI=DATT(J+1)
      OLDSR=0.d0
      OLDSI=0.d0
      J=J-IFP1
620   STMPR=SR
      STMPI=SI
      SR=TWOWR*SR-OLDSR+DATT(J)
      SI=TWOWR*SI-OLDSI+DATT(J+1)
      OLDSR=STMPR
      OLDSI=STMPI
      J=J-IFP1
      IF(J-JMIN)621,621,620
621   WORK(I)=WR*SR-WI*SI-OLDSR+DATT(J)
      WORK(I+1)=WI*SR+WR*SI-OLDSI+DATT(J+1)
630   I=I+2
      WTEMP=WR*WSTPI
      WR=WR*WSTPR-WI*WSTPI
640   WI=WI*WSTPR+WTEMP
      I=1
      DO 650 J2=I3,J2MAX,IFP1
      J3MAX=J2+NP2-IFP2
      DO 650 J3=J2,J3MAX,IFP2
      DATT(J3)=WORK(I)
      DATT(J3+1)=WORK(I+1)
650   I=I+2
      IF=IF+1
      IFP1=IFP2
      IF(IFP1-NP2)610,700,700
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     COMPLETE AREAL TRANSFORM IN THE 1ST DIMENSION, N EVEN, BY CON-   C
C     JUGATE SYMMETRIES                                                C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
700   GO TO (900,800,900,701),ICASE
701   NHALF=N
      N=N+N
      THETA=-TWOPI/N
      IF(ISIGN)703,702,702
702   THETA=-THETA
703   WSTPR=COS(THETA)
      WSTPI=SIN(THETA)
      WR=WSTPR
      WI=WSTPI
      IMIN=3
      JMIN=2*NHALF-1
      GO TO 725
710   J=JMIN
      DO 720 I=IMIN,NTOT,NP2
      SUMR=(DATT(I)+DATT(J))/2.d0
      SUMI=(DATT(I+1)+DATT(J+1))/2.d0
      DIFR=(DATT(I)-DATT(J))/2.d0
      DIFI=(DATT(I+1)-DATT(J+1))/2.d0
      TEMPR=WR*SUMI+WI*DIFR
      TEMPI=WI*SUMI-WR*DIFR
      DATT(I)=SUMR+TEMPR
      DATT(I+1)=DIFI+TEMPI
      DATT(J)=SUMR-TEMPR
      DATT(J+1)=-DIFI+TEMPI
720   J=J+NP2
      IMIN=IMIN+2
      JMIN=JMIN-2
      WTEMP=WR*WSTPI
      WR=WR*WSTPR-WI*WSTPI
      WI=WI*WSTPR+WTEMP
725   IF(IMIN-JMIN)710,730,740
730   IF(ISIGN)731,740,740
731   DO 735 I=IMIN,NTOT,NP2
735   DATT(I+1)=-DATT(I+1)
740   NP2=NP2+NP2
      NTOT=NTOT+NTOT
      J=NTOT+1
      IMAX=NTOT/2+1
745   IMIN=IMAX-2*NHALF
      I=IMIN
      GO TO 755
750   DATT(J)=DATT(I)
      DATT(J+1)=-DATT(I+1)
755   I=I+2
      J=J-2
      IF(I-IMAX)750,760,760
760   DATT(J)=DATT(IMIN)-DATT(IMIN+1)
      DATT(J+1)=0.d0
      IF(I-J)770,780,780
765   DATT(J)=DATT(I)
      DATT(J+1)=DATT(I+1)
770   I=I-2
      J=J-2
      IF(I-IMIN)775,775,765
775   DATT(J)=DATT(IMIN)+DATT(IMIN+1)
      DATT(J+1)=0.d0
      IMAX=IMIN
      GO TO 745
780   DATT(1)=DATT(1)+DATT(2)
      DATT(2)=0.d0
      GO TO 900
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     COMPLETE A REAL TRANSFORM FOR THE 2ND, 3RD, ETC. DIMENSION BY    C
C     CONJUGATE SYMMETRIES.                                            C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
800   IF(I1RNG-NP1)805,900,900
805   DO 860 I3=1,NTOT,NP2
      I2MAX=I3+NP2-NP1
      DO 860 I2=I3,I2MAX,NP1
      IMAX=I2+NP1-2
      IMIN=I2+I1RNG
      JMAX=2*I3+NP1-IMIN
      IF(I2-I3)820,820,810
810   JMAX=JMAX+NP2
820   IF(IDIM-2)850,850,830
830   J=JMAX+NP0
      DO 840 I=IMIN,IMAX,2
      DATT(I)=DATT(J)
      DATT(I+1)=-DATT(J+1)
840   J=J-2
850   J=JMAX
      DO 860 I=IMIN,IMAX,NP0
      DATT(I)=DATT(J)
      DATT(I+1)=-DATT(J+1)
860   J=J-NP0
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
C     END OF LOOP ON EACH DIMENSION                                    C
CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC
900   NP0=NP1
      NP1=NP2
910   NPREV=N
920   RETURN
      END
c
c-----------------------------------------------------------------------
c
c   ALF SUBROUTINES START HERE.
c
c-----------------------------------------------------------------------
c
c   Associated Legendre Function Computation Subroutines (v121305)
c
c   File: alf_sr_v121305
c
c-----------------------------------------------------------------------
c
c   Point Value Computations
c
c-----------------------------------------------------------------------
c
c
c
      subroutine alfpsct(nrst,nrfn,thetc,nmax,gs,ider,pmmd0,pmmd1,zero,
     &                   nmax0)
c-----------------------------------------------------------------------
c
c   This is a Fortran 77 subroutine to compute scaled, point values, and
c   first derivatives, of sectorial Associated Legendre Functions (ALFs).
c
c   Differentiation is with respect to co-latitude.
c
c   Input arguments are: the array 'thetc', in which the 'thetc(nr)'
c   element holds the northern spherical polar distance (in radians) for
c   the parallel 'nr'; the first ('nrst') and last ('nrfn') parallel
c   bands for which sectorial ALFs are to be computed; the maximum order
c   of the required ALFs 'nmax'; a global scale factor 'gs'; the
c   flag 'ider' which specifies the order of the derivative required,
c   where 'ider = 0' selects undifferentiated values only and 'ider = 1'
c   selects undifferentiated values AND first derivatives ; and 'nmax0',
c   which is used to define the first dimension of the 2-D arrays
c   'pmmd0' and 'pmmd1' (see below).
c
c   'zero' is an internal 1-D array that is not intended to pass values
c   between this subroutine and the calling program. It is included in
c   the calling statement to allow the calling program to define its
c   dimension (see below).
c
c   Scaled sectorial ALFs and their first derivatives are returned in
c   the 2-D arrays 'pmmd0' and 'pmmd1', respectively. For order 'm' and
c   parallel band 'nr', the elements 'pmmd0(m+1,nr)' and 'pmmd1(m+1,nr)'
c   hold, respectively, the sectorial ALF, and its first derivative.
c
c   The following arrays should be dimensioned in the calling program
c   as follows:
c
c   - thetc(maxr)
c   - pmmd0(nmax0+1,maxr+1)
c   - pmmd1(nmax0+1,maxr)
c   - zero(maxr+1)
c
c   where:
c
c   - 'maxr' should be set in the calling program such that 'nrfn' is
c     never larger than 'maxr', and
c   - 'nmax0' should be set in the calling program such that 'nmax' is
c     never larger than 'nmax0'.
c
c   Note that 'nmax' should never be larger than 2700.
c
c   This subroutine was originally called 'pmm1'.
c
c-----------------------------------------------------------------------
c
c     ORIGINAL PROGRAM:                           SIMON HOLMES, OCT 2004
c     MODIFIED TO ZERO HIGH-ORDER SECTORIALS:     SIMON HOLMES, JUN 2005
c     MODIFIED:                                   SIMON HOLMES, AUG 2005
c     MODIFIED:                                   SIMON HOLMES, NOV 2005
c
c-----------------------------------------------------------------------
      implicit real*8(a-h,o-z)
      parameter(nm=2700,nm1=nm+1)
      real*8 thetc(*),c(nm1),dbl(nm1)
      real*8 pmmd0(nmax0+1,*),pmmd1(nmax0+1,*)
      integer*4 zero(*)
c-----------------------------------------------------------------------
      if (nmax.gt.nmax0.or.nmax0.gt.2700) then
        write(6,6002)
 6002   format(///5x,
     &'***      Error in s/r alfpsct: nmax > nmax0 or nmax0 > 2700 ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
        stop
      endif  !  nmax,nmax0
c-----------------------------------------------------------------------
      nmax1 = nmax+1
      xmax1 = nmax1*1.d0
       pi = 4.d0*datan(1.d0)
      pip = pi + 1.d-10
      c(2) = dsqrt(3.d0)
      do n1 = 3, nmax1
          n = n1-1
        rn2 = n*2.d0
          c(n1) = dsqrt(rn2+1.d0)/dsqrt(rn2)
        dbl(n1) = n*1.d0
      enddo  !  n1
c-----------------------------------------------------------------------
      small = dlog10(1.d-200)
      gslog = dlog10(gs)
      do nr = nrst, nrfn
        thc = thetc(nr)
          u = dsin(thc)
        if (thc.lt.-1.d-10.or.thc.gt.pip) then
          write(6,6000)
          stop
        endif  !  thc
        if (u.eq.0.d0) then
          mmax1 = 1
        elseif (u.eq.1.d0) then
          mmax1 = nmax1
        else
          testm1 = (small - gslog)/dlog10(u) + 1.d0
          if (testm1.gt.xmax1) testm1 = xmax1
          mmax1 = nint(testm1)
        endif  !  u
        zero(nr) = mmax1
      enddo  !  nr
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        do n1 = 1, nmax1
          pmmd0(n1,nr) = 0.d0
        enddo  !  n1
      enddo  !  nr
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        thc = thetc(nr)
          u = dsin(thc)
        pmmd0(1,nr) = gs
        mmax1 = zero(nr)
        do n1 = 2, mmax1
          pmmd0(n1,nr) = c(n1)*pmmd0(n1-1,nr)*u
        enddo  !  n1
      enddo  !  nr
      if (ider.eq.0) return
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        thc = thetc(nr)
          t = dcos(thc)
          u = dsin(thc)
        if (dabs(u).lt.1.d-10) u = 0.d0
        ui = 0.d0
        if (u.ne.0.d0) ui = 1.d0/u
        cot = t*ui
        pmmd1(1,nr) = 0.d0
        pmmd1(2,nr) = c(2)*t*gs
        do n1 = 3, nmax1
          pmmd1(n1,nr) = pmmd0(n1,nr)*cot*dbl(n1)
        enddo  !  n1
      enddo  !  nr
c-----------------------------------------------------------------------
 6000 format(///5x,
     &'***      Error in s/r alfpsct: check that 0<=thetc<=pi      ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
c-----------------------------------------------------------------------
      return
      end
c
c
c
      subroutine alfpord(nrst,nrfn,thetc,m,nmax,ider,pmmd0,pmmd1,
     &                   p,p1,p2,uc,tc,uic,uic2,cotc,nmax0)
c-----------------------------------------------------------------------
c
c   This is a Fortran 77 subroutine to compute scaled, non-sectorial,
c   Associated Legendre Functions (ALFs), and their first and second
c   derivatives, for a given order 'm' and for all degrees from 'm'
c   to 'nmax'.
c
c   Differentiation is with respect to co-latitude.
c
c   Input arguments are: The array 'thetc', in which the 'thetc(nr)'
c   element holds the northern spherical polar distance (in radians) for
c   the parellel 'nr'; the first ('nrst') and last ('nrfn') parallel
c   bands for which non-sectorial ALFs are to be computed; the order 'm'
c   for which non-sectorial ALFs are to be computed; the maximum degree
c   of the required ALFs 'nmax'; the flag 'ider', which specifies the
c   order of the derivative required, where 'ider = 0' selects
c   undifferentiated values only, 'ider = 1' selects undifferentiated
c   values AND first derivatives, and 'ider = 2' selects undifferenti-
c   ated values AND first AND second derivatives.
c
c   Scaled point values of the sectorial ALFs and of their first
c   derivatives are input through the 2-D arrays 'pmmd0' and 'pmmd1',
c   respectively. The element 'pmmd0(m+1,nr)' holds the sectorial
c   ALF of order 'm' and parallel band 'nr'. The indexing of 'pmmd1'
c   is identical to that of 'pmmd0'. 'nmax0' is used to define the
c   first dimension of 'pmmd0' and 'pmmd1', as well as the first
c   dimension of the 2-D arrays 'p', 'p1' and 'p2' (see below).
c
c   The arrays 'uc','tc','uic','uic2', and 'cotc' are 1-D arrays
c   used for internal computations within the alfpord subroutine.
c   They are not intended to pass values between the subroutine and
c   the calling program. They are included in the calling statement
c   to allow the calling program to define their dimensions (see
c   below).
c
c   The input order 'm' must be less than or equal to the maximum
c   degree 'nmax'.
c   For each order 'm', sectorial ALFs and their derivatives are
c   computed for all degrees from 'm' to 'nmax', and these for all
c   parallel bands from 'nrst' to 'nrfn'.
c
c   ALFs are returned in the 2-D array 'p', in which the 'p(n+1,nr)'
c   element holds the ALF of degree 'n', parallel band 'nr', for the
c   specified order 'm'. First and second derivatives are returned in
c   the 2-D arrays 'p1' and 'p2', respectively. The indexing of 'p1'
c   and 'p2' is identical to that of 'p'.
c
c   Note that any global scaling of the computed ALFs enters through
c   the pre-computed (input) sectorial values in 'pmmd0' and 'pmmd1'.
c
c   The following arrays should be dimensioned in the calling program
c   as follows:
c
c   - thetc(maxr)
c   - pmmd0(nmax0+1,maxr+1)
c   - pmmd1(nmax0+1,maxr)
c   - p(nmax0+2,maxr)
c   - p1(nmax0+2,maxr)
c   - p2(nmax0+2,maxr)
c   - uc(maxr)
c   - tc(maxr)
c   - uic(maxr)
c   - uic2(maxr)
c   - cotc(maxr)
c
c   where:
c
c   - 'maxr' should be set in the calling program such that 'nrfn' is
c     never larger than 'maxr', and
c   - 'nmax0' should be set in the calling program such that 'nmax' is
c     never larger than 'nmax0'.
c
c   Note that 'nmax' should never be larger than 2700.
c
c   This subroutine was originally called 'ptm1'.
c
c-----------------------------------------------------------------------
c
c     ORIGINAL PROGRAM:                           SIMON HOLMES, SEP 2004
c     REMOVED DOUBLE COEFF ARRAYS:                SIMON HOLMES, JUL 2005
c     MODIFIED:                                   SIMON HOLMES, AUG 2005
c     MODIFIED:                                   SIMON HOLMES, NOV 2005
c
c-----------------------------------------------------------------------
      implicit real*8(a-h,o-z)
      parameter(nm=2700,nm1=nm+1)
      real*8 thetc(*),pmmd0(nmax0+1,*),pmmd1(nmax0+1,*)
      real*8 rt(0:2*nm+5),rti(0:2*nm+5),dbl(0:2*nm+5)
      real*8 a(nm1),b(nm1),f(nm1),temp(nm1)
      real*8 c(nm1),d(nm1),g(nm1)
      real*8 uc(*),tc(*),uic(*),uic2(*),cotc(*)
      real*8 p(nmax0+2,*),p1(nmax0+2,*),p2(nmax0+2,*)
c-----------------------------------------------------------------------
      save
      data ix,nmax_old/0,0/
       nmax1 = nmax+1
      nmax2p = 2*nmax+5
c-----------------------------------------------------------------------
      if (nmax.gt.nmax0.or.nmax0.gt.2700) then
        write(6,6002)
 6002   format(///5x,
     &'***      Error in s/r alfpord: nmax > nmax0 or nmax0 > 2700 ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
        stop
      endif  !  nmax,nmax0
c-----------------------------------------------------------------------
      if (m.gt.nmax) then
        write(6,6001)
 6001   format(///5x,'***  Error in s/r alfpord: m > Nmax  ***',
     &          //5x,'***        Execution Stopped         ***',///)
        stop
      endif  !  m
c-----------------------------------------------------------------------
      if (ix.eq.0.or.nmax.gt.nmax_old) then
        ix = 1
        nmax_old = nmax
        do n = 1, nmax2p
           rt(n) = dsqrt(dble(n))
          rti(n) = 1.d0/rt(n)
          dbl(n) = dble(n)
        enddo  !  n
         rt(0) = 0.d0
        rti(0) = 0.d0
        dbl(0) = 0.d0
        do n = 1, nmax
          n1 = n+1
          n2 = 2*n
          c(n1) = rt(n2+1)*rti(n2)
          d(n1) = dble(n*n)
          g(n1) = dble(n*n1)
        enddo  !  n
      endif  !  ix
c-----------------------------------------------------------------------
      m1 = m+1
      m2 = m+2
      m3 = m+3
      do n = m+1, nmax
        f(n+1) = rt(n-m)*rt(n+m)*rt(2*n+1)*rti(2*n-1)
      enddo  !  n
      do n = m+2, nmax
        temp(n+1) = rt(n*2+1)*rti(n+m)*rti(n-m)
        a(n+1) = temp(n+1)*rt(n*2-1)
        b(n+1) = temp(n+1)*rt(n+m-1)*rt(n-m-1)*rti(n*2-3)
      enddo  !  n
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
           thc = thetc(nr)
        tc(nr) = dcos(thc)
        uc(nr) = dsin(thc)
        if (dabs(uc(nr)).lt.1.d-10) uc(nr) = 0.d0
        uic(nr) = 0.d0
        if (uc(nr).ne.0.d0) uic(nr) = 1.d0/uc(nr)
        uic2(nr) = uic(nr)*uic(nr)
        cotc(nr) = tc(nr)*uic(nr)
      enddo  !  nr
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        p(m1,nr) = pmmd0(m1,nr)
        p(m2,nr) = rt(m1*2+1)*tc(nr)*p(m1,nr)
        do n1 = m3, nmax1
          p(n1,nr) = a(n1)*tc(nr)*p(n1-1,nr)-b(n1)*p(n1-2,nr)
        enddo  !  n1
      enddo  !  nr
      if (ider.eq.0) return
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        p1(m1,nr) = pmmd1(m1,nr)
        do n1 = m2, nmax1
          p1(n1,nr) = cotc(nr)*dbl(n1-1)*p(n1,nr)
     &               -uic(nr)*f(n1)*p(n1-1,nr)
        enddo  !  n1
      enddo  !  nr
      if (ider.eq.1) return
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        do n1 = m1, nmax1
          p2(n1,nr) = (d(m1)*uic2(nr) - g(n1))*p(n1,nr)
     &                 -cotc(nr)*p1(n1,nr)
        enddo  !  n1
      enddo  !  nr
c-----------------------------------------------------------------------
      return
      end
c-----------------------------------------------------------------------
c
c   Integrated Value Computations
c
c-----------------------------------------------------------------------
c
c
c
      subroutine iseries(u1sq,u2sq,n,pmm_1,pmm_2,spimm)
c-----------------------------------------------------------------------
c
c   Gerstl (1980, p.193): Identity to compute the required number of
c                         terms for a specified level of precision.
c
c   Note: For small integration regions, cancelling effects (loss of
c         significant figures) govern the maximum precision attainable,
c         NOT the number of terms.
c
c         For high degrees (Gerstl, 1980, p.193) must be determined
c         by the northern-most boundary, NOT an average of the north
c         and south.
c
c-----------------------------------------------------------------------
      implicit real*8(a-h,o-z)
      logerror = dlog(1.d-16)
      usq = dmax1(u1sq,u2sq)
      n1 = n+1
      x0 = (1.d0+logerror)/dlog(usq)
      im = dint(x0) + 1
c-----------------------------------------------------------------------
c
c   Paul (1978, eq.25): Series expansion for sectorial integrals.
c
c-----------------------------------------------------------------------
      x = dble(2*im)
      xpm = dble(n) + x
      top = x - 3.d0
      den = x - 2.d0
      sum2 = 0.d0
      sum1 = 0.d0
      do i = 1, im-1
         xpmi = 1.d0/xpm
        ratio = top/den
        sum2 = (sum2 + xpmi)*ratio*u2sq
        sum1 = (sum1 + xpmi)*ratio*u1sq
        xpm = xpm - 2.d0
        top = top - 2.d0
        den = den - 2.d0
      enddo  !  i
      sum2 = (sum2 + 1.d0/xpm)*pmm_2*u2sq
      sum1 = (sum1 + 1.d0/xpm)*pmm_1*u1sq
      spimm = dabs(sum1 - sum2)
c-----------------------------------------------------------------------
      return
      end
c
c
c
      subroutine alfisct(nrst,nrfn,thet1,thet2,nmax,gs,pmm,pimm,zero,
     &                   nmax0)
c-----------------------------------------------------------------------
c
c   This is a Fortran 77 subroutine to compute scaled definite integrals
c   of sectorial Associated Legendre Functions (ALFs), as well as point
c   values of sectorial ALFs for the northern and southern boundaries of
c   each integration region.
c
c   Definite integration is with respect to the cosine of co-latitude.
c
c   For input, two arrays hold the northern spherical polar distance
c   (in radians) of the northern ('thet2') and southern ('thet1')
c   boundaries of the required integrals. The arrays 'thet2(nr)' and
c   'thet1(nr)' contain, respectively, the northern and southern
c   boundary arguments for the parallel band 'nr'. Inputs 'nrst' and
c   'nrfn' denote, respectively, the northern-most and southern-most
c   parallel bands for which ALF integrals and point values are
c   computed.
c
c   Other input arguments are: The maximum order 'nmax' up to which
c   ALFs will be computed; a global scale factor 'gs'; and 'nmax0',
c   which is used to define the first dimension of the 2-D arrays
c   'pmm' and 'pimm' (see below).
c
c   Integrals and point values of sectorial ALFs are computed from
c   order zero to 'nmax', for all parallel bands from 'nrst' to 'nrfn'.
c
c   'zero' is an internal 1-D array that is not intended to pass values
c   between this subroutine and the calling program. It is included in
c   the calling statement to allow the calling program to define its
c   dimension (see below).
c
c   Sectorial ALF integrals are returned in the 2-D array 'pimm',
c   in which the 'pimm(m+1,nr)' element holds the sectorial ALF
c   integral of order 'm' and parallel band 'nr'. Sectorial point
c   values are returned in the 2-D array 'pmm', in which the
c   'pmm(m+1,nr)'and 'pmm(m+1,nr+1)' elements hold the sectorial ALF
c   point values for order 'm', and for, respectively, the northern
c   and southern boundary of the parallel band 'nr'. Note that this
c   output assumes that the parallel bands adjoin each other, so that
c   the southern boundary of parallel band 'nr' is also the northern
c   boundary of parallel band 'nr+1'.
c
c   External: This subroutine calls the subroutine 'iseries'.
c
c   The following arrays should be dimensioned in the calling program
c   as follows:
c
c   - thet1(maxr)
c   - thet2(maxr)
c   - pmm(nmax0+1,maxr+1)
c   - pimm(nmax0+1,maxr)
c   - zero(maxr+1)
c
c   where:
c
c   - 'maxr' should be set in the calling program such that 'nrfn' is
c     never larger than 'maxr', and
c   - 'nmax0' should be set in the calling program such that 'nmax' is
c     never larger than 'nmax0'.
c
c   Note that 'nmax' should never be larger than 2700.
c
c   This subroutine was originally called 'sectoral6'.
c
c-----------------------------------------------------------------------
c
c   Fwd/Rev sectorial decision rule: Gerstl (1980, Eq. 13)
c   Sectorial recursion over increasing order: Paul (1978, Eq. 22a)
c   Sectorial recursion over decreasing order: Gleason (1985, Eq. 4.23)
c
c   Paul MK, (1978). Recurrence relations for integrals of associated
c      Legendre functions, Bulletin Geodesique, 52, pp177-190.
c   Gerstl M, (1980). On the recursive computation of the integrals of
c      the associated Legendre functions, manuscripta geodaetica, 5,
c      pp181-199.
c   Gleason, DM (1985). Partial sums of Legendre series via Clenshaw
c      summation, manuscripta geodaetica, 10, pp115-130.
c
c-----------------------------------------------------------------------
c
c     ORIGINAL PROGRAM:                           SIMON HOLMES, OCT 2004
c     MODIFIED TO ZERO HIGH-ORDER SECTORIALS:     SIMON HOLMES, JUN 2005
c     MODIFIED:                                   SIMON HOLMES, AUG 2005
c     MODIFIED:                                   SIMON HOLMES, NOV 2005
c
c-----------------------------------------------------------------------
      implicit real*8(a-h,o-z)
      parameter(nm=2700,nm1=nm+1)
      real*8 thet1(*),thet2(*)
      real*8 rt(0:2*nm+5),rti(0:2*nm+5),dbl(0:2*nm+5)
      real*8 a(nm1),b(nm1),c(nm1),d(nm1)
      real*8 tmp1(nm),tmp2(nm)
      real*8 pmm(nmax0+1,*),pimm(nmax0+1,*)
      integer*4 zero(*)
c-----------------------------------------------------------------------
      if (nmax.gt.nmax0.or.nmax0.gt.2700) then
        write(6,6002)
 6002   format(///5x,
     &'***      Error in s/r alfisct: nmax > nmax0 or nmax0 > 2700 ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
        stop
      endif  !  nmax,nmax0
c-----------------------------------------------------------------------
       nrst1 = nrst+1
       nrfn1 = nrfn+1
       nmax1 = nmax+1
       xmax1 = nmax1*1.d0
      nmax2p = 2*nmax+5
        pi = 4.d0*datan(1.d0)
       pip = pi + 1.d-10
       pis = pi - 1.d-10
       pi2 = 0.5d0 * pi
      pi2p = pi2 + 1.d-10
      pi2s = pi2 - 1.d-10
c-----------------------------------------------------------------------
      do n = 1, nmax2p
         rt(n) = dsqrt(dble(n))
        rti(n) = 1.d0/rt(n)
        dbl(n) = dble(n)
      enddo  !  n
       rt(0) = 0.d0
      rti(0) = 0.d0
      dbl(0) = 0.d0
      do n = 1, nmax
        ns1 = n-1
         n1 = n+1
         n2 = 2*n
        a(n1) = 1.d0/dbl(n2+2)
        b(n1) = rt(n)*rt(n2-1)*rt(n2+1)*rti(ns1)
        c(n1) = rt(n2+1)*rti(n2)
        d(n1) = 2.d0*rt(n1)*rti(n+2)*rti(n2+3)*rti(n2+5)
      enddo  !  n
c-----------------------------------------------------------------------
      small = dlog10(1.d-200)
      gslog = dlog10(gs)
      do nr = nrst, nrfn
        th2 = thet2(nr)
        th1 = thet1(nr)
         u2 = dsin(th2)
         u1 = dsin(th1)
        if (th2.lt.-1.d-10.or.th1.gt.pip.or.th1.lt.th2) then
          write(6,6000)
          stop
        endif  !  th1;th2
        if (th2.lt.pi2s.and.th1.gt.pi2p) then
          write(6,6001)
          stop
        endif  !  th1;th2
        u = dsin(th2)
        if (dabs(u).lt.1.d-10) u = dsin(th1)
        if (u.eq.1.d0) then
          mmax1 = nmax1
        else
          testm1 = (small - gslog)/dlog10(u) + 1.d0
          if (testm1.gt.xmax1) testm1 = xmax1
          mmax1 = nint(testm1)
        endif  !  u
        zero(nr) = mmax1
      enddo  !  nr
c
      if (nrfn.ne.-1) then
        u = dsin(thet1(nrfn))
        if (dabs(u).lt.1.d-10) u = dsin(thet1(nrfn-1))
        if (u.eq.1.d0) then
          mmax1 = nmax1
        else
          testm1 = (small - gslog)/dlog10(u) + 1.d0
          if (testm1.gt.xmax1) testm1 = xmax1
          mmax1 = nint(testm1)
        endif  !  u
        zero(nrfn+1) = mmax1
      endif  !  nrfn
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        do n1 = 1, nmax1
           pmm(n1,nr) = 0.d0
          pimm(n1,nr) = 0.d0
        enddo  !  n1
      enddo  !  nr
      if (nrfn.ne.-1) then
        do n1 = 1, nmax1
          pmm(n1,nrfn+1) = 0.d0
        enddo  !  n1
      endif  !  nrfn
c-----------------------------------------------------------------------
      if (nrst.ne.0) then
        th2 = thet2(nrst)
         u2 = dsin(th2)
        if (dabs(u2).lt.1.d-10) u2 = 0.d0
        pmm(1,nrst) = gs
        if (nmax.gt.0) pmm(2,nrst) = rt(3)*u2*gs
        mmax1 = zero(nrst)
        do n1 = 3, mmax1
          pmm(n1,nrst) = c(n1)*pmm(n1-1,nrst)*u2
        enddo  !  n1
      endif  !  nrst
      do nr1 = nrst1, nrfn1
        mmax1 = zero(nr1)
        th1 = thet1(nr1-1)
         u1 = dsin(th1)
        if (dabs(u1).lt.1.d-10) u1 = 0.d0
        pmm(1,nr1) = gs
        if (nmax.gt.0) pmm(2,nr1) = rt(3)*u1*gs
        do n1 = 3, mmax1
          pmm(n1,nr1) = c(n1)*pmm(n1-1,nr1)*u1
        enddo  !  n1
      enddo  !  nr1
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        th1 = thet1(nr)
        th2 = thet2(nr)
         u1 = dsin(th1)
         u2 = dsin(th2)
         t1 = dcos(th1)
         t2 = dcos(th2)
        if (dabs(t1).lt.1.d-10) then
          t1 =  0.d0
          u1 =  1.d0
        elseif (dabs(t2).lt.1.d-10) then
          t2 =  0.d0
          u2 =  1.d0
        elseif (dabs(u1).lt.1.d-10) then
          u1 =  0.d0
          t1 = -1.d0
        elseif (dabs(u2).lt.1.d-10) then
          u2 =  0.d0
          t2 =  1.d0
        endif
        u1sq = u1*u1
        u2sq = u2*u2
        mmax1 = zero(nr)
        if (u1.lt.u2.and.dabs(u1).gt.1.d-10) mmax1 = zero(nr+1)
        mmax  = mmax1-1
c
        pimm(1,nr) = gs*
     &               2.d0*dsin((th1-th2)*.5d0)*dsin(((th1+th2)*.5d0))
        usq = dmin1(u2sq,u1sq)
        if (usq.eq.0.d0) then
          xk = 2
        else
          xk = (mmax)/(mmax1*usq)
        endif  !  usq
        if (u1.eq.1.d0.or.u2.eq.1.d0) then
          xk = -1.d0
        endif  !  u1;u2
c
        if (xk.lt.1) then
          if (nmax.ge.1)
     &    pimm(2,nr) = rt(3)*.5d0*(t2*u2-th2-t1*u1+th1)*gs
          if (nmax.ge.2)
     &    pimm(3,nr) = (rt(3)*rt(5)*pimm(1,nr)+t2*pmm(3,nr)
     &                                   -t1*pmm(3,nr+1))*rti(3)*rti(3)
          do n1 = 4, mmax1
            pimm(n1,nr) = a(n1)*( b(n1)*pimm(n1-2,nr)
     &                           +2.d0*(t2*pmm(n1,nr)-t1*pmm(n1,nr+1)))
          enddo  !  n1
c
        else  !  xk
          pmm_2 = pmm(mmax1,nr  )
          pmm_1 = pmm(mmax1,nr+1)
          call iseries(u1sq,u2sq,mmax,pmm_1,pmm_2,spimm)
          pimm(mmax1,nr) = spimm
          if (mmax.ne.0) then
            pmm_2 = pmm(mmax,nr  )
            pmm_1 = pmm(mmax,nr+1)
          endif  !  mmax
          call iseries(u1sq,u2sq,mmax-1,pmm_1,pmm_2,spimm)
          if (nmax.ne.0) pimm(nmax,nr) = spimm
          do n1 = 2, mmax-1
            tmp1(n1) = d(n1)*dbl(n1+2)
            tmp2(n1) = d(n1)*(t1*pmm(n1+2,nr+1) - t2*pmm(n1+2,nr))
          enddo  !  n1
          do n1 = mmax-1, 2, -1
            pimm(n1,nr) = tmp1(n1)*pimm(n1+2,nr) + tmp2(n1)
          enddo  !  n1
        endif  !  xk
      enddo  !  nr
c-----------------------------------------------------------------------
 6000 format(///5x,
     &'***  Error in s/r alfisct: check that 0<=thet2<=thet1<=pi   ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
c-----------------------------------------------------------------------
 6001 format(///5x,
     &'***  Error in s/r alfisct:    integrals across the equator  ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
c-----------------------------------------------------------------------
      return
      end
c
c
c
      subroutine alfiord(nrst,nrfn,thet1,thet2,m,nmax,pmm,pimm,pint,
     &                   p1,p2,nmax0)
c-----------------------------------------------------------------------
c
c   This is a Fortran 77 subroutine to compute scaled, definite
c   integrals of non-sectorial Associated Legendre Functions (ALFs), as
c   well as point values of non-sectorial ALFs for the northern and
c   southern boundaries of each integration region, for a given order
c   'm' and for all degrees from 'm' to 'nmax'.
c
c   Definite integration is with respect to the cosine of co-latitude.
c
c   For input, two arrays hold the northern spherical polar distance
c   (in radians) of the northern ('thet2') and southern ('thet1')
c   boundaries of the required integrals. The arrays 'thet2(nr)' and
c   'thet1(nr)' contain, respectively, the northern and southern
c   boundary arguments for the parallel band 'nr'. Inputs 'nrst' and
c   'nrfn' denote, respectively, the northern-most and southern-most
c   parallel bands for which ALF integrals and point values are to be
c   computed.
c
c   Sectorial ALF integrals are input through the 2-D array 'pimm',
c   in which the 'pimm(m+1,nr)' element holds the sectorial ALF
c   integral of order 'm' and parallel band 'nr'. Sectorial ALF point
c   values are input through the 2-D array 'pmm', in which the
c   'pmm(m+1,nr)' and 'pmm(m+1,nr+1)' elements hold the sectorial ALF
c   point values for order 'm', and for, respectively, the northern and
c   southern boundary of the parallel band 'nr'. Note that this input
c   assumes that the parallel bands adjoin each other, so that the
c   southern boundary of parallel band 'nr' is also the northern
c   boundary of parallel band 'nr+1'.
c
c   Other input arguments are: The order 'm' for which the ALF
c   integrals and point values will be computed; the maximum degree
c   of the ALFs 'nmax'; and 'nmax0', which is used to define the first
c   dimension of the 2-D arrays 'pmm', 'pimm', 'p1' ,'p2' and 'pint'
c   (see below).
c
c   For a given order 'm', the subroutine returns all ALF integrals,
c   from degree 'm' to 'nmax', for all parallel bands from 'nrst' to
c   'nrfn'.
c
c   ALF integrals are returned in the 2-D array 'pint', in which the
c   'pint(n+1,nr)' element holds the integral of degree 'n' and
c   parallel band 'nr', for the specified order 'm'. ALF point values
c   are stored in the 2-D arrays 'p2' (northern boundary of 'nr') and
c   'p1' (southern boundary of 'nr'), in which the '(n+1,nr)' element
c   holds the point value of degree 'n' and parallel band 'nr' in both
c   cases (again for the specified order 'm').
c
c   Note that any global scaling of the computed ALFs enters through
c   the pre-computed (input) sectorial values in 'pmm' and 'pimm'.
c
c   The following arrays should be dimensioned in the calling program
c   as follows:
c
c   - thet1(maxr)
c   - thet2(maxr)
c   - pmm(nmax0+1,maxr+1)
c   - pimm(nmax0+1,maxr)
c   - pint(nmax0+2,maxr)
c   - p1(nmax0+2,maxr)
c   - p2(nmax0+2,maxr)
c
c   where:
c
c   - 'maxr' should be set in the calling program such that 'nrfn' is
c     never larger than 'maxr', and
c   - 'nmax0' should be set in the calling program such that 'nmax' is
c     never larger than 'nmax0'.
c
c   Note that 'nmax' should never be larger than 2700.
c
c   This subroutine was originally called 'pintm7'.
c
c-----------------------------------------------------------------------
c
c   Zonal/Tes'l recursion over increasing degree: Paul (1978, Eq. 20a)
c
c   Paul MK, (1978). Recurrence relations for integrals of associated
c      Legendre functions, Bulletin Geodesique, 52, pp177-190.
c
c-----------------------------------------------------------------------
c
c     ORIGINAL PROGRAM:                           SIMON HOLMES, SEP 2004
c     REMOVED DOUBLE COEFF ARRAYS:                SIMON HOLMES, JUL 2005
c     MODIFIED:                                   SIMON HOLMES, NOV 2005
c
c-----------------------------------------------------------------------
      implicit real*8(a-h,o-z)
      parameter(nm=2700,nm1=nm+1)
      real*8 thet1(*),thet2(*),pmm(nmax0+1,*),pimm(nmax0+1,*)
      real*8 rt(0:2*nm+5),rti(0:2*nm+5),dbl(0:2*nm+5)
      real*8 e(nm1),f(nm1),g(nm1),h(nm1)
      real*8 temp1(nm1),temp2(nm1),temp3(nm1)
      real*8 p1(nmax0+2,*),p2(nmax0+2,*),pint(nmax0+2,*)
c-----------------------------------------------------------------------
      save
      data ix,nmax_old/0,0/
       nmax1 = nmax+1
      nmax2p = 2*nmax+5
c-----------------------------------------------------------------------
      if (nmax.gt.nmax0.or.nmax0.gt.2700) then
        write(6,6002)
 6002   format(///5x,
     &'***      Error in s/r alfiord: nmax > nmax0 or nmax0 > 2700 ***',
     &        //5x,
     &'       ***            Execution Stopped             ***',///)
        stop
      endif  !  nmax,nmax0
c-----------------------------------------------------------------------
      if (m.gt.nmax) then
        write(6,6001)
 6001   format(///5x,'***  Error in s/r alfiord: m > Nmax  ***',
     $          //5x,'***        Execution Stopped         ***',///)
        stop
      endif  !  m
c-----------------------------------------------------------------------
      if (ix.eq.0.or.nmax.gt.nmax_old) then
        ix = 1
        nmax_old = nmax
        do n = 1, nmax2p
           rt(n) = dsqrt(dble(n))
          rti(n) = 1.d0/rt(n)
          dbl(n) = dble(n)
        enddo  !  n
         rt(0) = 0.d0
        rti(0) = 0.d0
        dbl(0) = 0.d0
      endif  !  ix
      m1 = m+1
      m2 = m+2
      m3 = m+3
      do n = m+2, nmax
        temp1(n+1) = rt(n*2+1)*rti(n+m)*rti(n-m)
        temp2(n+1) = rt(n*2+1)*rti(n+m)*rti(n-m)/dbl(n+1)
        temp3(n+1) = rt(n+m-1)*rt(n-m-1)*rti(n*2-3)
        e(n+1) =  temp1(n+1)*rt(n*2-1)
        f(n+1) =  temp1(n+1)*temp3(n+1)
        g(n+1) = -temp2(n+1)*rt(n*2-1)
        h(n+1) =  temp2(n+1)*temp3(n+1)*dbl(n-2)
      enddo  !  n
c-----------------------------------------------------------------------
      do nr = nrst, nrfn
        th1 = thet1(nr)
        th2 = thet2(nr)
         u1 = dsin(th1)
         u2 = dsin(th2)
         t1 = dcos(th1)
         t2 = dcos(th2)
        if (dabs(t1).lt.1.d-10) then
          t1 =  0.d0
          u1 =  1.d0
        elseif (dabs(t2).lt.1.d-10) then
          t2 =  0.d0
          u2 =  1.d0
        elseif (dabs(u1).lt.1.d-10) then
          u1 =  0.d0
          t1 = -1.d0
        elseif (dabs(u2).lt.1.d-10) then
          u2 =  0.d0
          t2 =  1.d0
        endif
        u1sq = u1*u1
        u2sq = u2*u2
        t1sq = t1*t1
        t2sq = t2*t2
          p1(m1,nr) =  pmm(m1,nr+1)
          p2(m1,nr) =  pmm(m1,nr  )
        pint(m1,nr) = pimm(m1,nr  )
        xrt = rt(m1*2+1)
        p1(m2,nr) = xrt*t1*p1(m1,nr)
        p2(m2,nr) = xrt*t2*p2(m1,nr)
        pint(m2,nr) = xrt/dbl(m2)*(u1sq*pmm(m1,nr+1)-u2sq*pmm(m1,nr))
        do n1 = m3, nmax1
          ex = e(n1)
          fx = f(n1)
            p1(n1,nr) = ex*t1*p1(n1-1,nr) - fx*p1(n1-2,nr)
            p2(n1,nr) = ex*t2*p2(n1-1,nr) - fx*p2(n1-2,nr)
          pint(n1,nr) = g(n1)*(u2sq*p2(n1-1,nr) - u1sq*p1(n1-1,nr))+
     &                  h(n1)*pint(n1-2,nr)
        enddo  !  n1
      enddo  !  nr
c-----------------------------------------------------------------------
      return
      end
c-----------------------------------------------------------------------
c
c   ALF SUBROUTINES END HERE.
c
c-----------------------------------------------------------------------
c