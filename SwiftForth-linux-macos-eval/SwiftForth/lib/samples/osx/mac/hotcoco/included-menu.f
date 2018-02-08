{ ====================================================================
Adding a menu plus menu items to existing menubar.

Copyright (c) 2017 Roelf Toxopeus

SwiftForth version.
Forth ObjC Runtime interface usage example
Last: 20 November 2017 at 22:02:57 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
This example shows how to add a menuitem to the existing menubar programma-
tically. This menu is inspired by MacForth's -Project- menu. It contains
a list of all included files as its submenu menuitems. When clicked on,
the file will open in your editor.
In this example the menubar will be provided by by sfmenu.f and a menuitem
name Included will be added to the menubar.
One new method will be added to SFMenuClass, the class running SFMenu.

A menu structure is as follows:
menu -> menuitem -> submenu -> menuitem -> ... -> action -> target

Which translates to:
NSApp mainMenu (the menubar) -> menuitems (Application Name, File, Edit, ... Help)
each menuitem -> submenu (the dropdown menu)
each submenu -> menuitems (clickable items)
each menuitem -> defaultaction or action with target set by us.
See simplemenu.f

Note that in general speak we say MENU when a MENUITEM is meant.

Utillities for main menubar:
BARITEM -- returns menuitem for menuname in mainmenu
BARINDEX -- returns index for menuname in mainmenu
NEWBARITEM -- return new menuitem with name for the menubar. A submenu
is attached to the new menuitem.
NEWBARMENU -- insert menuitem with name, in front of Help menu.

The special added menu(item)s:
*edit: -- callback is implementation for the edit: method, which is
added to SFMenuClass. Its sender parameter is the selected menuitem,
who's representedObject is a fullname, which is opened in our editor.

FILE-ITEM -- return new filename-item for submenu, the dropdown part.
It expects the FULLNAME zbuffer, which will be set as representedObject.
The filename without path will be the menuitem title.

ADD.FILE -- insert given fullpath filename at index in -Included- menu
LASTFILE-ITEM -- return last included file as new filename-item.
>INCLUDED -- add last included file at top -Included- list
INCLUDED>MENU -- add all included files to the -Include- menu.
Code borrowed from .FILES

Possible redefinitions:
: LOAD-FILE ( -- )    LOAD-FILE >INCLUDED ;
: LOAD-EDIT ( -- )    LOAD-EDIT >INCLUDED ;
: INCLUDE ( <spaces>name -- )     INCLUDE >INCLUDED ;
etc.etc.
-------------------------------------------------------------------- }

\ sfmenu specifics, first add menubar to coco-sf
ABSENT SFMENU [IF]
PUSHPATH MAC
INCLUDE hotcoco/sfmenu5.f
POPPATH

SFMENU CR .( SFMENU installed)
[THEN]

/FORTH
DECIMAL

\ COCOA: @mainMenu ( -- menuref )   \ NSApplication

COCOACLASS NSMenu
COCOA: @initWithTitle: ( nsstringref -- menuref )	\ NSMenu
COCOA: @itemWithTitle: ( nsstringref -- itemref )	\ NSMenu
COCOA: @indexOfItemWithTitle: ( nsstring -- index )	\ NSMenu
COCOA: @insertItem:atIndex: ( newItem index -- ret )	\ NSMenu
COCOA: @addItem: ( newitem -- ret )	\ NSMenu

COCOACLASS NSMenuItem
COCOA: @submenu ( -- menuref )	\ NSMenuItem
COCOA: @setSubmenu: ( newmenu -- ret )	\ NSMenuItem
COCOA: @initWithTitle:action:keyEquivalent: ( nsstring action nsstring -- NSMenuItemRef )		\ NSMenuItem
COCOA: @setTarget: ( obj -- ret )	\ NSMenuItem
COCOA: @representedObject ( -- obj )	\ NSMenuItem
COCOA: @setRepresentedObject: ( obj -- ret )	\ NSMenuItem

: BARITEM ( za -- item )   >NSSTRING NSApp @ @mainMenu @itemWithTitle: ;

: BARINDEX ( za -- index )   >NSSTRING NSApp @ @mainMenu @indexOfItemWithTitle: ;

: (NEWITEM) ( name selector key -- item )   NSMenuItem @alloc @initWithTitle:action:keyEquivalent: ;

: (NEWMENU) ( name -- menu )   NSMenu @alloc @initWithTitle: ;

: NEWBARITEM ( zname -- item )
	>NSSTRING DUP 0 @" " (NEWITEM) 	\ DUP 0= ABORT" NO NEW ITEM !"
	SWAP (NEWMENU)
	OVER @setSubmenu: DROP ;			\ create the submenu (the dropdown) for later to be added items

: NEWBARMENU ( za -- )  
	NEWBARITEM
	Z" Help" BARINDEX
	NSApp @ @mainMenu @insertItem:atIndex: DROP ;

CALLBACK: *edit: ( rec sel sender -- n )  0 _PARAM_2 @representedObject >4THSTRING (EDIT-FILE)  0 ;

*edit: menuMethodTypes z" edit:"    SFMenuClass ADD.METHOD

: FILE-ITEM ( za -- NSMenuItemRef )
	DUP >NSSTRING >R								\ the fullname NSRtringRef will be representedObject
	ZCOUNT -PATH DROP >NSSTRING         DUP >R
	Z" edit:" @selector @" " (NEWITEM)  R> @release DROP ( NSStringRef)
	SFClassREF @ OVER @setTarget: DROP
	R> OVER @setRepresentedObject: DROP ;  \ don't release it !
	
: LASTFILE-ITEM ( -- NSMenuItemRef )   LASTFILE @ COUNT POCKET ZPLACE POCKET FILE-ITEM ;

(*
: ADD.LASTFILE ( za -- )   LASTFILE-ITEM 0 ROT BARITEM  @submenu @insertItem:atIndex: DROP ;

: >INCLUDED ( -- )   Z" Included" ADD.LASTFILE ;

: ADD.FILE ( za -- )   FILE-ITEM Z" Included" BARITEM  @submenu @addItem: DROP ;

: INCLUDED>MENU ( -- )
	Z" Included" NEWBARMENU
   FILES-WORDLIST WID> CELL+ BEGIN ( link)
      @REL DUP WHILE
      DUP LINK> >NAME COUNT +ROOT POCKET ZPLACE POCKET ADD.FILE
   REPEAT DROP ;
*)

: ADD.FILE ( za index -- )   SWAP FILE-ITEM SWAP Z" Included" BARITEM  @submenu @insertItem:atIndex: DROP ;

: >INCLUDED ( -- )   LASTFILE @ COUNT +ROOT POCKET ZPLACE POCKET 0 ADD.FILE ;

: INCLUDED>MENU ( -- )
	Z" Included" NEWBARMENU
   FILES-WORDLIST WID> CELL+
   -1 >R ( index)
   BEGIN ( link)
      @REL DUP WHILE
      DUP LINK> >NAME COUNT +ROOT POCKET ZPLACE POCKET RP@ DUP ++ @ ADD.FILE
   REPEAT DROP
   R> DROP ;

cr .( INCLUDED>MENU to add menu to main menubar)

\\ ( eof)

