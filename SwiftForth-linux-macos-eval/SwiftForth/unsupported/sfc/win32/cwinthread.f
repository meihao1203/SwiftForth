OPTIONAL CWINTHREAD A class representing a thread of operation.

{ ====================================================================
CWinThread object represents a thread of execution.

Copyright (c) 1972-1999, FORTH, Inc.

A CWinThread object represents a thread of execution within an
application. The main thread of execution is usually provided by an
object derived from CWinApp; CWinApp is derived from CWinThread.
Additional CWinThread objects allow multiple threads within a given
application.

Requires: CCmdTarget

Exports: see MFC documentation

==================================================================== }

REQUIRES CCmdTarget

1 IMPORT: GetThreadPriority
2 IMPORT: SetThreadPriority

CCmdTarget SUBCLASS CWinThread

PUBLIC

\ Data Members
   VARIABLE m_bAutoDelete
   VARIABLE m_hThread
   VARIABLE m_nThreadID
   VARIABLE m_pMainWnd
   VARIABLE m_pActiveWnd

\ Construction
   : CreateThread ( dwCreateFlags nStackSize
                    lpSecurityAttrs -- flag )  N/I ;

\ Operations
   : GetMainWnd ( -- CWnd )   m_pMainWnd @ ;

   : GetThreadPriority ( -- nPriority )
      m_hThread @ COMMON GetThreadPriority ;

   : PostThreadMessage ( message wParam lParam -- flag )   N/I ;

   : ResumeThread ( -- n )   m_hThread @ COMMON ResumeThread ;

   : SetThreadPriority ( nPriority -- flag )
      m_hThread @ SWAP COMMON SetThreadPriority ;

   : SuspendThread ( -- n )   m_hThread @ COMMON SuspendThread ;

\ Overridables
   DEFER: ExitInstance ( -- nExitCode )   N/I ;

   DEFER: InitInstance ( -- flag )   N/I ;

   DEFER: OnIdle ( lCount -- flag )   DROP FALSE ;

   DEFER: PreTranslateMessage ( pMsg -- flag )   DROP FALSE ;

   DEFER: IsIdleMessage ( pMsg -- flag )   DROP TRUE ;

   DEFER: ProcessWndProcException ( CException pMsg -- n )
      2DROP FALSE ;

   DEFER: ProcessMessageFilter ( code lpMsg -- flag )   2DROP FALSE ;

   DEFER: Run ( -- n )   N/I ;

END-CLASS

