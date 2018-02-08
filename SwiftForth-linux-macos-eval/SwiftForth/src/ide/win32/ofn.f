{ ====================================================================
Open file common dialog class

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman
==================================================================== }

?( Open file common dialog)

PACKAGE OFN-DIALOGS

{ --------------------------------------------------------------------
The OPENFILENAME data structure is extended to include the basic
mechanism for using it in the GetOpenFilename and GetSaveFilename
api calls.  This class includes a few default file extension lists,
and deferred mechanisms to allow future subclasses to redefine the
basic behavior of the words.

CUSTOM allows a subclass to change the dialog title, the extension
filter, and the flags which control the api call.

ACTION allows a subclass to define which api call to use.

The main user interface is CHOOSE, which will invoke an api based
dialog and let the user make a choice.
-------------------------------------------------------------------- }

OPENFILENAME SUBCLASS FILENAME-DIALOG

   256 BUFFER: FILENAME

   0  OFN_HIDEREADONLY OR
      OFN_LONGNAMES OR
   CONSTANT DEFAULT-OPEN-FLAGS

   0  OFN_HIDEREADONLY OR
      OFN_NOCHANGEDIR OR
      OFN_LONGNAMES OR
      OFN_OVERWRITEPROMPT OR
      OFN_EXTENSIONDIFFERENT OR
   CONSTANT DEFAULT-SAVE-FLAGS

   CREATE ALL-FILES
      ,Z" All files (*.*)"  ,Z" *.*"  0 ,

   CREATE FORTH-FILES
      ,Z" Forth files (*.F)"            ,Z" *.F"
      ,Z" FTH files (*.FTH)"            ,Z" *.FTH"
      ,Z" Text files (*.TXT)"           ,Z" *.TXT"
      ,Z" Log files (*.LOG)"            ,Z" *.LOG"
      ,Z" All files (*.*)"              ,Z" *.*"
      0 ,

   CREATE TEXT-FILES
      ,Z" Text files (*.TXT)"           ,Z" *.TXT"
      ,Z" All files (*.*)"              ,Z" *.*"
      0 ,

   CREATE LOG-FILES
      ,Z" log files (*.LOG)"            ,Z" *.LOG"
      ,Z" All files (*.*)"              ,Z" *.*"
      0 ,

   CREATE PROGRAM-FILES
      ,Z" Programs (*.EXE)"             ,Z" *.EXE"
      ,Z" Library files (*.DLL)"        ,Z" *.DLL"
      ,Z" All files (*.*)"              ,Z" *.*"
      0 ,

   : DEFAULTS ( -- )
      StructSize OPENFILENAME SIZEOF ERASE
      OPENFILENAME SIZEOF StructSize !
      HINST Instance !  HWND Owner !  1 FilterIndex !
      FILENAME zFile !  254 MaxFile !   FILENAME OFF ;

   DEFER: CUSTOM ( -- title filter flags )
      Z" Choose a file" ALL-FILES DEFAULT-OPEN-FLAGS ;

   DEFER: ACTION ( addr -- bool )   IOR_UNRESOLVED THROW ;

   : CHOOSE ( -- bool )
      DEFAULTS  CUSTOM  Flags !  zFilter !  zTitle !
      StructSize ACTION ;

END-CLASS

{ --------------------------------------------------------------------
OFN-DIALOG is the subclass of FILENAME-DIALOG which uses
GetOpenFilename as its api method.

INCLUDE-FILE-DIALOG
EDIT-FILE-DIALOG
RUN-PROGRAM-DIALOG all subclass OFN-DIALOG with custom filters, titles,
and flags. They are identical, except for the custom bits.
-------------------------------------------------------------------- }

FILENAME-DIALOG SUBCLASS OFN-DIALOG

   : ACTION ( addr -- bool )   GetOpenFileName ;

END-CLASS


OFN-DIALOG SUBCLASS INCLUDE-FILE-DIALOG

   : CUSTOM ( -- title filter flags )
      Z" Include file"  FORTH-FILES
      DEFAULT-OPEN-FLAGS OFN_FILEMUSTEXIST OR ;

END-CLASS

OFN-DIALOG SUBCLASS EDIT-FILE-DIALOG

   : CUSTOM ( -- title filter flags )
      Z" Edit file"  FORTH-FILES
      DEFAULT-OPEN-FLAGS ;

END-CLASS

OFN-DIALOG SUBCLASS RUN-PROGRAM-DIALOG

   : CUSTOM ( -- title filter flags )
      Z" Run"  PROGRAM-FILES
      DEFAULT-OPEN-FLAGS OFN_FILEMUSTEXIST OR OFN_NOCHANGEDIR OR ;

END-CLASS

{ --------------------------------------------------------------------
SFN-DIALOG is the subclass of FILENAME-DIALOG which uses
GetSaveFilename as its api method.

SAVE-PROGRAM-DIALOG
SAVE-TEXT-DIALOG all subclass SFN-DIALOG with custom filters, titles,
and flags. They are identical, except for the custom bits.
-------------------------------------------------------------------- }

FILENAME-DIALOG SUBCLASS SFN-DIALOG

   : ACTION ( addr -- bool )   GetSaveFileName ;

   : +EXT ( -- )
      FILENAME ZCOUNT -PATH [CHAR] . SCAN NIP IF EXIT THEN
      CUSTOM ROT 2DROP ZNEXT ZCOUNT [CHAR] . SCAN FILENAME ZAPPEND ;

END-CLASS


SFN-DIALOG SUBCLASS SAVE-PROGRAM-DIALOG

   : CUSTOM ( -- title filter flags )
      Z" Save program"  PROGRAM-FILES
      DEFAULT-SAVE-FLAGS ;

END-CLASS

SFN-DIALOG SUBCLASS SAVE-TEXT-DIALOG

   : CUSTOM ( -- title filter flags )
      Z" Save text"  TEXT-FILES
      DEFAULT-SAVE-FLAGS ;

END-CLASS

SFN-DIALOG SUBCLASS SAVE-LOG-DIALOG

   : CUSTOM ( -- title filter flags )
      Z" Save text"  LOG-FILES
      DEFAULT-SAVE-FLAGS ;

END-CLASS

{ --------------------------------------------------------------------
User interfaces to the dialogs

After defining specific classes to deal with different kinds of
open and save filename dialogs, we present a few fully enclosed
user interfaces to them.

CHOOSE-EDIT-FILE uses EDIT-FILE-DIALOG to ask the user for a
filename to edit.

CHOOSE-PROGRAM-FILE uses RUN-PROGRAM-DIALOG to ask the user for a
filename to execute.
-------------------------------------------------------------------- }

PUBLIC

: CHOOSE-EDIT-FILE ( -- )
   [OBJECTS
        EDIT-FILE-DIALOG MAKES EFD
   OBJECTS]
   EFD CHOOSE IF  1 EFD FILENAME ZCOUNT EDIT-FILE  THEN ;

: CHOOSE-PROGRAM-FILE ( -- zstring )
   [OBJECTS
      RUN-PROGRAM-DIALOG MAKES RPD
   OBJECTS]
   RPD CHOOSE IF  RPD FILENAME ZCOUNT PAD ZPLACE  PAD
   ELSE 0 THEN ;

{ --------------------------------------------------------------------
Include file command

INCLUDE-FILE-COMMAND is run from the menu option or toolbar button.
The action is executed during the callback, and the forth interpreter
is not valid then, so the actual "include" must be given to the forth
interpreter to execute. This is done via pushing the command "include
<filename>" into the keyboard queue. To make this work as generically
as possible, an escape, followed by a [ (to force interpret state) are
pushed first, and a cr is pushed after. Note that the pushtext command
requires a personality to be valid, this is set to operator by PUSH-
INCLUDE-FILE
-------------------------------------------------------------------- }

PRIVATE

: PUSH-INCLUDE-FILE ( zstr -- )   OPERATOR'S
   S\" \zINCLUDE \"" PAD PLACE  ZCOUNT PAD APPEND
   S\" \"\r" PAD APPEND  PAD COUNT PUSHTEXT ;

PUBLIC

: INCLUDE-FILE-COMMAND ( -- )
   [OBJECTS
      INCLUDE-FILE-DIALOG MAKES IFD
   OBJECTS]
   IFD CHOOSE IF  IFD FILENAME PUSH-INCLUDE-FILE  THEN ;

END-PACKAGE
