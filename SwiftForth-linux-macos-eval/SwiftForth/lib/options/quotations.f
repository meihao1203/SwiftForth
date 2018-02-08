{ ====================================================================
Quotations

Copyright 2016 by FORTH, Inc.

==================================================================== }

OPTIONAL QUOTATIONS Nested quotations inside colon definitions

{ --------------------------------------------------------------------
Quotations

[:  suspends compiling to the current definition, starts a new nested
definition with execution token xt, and compilation continues with
this nested definition. Locals may be defined in the nested
definition.  An ambiguous condition exists if a name is used that
satisfies the following constraints: 1) It is not the name of a
currently visible local of the current quotation.  2) It is the name
of a local that was visible right before the start of the present
quotation or any of the containing quotations.

;]  ends the current nested definition, and resumes compilation to the
previous (containing) current definition. It appends the following
run-time to the (containing) current definition:

  run-time: ( -- xt )

  xt is the execution token of the nested definition.
-------------------------------------------------------------------- }

LOCAL-VARIABLES SIZEOF CONSTANT |LVAR|          \ Size of compile-time locals structure
LOCAL-OBJECTS SIZEOF CONSTANT |LOBJ|            \ Size of compile-time objects structure

: [: ( -- addr1 addr2 addr3 addr4 )
   |LVAR| ALLOCATE THROW  LVAR-COMP OVER |LVAR| MOVE    \ Save our local variables
   |LOBJ| ALLOCATE THROW  LOBJ-COMP OVER |LOBJ| MOVE    \ Save our local objects
   LAST 2 CELLS + @  POSTPONE AHEAD                     \ Save last code address, forward branch
   HERE LAST 2 CELLS + !  /LOCALS                       \ Last code address points to our quotation
;  IMMEDIATE

: ;] ( addr1 addr2 addr3 addr4 -- )
   POSTPONE EXIT  POSTPONE THEN                 \ Branch over the quotation
   LAST 2 CELLS + @ CODE>  POSTPONE LITERAL     \ Quotation xt for runtime
   LAST 2 CELLS + !                             \ Restore outer def code addr
   DUP LOBJ-COMP |LOBJ| MOVE  FREE THROW        \ Restore local objects
   DUP LVAR-COMP |LVAR| MOVE  FREE THROW        \ Restore local variables
;  IMMEDIATE
