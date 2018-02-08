{ ====================================================================
Extend SwifForth OSX with Cocoa

Copyright (c) 2010-2017 Roelf Toxopeus

Load file with Cocoa extensions for a Darwin Forth system.
Adapt system specifcs like comment words, initial extensions and pivot
directory to include from, when porting. That's all.
Last: 15 November 2017 at 10:31:01 CEST  rt
==================================================================== }

{ --------------------------------------------------------------------
First include required electives.
Then create the path for the mac folder: MACPATH
The path is relative to ROOTPATH and obtained during the compilation
of coco-sf. In practice, this will be either:   %mac/   when compiled
from my distribution with   INCLUDE %new-coco
or   %swiftforth/lib/samples/osx/mac/   when compiled from the FORTH,
Inc distro with  REQUIRES new-coco

This MACPATH will be the pivot for further loading. Also used to find
necessary items like resources. The later to be defined word MAC will
use MACPATH to set the mac folder as the working directory.

Finaly start including the Cocoa extensions, ending with the OS fixes
and necessary initialisers.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --------------------------------------------------------------------
\ floating point math and George Kozlowski fp extensions

CR .( Loading George Kozlowski's and FORTH, Inc. supplied extra's)

REQUIRES fp-passing.f  					\ all the needed fp, contains requires fpmath.f

\ --------------------------------------------------------------------
\ set pivot directory and start including

CREATE MACPATH
INCLUDING -NAME PAD FULLNAME			\ needed for chdir later
S" /" PAD ZAPPEND
PAD -ROOT STRING,

PAD chdir DROP								\ make sure we're in the mac folder

CR .( Loading Roelf's stuff ...)

\ --------------------------------------------------------------------
\ petwords and compatibility layer

INCLUDE system/function-plus.f      \ SwiftForth only, spot foreign functions returning 2 values, optional
INCLUDE utils/mypatterns.f				\ SwiftForth only, extra patterns for optimizer, optional
INCLUDE utils/mypets.f					\ pet words, these needed for initial setup: (* LACKING 0" .H
INCLUDE utils/fp-precision-fast.f	\ 32b <-> 64b fp conversion words, some faster kernel redefinitions
INCLUDE utils/fp-utils.f				\ fstack jugglers and fp parameter passing
INCLUDE utils/double-extras.f			\ extra double words
INCLUDE utils/waypoints.f				\ help navigate through the file system
INCLUDE utils/mylist.f					\ relative chain/list words
INCLUDE randoms/baden-rnd.f			\ random number generator and extra's

\ --------------------------------------------------------------------
\ specific OS interaction

INCLUDE system/frameworkstuff.f		\ Mac OSX framework (libraries) accessors
INCLUDE system/abi-call-extras.f		\ extra ABI words, passing additional parameter
INCLUDE system/task-control.f			\ extra task control, optional
INCLUDE system/dispatchtasking.f	   \ multi core CPU scheduling, substitute for posix, optional
INCLUDE system/xcallback.f          \ substitute for :NONAME and CB:, optional
INCLUDE system/pthread_sigmask.f    \ set thread specific signal masks
 
\ --------------------------------------------------------------------
\ required for Cocoa, and other OS functionality

INCLUDE system/corefoundation.f		\ C based OSX core foundation functions
INCLUDE image/quartz/quartz-utils.f	\ fp structure accessors
INCLUDE bundling/bundlecheck.f		\ find the correct resources path, for nibs etc.

\ --------------------------------------------------------------------
\ the Cocoa interface for the Obj_C 2.0 Runtime

INCLUDE cocoa/coco-sf.f				   \ the objective C interface

\ --------------------------------------------------------------------
\ Fixes for OS issues

CR .( Loading OSX specific issue fixers ...)

\ Targeted at OSX 10.10 Yosemite and 10.11 El Capitan
\ Not needed in 10.12 Sierra and 10.6-10.9 pre-Yosemite, but doesn't do any harm when applied
INCLUDE system/yosemite.f			   \ temporary OS glitch fixes

\ Targeted at OSX 10.11 El Capitan and 19.12 Sierra
\ Not needed in 10.10 Yosemite and earlier, but doesn't do any harm when applied
INCLUDE system/elcapitan.f			   \ temporary OS glitch fixes

\ Targeted at OSX 10.12 Sierra
\ Not needed in 10.11 El Capitan and earlier, but doesn't do any harm when applied
INCLUDE system/sierra.f			      \ temporary OS glitch fixes

\ --------------------------------------------------------------------
\ Last before...

\ the Forth tread is posix, so user interrupt works.
\ make all ACTIVATEd tasks GCD from here on:
AKA ACTIVATE POSIX.ACTIVATE
DEFER ACTIVATE
' DISPATCH IS ACTIVATE					( ' POSIX.ACTIVATE IS ACTIVATE )

\\ ( eof )
