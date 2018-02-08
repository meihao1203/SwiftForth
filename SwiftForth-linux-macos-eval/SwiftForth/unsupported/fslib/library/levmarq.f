\ -- marquard.frt ------------------------------------------------------------
\ A nonlinear fitting toolkit. Implements the Levenberg-Marquardt method.

\ setup-marquardt ( 'X 'Y 'SIG ndata  'A ma  'LISTA mfit  'COVAR 'ALPHA -- )
\ Levenberg-Marquardt method, attempting to reduce the Chi-squared (chisq) of
\ a fit between ndata points X[], Y[] with individual standard deviations SIG[]
\ and a nonlinear function dependent on ma coefficients A[]. The array
\ LISTA[] numbers the ma parameters in A such that the first mfit elements
\ correspond to values actually being adjusted; the remaining ma-mfit
\ parameters are held fixed at their input value. The word mrqminimize delivers
\ current best-fit values for the ma fit parameters A , and chisq. During most
\ iterations the elements of the mfit x ma array COVAR[] (covariance) and the
\ ma x ma array ALPHA[] (curvature) are used as working space. The word must
\ be supplied with a routine MrqFitter ( 'A 'DYDA ) ( F: x -- yfit ) that
\ evaluates the fitting function yfit, and its ma derivatives DYDA[] with
\ respect to the fitting parameters A at x.
\ On the call to setup-marquardt, provide an initial guess for the parameters
\ A . Then start calling mrqminimize .

\ init-marquardt ( -- )
\ Part of setup-marquardt. Call when changes are made to ma, mfit and the
\ elements of vector LISTA[] but the other parameters given to setup-marquardt
\ should not be changed. This is (of course) only allowed when ma is made
\ *smaller* or stays the same and mfit is smaller than ma .

\ mrqminimize ( -- bad? )
\ First call setup-marquardt . If mrqminimize succeeds, chisq becomes smaller
\ and lambda decreases by a factor of 10. If a step fails lambda grows by a
\ factor of 10. You must call repeatedly until convergence is achieved.
\ When mrqminimize indicates convergence, make one final call with lambda = 0,
\ so that COVAR contains the covariance matrix, and ALPHA the curvature matrix.
\ (The "curvature" is 1/2 the Hessian).
\ Finally call exit-marquardt to clean up memory.
\ Note: the boolean bad? does not indicate successful convergence, but
\ reports TRUE in case of a fatal error. You may want to call exit-marquardt
\ when a fatal error happens (probably because of a singular matrix in gaussj).

\ exit-marquardt ( -- )
\ Call exit-marquardt to clean up memory after using setup-marquardt or
\ mrqminimize .

\ MrqFitter ( 'A 'DYDA -- ) ( F: x -- yfit )
\ A vectored word that evaluates the fitting function yfit, and its ma
\ derivatives DYDA[] with respect to the fitting parameters A at x.

\         Flowchart of the Nonlinear Fitting Process:
\         ===========================================
\   0    Set A to ma guessed/fixed values and call setup-marquardt .
\	 This computes the initial Chi-square(A) and picks a modest
\	 value for lambda. Lambda is an internal variable; when it is very
\	 small we are near the minimum and an inverse-Hessian approach is
\	 used, when it is very large we are far from the minimum and we use
\	 the steepest descent method.
\   1    Call mrqminimize
\          On error (bad? == TRUE) goto 3.
\          if chisq became less than 0.1, or repeatedly changes less than
\	   0.1%, goto 2. ('repeatedly' is more than 10 iterations)
\	   if chisq didn't change (it *never* increases), goto 1.
\        (To check changes in chi-square test variables chisq and best-chisq)
\   2    Make lambda = 0 and call mrqminimize one more time. Now COVAR holds
\	 the covariance and ALPHA the curvature (A and chisq become valid).
\   3    do exit-marquardt .

\ This is an ANS Forth program requiring:
\	1. The Floating-Point word sets
\	2. Uses FSL words from fsl_util.xxx
\	3. Uses gaussj from gaussj.xxx
\	4. Uses : F> FSWAP F< ;
\		: F2DUP ( F: r1 r2 -- r1 r2 r1 r2 ) FOVER FOVER ;
\	        : 1/F  ( F: r -- 1/r ) 1e FSWAP F/ ;
\		: F+! ( addr -- ) ( F: r -- )  DUP F@ F+ F! ;
\		: FSQR ( F: r1 -- r2 ) FDUP F* ;

		: F1+ ( F: r -- r ) 1e F+ ;

\		: S>F ( n -- ) ( F: -- r ) S>D D>F ;
\ 		  HERE 1+ VALUE seed ( note: '$' prefix means HEX )

		: RANDOM seed $107465 * $234567 + DUP TO seed ; ( -- )
		: CHOOSE ( n -- n ) RANDOM UM* NIP ; ( Paul Mennen, 1991 )
		: ranf ( -- ) ( F: -- x) \ generate a random value from 0.0 to 1.0
			RANDOM 0 D>F  $FFFFFFFF 0 D>F  F/ ;

\ Note: the code uses 8 fp stack cells when executing the test words.
\       (with iForth vsn 1.07)

\ See: 'Numerical recipes in Pascal, The Art of Scientific Computing',
\ William H. Press, Brian P. Flannery, Saul A. Teukolsky and William
\ T. Vetterling, Chapter 14 (14.4): Modeling of Data, Nonlinear Models.
\ 1989; Cambridge University Press, Cambridge, ISBN 0-521-37516-9

\ (c) Copyright 1995 Marcel Hendrix.  Permission is granted by the
\ author to use this software for any application provided this
\ copyright notice is preserved.

\ Vsn 1.0: Initial code, 1995.
\ Vsn 1.1: code review and suggestions: "C. Montgomery" <CGM@physics.utoledo.edu>
  CR .( MARQUARDT         V1.1            23 Jan  1997     MH )


\ TEST-CODE? FALSE TO TEST-CODE?
\  S" gaussj.frt" INCLUDED  ( get the Gauss-Jordan solver word: gaussj )
\ TO TEST-CODE?


Private:

  FLOAT DARRAY  x{		\ inputs x, y and individual standard deviations
  FLOAT DARRAY  y{
  FLOAT DARRAY  sig{		0 VALUE ndata

  FLOAT DARRAY  a{		0 VALUE ma
  FLOAT DARRAY  dyda{

  FLOAT DARRAY  lista{		0 VALUE mfit

  FLOAT DMATRIX covar{{		\ (ma x ma) covariances
  FLOAT DMATRIX alpha{{		\ (ma x ma) curvatures

  FLOAT DARRAY  MrqminBeta{	\ these four are scratch space.
  FLOAT DARRAY  atry{
  FLOAT DARRAY  da{
  FLOAT DMATRIX oneda{{

Public:

FVARIABLE chisq		\ current value of Chi-square.
FVARIABLE best-chisq	\ lowest value of Chi-square found so far.
FVARIABLE lambda	\ algorithm selector (internal)
			\ set to 0e to fetch the results (external)
TRUE VALUE LAMPTON?	\ False -> Original NR algorithm,
			\ True  -> M. Lampton, C.inP. vol11, pp110-115 1997.
			\          Claimed to work better for *some* problems
			\	   Works badly for examples in this file.

\ A vectored word that evaluates the fitting function yfit, and its ma
\ derivatives DYDA[] with respect to the fitting parameters A at x.
v: MrqFitter ( 'A 'DYDA -- ) ( F: x -- y )


\         Flowchart of the Nonlinear Fitting Process:
\         ===========================================
\   0    Set A to ma guessed/fixed values and call setup-marquardt .
\	 This computes the initial Chi-square(A) and picks a modest
\	 value for lambda. Lambda is an internal variable; when it is very
\	 small we are near the minimum and an inverse-Hessian approach is
\	 used, when it is very large we are far from the minimum and the
\	 steepest descent method takes over.
\   1    Call mrqminimize
\          On error (bad? == TRUE) goto 3.
\          if chisq became less than 0.1, or repeatedly changes less than
\	   0.1%, goto 2. ('repeatedly' is more than 10 iterations)
\	   if chisq didn't change (it *never* increases), goto 1.
\        (To check changes in chi-square test variables chisq and best-chisq)
\   2    Make lambda = 0 and call mrqminimize one more time. Now COVAR holds
\ 	 the covariance and ALPHA the curvature (A and chisq become valid).
\   3    do exit-marquardt .

Private:

\ Given the ma x ma covariance matrix COVAR[] of a fit for mfit of ma total
\ parameters, and their ordering vector LISTA[], repack the covariance matrix
\ to the true order of the parameters. Elements associated with fixed
\ parameters will be zero.
: covsrt ( -- )
	\ zero the elements below the diagonal
	ma 1- 0 ?DO  ma I 1+ ?DO  0e covar{{ I J }} F!  LOOP LOOP

	\ pack off-diagonal elements of fit into correct locations below
	\ diagonal
	mfit 1- 0 ?DO	mfit  I 1+ ?DO  covar{{ I J }} F@
					covar{{ lista{ J } @  lista{ I } @
					2DUP < IF  SWAP  THEN   }} F!
				  LOOP
		 LOOP

	\ Temporarily store diagonal elements in top row and zero the diagonal
	covar{{ 0 0 }} F@ ( "swap" )
	ma 0 DO  covar{{ I I }} DUP F@ 0e F!  covar{{ 0 I }} F!  LOOP

	\ Sort elements into proper order on diagonal
	( swap) covar{{ lista{ 0 } @ DUP }} F!
	mfit 1 DO  covar{{ 0 I }} F@  covar{{ lista{ I } @ DUP }} F!  LOOP

	\ Fill above diagonal by symmetry
	ma 1 DO  I 0 DO  covar{{ J I }} F@  covar{{ I J }} F!  LOOP LOOP ;


\ Used by mrqminize to evaluate the linearized fitting matrix A ,
\ mfit x mfit matrix ALPHA[] and vector MBETA[]
\ Called as   a{ alpha{{ MrqminBeta{ mrqcof  ||  atry{ covar{{ da{ mrqcof
: mrqcof ( 'A 'ALPHA 'MBETA -- )
	LOCALS| beta{ alpha{{ a{ |
	mfit 0 DO \ init symmetric alpha and beta
		  I 1+ 0 DO  0e alpha{{ J I }} F!  LOOP
		  0e beta{ I } F!
	     LOOP
	0e ( chi2)
	ndata 0 DO \ summation loop over all data
		   sig{ I } F@ FSQR 1/F ( F: chi2 s2)
		   y{ I } F@
		   x{ I } F@ a{ dyda{ MrqFitter ( F: ymod)
		   F- ( F: chi2 s2 dy)
		   mfit 0 DO
			     FOVER dyda{ lista{ I } @ } F@ F* ( F: .. wt)
			     I 1+ 0 DO
				       FDUP dyda{ lista{ I } @ } F@ F*
				       alpha{{ J I }} F+!
				  LOOP ( F: chi2 s2 dy wt)
			     FOVER F* beta{ I } F+!
			LOOP ( F: chi2 s2 dy)
		   FSQR F* F+ ( F: chi2)
	      LOOP
	chisq F!
	mfit 1 DO  I 0 DO  alpha{{ J I }} F@ alpha{{ I J }} F!  LOOP LOOP ;

Public:

\ Part of setup-marquardt. Call when changes are made to ma , mfit and the
\ elements of vector LISTA[] but the other parameters given to setup-marquardt
\ should not be changed. This is (of course) only allowed when ma is made
\ smaller or stays the same and mfit is smaller than ma .
: init-marquardt ( -- )
	mfit LOCALS| kk |

	ma 0 DO
		 0  mfit 0 DO lista{ I } @ J = 1 AND + LOOP
		 DUP 0= IF  DROP I lista{ kk } !  1 kk + TO kk
		      ELSE  1 > ABORT" lista -- improper permutation (1)"
		      THEN
	   LOOP  kk ma <> ABORT" lista -- improper permutation (2)"

	LAMPTON? IF 2e 		\ seems to be arbitrary
	       ELSE 0.001e 	\ "pick a modest value for lambda."
	       THEN lambda F!	\ Compute baseline chisq; save it in best-chisq

	a{ alpha{{ MrqminBeta{ mrqcof   chisq F@ best-chisq F!

	a{ atry{ ma }fcopy ;


\ Levenberg-Marquardt method, attempting to reduce the value chisq of a fit
\ between ndata points X[], Y[] with individual standard deviations SIG[] and
\ a nonlinear function dependent on ma coefficients A[]. The vector LISTA[]
\ numbers the ma parameters in A such that the first mfit elements correspond
\ to values actually being adjusted; the remaining ma-mfit parameters are held
\ fixed at their input value. The word mrqminimize delivers current best-fit
\ values for the ma fit parameters A , and chisq. During most iterations the
\ elements of the mfit x ma array COVAR[] and the ma x ma array ALPHA[] are
\ used as working space. The word must be supplied with a routine
\ MrqFitter ( 'A 'DYDA ) ( F: x -- yfit ) that evaluates the fitting function
\ yfit, and its ma derivatives DYDA[] with respect to the fitting parameters A
\ at x.
\ On the call to setup-marquardt, provide an initial guess for the parameters
\ A . Then start calling mrqminimize . It is allowed to stop, change ma, mfit
\ and LISTA[], call init-marquardt and continue calling mrqminimize.
: setup-marquardt ( 'X 'Y 'SIG ndata  'A ma  'LISTA mfit  'COVAR 'ALPHA -- )
	0e chisq F!
	& alpha{{ &!   & covar{{ &!
	TO mfit  & lista{ &!
	TO ma    & a{ &!
	TO ndata & sig{ &!  & y{ &!  & x{ &!
	&       dyda{ ma }malloc malloc-fail?
	& MrqminBeta{ ma }malloc malloc-fail? OR
	&       atry{ ma }malloc malloc-fail? OR
	& oneda{{ ma  1 }}malloc malloc-fail? OR
	& da{ ma }malloc malloc-fail? OR
	  ABORT" setup-marquardt -- out of memory"
	init-marquardt ;

\ Call exit-marquardt to clean up memory after using setup-marquardt or
\ mrqminimize .
: exit-marquardt ( -- )
	&         da{   }free
	&      oneda{{ }}free
	&       atry{   }free
	& MrqminBeta{   }free
	&       dyda{   }free ;


\ First call setup-marquardt . If mrqminimize succeeds, chisq becomes smaller
\ and lambda decreases by a factor of 10. If a step fails lambda grows by a
\ factor of 10. You must call repeatedly until convergence is achieved.
\ When mrqminimize indicates convergence, make one final call with lambda = 0,
\ so that COVAR contains the covariance matrix, and ALPHA the curvature matrix.
\ (The "curvature" is 1/2 the Hessian).
\ Finally call exit-marquardt to clean up memory.
\ Note: the boolean returned does not indicate successful convergence, but
\ reports TRUE in case of a fatal error. You may want to call exit-marquardt
\ when a fatal error happens (probably because of a singular matrix in gaussj).
: mrqminimize ( -- bad? )
	0 LOCALS| xt |
	alpha{{ covar{{ mfit DUP }}fcopy

	lambda F@
	LAMPTON? IF     ['] F+
	       ELSE F1+ ['] F*
	       THEN TO xt
	mfit 0 DO
		  FDUP alpha{{ I DUP }} F@  xt EXECUTE  covar{{ I DUP }} F!
		  MrqminBeta{ I } F@  oneda{{ I 0 }} F!
	     LOOP
	FDROP

	covar{{ oneda{{ mfit 1 gaussj IF TRUE EXIT THEN  \ singular?

	mfit 0 DO oneda{{ I 0 }} F@  da{ I } F! LOOP

	lambda	F@ F0= IF covsrt FALSE EXIT THEN

	mfit 0 DO     a{ lista{ I } @ } F@  da{ I } F@ F+
		   atry{ lista{ I } @ } F!
	     LOOP

	atry{ covar{{ da{ mrqcof
	chisq F@  best-chisq F@
	 F< IF	lambda DUP F@
		LAMPTON? IF 1e F- 1e-16 FMAX
		       ELSE 0.1e F*
		       THEN F!
		chisq F@  best-chisq F!
		covar{{ alpha{{ mfit mfit }}fcopy
		mfit 0 DO
			   atry{ lista{ I } @ } F@  a{ lista{ I } @ } F!
			   da{ I } F@  MrqminBeta{ I } F!
		     LOOP
	  ELSE	lambda DUP F@
		LAMPTON? IF 15e F+
		       ELSE ( 10e) 1.5e F*
		       THEN F!
	        best-chisq F@ chisq F!
	  THEN

	FALSE ;


Reset_Search_Order

TEST-CODE? [IF]


10 VALUE #datapoints	\ number of data points
 3 VALUE #funcs		\ number of functions to fit data
 3 VALUE #params/f	\ parameters per function

  FLOAT DARRAY x{
  FLOAT DARRAY y{
  FLOAT DARRAY sig{
  FLOAT DARRAY a{
INTEGER DARRAY lista{

FLOAT DMATRIX covar{{
FLOAT DMATRIX alpha{{

v: MRQ-SETUP    ( -- )
v: MRQ-STOP?    ( iter -- stop? )
v: MRQ-RESULTS  ( -- )

\ true when r1 and r2 differ by less than 0.1%
: NEARLY-EQUAL? ( -- bool ) ( F: +r1 +r2 -- )
	-1e-3 F~ ;

10 VALUE hesitate

: FIND-COEFFS ( -- )
	1 0 LOCALS| #same-chi iter |
	 0e  FRAME| a |

	MRQ-SETUP

	BEGIN
	  mrqminimize IF exit-marquardt TRUE ABORT" singular matrix" THEN
	  chisq F@  a NEARLY-EQUAL? IF #same-chi 1+ TO #same-chi
		     		  ELSE 0 TO #same-chi
		     		  THEN
	  chisq F@ &a F!
	  #same-chi hesitate > 	\ chisq doesn't change at all
	  chisq F@  0.1e F<  OR \ chisq is low enough
	  iter DUP 1+ TO iter
	  MRQ-STOP?  OR		\ user-defined additional criteria
	UNTIL

	MRQ-RESULTS

	|FRAME ;


: F.NICE ( F: r -- )
	FDUP F0< 0= IF SPACE THEN  F. SPACE ;


\ Setup code for the vectors MrqFitter MRQ-SETUP MRQ-STOP? and MRQ-RESULTS


\ ----------------------------------------------------------------------------
\ First example: fitting data with three bell-curves.

\ Evaluates and computes derivative of a set of #funcs Gaussian functions
\ of the form  f(x) = B * exp -( (x-E)/G )^2.
\ The parameters B,E,G are stored sequentially in a{ .
\ The derivatives dy/dB, dy/dE and dy/dG are stored sequentially in dyda{ .
: fgauss ( 'a 'dyda -- ) ( F: x -- y )
	0 LOCALS| ix dyda{ a{ |
	0e 0e 0e FRAME| a b c |
	0e ( F: x y)
	#funcs 0
	  DO
		I #params/f * TO ix
		FOVER a{ ix 1+ } F@ F-  a{ ix 2 + } F@ F/ ( arg) FDUP &a F!
		FSQR FNEGATE FEXP ( ex) FDUP &b F!
		a F* F2* a{ ix } F@ F* ( fac) &c F!  ( F: x y)
		a{ ix } F@ b F* F+ ( F: x y')
		b dyda{ ix } F!
		c a{ ix 2 + } F@ F/ FDUP dyda{ ix 1+ } F!
		a F* dyda{ ix 2 + } F!
 	LOOP
	FSWAP ( F: x ) FDROP |FRAME ;


FVARIABLE spread	\ actual value does NOT influence the number of
			\ iterations, but it affects covar{{ .
			\ Too small a value prevents convergence abruptly.

: UNSURE ( -- )  1e-2  spread F! ;
: SURE   ( -- )  1e-10 spread F! ;  SURE

20 VALUE X-range	\ data x-axis: between 0 - X-range

: gscale ( i -- ) ( F: -- delta )
	X-range * S>F  #datapoints S>F F/ ;

\ Assume the user sets up #datapoints.
\ Experiment with: #datapoints (up to 800 was tried)
\                  X-range     (up to 80 was tried).
\		   spread      (1e-2 and 1e-10 both tried)

: GAUSS-SETUP

	3 TO #funcs
	3 TO #params/f

	&     x{ #datapoints }malloc malloc-fail?
	&     y{ #datapoints }malloc malloc-fail? OR
	&   sig{ #datapoints }malloc malloc-fail? OR
	&     a{ #funcs #params/f * }malloc malloc-fail? OR
	& lista{ #funcs #params/f * }malloc malloc-fail? OR

	& covar{{ #funcs #params/f * DUP }}malloc malloc-fail? OR
	& alpha{{ #funcs #params/f * DUP }}malloc malloc-fail? OR
	ABORT" FIND-COEFFS -- not enough core"

	spread F@ 12e FSQRT F/  #datapoints 0 DO  sig{ I } FDUP F! LOOP  FDROP

	#datapoints 0 DO  I gscale   x{ I } F!  LOOP

	#datapoints 0 DO I gscale 2.5e F- 1.5e F/ FSQR FNEGATE FEXP 3.3e F*
			 I gscale 1.3e F- 2.1e F/ FSQR FNEGATE FEXP 6.6e F*  F-
			 I gscale 6.5e F- 7.5e F/ FSQR FNEGATE FEXP 2.2e F*  F+
			 ranf 0.5e F- spread F@ F* F+  y{ I } F!
	            LOOP

	CR ." The encoded function F(x) = " CR
	CR ."     3.3 exp -((x-2.5)/1.5)^2 "
	CR ."   - 6.6 exp -((x-1.3)/2.1)^2 "
	CR ."   + 2.2 exp -((x-6.5)/7.5)^2 " CR

	2e a{ 0 } F!   3e a{ 1 } F!	1e a{ 2 } F!
	3e a{ 3 } F!   1e a{ 4 } F! 	2e a{ 5 } F!
	1e a{ 6 } F!   2e a{ 7 } F!	3e a{ 8 } F!

	#funcs #params/f * 0 DO I lista{ I } ! LOOP

	x{ y{ sig{ #datapoints
	a{ #funcs #params/f *  lista{ #funcs #params/f *
	covar{{ alpha{{ setup-marquardt ( lambda <- 0.001)

	mrqminimize ABORT" singular matrix" ;


: GAUSS? ( iter -- stop? )
	CR ." iter = " 6 .R
	." , chisq = " chisq F@ FS. ." lambda = " lambda F@ FS.
	EKEY? DUP IF DROP EKEY BL - THEN ;


: .GAUSS
	chisq F@  0e lambda F! 		\ get the results
	mrqminimize IF exit-marquardt
		       TRUE ABORT" singular matrix"
	          THEN
	chisq F!

	exit-marquardt

	CR CR ." Results, spread      : " spread F@ F.
	   CR ."          chi squared : " chisq F@ FS.
	   CR ." Parameters: "
	#funcs 0 DO CR  #params/f 0 DO a{ J #params/f * I + } F@ F.NICE
				  LOOP
	       LOOP

	CR ." Expected: "
	CR ."  3.300000   2.500000   1.500000  "
	CR ." -6.600000   1.300000   2.100000  "
	CR ."  2.200000   6.500000   7.500000  "

	print-width @ >R  #funcs #params/f * print-width !
	 CR ." --more--" KEY DROP
	 CR ." Covariance matrix: "
	 CR #funcs #params/f * DUP covar{{ }}fprint CR
 	 CR ." --more--" KEY DROP
	 CR ." Curvature matrix: "
	 CR #funcs #params/f * DUP alpha{{ }}fprint
	R> print-width ! ;

: FIND-GAUSS
	& fgauss      defines MrqFitter
	& GAUSS-SETUP defines MRQ-SETUP
	& GAUSS?      defines MRQ-STOP?
	& .GAUSS      defines MRQ-RESULTS
	FIND-COEFFS ;

CR .( Try:  UNSURE  20 TO X-range  30 TO #datapoints  FIND-GAUSS )


0 [IF] An example run.

UNSURE  20 TO X-range  30 TO #datapoints  FIND-GAUSS

The encoded function F(x) =

    3.3 exp -((x-2.5)/1.5)^2
  - 6.6 exp -((x-1.3)/2.1)^2
  + 2.2 exp -((x-6.5)/7.5)^2

iter = 1 chisq = 2.933718E7
iter = 2 chisq = 1.899992E7
iter = 3 chisq = 1.245062E7
iter = 4 chisq = 6.924562E6
iter = 5 chisq = 6.924562E6
iter = 6 chisq = 6.924562E6
iter = 7 chisq = 6.924562E6
iter = 8 chisq = 4.482554E6
iter = 9 chisq = 4.482554E6
iter = 10 chisq = 1.416918E6
iter = 11 chisq = 1.416918E6
iter = 12 chisq = 3.568138E5
iter = 13 chisq = 1.151155E5
iter = 14 chisq = 1.708656E3
iter = 15 chisq = 6.289730E2
iter = 16 chisq = 2.480181E2
iter = 17 chisq = 1.780795E1
iter = 18 chisq = 1.780249E1
iter = 19 chisq = 1.780249E1
iter = 20 chisq = 1.780249E1
iter = 21 chisq = 1.780249E1
iter = 22 chisq = 1.780249E1
iter = 23 chisq = 1.780249E1
iter = 24 chisq = 1.780249E1
iter = 25 chisq = 1.780249E1
iter = 26 chisq = 1.780249E1
iter = 27 chisq = 1.780249E1
iter = 28 chisq = 1.780249E1

Results, spread      : 0.010000
         chi squared : 1.780249E1
Parameters:
 3.277261   2.501108   1.495904
-6.594641   1.296059  -2.103399
 2.202375   6.459837   7.533372
Expected:
 3.300000   2.500000   1.500000
-6.600000   1.300000   2.100000
 2.200000   6.500000   7.500000

--more--
Covariance matrix:
  1.507998E-0002  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  6.044973E-0005  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  1.606122E-0004  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  9.641815E-0003  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  3.793476E-0004  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  5.128008E-0005  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  5.770239E-0006  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  3.130938E-0004  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  2.370992E-0004


--more--
Curvature matrix:
  3.374552E+0005  1.444419E+0002  3.693623E+0005  3.121524E+0005 -7.497538E+0005  6.097921E+0005  3.582867E+0005 -1.057474E+0005  5.728673E+0004
  1.444419E+0002  1.618415E+0006  2.862736E+0003 -3.651327E+0005 -1.110557E+0006  8.498997E+0005  1.637068E+0005  3.789404E+0004 -6.032844E+0004
  3.693623E+0005  2.862736E+0003  1.208724E+0006  5.431725E+0005 -3.004227E+0005  1.140240E+0006  7.596113E+0005 -2.035320E+0005  1.160771E+0005
  3.121524E+0005 -3.651327E+0005  5.431725E+0005  4.472258E+0005 -1.743398E+0005  5.613314E+0005  3.849194E+0005 -1.361976E+0005  8.847438E+0004
 -7.497538E+0005 -1.110557E+0006 -3.004227E+0005 -1.743398E+0005  3.519807E+0006 -1.239853E+0006 -6.941239E+0005  1.096562E+0005 -4.842161E+0003
  6.097921E+0005  8.498997E+0005  1.140240E+0006  5.613314E+0005 -1.239853E+0006  2.099149E+0006  1.032362E+0006 -2.518601E+0005  1.294000E+0005
  3.582867E+0005  1.637068E+0005  7.596113E+0005  3.849194E+0005 -6.941239E+0005  1.032362E+0006  1.638840E+0006  3.844764E+0004  2.036834E+0005
 -1.057474E+0005  3.789404E+0004 -2.035320E+0005 -1.361976E+0005  1.096562E+0005 -2.518601E+0005  3.844764E+0004  1.190933E+0005  2.904559E+0004
  5.728673E+0004 -6.032844E+0004  1.160771E+0005  8.847438E+0004 -4.842161E+0003  1.294000E+0005  2.036834E+0005  2.904559E+0004  7.123986E+0004


SURE  20 TO X-range  30 TO #datapoints  FIND-GAUSS

The encoded function F(x) =

    3.3 exp -((x-2.5)/1.5)^2
  - 6.6 exp -((x-1.3)/2.1)^2
  + 2.2 exp -((x-6.5)/7.5)^2

iter = 1 chisq = 2.935374E23
iter = 2 chisq = 1.901706E23
iter = 3 chisq = 1.231598E23
iter = 4 chisq = 7.105935E22
iter = 5 chisq = 7.105935E22
iter = 6 chisq = 7.105935E22
iter = 7 chisq = 7.105935E22
iter = 8 chisq = 4.885832E22
iter = 9 chisq = 4.885832E22
iter = 10 chisq = 1.353706E22
iter = 11 chisq = 1.353706E22
iter = 12 chisq = 4.042113E21
iter = 13 chisq = 1.560580E21
iter = 14 chisq = 3.445118E19
iter = 15 chisq = 3.052738E18
iter = 16 chisq = 2.677526E18
iter = 17 chisq = 2.515745E13
iter = 18 chisq = 1.573504E4
iter = 19 chisq = 2.182845E1
iter = 20 chisq = 2.182838E1
iter = 21 chisq = 2.182838E1
iter = 22 chisq = 2.182838E1
iter = 23 chisq = 2.182838E1
iter = 24 chisq = 2.182838E1
iter = 25 chisq = 2.182838E1
iter = 26 chisq = 2.182838E1
iter = 27 chisq = 2.182838E1
iter = 28 chisq = 2.182838E1
iter = 29 chisq = 2.182838E1
iter = 30 chisq = 2.182838E1

Results, spread      : 1.000000E-10
         chi squared : 2.182838E1
Parameters:
 3.300000   2.500000   1.500000
-6.600000   1.300000  -2.100000
 2.200000   6.500000   7.500000
Expected:
 3.300000   2.500000   1.500000
-6.600000   1.300000   2.100000
 2.200000   6.500000   7.500000

--more--
Covariance matrix:
  1.615688E-0018  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  6.311909E-0021  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  1.657223E-0020  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  1.033440E-0018  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  4.008722E-0020  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  5.277391E-0021  0.000000E+0000  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  5.566767E-0022  0.000000E+0000  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  3.034061E-0020  0.000000E+0000
  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  0.000000E+0000  2.319471E-0020

--more--
Curvature matrix:
  3.383784E+0021  1.528693E+0018  3.719103E+0021  3.130869E+0021 -7.498132E+0021  6.118220E+0021  3.563557E+0021 -1.070463E+0021  5.876341E+0020
  1.528693E+0018  1.636405E+0022  3.024390E+0019 -3.672488E+0021 -1.129481E+0022  8.548402E+0021  1.670038E+0021  3.678508E+0020 -6.095755E+0020
  3.719103E+0021  3.024390E+0019  1.221951E+0022  5.453653E+0021 -2.931915E+0021  1.151697E+0022  7.588525E+0021 -2.066942E+0021  1.190807E+0021
  3.130869E+0021 -3.672488E+0021  5.453653E+0021  4.468538E+0021 -1.727207E+0021  5.631756E+0021  3.809586E+0021 -1.368996E+0021  8.991867E+0020
 -7.498132E+0021 -1.129481E+0022 -2.931915E+0021 -1.727207E+0021  3.539961E+0022 -1.237101E+0022 -6.909727E+0021  1.122087E+0021 -6.175225E+0019
  6.118220E+0021  8.548402E+0021  1.151697E+0022  5.631756E+0021 -1.237101E+0022  2.111149E+0022  1.027891E+0022 -2.557957E+0021  1.329875E+0021
  3.563557E+0021  1.670038E+0021  7.588525E+0021  3.809586E+0021 -6.909727E+0021  1.027891E+0022  1.634027E+0022  3.711254E+0020  2.046571E+0021
 -1.070463E+0021  3.678508E+0020 -2.066942E+0021 -1.368996E+0021  1.122087E+0021 -2.557957E+0021  3.711254E+0020  1.200655E+0021  2.849658E+0020
  5.876341E+0020 -6.095755E+0020  1.190807E+0021  8.991867E+0020 -6.175225E+0019  1.329875E+0021  2.046571E+0021  2.849658E+0020  7.199492E+0020

[THEN]


\ --------------------------------------------------------------------------
\ Second example: Fit the FEXP function with a polynomial, over the interval
\                 0 < x < 0.5



\ Copied from HORNER.xxx; note N coeffients, not N+1 !

: }Horner ( &a n -- ) ( F: x -- y[x] )
	FRAME| a |
        0e
        0 SWAP 1- DO
		    a F*
		    DUP I } F@ F+
            -1 +LOOP
	DROP
	|FRAME ;

\ Evaluates and computes derivative of a polynomial
\ of the form  f(x) = A + B x + C x^2 + D x^3 + E x^4 + F x^5 + G x^6 + ...
\ The parameters A .. G .. are stored sequentially in a{ .
\ The derivatives dy/dA .. dy/dG .. are stored sequentially in dyda{ .
: fexps ( 'a 'dyda -- ) ( F: x -- y )
	FRAME| a |
	LOCALS| dyda{ a{ |

	a a{ #params/f }Horner

	1e
	  #params/f 0 DO FDUP dyda{ I } F!  a F*  LOOP
	FDROP

	|FRAME ;

: y-value ( F: x -- y )
	a{ #params/f }Horner ;

: cscale ( i -- ) ( F: -- delta )
	S>F F2/ #datapoints S>F F/ ;


TRUE [IF] ( For those without XY-PLOT)

3 CONSTANT red
0 VALUE    Color

: XY-PLOT ( 'x 'y n -- )
	LOCALS| n y{ x{ |
	n 0 DO  CR I 4 .R  x{ I } F@ F.  y{ I } F@ F.  LOOP ;

[THEN]


\ Run only once, overwrites y{
: TEST-EXPS ( -- )
	red TO Color
	#datapoints 0 DO x{ I } F@  y-value  y{ I } DUP F@ F- F!
		    LOOP
	x{ y{ #datapoints XY-PLOT ;


\ Find the n-th order polynomial to fit the function exp(x); 0 < x < 0.5
\ Note: allocates a lot, never frees, even overwrites already allocated.
: EXPS-SETUP
	1 TO #funcs

	&     x{ #datapoints }malloc malloc-fail?
	&     y{ #datapoints }malloc malloc-fail? OR
	&   sig{ #datapoints }malloc malloc-fail? OR
	&     a{ #funcs #params/f * }malloc malloc-fail? OR
	& lista{ #funcs #params/f * }malloc malloc-fail? OR

	& covar{{ #funcs #params/f * DUP }}malloc malloc-fail? OR
	& alpha{{ #funcs #params/f * DUP }}malloc malloc-fail? OR
	ABORT" FIND-COEFFS -- not enough core"

	spread F@  #datapoints 0 DO FDUP sig{ I } F!  LOOP FDROP

	#datapoints 0 DO  I cscale   x{ I } F!  LOOP

	#datapoints 0 DO  I cscale FEXP  y{ I } F!  LOOP

	CR ." The encoded function F(x) = exp(x) " CR

	#funcs #params/f * 0 DO 1e-4  a{ I } F! LOOP

	#funcs #params/f * 0 DO  I lista{ I } ! LOOP

	x{ y{ sig{ #datapoints
	a{ #funcs #params/f *  lista{ #funcs #params/f *
	covar{{ alpha{{ setup-marquardt ( lambda <- 0.001)

	mrqminimize ABORT" singular matrix (1)" ;


: EXPS? ( iter -- stop? )
	CR ." iter = " 6 .R
	." , chisq = " chisq F@ FS. ." lambda = " lambda F@ FS.
	EKEY? DUP IF EKEY DROP THEN ;

: .EXPS	chisq F@  0e lambda F! 		\ get the results
	mrqminimize IF exit-marquardt
		       TRUE ABORT" singular matrix (2)"
	          THEN
	chisq F!

	exit-marquardt

	CR CR ." Fitting FEXP with an " #params/f 0 .R ." -order polynomial"
	   CR ." Results, spread      : " spread F@ F.
	   CR ."          chi squared : " chisq F@ FS.
	   CR ." Parameters: "
	#funcs 0 DO CR  #params/f 0 DO a{ J #params/f * I + } F@ F.NICE
				  LOOP
	       LOOP ;

: FIND-EXPS
	& fexps      defines MrqFitter
	& EXPS-SETUP defines MRQ-SETUP
	& EXPS?      defines MRQ-STOP?
	& .EXPS      defines MRQ-RESULTS
	FIND-COEFFS ;

CR .( Try: 7 TO #params/f UNSURE  30 TO #datapoints FIND-EXPS)
CR .(      TEST-EXPS)


[THEN]

				( * End of File * )

