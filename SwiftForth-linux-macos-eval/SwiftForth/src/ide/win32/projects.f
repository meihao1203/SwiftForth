{ ====================================================================
projects.f


Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

DIALOG NEW-PROJECT-TEMPLATE
[MODAL " New Project" 20 20 170 142 (CLASS SFDLG) (FONT 10, MS Sans Serif) ]
 [DEFPUSHBUTTON     " &Create"                         IDOK  90  125   35   12 ]

 [LTEXT             " &Description (title) of the project:"     98  5    5   160   10 ]
 [EDITTEXT           ( description)                     99  5    15  160   10 ]

 [LTEXT             " &Name of project directory:"      100  5    35  160   10 ]
 [EDITTEXT           ( name)                            101  5    45  160   10 ]

 [LTEXT             " &Root location for project:"      102  5    65  160   10 ]
 [EDITTEXT           ( location)                        103  5    75  145   10 (+STYLE ES_AUTOHSCROLL) ]
 [PUSHBUTTON        " ..."                              110  153  75  12    10 ]

 [LTEXT             " &Existing project to copy from:"  104  5    95  160   10 ]
 [EDITTEXT           ( based on)                        105  5   105  145   10 (+STYLE ES_AUTOHSCROLL) ]
 [PUSHBUTTON        " ..."                              111  153 105  12    10 ]

 [PUSHBUTTON        " Cance&l"                IDCANCEL  130  125   35   12 ]
END-DIALOG

{ --------------------------------------------------------------------
PROJECT-FOLDER-BROSWER is the handler for finding the container
directory for the new project.  The initialization procedure sets
it to the root path.
-------------------------------------------------------------------- }

FOLDER-BROWSER SUBCLASS PROJECT-FOLDER-BROWSER

   BFFM_INITIALIZEDA MESSAGE: ( msg -- )
      ROOTPATH COUNT 1- SZDIR ZPLACE
      HWND BFFM_SETSELECTIONA TRUE szDir SendMessage DROP ;

END-CLASS

{ --------------------------------------------------------------------
NEWPROJ is the dialog handler for the project cloning dialog.
-------------------------------------------------------------------- }

GENERICDIALOG SUBCLASS NEWPROJ

   : TEMPLATE ( -- addr )   NEW-PROJECT-TEMPLATE ;

   MAX_PATH BUFFER: DEST   MAX_PATH BUFFER: DBUF
   MAX_PATH BUFFER: SRC    MAX_PATH BUFFER: SBUF
   MAX_PATH BUFFER: TEMP   

   : GET ( id -- zstr )
      HWND SWAP TEMP MAX_PATH GetDlgItemText DROP  TEMP ;

   : PUT ( zstr id -- )
      SWAP HWND -ROT SetDlgItemText DROP ;

   : /DEST ( -- )
      103 GET ZCOUNT DEST ZPLACE  DEST +\  
      101 GET ZCOUNT DEST ZAPPEND  DEST +\ ;

   : /SRC ( -- )
      105 GET ZCOUNT SRC ZPLACE  SRC +\ ;

   : OK? ( -- flag )
       99 GET C@ 0<>            \ any title
      101 GET C@ 0<> AND        \ any name is good enough
      103 GET IS-DIR AND        \ as long as its home is valid
      105 GET HAS-PRJ AND ;     \ and the source is valid too

   : REOK ( -- )   
      HWND IDOK GetDlgItem OK? EnableWindow DROP ;

    99 COMMAND: REOK ;
   101 COMMAND: REOK ;
   103 COMMAND: REOK ;
   105 COMMAND: REOK ;

   110 COMMAND: ( -- )   
      [OBJECTS PROJECT-FOLDER-BROWSER MAKES PRJ OBJECTS]
      HWND Z" New Project" PRJ BROWSE ?DUP IF 103 PUT  THEN ;

   111 COMMAND: ( -- )   
      [OBJECTS FOLDER-BROWSER MAKES PRJ OBJECTS]
      HWND Z" Based on" PRJ BROWSE ?DUP IF 105 PUT THEN ;

   WM_INITDIALOG MESSAGE: ( -- res )   
      \ MAX_PATH TEMP GetCurrentDirectory DROP
      \ TEMP ZCOUNT -NAME PAD ZPLACE  PAD 103 PUT
      ROOTPATH COUNT 1- TEMP ZPLACE  TEMP 103 PUT
      MAX_PATH TEMP GetCurrentDirectory DROP  TEMP 105 PUT
      REOK 0 ;

   : DEST-EXISTS ( -- )
      HWND Z" The destination directory already exists" 
      Z" Project manager" MB_OK MessageBox DROP ;

   : MAKE-DEST-DIR ( -- ior )
      DEST IS-DIR IF DEST-EXISTS -1 EXIT THEN
      DEST 0 CreateDirectory 0= ;

   : +PATH ( zfile zpath buf -- )
      >R  0 R@ C!  ZCOUNT R@ ZPLACE  R@ +\  ZCOUNT R> ZAPPEND ;

   : +SRC ( zname -- zname )   SRC SBUF +PATH  SBUF ;
   : +DEST ( zname -- zname )   DEST DBUF +PATH  DBUF ;

   : COPY ( zname -- ior )   
      [OBJECTS DIRTOOL MAKES DT OBJECTS]
      +SRC  DT FIRST IF
         DT FileName DUP ZCOUNT -PATH PAD ZPLACE  PAD +DEST
         0 CopyFile 0=
      ELSE -1 THEN  DT CLOSE ;

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

   : COPIES ( z -- )   ?DUP -EXIT  BEGIN  ZCOUNT WHILE 
         DUP COPY DROP ZNEXT REPEAT DROP ;

   : SET-TITLE ( -- )   Z" STARTUP" Z" TITLE"
      99 GET ( zstr)  PRJFILE DROP
      CONFIGFILE ZCOUNT [CHAR] \ SCAN  NIP IF  +DEST  THEN
      WritePrivateProfileString DROP ;


   DEFER: BOILERPLATE ( -- z )   0 ;
   DEFER: KERNEL-COPIES ( -- ior )   -1 ;

   : COPY-SRC-FILES ( -- ior )   
      BOILERPLATE COPIES  KERNEL-COPIES  0 ;

   : CLONED ( -- ior )   /DEST /SRC
      MAKE-DEST-DIR ?IOR  COPY-SRC-FILES ?IOR  SET-TITLE  0 ;

   IDOK COMMAND:  CLONED IF EXIT THEN 1 CLOSE-DIALOG ;

END-CLASS

