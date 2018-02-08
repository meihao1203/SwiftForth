{ ====================================================================
Tabbed dialog

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL TABBED A tabbed dialog skeleton

{ --------------------------------------------------------------------
These dialogs are nearly identical, but serve as an example of
a tabbed dialog. They do not have to be similar except in the actual
size of the dialog itself.
-------------------------------------------------------------------- }

0 VALUE APP-HWND

LIBRARY USER32

FUNCTION: MessageBeep ( uType -- b )

{ --------------------------------------------------------------------
First page
-------------------------------------------------------------------- }

100 ENUM IDC_EDIT1
    ENUM IDC_LIST1
    DROP

DIALOG (TAB1)
   [MODELESS 4 21 172 95
   (STYLE WS_CHILD WS_VISIBLE WS_BORDER)
   (FONT 8, MS Sans Serif) ]

   [LTEXT     " Enter City Name:"      -1          20  6   59 10 ]
   [EDITTEXT                           IDC_EDIT1   20 17  110 12 (+STYLE ES_AUTOHSCROLL) ]
   [LTEXT     " Hotel List:"           -1          20 32   37  8 ]
   [LISTBOX                            IDC_LIST1   20 42  110 32 (+STYLE LBS_SORT WS_VSCROLL WS_TABSTOP) ]
   [PUSHBUTTON " &OK"                  IDOK        25 74   40 14 ]
   [PUSHBUTTON " &Cancel"              IDCANCEL    84 74   40 14 ]
END-DIALOG

[SWITCH TAB1-COMMANDS ZERO ( command -- res )
   IDOK     RUN:  0 MessageBeep DROP 0 ;
   IDCANCEL RUN:  HWND DestroyWindow DROP
                  APP-HWND DestroyWindow DROP 0 ;
SWITCH]

[SWITCH TAB1-MESSAGES ZERO ( msg -- res )
   WM_ACTIVATE RUNS MODELESS-ACTIVATE
   WM_COMMAND  RUN: WPARAM LOWORD TAB1-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD TAB1-MESSAGES ;  4 CB: RUNTAB1

{ --------------------------------------------------------------------
Second page
-------------------------------------------------------------------- }

100 ENUM IDC_EDIT2
    ENUM IDC_LIST2
    DROP

DIALOG (TAB2)
   [MODELESS  4 21 172 95
   (STYLE WS_CHILD WS_VISIBLE WS_BORDER)
   (FONT 8, MS Sans Serif) ]

   [LTEXT     " Enter District Name:"  -1          20  6   59 10 ]
   [EDITTEXT                           IDC_EDIT2   20 17  110 12 (+STYLE ES_AUTOHSCROLL) ]
   [LTEXT     " Restaurant List:"      -1          20 32   37  8 ]
   [LISTBOX                            IDC_LIST2   20 42  110 32 (+STYLE LBS_SORT WS_VSCROLL WS_TABSTOP) ]
   [PUSHBUTTON " &OK"                  IDOK        25 74   40 14 ]
   [PUSHBUTTON " &Cancel"              IDCANCEL    84 74   40 14 ]
END-DIALOG

[SWITCH TAB2-COMMANDS ZERO ( command -- res )
   IDOK     RUN:  0 MessageBeep DROP 0 ;
   IDCANCEL RUN:  HWND DestroyWindow DROP
                  APP-HWND DestroyWindow DROP 0 ;
SWITCH]

[SWITCH TAB2-MESSAGES ZERO ( msg -- res )
   WM_COMMAND RUN: WPARAM LOWORD TAB2-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD TAB2-MESSAGES ;  4 CB: RUNTAB2


{ ====================================================================
Standard window template
==================================================================== }

CREATE APP-NAME   ,Z" AppName"
CREATE APP-TITLE  ,Z" Application Title"


[SWITCH APP-MESSAGES DEFWINPROC ( msg -- res )
   WM_DESTROY RUN: ( 0 PostQuitMessage DROP ) 0 ;   \
SWITCH]

:NONAME  MSG LOWORD APP-MESSAGES ; 4 CB: APP-WNDPROC

: /APP-WINDOW ( cmdshow -- hwnd )   >R
      0                                 \ extended style
      APP-NAME                          \ window class name
      APP-TITLE                         \ window caption
      WS_OVERLAPPEDWINDOW               \ window style
      10 10 600 400                     \ position and size
      0                                 \ parent window handle
      0                                 \ window menu handle
      HINST                             \ program instance handle
      0                                 \ creation parameter
   CreateWindowEx ?DUP IF
      DUP TO APP-HWND
      DUP R> ShowWindow DROP
      DUP UpdateWindow DROP
   ELSE
      R> DROP
   THEN ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: Z ( -- )
   APP-NAME APP-WNDPROC DefaultClass DROP
   SW_SHOWNORMAL /APP-WINDOW DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

CREATE WC_TABCONTROL ,Z" SysTabControl32"

CREATE TCITEMS   256 ALLOT

0 VALUE HWND-TAB

: TEST
   APP-HWND PAD GetClientRect DROP
   0 WC_TABCONTROL 0
   WS_CHILD WS_CLIPSIBLINGS OR WS_VISIBLE OR
   PAD @RECT
   APP-HWND
   1000
   HINST
   0
   CreateWindowEx TO HWND-TAB ;

CREATE TAB1-TEXT   ,Z" TAB 1"
CREATE TAB2-TEXT   ,Z" TAB 2"

CREATE =TAB1
   TCIF_TEXT ,  \ value specifying which members to retrieve or set
   0 ,          \ reserved; do not use
   0 ,          \ reserved; do not use
   TAB1-TEXT ,  \ pointer to string containing tab text
   0 ,          \ size of buffer pointed to by the pszText member
   0 ,          \ index to tab control's image
   0 ,          \ application-defined data associated with tab

CREATE =TAB2
   TCIF_TEXT ,  \ value specifying which members to retrieve or set
   0 ,          \ reserved; do not use
   0 ,          \ reserved; do not use
   TAB2-TEXT ,  \ pointer to string containing tab text
   0 ,          \ size of buffer pointed to by the pszText member
   0 ,          \ index to tab control's image
   0 ,          \ application-defined data associated with tab


: TRY ( -- )
   HWND-TAB -EXIT
   HWND-TAB TCM_INSERTITEMA 0 =TAB1 SendMessage DROP
   HWND-TAB TCM_INSERTITEMA 1 =TAB2 SendMessage DROP ;


0 VALUE HTAB1
0 VALUE HTAB2

: TAB2 ( -- hwnd )
   HINST (TAB2) HWND-TAB RUNTAB2 0 CreateDialogIndirectParam ;

: TAB1 ( -- hwnd )
   HINST (TAB1) HWND-TAB RUNTAB1 0 CreateDialogIndirectParam ;

: FOO ( -- )
   HWND-TAB -EXIT
   TAB1 TO HTAB1  TAB2 TO HTAB2
   HTAB1 SW_SHOW ShowWindow DROP
   HTAB2 SW_HIDE ShowWindow DROP ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: TAB-NOTIFY ( -- res )
   LPARAM 2 CELLS + @ TCN_SELCHANGE = IF
      LPARAM @ TCM_GETCURSEL 0 0 SendMessage CASE
         0   OF HTAB1 HTAB2 ENDOF
         1   OF HTAB2 HTAB1 ENDOF
         DUP OF HTAB1 HTAB2 ENDOF
      ENDCASE SW_HIDE ShowWindow DROP SW_SHOW ShowWindow DROP
   THEN 0 ;

[+SWITCH APP-MESSAGES
   WM_NOTIFY RUNS TAB-NOTIFY
SWITCH]

: DEMO  Z TEST TRY FOO ;

CR
CR .( Type DEMO to run the tabbed dialog.)
CR
