\ FILES INCLUDED BY BUILD

INCLUDE %SWIFTX\SRC\MSP430\REG_12X              \ MSP430x12x hardware equates
INCLUDE %SWIFTX\SRC\MSP430\CONFIG               \ Common configuration
INCLUDE CONFIG                                  \ Target configuration
INCLUDE %SWIFTX\SRC\MSP430\USER                 \ User variables
INCLUDE %SWIFTX\SRC\MSP430\CORE                 \ Core word set
INCLUDE %SWIFTX\SRC\CORE                        \ Common core words
INCLUDE %SWIFTX\SRC\MSP430\EXTRA                \ Miscellaneous extensions
INCLUDE %SWIFTX\SRC\MSP430\STRING               \ Core string operators
INCLUDE %SWIFTX\SRC\STRING                      \ Core string operators
INCLUDE %SWIFTX\SRC\MSP430\EXCEPT               \ Exception handling
INCLUDE %SWIFTX\SRC\MSP430\DOUBLE               \ Double-precision numbers
INCLUDE %SWIFTX\SRC\DOUBLE                      \ Double-precision numbers
INCLUDE %SWIFTX\SRC\MSP430\MATH                 \ Core math operators
INCLUDE %SWIFTX\SRC\MIXED                       \ Mixed-precision operators
INCLUDE %SWIFTX\SRC\MSP430\OPT                  \ Initialize code optimizer
INCLUDE %SWIFTX\SRC\VIO                         \ Vectored I/O functions
INCLUDE %SWIFTX\SRC\EXCEPT                      \ Common exception handling
INCLUDE %SWIFTX\SRC\OUTPUT                      \ Core and facility output functions
INCLUDE %SWIFTX\SRC\OUTPUT2                     \ Double output functions
INCLUDE %SWIFTX\SRC\NUMBER                      \ Numeric input conversion functions
INCLUDE %SWIFTX\SRC\METHODS                     \ Methods and VALUE
INCLUDE %SWIFTX\SRC\MSP430\TASKER               \ Multitasker
INCLUDE %SWIFTX\SRC\TOOLS                       \ Debug tools
INCLUDE %SWIFTX\SRC\DUMP1                       \ Memory dump
INCLUDE %SWIFTX\SRC\MSP430\VECTORS_PROM         \ Interrupt vectors
INCLUDE %SWIFTX\SRC\MSP430\LPM                  \ Low Power Mode control
INCLUDE %SWIFTX\SRC\MSP430\XTL                  \ JTAG cross-target link
INCLUDE %SWIFTX\SRC\MSP430\STEPPER              \ Single-step debug support
INCLUDE %SWIFTX\SRC\ACCEPT                      \ Generic terminal input
INCLUDE %SWIFTX\SRC\MSP430\TIMERA               \ Timer A timing functions
INCLUDE %SWIFTX\SRC\TIMING                      \ Common timing functions
CDATA
INCLUDE %SWIFTX\SRC\CALENDAR                    \ Julian date calendar
IDATA
INCLUDE %SWIFTX\SRC\DATE                        \ System date access
INCLUDE %SWIFTX\SRC\CLOCK                       \ Time of day functions
INCLUDE %SWIFTX\SRC\TIMEDATE                    \ Clock and calendar functions
INCLUDE %SWIFTX\SRC\MSP430\FLASH                \ Resident flash programming

\ INCLUDE %SWIFTX\SRC\MSP430\FRACTION           \ Optional fractional arithmetic
\ INCLUDE %SWIFTX\SRC\FRACTION

INCLUDE APP                                     \ **YOUR APPLICATION LOADED BY THIS FILE**
INCLUDE %SWIFTX\SRC\MSP430\START                \ Common initialization
INCLUDE %SWIFTX\SRC\MSP430\FET430P120\START     \ Power-up initialization

