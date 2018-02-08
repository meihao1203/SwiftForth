\ FILE LIST INCLUDED BY BUILD.F

INCLUDE %SWIFTX\SRC\COLDFIRE\CONFIG             \ Generic configuration
INCLUDE CONFIG                                  \ Target configuration
INCLUDE %SWIFTX\SRC\COLDFIRE\USER               \ User variables
INCLUDE %SWIFTX\SRC\COLDFIRE\CORE               \ Core word set
INCLUDE %SWIFTX\SRC\COLDFIRE\EXTRA              \ Miscellaneous extensions
INCLUDE %SWIFTX\SRC\CORE                        \ Common core words
INCLUDE %SWIFTX\SRC\COLDFIRE\EXCEPT             \ Exception handling
INCLUDE %SWIFTX\SRC\COLDFIRE\MATH               \ Core math operators
INCLUDE %SWIFTX\SRC\COLDFIRE\DOUBLE             \ Double-precision numbers
INCLUDE %SWIFTX\SRC\DOUBLE                      \ Double-precision numbers
INCLUDE %SWIFTX\SRC\MIXED                       \ Mixed precision math
INCLUDE %SWIFTX\SRC\COLDFIRE\STRING             \ Core string operators
INCLUDE %SWIFTX\SRC\STRING                      \ Core string operators
INCLUDE %SWIFTX\SRC\COLDFIRE\OPT                \ Optimizer rules
INCLUDE %SWIFTX\SRC\VIO                         \ Vectored I/O functions
INCLUDE %SWIFTX\SRC\EXCEPT                      \ Common exception handling
INCLUDE %SWIFTX\SRC\OUTPUT                      \ Core and facility output functions
INCLUDE %SWIFTX\SRC\OUTPUT2                     \ Double output functions
INCLUDE %SWIFTX\SRC\NUMBER                      \ Numeric input conversion functions
INCLUDE %SWIFTX\SRC\METHODS                     \ Methods and VALUE
INCLUDE %SWIFTX\SRC\COLDFIRE\TASKER             \ Multitasker
INCLUDE %SWIFTX\SRC\TOOLS                       \ Debug tools
INCLUDE %SWIFTX\SRC\DUMP1                       \ Memory dump
INCLUDE %SWIFTX\SRC\COLDFIRE\REG_52235          \ MCF52235 internal registers
INCLUDE %SWIFTX\SRC\COLDFIRE\EV-IRAM            \ Exception vectors in internal RAM
INCLUDE %SWIFTX\SRC\COLDFIRE\BDM                \ Background debug mode interface
INCLUDE %SWIFTX\SRC\COLDFIRE\STEPPER            \ Single-step debug support
INCLUDE %SWIFTX\SRC\COLDFIRE\TRAP               \ Generic trap handler
INCLUDE %SWIFTX\SRC\COLDFIRE\TIMER_PIT          \ Coldfire PIT system timer
INCLUDE %SWIFTX\SRC\COLDFIRE\CLOCK              \ Timer-based clock
INCLUDE %SWIFTX\SRC\TIMING                      \ Common timing functions
INCLUDE %SWIFTX\SRC\ACCEPT                      \ Generic terminal input
INCLUDE %SWIFTX\SRC\COLDFIRE\UARTS              \ UART port(s) serial terminal
CDATA                                           \ Calendar table in code space
INCLUDE %SWIFTX\SRC\CALENDAR                    \ Julian date calendar
IDATA
INCLUDE %SWIFTX\SRC\DATE                        \ System date access
INCLUDE %SWIFTX\SRC\CLOCK                       \ Time of day functions
INCLUDE %SWIFTX\SRC\TIMEDATE                    \ Clock and calendar functions
TARGET-INTERP [IF]
INCLUDE %SWIFTX\SRC\COLDFIRE\INTERP             \ Resident interpreter support
INCLUDE %SWIFTX\SRC\INTERP                      \ Resident interpreter
INCLUDE %SWIFTX\SRC\MEM                         \ Resident memory management
INCLUDE %SWIFTX\SRC\COLDFIRE\COMP               \ Resident compiler support
INCLUDE %SWIFTX\SRC\COMP                        \ Resident compiler
INCLUDE %SWIFTX\SRC\QUIT                        \ Interpreter loop
[THEN]
INCLUDE APP                                     \ **YOUR APPLICATION LOADED BY THIS FILE**
INCLUDE %SWIFTX\SRC\COLDFIRE\START              \ Common initialization
INCLUDE START                                   \ Power-up
INCLUDE %SWIFTX\SRC\COLDFIRE\FLASHLOADER        \ Flash programming via BDM
