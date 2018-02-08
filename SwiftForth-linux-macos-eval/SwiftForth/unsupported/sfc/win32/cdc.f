OPTIONAL CDC A class defining device-context objects.

{ ====================================================================
CDC class defines a class of device-context objects.

Copyright (c) 1972-1999, FORTH, Inc.

The CDC object provides member functions for working with a device
context, such as a display or printer, as well as members for working
with a display context associated with the client area of a window.

Requires: CGdiObject

Exports: see MFC documentation

==================================================================== }

REQUIRES CGdiObject

4 IMPORT: MoveToEx
3 IMPORT: LineTo
1 IMPORT: GetROP2
2 IMPORT: SetROP2
5 IMPORT: Ellipse
5 IMPORT: Rectangle

\ a point class with get and set members.

POINT SUBCLASS CPoint
   : Get ( -- x y )   x @ y @ ;
   : Set ( x y -- )   y ! x ! ;
END-CLASS

RECT SUBCLASS CRect
   : Get ( -- left top right bottom )   left @ top @ right @ bottom @ ;
   : Set ( left top right bottom -- )   bottom ! right ! top ! left ! ;
END-CLASS

CGdiObject BUILDS CTempObject

CPoint BUILDS CTempPoint

CObject SUBCLASS CDC

PUBLIC

\ Data Members
   VARIABLE m_hDC
   VARIABLE m_hAttribDC

\ Initialization
   : Attach ( hDC -- flag )   DUP m_hDC !  m_hAttribDC !  TRUE ;

   : Detach ( -- )   0 m_hDC !  0 m_hAttribDC ! ;

   : CreateDC ( lpszDriverName lpszDeviceName lpszOutput
                lpInitData -- flag )   N/I ;

   : CreateIC ( lpszDriverName lpszDeviceName lpszOutput
                lpInitData -- flag )   N/I ;

   : CreateCompatibleDC ( pDC -- flag )   N/I ;

   : DeleteDC ( -- )   m_hDC @ DeleteDC DROP ;

   : FromHandle ( hDC -- CDC )   N/I ;

   : DeleteTempMap ( -- )   N/I ;

   : SetAttribDC ( hDC -- )   m_hAttribDC ! ;

   : SetOutputDC ( hDC -- )   m_hDC ! ;

   : ReleaseAttribDC ( -- )   0 m_hAttribDC ! ;

   : ReleaseOutputDC ( -- )   0 m_hDC ! ;

   : GetCurrentBitmap ( -- CBitMap )   N/I ;

   : GetCurrentBrush ( -- CBrush )   N/I ;

   : GetCurrentFont ( -- CFont )   N/I ;

   : GetCurrentPalette ( -- CPalette )   N/I ;

   : GetCurrentPen ( -- CPen )   N/I ;

   : GetWindow ( -- CWnd )   N/I ;

\ Device-Context Functions
   : GetSafeHdc ( -- hDC )   m_hDC @ ?DUP ?EXIT  N/I ;

   : SaveDC ( -- nSavedDC )   N/I ;

   : RestoreDC ( nSavedDC -- flag )   N/I ;

   : ResetDC ( lpDevMode -- flag )   N/I ;

   : GetDeviceCaps ( nIndex -- n )
      m_hDC @ SWAP COMMON GetDeviceCaps ;

   : IsPrinting ( -- flag )   FALSE ;

\ Drawing-Tool Functions
   : GetBrushOrg ( -- CPoint )   N/I ;

   : SetBrushOrg ( x y | CPoint -- CPoint )   N/I ;

   : EnumObjects ( nObjectType lpfn lpData -- n )   N/I ;

\ Type-Safe Selection Helpers
   : SelectObject ( pObject -- pObject )
      [OBJECTS  CGdiObject NAMES pObject  OBJECTS]
      m_hDC @  pObject m_hObject @
      COMMON SelectObject  CTempObject Attach
      CTempObject ADDR ;

   : SelectStockObject ( nIndex -- pObject )
      CTempObject CreateStockObject
      CTempObject ADDR SelectObject ;

\ Color and Color Palette Functions
   : GetNearestColor ( crColor -- crColor )   N/I ;

   : SelectPalette ( CPalette bForceBackground -- CPalette )   N/I ;

   : RealizePalette ( -- n )   N/I ;

   : UpdateColors ( -- )   N/I ;

   : GetHalftoneBrush ( -- CBrush )   N/I ;

\ Drawing-Attribute Functions
   : GetBkColor ( -- crColor )   m_hDC @ COMMON GetBkColor ;

   : SetBkColor ( crColor -- crColor )
      m_hDC @ SWAP COMMON SetBkColor ;

   : GetBkMode ( -- nBkMode )   N/I ;

   : SetBkMode ( nBkMode -- nBkMode )   N/I ;

   : GetPolyFillMode ( -- nPolyFillMode )   N/I ;

   : SetPolyFillMode ( nPolyFillMode -- nPolyFillMode )   N/I ;

   : GetROP2 ( -- nDrawMode )   m_hDC @ COMMON GetROP2 ;

   : SetROP2 ( nDrawMode -- nDrawMode )
      m_hDC @ SWAP COMMON SetROP2 ;

   : GetStretchBltMode ( -- nStretchMode )   N/I ;

   : SetStretchBltMode ( nStretchMode -- nStretchMode )   N/I ;

   : GetTextColor ( -- crColor )   N/I ;

   : SetTextColor ( crColor -- crColor )
      m_hDC @ SWAP COMMON SetTextColor ;

   : GetColorAdjustment ( lpColorAdjust -- flag )   N/I ;

   : SetColorAdjustment ( lpColorAdjust -- flag )   N/I ;

\ Mapping Functions
   : GetMapMode ( -- nMapMode )   N/I ;

   : SetMapMode ( nMapMode -- nMapMode )   N/I ;

\ ... I'm getting tired of this!!! ;(

\ Line-Output Functions

   : GetCurrentPosition ( -- CPoint )   N/I ;

   : MoveTo ( CPoint -- CPoint )
      [OBJECTS  CPoint NAMES pt  OBJECTS]
      m_hDC @  pt Get  CTempPoint ADDR COMMON MoveToEx DROP
      CTempPoint ADDR ;

   : LineTo ( CPoint -- flag )
      [OBJECTS  CPoint NAMES pt  OBJECTS]
      m_hDC @  pt Get COMMON LineTo ;

\ Ellipse and Polygon Functions

   : Ellipse ( lpRect -- flag )
      [OBJECTS  CRect NAMES rect  OBJECTS]
      m_hDC @  rect Get  COMMON Ellipse ;

   : Rectangle ( lpRect -- flag )
      [OBJECTS  CRect NAMES rect  OBJECTS]
      m_hDC @  rect Get  COMMON Rectangle ;

   : TextOut ( x y addr len -- )
      m_hDC @  4 -ROLL COMMON TextOut DROP ;

   : DrawText ( addr len 'rect format -- height )
      m_hDC @ 4 -ROLL COMMON DrawText DROP ;

END-CLASS

