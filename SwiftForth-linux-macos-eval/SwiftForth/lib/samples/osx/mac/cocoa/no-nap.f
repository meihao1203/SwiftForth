{ ====================================================================
No AppNap

Copyright (c) 2013-2017 Roelf Toxopeus

Specific OS handling.
SwiftForth version.
Protect coco-sf from being put to sleep by OS
Last: 22 December 2013 11:07:39 CET   -rt
==================================================================== }

{ --------------------------------------------------------------------
Run the following in the Terminal window of coco-sf:

: TT ( -- )   BEGIN  CR ." ONE " 500 MS ." TWO " 1000 MS ." TEST" KEY? UNTIL ;

Notice after a short while the output gets irregular. As if the app is
frozen. Bringing the NSApp part to the front, kicks coco-sf in to life
again. But Terminal is in the background, not very convenient in an in-
ter active environment. It looks like the NSApp part needs some attention
once in a while.
Note: no such issues with the regular sf and the experimental coco-sf
with its own I/O window.

As we see it now (could change):
As of OSX 10.9 Mavericks, there's a new feature causing an application
to be put to sleep by the OS: App Nap. This happens under certain
circumstances as described here:
https://developer.apple.com/library/mac/releasenotes/MacOSX/WhatsNewInOSX/Articles/MacOSX10_9.html#//apple_ref/doc/uid/TP40013207-CH100

The NSApp part of coco-sf, the main thread/task, is not doing anything
for us when not having any GUI related or main thread related things
going on. Appearently the OS sees this as the whole application idling,
and puts the app napping. With concequenses for Forth...

Using the info from above mentioned Apple doc we can try to convince
the OS to keep coco-sf awake. Also see the NSProcessInfo Class Reference.
The resulting code below seems to work and Activity Monitor doesn't
show coco-sf running wild. It's just as in Mountain Lion etc.

Note: coco-sf still shows App Nap as -yes- in Activity Monitor.

Update: defaults write coco-sf NSAppSleepDisabled -bool YES
will change App Nap as -no- in Activity Monitor.
You only have to do this once, check coco-sf.plist in ~/Library/Preferences

NONAP -- first checks if the nap stuff is availlable (10.9 and up),
if so, disables App Nap.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

COCOACLASS NSProcessInfo
COCOA: @processInfo ( -- info )			 \ returns NSProcessInfo object
COCOA: @beginActivityWithOptions:reason: ( lo:option hi:option nsstring -- objecttoken )

$FF S>D 2CONSTANT NSActivityBackground                    \ used option 0x000000FFULL

VARIABLE ACTIVITY-TOKEN                                   \ for now, might need it later

: NONAP ( -- )
   Z" beginActivityWithOptions:reason:" @selector
   NSProcessInfo @processInfo
   DUP >R @respondsToSelector:
   IF   NSActivityBackground @" coco-sf stays awake!"
        R> @beginActivityWithOptions:reason: ACTIVITY-TOKEN !
   ELSE R> DROP THEN ;

\\ ( eof )
