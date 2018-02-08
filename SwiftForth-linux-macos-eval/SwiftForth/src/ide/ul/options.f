{ ====================================================================
Optional included files

Copyright (C) 2008 FORTH, Inc.  All rights reserved

Optional packages are loaded only once. They may be included as
normal, or via REQUIRES, or via the optional packages menu/dialog.

OPTIONAL <name> <descriptive text, one line, less than 200 chars>

While including a file:

If name exists in the LOADED-OPTIONS wordlist, ignore the rest of the
file.  If name does not exist in the LOADED-OPTIONS wordlist, construct
a dictionary entry for name there and ignore the rest of the line.

While not including a file:

All text to the end of the line will be treated as a comment.
OPTIONAL is valid only while including a file.
==================================================================== }

PACKAGE OPTIONAL-STUFF

1 STRANDS CONSTANT LOADED-OPTIONS

: OPTION-LOADED? ( addr len -- flag )
   LOADED-OPTIONS SEARCH-WORDLIST DUP IF NIP THEN ;

PUBLIC

: OPTIONAL ( -- )
   SOURCE=FILE IF
      BL WORD COUNT 2DUP OPTION-LOADED? IF
         2DROP \\ EXIT
      THEN
      LOADED-OPTIONS (WID-CREATE)
      /SOURCE STRING,
   THEN POSTPONE \ ;

END-PACKAGE
