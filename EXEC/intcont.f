      program intcont

!=============================================================================
!  CALCULATE ATOMIC CONTACTS BETWEEN TWO INTERFACES  
!  AND GENERATE A 20 X 20 (SYMMETRIC) COMPLEMENTARY MATRIX  
!=============================================================================

      character(80)::pdb,intf1,intf2
      integer::ires1(500),ires2(500)
      character(3)::res1(500),res2(500),atest
      character(1)::ch1(500),ch2(500)
      character(4)::atom(10000)
      integer::ires(10000),iret
      character(3)::res(10000)
      character(1)::ch(10000)
      real::x(10000),y(10000),z(10000)
      character(3)::resic1(1000),resic2(1000)
      integer::icontmat(20,20)
      real::contmatf(20,20)

      call getarg(1,pdb)	! The PDB file contating two chains
      call getarg(2,intf1)	! Interface 1
      call getarg(3,intf2)	! Interface 2

      open (1,file=pdb,status='old')
      open (2,file=intf1,status='old')
      open (3,file=intf2,status='old')

      ic1 = 0
      ic2 = 0

      do i = 1,500
      read(2,34,end=10)ires1(i),res1(i),ch1(i)
      ic1 = ic1 + 1
      enddo

10    continue

      do i = 1,500
      read(3,34,end=20)ires2(i),res2(i),ch2(i)
      ic2 = ic2 + 1
      enddo

20    continue

34    format(i3,1x,a3,1x,a1)

!      print*,ic1,ic2

      ic = 0
      do i = 1,10000
      read(1,32,end=30)atom(i),res(i),ch(i),ires(i),x(i),y(i),z(i)
      ic = ic + 1
      enddo

30    continue

32    format(12x,a4,1x,a3,1x,a1,1x,i3,4x,3f8.3)

!      print*,ic
!==========================================================================================================================
!     CREATE THE COMPLEMENTATION MATRIX (OR CONTACT MAP) : THE MATRIX SHOULD BE SYMMETRIC 
!==========================================================================================================================

!========================================================================================================
!     Test CONVERTION aa strings to indexes here 
!========================================================================================================

      atest = 'PHE'

      call aa2ind(atest,iret)
!      write(*,85)atest,iret
85    format(a3,2x,i5)
      
      distcut = 6.0

!========================================================================================================
!     INITIALIZE (BOTH) CONTACT MATRICES 
!========================================================================================================

       do i = 1,20 
            do j = 1,20
            icontmat(i,j) = 0
            contmatf(i,j) = 0.00
            enddo
       enddo

!========================================================================================================
!================================== CALCULATE INTERFACIAL ATOMIC CONTACTS HERE ===============================================    

      icnt = 0

      do i = 1,ic1
           do j = 1,ic2
!                print*,ires1(i),res1(i),ch1(i),ires2(j),res2(j),ch2(j)
           icon = 0
                do k = 1,ic
                     if (ires1(i)==ires(k) .and. res1(i).eq.res(k) 
     &.and. ch1(i).eq.ch(k))then
                         do l = 1,ic
                           if (ires2(j)==ires(l) .and. 
     &res2(j).eq.res(l) .and. ch2(j).eq.ch(l))then
!============================================================================================================================
!=================================NON-HYDROGEN SIDE-CHAIN ATOMS + CA ========================================================
!============================================================================================================================
                               if (atom(k).ne.' N  '.and.
!     &                             atom(k).ne.' CA '.and.
     &                             atom(k).ne.' C  '.and.
     &                             atom(k).ne.' O  '.and.
     &                             atom(k)(2:2).ne.'H'.and.
     &                             atom(l).ne.' N  '.and.
!     &                             atom(l).ne.' CA '.and.
     &                             atom(l).ne.' C  '.and.
     &                             atom(l).ne.' O  '.and.
     &                             atom(l)(2:2).ne.'H')then
!============================================================================================================================
                           dist = sqrt((x(k)-x(l))**2 + (y(k)-y(l))**2 
     &+ (z(k)-z(l))**2)
                                      if (dist <= distcut)then
                                      icon = icon + 1
                                      endif 
                               endif
                           endif
                         enddo
                     endif                           
                enddo
                if (icon >= 1)then
!                write(31,96)ires1(i),res1(i),ch1(i),ires2(j),res2(j),
!     &ch2(j),icon
                write(23,99)res1(i),res2(j)
                icnt = icnt + 1
                call aa2ind(res1(i),i1)
                call aa2ind(res2(j),j1)
                icontmat(i1,j1) = icontmat(i1,j1) + 1
                icontmat(j1,i1) = icontmat(j1,i1) + 1
                write(31,196)res1(i),res2(j),icnt,i1,j1			! List the contacts
                endif
           enddo
      enddo

      print*,'uncorrected_count: ',icnt

!============================ CORRECT FOR THE DOUBLE COUNTNING OF DIAGONAL ELEMENTS ==============================

      do i = 1,20
         icontmat(i,i) = icontmat(i,i)/2
      enddo

!============================ CORRECT COUNT =====================================================================

      icntc = 0

      do i = 1,20
         do j = 1,20      
              icntc = icntc + icontmat(i,j)						! Contact map (in fraction)
         enddo
      enddo

      print*,'corrected_count: ',icntc

!=================================================================================================================

96    format(i3,2x,a3,2x,a1,5x,i3,2x,a3,2x,a1,5x,i10)
196   format(a3,2x,a3,2x,i5,2x,i5,2x,i5)
99    format(a3,2x,a3)

       itotc = 0

       print*,'----------------------------'

67     format(a3,2x,a3)
167    format(i3,2x,i3,2x,a3,2x,a3,2x,i5)
68     format(a3,2x,a3,2x,i5)
168    format(a3,2x,a3,2x,i5,2x,i5)

!======================================== CHECK SYMMETRY of the integer contact matrix ======================

       itot1 = 0
       Nc1 = 0

       do i = 1,20
            do j = (i+1),20
                 if (icontmat(i,j)==icontmat(j,i))then
                 Nc1 = Nc1 + 1
                 endif
            itot1 = itot1 + 1
            enddo
       enddo

!       print*,Nc1,itot1

       if (Nc1 == itot1)then
       write(*,*) 'INTEGER CONTACT MATRIX IS SYMMETRIC'
       endif


79     format(a3,2x,a3)

!=============================== GENERATE FRACTIONAL CONTACT MATRIX ===================================
!======================= & CHECK SUM of both matrices ==========================================================
       sumch = 0.000
       isum1 = 0

       do i = 1,20
            do j = 1,20
                 if (icntc == 0)then
                 contmatf(i,j) = 0.000
                 else
                 contmatf(i,j) = float(icontmat(i,j))/float(icntc)				! Contact map (in fraction)
                 endif
                 isum1 = isum1 + icontmat(i,j)						! Contact map (in fraction)
!                 write(*,93)i,j,icontmat(i,j),contmatf(i,j)
                 sumch = sumch + contmatf(i,j)
            enddo
       enddo

       write(*,*)'sum_int = ',isum1,'sum_frac = ',sumch

93     format(i3,2x,i3,2x,i10,2x,f10.5)

!======================================== CHECK SYMMETRY of the fractional contact matrix ==================
!===========================================================================================================

       itot2 = 0
       Nc2 = 0

       do i = 1,20
            do j = (i+1),20
                 if (contmatf(i,j)==contmatf(j,i))then
                 Nc2 = Nc2 + 1
                 endif
            itot2 = itot2 + 1
            enddo
       enddo

       if (Nc2 == itot2)then
       write(*,*) 'FRACTIONAL CONTACT MATRIX IS SYMMETRIC'
       endif

!       print*,Nc2,itot2

!============================================================================================================

!       print*,'~~~~~~~~~~~',icontmat(20,5)

       do i = 1,20
       write(*,81)(icontmat(i,j), j = 1,20)
       write(35,81)(icontmat(i,j), j = 1,20)
       enddo

81     format(20(i3,1x))

       do i = 1,20
       write(*,82)(contmatf(i,j), j = 1,20)
       write(36,82)(contmatf(i,j), j = 1,20)
       enddo

82     format(20(f8.5,1x))

      endprogram intcont

      subroutine aa2ind(aainp,indret)
!==========================================================================================================================
!     CREATE THE COMPLEMENTATION MATRIX (OR CONTACT MAP) : THE MATRIX SHOULD BE SYMMETRIC 
!==========================================================================================================================
      character(3)::aainp,aa(20)
      integer::inda(20)
      
      aa = (/'GLY','ALA','VAL','LEU','ILE','PHE','TYR','TRP','SER',
     &'THR','CYS','MET','ASP','GLU','ASN','GLN','LYS','ARG','PRO',
     &'HIS'/)
      
      do i = 1,20
      inda(i) = i
!      write(*,*)aa(i),'     ',inda(i)
            if (aainp.eq.aa(i))then
            indret = i
            endif
      enddo

      return

!========================================================================================================
      end

