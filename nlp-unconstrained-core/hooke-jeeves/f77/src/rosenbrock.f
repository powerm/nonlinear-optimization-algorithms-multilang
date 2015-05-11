C =============================================================================
C NLP-UNCONSTRAINED-CORE/HOOKE-JEEVES/F77/ROSENBROCK.F
C =============================================================================
C NONLINEAR OPTIMIZATION ALGORITHMS MULTILANG. VERSION 0.1
C =============================================================================
C NONLINEAR PROGRAMMING ALGORITHMS AS THE (UN-)CONSTRAINED MINIMIZATION
C PROBLEMS WITH THE FOCUS ON THEIR NUMERICAL EXPRESSION USING VARIOUS
C PROGRAMMING LANGUAGES.
C
C THIS IS THE HOOKE AND JEEVES NONLINEAR UNCONSTRAINED MINIMIZATION ALGORITHM.
C =============================================================================
C COPYRIGHT (C) 2015 RADISLAV (RADIC) GOLUBTSOV

C     ROSENBROCK'S CLASSIC PARABOLIC VALLEY ('BANANA') FUNCTION.
      FUNCTION F(X, N)
          IMPLICIT NONE

C         MAX NUMBER OF VARIABLES.
          INTEGER    VARS
          PARAMETER (VARS = 250)

          DOUBLE PRECISION F
          DOUBLE PRECISION X(VARS)

          INTEGER N

C         GLOBAL VARIABLES.
          INTEGER FUNEVA
          COMMON  FUNEVA

          DOUBLE PRECISION A
          DOUBLE PRECISION B
          DOUBLE PRECISION C

          FUNEVA = FUNEVA + 1

          A = X(1)
          B = X(2)

          C = 100.0 * (B - (A * A)) * (B - (A * A))

          F = C + ((1.0 - A) * (1.0 - A))

          RETURN
      END

C     GIVEN A POINT, LOOK FOR A BETTER ONE NEARBY, ONE COORD AT A TIME.
      FUNCTION BEST_N(DELTA, POINT, PREVBE, NVARS)
          IMPLICIT NONE

C         MAX NUMBER OF VARIABLES.
          INTEGER    VARS
          PARAMETER (VARS = 250)

          DOUBLE PRECISION BEST_N
          DOUBLE PRECISION DELTA(VARS)
          DOUBLE PRECISION POINT(VARS)
          DOUBLE PRECISION PREVBE

          INTEGER NVARS

          DOUBLE PRECISION MINF
          DOUBLE PRECISION Z(VARS)
          DOUBLE PRECISION FTMP

          INTEGER I

          DOUBLE PRECISION F

          MINF = PREVBE

          DO 10 I = 1, NVARS
              Z(I) = POINT(I)
10        CONTINUE

          DO 20 I = 1, NVARS
              Z(I) = POINT(I) + DELTA(I)

              FTMP = F(Z, NVARS)

              IF (FTMP .LT. MINF) THEN
                  MINF = FTMP
              ELSE
                  DELTA(I) = 0.0 - DELTA(I)
                  Z(I)     = POINT(I) + DELTA(I)

                  FTMP = F(Z, NVARS)

                  IF (FTMP .LT. MINF) THEN
                      MINF = FTMP
                  ELSE
                      Z(I) = POINT(I)
                  END IF
              END IF
20        CONTINUE

          DO 30 I = 1, NVARS
              POINT(I) = Z(I)
30        CONTINUE

          BEST_N = MINF

          RETURN
      END

      FUNCTION HOOKE(NVARS, STARTP, ENDPT, RHO, EPSILO, ITERMA)
          IMPLICIT NONE

C         MAX NUMBER OF VARIABLES.
          INTEGER    VARS
          PARAMETER (VARS = 250)

          INTEGER HOOKE
          INTEGER NVARS

          DOUBLE PRECISION STARTP(VARS)
          DOUBLE PRECISION ENDPT(VARS)
          DOUBLE PRECISION RHO
          DOUBLE PRECISION EPSILO

          INTEGER ITERMA
          INTEGER I
          INTEGER IADJ
          INTEGER ITERS
          INTEGER J
          INTEGER KEEP

          DOUBLE PRECISION NEWX(VARS)
          DOUBLE PRECISION XBEFOR(VARS)
          DOUBLE PRECISION DELTA(VARS)
          DOUBLE PRECISION STEPLE
          DOUBLE PRECISION FBEFOR
          DOUBLE PRECISION NEWF
          DOUBLE PRECISION TMP

C         GLOBAL VARIABLES.
          INTEGER FUNEVA
          COMMON  FUNEVA

          DOUBLE PRECISION F
          DOUBLE PRECISION BEST_N

          DO 10 I = 1, NVARS
              XBEFOR(I) = STARTP(I)
              NEWX(I)   = XBEFOR(I)

              DELTA(I) = ABS(STARTP(I) * RHO)

              IF (DELTA(I) .EQ. 0.0) THEN
                  DELTA(I) = RHO
              END IF
10        CONTINUE

          IADJ   = 0
          STEPLE = RHO
          ITERS  = 0

          FBEFOR = F(NEWX, NVARS)

          NEWF = FBEFOR

120       IF ((ITERS .LT. ITERMA) .AND. (STEPLE .GT. EPSILO)) THEN
              ITERS = ITERS + 1
              IADJ  = IADJ + 1

              PRINT 20, FUNEVA, FBEFOR
20            FORMAT (/, 'AFTER ', I5, ' FUNEVALS, F(X) =  ', 1PE11.4E3,
     *                ' AT')

              DO 30 J = 1, NVARS
                  PRINT 40, J - 1, XBEFOR(J)
40                FORMAT ('   X(', I2, ') = ', 1PE12.4E3)
30            CONTINUE

C             FIND BEST NEW POINT, ONE COORD AT A TIME.
              DO 50 I = 1, NVARS
                  NEWX(I) = XBEFOR(I)
50            CONTINUE

              NEWF = BEST_N(DELTA, NEWX, FBEFOR, NVARS)

C             IF WE MADE SOME IMPROVEMENTS, PURSUE THAT DIRECTION.
              KEEP = 1

100           IF ((NEWF .LT. FBEFOR) .AND. (KEEP .EQ. 1)) THEN
                  IADJ = 0

                  DO 60 I = 1, NVARS
C                     FIRSTLY, ARRANGE THE SIGN OF DELTA().
                      IF (NEWX(I) .LE. XBEFOR(I)) THEN
                          DELTA(I) = 0.0 - ABS(DELTA(I))
                      ELSE
                          DELTA(I) = ABS(DELTA(I))
                      END IF

C                     NOW, MOVE FURTHER IN THIS DIRECTION.
                      TMP       = XBEFOR(I)
                      XBEFOR(I) = NEWX(I)
                      NEWX(I)   = NEWX(I) + NEWX(I) - TMP
60                CONTINUE

                  FBEFOR = NEWF

                  NEWF = BEST_N(DELTA, NEWX, FBEFOR, NVARS)

C                 IF THE FURTHER (OPTIMISTIC) MOVE WAS BAD....
                  IF (NEWF .GE. FBEFOR) THEN
                      GO TO 70
                  END IF

C                 MAKE SURE THAT THE DIFFERENCES BETWEEN THE NEW
C                 AND THE OLD POINTS ARE DUE TO ACTUAL DISPLACEMENTS.
C                 BEWARE OF ROUNDOFF ERRORS THAT MIGHT CAUSE
C                 NEWF .LT. FBEFORE.
                  KEEP = 0

                  DO 80 I = 1, NVARS
                      KEEP = 1

                      IF (ABS(NEWX(I) - XBEFOR(I))
     *                    .GT. (0.5 * ABS(DELTA(I)))) THEN

                          GO TO 90
                      ELSE
                          KEEP = 0
                      END IF
80                CONTINUE

90                GO TO 100
70            END IF

              IF ((STEPLE .GE. EPSILO) .AND. (NEWF .GE. FBEFOR)) THEN
                  STEPLE = STEPLE * RHO

                  DO 110 I = 1, NVARS
                      DELTA(I) = DELTA(I) * RHO
110               CONTINUE
              END IF

              GO TO 120
          END IF

          DO 130 I = 1, NVARS
              ENDPT(I) = XBEFOR(I)
130       CONTINUE

          HOOKE = ITERS

          RETURN
      END

      PROGRAM ROSENB
          IMPLICIT NONE

C         MAX NUMBER OF VARIABLES.
          INTEGER    VARS
          PARAMETER (VARS = 250)

C         STEPSIZE GEOMETRIC SHRINK.
          DOUBLE PRECISION RHO_BE
          PARAMETER       (RHO_BE = 0.5)

C         ENDING VALUE OF STEPSIZE.
          DOUBLE PRECISION EPSMIN
          PARAMETER       (EPSMIN = 1E-6)

C         MAX NUMBER OF ITERATIONS.
          INTEGER    IMAX
          PARAMETER (IMAX = 5000)

C         GLOBAL VARIABLES.
          INTEGER FUNEVA
          COMMON  FUNEVA

          INTEGER NVARS
          INTEGER ITERMA
          INTEGER JJ
          INTEGER I

          DOUBLE PRECISION STARTP(VARS)
          DOUBLE PRECISION RHO
          DOUBLE PRECISION EPSILO
          DOUBLE PRECISION ENDPT(VARS)

          INTEGER HOOKE

          FUNEVA = 0

C         STARTING GUESS FOR ROSENBROCK'S TEST FUNCTION.
          NVARS     = 2
          STARTP(1) = -1.2
          STARTP(2) = 1.0
          ITERMA    = IMAX
          RHO       = RHO_BE
          EPSILO    = EPSMIN

          JJ = HOOKE(NVARS, STARTP, ENDPT, RHO, EPSILO, ITERMA)

          PRINT 10, JJ
10        FORMAT (///, 'HOOKE USED ', I2, ' ITERATIONS, AND RETURNED')

          DO 20 I = 1, NVARS
              PRINT 30, I - 1, ENDPT(I)
30            FORMAT ('X(', I3, ') = ', 1PE15.7E3, ' ')
20        CONTINUE
      END

C =============================================================================