{ ----------------------------------------------------------------------
Global variables for the TTY package
Local use only -- some will rename SwiftForth equivalents!
---------------------------------------------------------------------- }

2000
   ENUM TTY_FIRSTLINE
   ENUM TTY_NEXTLINE
   ENUM TTY_EMIT
   ENUM TTY_TYPE
   ENUM TTY_WRAP
   ENUM TTY_CR
   ENUM TTY_PAGE
   ENUM TTY_NEW
   ENUM TTY_EKEY
   ENUM TTY_EKEYQ
   ENUM TTY_KEYMODE
   ENUM TTY_PUSHTEXT
   ENUM TTY_BREAK
   ENUM TTY_SETXY
   ENUM TTY_GETXY
   ENUM TTY_GETSIZE
   ENUM TTY_COPYTEXT
   ENUM TTY_GETWORD
   ENUM TTY_SELECTALL
   ENUM TTY_SETFONT
   ENUM TTY_GETFONT
   ENUM TTY_RECORDER
   ENUM TTY_CARETMODE
   ENUM TTY_SETCARET
   ENUM TTY_SETFGCOLOR
   ENUM TTY_SETBKCOLOR
   ENUM TTY_USECOLOR
DROP

{ --------------------------------------------------------------------
32 attribute pairs allowed; foreground and background. The actual
tables are allocated in the virtual buffer space 'VBUF
-------------------------------------------------------------------- }

32 CONSTANT #COLORS

#COLORS CELLS CONSTANT |COLORMAP|
