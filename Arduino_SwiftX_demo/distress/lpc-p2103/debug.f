\ TARGET TESTING

TARGET  KERNEL  PRAM
RELOAD  CR CR GREET

{ ---------------------------------------------------------------------
Interactive debug mode

SET-DOWNLOAD and DOWNLOAD-ALL are provided by the SwiftX debug
environment to speed up the loading and testing of target code. The
code is compiled to host memory and then downloaded to the target.

SET-DOWNLOAD disconnects the XTL and remembers the starting target
addresses for HERE and THERE.  This should be followed by the target
test files to be included.

DOWNLOAD-ALL reconnects the XTL and downloads CDATA and IDATA added
since SET-DOWNLOAD.  This bulk download is much faster than loading
the target definitions with the XTL connected.

Important: Any interactive target initialization must be done after
the DOWNLOAD-ALL.
--------------------------------------------------------------------- }

SET-DOWNLOAD  DECIMAL
\ Load test code here

\ INCLUDE %SWIFTX\SRC\ARM\FRACTION      \ Fractional arithmetic
\ INCLUDE %SWIFTX\SRC\FRACTION           \ Fractional angles and trig

INCLUDE %SWIFTX\SRC\CONICAL             \ Conical piles demo
{
INCLUDE %SWIFTX\SRC\DUMB                \ Dumb terminal
INCLUDE %SWIFTX\SRC\ARM\SERIAL-DEMO     \ Serial terminal task demo
}

DOWNLOAD-ALL

\ Perform target initialization here

HOST @NOW  TARGET !NOW
@LAST LAST !
\ CONSOLE CONSTRUCT   DEMO
