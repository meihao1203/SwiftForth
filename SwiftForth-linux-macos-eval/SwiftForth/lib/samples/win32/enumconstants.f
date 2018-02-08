{ ====================================================================
List wincon.dll constants

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL ENUMCONST Enumerate the constants from WINCON.DLL

LIBRARY WINCON

:NONAME ( -- res )   OPERATOR'S
   CR _PARAM_2 8 H.0 ."  EQU " _PARAM_0 _PARAM_1 TYPE
   1 ;  3 CB: EQU-ENUMERATE

: .EQUATES ( -- )       \ output an equates list for swiftx
   CR ." 499 STRANDS WID:VOC WINCONS"
   CR ." WINCONS DEFINITIONS"
   PAD 0 EQU-ENUMERATE EnumWin32Constants
   CR ." ( " . ."  constants) "
   CR ." FORTH DEFINITIONS" ;

:NONAME ( -- res )   OPERATOR'S
   _PARAM_0 _PARAM_1 ?TYPE SPACE SPACE 1 ;  3 CB: ENUMERATE

: CONSTANTS ( -- )
   BL WORD COUNT ENUMERATE EnumWin32Constants DROP ;

.(
Type CONSTANTS to see all of the windows constants defined in WINCON.DLL .
Type CONSTANTS <pat> to see all constants that contain pattern <pat>.
For example:

        CONSTANTS CS_

will display all constants which contain the string CS_ . Note that
the pattern recognition is case sensitive, and that most of these constants
are uppercase.
)
