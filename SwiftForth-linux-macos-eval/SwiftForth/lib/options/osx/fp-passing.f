\ fp-passing.f
\ George Kozlowski  original: 9/22/2009
\ changes:
\ 12/01/2009: Used -? to eliminate announcement of duplication of names.
\ 9/26/2010: to eliminate DEMO change TRUE to FALSE at the end of this file 
{ ------------------------------------------------------------------------------------------
These words implement a floating point package for accessing
libraries on the mac.  They also work for linux by calling appropriate libs.

This implementation assumes a software stack.

ST0> transfers a df from the FPU to the fp-stack.
fstack>stack transfers a df from the fp-stack to the stack.
stack>fstack transfers a df from the stack to the fp-stack.
These operations are inverses of each other.  All are related
to similar ops in fpmath.f.
2fstack>stack and 4fstack>stack transfer 2 and 4 df's to the fp-stack.
These are useful for handling complex numbers which consist of two df's
stored on the fp-stack in the order: real-part imaginary-part.

See /usr/include/architecture/i386/math.h for more possibilities.
------------------------------------------------------------------------------------------ }

REQUIRES fpmath

ONLY FORTH DEFINITIONS

EXISTS --fp-passing-- [IF]  --fp-passing--  [THEN]
MARKER --fp-passing--

DECIMAL

ICODE ST0>  ( -- ; F: -- r )  \ from ST0 to fp-stack
   |NUMERIC| # 'N [U] SUB
   'N [U] EAX MOV
   0 [EAX] TBYTE FSTP
   RET END-CODE

CODE fstack>stack  ( -- d ; F: r -- )
   'N [U] EAX MOV					\ load fp-stack pointer
   0 [EAX] TBYTE FLD				\ 10-byte float
   |NUMERIC| # 'N [U] ADD			\ popped into fpu
   -12 [EBP] QWORD FSTP				\ 10->df stored in future stack space
   EBX -4 [EBP] DWORD MOV			\ leaving room for storing current tos
   -12 [EBP] ECX DWORD MOV			\ swap hi & lo dwords
   -8 [EBP] EBX DWORD MOV			\ lo dword to tos
   ECX -8 [EBP] DWORD MOV			\ finishing the swap
   8 # EBP SUB						\ not 12 because 4 bytes went to tos
   RET END-CODE

CODE 2fstack>stack  ( -- d d ; F: r r -- )
   'N [U] EAX MOV
   0 [EAX] TBYTE FLD
   |NUMERIC| # 'N [U] ADD
   -20 [EBP] QWORD FSTP
   EBX -4 [EBP] DWORD MOV
   10 [EAX] TBYTE FLD
   |NUMERIC| # 'N [U] ADD
   -12 [EBP] QWORD FSTP
   -8 [EBP] EBX DWORD MOV
   -12 [EBP] ECX DWORD MOV
   EBX -12 [EBP] MOV
   ECX -8 [EBP] MOV
   -20 [EBP] ECX DWORD MOV
   -16 [EBP] EBX DWORD MOV
   ECX -16 [EBP] DWORD MOV
   16 # EBP SUB
   RET END-CODE

CODE 4fstack>stack  ( -- d d d d ; F: r r r r -- )
   'N [U] EAX MOV
   0 [EAX] TBYTE FLD
   |NUMERIC| # 'N [U] ADD
   -36 [EBP] QWORD FSTP
   |NUMERIC| # 'N [U] ADD
   10 [EAX] TBYTE FLD
   -28 [EBP] QWORD FSTP
   |NUMERIC| # 'N [U] ADD
   20 [EAX] TBYTE FLD
   -20 [EBP] QWORD FSTP
   |NUMERIC| # 'N [U] ADD
   30 [EAX] TBYTE FLD
   EBX -4 [EBP] DWORD MOV
   -12 [EBP] QWORD FSTP
   -8 [EBP] EBX DWORD MOV
   -12 [EBP] ECX DWORD MOV
   EBX -12 [EBP] MOV
   ECX -8 [EBP] MOV
   -16 [EBP] EBX DWORD MOV
   -20 [EBP] ECX DWORD MOV
   EBX -20 [EBP] MOV
   ECX -16 [EBP] MOV
   -24 [EBP] EBX DWORD MOV
   -28 [EBP] ECX DWORD MOV
   EBX -28 [EBP] MOV
   ECX -24 [EBP] MOV
   -32 [EBP] EBX DWORD MOV
   -36 [EBP] ECX DWORD MOV
   ECX -32 [EBP] DWORD MOV
   32 # EBP SUB
   RET END-CODE

CODE stack>fstack  ( d -- ; F: -- r )
   |NUMERIC| # 'N [U] SUB
   0 [EBP] ECX DWORD MOV
   EBX 0 [EBP] DWORD MOV
   ECX -4 [EBP] DWORD MOV
   'N [U] EAX MOV
   -4 [EBP] QWORD FLD
   4 [EBP] EBX DWORD MOV
   0 [EAX] TBYTE FSTP
   8 # EBP ADD
   RET END-CODE

\ examples illustrating various calls

LIBRARY libstdc++.6.dylib		\ osx
\ LIBRARY libstdc++.so.6		\ linux

\ double drand48(void);
FUNCTION: drand48 ( -- )
-? : drand48  ( -- ; F: -- r )
   drand48   st0> ;
{ ---------------------------------------------------------------------------
drand48 f. 0.3186927  ok
drand48 f. 0.8864284  ok
drand48 f. 0.0155828  ok
--------------------------------------------------------------------------- }

LIBRARY libm.dylib				\ osx
\ LIBRARY libm.so				\ linux

\ extern double rint ( double );
FUNCTION: rint ( n n -- )
-? : rint  ( -- ; F: r -- r )
   fstack>stack   rint   st0> ;
{ ---------------------------------------------------------------------------
3.6e0 rint f. 3.0000000  ok
4.5e0 rint f. 4.0000000  ok
--------------------------------------------------------------------------- }

\ extern double  cbrt( double );
FUNCTION: cbrt ( n n -- )
-? : cbrt  ( -- ; F: r -- r )
   fstack>stack   cbrt   st0> ;
{ ---------------------------------------------------------------------------
1000e0 cbrt f. 10.000000  ok
--------------------------------------------------------------------------- }

\ extern double j0 ( double );
FUNCTION: j0 ( n n -- )
-? : j0  ( -- ; F: r -- r )
   fstack>stack   j0   st0> ;
{ ---------------------------------------------------------------------------
2e0 j0 f. 0.2238907  ok
3e0 j0 f. -0.2600519  ok
--------------------------------------------------------------------------- }

\ extern double j1 ( double );
FUNCTION: j1 ( n n -- )
-? : j1  ( -- ; F: r -- r )
   fstack>stack   j1   st0> ;
{ ---------------------------------------------------------------------------
3e0 j1 f. 0.3390589  ok
4e0 j1 f. -0.0660433  ok
--------------------------------------------------------------------------- }

\ extern double jn ( int, double );
FUNCTION: jn ( n n n -- )
-? : jn  ( n -- ; F: r -- r )
   fstack>stack   jn   st0> ;
{ ---------------------------------------------------------------------------
4e0 1 jn f. -0.0660433  ok
0 3e0 jn f. -0.2600519  ok
--------------------------------------------------------------------------- }

\ extern double pow ( double, double );
FUNCTION: pow ( n n n n -- )
-? : pow  ( -- ; F: r r -- r )
   2fstack>stack   pow   st0> ;
{ ---------------------------------------------------------------------------
2e0 3e0 pow f. 8.0000000  ok
--------------------------------------------------------------------------- }

\ extern double hypot ( double, double );
FUNCTION: hypot ( n n n n -- )
-? : hypot  ( -- ; F: r r -- r )
   2fstack>stack   hypot   st0> ;
{ ---------------------------------------------------------------------------
3e0 4e0 hypot f. 5.0000000  ok
--------------------------------------------------------------------------- }

{ ---------------------------------------------------------------------------
     double
     remquo(double x, double y, int *quo);

The remquo() function computes the value r such that r = x - n*y, where n
is the integer nearest the exact value of x/y.
If there are two integers closest to x/y, n shall be the even one. If r
is zero, it is given the same sign as x.  This is the same value that is
returned by the remainder() function.  remquo() also calculates the lower
seven bits of the integral quotient x/y, and gives that value the same
sign as x/y. It stores this signed value in the object pointed to by quo.
--------------------------------------------------------------------------- }

\ extern double remquo ( double, double, int * );
\ N.B. The anticipated integer return should not exceed 7
\ If it does, the integer actually returned has been ANDed with 7
\ Again we have to pay attention to stack order.
\ Note also that 0 reserves a place on the stack for the integer return.
FUNCTION: remquo  ( n n n n a -- )
-? : remquo  ( -- n ; F: r r -- r )
   0 SP@ >R 2fstack>stack R>   remquo   st0> ;
{ ---------------------------------------------------------------------------
123e0 20e0 remquo .s
6 <-Top 3.0000000 <-NTop  ok
f. 3.0000000  ok
. 6  ok
--------------------------------------------------------------------------- }

\ extern double  tgamma( double );
FUNCTION: tgamma  ( n n -- )
-? : tgamma  ( -- ; F: r -- r )
   fstack>stack   tgamma   st0> ;
{ ---------------------------------------------------------------------------
5e0 tgamma f. 24.000000  ok
4e0 tgamma f. 6.0000000  ok
3e0 tgamma f. 2.0000000  ok
2e0 tgamma f. 1.0000000  ok
--------------------------------------------------------------------------- }

\ extern double  lgamma( double );
FUNCTION: lgamma  ( n n -- )
-? : lgamma  ( -- ; F: r -- r )
   fstack>stack   lgamma   st0> ;
{ ---------------------------------------------------------------------------
1e0 lgamma f. 00.000000  ok
2e0 lgamma f. 00.000000  ok
3e0 lgamma f. 0.6931471  ok
4e0 lgamma f. 1.7917594  ok
--------------------------------------------------------------------------- }

\ extern double lgamma_r ( double, int * )
\ AVAILABLE_MAC_OS_X_VERSION_10_6_AND_LATER;
\ paying attention to stack order.
\ 0 reserves a place on the stack for the integer return.
FUNCTION: lgamma_r  ( n n a -- )
-? : lgamma_r  ( -- n ; F: r -- r )
   0 SP@ >R fstack>stack R>   lgamma_r   st0> ;
{ ---------------------------------------------------------------------------
1e0 lgamma_r . f. 1 00.000000  ok
2e0 lgamma_r . f. 1 00.000000  ok                                              
3e0 lgamma_r . f. 1 0.6931471  ok                                              
4e0 lgamma_r . f. 1 1.7917594  ok                                              
--------------------------------------------------------------------------- }

\ extern double cabs( double complex );
FUNCTION: cabs  ( n n n n -- )
-? : cabs  ( -- ; F: r r -- r )
   2fstack>stack   cabs   st0> ;
{ ---------------------------------------------------------------------------
3e0 -4e0 cabs f. 5.0000000  ok
--------------------------------------------------------------------------- }
\ extern double carg( double complex );
FUNCTION: carg  ( n n n n -- )
-? : carg  ( -- ; F: r r -- r )
   2fstack>stack   carg   st0> ;
{ ---------------------------------------------------------------------------
1e0 -1e0 carg f. -0.7853981  ok
-1e0 0e0 carg f. 3.1415926  ok
--------------------------------------------------------------------------- }
\ extern double cimag( double complex );
FUNCTION: cimag  ( n n n n -- )
-? : cimag  ( -- ; F: r r -- r )
   2fstack>stack   cimag   st0> ;
{ ---------------------------------------------------------------------------
3e0 -4e0 cimag f. -4.0000000  ok
--------------------------------------------------------------------------- }
\ extern double creal( double complex );
FUNCTION: creal  ( n n n n -- )
-? : creal  ( -- ; F: r r -- r )
   2fstack>stack   creal   st0> ;
{ ---------------------------------------------------------------------------
3e0 -4e0 creal f. 3.0000000  ok
--------------------------------------------------------------------------- }
TRUE [IF]  \ osx
: allot-aligned  ( child compile time: n -- ; child run time: -- addr )
   CREATE   HERE CELL+ DUP DUP $F +  $FFFFFFF0 AND
            DUP ( aligned address ) ,
            SWAP - ROT +  DUP ( no. of bytes ) ALLOT   ERASE
   DOES>   @ ( the aligned address ) ;

\ sample usage:
2 DFLOATS allot-aligned f-buf
[ELSE]  \ linux
CREATE f-buf   2 DFLOATS ALLOT   f-buf 2 DFLOATS ERASE
[THEN]

\ extern double complex conj( double complex );
\ the parameters passed to conj are in the order ( a n0 n1 n2 n3 )
\ with a the address of the buffer for the complex number returned
\ by conj.

FUNCTION: conj  ( a n0 n1 n2 n3 -- a )
: <conj>  ( -- a ; F: r r -- )
   f-buf 2fstack>stack   conj ;
-? : conj  ( -- ; F: r r -- r r )
   <conj>   DUP F@   FLOAT+ F@ ;
{ ---------------------------------------------------------------------------
2e0 -4e0 conj f. f. 4.0000000 2.0000000 ok               
--------------------------------------------------------------------------- }

FUNCTION: cexp  ( a n0 n1 n2 n3 -- a )
: <cexp>  ( -- a ; F: r r -- )
   f-buf 2fstack>stack   cexp ;
-? : cexp  ( -- ; F: r r -- r r )
   <cexp>   DUP F@   FLOAT+ F@ ;
{ ---------------------------------------------------------------------------
1e0 0e0 cexp f. f. 00.000000 2.7182818  ok         
2e0 -1e0 cexp f. f. -6.2176763 3.9923240  ok                         
--------------------------------------------------------------------------- }

FUNCTION: cpow  ( a n0 n1 n2 n3 n4 n5 n6 n7 -- a )
: <cpow>  ( -- a ; F: r r r r -- )
   f-buf 4fstack>stack   cpow ;
-? : cpow  ( -- ; F: r r r r -- r r )
   <cpow>   DUP F@   FLOAT+ F@ ;
{ ---------------------------------------------------------------------------
2e0 0e0 3e0 0e0 cpow f. f. 00.000000 7.9999999  ok                             
2e0 -1e0 3e0 -4e0 cpow f. f. 1.7407165 -0.1791746  ok                          
--------------------------------------------------------------------------- }

TRUE [IF]  \ want a demo
: DEMO  ( -- )
CR ." random real numbers:"
CR ." drand48 f. "  drand48 f.
CR ." drand48 f. "  drand48 f.
CR ." drand48 f. "  drand48 f.
CR ." rounding to real integer:"
CR ." 3.6e0 rint f. 3.0000000  check: " 3.6e0 rint f.
CR ." 4.5e0 rint f. 4.0000000  check: " 4.5e0 rint f.
CR ." cube root:"
CR ." 1000e0 cbrt f. 10.000000  check: " 1000e0 cbrt f.
CR ." Bessel function of first kind of order zero:"
CR ." 2e0 j0 f. 0.2238907  check: " 2e0 j0 f. 
CR ." 3e0 j0 f. -0.2600519  check: " 3e0 j0 f.
CR ." Bessel function of first kind of order one:"
CR ." 3e0 j1 f. 0.3390589  check: " 3e0 j1 f.
CR ." 4e0 j1 f. -0.0660433  check: " 4e0 j1 f.
CR ." Bessel function of first kind of order n:"
CR ." 4e0 1 jn f. -0.0660433  check: " 4e0 1 jn f.
CR ." 0 3e0 jn f. -0.2600519  check: " 0 3e0 jn f.
CR ." x y -> x to the power y:"
CR ." 2e0 3e0 pow f. 8.0000000  check: " 2e0 3e0 pow f.
CR ." hypotenuse:"
CR ." 3e0 4e0 hypot f. 5.0000000  check: " 3e0 4e0 hypot f.
CR ." remquo:"
CR ." 123e0 20e0 remquo .s" 123e0 20e0 remquo .s
CR ." 6 <-Top 3.0000000 <-NTop  check: "
CR ." f. 3.0000000  check: " f.
CR ." . 6  check: " .
CR ." Gamma function"
CR ." 5e0 tgamma f. 24.000000  check: " 5e0 tgamma f.
CR ." 4e0 tgamma f. 6.0000000  check: " 4e0 tgamma f.
CR ." 3e0 tgamma f. 2.0000000  check: " 3e0 tgamma f.
CR ." 2e0 tgamma f. 1.0000000  check: " 2e0 tgamma f.
CR ." natural log of the Gamma function"
CR ." 1e0 lgamma f. 00.000000  check: " 1e0 lgamma f.
CR ." 2e0 lgamma f. 00.000000  check: " 2e0 lgamma f.
CR ." 3e0 lgamma f. 0.6931471  check: " 3e0 lgamma f.
CR ." 4e0 lgamma f. 1.7917594  check: " 4e0 lgamma f.
\ comment out the lgamma_r stuff in linux
CR ." thread-safe lgamma_r; see man page:"
CR ." 1e0 lgamma_r . f. 1 00.000000  check: " 1e0 lgamma_r . f.
CR ." 2e0 lgamma_r . f. 1 00.000000  check: " 2e0 lgamma_r . f.                                        
CR ." 3e0 lgamma_r . f. 1 0.6931471  check: " 3e0 lgamma_r . f.                            
CR ." 4e0 lgamma_r . f. 1 1.7917594  check: " 4e0 lgamma_r . f.                            
CR ." abs of a complex number:"
CR ." 3e0 -4e0 cabs f. 5.0000000  check: " 3e0 -4e0 cabs f.
CR ." argument (angle) of a complex number:"
CR ." 1e0 -1e0 carg f. -0.7853981  check: " 1e0 -1e0 carg f.
CR ." -1e0 0e0 carg f. 3.1415926  check: " -1e0 0e0 carg f.
CR ." imaginary part:"
CR ." 3e0 -4e0 cimag f. -4.0000000  check: " 3e0 -4e0 cimag f.
CR ." real part:"
CR ." 3e0 -4e0 creal f. 3.0000000  check: " 3e0 -4e0 creal f.
CR ." conjugate:"
CR ." 2e0 -4e0 conj f. f. 4.0000000 2.0000000 check: " 2e0 -4e0 conj f. f.         
CR ." complex exponential:"
CR ." 1e0 0e0 cexp f. f. 00.000000 2.7182818  check: " 1e0 0e0 cexp f. f.      
CR ." 2e0 -1e0 cexp f. f. -6.2176763 3.9923240  check: " 2e0 -1e0 cexp f. f.                     
CR ." power function:"
CR ." 2e0 0e0 3e0 0e0 cpow f. f. 00.000000 7.9999999  check: " 2e0 0e0 3e0 0e0 cpow f. f.                          
CR ." 2e0 -1e0 3e0 -4e0 cpow f. f. 1.7407165 -0.1791746  check: " 2e0 -1e0 3e0 -4e0 cpow f. f.                      
;

CR .( try DEMO)
[THEN]