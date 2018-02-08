OPTIONAL CFrameWnd Provides an SDI overlapped or pop-up window.

{ ====================================================================
CFrameWnd provides an SDI overlapped or pop-up window.

Copyright (c) 1972-1999, FORTH, Inc.

The CFrameWnd class provides the functionality of a Windows single
document interface (SDI) overlapped or pop-up frame window, along with
members for managing the window.

Requires: CWnd

Exports: see MFC documentation

==================================================================== }

REQUIRES CWnd

{ --------------------------------------------------------------------
rectDefault has to be system global since we do not have the ability
to define class global data yet.  This simply means that no parent
object need be referenced before this object is used.

-------------------------------------------------------------------- }

RECT BUILDS rectDefault   RECT SIZEOF NEGATE ALLOT
   CW_USEDEFAULT ,
   CW_USEDEFAULT ,
   CW_USEDEFAULT ,
   CW_USEDEFAULT ,

CLASS CCreateContext
   VARIABLE m_pNewViewClass
   VARIABLE m_pCurrentDoc
   VARIABLE m_pNewDocTemplate
   VARIABLE m_pLastView
   VARIABLE m_pCurrentFrame
END-CLASS

CWnd SUBCLASS CFrameWnd

\ Data Members
   VARIABLE m_bAutoMenuEnable

\ Initialization
   : CreateEx ( lpszClassName lpszWindowName dwStyle rect pParentWnd
                lpszMenuName dwExStyle pContext -- flag )
      0<> IF  N/I  THEN \ Not dealing with context yet
      6 -ROLL 0 SUPER CreateEx ;

\ Operations

\ Overridables

\ Command Handlers

END-CLASS

