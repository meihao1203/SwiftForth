{ ====================================================================
Blocks-to-text source conversion utility

Copyright (C) 2002-2003 FORTH, Inc.  All rights resrved.

This utility converts a block file (SRC) into a text file (TXT).
===================================================================== }

OPTIONAL SRC2TXT Converts block (screen) files to text files.
REQUIRES blocks

{ ---------------------------------------------------------------------
Tools

TXTFILE holds the fileid of the textfile being exported to.

BLANK-LINES holds count of blank lines.

BLOCK#S controls printing the block #.  See comments at end of file.

BLOCK-LINE returns line of a block, removing trailing spaces.

END-LINE close the line and reset blank line counter.

BLANK-LINE add a blank line if we haven't had any and increments the
blank line counter.
--------------------------------------------------------------------- }

VARIABLE TXTFILE
VARIABLE BLANK-LINES
VARIABLE BLOCK#S   BLOCK#S ON
VARIABLE BIAS
80 BUFFER: TXTLINE

: BLOCK-LINE ( b# l# -- addr u )   >R BLOCK R> 64 * + 64 -TRAILING ;

: END-LINE ( -- )   TXTLINE COUNT  0 TXTLINE C!  0 BLANK-LINES !
   TXTFILE @ WRITE-LINE THROW ;

: BLANK-LINE ( -- )
   BLANK-LINES @ 0= IF  0 TXTLINE C!  END-LINE  THEN  1 BLANK-LINES +! ;

{ ---------------------------------------------------------------------
Shadow block support

SHADOWS tells EXPORT if the current part has shadow blocks or not.
This is on by default.  SHADOWS OFF will treat the current part as all
source blocks with no shadows.  This is useful for porting code from
Forth systems that don't support shadow blocks.

>ASHADOW returns the absolute shadow block number in the other half of
>the source file containing absolute block number u.

>SHADOW does the same, but with relative block numbers.

WRITE-SHADOW writes the shadow block corresponding to source block n.
--------------------------------------------------------------------- }

VARIABLE SHADOWS   SHADOWS ON

: >ASHADOW ( u - u')   MAPPED >PART DROP  #BLOCK @ -
   #BLOCKS 2/ SWAP OVER /MOD  1 XOR  ROT * +  #BLOCK @ + ;

: >SHADOW ( n - n')   ABSOLUTE >ASHADOW RELATIVE ;

: WRITE-SHADOW ( n -- )
   >SHADOW  16 0 DO
      DUP I BLOCK-LINE ?DUP IF
         S" \ "  TXTLINE PLACE  TXTLINE APPEND  END-LINE
      ELSE  DROP  BLANK-LINES @ 0= IF  S" \" TXTLINE PLACE
      END-LINE  THEN  1 BLANK-LINES +!
   THEN  LOOP  DROP ;

{ ---------------------------------------------------------------------
EXPORTED exports the current part to the given textfile name.  Each
block is indicated by a comment line which includes its block number
(unless BLOCK#S are OFF).  The shadow block is output first (if
SHADOWS are ON), with each line made into a comment and the source
block follows.  Repetitive blank lines are removed, but each block is
seperated by 1 blank line.

EXPORT takes the textfile name from the input stream.
--------------------------------------------------------------------- }

: EXPORTED ( c-addr u -- )
   R/W CREATE-FILE THROW  TXTFILE !  1 BLANK-LINES !
   SHADOWS @ IF  0 >SHADOW  ELSE  #BLOCKS  THEN
   0 ?DO  BLANK-LINE  BLOCK#S @ IF
         S" \ *** BLOCK " TXTLINE PLACE
         I BIAS @ + (.) TXTLINE APPEND  END-LINE
      THEN
      SHADOWS @ IF  I WRITE-SHADOW  THEN
      16 0 DO  J I BLOCK-LINE
         ?DUP IF  TXTLINE PLACE  END-LINE  ELSE
      DROP  BLANK-LINE  THEN
   LOOP LOOP  TXTFILE @ CLOSE-FILE THROW ;

: EXPORT ( <name> -- )   BL WORD COUNT EXPORTED ;


BOLD ?(
BLOCKS-TO-TEXT SOURCE CONVERSION UTILITY

EXPORT <name> to convert the current PART into a text file with the
name that follows.

To convert a block file that doesn't have shadow blocks, type
SHADOWS OFF before EXPORT <name>.

By default,  "\ *** BLOCK n" is printed at the start of each block.
BLOCK#S OFF suppresses this behavior.

n BIAS ! sets an BIAS to the output block #.

) NORMAL

