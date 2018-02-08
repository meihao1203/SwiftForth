{ ====================================================================
Tree View sample control

Copyright (C) 2001 FORTH, Inc.
==================================================================== }

OPTIONAL TREEVIEW A Tree View sample control

{ --------------------------------------------------------------------
This sample uses code found in the Win32 Programmer's Reference with
modifications found in Dave Edson's "Great Windows Programming" book.

Requires: STRUCTS, Window's Common Controls

Exports: CreateATreeView GO
-------------------------------------------------------------------- }

EMPTY  ONLY FORTH DEFINITIONS  DECIMAL

REQUIRES WINAPP

{ --------------------------------------------------------------------
Adding Tree-View Items

TV_INSERTSTRUCT structure contains information used to add a new
item to a tree-view control.

TV_ITEM structure specifies or receives attributes of a tree-view
item.

hwndTV handle of tree-view control.

AddItemToTree adds items to a tree-view control. Returns the handle of
the newly added item.
        lpszItem - text of the item to add
        nLevel - level at which to add the item

InitTreeViewItems passes strings to a function that adds them to a
tree-view control.
-------------------------------------------------------------------- }

CLASS TV_ITEM
   VARIABLE .mask
   VARIABLE .hItem
   VARIABLE .state
   VARIABLE .stateMask
   VARIABLE .pszText
   VARIABLE .cchTextMax
   VARIABLE .iImage
   VARIABLE .iSelectedImage
   VARIABLE .cChildren
   VARIABLE .lParam
END-CLASS

CLASS TV_INSERTSTRUCT
   VARIABLE .hParent
   VARIABLE .hInsertAfter
   TV_ITEM BUILDS .tvi
END-CLASS

TV_INSERTSTRUCT BUILDS tvins

0 VALUE hwndTV

TVI_FIRST VALUE hPrev

TV_FIRST 0 + CONSTANT TVM_INSERTITEM

NULL VALUE hPrevRootItem
NULL VALUE hPrevLev2Item

: AddItemToTree ( nLevel lpszItem -- hTreeItem )
   TVIF_TEXT TVIF_PARAM OR tvins .tvi .mask !
   DUP tvins .tvi .pszText !              \ Set the text of the item.
   ZCOUNT NIP tvins .tvi .cchTextMax !

   \ Save the heading level in the item's application-defined
   \ data area.
   DUP tvins .tvi .lParam !

   hPrev tvins .hInsertAfter !

   \ Set the parent item based on the specified level.
   DUP CASE  1 OF  TVI_ROOT       ENDOF
             2 OF  hPrevRootItem  ENDOF
               >R  hPrevLev2Item  R>
   ENDCASE  tvins .hParent !

   \ Add the item to the tree-view control.
   hwndTV TVM_INSERTITEM 0 tvins ADDR SendMessage

   \ Save the handle of the item.
   SWAP CASE  1 OF  DUP TO hPrevRootItem  ENDOF
              2 OF  DUP TO hPrevLev2Item  ENDOF
   ENDCASE  DUP TO hPrev ;

0 VALUE HITEM-1
0 VALUE HITEM-2
0 VALUE HITEM-3
0 VALUE HITEM-4

: InitTreeViewItems ( -- flag )
   1 Z" Count" AddItemToTree DUP IF  TO HITEM-1
   2 Z" One"   AddItemToTree DUP IF  TO HITEM-2
   3 Z" One.1" AddItemToTree DUP IF  TO HITEM-3
   2 Z" Two"   AddItemToTree DUP IF  TO HITEM-4  -1
   THEN THEN THEN THEN ;

{ --------------------------------------------------------------------
Creating a Tree-View Control

RECT structure defines the coordinates of the upper-left and
lower-right corners of a rectangle.

rcClient dimensions of client area.

CreateATreeView creates a tree-view control, returning the handle of
the new control if successful or NULL otherwise.

SET-BOLD makes the display of the given items use a bold font.

-------------------------------------------------------------------- }

RECT BUILDS rcClient

CREATE WC_TREEVIEW ,Z" SysTreeView32"

0 VALUE hwndSHELL

: CreateATreeView ( -- hwnd )
   AppStart TO hwndSHELL
   \ Get the dimensions of the parent window's client area
   hwndSHELL rcClient left GetClientRect DROP
   \ Create the tree-view control.
   0                                 \ extended style
   WC_TREEVIEW                       \ window class name
   Z" Tree View"                     \ caption
   WS_VISIBLE WS_CHILD OR WS_BORDER OR
   TVS_HASLINES OR TVS_LINESATROOT OR
   TVS_HASBUTTONS OR                 \ window style
   0 0 rcClient right @
       rcClient bottom @             \ initial position
   hwndSHELL                         \ parent window handle
   999                               \ window menu handle
   HINST                             \ program instance handle
   NULL                              \ creation parameter
   CreateWindowEx DUP TO hwndTV
   \ Initialize the image list, and add items to the control.
   InitTreeViewItems 0= IF
      DestroyWindow DROP  0
   THEN ;

TV_ITEM BUILDS pitem

: SET-BOLD ( hTreeView hItem -- res )
   TVIF_STATE pitem .mask !
   TVIS_BOLD pitem .stateMask !
   TVIS_BOLD pitem .state !
   pitem .hItem !
   TVM_SETITEMA 0 pitem ADDR SendMessage ;

: TREEVIEW CreateATreeView
   DUP HITEM-2 SET-BOLD DROP
       HITEM-4 SET-BOLD DROP ;

CR
CR .( A Tree View sample control)
CR
CR .( Type TREEVIEW to run the demo.)
CR
