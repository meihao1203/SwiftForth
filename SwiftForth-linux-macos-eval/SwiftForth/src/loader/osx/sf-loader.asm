# SwiftForth OS X loader
# Copyright 2010  FORTH, Inc.

        .text
        .globl start                    # main entry point
start:
        call start1

api_table:                              # system calls resolved by dyld
        jmp _exit
        jmp _dlopen
        jmp _dlclose
        jmp _dlsym
        jmp _dlerror
        jmp __NSGetExecutablePath

start1:
        pop %eax                        # address of api_offsets
        mov $(forth-api_table),%edi     # offset from api_table to start of Forth image
        add %eax,%edi                   # address of SwiftForth image in memory (passed in EDI)
        mov %eax,4(%edi)                # store api_offsets table address at SwiftForth's ORIGIN CELL+ for use by /PE-IMPORTS
        mov (%edi),%ecx                 # entry point offset from image ORIGIN
        add %edi,%ecx                   # calculate entry point
        jmp *%ecx

        .align 4
        .data

forth:  .ascii "FORTHIMG"               # signature for sanity check by xcomp and turnkey compiler
