{ ====================================================================
Environment queries

Copyright (C) 2001 FORTH, Inc.  All rights reserved.

This file implements ANS environment queries.
==================================================================== }

?( ... Environment queries)

{ --------------------------------------------------------------------
ENVIRONMENT? is implemented as a wordlist, which is scanned by the
query for executable entities.
-------------------------------------------------------------------- }

/FORTH

PACKAGE ENVIRONMENT-WORDLIST

                255  CONSTANT /COUNTED-STRING
                 68  CONSTANT /HOLD
                256  CONSTANT /PAD
                  8  CONSTANT ADDRESS-UNIT-BITS
               TRUE  CONSTANT CORE
              FALSE  CONSTANT CORE-EXT
              FALSE  CONSTANT FLOORED
                255  CONSTANT MAX-CHAR
$FFFFFFFF $7FFFFFFF 2CONSTANT MAX-D
          $7FFFFFFF  CONSTANT MAX-N
          $FFFFFFFF  CONSTANT MAX-U
$FFFFFFFF $FFFFFFFF 2CONSTANT MAX-UD
               4096  CONSTANT RETURN-STACK-CELLS
               1024  CONSTANT STACK-CELLS

               TRUE  CONSTANT DOUBLE
               TRUE  CONSTANT DOUBLE-EXT

               TRUE  CONSTANT EXCEPTION
               TRUE  CONSTANT EXCEPTION-EXT

               TRUE  CONSTANT FACILITY
               TRUE  CONSTANT FACILITY-EXT

               TRUE  CONSTANT FILE
               TRUE  CONSTANT FILE-EXT

               TRUE  CONSTANT LOCALS
            #LOCALS  CONSTANT #LOCALS
               TRUE  CONSTANT LOCALS-EXT

               TRUE  CONSTANT MEMORY-ALLOC
              FALSE  CONSTANT MEMORY-ALLOC-EXT  \ The MEMORY-ALLOC-EXT word set has no members

               TRUE  CONSTANT TOOLS
              FALSE  CONSTANT TOOLS-EXT

               TRUE  CONSTANT SEARCH-ORDER
               TRUE  CONSTANT SEARCH-ORDER-EXT
              #VOCS  CONSTANT WORDLISTS

               TRUE  CONSTANT STRING
              FALSE  CONSTANT STRING-EXT        \ The STRING-EXT word set has no members

PUBLIC

: ENVIRONMENT? ( c-addr u -- false | i*x true )
   ENVIRONMENT-WORDLIST SEARCH-WORDLIST DUP IF >R EXECUTE R> THEN ;

: [ENVIRONMENT?] ( "name" -- false | i*x true )
   PARSE-WORD ENVIRONMENT? ;

END-PACKAGE
