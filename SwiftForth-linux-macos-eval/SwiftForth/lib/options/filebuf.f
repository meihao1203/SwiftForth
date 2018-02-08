{ ----------------------------------------------------------------------
Buffered file output

Copyright (C) 2006 FORTH, Inc.  All rights reserved.
---------------------------------------------------------------------- }

OPTIONAL FILEBUF A buffered file output class for simple fast file output

CLASS BUFFERED-FILE-OUTPUT

PUBLIC

   10240 CONSTANT SIZE

PRIVATE

   VARIABLE FID             \ file id to write
   VARIABLE BUFFER          \ address of buffer ALLOCATE-ed
   VARIABLE POINTER         \ pointer into the buffer
   VARIABLE ERR             \ last error noticed
   VARIABLE WRITTEN         \ number of bytes written

   \ write a string to the file.

   : WRITE-DATA ( addr len -- )
      TUCK  FID @ WRITE-FILE ERR !  WRITTEN +! ;

   \ abort gracelessly if the buffer isn't valid.

   : ?BUFFER ( -- )
      BUFFER @ SIZE IsBadWritePtr THROW ;

   \ if there is content in the buffer, write it to the file
   \ and zero the buffer pointer.

   : FLUSH-BUFFER ( -- )   ?BUFFER
      POINTER @ IF
         BUFFER @ POINTER @ WRITE-DATA  0 POINTER !
      THEN ;

   \ true if the new string will not fit in the buffer.

   : FULL? ( len -- flag )
      POINTER @ +  SIZE >= ;

PUBLIC

   \ write a string either to the buffer or directly to the
   \ file. flush if needed.

   : WRITE ( addr len -- )   ?BUFFER
      DUP SIZE > IF
         FLUSH-BUFFER  WRITE-DATA
      ELSE
        DUP FULL? IF FLUSH-BUFFER THEN
        TUCK  POINTER @ BUFFER @ + SWAP CMOVE  POINTER +!
      THEN ;

   \ flush and close any open file

   : CLOSE ( -- )
      FID @ IF
         FLUSH-BUFFER  FID @ CLOSE-FILE ERR !  0 FID !
      THEN ;

   \ open a new file for writing. close previous file if still open.

   : OPEN ( addr len -- )
      CLOSE  APPEND-FILE THROW  FID !  0 POINTER !  0 WRITTEN ! ;

   \ initialize when object is created. allocate memory, etc.

   : CONSTRUCT ( -- )
      SIZE ALLOCATE THROW BUFFER !
      0 FID !  0 POINTER !  0 WRITTEN !  0 ERR ! ;

   \ clean up when object is destroyed, release memory, etc.

   : DESTROY ( -- )
      CLOSE   BUFFER @ FREE DROP  0 BUFFER !  ;

END-CLASS

\\

{ ----------------------------------------------------------------------
Build a simple set of tests for fileout.
The images won't be exactly the same because of the nature
of the swiftforth kernel which is being written, but they
will be really close!
---------------------------------------------------------------------- }

BUFFERED-FILE-OUTPUT BUILDS FOUT
FOUT CONSTRUCT

: TEST1 ( -- )
   S" IMAGE1" FOUT OPEN
   HERE ORIGIN DO
      I 4000 FOUT WRITE
   4000 +LOOP
   FOUT CLOSE ;

: TEST2 ( -- )
   S" IMAGE2" FOUT OPEN
   HERE ORIGIN DO
      I 3141 FOUT WRITE
   3141 +LOOP
   FOUT CLOSE ;

: TEST3 ( -- )
   S" IMAGE3" FOUT OPEN
   ORIGIN HERE OVER - FOUT WRITE
   FOUT CLOSE ;

: TEST4 ( -- )
   S" IMAGE4" R/W CREATE-FILE THROW >R
   ORIGIN HERE OVER - R@ WRITE-FILE THROW
   R> CLOSE-FILE DROP ;

: TRY ( -- )   TEST1 TEST2 TEST3 TEST4 ;
