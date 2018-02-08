{ ====================================================================
(C) Copyright 1999 FORTH, Inc.   www.forth.com

polyFORTH block editor
======================================================================== }

OPTIONAL BLKEDIT A block editor for source code

REQUIRES blocks

ONLY FORTH ALSO DEFINITIONS

#USER
      CELL  +USER SCRATCHED
      CELL  +USER EXTENT    \ where to wrap lines, normally 64 or 1024
TO #USER

WORDLIST CONSTANT EDITOR-WORDLIST  EDITOR-WORDLIST (VOCABULARY) EDITOR

EDITOR ALSO DEFINITIONS

: CLEAN ( -- )   GET-XY  OVER 80 SWAP - SPACES  AT-XY ;

VARIABLE LOCATED      \ located keeps up with "text" that was located

DEFER BSHOW
DEFER .BLOCKLOCATION ( view -- )

{ ------------------------------------------------------------------------

CARET  returns the ASCII code for the editor string terminator.

#BLOCKS  returns the number of 1K blocks for the file
   mapped in the part pointed to by  'PART .
>ASHADOW  returns the absolute shadow block number in the other
   half of the source file containing absolute block number  u .
>SHADOW  does the same, but with relative block numbers.

(COPY)  re-labels a block as another without flushing it.
COPY  copies the contents of one block into another block.
+COPY  copies a block along with its shadow.
ACOPY  copies using unsigned, absolute block numbers.

------------------------------------------------------------------------ }

94 CONSTANT CARET

: >ASHADOW ( u - u')   MAPPED >PART DROP  #BLOCK @ -
   #BLOCKS 2/ SWAP OVER /MOD  1 XOR  ROT * +  #BLOCK @ + ;

: >SHADOW ( n - n')   ABSOLUTE >ASHADOW RELATIVE ;

: (COPY) ( s d)   SWAP BLOCK DROP  IDENTIFY  UPDATE ;
: COPY ( s d)   FLUSH (COPY) ;
: +COPY ( s d)   OVER >SHADOW  OVER >SHADOW  COPY (COPY) ;

: ACOPY ( us ud)   FLUSH SWAP ABLOCK DROP  AIDENTIFY
   UPDATE ;

{ ------------------------------------------------------------------------

This editor uses two string buffers, a "find" buffer ( #F ) and
   an "insert" buffer ( #I ).  Their use is described in
   Starting Forth.  In all cases where an editing word requires
   a string pattern, the string may be specified in one of two
   ways.  Either the pattern is supplied in the input stream
   immediately after the editing word itself, or the input
   stream is terminated immediately after the editing word.  If
   supplied, the pattern may be delimited by either a caret "^"
   or the end of the input stream.  The pattern is first copied
   to either the find or insert buffer before use.  If the
   pattern is not supplied, the current contents of the buffer
   connected to the word is used.

The words in this block are for low-level editor support.  They
   are not normally needed by the user, so are not documented
   here.  They are useful for writing editor extensions.

------------------------------------------------------------------------ }

80 CONSTANT #TB

: #I ( - a)   PAD #TB + ;       : #F ( - a)   PAD #TB 2* + ;

: REST ( n - n)   CHR @  OVER 1- AND - ;
: At ( - a n)   SCR @ ABLOCK  CHR @ +  64 REST ;
: AT0 ( - a n)   CHR @  -64 AND  CHR !  At ;
: SET ( - r c)   GET-XY SWAP  CHR @ 64 /MOD 1+ SWAP 2+ 1+ SWAP AT-XY ;
: -LINE   SET  At -TRAILING TYPE  CLEAN  SWAP AT-XY ;
: .LINE   SET  At MARK  SWAP AT-XY ;
: .EXT   GET-XY  58 0 AT-XY  ." Ext"  EXTENT @ 5 U.R  AT-XY ;
: +CHR ( n)   CHR @ +  1023 AND  CHR ! ;

: BODY   CHR @  1024 OVER -64 AND DO  I CHR !  -LINE
   64 +LOOP  CHR ! ;
: ?BODY ( n)   EXTENT @ 64 > IF  BODY  ELSE  DUP IF  -LINE
   THEN  THEN  +CHR  .LINE ;

{ ------------------------------------------------------------------------

!STRING  parses a string delimited by a caret.  The string is
   stored at  s  as a counted string, padded with blanks to a
   length of 80 bytes.  The  s'  returned is  s  plus one.
   If the input stream is empty, the buffer is unchanged.
EXTRACT  deletes  s#  bytes at the front of  d  length  d# .
INSERT  inserts  s  for  s#  at the front of  d  length  d# .
RETAIN  copies the current line into the insert buffer.
P  puts insert buffer text in place of the current line.
X  moves the current line to the insert buffer, moving lower
   lines up, with blank fill from the bottom.
U  inserts text under the current line, moving lower lines down
   and dropping Line 15 off the bottom.
K  swaps the insert and find buffers.
M  copies the line at the block number and line number given
   on the stack, to below the current line.  The next line is
   selected both on the stack and in the current block.

------------------------------------------------------------------------ }

: !STRING ( s - s')   CARET WORD C@ IF  DUP #TB BLANK
      HERE  2DUP C@ 1+ CMOVE  THEN  1+ ;
: EXTRACT ( d d# s#)   OVER MIN  DUP >R  -  2DUP OVER R@ +
   ROT ROT CMOVE  + R> BLANK  UPDATE ;
: INSERT ( s s# d d#)   ROT  OVER MIN  DUP >R  -
   OVER DUP R@ +  ROT CMOVE>  R> CMOVE  UPDATE ;

: RETAIN   AT0 #I  2DUP C!  1+ SWAP CMOVE ;
: P   -LINE  #I !STRING  AT0 CMOVE  UPDATE .LINE ;
: X   RETAIN  AT0  1024 REST  SWAP EXTRACT  BODY .LINE ;
: U   -LINE  #I !STRING  64 +CHR  AT0 SWAP  1024 REST  INSERT
   BODY .LINE ;
: K   #I PAD #TB 2* CMOVE  PAD #F #TB CMOVE ;
: M ( b n - b n+1)   2DUP  SCR 2@ 2>R  64 *
   SWAP ABSOLUTE SCR 2!  RETAIN  2R> SCR 2!  U  1+ ;

{ ------------------------------------------------------------------------

TILL  deletes all the text from the character pointer up to,
   and including, the find buffer.

I  inserts text at the character pointer and advances it.
E  deletes backwards from the character pointer, the number of
   characters in the find buffer.  It's good for deleting
   a piece of text which has been found by  F .
D  finds and deletes the first occurrence of a find string.
F  places the character pointer after the next occurrence of a
   find string.
R  replaces text just found by  F  with an insert string.

CLIP  limits the extent of editing changes to the current line.
WRAP  limits the extent only to the end of the current block.

------------------------------------------------------------------------ }

: -FOUND ( - a a' t)   #F !STRING DROP  At DROP
   DUP  1024 REST  #F COUNT  -MATCH ;
: SEARCH   -LINE  -FOUND IF  #F  HERE 65 CMOVE
      1 ABORT" none"  THEN  SWAP-  +CHR ;
: EXT ( - a n)   At DROP  EXTENT @ REST ;
: ADV ( n)   SCR @  + 0 MAX  SCR ! ;
: (E)   -LINE  #F C@  DUP NEGATE +CHR  EXT ROT EXTRACT  .LINE ;

: TILL   CHR @  SEARCH  CHR @ SWAP  DUP CHR !
   - 1023 AND  EXT ROT EXTRACT  0 ?BODY ;
: I   #I !STRING  #I C@ EXT INSERT  #I C@ ?BODY ;
: E   (E)  0 ?BODY ;
: D   SEARCH E ;
: F   SEARCH .LINE ;
: R   (E) I ;

: CLIP   64 EXTENT !  .EXT ;
: WRAP   1024 EXTENT !  .EXT ;

64 EXTENT !

{ ------------------------------------------------------------------------

Line 0 forces the next definitions into the  FORTH  vocabulary
   while including the  EDITOR  vocabulary in the search order.
(LIST)  displays a block, making it current, without showing
   the editing cursor.  'list  is for  .PART  patch.
LIST  displays a block as you see it now, making it current.
RE  returns the relative block number of the current block.
L  lists the current block and selects the  EDITOR .
T  makes the given line current and selects the  EDITOR .
N  lists the next block and makes it current.
B  lists the preceding block and makes it current.
O  lists the alternate block and makes it current.

Q  lists the current block's shadow block and makes it current.
WIPE  clears the current block to blanks.
FINISH  loads the current block beginning at the cursor.

------------------------------------------------------------------------ }

: (LIST) ( n)   PAGE  DUP .  2 SPACES
   16 0 DO  CR [ FORTH ] I 2 U.R  SPACE
      DUP BLOCK I 64 * +  64 -TRAILING
      [ EDITOR ] TYPE  LOOP ABSOLUTE >SCR !  ;

: RE ( - n)   SCR @ RELATIVE ;

: (EDIT) ( n)   (LIST)  0 +CHR .EXT  .LINE  EDITOR ;

: T ( n)   -LINE  15 AND  64 * CHR !  .EXT .LINE  EDITOR ;

: L   RE LIST ;

: N   1 ADV RE LIST ;
: B   -1 ADV RE LIST ;

: O   (SCR) 2@  SCR 2@ (SCR) 2!  SCR 2!  RE LIST ;

: Q   SCR @ >ASHADOW  SCR !  RE LIST ;
: WIPE   SCR @ ABLOCK 1024 BLANK  UPDATE  L ;

{ ------------------------------------------------------------------------

S  searches all blocks (starting at the current) until, but not
   including, the block whose number is on the stack.  The
   search pattern follows, or is the find buffer.  The
   terminating block number remains on the stack until no more
   patterns are found.

#BLANKS  calculates the number of spaces following the cursor.

A  deletes all spaces following the cursor thereby pulling
   the first word following, to the cursor position.

J  inserts spaces until the first word following the cursor is
   moved to the next line.  It will be indented the given number
   of spaces.

------------------------------------------------------------------------ }

: S ( n)
   >IN @  OVER ABSOLUTE  SCR 2@  ROT OVER ?DO
      ROT DUP >IN !  ROT ROT  -FOUND IF
         2DROP 1 ADV  0 CHR !
      ELSE  SWAP- +CHR  CHR @ 0= IF  1 ADV  THEN  DROP
         SCR 2@  L  LEAVE
      THEN
   LOOP
   SCR 2!  2DROP ;

: #BLANKS ( a n - a n #)
   2DUP BL SKIP NIP OVER SWAP - ;

: A   EXT  #BLANKS EXTRACT  0 ?BODY ;

: J ( n)
   EXTENT @ REST 65 < ABORT" Can't"  -LINE  EXT #BLANKS
   DUP 1024 REST = NOT AND  +CHR 2DROP  At ROT +  DUP >R
   1024 REST MIN  2DUP 2DUP +  1024 REST  ROT - CMOVE>
   BLANK  UPDATE  R> ?BODY ;

: PAGE   PAGE PREVIOUS ALSO ;

BLOCK-PARTS +ORDER

: BLOCK-LOCATION ( view -- nfa blk )
   $7FFFFFFF AND  DUP $3FF AND CHR !
   DUP   23 RSHIFT >FILENAME @ +ORIGIN
   SWAP  $007FFC00 AND  10 RSHIFT ;

: (.BLOCKLOCATION) ( view -- )
   BLOCK-LOCATION ." in block " . ." of " COUNT TYPE ;

: (BSHOW) ( view -- )   BLOCK-LOCATION SWAP
   COUNT (USING) >PART  #BLOCK @ + >SCR !  RE LIST
   >SCR CELL+ @ 64 /MOD 1+ SWAP 3 + SWAP AT-XY
   LOCATED @ COUNT MARK  0 17 AT-XY ;

BLOCK-PARTS -ORDER

{ --------------------------------------------------------------------
This section defines  CUT  ,  PASTE  and  YANK  block editor extensions.
   They work by creating a stack of text buffers above the two
   buffers used by the editor.

SCRATCHED  contains the # of bytes of text buffers contained
   in the stack.  It needs to be a user variable if this code
   is shared by multiple programmers.

SCRATCH  returns the address of the next available text buffer.

CRUMPLE  clears the stack of all text buffers.

LINES>  executes the remainder of the calling definition the
  given number of times.  It updates the screen only when done.

CUT  cuts and stacks the given number of lines.

PASTE  unstacks and pastes the given number of lines.  The
  current line and those below it are moved down.

YANK  copies and stacks the given number of lines.

TABS  displays a ruler above the current line that contains at
   least  n  even tabs positions, to be used as a template.

cut  ,  paste , yank  and  tabs  are lower case versions for
   convenience.


-------------------------------------------------------------------- }

ONLY FORTH ALSO DEFINITIONS

EDITOR DEFINITIONS

: SCRATCH ( - a)   PAD #TB 4 * +  SCRATCHED @ + ;

: CRUMPLE   0 SCRATCHED ! ;

: LINES> ( n)   -LINE  R>  SWAP 0 DO  DUP CALL  LOOP DROP
   BODY .LINE ;

: CUT ( n)   LINES>  RETAIN  AT0  1024 REST  SWAP EXTRACT
   #I SCRATCH #TB CMOVE  #TB SCRATCHED +! ;

: PASTE ( n)   LINES>  SCRATCHED @  #TB - 0 MAX  SCRATCHED !
   SCRATCH #I #TB CMOVE  #I 1+  AT0 SWAP  1024 REST  INSERT ;

: YANK ( n)   LINES>  RETAIN  64 +CHR  #I SCRATCH #TB CMOVE
   #TB SCRATCHED +! ;

: TABS ( n)   L  3  CHR @  64 /  AT-XY  64 SWAP /  64 0 DO
      [ FORTH ] I OVER MOD IF  ." -"  ELSE  ." V"  THEN
   LOOP  DROP  0 17 AT-XY ;    EDITOR

-? AKA CUT cut
-? AKA PASTE paste
-? AKA YANK yank
-? AKA TABS tabs

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

' (EDIT) IS LIST
' (.BLOCKLOCATION) IS .BLOCKLOCATION
' (BSHOW) IS BSHOW

ONLY FORTH ALSO DEFINITIONS

: T   [ EDITOR ] T ; FORTH

ONLY FORTH ALSO DEFINITIONS  

GILD

