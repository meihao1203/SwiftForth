OPTIONAL SCILOAD Forth Scientific Library test load

{ ====================================================================
Test Forth Scientific Library

This file loads all of the FSL routines and runs as many of the test
routines as possible.  The goal is to produce a consistent command
window image so that modifications can be validated quickly.

\ before a test means that it presently causes run time errors.
( ??? ) means that there is presently no test case for these routines.
( random ) means that the test case produces random output.
( overflow ) means that the test takes more than 8 stack items.

==================================================================== }

EMPTY

REQUIRES fpmath /INPUT

INCLUDE library/fsl-util.f              \ Required for all

GILD

EMPTY   INCLUDE library/expint.f        expint_test
EMPTY   INCLUDE library/elip.f          elip_test
EMPTY   INCLUDE library/expint.f
        INCLUDE library/horner.f        horner_test
EMPTY   INCLUDE library/logistic.f
                CR % 1.0 % 1.0 % 0.0 logistic f.  .( = 0.731059)
                CR % 3.2 % 1.5 % 0.2 logistic f.  .( = 0.993307)
                CR % 3.2 % 1.5 % 0.2 d_logistic f. .( = 0.00997209)
EMPTY   INCLUDE library/cube_rt.f       ( ??? )
EMPTY   INCLUDE library/cubic.f         ( ??? )
EMPTY   INCLUDE library/regfalsi.f      ( ??? )
EMPTY   INCLUDE library/hartley.f       hartley-test1
                                        hartley-test2
        INCLUDE library/harttest.f
                CR SINE-TEST  CR SHOW-FFT  CR SHOW-POWER
                CR .SPEED  CR .SPEED-FHT
EMPTY   INCLUDE library/logistic.f
        INCLUDE library/aitken.f        1.2E aitken_test1
                                        2.0E aitken_test2
EMPTY   INCLUDE library/logistic.f
        INCLUDE library/hermite.f       1.2E hermite_test1
                                        2.0E hermite_test2
EMPTY   INCLUDE library/logistic.f
        INCLUDE library/lagrange.f      1.2E lagrange_test1
                                        2.0E lagrange_test2
EMPTY   INCLUDE library/logistic.f
        INCLUDE library/divdiffs.f
        INCLUDE library/newton.f        1.2E fnewt-test1
                                        2.0E fnewt-test2
                                        1.2E bnewt-test1
                                        2.0E bnewt-test2
EMPTY   INCLUDE library/factorl.f       factorial-test
EMPTY   INCLUDE library/shellsrt.f      test_sort
EMPTY   INCLUDE library/expint.f
        INCLUDE library/horner.f
        INCLUDE library/factorl.f
        INCLUDE library/seriespw.f      series_tests
                                        test_1/(1+x)
EMPTY   INCLUDE library/logistic.f
        INCLUDE library/polrat.f        1.5E0 polrat_test1 err-test1
                                          2E0 polrat_test2 err-test2
                                         -2E0 polrat_test3 err-test3
EMPTY   INCLUDE library/expint.f
        INCLUDE library/horner.f
        INCLUDE library/gamma.f         gamma-test
EMPTY   INCLUDE library/adaptint.f      ( ??? )
EMPTY   INCLUDE library/expint.f
        INCLUDE library/horner.f
        INCLUDE library/gamma.f
        INCLUDE library/pcylfun.f       pcf-test
EMPTY   INCLUDE library/polys.f         test-cheby
                                        test-hermite
                                        test-laguerre
                                        test-legendre
                                        test-glaguerre
                                        test-bessel
EMPTY   INCLUDE library/dates.f         date-test
EMPTY   INCLUDE library/r250.f          lcm_test
                                        r250_test
EMPTY   INCLUDE library/ran4.f          ( ??? )
EMPTY   INCLUDE library/hilbert.f       2 hilbert-test .( = 0.0833333)
                                        3 hilbert-test .( = 0.000462963)
                                        4 hilbert-test .( = 1.65344e-7)
                                        5 hilbert-test .( = 3.7493E-12)
EMPTY   INCLUDE library/find.f          3 test-find
EMPTY   INCLUDE library/gauleg.f        8 gauleg-test
EMPTY   INCLUDE library/expint.f
        INCLUDE library/horner.f
        INCLUDE library/elip12.f        EK_test
EMPTY   INCLUDE library/runge4.f        10 dvib_test_twice
                                        10 dvib_test
                                        10 lorenz_test
                                        10 cap_test
                                        200e-3 50e-3 1e-3 cap_test2
                                        800e-3 50e-3 1e-3 dvib_test2
EMPTY   INCLUDE library/kande.f         kande_test
EMPTY   INCLUDE library/factorl.f
        INCLUDE library/telscop1.f      test_telescope1
EMPTY   INCLUDE library/factorl.f
        INCLUDE library/telscop2.f      test_telescope2
EMPTY   INCLUDE library/structs.f       test0 test1 test2 test3
EMPTY   INCLUDE library/structs.f
        INCLUDE library/hilbert.f
        INCLUDE library/lufact.f        lufact-test
                                        lufact-test2
                                        lufact-test3
EMPTY   INCLUDE library/structs.f
        INCLUDE library/hilbert.f
        INCLUDE library/lufact.f
        INCLUDE library/dets.f          4 det-test
EMPTY   INCLUDE library/structs.f
        INCLUDE library/hilbert.f
        INCLUDE library/lufact.f
        INCLUDE library/backsub.f       backsub-test
EMPTY   INCLUDE library/structs.f
        INCLUDE library/hilbert.f
        INCLUDE library/lufact.f
        INCLUDE library/backsub.f
        INCLUDE library/invm.f          4 invm-test
EMPTY   INCLUDE library/complex.f
        INCLUDE library/cmath.f         zmath-test
                                       ( 10 zmath-table ( overflow )
EMPTY   INCLUDE library/complex.f
        INCLUDE library/cmath.f
        INCLUDE library/dfourier.f      dfourier-test1
                                       \ dfourier-test2
EMPTY   INCLUDE library/complex.f
        INCLUDE library/cmath.f
        INCLUDE library/ffourier.f      ffourier-test1
                                       \ ffourier-test2
EMPTY   INCLUDE library/gaussj.f       ( TEST-MAT ( random )
                                        3EQS SOLVE-IT
EMPTY   INCLUDE library/gaussj.f
        INCLUDE library/svd.f           PROBLEM1 PROBLEM2
                                       ( TEST-SINGULAR ( random )
                                       ( TEST-SVDCMP ( random )
              1e-32 svdtol F! use( fpoly[odd] )FIT-SINE
              8 TO #vr use( fpoly[odd] )FIT-SINE

EMPTY   INCLUDE library/amoeba          SHOW-PROBLEM
                                        1E-3 TEST-AMOEBA

EMPTY   INCLUDE library/sunday          QTEST
EMPTY   INCLUDE library/expint
        INCLUDE library/horner
        INCLUDE library/gauss           gauss-test
EMPTY   INCLUDE library/sph_bes         ( ??? )
EMPTY   INCLUDE library/crc             ( self-testing )
EMPTY   INCLUDE library/logistic
        INCLUDE library/polrat
        INCLUDE library/integral        TEST-PROGRAM
EMPTY   INCLUDE library/big             ( ??? )
EMPTY   INCLUDE library/walsh           walsh-test
