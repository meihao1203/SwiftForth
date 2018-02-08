{ =====================================================================
Morse Code S.O.S. Beacon

Copyright 2001-2007  FORTH, Inc.

This little demo app shows a simple application using the LED on the
evaluation board.

Requires board-specific LED interface and MS (millisecond delay)
function.

===================================================================== }

TARGET

{ ---------------------------------------------------------------------
Timing

The speed of Morse code is typically specified in "words per minute"
(WPM). In text-book, full-speed Morse, a dah is conventionally 3 times
as long as a dit. The spacing between dits and dahs within a character
is the length of one dit; between letters in a word it is the length of
a dah (3 dits); and between words it is 7 dits. The "Paris standard"
defines the speed of Morse transmission as the dot and dash timing
needed to send the word "Paris" a given number of times per minute. The
word Paris is used because it is precisely 50 "dits" based on the text
book timing.

Under this standard, the time unit for one "dit" can be computed by the
formula:

    Tu = 1200 / W

Where: W is the desired speed in words-per-minute, and Tu is one dit-time
in milliseconds.

Tu holds the current value of one "dit" time.  The default value of 120
sets the initial rate at 10 WPM as defined above.

WPM sets Tu based on the formula above.
DELAY pauses for n dit times.
--------------------------------------------------------------------- }

CREATE Tu  120 ,

: WPM ( n -- )   1200 SWAP /  Tu ! ;
: DELAY ( n -- )   Tu @ * MS ;

{ ---------------------------------------------------------------------
Morse code elements

DIT and DAH are the short and long morse code output elements.
--------------------------------------------------------------------- }

: DIT ( -- )   +LED  1 DELAY  -LED  1 DELAY ;
: DAH ( -- )   +LED  3 DELAY  -LED  1 DELAY ;

{ ---------------------------------------------------------------------
Character codes
--------------------------------------------------------------------- }

: S ( -- )   DIT DIT DIT  2 DELAY ;
: O ( -- )   DAH DAH DAH  2 DELAY ;

{ ---------------------------------------------------------------------
Distress signal
--------------------------------------------------------------------- }

: SOS ( -- )  S O S  4 DELAY ;
