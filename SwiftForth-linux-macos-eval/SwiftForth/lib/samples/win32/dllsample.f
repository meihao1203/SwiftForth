{ ====================================================================
Simple DLL exporting calculator-type functions

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL DLLSAMPLE A simple DLL exporting calculator-type functions

[DEFINED] PROGRAM-SEALED [IF]

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

EMPTY
ONLY FORTH ALSO DEFINITIONS DECIMAL

: SQ ( n1 -- n2 )   DUP * ;

AS Square       1 EXPORT: SQ
AS Plus         2 EXPORT: +
AS Minus        2 EXPORT: -
AS Times        2 EXPORT: *
AS Divide       2 EXPORT: /

PROGRAM-SEALED CALC.DLL

{ --------------------------------------------------------------------
Test the DLL we just saved
-------------------------------------------------------------------- }

EMPTY  ONLY FORTH  ALSO DEFINITIONS

LIBRARY CALC

FUNCTION: Square ( n1 -- n2 )
FUNCTION: Plus ( n1 n2 -- n3 )
FUNCTION: Minus ( n1 n2 -- n3 )
FUNCTION: Times ( n1 n2 -- n3 )
FUNCTION: Divide ( n1 n2 -- n3 )

: TEST ( -- )
   3 5 Plus 8 Times . ;

CR
CR .( By loading this file, you have saved CALC.DLL. This library)
CR .( exports five simple calculator-like functions. Type TEST to)
CR .( exercise the dll.)
CR

[ELSE]

CR
.( This demo is not available for the SwiftForth Evaluation version)
CR

[THEN]
