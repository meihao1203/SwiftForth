\ FILE LIST INCLUDED BY BUILD.F

INCLUDE %SWIFTX\SRC\ARM\CONFIG                  \ Generic configuration
INCLUDE CONFIG                                  \ Target configuration
INCLUDE %SWIFTX\SRC\ARM\USER                    \ User variables
INCLUDE %SWIFTX\SRC\ARM\CORE                    \ Core word set
INCLUDE %SWIFTX\SRC\CORE                        \ Common core words
INCLUDE %SWIFTX\SRC\ARM\EXTRA                   \ Miscellaneous extensions
INCLUDE %SWIFTX\SRC\ARM\MATH                    \ Core math operators
INCLUDE %SWIFTX\SRC\ARM\STRING                  \ Core string operators
INCLUDE %SWIFTX\SRC\STRING                      \ Core string operators
INCLUDE %SWIFTX\SRC\ARM\OPT                     \ Optimizer rules
INCLUDE %SWIFTX\SRC\VIO                         \ Vectored I/O functions
INCLUDE %SWIFTX\SRC\ARM\EXCEPT                  \ Exception handling
INCLUDE %SWIFTX\SRC\EXCEPT                      \ Common exception handling
INCLUDE %SWIFTX\SRC\ARM\DOUBLE                  \ Double-precision numbers
INCLUDE %SWIFTX\SRC\DOUBLE                      \ Double-precision numbers
INCLUDE %SWIFTX\SRC\MIXED                       \ Mixed-precision numbers
INCLUDE %SWIFTX\SRC\OUTPUT                      \ Core and facility output functions
INCLUDE %SWIFTX\SRC\OUTPUT2                     \ Double output functions
INCLUDE %SWIFTX\SRC\NUMBER                      \ Numeric input conversion functions
INCLUDE %SWIFTX\SRC\METHODS                     \ Methods and VALUE
INCLUDE %SWIFTX\SRC\ARM\TASKER                  \ Multitasker
INCLUDE %SWIFTX\SRC\TOOLS                       \ Debug tools
INCLUDE %SWIFTX\SRC\DUMP1                       \ Memory dump
INCLUDE %SWIFTX\SRC\ARM\LPC\REG_LPC2103         \ LPC2103 register map
INCLUDE %SWIFTX\SRC\ARM\LPC\INTS                \ Interrupt controller interface
INCLUDE IPL                                     \ Target-specific interrupt priority assignments
INCLUDE %SWIFTX\SRC\ARM\LPC\TIMER0              \ System millisecond timebase
INCLUDE %SWIFTX\SRC\TIMING                      \ Common timing functions
INCLUDE %SWIFTX\SRC\ARM\XTL_ICE                 \ JTAG/ICE cross-target link
CDATA                                           \ Calendar table in code space
INCLUDE %SWIFTX\SRC\CALENDAR                    \ Julian date calendar
IDATA
INCLUDE %SWIFTX\SRC\ARM\LPC\RTC                 \ Real-time clock
INCLUDE %SWIFTX\SRC\DATE                        \ System date access
INCLUDE %SWIFTX\SRC\CLOCK                       \ Time of day functions
INCLUDE %SWIFTX\SRC\TIMEDATE                    \ Clock and calendar functions
INCLUDE %SWIFTX\SRC\ACCEPT                      \ Generic terminal input
INCLUDE %SWIFTX\SRC\ARM\SERIAL                  \ Common UART support
INCLUDE %SWIFTX\SRC\ARM\LPC\UART                \ UART terminal I/O
TARGET-INTERP [IF]
INCLUDE %SWIFTX\SRC\ARM\INTERP                  \ Resident interpreter support
INCLUDE %SWIFTX\SRC\INTERP                      \ Resident interpreter
INCLUDE %SWIFTX\SRC\MEM                         \ Resident memory management
INCLUDE %SWIFTX\SRC\ARM\COMP                    \ Resident compiler support
INCLUDE %SWIFTX\SRC\COMP                        \ Resident compiler
INCLUDE %SWIFTX\SRC\QUIT                        \ Interpreter loop
[THEN]
INCLUDE %SWIFTX\SRC\ARM\LPC\FLASHLOADER         \ Flash loader
INCLUDE APP                                     \ **YOUR APPLICATION LOADED BY THIS FILE**
INCLUDE %SWIFTX\SRC\ARM\START                   \ Common initialization
INCLUDE START                                   \ Power-up
