OPTIONAL CPaintDC A device-context class derived from CDC for use in responding to a WM_PAINT message.

{ ====================================================================
CPaintDC can only be used when responding to a WM_PAINT message.

Copyright (c) 1972-1999, FORTH, Inc.

The CPaintDC class is a device-context class derived from CDC. It
performs a CWnd::BeginPaint at construction time and CWnd::EndPaint at
destruction time.

Requires: CDC

Exports: see MFC documentation

==================================================================== }

REQUIRES CDC

CLASS PAINTSTRUCT
   VARIABLE dc
   VARIABLE Erase
   RECT BUILDS Paint
   VARIABLE Restore
   VARIABLE IncUpdate
   32 BUFFER: Reserved
END-CLASS

CDC SUBCLASS CPaintDC

\ Data Members
   PAINTSTRUCT BUILDS m_ps
   VARIABLE m_hWnd

   : Construct ( -- )   HWND DUP m_hWnd !
      m_ps ADDR BeginPaint  Attach DROP ;

   : Destroy ( -- )   m_hWnd @
      m_ps ADDR EndPaint DROP  Detach ;

END-CLASS

CDC SUBCLASS CDrawDC

\ Data Members
   VARIABLE m_hWnd

   : Attach ( hwnd -- )   DUP m_hWnd !  GetDC  Attach DROP ;

   : Destroy ( -- )   m_hWnd @  m_hDC @ ReleaseDC DROP  Detach ;

END-CLASS

