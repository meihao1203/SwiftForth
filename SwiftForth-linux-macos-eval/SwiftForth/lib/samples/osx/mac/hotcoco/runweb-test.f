{ ====================================================================
Web browsing

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version
Running the webview stuff from cocoanib on mainthread
Note: When using floatingpoint numbers in callbacks, you'll have to
add fstack space in SwiftForth with: n FSTACK
It's like MacForth with fp.init
A lot if not all Mac OSX GUI objects use floats!
Needs cocoawebview6.f
Last: 18 Oct 2016 18:39:41 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
All GUI stuff should be run on the main thread. The web browser created
in cocoawebview3.f runs in Forth, here not on the main thread.

Solution is to create a control panel, run on the main thread, which
executes cocoawebview3 words. A Heads Up Display is used as control
panel: resources/runweb-sf.nib

Creation follows the normal procedure: method implementations,
class creation, loading NIB and run it.
-------------------------------------------------------------------- }

PUSHPATH  MAC INCLUDE hotcoco/cocoawebview6.f  POPPATH

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ The so called IBAction connected to the buttons in the window

CALLBACK: *cocoa: ( rec sel sender:button -- n )  8 fstack cocoa 0 ;

CALLBACK: *bmb: ( rec sel sender:button -- n )  8 fstack bmb  0 ;

CALLBACK: *sf: ( rec sel sender:button -- n )  8 fstack swifo  0 ;

CALLBACK: *info: ( rec sel sender:button -- n )  8 fstack info  0 ;

CALLBACK: *<go: ( rec sel sender:button -- n )  8 fstack <go  0 ;

CALLBACK: *go>: ( rec sel sender:button -- n )  8 fstack go>  0 ;

COCOA: @stringValue ( -- string )			\ NSControl method, NSTextView inherits from NSControl: -- NSString object
CALLBACK: *runit: ( rec sel sender:textview -- n )  8 fstack _param_2 @stringValue >4thstring drop load  0 ;

CALLBACK: *reload: ( rec sel sender:button -- n )  8 fstack reload  0 ;

: RUNWEBTYPES ( -- addr )  0" v@:V" ;

\ --------------------------------------------------------------------
\ Create class

NSObject new.class runWebClass

\ assign callback as method to the class and register its name with the objc runtime
*cocoa:    RUNWEBTYPES  0" runWebCocoa:"     runWebClass ADD.METHOD
*bmb:      RUNWEBTYPES  0" runWebBMB:"       runWebClass ADD.METHOD
*sf:       RUNWEBTYPES  0" runWebsf:"        runWebClass ADD.METHOD
*info:     RUNWEBTYPES  0" runWebInfo:"      runWebClass ADD.METHOD
*<go:      RUNWEBTYPES  0" runWebBackward:"  runWebClass ADD.METHOD
*go>:      RUNWEBTYPES  0" runWebForward:"   runWebClass ADD.METHOD
*runit:    RUNWEBTYPES  0" runWebIt:"        runWebClass ADD.METHOD
*reload:   RUNWEBTYPES  0" runWebReload:"    runWebClass ADD.METHOD

\ add the class
runWebClass ADD.CLASS

\ --------------------------------------------------------------------
\ The Nib stuff, a full path including nib filename

\ Show it
\ : DO.SHOW ( -- )    Z" runweb-sf.nib" @NIB /NIB 0= ABORT" Can't initiate NIB !" ;
: DO.SHOW ( -- )    Z" runweb-sf.nib" SHOW.NIB 0= ABORT" Can't initiate NIB !" ;

cr .( do.show  -- to start things)
cr .( use the control panel to navigate the web)

\\ ( eof )
