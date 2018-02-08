; SwiftForth Linux loader
; Copyright 2010  FORTH, Inc.


format ELF executable 3         ; 3=Linux
entry start

include 'import32.inc'

interpreter '/lib/ld-linux.so.2'
needed 'libdl.so.2'
import dlopen,dlsym,dlclose,dlerror

; ----------------------------------------------------------------------

segment readable executable

start:
        call start1

api_offsets:
        dd dlopen - api_offsets
        dd dlclose - api_offsets
        dd dlsym - api_offsets
        dd dlerror - api_offsets

forth_offset = forth - api_offsets

start1:
        pop eax                 ; address of api_offsets
        mov edi,forth_offset    ; SwiftForth image base offset
        add edi,eax             ; current address of SwiftForth image in memory
        mov [edi+4],eax         ; store api_offsets address at SwiftForth's ORIGIN CELL+ for use by /HEADER-IMPORTS
        mov ecx,[edi]           ; entry point offset from image ORIGIN
        add ecx,edi             ; calculate entry point
        jmp ecx                 ; SwiftForth image has offset to its entry point in its first cell

; ----------------------------------------------------------------------

segment readable writeable executable

forth_seg:
        align 16

forth:  db 'FORTHIMG'
        rb (0x4444-($-forth_seg))
