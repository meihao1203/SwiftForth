{ ====================================================================
Extend SwiftForth

Copyright (C) 2001 FORTH, Inc.

This is the file loaded by the HI command to extend the SwiftForth
environment.
==================================================================== }

\ --------------------------------------------------------------------
\ Required extensions

INCLUDE %SwiftForth\src\ide\errmessages                 \ The basis for error handling
INCLUDE %SwiftForth\src\ide\encapsulate                 \ Simple vocabulary management
INCLUDE %SwiftForth\src\ide\asm80x86                    \ The opcode assembler
INCLUDE %SwiftForth\src\ide\assembler                   \ The 80x86 assembler
INCLUDE %SwiftForth\src\ide\optimizer                   \ Optimizing compiler
INCLUDE %SwiftForth\src\ide\inlines                     \ Inline expansions of common phrases
INCLUDE %SwiftForth\src\ide\patterns                    \ Patterns of xts to be optimized
INCLUDE %SwiftForth\src\ide\swoopopt                    \ Optimization for swoop
/OPTIMIZER                                              \ Initialize code optimizer

\ --------------------------------------------------------------------
\ Extensions

INCLUDE %SwiftForth\src\ide\preamble                    \ Common support
INCLUDE %SwiftForth\src\ide\win32\preamble              \ Win32 support
INCLUDE %SwiftForth\src\ide\tools                       \ Programmer tools
INCLUDE %SwiftForth\src\ide\prune                       \ Dictionary management
INCLUDE %SwiftForth\src\ide\aswoop                      \ Object oriented programming
INCLUDE %SwiftForth\src\ide\localvariables              \ Variables and objects on the return stack
INCLUDE %SwiftForth\src\ide\buffio                      \ Buffered io personality
INCLUDE %SwiftForth\src\ide\decode                      \ Disassembler/decompiler
INCLUDE %SwiftForth\src\ide\strings                     \ Extended string functions
INCLUDE %SwiftForth\src\ide\values                      \ Value OOP extension
INCLUDE %SwiftForth\src\ide\fileviewer                  \ View lines of a file
INCLUDE %SwiftForth\src\ide\locate                      \ Locate source code
INCLUDE %SwiftForth\src\ide\vocabularies                \ Vocabularies, wordlist management
INCLUDE %SwiftForth\src\ide\traverse                    \ Traverse wordlists
INCLUDE %SwiftForth\src\ide\words                       \ Dictionary visibility
INCLUDE %SwiftForth\src\ide\win32\xref                  \ Cross reference support
INCLUDE %SwiftForth\src\ide\xref                        \ Cross reference utility
INCLUDE %SwiftForth\src\ide\printf                      \ String output ala printf
INCLUDE %SwiftForth\src\ide\win32\imports               \ Import functions from external libraries
INCLUDE %SwiftForth\src\ide\win32\winconstants          \ Common windows constants
INCLUDE %SwiftForth\src\ide\win32\dllfunctions          \ Windows API calls
INCLUDE %SwiftForth\src\ide\win32\callback              \ Windows callback handler
INCLUDE %SwiftForth\src\ide\win32\exception             \ Exception handler context

INCLUDE %SwiftForth\src\ide\win32\bmp                   \ Primitive image display class
INCLUDE %SwiftForth\src\ide\win32\registry              \ Read and write windows registry
INCLUDE %SwiftForth\src\ide\win32\resources             \ Internally allocated resources, MI_xxx
INCLUDE %SwiftForth\src\ide\win32\configuration         \ System configuration kept in registry
INCLUDE %SwiftForth\src\ide\win32\colors                \ Use colors in the console

INCLUDE %SwiftForth\src\ide\win32\winstructures         \ Windows data structures
INCLUDE %SwiftForth\src\ide\win32\tasking               \ Multi-threaded multitasking
INCLUDE %SwiftForth\src\ide\tasking                     \ Common multitasking
INCLUDE %SwiftForth\src\ide\win32\control

INCLUDE %SwiftForth\src\ide\win32\winmgmt               \ Window management functions

INCLUDE %SwiftForth\src\ide\win32\winmaker              \ class interface for windows
INCLUDE %SwiftForth\src\ide\win32\canvas                \
INCLUDE %SwiftForth\src\ide\win32\file-ext              \ File tools

\ --------------------------------------------------------------------
\ Resource compilers

INCLUDE %SwiftForth\src\ide\win32\dialogs               \ Simple dialog compiler
INCLUDE %SwiftForth\src\ide\win32\dialogcontrols        \ Windows standard dialog controls
INCLUDE %SwiftForth\src\ide\win32\menucomp              \ Simple menu compiler

\ --------------------------------------------------------------------
\ These files need to be revisited

INCLUDE %SwiftForth\src\ide\win32\directory             \ Generate directory listings
INCLUDE %SwiftForth\src\ide\win32\shell                 \ Shell interface; run programs etc
INCLUDE %SwiftForth\src\ide\win32\help                  \ Windows help system
INCLUDE %SwiftForth\src\ide\win32\requires              \ Optional package loading in LIB\


\ --------------------------------------------------------------------
\ These files are candidates for replacement by class-oriented things

INCLUDE %SwiftForth\src\ide\win32\notepad               \ Interface to windows notepad for editor
INCLUDE %SwiftForth\src\ide\win32\editor                \ Interface to arbitrary external editor
INCLUDE %SwiftForth\src\ide\win32\ofn                   \ Open- and save- filename dialogs

\ ----------------------------------------------------------------------
\ build the gui

INCLUDE %SwiftForth\src\ide\win32\tty\tty               \ Embedded tty window
INCLUDE %SwiftForth\src\ide\win32\console-gui           \ Console GUI "debug window" interface to tty

INCLUDE %SwiftForth\src\ide\win32\menu                  \ Menu for console
INCLUDE %SwiftForth\src\ide\win32\winclass              \ Primitive window class
INCLUDE %SwiftForth\src\ide\win32\status                \ Primitive status class
INCLUDE %SwiftForth\src\ide\win32\toolbar               \ Primitive toolbar class
INCLUDE %SwiftForth\src\ide\win32\frame                 \ SwiftForth's console as a window
INCLUDE %SwiftForth\src\ide\win32\commands              \ Process menu and toolbar commands

\ --------------------------------------------------------------------

INCLUDE %SwiftForth\src\ide\win32\browse
INCLUDE %SwiftForth\src\ide\win32\projects
INCLUDE %SwiftForth\src\ide\win32\counter               \ Elapsed time measurements
INCLUDE %SwiftForth\src\ide\win32\pkcolor               \ Choose system color dialog
INCLUDE %SwiftForth\src\ide\win32\colorize              \ Color indicators of word type in WORDS
INCLUDE %SwiftForth\src\ide\win32\run                   \ Run external files
INCLUDE %SwiftForth\src\ide\win32\editline              \ Supercharge ACCEPT; history and command completion
INCLUDE %SwiftForth\src\ide\win32\prefs                 \ Preferences dialog
INCLUDE %SwiftForth\src\ide\win32\fonts                 \ Font management for console
INCLUDE %SwiftForth\src\ide\win32\options               \ Optional packages; load only once
INCLUDE %SwiftForth\src\ide\win32\about                 \ Swiftforth's about box
INCLUDE %SwiftForth\src\ide\win32\pickeditor            \ Dialog for choosing an editor
INCLUDE %SwiftForth\src\ide\verbose                     \ Monitor progress during include
INCLUDE %SwiftForth\src\ide\win32\monconfig             \ Verbose configuration dialog
INCLUDE %SwiftForth\src\ide\win32\dragdrop              \ Drag and drop files onto swiftforth
INCLUDE %SwiftForth\src\ide\win32\popwords              \ Right-button popup word extensions
INCLUDE %SwiftForth\src\ide\win32\popup                 \ Manage the right-button popup menu
INCLUDE %SwiftForth\src\ide\win32\memtools              \ Memory and variable watch windows
INCLUDE %SwiftForth\src\ide\win32\wordbrowser           \ Dictionary browsing
INCLUDE %SwiftForth\src\ide\win32\commandhistory        \ Command history as an editable window
INCLUDE %SwiftForth\src\ide\envq                        \ ANS environment queries
INCLUDE %SwiftForth\src\ide\win32\calendar              \ PolyForth time and date functions
INCLUDE %SwiftForth\src\ide\win32\throws                \ Optionally display errors in a dialog
INCLUDE %SwiftForth\src\ide\win32\warnings              \ Configure warning levels
INCLUDE %SwiftForth\src\ide\win32\printerior            \ Printer throw codes
INCLUDE %SwiftForth\src\ide\win32\richedit              \ Rich Edit control
INCLUDE %SwiftForth\src\ide\win32\preview               \ Print preview
INCLUDE %SwiftForth\src\ide\win32\printer               \ Printer personality
INCLUDE %SwiftForth\src\ide\win32\printing              \ Extend the file menu to include printing

{ --------------------------------------------------------------------
Wrap up system for turnkey save
-------------------------------------------------------------------- }

INCLUDE %SwiftForth\src\ide\win32\exports               \ Exports for building DLLs
INCLUDE %SwiftForth\src\ide\win32\save                  \ Save turnkey image
INCLUDE %SwiftForth\src\ide\win32\startup               \ Program starup
-? : HI ( ---)   ." Already loaded" ;

ONLY FORTH DEFINITIONS  GILD

{ --------------------------------------------------------------------
Alert to redefines
-------------------------------------------------------------------- }

OBSCURED @ [IF]

BRIGHT
CR OBSCURED ? .( definitions were hidden, no program saved.)
NORMAL
QUIT

[THEN]
