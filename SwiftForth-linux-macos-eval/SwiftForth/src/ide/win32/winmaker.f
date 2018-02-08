{ ====================================================================
Window class operations

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

{ --------------------------------------------------------------------
EBOX is a simple message box.
-------------------------------------------------------------------- }

: EBOX ( hwnd zstr -- )
   Z" Swift" 4096 MessageBox DROP ;

{ --------------------------------------------------------------------
Library calls
-------------------------------------------------------------------- }

LIBRARY USER32
FUNCTION: GetClassInfoEx ( hinst zclass 'classdata -- bool )

LIBRARY KERNEL32
FUNCTION: SetLastError ( error -- )

{ --------------------------------------------------------------------
Windows last-error message processing.

LAST-ERROR-ALERT takes a null-terminated title string (or 0 for the
generic "Error" title) and displays a little message box with the
system text associated with the result in GetLastError.

.LAST-ERROR outputs the error message using TYPE.

Be sure to call these functions *immediately* after the API call that
sets GetLastError.
-------------------------------------------------------------------- }

: LAST-ERROR-ALERT ( zstr -- )
   0 >R ( place for pointer to string)
   FORMAT_MESSAGE_ALLOCATE_BUFFER FORMAT_MESSAGE_FROM_SYSTEM OR
   0 GetLastError 0 RP@ 0 0 FormatMessage DROP
   0 R@ ROT MB_OK MB_ICONINFORMATION OR MessageBox DROP
   R> LocalFree DROP ;

: .LAST-ERROR ( -- )
   0 >R ( place for pointer to string)
   FORMAT_MESSAGE_ALLOCATE_BUFFER FORMAT_MESSAGE_FROM_SYSTEM OR
   0 GetLastError 0 RP@ 0 0 FormatMessage
   R@ SWAP 0 ?DO  COUNT BL MAX EMIT  LOOP DROP
   R> LocalFree DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

THROW#
   S" Can't register the class" >THROW ENUM IOR_BADWINCLASS
TO THROW#

{ ----------------------------------------------------------------------
We define a common subclass for the window elements so they can share 
a few common definitions.
---------------------------------------------------------------------- }

CLASS GUICOMMON         \ a common ancestor for basewindow and basedialog
                        \ the first items here are required to be in order
   SINGLE mHWND         \ 0 set by WM_NCCREATE message in CLASS-CALLBACK
   SINGLE MYTAG         \ 1 this tag _must_ be the first item here!
   SINGLE MYCLASS       \ 2 my class
   SINGLE OLDPROC       \ 3 old callback address
END-CLASS

{ ----------------------------------------------------------------------
The base window class is defined here. Many defers can be left in their
default states. This class is refined to include child windows etc.
---------------------------------------------------------------------- }

GUICOMMON SUBCLASS BASEWINDOW  

   DEFER: MyClass_Style           0 ;
   DEFER: MyClass_WndProc         CLASS-CALLBACK ;
   DEFER: MyClass_ClsExtra        0 ;
   DEFER: MyClass_WndExtra        0 ;
   DEFER: MyClass_hInstance       HINST ;
   DEFER: MyClass_hIcon           HINST 101 LoadIcon ;
   DEFER: MyClass_hCursor         0 IDC_ARROW LoadCursor ;
   DEFER: MyClass_hbrBackground   WHITE_BRUSH GetStockObject ;
   DEFER: MyClass_MenuName        0 ;
   DEFER: MyClass_ClassName       Z" SF000000" ;
   DEFER: MyClass_hIconSm         0 ;

   : MyClass_Register ( -- ior )
      [OBJECTS WNDCLASSEX MAKES WC OBJECTS]
      MyClass_ClassName 0= IF -1 EXIT THEN
      HINST MyClass_ClassName WC ADDR GetClassInfoEx IF ( already exists)
         0 EXIT  THEN
      MyClass_Style          WC style       !
      MyClass_WndProc        WC WndProc     !
      MyClass_ClsExtra       WC ClsExtra    !
      MyClass_WndExtra       WC WndExtra    !
      MyClass_hInstance      WC Instance    !
      MyClass_hIcon          WC Icon        !
      MyClass_hCursor        WC Cursor      !
      MyClass_hbrBackground  WC Background  !
      MyClass_MenuName       WC MenuName    !
      MyClass_ClassName      WC ClassName   !
      MyClass_hIconSm        WC IconSm      !
      WC ADDR RegisterCLassEx 0= DUP IF DROP
         GetLastError  DUP SetLastError
         DUP ERROR_SUCCESS <>
         SWAP ERROR_CLASS_ALREADY_EXISTS <> AND
         IOR_BADWINCLASS AND
         DUP IF
            S" The windows class " PAD ZPLACE
            MyClass_ClassName ZCOUNT PAD ZAPPEND
            S"  could not be registered"
            PAD LAST-ERROR-ALERT
         THEN
      THEN ;

   DEFER: MyWindow_ExStyle      0 ;
   DEFER: MyWindow_ClassName    MyClass_ClassName ;
   DEFER: MyWindow_WindowName   Z" SF Application" ;
   DEFER: MyWindow_Style        WS_OVERLAPPEDWINDOW ;
   DEFER: MyWindow_X            10 ;
   DEFER: MyWindow_Y            10 ;
   DEFER: MyWindow_Width        200 ;
   DEFER: MyWindow_Height       150 ;
   DEFER: MyWindow_Parent       0 ;
   DEFER: MyWindow_Menu         0 ;
   DEFER: MyWindow_Instance     HINST ;
   DEFER: MyWindow_Param        0 ;

   DEFER: PreConstruct ;
   DEFER: PostConstruct ;

   DEFER: MyWindow_Shape ( -- x y cx cy )
      MyWindow_X  MyWindow_Y  MyWindow_Width  MyWindow_Height ;

   : DESTRUCT ( -- )
      mHWND DestroyWindow DROP  ;

   : _CONSTRUCT ( -- ior )   mHWND IF DESTRUCT THEN
      MyClass_Register DUP ?EXIT DROP
      WINDOW-OBJECT-TAG TO MYTAG  THIS TO MYCLASS
      MyWindow_ExStyle MyWindow_ClassName MyWindow_WindowName
      MyWindow_Style MyWindow_Shape
      MyWindow_Parent MyWindow_Menu MyWindow_Instance
      MyWindow_Param >R SELF >R RP@ CreateWindowEx 2R> 2DROP ;

   : CONSTRUCT ( -- )    PreConstruct _CONSTRUCT DROP PostConstruct ;

   DEFER: PreDestroy ( -- )   ;
   DEFER: PostDestroy ( -- )   ;

   WM_NCDESTROY MESSAGE: ( -- res )   PreDestroy
      mHWND SFTAG RemoveProp DROP  0 TO mHWND
      PostDestroy  0 ;

   : SelfMessage ( msg wparam lparam -- res )
      2>R mHWND SWAP 2R> SendMessage ;

   DEFER: RESIZE ( x y x y -- )
      2>R 2>R mHWND 2R> 2R> -1 MoveWindow DROP ;

   DEFER: ATTACH ;
   DEFER: DETACH ;
   DEFER: PreAttach ;
   DEFER: PostAttach ;


END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

BASEWINDOW SUBCLASS GENERICWINDOW

   DEFER: VISIBLE ( -- )   mHWND SW_SHOW ShowWindow DROP ;

   : CONSTRUCT ( -- )   CONSTRUCT VISIBLE ;

\ deferred message routines

   DEFER: OnDestroy ( -- res )   0 'MAIN @ ?EXIT PostQuitMessage ;
   DEFER: OnClose   ( -- res )   DEFWINPROC ;
   DEFER: OnCreate  ( -- res )   DEFWINPROC ;
   DEFER: OnPaint   ( -- res )   DEFWINPROC ;

   DEFER: OnCommand ( -- res )   [ OOP +ORDER ]
      WPARAM LOWORD THIS >ANONYMOUS2 BELONGS? IF
         SELF SWAP LATE-BINDING 0 EXIT
      THEN DROP 0 [ OOP -ORDER ] ;

\ default message handlers

   WM_COMMAND MESSAGE: OnCommand ;

   WM_DESTROY MESSAGE: OnDestroy ;
   WM_CLOSE   MESSAGE: OnClose ;
   WM_CREATE  MESSAGE: OnCreate ;
   WM_PAINT   MESSAGE: OnPaint ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

GENERICWINDOW SUBCLASS CHILDWINDOW

   SINGLE HPARENT

   : MyClass_ClassName ( -- zname )   Z" SFCHILD01" ;
   : MyWindow_Style ( -- style )   WS_CHILD WS_VISIBLE OR ;
   : MyWindow_Parent ( -- hparent )   HPARENT ;

   : ATTACH ( parent -- )   TO HPARENT  PreAttach CONSTRUCT  PostAttach ;
   : DETACH ( -- )   DESTRUCT ;

   : CONSTRUCT ( -- ) ;         \ mask original construct behavior

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

BASEWINDOW SUBCLASS DERIVEDWINDOW

   SINGLE HPARENT

   : DEFPROC ( -- res )
      OLDPROC HWND MSG WPARAM LPARAM CallWindowProc ;

\ deferred message routines

   DEFER: OnCommand ( -- res )   [ OOP +ORDER ]
      WPARAM LOWORD THIS >ANONYMOUS2 BELONGS? IF
         SELF SWAP LATE-BINDING 0 EXIT
      THEN DROP [ OOP -ORDER ]  DEFPROC ;

\ default message handlers

   WM_COMMAND MESSAGE: OnCommand ;

   DEFER: MyWindow_ClassName ( -- z )
      0 Z" Must define a class for a derived window" EBOX -1 THROW ;

   DEFER: MyClass_ClassName ( -- 0 )   0 ;
   DEFER: MyWindow_Parent ( -- hparent )   HPARENT ;
   DEFER: MyWindow_Style ( -- style )   WS_CHILD WS_VISIBLE OR ;
   DEFER: MyWindow_Menu       100 ;

   : X_CONSTRUCT ( -- ior )   mHWND IF DESTRUCT THEN
      WINDOW-OBJECT-TAG TO MYTAG  THIS TO MYCLASS
      MyWindow_ExStyle MyWindow_ClassName MyWindow_WindowName
      MyWindow_Style MyWindow_Shape
      MyWindow_Parent MyWindow_Menu MyWindow_Instance
      MyWindow_Param >R SELF >R RP@ CreateWindowEx 2R> 2DROP ;

   : deriveConstruct ( hwnd -- )   TO mHWND
      mHWND SFTAG ADDR SetProp DROP
      mHWND GWL_WNDPROC GetWindowLong TO OLDPROC
      mHWND GWL_WNDPROC DERIVED-CLASS-CALLBACK SetWindowLong DROP ;

   : ATTACH ( parent -- )   TO HPARENT  PreAttach
      PreConstruct X_CONSTRUCT deriveConstruct PostConstruct  PostAttach ;

   : DETACH ( -- )   mHWND -EXIT  DESTRUCT  0 TO mHWND ;

   : CONSTRUCT ( -- ) ;         \ mask original construct behavior

END-CLASS

{ ----------------------------------------------------------------------
Derive a statusbar class from the windows statusbar object

Public-ish methods are:

+PANE ( width -- )   add a pane to the right side of the bar
-PANE ( -- )   remove the right-most pane
ZTYPE ( zstr pane -- )   type zstring on the pane, 0=leftmost
TYPE ( addr len pane -- )   type the string
SET-FONT ( hfont -- )   set the statusbar's font
FIXED-FONT ( -- )  use ANSI_FIXED_FONT 

---------------------------------------------------------------------- }

DERIVEDWINDOW SUBCLASS STATUSBAR
 
   0 WS_CHILD OR
     WS_VISIBLE OR
     WS_CLIPSIBLINGS OR
     CCS_BOTTOM OR
   CONSTANT STYLE

   : MyWindow_Style        STYLE ;
   : MyWindow_ClassName    Z" msctls_statusbar32" ;
   : MyWindow_WindowName   0 ;

   63 CONSTANT MAXPANES
   
   MAXPANES 2+ CELLS BUFFER: PANEMAP    \ #parts, part 1, part 2, ...

   : WIDTH ( -- n )
      PANEMAP @ IF   PANEMAP @+ 1- CELLS + @  ELSE  0  THEN ;

   : MORE ( n -- )   PANEMAP @ +  0 MAX  MAXPANES MIN  PANEMAP ! ;
   : LESS ( n -- )   NEGATE MORE ;
   
   : PANES ( -- n )   PANEMAP @ 1+ ;

   : TAIL ( -- addr )   PANEMAP @+ CELLS + ;

   : FILLED ( -- )   -1 TAIL ! ;

   : DIVIDES ( -- )
      mHWND SB_SETPARTS PANES PANEMAP CELL+ SendMessage DROP ;

   : PreConstruct  ( -- )   0 PANEMAP !  FILLED ;
   
   : HIGH ( -- n )   
      [OBJECTS RECT MAKES AREA OBJECTS]
      mHWND AREA ADDR GetWindowRect DROP
      AREA bottom @ AREA top @ - ;

   \ ----------------------------------------------------------------------

   : +PANE ( n -- )   WIDTH +  TAIL !  1 MORE  FILLED  DIVIDES ;
   : -PANE ( -- )   1 LESS FILLED  DIVIDES ;
      
   : ZTYPE ( zstr pane -- )
      mHWND SB_SETTEXTA 2SWAP SWAP SendMessage DROP ;

   : TYPE ( addr len pane -- )
      >R  PAD ZPLACE  PAD R> ZTYPE ;

   : SET-FONT ( hfont -- )
      >R  mHWND WM_SETFONT R> 1 SendMessage DROP ;

   : FIXED-FONT ( -- )  ANSI_FIXED_FONT GetStockObject SET-FONT ;
   
END-CLASS

{ --------------------------------------------------------------------
The base dialog class is defined here. 
-------------------------------------------------------------------- }

GUICOMMON SUBCLASS BASEDIALOG        

   SINGLE OWNER
   SINGLE RES

   SINGLE IS-MODAL

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

   : DlgClassName ( -- z )   Z" SFDLG" ;

   : MyDlgClass_Register ( -- ior )
      [OBJECTS WNDCLASSEX MAKES WC OBJECTS]
      HINST DlgClassName WC ADDR GetClassInfoEx IF ( already exists)
         0 EXIT  THEN

      HINST WC_DIALOG WC ADDR GetClassInfoEx 0= DUP ?EXIT DROP

      SUPERCLASS-DLG-CALLBACK     WC WndProc     !
      DlgClassName           WC ClassName   !

      WC ADDR RegisterCLassEx 0= ;

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

   DEFER: TEMPLATE ( -- addr )   0 ;
   DEFER: PARAM ( -- n )   0 ;

   DEFER: PreConstruct ;
   DEFER: PostConstruct ;       \ note: for modal, executed on exit!

   : UCOUNT ( a -- a n )
      DUP 0 BEGIN  OVER H@ WHILE  1+ SWAP 2+ SWAP  REPEAT  NIP ;

   : U>Z ( from to -- )
      BEGIN   OVER H@  OVER C!
         OVER H@ WHILE  1+ SWAP 2+  SWAP
      REPEAT  2DROP ;

   : VALID ( -- flag )
      TEMPLATE DUP IF
         18 +            \ skip style, extstyle, cdit, x y cx cy
         UCOUNT + 2+     \ skip menu designator
         PAD U>Z         \ copy to pad as zstr
         DlgClassName ZCOUNT PAD ZCOUNT COMPARE 0=
      THEN ;

   : CLOSE-DIALOG ( res -- )   TO RES   mHWND -EXIT
      IS-MODAL IF  mHWND RES EndDialog
      ELSE mHWND DestroyWindow  THEN DROP ;

   : CONSTRUCTOR ( -- )
      VALID 0= IF  0 TO RES  EXIT  THEN
      MyDlgClass_Register DROP  SYNC-NCCREATE
      WINDOW-OBJECT-TAG TO MYTAG  THIS TO MYCLASS
      PreConstruct
      HINST TEMPLATE OWNER CLASS-DLG-CALLBACK PARAM
      IS-MODAL IF  DialogBoxIndirectParam
      ELSE  CreateDialogIndirectParam  THEN  TO RES
      PostConstruct ;

   : ATTACH ( hwnd -- result )   TO OWNER  CONSTRUCTOR  RES ;

   WM_COMMAND MESSAGE: ( -- )   [ OOP +ORDER ]
      WPARAM LOWORD THIS >ANONYMOUS2 BELONGS? IF
         SELF SWAP LATE-BINDING EXIT
      THEN DROP [ OOP -ORDER ] ;

   WM_NCDESTROY DIALOG: ( -- )
      mHWND SFTAG RemoveProp DROP  0 TO mHWND  0 ;

   WM_ACTIVATE MESSAGE: ( -- 0 )
      IS-MODAL IF  -1 EXIT THEN
      WPARAM LOWORD IF mHWND ELSE 0 THEN  DLGACTIVE !  0 ;

   : DESTRUCT ( -- )   0 CLOSE-DIALOG ;

   IDOK COMMAND:  1 CLOSE-DIALOG ;
   IDCANCEL COMMAND: 0 CLOSE-DIALOG ;

   \ ----------------------------------------------------------------------
   \ common methods on dialog controls

   : SET-CHECK ( id flag -- )
      mHWND ROT ROT  0<> CheckDlgButton DROP ;

   : IS-CHECKED ( id -- flag )
      mHWND SWAP IsDlgButtonChecked 0<> ;

   : SET-ITEM-TEXT ( id ztext -- )
      mHWND ROT ROT SetDlgItemText DROP ;

   : SET-ITEM-HEX ( id n -- )
      8 (H.0) PAD ZPLACE  PAD SET-ITEM-TEXT ;

   : SET-ITEM-INT ( id n -- )
      mHWND ROT ROT 1 SetDlgItemInt DROP ;

   : SET-ITEM-UINT ( id u -- )
      mHWND ROT ROT 0 SetDlgItemInt DROP ;

   : GET-ITEM-INT ( id -- n )
      mHWND SWAP 0 1 GetDlgItemInt ;

   : GET-ITEM-UINT ( id -- n )
      mHWND SWAP 0 0 GetDlgItemInt ;

   : GET-ITEM-TEXT ( id zaddr zmaxlen -- zlen )
      >R mHWND -ROT R> GetDlgItemText ;

   : ENABLE ( id -- )   
      mHWND SWAP GetDlgItem 1 EnableWindow DROP ;

   : DISABLE ( id -- )   
      mHWND SWAP GetDlgItem 0 EnableWindow DROP ;

   : HIDE ( id -- )
      mHWND SWAP GetDlgItem SW_HIDE ShowWindow DROP ;

   : SHOW ( id -- )
      mHWND SWAP GetDlgItem SW_SHOW ShowWindow DROP ;

   : IS-HIDDEN ( id -- flag )
      mHWND SWAP GetDlgItem IsWindowVisible 0= ;

   : SET-FOCUS ( id -- )
      mHWND SWAP GetDlgItem SetFocus DROP ;

END-CLASS

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

BASEDIALOG SUBCLASS GENERICDIALOG

   : MODAL ( hwnd -- res )   1 TO IS-MODAL  ATTACH ;
   : MODELESS ( hwnd -- res )   0 TO IS-MODAL  ATTACH ;

 \ We'll define this in its own subclass so as not to break existing code
 \ : MODALP ( hwnd param -- res )   TO PARAM MODAL ;

END-CLASS

\ We'll define this so as not to break existing code
BASEDIALOG SUBCLASS PARAMDIALOG

   SINGLE MY-PARAM
   : PARAM  ( -- )  MY-PARAM ;

   : MODALP ( hwnd param -- res )   TO MY-PARAM
      1 TO IS-MODAL  ATTACH ( just as MODAL above ) ;

END-CLASS


