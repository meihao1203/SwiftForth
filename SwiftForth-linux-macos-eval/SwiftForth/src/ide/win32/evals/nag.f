{ ----------------------------------------------------------------------
Nag screen
Rick VanNorman 27Sep2011

**experimental -- not used at this time**
---------------------------------------------------------------------- }

DIALOG NAG-TEMPLATE
   [MODAL " SwiftForth"  10 10 100 65  (CLASS SFDLG)  (FONT 9, Fixedsys) ]

   [DEFPUSHBUTTON " QUIT"                  IDCANCEL       5  45   40 15 ]
   [DEFPUSHBUTTON " OK"                    IDOK          55  45   40 15 ]
   [CTEXT         " Please type the word"  -1             5   5   90 10 ]
   [CTEXT                                  1001           5  15   90 10 ]
   [EDITTEXT                               1002          25  25   50 12 ]
END-DIALOG

GENERICDIALOG SUBCLASS NAGBOX-DIALOG

   : TEMPLATE ( -- a )   NAG-TEMPLATE ;

   : REWORD ( -- )
      UCOUNTER DROP 7 AND CASE
         0 OF  ['] CREATE   ENDOF
         1 OF  ['] VARIABLE ENDOF
         2 OF  ['] CONSTANT ENDOF
         3 OF  ['] HERE     ENDOF
         4 OF  ['] CMOVE    ENDOF
         5 OF  ['] DUP      ENDOF
         6 OF  ['] ROT      ENDOF
         7 OF  ['] SWAP     ENDOF
      ENDCASE  >NAME COUNT PAD ZPLACE
      mHWND 1001 PAD SetDlgItemText DROP ;

   WM_INITDIALOG MESSAGE:
      REWORD  mHWND 1002 GetDlgItem SetFocus DROP  0 ;

   IDCANCEL COMMAND:
      0 ExitProcess ;

   IDOK COMMAND:
      mHWND 1002 PAD  32 GetDlgItemText DROP
      mHWND 1001 HERE 32 GetDlgItemText DROP
      PAD ZCOUNT HERE ZCOUNT COMPARE IF REWORD ELSE CLOSE-DIALOG THEN ;


   \ The timer routine is buried here to make it harder to find
   \ in object code. It sets the 999 timer for the given window
   \ to expire in 5 to 13 minutes.

   : TIMER ( hwnd -- )
      ( h) 999  5  uCOUNTER DROP 7 AND +  60000 *   0 SetTimer DROP ;

END-CLASS

: TEST ( -- )
   [OBJECTS NAGBOX-DIALOG MAKES NAG OBJECTS]
   HWND NAG MODAL DROP ;

{ ----------------------------------------------------------------------
Insert into swiftforth's main loop with a timer
Piggy-back into the existing tty wm_timer handler
---------------------------------------------------------------------- }

TTY-WORDS +ORDER

[+SWITCH TTY-MESSAGES
   WM_TIMER RUN:
      WPARAM 999 = IF
         HWND 999 KillTimer DROP ( not reentrant)
         [OBJECTS NAGBOX-DIALOG MAKES NAG OBJECTS]
         HWND NAG MODAL DROP
         HWND NAG TIMER
      ELSE DO-TIMER
      THEN ;
   WM_CREATE RUN:
      CREATE-WINDOW
         [OBJECTS NAGBOX-DIALOG MAKES NAG OBJECTS]
         HWND NAG TIMER
         0 ;
SWITCH]

TTY-WORDS -ORDER
