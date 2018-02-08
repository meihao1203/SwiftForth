{ ====================================================================
File extensions

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

Non-ANS file operations supplied for application support.

==================================================================== }

{ ----------------------------------------------------------------------
COPY-FILE and COPY-REPLACE-FILE copy named files
---------------------------------------------------------------------- }

: COPY-FILE ( caddr1 u1 caddr2 u2 -- ior )
   R-BUF R@ ZPLACE  R>  -ROT
   R-BUF R@ ZPLACE  R>  SWAP 1 CopyFile 0= -192 AND ;

: COPY-REPLACE-FILE ( caddr1 u1 caddr2 u2 -- ior )
   R-BUF R@ ZPLACE  R>  -ROT
   R-BUF R@ ZPLACE  R>  SWAP 0 CopyFile 0= -192 AND ;

{ --------------------------------------------------------------------
SEEK-FILE allows relative positioning of the file read/write pointer
-------------------------------------------------------------------- }

: SEEK-FILE ( ud mode fileid -- ior )
   ROT >R ( l m f) -ROT RP@ SWAP SetFilePointer R>2DROP 0 ;

\ ----------------------------------------------------------------------
\\ \\\\ 
\\\ \\\ 
\\\\ \\ 
\\\\\ \ 

s" test.txt" r/w create-file drop value z
: try pad 1 z read-file 2drop pad 10 dump ;
s" 0123456789abcdef" z write-file drop

4. FILE_BEGIN Z SEEK-FILE drop try
\ 47DF38 34 00 00 00 00 00 00 00 00 00                   4.........

4. FILE_CURRENT Z SEEK-FILE drop try
\ 47DF38 39 00 00 00 00 00 00 00 00 00                   9.........

-4.  FILE_CURRENT Z SEEK-FILE drop try
\ 47DF86 36 00 00 00 00 00 00 00 00 00                   6.........

-4.  FILE_CURRENT Z SEEK-FILE drop try
\ 47DF38 33 00 00 00 00 00 00 00 00 00                   3.........

-3. FILE_END Z SEEK-FILE drop try
\ 47DF38 64 00 00 00 00 00 00 00 00 00                   d.........

try
\ 47DF38 65 00 00 00 00 00 00 00 00 00                   e.........

-3. FILE_END Z SEEK-FILE drop try
\ 47DF38 64 00 00 00 00 00 00 00 00 00                   d.........

-2. FILE_END Z SEEK-FILE drop try
\ 47DF38 65 00 00 00 00 00 00 00 00 00                   e.........

-1. FILE_END Z SEEK-FILE drop try
\ 47DF38 66 00 00 00 00 00 00 00 00 00                   f.........

0. FILE_END Z SEEK-FILE drop try
\ 47DF38 66 00 00 00 00 00 00 00 00 00                   f.........

z close-file drop
0 to z
