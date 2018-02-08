{ ====================================================================
Dialog editor

Copyright (C) 2001 FORTH, Inc.

==================================================================== }

OPTIONAL BOXED Alpha release of a dialog editor for SwiftForth.

{ --------------------------------------------------------------------
Original work (C) Copyright 1999 Charles Melice   mail@forthcad.com
   Extensions (C) Copyright 1999 FORTH, Inc.      www.forth.com
Formatting changes contributed by Mike Ghan.
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
Usage:
  ------
    dlgTemplate Boxed ( edit an existing dialog template )
    0 Boxed           ( create a new dialog template )

  The resulting template is copied in the clipboard. Just
  paste it in your editor.

  NB1:  search for 'adjust' to adjust some constants
    2:  line 64: "PatternDefinitionSet" can be completed
    3:  mouse-resizing possible only on right/bottom side
    4:  clic-right on dialog/ctrl to open popup menu options.
    5:  drag+<ctrl-key> disable the grid-mode

      Idea:
            * Align sequence to bottom
            * Align sequence to right
            * z-order management (ctrl sequence)
            * save/restore the template-name
            * append new control
            * sizeable ctrl on top/left side
            * check the system with other screen resolution
            * ...
-------------------------------------------------------------------- }

PACKAGE BOXER

\ =============================================================
\ PatternDefinitionSet to define editable controls
\ =============================================================

GetDialogBaseUnits HILO
   2/ CONSTANT XGRID       \ adjustable but difficult
2/ 2/ CONSTANT YGRID

XGRID 16 * CONSTANT CX
YGRID 5  * CONSTANT CY

CREATE BOX-TITLE   256 ALLOT

0  CONSTANT SCHEMA0 \ output normal schema
1  CONSTANT SCHEMA1 \ output without text
2  CONSTANT SCHEMA2 \ output RESOURCE

\ adjust class set

: szBUTTON  ( -- sz )   Z" BUTTON" ;
: szEDIT    ( -- sz )   Z" EDIT" ;
: szSTATIC  ( -- sz )   Z" STATIC" ;
: szLISTBOX ( -- sz )   Z" LISTBOX" ;

0 VALUE (N)

: RUN++: ( -- )  (N) 1 +TO (N) RUN: ;

\ -----------------------------------------------

: UNSPACED ( addr len -- )
   BOUNDS DO I C@ BL = IF [CHAR] _ I C! THEN LOOP ;

\ -----------------control set-------------------

[SWITCH PatternDefinitionSet[] ZERO
            ( n -- szPtrn szStyle cx cy schema szClass | 0 )

                                \ ------schema--------------
    RUN++:  Z" [PUSHBUTTON"     \ 1.definition-string
            BS_PUSHBUTTON       \ 2.combined (or) style
            CX CY               \ 3.default creation size
            SCHEMA0             \ 4.output-schema
            szBUTTON ;          \ 5.class-name
                                \ --------------------------
    RUN++:  Z" [DEFPUSHBUTTON"
            BS_DEFPUSHBUTTON
            CX CY
            SCHEMA0
            szBUTTON ;

    RUN++:  Z" [RADIOBUTTON"
            BS_RADIOBUTTON
            CX CY
            SCHEMA0
            szBUTTON ;

    RUN++:  Z" [AUTORADIOBUTTON"
            BS_AUTORADIOBUTTON
            CX CY
            SCHEMA0
            szBUTTON ;

    RUN++:  Z" [AUTOCHECKBOX"
            BS_AUTOCHECKBOX
            CX CY
            SCHEMA0
            szBUTTON ;

    RUN++:  Z" [LTEXT"
            [ SS_LEFT WS_GROUP OR ] LITERAL
            CX 2* CY
            SCHEMA0
            szSTATIC ;

    RUN++:  Z" [RTEXT"
            [ SS_RIGHT WS_GROUP OR ] LITERAL
            CX 2* CY
            SCHEMA0
            szSTATIC ;

    RUN++:  Z" [CTEXT"
            [ SS_CENTER WS_GROUP OR ] LITERAL
            CX 2* CY
            SCHEMA0
            szSTATIC ;

    RUN++:  Z" [EDITTEXT"
            [ ES_LEFT WS_BORDER OR WS_TABSTOP OR ] LITERAL
            CX 2 * CY
            SCHEMA0
            szEDIT ;

    RUN++:  Z" [EDITBOX"
            [ ES_LEFT WS_BORDER OR ES_MULTILINE OR ] LITERAL
            CX 3 * CY 2 *
            SCHEMA0
            szEDIT ;

    RUN++:  Z" [LISTBOX"
            [ LBS_NOTIFY WS_BORDER OR LBS_NOINTEGRALHEIGHT OR ] LITERAL
            CX 2* CY 3 *
            SCHEMA1     \ no text to output
            szLISTBOX ;

    RUN++:  Z" [ICON"
            SS_ICON
            32 32
            SCHEMA2
            szSTATIC ;

    RUN++:  Z" [GROUPBOX"
            BS_GROUPBOX
            cx 2 * CY 4 *
            SCHEMA0
            szBUTTON ;
SWITCH]

\ -------------------------------------------------------------

FUNCTION: MapWindowPoints   ( hfrom hto pPt cPoint -- int )
FUNCTION: SetWindowPos      ( hwnd hafter x y cx cy flags -- bool )
FUNCTION: SetCursorPos      ( x y -- bool )
FUNCTION: GetClassName      ( hWnd lpClassName nMaxCount -- int )
FUNCTION: FrameRect         ( hdc prect hbrush -- int )
FUNCTION: SetPixelV         ( hdc x y clr -- bool )
FUNCTION: InflateRect       ( rect cx cy -- bool )
FUNCTION: OffsetRect        ( rect dx dy -- bool )
FUNCTION: IsChild           ( hParent hWnd -- bool )

\ =============================================================
\ Force all children of a window to have a particular font
\ =============================================================

: ForceGuiFont ( hwnd -- )
   GW_CHILD GetWindow
   BEGIN DUP WHILE
      DUP WM_SETFONT DEFAULT_GUI_FONT GetStockObject FALSE SendMessage DROP
      GW_HWNDNEXT GetWindow
   REPEAT
   DROP ;

\ =============================================================
\ Some control infos from "PatternDefinitionSet"
\ =============================================================

\ szPtrn szStyle cx cy schema szClass

: PatternName[] ( n -- szName true | false )
    PatternDefinitionSet[] DUP IF 3DROP 2DROP TRUE THEN ;

: PatternClassName[] ( n -- szClassName true | false )
    PatternDefinitionSet[] DUP IF >R 2DROP 3DROP R> TRUE THEN ;

: PatternControlStyle[] ( n -- style true | false )
    PatternDefinitionSet[] DUP
    IF  2DROP 2DROP NIP
        [ WS_VISIBLE WS_CHILD OR WS_BORDER OR WS_TABSTOP OR ] LITERAL OR
        TRUE
    THEN ;

: PatternDefaultSize[]  ( n -- cx cy true | false )
    PatternDefinitionSet[] DUP IF 2DROP 2>R 2DROP 2R> TRUE THEN ;

: PatternSchema[]  ( n -- schema true | false )
    PatternDefinitionSet[] DUP IF DROP >R 2DROP 2DROP R> TRUE THEN ;

\ =============================================================
\ simplify ALLOCATE/FREE usage
\ =============================================================

: GetMem    ( n -- addr )   ALLOCATE ABORT" allocate error" ;
: FreeMem   ( addr -- )     FREE ABORT" free error" ;

\ =============================================================
\ smallest struct package in the world ?
\ =============================================================

: field         ( ofs n "name" -- n+ofs ) CREATE OVER , + DOES> @ + ;
: End-Struct    ( n "name" -- ) CONSTANT ;
0 End-Struct Struct ( -- )

\ =============================================================
\ Used to read signed cursor-pos from LPARAM
\ =============================================================

: SIGNED ( n16 -- n32 )
    [ASM  $00008000 # EBX TEST  0<> IF $FFFF0000 # EBX OR THEN ASM] ;

: iLOHI  ( lparm -- x y )  HILO SIGNED SWAP SIGNED ;
: iHILO  ( lparm -- x y )  LOHI SIGNED SWAP SIGNED ;

\ =============================================================
\ POINT structure - pt.
\ =============================================================

Struct
    CELL field pt.X
    CELL field pt.Y
End-Struct sPOINT

sPOINT BUFFER: (tempt)

: pt.!      ( x y addr -- )     >R SWAP R> 2! ;
: pt.@      ( addr -- x y )     2@ SWAP ;

: pt.ScreenToClient   ( hwnd x y -- x' y' )
    (tempt) pt.!
    (tempt) ScreenToClient DROP
    (tempt) pt.@ ;

: pt.ClientToScreen   ( hwnd x y -- x' y' )
    (tempt) pt.!
    (tempt) ClientToScreen DROP
    (tempt) pt.@ ;

: pt.Offset  ( dx dy ^pt -- )
    ROT OVER +! CELL+ +! ;

: pt.MakeDlgUnits   ( x y -- x' y' )
    GetDialogBaseUnits HILO >R 8 SWAP */ SWAP 4 R> */ SWAP ;

: pt.MakePixUnits   ( x y -- x' y' )
    GetDialogBaseUnits HILO >R  8 */ SWAP R> 4 */ SWAP ;

: pt.Sub ( x1 y1 x2 y2 -- x3 y3 )
    ROT SWAP - >R - R> ;

\ =============================================================
\ RECTANGLE structure - rect.
\ =============================================================

Struct
    CELL field rect.Left
    CELL field rect.Top
    CELL field rect.Right
    CELL field rect.Bottom
End-Struct sRECT


: rect.@    ( rect -- x0 y0 x1 y1 ) @+ SWAP @+ SWAP @+ SWAP @ ;
: rect.!    ( x0 y0 x1 y1 rect -- ) DUP >R CELL+ CELL+ pt.! R> pt.! ;

: rect.GetOrg ( rect -- x0 y0 )     2@ SWAP ;
: rect.GetExt ( rect -- x1 y1 )     CELL+ CELL+ 2@ SWAP ;

: rect.GetSize ( rect -- cx cy )    DUP rect.GetExt ROT rect.GetOrg pt.Sub
;

: rect.PtCode    ( x y rect -- code )   \    4
    >R                                  \  1[0]2  - Sutherland method
    DUP R@ rect.Top @ <                 \    8
    IF   DROP 4
    ELSE R@ rect.Bottom @ >
         IF 8 ELSE 0 THEN
    THEN
    SWAP DUP R@ rect.Left @ <
    IF   DROP 1
    ELSE R@ rect.Right @ >
         IF 2 ELSE 0 THEN
    THEN OR
    R> DROP ;

: rect.MakeDlgUnits ( rect -- )
    >R R@ rect.GetOrg pt.MakeDlgUnits
    R@ rect.GetExt pt.MakeDlgUnits
    R> rect.! ;

\ =============================================================
\ GRID primitive to simplify position
\ =============================================================

: xy>Grid   ( x y -- x' y' )
    YGRID 2/ + DUP YGRID MOD - SWAP
    XGRID 2/ + DUP XGRID MOD - SWAP ;

: pt>Grid   ( ^pt -- )
    DUP >R pt.@ xy>Grid R> pt.! ;

: rect>Grid ( ^rect -- )
    DUP >R pt>Grid R> CELL+ CELL+ pt>Grid ;

\ =============================================================
\ InputCtrlSetting - used to enter the dlg title, ids, ...
\ =============================================================

0 VALUE hCtrl

DIALOG CtrlSettingTemplate
    [MODAL  " Control settings" 22 17 195 45 (FONT 8, MS Sans Serif)
                                               (+STYLE WS_SYSMENU) ]
    [RTEXT          " Control Te&xt"    -1      5   7   70  12 ]
    [EDITTEXT                           100     80  5   100 12 ]
    [RTEXT      " Control I&d (>100)"   -1      5   22  70  12 ]
    [EDITTEXT                           101     80  20  32  12 (+STYLE ES_NUMBER) ]
    [DEFPUSHBUTTON  " OK"               IDOK    155 26  32  12 ]
END-DIALOG

:NONAME ( -- res )
    MSG LOWORD DUP WM_COMMAND =
    IF  DROP
        WPARAM LOWORD DUP IDOK =
        IF  DROP
            HWND 100 PAD 80 GetDlgItemText DROP
            hCtrl PAD SetWindowText DROP
            HWND 101 PAD 0 GetDlgItemInt
            hCtrl GWL_ID ROT SetWindowLong DROP
            HWND TRUE EndDialog 0 EXIT
        THEN
        IDCANCEL =
        IF  HWND FALSE EndDialog THEN
    ELSE
        DUP WM_INITDIALOG =
        IF  hCtrl PAD 80 GetWindowText DROP
            HWND 100 PAD SetDlgItemText DROP
            hCtrl GWL_ID GetWindowLong
            HWND 101 ROT 0 SetDlgItemInt
            HWND ForceGuiFont
            TRUE EXIT
        ELSE
            WM_CLOSE =
            IF 0 THEN
        THEN
    THEN
    0 ; 4 CB: CtrlSettingProc


: InputCtrlSetting  ( hCtrl -- ok? )
    TO hCtrl
    HINST CtrlSettingTemplate HWND CtrlSettingProc 0 DialogBoxIndirectParam
;


\ =============================================================
\ Simple InputBox
\ =============================================================

0 VALUE (buffer)    \ text to edit

DIALOG IBoxTemplate
    [MODAL " Dialog Title"  22 17 150 20 (+STYLE WS_SYSMENU) ]
    [EDITTEXT                           100     5   5   100 12 ]
    [DEFPUSHBUTTON      " OK"           IDOK    110 5   32  12 ]
END-DIALOG

:NONAME ( -- res )
    MSG LOWORD DUP WM_COMMAND =
    IF  DROP
        WPARAM LOWORD DUP IDOK =
        IF  DROP
            HWND 100 (buffer) 80 GetDlgItemText DROP
            HWND TRUE EndDialog 0 EXIT
        THEN
        IDCANCEL =
        IF  HWND FALSE EndDialog THEN
    ELSE
        DUP WM_INITDIALOG =
        IF  HWND 100 (buffer) SetDlgItemText DROP
            HWND ForceGuiFont
            TRUE EXIT
        ELSE
            WM_CLOSE = IF 0 THEN
        THEN
    THEN
    0 ; 4 CB: InputBoxProc


: InputBox  ( buffer -- ok? )
    TO (buffer)
    HINST IBoxTemplate HWND InputBoxProc 0 DialogBoxIndirectParam ;


\ =============================================================
\ DIVERS
\ =============================================================

Struct
    CELL  field ps.hdc
    CELL  field ps.fErase
    sRECT field ps.rcPaint
    CELL  field ps.fRestore;
    CELL  field ps.fIncUpdate;
    32    field ps.rgbReserved[32]
End-Struct sPAINTSTRUCT

: RunPopupMenuTemplate  ( hwnd template -- )
    LoadMenuIndirect LOCALS| hmenu hwnd |
    hmenu 0 GetSubMenu
    [ TPM_LEFTALIGN TPM_LEFTBUTTON OR TPM_RIGHTBUTTON OR ] LITERAL
    HERE DUP GetCursorPos DROP 2@ SWAP
    0 hwnd 0 TrackPopupMenu DROP
    hmenu DestroyMenu DROP ;

: Invalidate    ( hwnd -- )
    0 TRUE InvalidateRect DROP ;

: EnumControls   ( hwnd xt -- )   \ xt-param ( hwnd -- )
    SWAP GW_CHILD GetWindow
    BEGIN DUP WHILE    \ s: xt hwnd
        2DUP 2>R SWAP EXECUTE
        2R> GW_HWNDNEXT GetWindow
    REPEAT
    2DROP ;

\ gray a menu-item in a WM_INITMENU msg

: SetMenuItemOff  ( hMenu id -- )
    [ MF_BYCOMMAND MF_GRAYED OR ] LITERAL EnableMenuItem DROP ;

\ ===============================================================
\ Controls - IDs must begins from 100 excepted IDOK, IDCANCEL
\ ===============================================================

-5 CONSTANT CAPTURE-MARGE   \ adjustable

FALSE VALUE grid-mode?

sPOINT BUFFER: ptCapture
sRECT  BUFFER: clirect

0 VALUE nCaptureOperation

90  ENUM ID-AL-LEFT     \ order important: see WM_INITMENU
    ENUM ID-AL-RIGHT
    ENUM ID-AL-TOP
    ENUM ID-AL-BOTTOM
    ENUM ID-SI-WIDTH
    ENUM ID-SI-HEIGHT
    ENUM ID-SI-SAME
    ENUM ID-DEF-TEXT
    ENUM ID-DELETECTRL
    DROP

MENU tmrMenu0
    POPUP "  "
        ID-AL-LEFT      MENUITEM "Align &Left"
        ID-AL-RIGHT     MENUITEM "Align &Right"
        ID-AL-TOP       MENUITEM "Align &Top"
        ID-AL-BOTTOM    MENUITEM "Align &Bottom"
        SEPARATOR
        ID-SI-WIDTH     MENUITEM "Dim. same &Width"
        ID-SI-HEIGHT    MENUITEM "Dim. same &Height"
        ID-SI-SAME      MENUITEM "Dim. same &Size"
        SEPARATOR
        ID-DEF-TEXT     MENUITEM "&Control Settings"
        ID-DELETECTRL   MENUITEM "&Delete this Control"
    END-POPUP
END-MENU

\ ---------------------------------------------------------------

: ComputeCursorShape    ( x y -- idc )
    HWND clirect GetClientRect DROP
    2DUP clirect rect.PtCode
    IF  2DROP
        IDC_CROSS   \ outside
    ELSE
        CAPTURE-MARGE DUP clirect rect.Right +! clirect rect.Bottom +!
        clirect rect.PtCode
        CASE    2 OF IDC_SIZEWE ENDOF
                8 OF IDC_SIZENS ENDOF
               10 OF IDC_SIZENWSE ENDOF
               IDC_SIZEALL SWAP
        ENDCASE
    THEN ;


: CallDefCtrlProc   ( msg -- res )
    DROP
    HWND GWL_USERDATA GetWindowLong
    HWND MSG WPARAM LPARAM CallWindowProc ;


: OnPaint  ( -- res )
    0 0 LOCALS| hbrush hdc |
    0 CallDefCtrlProc    \ s: res
    HWND GetParent GetDC TO hdc
    HWND GetFocus = IF $FF ELSE $FF8080 THEN CreateSolidBrush TO hbrush
    HWND HERE GetWindowRect DROP
    0 HWND GetParent HERE 2 MapWindowPoints DROP    \ s: res
    hdc HERE hbrush FrameRect DROP
    HWND GetParent hdc ReleaseDC DROP
    hbrush DeleteObject DROP ;

\ ---------------------------------------------------------------

: ctrlMove  ( hwnd dx dy -- )
    sRECT GetMem  LOCALS| ^rect dy dx hwnd |
    hwnd ^rect GetWindowRect DROP
    0 hwnd GetParent ^rect 2 MapWindowPoints DROP
    ^rect dx dy OffsetRect DROP
    grid-mode? IF ^rect rect>Grid THEN
    hwnd ^rect rect.GetOrg ^rect rect.GetSize TRUE MoveWindow DROP
    ^rect FreeMem
    hwnd UpdateWindow DROP ;

: ctrlSize  ( hwnd dx dy -- )
    sRECT GetMem  LOCALS| ^rect dy dx hwnd |
    hwnd ^rect GetWindowRect DROP
    0 hwnd GetParent ^rect 2 MapWindowPoints DROP
    dx ^rect rect.Right +!
    dy ^rect rect.Bottom +!
    hwnd ^rect rect.GetOrg ^rect rect.GetSize TRUE MoveWindow DROP
    ^rect FreeMem
    hwnd UpdateWindow DROP ;

\ ---------------------------------------------------------------

{ IsFocusedBrother?
    check hwnd
        is a child
        is not focused
        have a focused brother
            only then -> returns TRUE
}

: IsFocusedBrother?     ( hwnd -- flag )
    GetFocus OVER = IF DROP FALSE EXIT THEN
    GetParent GetFocus IsChild ;

: GetDeltaPosRectFocus  ( hwnd -- dxl dyt dxr dyb true | false )
    DUP IsFocusedBrother? 0= IF DROP FALSE EXIT THEN
    sRECT GetMem sRECT GetMem LOCALS| rectFocus rectMe |
    rectMe GetWindowRect DROP
    GetFocus rectFocus GetWindowRect DROP
    rectFocus rect.GetOrg rectMe rect.GetOrg pt.Sub
    rectFocus rect.GetExt rectMe rect.GetExt pt.Sub
    rectFocus FreeMem rectMe FreeMem
    TRUE ;

: GetDeltaSizeRectFocus ( hwnd -- ddx ddy true | false )
    DUP IsFocusedBrother? 0= IF DROP FALSE EXIT THEN
    sRECT GetMem sRECT GetMem LOCALS| rectFocus rectMe |
    rectMe GetWindowRect DROP \ s: hwnd
    GetFocus rectFocus GetWindowRect DROP
    rectFocus rect.GetSize rectMe rect.GetSize pt.Sub
    rectFocus FreeMem rectMe FreeMem
    TRUE ;


[SWITCH OnControlCommand ZERO  ( id -- res )

    ID-AL-LEFT      RUN:
        0
        HWND GetDeltaPosRectFocus -EXIT 3DROP
        HWND SWAP 0 ctrlMove ;

    ID-AL-RIGHT     RUN:
        0
        HWND GetDeltaPosRectFocus -EXIT DROP
        HWND SWAP 0 ctrlMove 2DROP ;

    ID-AL-TOP       RUN:
        0
        HWND GetDeltaPosRectFocus -EXIT 2DROP NIP
        HWND SWAP 0 SWAP ctrlMove ;

    ID-AL-BOTTOM    RUN:
        0
        HWND GetDeltaPosRectFocus -EXIT
        HWND SWAP 0 SWAP ctrlMove 3DROP ;

    ID-SI-WIDTH     RUN:
        0
        HWND DUP GetDeltaSizeRectFocus -EXIT \ s: hwnd ddx ddy
        DROP 0 ctrlSize ;

    ID-SI-HEIGHT    RUN:
        0
        HWND DUP GetDeltaSizeRectFocus -EXIT \ s: hwnd ddx ddy
        NIP 0 SWAP ctrlSize ;

    ID-SI-SAME      RUN:
        0
        HWND DUP GetDeltaSizeRectFocus -EXIT \ s: hwnd ddx ddy
        ctrlSize ;

    ID-DEF-TEXT     RUN:
        HWND InputCtrlSetting 0 ;

    ID-DELETECTRL   RUN:
        HWND GetParent
        HWND DestroyWindow DROP
        HWND Invalidate 0 ;

SWITCH]

: EDITCONTROL ( -- res )
   HWND InputCtrlSetting 0 EXIT tmrMenu0 RunPopupMenuTemplate 0 ;

\ ---------------------------------------------------------------

[SWITCH OnCtrlMsg CallDefCtrlProc ( id -- res )

    \ disable standard ctrl msg
    \ -------------------------
    WM_SETCURSOR        RUN: TRUE ;
    WM_NCHITTEST        RUN: HTCLIENT ;
    WM_MOUSEACTIVATE    RUN: MA_NOACTIVATE ;
    WM_MBUTTONDOWN      RUN: 0 ;
    WM_LBUTTONDBLCLK    RUN: EDITCONTROL ;
    WM_RBUTTONDBLCLK    RUN: 0 ;
    WM_MBUTTONDBLCLK    RUN: 0 ;
    WM_KEYDOWN          RUN: 0 ;
    WM_KEYUP            RUN: 0 ;
    WM_CHAR             RUN: 0 ;

    \ Show border and focused ctrl
    \ -----------------------------
    WM_PAINT            RUNS OnPaint

    \ mouse messages
    \ --------------
    WM_RBUTTONDOWN      RUN: EDITCONTROL ;
    WM_RBUTTONUP        RUN: 0 ;

    WM_LBUTTONDOWN      RUN:
        GetCapture 0=
        IF  HWND SetCapture DROP
            LPARAM iLOHI ptCapture pt.!
            HWND 0 ptCapture 1 MapWindowPoints DROP
            HWND SetFocus DROP
            HWND Invalidate
            0 TO grid-mode?
        THEN 0 ;

    WM_LBUTTONUP        RUN: \ <Ctrl> key disable grid-mode
        WPARAM MK_CONTROL AND 0= TO grid-mode?
        HWND 0 0 ctrlMove
        ReleaseCapture DROP
        HWND GetParent Invalidate
        0 ;

    WM_MOUSEMOVE        RUN:
        GetCapture 0=
        IF  LPARAM iLOHI ComputeCursorShape DUP TO nCaptureOperation
            0 SWAP LoadCursor SetCursor DROP
        ELSE
            ptCapture pt.@
            LPARAM iLOHI ptCapture pt.!
            HWND 0 ptCapture 1 MapWindowPoints DROP
            ptCapture pt.@
            2SWAP pt.Sub HWND -ROT
            nCaptureOperation
            CASE        \ s: hwnd dx dy
                IDC_SIZEWE   OF DROP 0 ctrlSize ENDOF
                IDC_SIZENS   OF NIP 0 SWAP ctrlSize ENDOF
                IDC_SIZENWSE OF ctrlSize ENDOF
                >R ctrlMove R>
            ENDCASE
        THEN 0 ;

    \ right-button popup-menu commands
    \ --------------------------------
    WM_COMMAND          RUN: WPARAM LOWORD OnControlCommand ;

    \ Menu items activation
    \ --------------------
    WM_INITMENU         RUN:
        0
        HWND IsFocusedBrother? ?EXIT
        ID-DEF-TEXT ID-AL-LEFT DO WPARAM I SetMenuItemOff LOOP ;

SWITCH]

\ ---------------------------------------------------------------

:NONAME     ( -- res )
    MSG OnCtrlMsg ; 4 CB: CtrlSuperProc#

: MakeSuperClass    ( hwnd -- )
    DUP GWL_WNDPROC CtrlSuperProc# SetWindowLong >R \ set new proc
    DUP GWL_USERDATA R> SetWindowLong DROP          \ save old proc
    WM_SETFONT  DEFAULT_GUI_FONT GetStockObject  TRUE  SendMessage DROP ;


\ ===============================================================
\ Dialog
\ ===============================================================

50  ENUM DLG_IDNEWCTRL
DROP 90
    ENUM DLG_DLGTITLE
    ENUM DLG_DELETECTRL
    ENUM DLG_AGAIN
DROP


MENU tmrMenu
    POPUP " "
        DLG_AGAIN           MENUITEM "Again"
        DLG_DLGTITLE        MENUITEM "Set Dialog Title"
        DLG_DELETECTRL      MENUITEM "Delete Selected Control"
        SEPARATOR
    END-POPUP
END-MENU

: FORMED ( ztext id -- )
   S" &" PAD ZPLACE  DIGIT SP@ 1 PAD ZAPPEND  DROP  S"  " PAD ZAPPEND
   ZCOUNT 1 /STRING  PAD ZAPPEND ;

: RunDlgPopupMenu  ( hwnd template -- )
    LoadMenuIndirect
    0 0 0 LOCALS| id name hsubmenu hmenu hwnd |
    hmenu 0 GetSubMenu DUP 0= ABORT" GetSubMenu" TO hsubmenu
    BEGIN id PatternName[] WHILE \ s: szName
        id FORMED
        hsubmenu MF_STRING id DLG_IDNEWCTRL + PAD AppendMenu DROP
        1 +TO id
    REPEAT
    hsubmenu
    [ TPM_LEFTALIGN TPM_LEFTBUTTON OR TPM_RIGHTBUTTON OR ] LITERAL
    HERE DUP GetCursorPos DROP 2@ SWAP
    0 hwnd 0 TrackPopupMenu DROP
    hmenu DestroyMenu DROP ;

\ ---------------------------------------------------------------

[SWITCH OnCommand DROP ( id -- )

    DLG_DLGTITLE        RUN:
        HWND PAD 80 GetWindowText DROP
        PAD InputBox 0= ?EXIT
        HWND PAD SetWindowText DROP ;

    DLG_DELETECTRL      RUN:
        HWND GetFocus IsChild 0= IF 0 EXIT THEN
        GetFocus DestroyWindow DROP
        HWND Invalidate ;

SWITCH]

\ ---------------------------------------------------------------

: OnPaintCtrl  ( hwnd -- res )
    0 0 0 LOCALS| ^ps ^rect hdc hwnd |
    sRECT GetMem TO ^rect
    sPAINTSTRUCT GetMem TO ^ps
    \
    hwnd ^ps BeginPaint TO hdc
    hwnd ^rect GetClientRect DROP
    ^rect rect.Right @ 0
    DO  ^rect rect.Bottom @ 0
        DO  hdc J I $8000 SetPixelV DROP
            YGRID 2* +LOOP
        XGRID 2* +LOOP
    hwnd ^ps EndPaint DROP
    ^ps FreeMem
    ^rect FreeMem
    0 ;

: SetEditDlgStyles  ( hwnd -- )
    >R R@ GWL_STYLE GetWindowLong
    [ WS_SYSMENU WS_THICKFRAME OR WS_BORDER OR ] LITERAL OR
    R> GWL_STYLE ROT SetWindowLong DROP ;

: SuperClassControls  ( hwnd -- )
    ['] MakeSuperClass EnumControls ;


: SearchControlPattern   ( hCtrl -- n true | false )
    >R R@ PAD 80 GetClassName 0= ABORT" GetClassName" 0 \ s: n=0
    BEGIN DUP PatternClassName[] WHILE      \ s: n szName
        ZCOUNT PAD ZCOUNT COMPARE(NC) 0=    \ s: n flag
        IF  R@ GWL_STYLE GetWindowLong      \ s: n styles
            OVER PatternControlStyle[] DROP \ s: n styles ctrl-styles
            SWAP OVER OR =                  \ s: n flag
            IF  R> DROP
                TRUE EXIT
            THEN
        THEN
        1+                                  \ s: n++
    REPEAT
    R> 2DROP FALSE ;


: (greater-id)  ( n hCtrl -- n' )
    GWL_ID GetWindowLong 2DUP > IF DROP ELSE NIP THEN ;

: FindGreaterCtrlID ( hParent -- id )
    99 SWAP ['] (greater-id) EnumControls ;


: (RememberCtrlSize)   ( cx cy nPtrn hCtrl -- cx cy nPtrn )
    >R R@ SearchControlPattern
    IF  OVER =
        IF  NIP NIP
            R@ PAD GetWindowRect DROP
            PAD rect.GetSize ROT
        THEN
    THEN
    R> DROP ;

: RememberCtrlSize  ( nPtrn hParent -- cx cy )
    >R DUP PatternDefaultSize[] DROP ROT R>  \ s: cx cy nPtrn hParent
    ['] (RememberCtrlSize) EnumControls DROP ;


: DROP1+   ( n hwnd -- n+1 ) DROP 1+ ;

: GetControlCount   ( hwnd -- n )
    0 SWAP ['] DROP1+ EnumControls ;


: InsertNewControl  ( nPtrn hParent -- hwnd )
    LOCALS| hParent nPtrn |
    0
    nPtrn PatternClassName[] DROP
    Z" ?"
    nPtrn PatternControlStyle[] DROP
    HERE GetCursorPos DROP hParent HERE 2@ SWAP pt.ScreenToClient xy>Grid
    nPtrn hParent RememberCtrlSize
    hParent
    hParent FindGreaterCtrlID 1+
    HINST
    0
    CreateWindowEx ;

\ ---------------------------------------------------------------

: ClipboardCopyResult?  ( hwnd -- y|n|c )
    Z" OK to copy resulting dlg-template to the clipboard ?"
    Z" Confirm"
    MB_YESNOCANCEL
    MessageBox ;

0 VALUE (hMem)  \ handle
0 VALUE (pMem)  \ pointer

sRECT BUFFER: rtmp

: ClipOpenMem   ( -- )
    GMEM_DDESHARE GHND OR 16384
    GlobalAlloc DUP 0= ABORT" GlobalAlloc failed" TO (hMem)
    (hMem) GlobalLock TO (pMem)
    (pMem) OFF ;

: $>>   ( szStr -- )    ZCOUNT (pMem) ZAPPEND ;
: bl>>  ( -- )          Z"  " $>> ;
: $bl>> ( sz -- )       $>> bl>> ;
: eol>> ( -- )          Z\" \n" $>> (pMem) ZCOUNT CHARS + TO (pMem) ;
: i>>   ( i -- )        DUP ABS 0 <# #S ROT SIGN #> OVER + OFF $bl>> ;
: ">>   ( -- )          Z\" \"" $>> ;

: iL>>  ( i #char -- )
   >R  DUP ABS 0 <# #S ROT SIGN #>  DUP>R
   OVER + OFF $bl>>
   R> R> SWAP ( cnt ) - 0 MAX 0 ?DO bl>> LOOP ;


: tab>> ( n -- )
    (pMem) ZLENGTH - DUP 1 < IF DROP bl>> EXIT THEN
    (pMem) ZCOUNT CHARS +
    SWAP 2DUP BL FILL
    CHARS + OFF ;

: FinalizeClipboard  ( hwnd -- )
    (hMem) GlobalUnlock DROP
    \ -> clipboard
    OpenClipboard 0= ABORT" cannot open clipboard"
    EmptyClipboard DROP
    CF_TEXT (hMem) SetClipboardData DROP
    CloseClipboard 0= ABORT" cannot close clipboard" ;

: OutputHeader  ( hwnd -- )
    >R
    R@ BOX-TITLE 250 GetWindowText DROP
    BOX-TITLE ZCOUNT UNSPACED
    Z" DIALOG " $>> BOX-TITLE $>> Z" -TEMPLATE" $>> eol>>
    Z\" [MODAL \" " $>>
    R@ PAD 80 GetWindowText DROP PAD $>> Z\" \" " $>>
    R@ rtmp GetClientRect DROP \ NB: bug GetWindowRect ???
    rtmp rect.MakeDlgUnits
\    0 R@ GetParent rtmp 2 MapWindowPoints DROP
\    rtmp rect.MakeDlgUnits
    ( rtmp rect.GetOrg swap ) 20 DUP i>> i>>
    rtmp rect.GetSize SWAP i>> i>>
    Z" ]" $>> eol>>
    R> DROP ;

: OutputControl ( hCtrl -- )
    >R R@ SearchControlPattern 0= IF R> DROP EXIT THEN  \ s: nPtrn
    bl>> DUP PatternName[] DROP $>> 20 tab>>
    PatternSchema[] DROP
    CASE
        SCHEMA0 OF
            R@ PAD 80 GetWindowText 0>
            IF  Z\" \" " $>>
                PAD $>> ">>
            THEN ENDOF

        SCHEMA2 OF
            Z" ?? RESOURCE" $>>
            ENDOF
    ENDCASE
    50 tab>> R@ GWL_ID GetWindowLong CASE
    IDOK     OF  Z" IDOK"     $>>  ENDOF
    IDCANCEL OF  Z" IDCANCEL" $>>  ENDOF
    DUP i>>
    ENDCASE
    R@ rtmp GetWindowRect DROP 0 R@ GetParent rtmp 2 MapWindowPoints DROP
    rtmp rect.MakeDlgUnits
    60 tab>> rtmp rect.GetOrg  SWAP 3 iL>> 3 iL>>
    rtmp rect.GetSize SWAP 3 iL>> 3 iL>>
    Z" ]" $>> eol>>
    R> DROP ;

: OutputControls ( hParent -- )
    ['] OutputControl EnumControls ;

DEFER CodeGenerator ( hParent -- )   ' DROP IS CodeGenerator

: PutResultToClipboard  ( hwnd -- )
    ClipOpenMem
    DUP OutputHeader
    DUP OutputControls
    Z" END-DIALOG" $>> eol>> eol>>
    DUP CodeGenerator
    FinalizeClipboard ;


\ ---------------------------------------------------------------

0 VALUE PENULT

: NEWCONTROL ( id -- )   DUP TO PENULT
   DLG_IDNEWCTRL - HWND InsertNewControl ?DUP
   IF DUP MakeSuperClass          \ s: hwnd
      HWND GetControlCount 1 =    \ alone - become referencer
      IF  DUP SetFocus DROP Invalidate
      ELSE DROP
      THEN
   THEN ;

[+SWITCH OnCommand
    DLG_AGAIN RUN: PENULT NEWCONTROL ;
SWITCH]

[SWITCH OnMessage ZERO  ( msg -- res )

    WM_CLOSE    RUN:
        HWND ClipboardCopyResult?
        CASE
            IDNO    OF HWND TRUE EndDialog ENDOF
            IDYES   OF HWND PutResultToClipboard HWND TRUE EndDialog ENDOF
        ENDCASE 0 ;

    WM_COMMAND  RUN:
        WPARAM LOWORD DUP DLG_IDNEWCTRL >=
        SWAP DLG_DLGTITLE < AND
        IF   WPARAM LOWORD NEWCONTROL
        ELSE WPARAM LOWORD OnCommand
        THEN 0 ;

    WM_INITDIALOG RUN:
        HWND SetEditDlgStyles
        HWND SuperClassControls
        HWND ForceGuiFont
        TRUE ;

    WM_PAINT RUN:
        HWND OnPaintCtrl ;

    WM_RBUTTONDOWN  RUN: ( -- res )
        HWND LPARAM iLOHI pt.ClientToScreen   \ s: x y
        HWND tmrMenu RunDlgPopupMenu
        SetCursorPos DROP
        0 ;

    \ dialog not subclassed: cannot trap those msg
    WM_KEYDOWN          RUN: 0 ;
    WM_KEYUP            RUN: 0 ;
    WM_CHAR             RUN: 0 ;

    WM_INITMENU         RUN:  \ WPARAM is hMenu
        HWND GetControlCount 0=
        IF WPARAM DLG_DELETECTRL SetMenuItemOff THEN 0 ;


SWITCH]

\ ---------------------------------------------------------------

:NONAME     ( -- res )
    MSG OnMessage ; 4 CB: BoxEdProc

DIALOG BasicTemplate
[MODAL " Dialog Template" 20 20 160 70 (+STYLE WS_THICKFRAME) ]
[DEFPUSHBUTTON     " OK"                         1    8   52  40  12 ]
[PUSHBUTTON        " Cancel"                     2    120 52  40  12 ]
END-DIALOG

\ =============================================================

: Run   ( template|0 -- flag ) \ codable version
    ?DUP 0= IF BasicTemplate THEN
    HINST SWAP HWND BoxEdProc 0 DialogBoxIndirectParam ;

PUBLIC

: Boxed ( template|0 -- )   \ console version
    Run DROP ;

END-PACKAGE

{ ====================================================================
(C) Copyright 1999 FORTH, Inc.   www.forth.com

Runtime code output by Rick VanNorman
==================================================================== }

PACKAGE BOXER

: EXPANDZ ( zstr zaddr xt -- zstr zaddr2 xt )
   >R BEGIN
      DUP C@ WHILE
      DUP C@ [CHAR] % = IF
         OVER R@ EXECUTE 1+
      ELSE
         COUNT SP@ R@ EXECUTE DROP
      THEN
   REPEAT 1+ R> ;

: EXPANDING ( zstr addr xt -- )
   BEGIN  OVER @ WHILE EXPANDZ REPEAT 3DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CREATE GENERIC-COMMANDSWITCH
   ,Z\" [SWITCH %-COMMANDS DROP ( wparam -- )\n"
   ,Z\"    IDOK RUN: HWND 0 EndDialog ;\n"
   ,Z\"    IDCANCEL RUN: HWND 0 EndDialog ;\n"

   0 ,

: OutputCommand ( hCtrl -- )
   GWL_ID GetWindowLong CASE
          IDOK OF ENDOF
      IDCANCEL OF ENDOF
   ENDCASE ;

: OutputCommandSwitch ( hCtrl -- )
   BOX-TITLE GENERIC-COMMANDSWITCH ['] $>> EXPANDING
   ( hparent) ['] OutputCommand EnumControls
   Z\" SWITCH]\n\n" $>> ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CREATE GENERIC-TEMPLATE
   ,Z\" [SWITCH %-MESSAGES ZERO ( msg -- res )\n"
   ,Z\"    WM_COMMAND RUN: WPARAM LOWORD %-COMMANDS ;\n"
   ,Z\"    WM_INITDIALOG  RUN: NOOP ;\n"
   ,Z\" SWITCH]\n\n"

   ,Z\" :NONAME ( -- res )   MSG LOWORD %-MESSAGES ;  4 CB: %-CALLBACK\n\n"

   ,Z\" : % ( hwnd -- res )\n"
   ,Z\"    HINST %-TEMPLATE ROT %-CALLBACK 0 DialogBoxIndirectParam ;\n\n"

   ,Z\" : GO ( -- )   HWND % DROP ;\n\n"

   0 ,

: OutputDialogCode ( -- )
   BOX-TITLE GENERIC-TEMPLATE ['] $>> EXPANDING ;

: OutputRuntime ( hParent -- )
    OutputCommandSwitch OutputDialogCode ;

' OutputRuntime IS CodeGenerator

END-PACKAGE


{ --------------------------------------------------------------------
Testing
-------------------------------------------------------------------- }

EXISTS RELEASE-TESTING [IF] VERBOSE

0 BOXED

BYE  [THEN]
