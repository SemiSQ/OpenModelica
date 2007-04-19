   
 
      SUBROUTINE NELMEAD(P,STEP,NOP,FUNC,MAX,IPRINT,STOPCR,NLOOP,IQUAD,
     1    SIMP,VAR,FUNCTN,IFAULT)
C
C     A PROGRAM FOR FUNCTION MINIMIZATION USING THE SIMPLEX METHOD.
C
C     FOR DETAILS, SEE NELDER & MEAD, THE COMPUTER JOURNAL, JANUARY 1965
C
C     PROGRAMMED BY D.E.SHAW,
C     CSIRO, DIVISION OF MATHEMATICS & STATISTICS
C     P.O. BOX 218, LINDFIELD, N.S.W. 2070
C
C     WITH AMENDMENTS BY R.W.M.WEDDERBURN
C     ROTHAMSTED EXPERIMENTAL STATION
C     HARPENDEN, HERTFORDSHIRE, ENGLAND
C
C     Further amended by Alan Miller
C     CSIRO Division of Mathematics & Statistics
C     Private Bag 10, CLAYTON, VIC. 3168
C
C     ARGUMENTS:-
C     P()     = INPUT, STARTING VALUES OF PARAMETERS
C               OUTPUT, FINAL VALUES OF PARAMETERS
C     STEP()  = INPUT, INITIAL STEP SIZES
C     NOP     = INPUT, NO. OF PARAMETERS, INCL. ANY TO BE HELD FIXED
C     FUNC    = OUTPUT, THE FUNCTION VALUE CORRESPONDING TO THE FINAL
C                 PARAMETER VALUES.
C     MAX     = INPUT, THE MAXIMUM NO. OF FUNCTION EVALUATIONS ALLOWED.
C               Say, 20 times the number of parameters, NOP.
C     IPRINT  = INPUT, PRINT CONTROL PARAMETER
C                 < 0 NO PRINTING
C                 = 0 PRINTING OF PARAMETER VALUES AND THE FUNCTION
C                     VALUE AFTER INITIAL EVIDENCE OF CONVERGENCE.
C                 > 0 AS FOR IPRINT = 0 PLUS PROGRESS REPORTS AFTER
C                     EVERY IPRINT EVALUATIONS, PLUS PRINTING FOR THE
C                     INITIAL SIMPLEX.
C     STOPCR  = INPUT, STOPPING CRITERION.
C               The criterion is applied to the standard deviation of
C               the values of FUNC at the points of the simplex.
C     NLOOP   = INPUT, THE STOPPING RULE IS APPLIED AFTER EVERY NLOOP
C               FUNCTION EVALUATIONS.   Normally NLOOP should be slightly
C               greater than NOP, say NLOOP = 2*NOP.
C     IQUAD   = INPUT, = 1 IF FITTING OF A QUADRATIC SURFACE IS REQUIRED
C                      = 0 IF NOT
C               N.B. The fitting of a quadratic surface is strongly
C               recommended, provided that the fitted function is
C               continuous in the vicinity of the minimum.   It is often
C               a good indicator of whether a premature termination of
C               the search has occurred.
C     SIMP    = INPUT, CRITERION FOR EXPANDING THE SIMPLEX TO OVERCOME
C               ROUNDING ERRORS BEFORE FITTING THE QUADRATIC SURFACE.
C               The simplex is expanded so that the function values at
C               the points of the simplex exceed those at the supposed
C               minimum by at least an amount SIMP.
C     VAR()   = OUTPUT, CONTAINS THE DIAGONAL ELEMENTS OF THE INVERSE OF
C               THE INFORMATION MATRIX.
C     FUNCTN  = INPUT, NAME OF THE USER'S SUBROUTINE - ARGUMENTS 
C		(NOP,P,FUNC) WHICH RETURNS THE FUNCTION VALUE FOR A GIVEN
C               SET OF PARAMETER VALUES IN ARRAY P.
C****     FUNCTN MUST BE DECLARED EXTERNAL IN THE CALLING PROGRAM.
C     IFAULT  = OUTPUT, = 0 FOR SUCCESSFUL TERMINATION
C                 = 1 IF MAXIMUM NO. OF FUNCTION EVALUATIONS EXCEEDED
C                 = 2 IF INFORMATION MATRIX IS NOT +VE SEMI-DEFINITE
C                 = 3 IF NOP < 1
C                 = 4 IF NLOOP < 1
C
C     N.B. P, STEP AND VAR (IF IQUAD = 1) MUST HAVE DIMENSION AT LEAST NOP
C          IN THE CALLING PROGRAM.
C     THE DIMENSIONS BELOW ARE FOR A MAXIMUM OF 20 PARAMETERS.
C
C     LATEST REVISION - 6 April 1985
C
C*****************************************************************************
C
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      DIMENSION P(NOP),STEP(NOP),VAR(NOP)
      DIMENSION G(21,20),H(21),PBAR(20),PSTAR(20),PSTST(20),AVAL(20),
     1 BMAT(210),PMIN(20),VC(210),TEMP(20)
      EXTERNAL FUNCTN
C
C     A = REFLECTION COEFFICIENT, B = CONTRACTION COEFFICIENT, AND
C     C = EXPANSION COEFFICIENT.
C
      DATA A,B,C/1.0D0, 0.5D0, 2.0D0/
C
C     SET LOUT = LOGICAL UNIT NO. FOR OUTPUT
C
      DATA LOUT/6/
C
C     IF PROGRESS REPORTS HAVE BEEN REQUESTED, PRINT HEADING
C
      IF(IPRINT.GT.0) WRITE(LOUT,1000) IPRINT
 1000 FORMAT(' Progress Report every',I4,' function evaluations'/,
     1 ' EVAL.   FUNC.VALUE.',10X,'PARAMETER VALUES')
C
C     CHECK INPUT ARGUMENTS
C
      IFAULT = 0
      IF(NOP.LE.0) IFAULT = 3
      IF(NLOOP.LE.0) IFAULT = 4
      IF(IFAULT.NE.0) RETURN
C
C     SET NAP = NO. OF PARAMETERS TO BE VARIED, I.E. WITH STEP.NE.0
C
      NAP = 0
      NEVAL = 0
      LOOP = 0
      IFLAG = 0
      DO 10 I = 1,NOP
        IF(STEP(I).NE.0.D0) NAP = NAP+1
   10 CONTINUE
C
C     IF NAP = 0 EVALUATE FUNCTION AT THE STARTING POINT AND RETURN
C
      IF(NAP.GT.0) GO TO 30
      CALL FUNCTN(NOP, P, FUNC)
      RETURN
C
C     SET UP THE INITIAL SIMPLEX
C
   30 DO 40 I = 1,NOP
   40 G(1,I) = P(I)
      IROW = 2
      DO 60 I = 1,NOP
        IF(STEP(I).EQ.0.D0) GO TO 60
        DO 50 J = 1,NOP
   50   G(IROW,J) = P(J)
        G(IROW,I) = P(I)+STEP(I)
        IROW = IROW+1
   60 CONTINUE
C
      NP1 = NAP+1
      DO 90 I = 1,NP1
        DO 70 J = 1,NOP
   70   P(J) = G(I,J)
        CALL FUNCTN(NOP, P, H(I))
        NEVAL = NEVAL+1
        IF(IPRINT.LE.0) GO TO 90
        WRITE(LOUT,1010) NEVAL,H(I),(P(J),J=1,NOP)
 1010   FORMAT(/1X, I4, 2X, G12.5, 2X, 5G11.4, 3(/21X, 5G11.4))
   90 CONTINUE
C
C     START OF MAIN CYCLE.
C
C     FIND MAX. & MIN. VALUES FOR CURRENT SIMPLEX (HMAX & HMIN).
C
  100 LOOP = LOOP+1
      IMAX = 1
      IMIN = 1
      HMAX = H(1)
      HMIN = H(1)
      DO 120 I = 2,NP1
        IF(H(I).LE.HMAX) GO TO 110
        IMAX = I
        HMAX = H(I)
        GO TO 120
  110   IF(H(I).GE.HMIN) GO TO 120
        IMIN = I
        HMIN = H(I)
  120 CONTINUE
C
C     FIND THE CENTROID OF THE VERTICES OTHER THAN P(IMAX)
C
      DO 130 I = 1,NOP
  130 PBAR(I) = 0.D0
      DO 150 I = 1,NP1
        IF(I.EQ.IMAX) GO TO 150
        DO 140 J = 1,NOP
  140   PBAR(J) = PBAR(J)+G(I,J)
  150 CONTINUE
      DO 160 J = 1,NOP
  160 PBAR(J) = PBAR(J)/FLOAT(NAP)
C
C     REFLECT MAXIMUM THROUGH PBAR TO PSTAR,
C     HSTAR = FUNCTION VALUE AT PSTAR.
C
      DO 170 I = 1,NOP
  170 PSTAR(I) = A*(PBAR(I)-G(IMAX,I))+PBAR(I)
      CALL FUNCTN(NOP, PSTAR, HSTAR)
      NEVAL = NEVAL+1
      IF(IPRINT.LE.0) GO TO 180
      IF(MOD(NEVAL,IPRINT).EQ.0) WRITE(LOUT,1010) NEVAL,HSTAR,
     1 (PSTAR(J),J=1,NOP)
C
C     IF HSTAR < HMIN, REFLECT PBAR THROUGH PSTAR,
C     HSTST = FUNCTION VALUE AT PSTST.
C
  180 IF(HSTAR.GE.HMIN) GO TO 220
      DO 190 I = 1,NOP
  190 PSTST(I) = C*(PSTAR(I)-PBAR(I))+PBAR(I)
      CALL FUNCTN(NOP, PSTST, HSTST)
      NEVAL = NEVAL+1
      IF(IPRINT.LE.0) GO TO 200
      IF(MOD(NEVAL,IPRINT).EQ.0) WRITE(LOUT,1010) NEVAL,HSTST,
     1 (PSTST(J),J=1,NOP)
C
C     IF HSTST < HMIN REPLACE CURRENT MAXIMUM POINT BY PSTST AND
C     HMAX BY HSTST, THEN TEST FOR CONVERGENCE.
C
  200 IF(HSTST.GE.HMIN) GO TO 320
      DO 210 I = 1,NOP
        IF(STEP(I).NE.0.D0) G(IMAX,I) = PSTST(I)
  210 CONTINUE
      H(IMAX) = HSTST
      GO TO 340
C
C     HSTAR IS NOT < HMIN.
C     TEST WHETHER IT IS < FUNCTION VALUE AT SOME POINT OTHER THAN
C     P(IMAX).   IF IT IS REPLACE P(IMAX) BY PSTAR & HMAX BY HSTAR.
C
  220 DO 230 I = 1,NP1
        IF(I.EQ.IMAX) GO TO 230
        IF(HSTAR.LT.H(I)) GO TO 320
  230 CONTINUE
C
C     HSTAR > ALL FUNCTION VALUES EXCEPT POSSIBLY HMAX.
C     IF HSTAR <= HMAX, REPLACE P(IMAX) BY PSTAR & HMAX BY HSTAR.
C
      IF(HSTAR.GT.HMAX) GO TO 260
      DO 250 I = 1,NOP
        IF(STEP(I).NE.0.D0) G(IMAX,I) = PSTAR(I)
  250 CONTINUE
      HMAX = HSTAR
      H(IMAX) = HSTAR
C
C     CONTRACTED STEP TO THE POINT PSTST,
C     HSTST = FUNCTION VALUE AT PSTST.
C
  260 DO 270 I = 1,NOP
  270 PSTST(I) = B*G(IMAX,I)+(1.0-B)*PBAR(I)
      CALL FUNCTN(NOP, PSTST, HSTST)
      NEVAL = NEVAL+1
      IF(IPRINT.LE.0) GO TO 280
      IF(MOD(NEVAL,IPRINT).EQ.0) WRITE(LOUT,1010) NEVAL,HSTST,
     1 (PSTST(J),J=1,NOP)
C
C     IF HSTST < HMAX REPLACE P(IMAX) BY PSTST & HMAX BY HSTST.
C
  280 IF(HSTST.GT.HMAX) GO TO 300
      DO 290 I = 1,NOP
        IF(STEP(I).NE.0.D0) G(IMAX,I) = PSTST(I)
  290 CONTINUE
      H(IMAX) = HSTST
      GO TO 340
C
C     HSTST > HMAX.
C     SHRINK THE SIMPLEX BY REPLACING EACH POINT, OTHER THAN THE CURRENT
C     MINIMUM, BY A POINT MID-WAY BETWEEN ITS CURRENT POSITION AND THE
C     MINIMUM.
C
  300 DO 315 I = 1,NP1
        IF(I.EQ.IMIN) GO TO 315
        DO 310 J = 1,NOP
          IF(STEP(J).NE.0.D0) G(I,J) = (G(I,J)+G(IMIN,J))*0.5
  310     P(J) = G(I,J)
        CALL FUNCTN(NOP, P, H(I))
        NEVAL = NEVAL+1
        IF(IPRINT.LE.0) GO TO 315
        IF(MOD(NEVAL,IPRINT).EQ.0) WRITE(LOUT,1010) NEVAL,H(I),
     1       (P(J),J=1,NOP)
  315 CONTINUE
      GO TO 340
C
C     REPLACE MAXIMUM POINT BY PSTAR & H(IMAX) BY HSTAR.
C
  320 DO 330 I = 1,NOP
        IF(STEP(I).NE.0.D0) G(IMAX,I) = PSTAR(I)
  330 CONTINUE
      H(IMAX) = HSTAR
C
C     IF LOOP = NLOOP TEST FOR CONVERGENCE, OTHERWISE REPEAT MAIN CYCLE.
C
  340 IF(LOOP.LT.NLOOP) GO TO 100
C
C     CALCULATE MEAN & STANDARD DEVIATION OF FUNCTION VALUES FOR THE
C     CURRENT SIMPLEX.
C
      HSTD = 0.D0
      HMEAN = 0.D0
      DO 350 I = 1,NP1
  350 HMEAN = HMEAN+H(I)
      HMEAN = HMEAN/FLOAT(NP1)
      DO 360 I = 1,NP1
  360 HSTD = HSTD+(H(I)-HMEAN)**2
      HSTD = SQRT(HSTD/FLOAT(NP1))
C
C     IF THE RMS > STOPCR, SET IFLAG & LOOP TO ZERO AND GO TO THE
C     START OF THE MAIN CYCLE AGAIN.
C
      IF(HSTD.LE.STOPCR.OR.NEVAL.GT.MAX) GO TO 410
      IFLAG = 0
      LOOP = 0
      GO TO 100
C
C     FIND THE CENTROID OF THE CURRENT SIMPLEX AND THE FUNCTION VALUE THERE.
C
  410 DO 380 I = 1,NOP
        IF(STEP(I).EQ.0.D0) GO TO 380
        P(I) = 0.D0
        DO 370 J = 1,NP1
  370   P(I) = P(I)+G(J,I)
        P(I) = P(I)/FLOAT(NP1)
  380 CONTINUE
      CALL FUNCTN(NOP, P, FUNC)
      NEVAL = NEVAL+1
      IF(IPRINT.LE.0) GO TO 390
      IF(MOD(NEVAL,IPRINT).EQ.0) WRITE(LOUT,1010) NEVAL,FUNC,
     1 (P(J),J=1,NOP)
C
C     TEST WHETHER THE NO. OF FUNCTION VALUES ALLOWED, MAX, HAS BEEN
C     OVERRUN; IF SO, EXIT WITH IFAULT = 1.
C
  390 IF(NEVAL.LE.MAX) GO TO 420
      IFAULT = 1
      IF(IPRINT.LT.0) RETURN
      WRITE(LOUT,1020) MAX
 1020 FORMAT(' No. of function evaluations > ',I5)
      WRITE(LOUT,1030) HSTD
 1030 FORMAT(' RMS of function values of last simplex =',G14.6)
      WRITE(LOUT,1040)(P(I),I=1,NOP)
 1040 FORMAT(' Centroid of last simplex =',4(/1X,6G13.5))
      WRITE(LOUT,1050) FUNC
 1050 FORMAT(' Function value at centroid =',G14.6)
      RETURN
C
C     CONVERGENCE CRITERION SATISFIED.
C     IF IFLAG = 0, SET IFLAG & SAVE HMEAN.
C     IF IFLAG = 1 & CHANGE IN HMEAN <= STOPCR THEN SEARCH IS COMPLETE.
C
  420 IF(IPRINT.LT.0) GO TO 430
      WRITE(LOUT,1060)
 1060 FORMAT(/' EVIDENCE OF CONVERGENCE')
      WRITE(LOUT,1040)(P(I),I=1,NOP)
      WRITE(LOUT,1050) FUNC
  430 IF(IFLAG.GT.0) GO TO 450
      IFLAG = 1
  440 SAVEMN = HMEAN
      LOOP = 0
      GO TO 100
  450 IF(ABS(SAVEMN-HMEAN) .GE. STOPCR) GO TO 440
      IF(IPRINT.LT.0) GO TO 460
      WRITE(LOUT,1070) NEVAL
 1070 FORMAT(//' Minimum found after',I5,' function evaluations')
      WRITE(LOUT,1080)(P(I),I=1,NOP)
 1080 FORMAT(' Minimum at',4(/1X,6G13.6))
      WRITE(LOUT,1090) FUNC
 1090 FORMAT(' Function value at minimum =',G14.6)
  460 IF(IQUAD.LE.0) RETURN
C
C------------------------------------------------------------------
C
C     QUADRATIC SURFACE FITTING
C
      IF(IPRINT.GE.0) WRITE(LOUT,1110)
 1110 FORMAT(/' Fitting quadratic surface about supposed minimum'/)
C
C     EXPAND THE FINAL SIMPLEX, IF NECESSARY, TO OVERCOME ROUNDING
C     ERRORS.
C
      HMIN = FUNC
      NMORE = 0
      DO 490 I = 1,NP1
  470   TEST = ABS(H(I)-FUNC)
        IF(TEST.GE.SIMP) GO TO 490
        DO 480 J = 1,NOP
          IF(STEP(J).NE.0.D0) G(I,J) = (G(I,J)-P(J))+G(I,J)
  480     PSTST(J) = G(I,J)
        CALL FUNCTN(NOP, PSTST, H(I))
        NMORE = NMORE + 1
        NEVAL = NEVAL+1
        IF(H(I) .GE. HMIN) GO TO 470
        HMIN = H(I)
        IF(IPRINT.GE.0) WRITE(LOUT, 1010) NEVAL, HMIN,
     +               (PSTST(J),J=1,NOP)
        GO TO 470
  490 CONTINUE
C
C     FUNCTION VALUES ARE CALCULATED AT AN ADDITIONAL NAP POINTS.
C
      DO 510 I = 1,NAP
        I1 = I+1
        DO 500 J = 1,NOP
  500   PSTAR(J) = (G(1,J)+G(I1,J))*0.5
        CALL FUNCTN(NOP, PSTAR, AVAL(I))
        NMORE = NMORE + 1
        NEVAL = NEVAL+1
  510 CONTINUE
C
C     THE MATRIX OF ESTIMATED SECOND DERIVATIVES IS CALCULATED AND ITS
C     LOWER TRIANGLE STORED IN BMAT.
C
      A0 = H(1)
      DO 540 I = 1,NAP
        I1 = I-1
        I2 = I+1
        IF(I1.LT.1) GO TO 540
        DO 530 J = 1,I1
          J1 = J+1
          DO 520 K = 1,NOP
  520     PSTST(K) = (G(I2,K)+G(J1,K))*0.5
          CALL FUNCTN(NOP, PSTST, HSTST)
          NMORE = NMORE + 1
          NEVAL = NEVAL+1
          L = I*(I-1)/2+J
          BMAT(L) = 2.0*(HSTST+A0-AVAL(I)-AVAL(J))
  530   CONTINUE
  540 CONTINUE
      L = 0
      DO 550 I = 1,NAP
        I1 = I+1
        L = L+I
        BMAT(L) = 2.0*(H(I1)+A0-2.0*AVAL(I))
  550 CONTINUE
C
C     THE VECTOR OF ESTIMATED FIRST DERIVATIVES IS CALCULATED AND
C     STORED IN AVAL.
C
      DO 560 I = 1,NAP
        I1 = I+1
  560   AVAL(I) = 2.0*AVAL(I)-(H(I1)+3.0*A0)*0.5
C
C     THE MATRIX Q OF NELDER & MEAD IS CALCULATED AND STORED IN G.
C
      DO 570 I = 1,NOP
  570 PMIN(I) = G(1,I)
      DO 580 I = 1,NAP
        I1 = I+1
        DO 580 J = 1,NOP
          G(I1,J) = G(I1,J)-G(1,J)
  580 CONTINUE
      DO 590 I = 1,NAP
        I1 = I+1
        DO 590 J = 1,NOP
          G(I,J) = G(I1,J)
  590 CONTINUE
C
C     INVERT BMAT
C
      CALL SYMINV(BMAT, NAP, BMAT, TEMP, NULLTY, IFAULT, RMAX)
      IF(IFAULT.NE.0) GO TO 600
      IRANK = NAP-NULLTY
      GO TO 610
  600 IF(IPRINT.GE.0) WRITE(LOUT,1120)
 1120 FORMAT(/' MATRIX OF ESTIMATED SECOND DERIVATIVES NOT +VE DEFN.'/
     1 ' MINIMUM PROBABLY NOT FOUND'/)
      IFAULT = 2
      IF(NEVAL .GT. MAX) RETURN
      WRITE(LOUT, 1130)
 1130 FORMAT(/10X, 'Search restarting'/)
      DO 605 I = 1,NOP
  605 STEP(I) = 0.5 * STEP(I)
      GO TO 30
C
C     BMAT*A/2 IS CALCULATED AND STORED IN H.
C
  610 DO 650 I = 1,NAP
        H(I) = 0.D0
        DO 640 J = 1,NAP
          IF(J.GT.I) GO TO 620
          L = I*(I-1)/2+J
          GO TO 630
  620     L = J*(J-1)/2+I
  630     H(I) = H(I)+BMAT(L)*AVAL(J)
  640   CONTINUE
  650 CONTINUE
C
C     FIND THE POSITION, PMIN, & VALUE, YMIN, OF THE MINIMUM OF THE
C     QUADRATIC.
C
      YMIN = 0.D0
      DO 660 I = 1,NAP
  660 YMIN = YMIN+H(I)*AVAL(I)
      YMIN = A0-YMIN
      DO 670 I = 1,NOP
        PSTST(I) = 0.D0
        DO 670 J = 1,NAP
  670   PSTST(I) = PSTST(I)+H(J)*G(J,I)
      DO 680 I = 1,NOP
  680 PMIN(I) = PMIN(I)-PSTST(I)
      IF(IPRINT.LT.0) GO TO 690
      WRITE(LOUT,1140) YMIN,(PMIN(I),I=1,NOP)
 1140 FORMAT(' Minimum of quadratic surface =',G14.6,' at',
     1 4(/1X,6G13.5))
      WRITE(LOUT,1150)
 1150 FORMAT(' IF THIS DIFFERS BY MUCH FROM THE MINIMUM ESTIMATED',
     1 1X,'FROM THE MINIMIZATION,'/
     2 ' THE MINIMUM MAY BE FALSE &/OR THE INFORMATION MATRIX MAY BE',
     3 1X,'INACCURATE'/)
C
C     Q*BMAT*Q'/2 IS CALCULATED & ITS LOWER TRIANGLE STORED IN VC
C
  690 DO 760 I = 1,NOP
        DO 730 J = 1,NAP
          H(J) = 0.D0
          DO 720 K = 1,NAP
            IF(K.GT.J) GO TO 700
            L = J*(J-1)/2+K
            GO TO 710
  700       L = K*(K-1)/2+J
  710       H(J) = H(J)+BMAT(L)*G(K,I)*0.5
  720     CONTINUE
  730   CONTINUE
        DO 750 J = I,NOP
          L = J*(J-1)/2+I
          VC(L) = 0.D0
          DO 740 K = 1,NAP
  740     VC(L) = VC(L)+H(K)*G(K,J)
  750   CONTINUE
  760 CONTINUE
C
C     THE DIAGONAL ELEMENTS OF VC ARE COPIED INTO VAR.
C
      J = 0
      DO 770 I = 1,NOP
        J = J+I
  770 VAR(I) = VC(J)
      IF(IPRINT.LT.0) RETURN
      WRITE(LOUT,1160) IRANK
 1160 FORMAT(' Rank of information matrix =',I3/
     1 ' Inverse of information matrix:-')
      IJK = 1
      GO TO 880
C
  790 CONTINUE
      WRITE(LOUT,1170)
 1170 FORMAT(/' If the function minimized was -LOG(LIKELIHOOD),'/
     1 ' this is the covariance matrix of the parameters.'/
     2 ' If the function was a sum of squares of residuals,'/
     3 ' this matrix must be multiplied by twice the estimated',
     4 1X, 'residual variance'/' to obtain the covariance matrix.'/)
      CALL SYMINV(VC, NAP, BMAT, TEMP, NULLTY, IFAULT, RMAX)
C
C     BMAT NOW CONTAINS THE INFORMATION MATRIX
C
      WRITE(LOUT,1190)
 1190 FORMAT(' INFORMATION MATRIX:-'/)
      IJK = 3
      GO TO 880
C
  800 IJK = 2
      II = 0
      IJ = 0
      DO 840 I = 1,NOP
        II = II+I
        IF(VC(II).GT.0.D0) THEN
          VC(II) = 1.0/SQRT(VC(II))
        ELSE
          VC(II) = 0.D0
        END IF
        JJ = 0
        DO 830 J = 1,I-1
          JJ = JJ+J
          IJ = IJ+1
          VC(IJ) = VC(IJ)*VC(II)*VC(JJ)
  830   CONTINUE
        IJ = IJ+1
  840 CONTINUE
C
      WRITE(LOUT,1200)
 1200 FORMAT(//' CORRELATION MATRIX:-')
      II = 0
      DO 850 I = 1,NOP
        II = II+I
        IF(VC(II).NE.0.D0) VC(II) = 1.D0
  850 CONTINUE
      GO TO 880
C
C     Exit, on successful termination.
C
  860 WRITE(LOUT,1210) NMORE
 1210 FORMAT(/' A further',I4,' function evaluations have been used'/)
      RETURN
C
  880 L = 1
  890 IF(L.GT.NOP) GO TO (790, 860, 800),IJK
      II = L*(L-1)/2
      DO 910 I = L,NOP
        I1 = II+L
        II = II+I
        I2 = MIN0(II,I1+5)
        IF(IJK.EQ.3) GO TO 900
        WRITE(LOUT,1230)(VC(J),J=I1,I2)
        GO TO 910
  900   WRITE(LOUT,1230)(BMAT(J),J=I1,I2)
  910 CONTINUE
 1230 FORMAT(1X,6G13.5)
      WRITE(LOUT,1240)
 1240 FORMAT(/)
      L = L+6
      GO TO 890
      END




      SUBROUTINE SYMINV(A, N, C, W, NULLTY, IFAULT, RMAX)
C
C     ALGORITHM AS7, APPLIED STATISTICS, VOL.17, 1968.
C
C     ARGUMENTS:-
C     A()    = INPUT, THE SYMMETRIC MATRIX TO BE INVERTED, STORED IN
C                LOWER TRIANGULAR FORM
C     N      = INPUT, ORDER OF THE MATRIX
C     C()    = OUTPUT, THE INVERSE OF A (A GENERALIZED INVERSE IF C IS
C                SINGULAR), ALSO STORED IN LOWER TRIANGULAR.
C                C AND A MAY OCCUPY THE SAME LOCATIONS.
C     W()    = WORKSPACE, DIMENSION AT LEAST N.
C     NULLTY = OUTPUT, THE RANK DEFICIENCY OF A.
C     IFAULT = OUTPUT, ERROR INDICATOR
C                 = 1 IF N < 1
C                 = 2 IF A IS NOT +VE SEMI-DEFINITE
C                 = 0 OTHERWISE
C     RMAX   = OUTPUT, APPROXIMATE BOUND ON THE ACCURACY OF THE DIAGONAL
C                ELEMENTS OF C.  E.G. IF RMAX = 1.E-04 THEN THE DIAGONAL
C                ELEMENTS OF C WILL BE ACCURATE TO ABOUT 4 DEC. DIGITS.
C
C     LATEST REVISION - 1 April 1985
C
C***************************************************************************
C
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      DIMENSION A(1),C(1),W(N)
      NROW = N
      IFAULT = 1
      IF(NROW.LE.0) GO TO 100
      IFAULT = 0
C
C     CHOLESKY FACTORIZATION OF A, RESULT IN C
C
      CALL CHOLA(A,NROW,C,NULLTY,IFAULT,RMAX,W)
      IF(IFAULT.NE.0) GO TO 100
C
C     INVERT C & FORM THE PRODUCT (CINV)'*CINV, WHERE CINV IS THE INVERSE
C     OF C, ROW BY ROW STARTING WITH THE LAST ROW.
C     IROW = THE ROW NUMBER, NDIAG = LOCATION OF LAST ELEMENT IN THE ROW.
C
      NN = NROW*(NROW+1)/2
      IROW = NROW
      NDIAG = NN
   10 IF(C(NDIAG).EQ.0.D0) GO TO 60
      L = NDIAG
      DO 20 I = IROW,NROW
      W(I) = C(L)
      L = L+I
   20 CONTINUE
      ICOL = NROW
      JCOL = NN
      MDIAG = NN
   30 L = JCOL
      X = 0.D0
      IF(ICOL.EQ.IROW) X = 1.D0/W(IROW)
      K = NROW
   40 IF(K.EQ.IROW) GO TO 50
      X = X-W(K)*C(L)
      K = K-1
      L = L-1
      IF(L.GT.MDIAG) L = L-K+1
      GO TO 40
   50 C(L) = X/W(IROW)
      IF(ICOL.EQ.IROW) GO TO 80
      MDIAG = MDIAG-ICOL
      ICOL = ICOL-1
      JCOL = JCOL-1
      GO TO 30
   60 L = NDIAG
      DO 70 J = IROW,NROW
      C(L) = 0.D0
      L = L+J
   70 CONTINUE
   80 NDIAG = NDIAG-IROW
      IROW = IROW-1
      IF(IROW.NE.0) GO TO 10
  100 RETURN
      END





      SUBROUTINE CHOLA(A, N, U, NULLTY, IFAULT, RMAX, R)
C
C     ALGORITHM AS6, APPLIED STATISTICS, VOL.17, 1968, WITH
C     MODIFICATIONS BY A.J.MILLER
C
C     ARGUMENTS:-
C     A()    = INPUT, A +VE DEFINITE MATRIX STORED IN LOWER-TRIANGULAR
C                FORM.
C     N      = INPUT, THE ORDER OF A
C     U()    = OUTPUT, A LOWER TRIANGULAR MATRIX SUCH THAT U*U' = A.
C                A & U MAY OCCUPY THE SAME LOCATIONS.
C     NULLTY = OUTPUT, THE RANK DEFICIENCY OF A.
C     IFAULT = OUTPUT, ERROR INDICATOR
C                 = 1 IF N < 1
C                 = 2 IF A IS NOT +VE SEMI-DEFINITE
C                 = 0 OTHERWISE
C     RMAX   = OUTPUT, AN ESTIMATE OF THE RELATIVE ACCURACY OF THE
C                DIAGONAL ELEMENTS OF U.
C     R()    = OUTPUT, ARRAY CONTAINING BOUNDS ON THE RELATIVE ACCURACY
C                OF EACH DIAGONAL ELEMENT OF U.
C
C     LATEST REVISION - 1 April 1985
C
C***************************************************************************
C
      IMPLICIT DOUBLE PRECISION (A-H, O-Z)
      DIMENSION A(1),U(1),R(N)
C
      ETA=.5D0
 110  ETA=ETA/2.D0
      IF (1.D0 + ETA .GT. 1.D0) GOTO 110
      ETA=ETA*2.D0
      IFAULT = 1
      IF(N.LE.0) GO TO 100
      IFAULT = 2
      NULLTY = 0
      RMAX = ETA
      R(1) = ETA
      J = 1
      K = 0
C
C     FACTORIZE COLUMN BY COLUMN, ICOL = COLUMN NO.
C
      DO 80 ICOL = 1,N
      L = 0
C
C     IROW = ROW NUMBER WITHIN COLUMN ICOL
C
      DO 40 IROW = 1,ICOL
      K = K+1
      W = A(K)
      IF(IROW.EQ.ICOL) RSQ = (W*ETA)**2
      M = J
      DO 10 I = 1,IROW
      L = L+1
      IF(I.EQ.IROW) GO TO 20
      W = W-U(L)*U(M)
      IF(IROW.EQ.ICOL) RSQ = RSQ+(U(L)**2*R(I))**2
      M = M+1
   10 CONTINUE
   20 IF(IROW.EQ.ICOL) GO TO 50
      IF(U(L).EQ.0.D0) GO TO 30
      U(K) = W/U(L)
      GO TO 40
   30 U(K) = 0.D0
      IF(ABS(W).GT.ABS(RMAX*A(K))) GO TO 100
   40 CONTINUE
C
C     END OF ROW, ESTIMATE RELATIVE ACCURACY OF DIAGONAL ELEMENT.
C
   50 RSQ = SQRT(RSQ)
      IF(ABS(W).LE.5.*RSQ) GO TO 60
      IF(W.LT.0.D0) GO TO 100
      U(K) = SQRT(W)
      R(I) = RSQ/W
      IF(R(I).GT.RMAX) RMAX = R(I)
      GO TO 70
   60 U(K) = 0.D0
      NULLTY = NULLTY+1
   70 J = J+ICOL
   80 CONTINUE
      IFAULT = 0.D0
  100 RETURN
      END
