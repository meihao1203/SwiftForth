{ ====================================================================
Help files

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

Access to various help and documentation files

Access to various help and documentation files for windows 10, which
doesn't support .hlp files anymore.

The basic functionality is: find or open the win32api.chm file,
then select the Index tab, then send it the string to search for.

The SELECT-INDEX-TAB and CHILDID of the edit control were empirically
determined by examining a running help engine with the chm displayed.
==================================================================== }

?( ... Help files)

LIBRARY hhctrl.ocx  
FUNCTION: HtmlHelp ( hwnd zfile cmd data -- hwnd )

PACKAGE SHELL-TOOLS

CREATE WINAPI 256 /ALLOT
CONFIG: WINAPI ( -- addr len )  WINAPI 256 ;

: >DOCPATH ( addr n -- zaddr )   ROOTPATH COUNT PAD ZPLACE
   S" SwiftForth\Doc\" PAD ZAPPEND  PAD ZAPPEND  PAD ;

: WINAPI-FILE ( -- zname )
   WINAPI C@ IF WINAPI ELSE S" WIN32API.CHM" >DOCPATH THEN ;

: HELPCMD ( zaddr -- )
   HWND 0 ROT 0 0 SW_NORMAL ShellExecute  32 < IF
      HWND Z" Help file not found"  Z" Error" MB_OK MessageBox DROP
   THEN ;

: MAKE-HTMLHELP-STRING ( addr len -- z )   
   WINAPI-FILE ZCOUNT PAD ZPLACE  S" ::/topic_" PAD ZAPPEND
   ( addr len) PAD ZAPPEND  S" .htm" PAD ZAPPEND  PAD ;

: SHOW-API ( addr len -- )
   MAKE-HTMLHELP-STRING   HWND SWAP 0 0 HtmlHelp DROP ;

PUBLIC

: SWIFT-PDF       S" SwiftForth-Win32.pdf" >DOCPATH HELPCMD ;
: FORTH-HANDBOOK  S" Handbook.pdf" >DOCPATH HELPCMD ;
: RELEASE-NOTES   S" http://www.forth.com/swiftforth/version.html" >SHELL ;
: SWF-ONLINE      S" http://www.forth.com/swiftforth/ref.html" >SHELL ;
: DPANS-PDF       S" DPANS94.pdf" >DOCPATH HELPCMD ;
: API-MSDN        S" http://msdn.microsoft.com/en-us/library/aa383749(VS.85).aspx" >SHELL ;

: API-HELP        S" organization_of_the_win32_programm" SHOW-API ;

: API ( -- <topic> )
   BL WORD COUNT SHOW-API ;
      
END-PACKAGE
