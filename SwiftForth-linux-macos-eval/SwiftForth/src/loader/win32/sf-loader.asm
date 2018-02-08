; SwiftForth kernel loader

format PE console 4.0
stack 0x100000,0x10000
entry main

include '\fasm\include\win32a.inc'
include '\fasm\include\macro\import32.inc'

; ----------------------------------------------------------------------

section '.text' code readable executable

; The SwiftForth image has the offset to its entry point in the first cell.

main:   call main1

api_offsets:
        dd ExitProcess - api_offsets
        dd LoadLibrary - api_offsets
        dd GetProcAddress - api_offsets
        dd GetModuleHandle - api_offsets
        dd MessageBox - api_offsets

forth_offset = forth - api_offsets

; only use eax, ecx, edx here in case this is a dll entry point

main1:
        pop eax                 ; address of api_offsets
        mov edx,forth_offset    ; SwiftForth image base offset
        add edx,eax             ; current address of SwiftForth image in memory
        mov [edx+4],eax         ; store api_offsets table address at SwiftForth's ORIGIN CELL+ for use by /PE-IMPORTS
        mov ecx,[edx]           ; entry point offset from image ORIGIN
        add ecx,edx             ; calculate entry point
        jmp ecx

; ----------------------------------------------------------------------

section '.rdata' import data readable writeable

library kernel,'KERNEL32.DLL',\
        user,'USER32.DLL'

import kernel,\
        ExitProcess,      'ExitProcess',\
        LoadLibrary,      'LoadLibraryA',\
        GetProcAddress,   'GetProcAddress',\
        GetModuleHandle,  'GetModuleHandleA'

import user,\
        MessageBox,'MessageBoxA'

; ----------------------------------------------------------------------

section '.rsrc' resource data readable

  ; resource directory

  directory  RT_ICON,icons,\
        RT_GROUP_ICON,group_icons

  ; resource subdirectories

  resource group_icons,\
	   101,LANG_NEUTRAL,main_icon

; IMPORTANT: Resource 101 is used in frame.f for the SwiftForth Debug Window icon!

  resource icons,\
	   1,LANG_NEUTRAL,main_icon_data

  icon main_icon,main_icon_data,'sfk.ico'

; ----------------------------------------------------------------------

section '.data' data readable writeable executable

forth:
        times 0x4000000 db ?
