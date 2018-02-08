OPTIONAL CWinApp The base class for Windows applications.

{ ====================================================================
CWinApp class is the base class for Windows applications.

Copyright (c) 1972-1999, FORTH, Inc.

The CWinApp class is the base class from which you derive a Windows
application object. An application object provides member functions
for initializing your application (and each instance of it) and for
running the application.

Requires: CWinThread

Exports: see MFC documentation

==================================================================== }

REQUIRES CWinThread

0 VALUE AfxGetApp

CWinThread SUBCLASS CWinApp

PUBLIC

\ Data Members
   VARIABLE m_pszAppName
   VARIABLE m_hInstance
   VARIABLE m_hPrevInstance
   VARIABLE m_lpCmdLine
   VARIABLE m_nCmdShow
   VARIABLE m_bHelpMode
   VARIABLE m_pActiveWnd
   VARIABLE m_pszExeName
   VARIABLE m_pszHelpFilePath
   VARIABLE m_pszProfileName
   VARIABLE m_pszRegistryKey

\ Operations
   : LoadCursor ( nIDResource | lpszResourceName -- hCursor )
      m_hInstance @ SWAP COMMON LoadCursor ;

   : LoadStandardCursor ( lpszCursorName -- hCursor )
      m_hInstance @ SWAP COMMON LoadCursor ;

   : LoadOEMCursor ( nIDCursor -- hCursor )
      m_hInstance @ SWAP COMMON LoadCursor ;

   : LoadIcon ( nIDResource | lpszResourceName -- hIcon )
      m_hInstance @ SWAP COMMON LoadIcon ;

   : LoadStandardIcon ( lpszIconName -- hIcon )
      m_hInstance @ SWAP COMMON LoadIcon ;

   : LoadOEMIcon ( nIDIcon -- hIcon )
      m_hInstance @ SWAP COMMON LoadIcon ;

   : RunAutomated ( -- flag )   N/I ;

   : RunEmbedded ( -- flag )   N/I ;

   : ParseCommandLine ( rCmdInfo -- )   N/I ;

\ Overridables
   DEFER: InitInstance ( -- flag )   TRUE ;

   : Construct ( -- )   SELF TO AfxGetApp
      HINST m_hInstance !  SW_NORMAL m_nCmdShow ! ;

END-CLASS

