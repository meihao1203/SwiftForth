{ ====================================================================
Configuration of the MONITORS flags

Copyright 2001  FORTH, Inc.
Rick VanNorman
==================================================================== }

PACKAGE FILE-TOOLS-CONFIG

FILE-TOOLS +ORDER

CREATE MONITORS-DEFAULT   4 ,

: HASNT-MONITORS ( -- flag )   GETREGKEY >R
   PAD CELL Z" MONITORS" R@ READ-REG 0<> NIP
   R> RegCloseKey DROP ;

: READ-MONITORS ( -- )   GETREGKEY >R
   MONITORS CELL Z" MONITORS" R@ READ-REG 2DROP
   R> RegCloseKey DROP ;

: WRITE-MONITORS ( -- )   GETREGKEY >R
   MONITORS CELL Z" MONITORS" R@ WRITE-REG DROP
   R> RegCloseKey DROP ;

101 ENUM DI_APPLY
    ENUM DI_DFLT
    ENUM DI_STACK
    ENUM DI_HERE
    ENUM DI_TEXT
    ENUM DI_HIGH
    ENUM DI_EXEC
    ENUM DI_WORD
    ENUM DI_KEYS
DROP

DIALOG (MONITORS-CONFIG)
   [MODAL  " Included File Monitoring Options"
                   (FONT 8, MS Sans Serif)          10   10  205   90 ]

\  [control        " default text"        id      xpos ypos xsiz ysiz ]
   [DEFPUSHBUTTON  " OK"                  IDOK       5   70   45   15 ]
   [PUSHBUTTON     " Cancel"              IDCANCEL  55   70   45   15 ]
   [PUSHBUTTON     " &Apply"              DI_APPLY 105   70   45   15 ]
   [PUSHBUTTON     " &Defaults"           DI_DFLT  155   70   45   15 ]
   [CHECKBOX       " Display the stack before each line is interpreted"
                                          DI_STACK   5    5  200   10 ]
   [CHECKBOX       " Display HERE before each line is interpreted"
                                          DI_HERE    5   15  200   10 ]
   [CHECKBOX       " Display the text of each line"
                                          DI_TEXT    5   25  200   10 ]
   [CHECKBOX       " Highlight the text of the line"
                                          DI_HIGH    5   35  200   10 ]
   [CHECKBOX       " Execute"             DI_EXEC    5   45   38   10 ]
   [EDITTEXT                              DI_WORD   46   45  155   10
                                              (+STYLE ES_AUTOHSCROLL) ]
   [CHECKBOX       " Monitor keyboard for ESC to terminate INCLUDE"
                                          DI_KEYS    5   55  200   10 ]

END-DIALOG

VARIABLE MONITORS-TEMP

: MONITORS-CLOSE-DIALOG ( -- res )   HWND 0 EndDialog ;

: CHECK-APPLY ( -- )
   MONITORS-TEMP @ MONITORS @ <>
   HWND DI_APPLY GetDlgItem SWAP EnableWindow DROP
   MONITORS-TEMP @ MONITORS-DEFAULT @ <>
   HWND DI_DFLT GetDlgItem SWAP EnableWindow DROP ;

: CHECK-STACK ( -- )   HWND DI_STACK MONITORS-TEMP @ 1 AND IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-STACK ( -- )   MONITORS-TEMP
   DUP @ 1 XOR SWAP !  CHECK-STACK ;

: CHECK-HERE ( -- )   HWND DI_HERE MONITORS-TEMP @ 2 AND IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-HERE ( -- )   MONITORS-TEMP
   DUP @ 2 XOR SWAP !  CHECK-HERE ;

: CHECK-TEXT ( -- )   HWND DI_TEXT MONITORS-TEMP @ 4 AND IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-TEXT ( -- )   MONITORS-TEMP
   DUP @ 4 XOR SWAP !  CHECK-TEXT ;

: CHECK-HIGH ( -- )   HWND DI_HIGH MONITORS-TEMP @ 0< IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-HIGH ( -- )   MONITORS-TEMP
   DUP @ $80000000 XOR SWAP !  CHECK-HIGH ;

: FOCUS-WORD ( -- )   HWND DI_WORD GetDlgItem SetFocus DROP ;

: CHECK-EXEC ( -- )   HWND DI_EXEC MONITORS-TEMP @ 8 AND IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-EXEC ( -- )   MONITORS-TEMP
   DUP @ 8 XOR SWAP !  CHECK-EXEC  FOCUS-WORD ;

: CHECK-WORD ( -- )   'MONITOR @ ?DUP IF
      DUP ORIGIN < IF  >CODE DUP (.') ( a nfa)
         COUNT 2DUP 2>R  + 1+ -  0= IF
            2R> PAD ZPLACE  HWND DI_WORD PAD SetDlgItemText DROP  EXIT
   THEN  2R>  THEN  THEN  HWND DI_WORD Z" NOOP" SetDlgItemText DROP
   0 'MONITOR ! ;

: SET-EXEC-WORD ( -- )
   WPARAM HIWORD EN_KILLFOCUS = IF
      HWND DI_WORD PAD 1+ 255 GetDlgItemText PAD C!
      PAD COUNT FORTH-WORDLIST SEARCH-WORDLIST IF  'MONITOR !
      ELSE  HWND Z" Word not found in FORTH wordlist"
         Z" Error" MB_OK MessageBox DROP
      THEN  CHECK-WORD
   THEN ;

: CHECK-KEYS ( -- )   HWND DI_KEYS MONITORS-TEMP @ 16 AND IF
      BST_CHECKED  ELSE  BST_UNCHECKED
   THEN  CheckDlgButton DROP ;

: TOGGLE-CHECK-KEYS ( -- )   MONITORS-TEMP
   DUP @ 16 XOR SWAP !  CHECK-KEYS ;

: FETCH-MONITORS ( -- )   CHECK-STACK  CHECK-HERE  CHECK-TEXT
   CHECK-HIGH  CHECK-EXEC  CHECK-KEYS  CHECK-WORD ;
: START-MONITORS ( -- )   MONITORS @
   MONITORS-TEMP !  FETCH-MONITORS ;

: DEFAULT-MONITORS ( -- )   MONITORS-DEFAULT @
   MONITORS-TEMP !  FETCH-MONITORS ;

: UPDATE-MONITORS ( -- )   MONITORS-TEMP @ MONITORS !
   WRITE-MONITORS  CHECK-APPLY ;

[SWITCH MONITORS-COMMANDS ZERO ( -- res )
   IDOK     RUN:  UPDATE-MONITORS  MONITORS-CLOSE-DIALOG ;
   IDCANCEL RUN:  MONITORS-CLOSE-DIALOG ;
   DI_APPLY RUN:  UPDATE-MONITORS  0 ;
   DI_DFLT  RUN:  DEFAULT-MONITORS  CHECK-APPLY  0 ;
   DI_STACK RUN:  TOGGLE-CHECK-STACK  CHECK-APPLY  0 ;
   DI_HERE  RUN:  TOGGLE-CHECK-HERE  CHECK-APPLY  0 ;
   DI_TEXT  RUN:  TOGGLE-CHECK-TEXT  CHECK-APPLY  0 ;
   DI_HIGH  RUN:  TOGGLE-CHECK-HIGH  CHECK-APPLY  0 ;
   DI_EXEC  RUN:  TOGGLE-CHECK-EXEC  CHECK-APPLY  0 ;
   DI_KEYS  RUN:  TOGGLE-CHECK-KEYS  CHECK-APPLY  0 ;
   DI_WORD  RUN:  SET-EXEC-WORD  0 ;
SWITCH]

[SWITCH MONITORS-MESSAGES ZERO
   WM_CLOSE      RUNS  MONITORS-CLOSE-DIALOG
   WM_INITDIALOG RUN:  READ-MONITORS  START-MONITORS
                       UPDATE-MONITORS  -1 ;
   WM_COMMAND    RUN:  WPARAM LOWORD MONITORS-COMMANDS ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD MONITORS-MESSAGES ; 4 CB: RUN-MONITORS

PUBLIC

: MONITORS-CONFIG ( -- )
   HINST  (MONITORS-CONFIG)  HWND  RUN-MONITORS
   0 DialogBoxIndirectParam DROP ;

FILE-TOOLS -ORDER

{ --------------------------------------------------------------------
File include monitoring
-------------------------------------------------------------------- }

CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_MONCFG      RUNS MONITORS-CONFIG
SWITCH]

CONSOLE-WINDOW -ORDER

[THEN]



END-PACKAGE

