\ FILE LIST INCLUDED BY BUILD.F

INCLUDE %SWIFTX\SRC\68HCS08\CONFIG              \ Common configuration
INCLUDE CONFIG                                  \ Target configuration
INCLUDE %SWIFTX\SRC\68HCS08\REG_GB60            \ Registers and exception vectors
INCLUDE %SWIFTX\SRC\68HCS08\CORE                \ Core word set
INCLUDE %SWIFTX\SRC\68HCS08\USER                \ User variables
INCLUDE %SWIFTX\SRC\CORE                        \ Common core words
INCLUDE %SWIFTX\SRC\68HCS08\EXTRA               \ Miscellaneous extensions
INCLUDE %SWIFTX\SRC\68HCS08\MATH                \ Core math operators
INCLUDE %SWIFTX\SRC\68HCS08\DOUBLE              \ Double-precision operators
INCLUDE %SWIFTX\SRC\DOUBLE                      \ Double-precision operators
INCLUDE %SWIFTX\SRC\MIXED                       \ Mixed-precision operators
INCLUDE %SWIFTX\SRC\68HCS08\STRING              \ Core string operators
INCLUDE %SWIFTX\SRC\STRING                      \ Core string operators
INCLUDE %SWIFTX\SRC\VIO                         \ Vectored I/O functions
INCLUDE %SWIFTX\SRC\68HCS08\EXCEPT              \ Exception handling
INCLUDE %SWIFTX\SRC\EXCEPT                      \ Common exception handling
INCLUDE %SWIFTX\SRC\68HCS08\TASKER              \ Multitasker
INCLUDE %SWIFTX\SRC\OUTPUT                      \ Core and facility output functions
INCLUDE %SWIFTX\SRC\OUTPUT2                     \ Double output functions
INCLUDE %SWIFTX\SRC\NUMBER                      \ Numeric input conversion functions
INCLUDE %SWIFTX\SRC\METHODS                     \ Methods and VALUE
INCLUDE %SWIFTX\SRC\TOOLS                       \ Debug tools
INCLUDE %SWIFTX\SRC\DUMP1                       \ Memory dump
INCLUDE %SWIFTX\SRC\68HCS08\EV-RAM              \ Exception vectors in RAM
INCLUDE %SWIFTX\SRC\68HCS08\TIMER_RTI           \ Millisecond counter
INCLUDE %SWIFTX\SRC\TIMING                      \ Common timing functions
INCLUDE %SWIFTX\SRC\XTLCTRL                     \ XTL support
INCLUDE %SWIFTX\SRC\68HCS08\BDM                 \ Cross-target link via BDM interface
INCLUDE %SWIFTX\SRC\ACCEPT                      \ Terminal input
INCLUDE %SWIFTX\SRC\68HCS08\SCITERM
INCLUDE APP                                     \ **YOUR APPLICATION LOADED BY THIS FILE**
INCLUDE %SWIFTX\SRC\68HCS08\START               \ Common initialization
INCLUDE START                                   \ Power-up
INCLUDE %SWIFTX\SRC\68HCS08\FLASHLOADER
