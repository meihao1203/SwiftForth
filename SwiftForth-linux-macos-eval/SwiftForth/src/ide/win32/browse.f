{ ====================================================================
Folder browsing

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
BrowseForFolder ( hwnd -- szDir -1 | 0 )     Ch. Melice 4 mai 00

Use the API 'SHBrowseForFolder' to choose a directory from the
current one.
-------------------------------------------------------------------- }

\ Imported functions

FUNCTION: SHGetPathFromIDList   ( pidl pszPath -- bool )
FUNCTION: SHBrowseForFolder     ( lpBrowseInfo -- lpId )

LIBRARY OLE32

FUNCTION: CoTaskMemFree         ( pv -- )

{ --------------------------------------------------------------------
Generic callback for class
-------------------------------------------------------------------- }

\ lparam is given at creation, is the object address
\ wparam is whatever
\ msg is specific
\ hwnd is handle

OOP +ORDER

:NONAME ( -- res )
   LPARAM MSG OVER CELL - @ >ANONYMOUS BELONGS?
   IF LATE-BINDING  ELSE 2DROP THEN 0 ;
4 CB: SHBROWSEPROC

OOP -ORDER

{ --------------------------------------------------------------------
BROWSEINFO data structure
-------------------------------------------------------------------- }

CLASS BROWSEINFO
   VARIABLE OWNER
   VARIABLE ROOT
   VARIABLE DISPLAYNAME
   VARIABLE TITLE
   VARIABLE FLAGS
   VARIABLE PROC
   VARIABLE PARAM
   VARIABLE IMAGE
END-CLASS

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

BROWSEINFO SUBCLASS FOLDER-BROWSER

   $0001 CONSTANT BIF_RETURNONLYFSDIRS
   $0004 CONSTANT BIF_STATUSTEXT
   $0008 CONSTANT BIF_RETURNFSANCESTORS

   1 CONSTANT BFFM_INITIALIZEDA
   2 CONSTANT BFFM_SELCHANGED

   WM_USER 100 + CONSTANT BFFM_SETSTATUSTEXTA
   WM_USER 101 + CONSTANT BFFM_ENABLEOK
   WM_USER 102 + CONSTANT BFFM_SETSELECTIONA

   MAX_PATH BUFFER: SZDIR

   DEFER: OK? ( dir -- flag )   DROP 1 ;

   BFFM_INITIALIZEDA MESSAGE: ( msg -- )
      MAX_PATH SZDIR GetCurrentDirectory DROP
      HWND BFFM_SETSELECTIONA TRUE szDir SendMessage DROP ;

   BFFM_SELCHANGED MESSAGE: ( msg -- )
      WPARAM SZDIR SHGetPathFromIDList DROP
      HWND BFFM_ENABLEOK 0 SZDIR OK? SendMessage DROP ;

   : INIT ( hwnd ztitle -- )   TITLE !  OWNER !
      0 ROOT !  BIF_RETURNONLYFSDIRS FLAGS !
      SHBROWSEPROC PROC !  SELF PARAM ! ;

   : BROWSE ( hwnd ztitle -- 0 | zpath )   INIT
      ADDR SHBrowseForFolder DUP IF
         DUP SZDIR SHGetPathFromIDList IF  SZDIR ELSE 0 THEN
         SWAP CoTaskMemFree
      THEN ;

END-CLASS

\ -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

\\

: OPEN-PROJECT ( -- )
   [OBJECTS PROJECT-BROWSER MAKES PB OBJECTS]
   HWND Z" Select an existing project" PB BROWSE IF
      S" \" PB SZDIR ZAPPEND
      PRJFILE PB SZDIR ZAPPEND
      PB SZDIR ZCOUNT TYPE
   THEN ;

PROJECT-BROWSER BUILDS FOO

: Z HWND Z" HA HA" FOO BROWSE ;
