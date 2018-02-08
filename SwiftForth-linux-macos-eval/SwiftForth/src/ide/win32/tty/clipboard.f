{ ==========================================================================
Clipboard access

Copyright (C) 2004  FORTH, Inc.  All rights reserved.

Memory allocated for use by the clipboard is "owned" by the system.
Do not free memory in use by the clipboard.

========================================================================== }

{ --------------------------------------------------------------------
Copy to clipboard

#MARKED returns the size of the marked area.

/COPY allocates memory for the copy operation based on current #MARKED
(plus extra for return characters).  Buffer memory pointer is stored
in 'COPY; handle is stored in HCOPY.

COPY/ posts data from the HCOPY handle to the clipboard.  The actual
size written to the clipboard memory is used to resize the memory
section before handing it off to the clipboard.

>CLIP writes a string to the copy buffer.
+CLIP appends a single character to the copy buffer.
CRLF>CLIP appends a CR LF sequence to the copy buffer.

The selected area lives between MARK-BEGIN and MARK-END, which are
virtual (not physical) addresses.

/SELECTION clears the selected area pointers.

>EOL returns the number of characters from the given virtual buffer
address to the end of that line.

COPY-TEXT copies all text from MARK-BEGIN thru MARK-END to the
clipboard buffer. No trailing blanks are copied; a CRLF is appended
to each line.  A null is added to the end when finished.

COPY-SELECTION copies the selected data to the clipboard and clears
the selection.
-------------------------------------------------------------------- }

: #MARKED ( -- n )
   MARK-END @ MARK-BEGIN @ - ;

: /COPY ( -- )
   HWND OpenClipboard DROP  EmptyClipboard DROP
   GMEM_MOVEABLE #MARKED GlobalAlloc
   DUP HCOPY !  GlobalLock DUP 'COPY 2! ;

: COPY/ ( -- )
   HCOPY @ GlobalUnlock DROP
   HCOPY @ 'COPY 2@ SWAP - GMEM_MOVEABLE GlobalReAlloc DROP
   CF_TEXT HCOPY @ SetClipboardData DROP
   CloseClipboard DROP ;

CODE PRINTABLE ( addr u -- )
   0 [EBP] ECX MOV   EBX EBX TEST   0= NOT IF
      32 # AL MOV   BEGIN
         AL 0 [ECX] CMP  U< IF  AL 0 [ECX] MOV  THEN
      ECX INC   EBX DEC   0= UNTIL   THEN
   4 [EBP] EBX MOV   8 # EBP ADD   RET   END-CODE

: >CLIP ( addr len -- )
   TUCK  'COPY @ SWAP CMOVE
   'COPY @ OVER PRINTABLE 'COPY +! ;

: +CLIP ( char -- )   'COPY @ C!  1 'COPY +! ;

: CRLF>CLIP ( -- )   13 +CLIP  10 +CLIP ;

: /SELECTION ( -- )
   0 MARK-BEGIN !  0 MARK-END ! 0 MARK-ANCHOR ! ;

: >EOL ( vaddr -- vaddr )   COLS / 1+ COLS * ;

: COPY-TEXT ( -- )
   MARK-BEGIN @  DUP MARK-END @ U< IF
      BEGIN  DUP >EOL DUP >R  MARK-END @ MIN
         OVER -  SWAP V>BUF SWAP -TRAILING >CLIP
         R>  DUP MARK-END @ U< WHILE
   CRLF>CLIP  REPEAT THEN  DROP  0 +CLIP ;

: COPY-SELECTION ( -- )
   /COPY  COPY-TEXT  COPY/ ;

{ --------------------------------------------------------------------
We also deal with words that might be marked.

GET-MARKED-WORD copies the marked word from the text buffer to the
word buffer.

GET-CURSOR-WORD returns the blank-delimited word under the cursor
to the word buffer.
-------------------------------------------------------------------- }

: GET-MARKED-WORD ( -- zstr )   WORD-BUF OFF
   #MARKED IF
      MARK-BEGIN @  DUP V>BUF  OVER >EOL  ROT -
      BL SKIP  2DUP  BL SCAN  NIP -  63 MIN  WORD-BUF ZPLACE
   THEN  WORD-BUF ;

: GET-CURSOR-WORD ( -- zstr )   RB-PRESS @
   BEGIN DUP VC@ BL <> WHILE 1- REPEAT 1+ DUP V>BUF SWAP
   BEGIN DUP VC@ BL <> WHILE 1+ REPEAT V>BUF OVER -
   63 MIN WORD-BUF  ZPLACE  WORD-BUF ;

{ --------------------------------------------------------------------
/PASTE terminates any ongoing PASTE operation.

PASTING initializes the state machine for the PASTE operation if
   the clipboard contents are CF_TEXT .

PASTEKEY returns a character from the paste buffer. Note that
   if the character returned is the last one, ie followed by
   a null, PASTEKEY will unvector itself before returning.

PASTEQ is true if the paste handle is non-zero.
-------------------------------------------------------------------- }

: /PASTE ( -- )   HPASTE @ ?DUP IF
      GlobalUnlock DROP
      CloseClipboard DROP
   THEN  HPASTE OFF  'PASTE OFF ;

: PASTING ( -- )
   /PASTE  HWND OpenClipboard IF
      CF_TEXT GetClipboardData ?DUP IF
         DUP HPASTE !  GlobalLock 'PASTE !
      THEN
   THEN ;

: PASTEKEY ( -- char )
   'PASTE @ IF
      'PASTE @ C@  DUP IF
         DUP 9 = IF DROP BL THEN
      'PASTE ++  EXIT THEN
      DROP  /PASTE
   THEN -1 ;

: PASTEQ ( -- flag )
   'PASTE @ 0<> ;

{ --------------------------------------------------------------------
REFRESH to invalidate the entire window but not redraw background
REFRESHBK to redraw background

-------------------------------------------------------------------- }

: REFRESH ( -- )   HWND 0 0 InvalidateRect DROP ;
: REFRESHBK ( -- )   HWND 0 -1 InvalidateRect DROP ;

: /MARKS ( -- )
   #MARKED IF   0 MARK-BEGIN !  0 MARK-END !  REFRESH  THEN ;

: TTY->CLIPBOARD ( -- )
   #MARKED IF COPY-SELECTION /MARKS THEN ;

: CLIPBOARD->TTY ( -- )
   PASTING ;

: CLEAR-MARKS ( -- )
   0 MARK-BEGIN !  0 MARK-END !  REFRESH ;

: MARK-ALL ( -- )
   0 TOP XY>V MARK-BEGIN !  X Y XY>V MARK-END !  REFRESH  ;
