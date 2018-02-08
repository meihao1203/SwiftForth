{ ====================================================================
Optional included files

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
Optional packages are defined by their presence in a fixed set of
directories (relative to the bin\ directory where the .exe is).

To be considered an optional file, one line within the first 10 of the
file must begin with the word OPTIONAL. This is followed by a name
representing the package, which is followed by a description of the
package.

The tag, name, and description must be on the first line of the
file, and may not total more than 250 characters.

Optional packages are loaded only once. They may be included as
normal, or via REQUIRES, or via the optional packages menu/dialog.

OPTIONAL <name> <descriptive text, one line, less than 200 chars>

While not including a file:

All text to the end of the line will be ignored.  OPTIONAL is
considered to be valid only while including a file.

While including a file:

If name exists in the LOADED-OPTIONS wordlist, ignore the rest of the
file.  If name does not exist in the LOADED-OPTIONS wordlist, construct
a dictionary entry for name there and ignore the rest of the line.

In the specific directories

        %SwiftForth\lib\samples\
        %SwiftForth\lib\samples\win32\
        %SwiftForth\lib\options\
        %SwiftForth\lib\options\win32\

-------------------------------------------------------------------- }

PACKAGE OPTIONAL-STUFF

1 STRANDS CONSTANT LOADED-OPTIONS

: OPTION-LOADED? ( addr len -- flag )
   LOADED-OPTIONS SEARCH-WORDLIST DUP IF NIP THEN ;

: .OPTION ( nfa -- )
   CR DUP H.8 SPACE DUP COUNT BRIGHT TYPE NORMAL SPACE NAME> >BODY COUNT TYPE ;

PUBLIC

: .OPTIONS ( -- )
   LOADED-OPTIONS WID> CELL+ BEGIN
      @REL ?DUP WHILE
      DUP L>NAME .OPTION
   REPEAT ;

: OPTIONAL ( -- )
   SOURCE=FILE IF
      BL WORD COUNT 2DUP OPTION-LOADED? IF
         2DROP \\ EXIT
      THEN
      LOADED-OPTIONS (WID-CREATE)
      /SOURCE STRING,
   THEN POSTPONE \ ;

{ ------------------------------------------------------------------------
Define the dialog for browsing optional packages
------------------------------------------------------------------------ }

100 ENUM IDOPTIONS
    ENUM IDFNAME
    ENUM IDDESC
    ENUM IDINSTALLED
DROP

DIALOG (OBOX)

   [MODAL " Load options"  10 10 200 95  (FONT 8, MS Sans Serif) ]

   [DEFPUSHBUTTON " Ok"      IDOK      100 75 30 12 ]
   [PUSHBUTTON    " Cancel"  IDCANCEL  140 75 30 12 ]

   [LISTBOX  IDOPTIONS  5 15 70 90 (+STYLE LBS_SORT WS_VSCROLL) ]

   [LTEXT    IDFNAME      5  2 190 10 ]
   [TEXTBOX  IDDESC      80 15 115 40 ]
   [LTEXT    IDINSTALLED " Installed" 100 77  30 12 ]

END-DIALOG

{ --------------------------------------------------------------------
ZSCAN looks for the end of zstring.

.INSTALLED makes enables either the OK button or the "installed"
   text and disables the other.

(OBOX-UPDATE) uses the data associated with the current listbox
   selection to update the title, description, and installed status.

OBOX-UPDATE filters to only update the data if the selection changes.

OBOX-INIT assumes that LPARAM points to an array of data in memory
   which is parsed to create the listbox information. Each listbox
   item is associated with its address in the table, so that the
   update routines can access the option name and description.

OBOX-CANCEL simply ends the dialog.

OBOX-CLOSE returns the address of the data of the selected option.
-------------------------------------------------------------------- }

: ZSCAN ( z -- z' )   65536 0 SCAN DROP 1+ ;

: .INSTALLED ( addr n -- )
   IDINSTALLED IDOK  2SWAP  OPTION-LOADED? IF SWAP THEN
   HWND SWAP GetDlgItem SW_SHOW ShowWindow DROP
   HWND SWAP GetDlgItem SW_HIDE ShowWindow DROP ;

: (OBOX-UPDATE) ( -- )
   HWND IDOPTIONS GetDlgItem >R

   R@ LB_GETCURSEL 0 0 SendMessage ( index)             \ current selection

   R@ LB_GETTEXT THIRD PAD SendMessage DROP
   PAD ZCOUNT -TRAILING .INSTALLED
   R> LB_GETITEMDATA ROT 0 SendMessage  ( addr)         \ addr of data in roster

   HWND IDFNAME THIRD SetDlgItemText DROP ZSCAN ZSCAN
   HWND IDDESC  THIRD SetDlgItemText DROP DROP ;

: OBOX-UPDATE ( -- )
   WPARAM LOWORD IDOPTIONS <> ?EXIT
   WPARAM HIWORD LBN_SELCHANGE <> ?EXIT
   (OBOX-UPDATE) ;

: OBOX-INIT ( -- )
   HWND IDOPTIONS GetDlgItem >R
   LPARAM @ IF
      LPARAM @+ BOUNDS BEGIN ( end current)
         ( e c)   R@ LB_ADDSTRING 0 FOURTH ZSCAN SendMessage ( n)
         ( e c n) R@ LB_SETITEMDATA ROT FOURTH SendMessage DROP
         ZSCAN ZSCAN ZSCAN
         2DUP > NOT
      UNTIL DROP
      R@ LB_SETCURSEL 0 0 SendMessage DROP
   THEN
   (OBOX-UPDATE)
   R> SetFocus DROP ;

: OBOX-CANCEL ( -- res )
   HWND 0 EndDialog ;

: OBOX-CLOSE ( -- res )
   HWND IDOPTIONS GetDlgItem LB_GETITEMDATA
   OVER LB_GETCURSEL 0 0 SendMessage 0 SendMessage        \ current selection
   HWND SWAP EndDialog ;

{ --------------------------------------------------------------------
OBOX-COMMANDS processes commands, and
OBOX-MESSAGES processes messages.

RUNOBOX is the callback's name, which is used by
OBOX to create the modal dialog.  OBOX requires the address of
   a table in memory which contains

        CREATE POO   0 ,
           ,Z" FILENAME1" ,Z" OPTION1" ,Z" DESCRIPTION 1"
           ,Z" FILENAME2" ,Z" OPTION2" ,Z" DESCRIPTION 2"
           ,Z" FILENAME3" ,Z" OPTION3" ,Z" DESCRIPTION 3"
           ,Z" FILENAME4" ,Z" OPTION4" ,Z" DESCRIPTION 4"

        HERE POO - CELL- POO !   POO OBOX

   the value returned is a pointer to the item's data.
-------------------------------------------------------------------- }

[SWITCH OBOX-COMMANDS ZERO ( -- res )
   IDOK          RUN: OBOX-CLOSE ;
   IDCANCEL      RUN: OBOX-CANCEL ;
   IDOPTIONS     RUN: OBOX-UPDATE 1 ;
SWITCH]

[SWITCH OBOX-MESSAGES ZERO ( -- res )
   WM_COMMAND    RUN: WPARAM LOWORD OBOX-COMMANDS ;
   WM_INITDIALOG RUN: OBOX-INIT 0 ;
   WM_CLOSE      RUN: OBOX-CLOSE ;
SWITCH]

:NONAME ( -- res )   MSG LOWORD OBOX-MESSAGES ;  4 CB: RUNOBOX

: OBOX ( a -- res )
   >R HINST (OBOX)  HWND  RUNOBOX R> DialogBoxIndirectParam ;

{ --------------------------------------------------------------------
OPTIONS-DATA has a pointer to the buffer where the option list is
   accumulated before calling OBOX and used for loading the option.

PLUNK adds a string to the database at OPTIONS-DATA.

ODIR holds the directory where the options are being cataloged and
OTEXT holds the first line of the current file.

-OPTIONAL opens the given filename. reading up to 10 lines looking for
the word OPTIONAL.  Returns 0 if found.  Data left at OTEXT .

ADD-OPTION stores the filenmae and the optional tag and description
   in the OPTIONS-DATA database.

ENUM-OPTIONS does directory enquiries in the specified directory and
   adds all options to the OPTIONS-DATA database.
-------------------------------------------------------------------- }

0 VALUE OPTIONS-DATA

: PLUNK ( a n -- )
   TUCK OPTIONS-DATA @+ + ZPLACE 1+ OPTIONS-DATA +! ;

CREATE ODIR    256 /ALLOT
CREATE OTEXT   256 /ALLOT

: -OPTIONAL ( addr len -- flag )
   R-BUF  ODIR COUNT R@ PLACE  R@ APPEND  R> COUNT
   R/O OPEN-FILE IF  DROP  -1 EXIT THEN
   10 0 DO ( fid)
      OTEXT 256 ERASE
      OTEXT 255 THIRD READ-LINE 2DROP  OTEXT + 0 SWAP C!
      S" OPTIONAL" OTEXT 8 COMPARE(NC) 0= IF LEAVE THEN
   LOOP ( fid) CLOSE-FILE DROP
   S" OPTIONAL" OTEXT 8 COMPARE(NC) ;

: ADD-OPTION ( addr len -- )
   PLUNK  OTEXT ZCOUNT  8 /STRING  BL SKIP  OVER SWAP  BL SCAN
   OVER SWAP BL SKIP  2>R  OVER - PLUNK   2R>  PLUNK ;

\ MAKE SURE TO CALL WITH TRAILING \

: ENUM-OPTIONS ( addr len -- n )
   [OBJECTS
      WIN32_FIND_DATA MAKES WFD
      FILENAME-BUFFER MAKES FN
   OBJECTS]   OPTIONS-DATA OFF  2DUP ODIR PLACE
   FN FileName ZPLACE  S" *.F" FN FileName ZAPPEND
   FN FileName  WFD ADDR FindFirstFile
   DUP INVALID_HANDLE_VALUE <> BEGIN ( handle flag)
      0<> WHILE
      WFD FileName ZCOUNT
      2DUP -OPTIONAL IF  2DROP  ELSE
         ADD-OPTION  THEN
      DUP WFD ADDR FindNextFile
   REPEAT FindClose DROP  OPTIONS-DATA @ ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: SELECT-OPTION ( addr n -- addr )
   ENUM-OPTIONS DUP IF DROP  OPTIONS-DATA OBOX THEN  ;

: INCLUDE-OPTION ( -- )
   [CHAR] ` WORD COUNT OVER + OFF  SetCurrentDirectory
   IF INCLUDE ELSE CR ." Directory does not exist: "
      HERE 1+ ZCOUNT TYPE
   THEN ;

PUBLIC

: INCLUDING-OPTION ( -- )
   PUSHPATH  ['] INCLUDE-OPTION CATCH DROP  POPPATH ;

PRIVATE

: REQUIRED ( addr -- )
   ?DUP IF  R-BUF
      S\" \zINCLUDING-OPTION "  R@ PLACE
      ODIR COUNT R@ APPEND S" ` " R@ APPEND
      ZCOUNT R@ APPEND  S\" \r" R@ APPEND
      R> COUNT OPERATOR'S PUSHTEXT
   THEN ;

: CHOOSE ( addr n -- )
   65536 R-ALLOC TO OPTIONS-DATA  SELECT-OPTION  REQUIRED ;

: SHOVE ( addr len -- )   R-BUF
   S\" \z" R@ PLACE R@ APPEND S\" \r" R@ APPEND
   R> COUNT OPERATOR'S PUSHTEXT ;

PUBLIC

: CHOOSE-SAMPLES        S" %SWIFTFORTH\LIB\SAMPLES\"           +ROOT CHOOSE ;
: CHOOSE-WINSAMPLES     S" %SWIFTFORTH\LIB\SAMPLES\WIN32\"     +ROOT CHOOSE ;
: CHOOSE-OPTIONS        S" %SWIFTFORTH\LIB\OPTIONS\"           +ROOT CHOOSE ;
: CHOOSE-WINOPTIONS     S" %SWIFTFORTH\LIB\OPTIONS\WIN32\"     +ROOT CHOOSE ;


CONSOLE-WINDOW +ORDER

[+SWITCH SF-COMMANDS ( wparam -- )
   MI_SAMPLES      RUN: S" CHOOSE-SAMPLES" SHOVE ;
   MI_WINSAMPLES   RUN: S" CHOOSE-WINSAMPLES" SHOVE ;
   MI_OPTIONALS    RUN: S" CHOOSE-OPTIONS" SHOVE ;
   MI_WINOPTIONALS RUN: S" CHOOSE-WINOPTIONS" SHOVE ;
SWITCH]

CONSOLE-WINDOW -ORDER

END-PACKAGE

