OPTIONAL CClientDC The client area of a window.

{ ====================================================================
CClientDC object is the client area of a window.

Copyright (c) 1972-1999, FORTH, Inc.

The CClientDC class is derived from CDC and takes care of calling the
Windows functions GetDC at construction time and ReleaseDC at
destruction time. This means that the device context associated with a
CClientDC object is the client area of a window.

Requires: CDC

Exports: see MFC documentation

==================================================================== }

REQUIRES CDC

CDC SUBCLASS CClientDC

\ Data Members
   VARIABLE m_hWnd

   : Construct ( -- )   HWND DUP m_hWnd !  COMMON GetDC Attach DROP ;
   : Destruct ( -- )   m_hWnd @ m_hDC @ COMMON ReleaseDC DROP  Detach ;

END-CLASS

