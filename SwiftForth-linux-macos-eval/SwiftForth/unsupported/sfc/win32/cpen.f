OPTIONAL CPen A Window's pen.

{ ====================================================================
CPen is a Window's pen.

Copyright (c) 1972-1999, FORTH, Inc.

The CPen class encapsulates a Windows graphics device interface (GDI)
pen.

Requires: CGdiObject

Exports: see MFC documentation

==================================================================== }

REQUIRES CGdiObject

3 IMPORT: CreatePen

CGdiObject SUBCLASS CPen

   : CreatePen ( nPenStyle nWidth crColor -- flag )
      COMMON CreatePen Attach ;

END-CLASS

