{ ====================================================================
Extend SwiftForth

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

This is the file loaded by the HI command to extend the SwiftForth
environment.
==================================================================== }

\ --------------------------------------------------------------------
\ Required extensions

INCLUDE %SwiftForth/src/ide/errmessages                 \ The basis for error handling
INCLUDE %SwiftForth/src/ide/encapsulate                 \ Simple vocabulary management
INCLUDE %SwiftForth/src/ide/asm80x86                    \ The opcode assembler
INCLUDE %SwiftForth/src/ide/assembler                   \ The 80x86 assembler
INCLUDE %SwiftForth/src/ide/optimizer                   \ Optimizing compiler
INCLUDE %SwiftForth/src/ide/inlines                     \ Inline expansions of common phrases
INCLUDE %SwiftForth/src/ide/patterns                    \ Patterns of xts to be optimized
INCLUDE %SwiftForth/src/ide/swoopopt                    \ Optimization for swoop

/OPTIMIZER

\ --------------------------------------------------------------------
\ Extensions

INCLUDE %SwiftForth/src/ide/preamble                    \ Common support
INCLUDE %SwiftForth/src/ide/tools                       \ Programmer tools
INCLUDE %SwiftForth/src/ide/prune                       \ Dictionary management
INCLUDE %SwiftForth/src/ide/aswoop                      \ Object oriented programming
INCLUDE %SwiftForth/src/ide/localvariables              \ Variables and objects on the return stack
INCLUDE %SwiftForth/src/ide/buffio                      \ Buffered io personality
INCLUDE %SwiftForth/src/ide/decode                      \ Disassembler/decompiler
INCLUDE %SwiftForth/src/ide/strings                     \ Extended string functions
INCLUDE %SwiftForth/src/ide/values                      \ Value OOP extension
INCLUDE %SwiftForth/src/ide/fileviewer                  \ View lines of a file
INCLUDE %SwiftForth/src/ide/locate                      \ Locate source code
INCLUDE %SwiftForth/src/ide/vocabularies                \ Vocabularies, wordlist management
INCLUDE %SwiftForth/src/ide/ul/linux/exception          \ Signal display registers
INCLUDE %SwiftForth/src/ide/ul/exception                \ Signal display
INCLUDE %SwiftForth/src/ide/traverse                    \ Traverse wordlists
INCLUDE %SwiftForth/src/ide/words                       \ Dictionary visibility
INCLUDE %SwiftForth/src/ide/ul/xref                     \ Cross reference support
INCLUDE %SwiftForth/src/ide/xref                        \ Cross reference utility
INCLUDE %SwiftForth/src/ide/ul/imports                  \ Import functions from external libraries
INCLUDE %SwiftForth/src/ide/ul/callback                 \ Callback wrapper
INCLUDE %SwiftForth/src/ide/ul/linux/sigcont            \ SIGCONT handler

LIBRARY libc.so.6
INCLUDE %SwiftForth/src/ide/ul/directory                \ Directory operators

INCLUDE %SwiftForth/src/ide/verbose                     \ Monitor progress during include

LIBRARY librt.so.1
INCLUDE %SwiftForth/src/ide/ul/linux/timer              \ System timer
INCLUDE %SwiftForth/src/ide/ul/timer                    \ Timing functions

LIBRARY libc.so.6
INCLUDE %SwiftForth/src/ide/ul/linux/timedate           \ System time/date
INCLUDE %SwiftForth/src/ide/ul/calendar                 \ Date and time
INCLUDE %SwiftForth/src/ide/ul/keymap                   \ Extended key code constants
INCLUDE %SwiftForth/src/ide/ul/keydecode                \ Extended key decoding
INCLUDE %SwiftForth/src/ide/ul/editline                 \ Edited line input

LIBRARY libc.so.6
INCLUDE %SwiftForth/src/ide/ul/shell                    \ Shell interface

INCLUDE %SwiftForth/src/ide/ul/editor                   \ External editor interface
INCLUDE %SwiftForth/src/ide/ul/options                  \ Optional packages; load only once
INCLUDE %SwiftForth/src/ide/ul/linux/requires           \ Load lib source
INCLUDE %SwiftForth/src/ide/envq                        \ ANS environment queries

LIBRARY libpthread.so.0
INCLUDE %SwiftForth/src/ide/ul/tasking                  \ Multi-threaded multitasking
INCLUDE %SwiftForth/src/ide/tasking                     \ Common multitasking support

INCLUDE %SwiftForth/src/ide/ul/linux/save               \ Save turnkey image

{ --------------------------------------------------------------------
Wrap up system for turnkey save
-------------------------------------------------------------------- }

INCLUDE %SwiftForth/src/ide/ul/startup
-? : HI ( -- )   ." Already loaded" ;

ONLY FORTH DEFINITIONS  GILD

{ --------------------------------------------------------------------
Alert to redefines
-------------------------------------------------------------------- }

OBSCURED @ [IF]

BRIGHT
CR OBSCURED ? .( definitions were hidden, no program saved.)
NORMAL
ABORT

[THEN]
