{ ====================================================================
Enumerate COM ports via registry enquiries

Copyright 2001  FORTH, Inc.
==================================================================== }

LIBRARY ADVAPI32

FUNCTION: RegOpenKeyEx ( hkey zkey 0 security 'handle -- ior )
FUNCTION: RegEnumValue ( hkey index 'name 'namelen 0 'type 'data 'datalen -- ior )

: HKEY_SERIALCOMM ( -- hkey )   0 >R
   HKEY_LOCAL_MACHINE Z" HARDWARE\DEVICEMAP\SERIALCOMM" 0 KEY_READ RP@
   RegOpenKeyEX 0= R> AND ;

: EnumCommPort ( index -- zaddr )      \ uses pad and here
   256 HERE !  256 PAD !  HKEY_SERIALCOMM TUCK >R
   HERE CELL+ HERE  0 0  PAD CELL+ PAD RegEnumValue
   0=  PAD CELL+ AND  R> RegCloseKey DROP ;

\ --------------------------------------------------------------------

DIALOG CHOOSE-COMMPORT-TEMPLATE
[MODAL " Configure XTL" 20 20 80 74 (FONT 10, MS SANS SERIF) (CLASS SFDLG) ]
 [DEFPUSHBUTTON " OK"              IDOK      44   58   32   12 ]
 [PUSHBUTTON    " Cancel"          IDCANCEL   4   58   32   12 ]
 [LISTBOX                          100        4   14   72   40 (+STYLE LBS_SORT LBS_NOINTEGRALHEIGHT	) ]
 [LTEXT         " Select Comport"  101        4    4   64   10 ]
END-DIALOG

GENERICDIALOG SUBCLASS COMMPORT-DIALOG

   : TEMPLATE ( -- addr )   CHOOSE-COMMPORT-TEMPLATE ;

   MAX_PATH BUFFER: SELECTED

   : ENUMERATE-COMMPORTS ( -- )
      mHWND 100 GetDlgItem >R  0 BEGIN
         DUP EnumCommPort ?DUP WHILE
         R@ LB_ADDSTRING ROT 0 SWAP SendMessage DROP
         1+
      REPEAT DROP
      R> LB_SETCURSEL 0 0 SendMessage DROP ;

   : DONE ( -- zaddr )   S" \\.\" SELECTED ZPLACE
      mHWND 100 GetDlgItem DUP
      LB_GETCURSEL 0 0 SendMessage  DUP 0< IF  2DROP 0 EXIT THEN
      LB_GETTEXT SWAP SELECTED ZCOUNT + SendMessage DROP  SELECTED ;

   IDOK COMMAND: DONE CLOSE-DIALOG ;

   WM_INITDIALOG MESSAGE: ( -- res )
      ENUMERATE-COMMPORTS 0 ;

END-CLASS

: CHOOSE-COMMPORT ( hwnd -- zstr | 0 )
   [OBJECTS COMMPORT-DIALOG MAKES CPD OBJECTS]
   >R BEGIN
      R@ CPD MODAL DUP WHILE
      DUP ZCOUNT R/W OPEN-FILE WHILE DROP
         S" Can't open " PAD ZPLACE
         ZCOUNT -PATH PAD ZAPPEND
         R@ PAD Z" Choose Commport" MB_OK MessageBox DROP
      REPEAT CLOSE-FILE DROP  ZCOUNT PAD ZPLACE  PAD
   THEN R> DROP ;

