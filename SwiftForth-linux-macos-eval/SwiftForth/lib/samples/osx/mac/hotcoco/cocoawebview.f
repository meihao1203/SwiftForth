{ ====================================================================
WebKit browsing

Copyright (C) 2006-2017 Roelf Toxopeus

SwiftForth version and Snowleopard Mac OSX 10.6 and later
Playing with webkit.
Last: 18 November 2017 at 09:54:48 CEST   -rt
==================================================================== }

{ --------------------------------------------------------------------
Implement a crude webbrowser.

WEBWIN -- window for web content.
NEW.WEBVIEW -- create new webview instance, fitting the contentview.
Use INIT, no need for a frame size, works on Panther and upwards.
MAKE-WEBVIEW -- creates new webview and connects to given window.
HELLO-WEB -- initialise and open a window for web browsing
BYE-WEB -- closes it.

LOAD -- will open window and load and display the given url.
<GO -- attemp to go to back
GO> -- attemp to go forward
RELOAD -- reload current url

Note: as of OS X 10.11 many NSWindow NSView and WebKit usage should be executed on the main thread.
Examples of strategic placing PASS ...

Following words are executed on Main thread:
SHOW-VIEW ( ADD.WINDOW)
NEW.WEBVIEW
MAKE-WEBVIEW ( SHOW-VIEW NEW.WEBVIEW and MAKE.CONTENTVIEW)
LOADREQUEST
GOBACK
GOFORWARD
RELOAD

This is what you see when URL loading and navigating is not executed on the main thread:

maps  ok
knmi  ok
<go 2016-10-16 10:43:30.125 coco-sf[661:17814] WebKit Threading Violation - -[WebHistoryItem initWithWebCoreHistoryItem:] called from secondary thread
2016-10-16 10:43:30.125 coco-sf[661:17814] Additional threading violations for this function will not be logged.
2016-10-16 10:43:30.126 coco-sf[661:17814] WebKit Threading Violation - DOMDocument *kit(WebCore::Document *) called from secondary thread
2016-10-16 10:43:30.127 coco-sf[661:17814] Additional threading violations for this function will not be logged.
2016-10-16 10:43:30.127 coco-sf[661:17814] WebKit Threading Violation - DOMNode *kit(WebCore::Node *) called from secondary thread
2016-10-16 10:43:30.127 coco-sf[661:17814] Additional threading violations for this function will not be logged.

and the webkit activities stalls.

-------------------------------------------------------------------- }


/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ Window for webview:
NEW.WINDOW WEBWIN

: SHOW-VIEW ( wptr4 -- )
	DUP ADD.WINDOW
	0" Web View" SWAP SET.WTITLE ;

\ --------------------------------------------------------------------
\ Create a webview:

FRAMEWORK WebKit.framework
WebKit.framework

COCOACLASS WebView

COCOA: @mainFrame ( -- frame )				   \ WebView

VARIABLE NATIVEVIEW		\ global usage
VARIABLE MAINWEBFRAME	\ global usage

\ Main thread redefinitionS
: (NEW.WEBVIEW) ( -- )  WebView @alloc @init POCKET ! ;
: NEW.WEBVIEW ( -- WebViewRef )  0 DUP ['] (NEW.WEBVIEW) PASS POCKET @ ;

\ SHOW-VIEW NEW.WEBVIEW and MAKE.CONTENTVIEW are executed on main thread
: MAKE-WEBVIEW ( wptr4 -- )
	DUP >R SHOW-VIEW
	NEW.WEBVIEW DUP NATIVEVIEW !				\ make new webview instance and save
	DUP R> MAKE.CONTENTVIEW						\ connect to nswindow
	@mainFrame MAINWEBFRAME !			      \ retrieve the main webframe and save
;

: HELLO-WEB ( -- )	WEBWIN DUP +W.REF @ IF DROP EXIT THEN MAKE-WEBVIEW ;

: BYE-WEB ( -- )	WEBWIN CLOSE.WINDOW ;

\ --------------------------------------------------------------------
\ Interface: load url in web view

COCOACLASS NSURL
COCOACLASS NSURLRequest

COCOA: @URLWithString:	( NSStringRef -- NSURLRef )	 \ NSURL
COCOA: @requestWithURL: ( NSURLRef -- NSURLRequesRef ) \ NSURLRequest
COCOA: @loadRequest: ( NSURLRequesRef -- ret )	       \ WebFrame

: REQUEST ( 0string -- NSURLRequesRef )
	>NSSTRING NSURL @URLWithString:
	NSURLRequest @requestWithURL: ;
	
: LOADREQUEST ( 0string frame -- )  >R REQUEST R> @loadRequest: DROP ;

: LOAD ( url -- )   HELLO-WEB MAINWEBFRAME @ 2 0 ['] LOADREQUEST PASS ;

\ --------------------------------------------------------------------
\ Interface: more controls

COCOA: @canGoBack ( -- flag )     \ BOOL
COCOA: @goBack ( -- flag )        \ BOOL
COCOA: @canGoForward ( -- flag )  \ BOOL
COCOA: @goForward ( -- flag )     \ BOOL 
COCOA: @reload: ( sender -- ret ) \ id

: GOBACK ( obj -- )   DUP @canGoBack IF  @goBack  THEN  DROP  ;
: GOBACK ( obj -- )   1 0 ['] GOBACK PASS ;
: <GO ( -- )  NATIVEVIEW @ GOBACK ;

: GOFORWARD ( obj -- )   DUP @canGoForward IF  @goForward  THEN  DROP ;
: GOFORWARD ( obj -- )   1 0 ['] GOFORWARD PASS ;
: GO> ( -- )   NATIVEVIEW @ GOFORWARD ;

: RELOAD ( -- )   MAINWEBFRAME @ NATIVEVIEW @ @reload: ;
: RELOAD ( -- )   0 0 ['] RELOAD PASS ;

\ --------------------------------------------------------------------
\ Shortcuts:

: BMB ( -- )   0" http://www.bmbcon.org" LOAD ;

: KNMI ( -- )   0" http://www.knmi.nl" LOAD ;

: HAIKU ( -- )   0" https://forthsalon.appspot.com" LOAD ;

: COCOA ( -- )   0" http://developer.apple.com/library/mac/index.html" LOAD ;

: INFO ( -- )   0" https://www.ixquick.com/" LOAD ;

: UBU ( -- )   0" http://www.ubu.com/" LOAD ;

: SWIFO ( -- )   0" http://www.forth.com/swiftforth/version.html" LOAD ;

: MAPS ( -- )   0" http://www.openstreetmap.org/#map=12/51.9811/5.9055" LOAD ;

\\ ( eof )