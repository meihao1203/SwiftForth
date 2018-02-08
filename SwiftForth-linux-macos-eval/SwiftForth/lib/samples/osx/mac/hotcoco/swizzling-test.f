{ ====================================================================
Method swizzling

Copyright (c) 2006-2017 Roelf Toxopeus

SwiftForth version.
Testing method swizzling.
Plays with NSWindow's close method:  (void)close
Last: 28 October 2015 at 17:02:54 GMT+1  -rt
==================================================================== }

{ --------------------------------------------------------------------
Apart from subclassing and delegation to change default behaviour,
there's a third way which is quite interesting.

It works on a lower implementation level:

It's like method swizling. Replace a method implementation.
As you might recall it was hinted at in ObjC 1 Runtime.
In the ObjC 2 Runtime it looks legal to use ;-)

class_getInstanceMethod ( obj SEL -- Method )

method_getImplementation ( Method -- IMP )
The returned IMP can be executed like an external library function.

method_setImplementation ( Method IMP -- IMP )
The passed in IMP is like a Forth callback with the appropriate
signature.

Its easy, perhaps trivial, to wrap these functions in getter and
setter words.

Experiments show the changes have only effect on methods in your
own application. As expected. So there's no system wide harm...
(the system enhancer hacks like Pithhelmet, Glimms, Safari Cookies
etc. make use of a global version of this: SIMBL
http://culater.net/wiki/moin.cgi/CocoaReverseEngineering )

In this light you could see methods as DEFERed Forth words. You plug
in what's needed. I must say, I haven't used this in real world
applications. No need (yet), the defaults suffice.

But what I do use in one case, is executing the method implementation
directly. Bypassing the late binding messaging mechanism.
I do this with real time video processing. No crashes yet.
Note: the method caching mechanism used by the ObjC runtime might
result in similar swiftness. Still it's good to know you can do this
unpunished (so far).

Here, experiment with the close method of NSWindow.
Firts get the instance mathod and its implementation.
Than plug another implementation, a Forth callback, in to the
method, /CLOSE. Make sure the situation can be undone: -CLOSE.
Add two windows and hit the red buttons.

Next test by-passing message sending using CLOSE.FAST.
Add a third window and execute WIN3 CLOSE.FAST
Not that the difference is noted, but at least it works.
See fastcocoa.f for more.

Note: when you loaded this file as is with LOAD-FILE, you may have 
noticed the new closing message printed twice. You did not close
any window yet, did you? Actually you did: the Filekite. Appearently
it contains two objects which were closed by the ObjC runtime, when
it was released.
You can check this by LOAD-FILE another file. Then run -CLOSE and try
again. No more messages...

Note: method implementations follow the rules of their messages:
so take care of mainthread requirements.

-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ take care when turnkeying: beware of constant !
NSWindow 0" close" @SELECTOR class_getInstanceMethod CONSTANT CLOSE-METHOD

\ take care when turnkeying: beware of constant !
CLOSE-METHOD method_getImplementation CONSTANT CLOSE-IMP

CALLBACK: NEW.CLOSE-IMP ( receiver selector -- ) 
   IMPOSTOR'S CR ." we will close..."
   _PARAM_0 _PARAM_1 2 CLOSE-IMP EXTERN-CALL
   CR ." ...done!" ;

: /CLOSE ( -- )   CLOSE-METHOD NEW.CLOSE-IMP method_setImplementation DROP ;

: -CLOSE ( -- )   CLOSE-METHOD CLOSE-IMP method_setImplementation DROP ;

/CLOSE

NEW.WINDOW WIN1
S" win1"   WIN1 W.TITLE
WIN1 ADD.WINDOW

NEW.WINDOW WIN2
S" win2"   WIN2 W.TITLE
WIN2 ADD.WINDOW

: CLOSE.FAST ( wptr4 -- )
	+W.REF @ [ 0" close" @SELECTOR ] LITERAL 2 CLOSE-IMP EXTERN-CALL DROP ;

NEW.WINDOW WIN3
S" win3"   WIN3 W.TITLE
WIN3 ADD.WINDOW

\ WIN3 1 0 ' CLOSE.FAST PASS

\\ ( eof )
