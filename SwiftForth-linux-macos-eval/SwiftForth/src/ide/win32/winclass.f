{ ====================================================================
winclass.f
A very simple class for general windows

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

?( A very simple class for general windows)

CLASS SIMPLEWINCLASS

   VARIABLE HANDLE
   VARIABLE OWNER
   VARIABLE DC

   : SIZES ( handle -- )   WM_SIZE 0 0 SendMessage DROP ;

   : RESIZE ( -- )   HANDLE @ SIZES ;

   : SHOW/HIDE ( show -- )
      HANDLE @ SWAP ShowWindow DROP
      RESIZE  OWNER @ SIZES ;

   : HIDE ( -- )   SW_HIDE SHOW/HIDE ;
   : SHOW ( -- )   SW_NORMAL SHOW/HIDE ;

   : SHOWN? ( -- flag )   HANDLE @ IsWindowVisible ;

   : CLOSE ( -- )   HANDLE @ WM_CLOSE 0 0 SendMessage DROP ;

   : HEIGHT ( -- height )
      SHOWN? IF HANDLE @ WINDOW-HEIGHT ELSE 0 THEN ;

   : SETFONT ( hfont -- )
      HANDLE @ WM_SETFONT ROT 1 SendMessage DROP ;

END-CLASS







