{ =====================================================================
sfbench.f
Copyright (c) 1972-1999, FORTH, Inc.

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
===================================================================== }

{ --------------------------------------------------------------------
These simple benchmarks are used for comparisons of FORTH, Inc.
implementations.  Execute BENCHMARK to run all of them.  Timing is
only as accurate as the granularity of the target's millisecond
counter.

Requires: OPTIONAL REQUIRES IN PAGE .(

Exports: BENCHMARK
-------------------------------------------------------------------- }

OPTIONAL BENCHMARKS A set of 32 bit benchmarks for SwiftForth

REQUIRES parts          \ Block file support

   1 IN BENCH.SRC CONSTANT TEST-BLOCK

REQUIRES bench           \ Core benchmarks
REQUIRES bench2          \ Highlevel benchmarks

-? : BENCHMARK ( -- )   PAGE  BENCHMARK  CR  CR  ." Tests complete!" ;

BENCHMARK .(   To run them again, type BENCHMARK )
