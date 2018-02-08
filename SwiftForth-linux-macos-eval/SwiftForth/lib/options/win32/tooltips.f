OPTIONAL TOOLTIPS Support for the tooltip control

{ ======================================================================
Tooltips for windows

Author: Rick VanNorman
Initial release: 12 Jun 2011
====================================================================== }

CLASS TOOLINFO
   VARIABLE SIZE
   VARIABLE FLAGS
   VARIABLE OWNER
   VARIABLE ID
   RECT BUILDS R
   VARIABLE HINST
   VARIABLE 'TEXT
END-CLASS

TOOLINFO SUBCLASS TOOLTIPS

   SINGLE mHWND

   : CONSTRUCT ( -- )
      THIS SIZEOF SIZE ! ;

   : CREATE-TIPCONTROL ( owner -- htip )
      >R  InitCommonControls DROP
      0 Z" tooltips_class32" 0 TTS_ALWAYSTIP
      CW_USEDEFAULT CW_USEDEFAULT CW_USEDEFAULT CW_USEDEFAULT
      R>  0 HINST 0 CreateWindowEx  TO mHWND ;

   : ATTACH ( hwnd -- )
      DUP CREATE-TIPCONTROL  OWNER !  THIS SIZEOF SIZE ! ;

   : ADD-TIP ( -- )
      mHWND TTM_ADDTOOLA 0 ADDR SendMessage DROP ;

END-CLASS
