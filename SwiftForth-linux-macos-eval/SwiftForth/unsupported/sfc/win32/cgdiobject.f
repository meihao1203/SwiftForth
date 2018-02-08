OPTIONAL CGdiObject Provides a base class for Windows GDI objects.

{ ====================================================================
CGdiObject provides a base class for Windows GDI objects.

Copyright (c) 1972-1999, FORTH, Inc.

The CGdiObject class provides a base class for various kinds of
Windows graphics device interface (GDI) objects such as bitmaps,
regions, brushes, pens, palettes, and fonts. You never create a
CGdiObject directly. Rather, you create an object from one of its
derived classes, such as CPen or CBrush.

Requires: CObject

Exports: see MFC documentation

==================================================================== }

REQUIRES CObject

CObject SUBCLASS CGdiObject

PUBLIC

   VARIABLE m_hObject

\ Operations
   : Attach ( hObject -- flag )   m_hObject !  TRUE ;

   : Detach ( -- hObject )   m_hObject @  0 m_hObject ! ;

   : CreateStockObject ( nIndex -- flag )
      COMMON GetStockObject Attach ;

END-CLASS

