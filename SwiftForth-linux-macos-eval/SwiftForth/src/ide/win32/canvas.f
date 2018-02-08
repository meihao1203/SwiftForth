{ ====================================================================
CANVAS class for drawing

Copyright 2001  FORTH, Inc.
==================================================================== }

FUNCTION: TabbedTextOut ( hdc x y addr len n 'tabs origin -- len )
FUNCTION: PatBlt ( hdc x y cx cy rop -- bool )
FUNCTION: SetPixel ( hdc x y color -- result )  \ result is color or -1 on fail
FUNCTION: MoveToEx ( hdc x y 'old -- bool )
FUNCTION: LineTo ( hdc x y -- bool )

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS CANVAS

   SINGLE HDC

   : WHITEWASH ( rect -- )
      HDC SWAP @RECT WHITENESS PatBlt DROP ;

   : BLACKWASH ( rect -- )
      HDC SWAP @RECT BLACKNESS PatBlt DROP ;

   : SetPixel ( x y color -- )
      HDC 3 -ROLL SetPixel DROP ;

   : MoveTo ( x y -- )
      HDC ROT ROT 0 MoveToEx DROP ;

   : LineTo ( x y -- )
      HDC ROT ROT LineTo DROP ;

   : Line ( x y x y -- )
      MoveTo LineTo ;

   : Text ( x y addr len -- )
      HDC 4 -ROLL TextOut DROP ;

   : TabbedText ( x y addr len tabsize -- len )
      >R  HDC 4 -ROLL  1 RP@ 0 TabbedTextOut LOWORD  R> DROP ;

   : GetTextSize ( -- x y )
      [OBJECTS TEXTMETRIC MAKES TM OBJECTS]
      HDC TM ADDR GetTextMetrics DROP
      TM AveCharWidth @ TM Height @ TM ExternalLeading @ + ;

   : /HDC ( -- )   0 TO HDC ;

   DEFER: ATTACH ( dc -- )   TO HDC ;
   DEFER: DETACH ( -- )   /HDC ;

   : CONSTRUCT ( -- )   /HDC ;
   : DESTRUCT ( -- )   DETACH /HDC ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS PAINTSTRUCT
   VARIABLE dc
   VARIABLE Erase
   RECT BUILDS Paint
   VARIABLE Restore
   VARIABLE IncUpdate
   32 BUFFER: Reserved
END-CLASS

CANVAS SUBCLASS PAINTCANVAS

   SINGLE mHWND
   PAINTSTRUCT BUILDS ps

   : ATTACH ( hwnd -- )   TO mHWND
      mHWND ps ADDR BeginPaint  TO HDC ;

   : DETACH ( -- )
      mHWND ps ADDR EndPaint DROP ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CANVAS SUBCLASS MEMCANVAS

   : ATTACH ( dc -- )
      CreateCompatibleDC TO HDC ;

   : DETACH ( -- )
      HDC DeleteDC DROP  /HDC ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

MEMCANVAS SUBCLASS BITMAPCANVAS

   SINGLE HOLDBITMAP

   : ATTACH ( hdc hbitmap -- )
      >R  SUPER ATTACH  HDC R> SelectObject  TO HOLDBITMAP ;

   : DETACH ( -- )   SUPER DETACH  HDC HOLDBITMAP SelectObject DROP ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CANVAS SUBCLASS UPDATECANVAS

   SINGLE HW

   : ATTACH ( hwnd -- )   DUP TO HW  GetDC  TO HDC ;
   : DETACH ( -- )   HW HDC ReleaseDC DROP  0 TO HW  /HDC ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CLASS DC-OBJECT

   SINGLE DC
   SINGLE OLD
   SINGLE HANDLE

   : ATTACH ( dc -- )   TO DC ;
   : DETACH ( -- )   0 TO DC ;
   : CONSTRUCT ( -- )   0 TO DC ;
   : DESTRUCT ( -- )   DC -EXIT
      DC OLD SelectObject DeleteObject DROP ;

   : USE ( dc new -- )   DUP TO HANDLE
      DESTRUCT OVER TO DC  SelectObject TO OLD ;

END-CLASS

DC-OBJECT SUBCLASS CPEN     END-CLASS
DC-OBJECT SUBCLASS CBRUSH   END-CLASS
DC-OBJECT SUBCLASS CPALETTE END-CLASS

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DC-OBJECT SUBCLASS CFONT

   TEXTMETRIC BUILDS TM

   : METRICS ( -- )
      DC TM ADDR GetTextMetrics DROP ;

   : CHARW ( -- width )   METRICS  TM MaxCharWidth @ ;
   : CHARH ( -- height)    METRICS  TM Height @ TM ExternalLeading @ + ;

END-CLASS

