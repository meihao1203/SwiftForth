{ ====================================================================
bmpsoko.f
Read a bmp and use it as multiple images

Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

{ --------------------------------------------------------------------
Device Context Handling
-------------------------------------------------------------------- }

32 VALUE SQ
 6 CONSTANT #SPRITES

0 CONSTANT SPRITE(SOKO)
1 CONSTANT SPRITE(WALL)
2 CONSTANT SPRITE(ROCK)
3 CONSTANT SPRITE(GOLD)
4 CONSTANT SPRITE(GOAL)
5 CONSTANT SPRITE(TILE)

SQ #SPRITES * VALUE BMPWIDE
SQ            VALUE BMPHIGH

0 VALUE hdcSprite
0 VALUE hSpriteBitmap
0 VALUE hdcSpriteMem

0 VALUE hdcDRAW

S" SOKOBIG.BMP" BMP BIG
S" SOKOBAN.BMP" BMP SMALL

DEFER SPRITES   ' BIG IS SPRITES

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: CreateSpriteDC (  --  )
   hSpriteBitmap IF hSpriteBitmap DeleteObject DROP THEN
   HWND GetDC TO hdcSprite
   hdcSprite CreateCompatibleDC TO hdcSpriteMem
   hdcSprite BMPWIDE BMPHIGH CreateCompatibleBitmap TO hSpriteBitmap
   HWND hdcSprite ReleaseDC DROP
   hdcSpriteMem hSpriteBitmap SelectObject DROP ;

: InitSpriteDC (  --  )
   [OBJECTS BITMAP MAKES BM OBJECTS]
   SPRITES hdcSpriteMem 0 0 BM DRAW ;

: DeleteSpriteDC (  --  )
   hdcSpriteMem DeleteDC DROP
   hSpriteBitmap DeleteObject DROP ;

: /SPRITES
   CREATESPRITEDC INITSPRITEDC
   HWND GetDC TO hdcDRAW ;

: SPRITES/
   DELETESPRITEDC ;

: .SPRITE ( Sprite# x y --  )   \ --- Display Sprite
   rot >r >r >r
   hdcDRAW                        \ Dest DC
   r> r> SQ DUP                   \ Dest x y w h
   hdcSpriteMem                   \ Source DC
   r> SQ * 0                      \ Source x y
   SRCCOPY                        \ blit mode
   BitBlt drop ;

: ZOOM ( flag -- )              \ true is big
   SPRITES/
   IF   ['] BIG 32
   ELSE ['] SMALL 20 THEN  TO SQ  IS SPRITES
   SQ #SPRITES * TO BMPWIDE
   SQ TO BMPHIGH
   /SPRITES ;

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: OBJ>SPRITE ( obj -- sprite )
   CASE
      SOKO OF  SPRITE(SOKO)  ENDOF
      ROCK OF  SPRITE(ROCK)  ENDOF
      GOAL OF  SPRITE(GOAL)  ENDOF
      WALL OF  SPRITE(WALL)  ENDOF
      TILE OF  SPRITE(TILE)  ENDOF
   127 AND
      ROCK OF  SPRITE(GOLD)  ENDOF
      SOKO OF  SPRITE(SOKO)  ENDOF
       DUP OF  SPRITE(TILE)  ENDOF
   ENDCASE ;

: SPRITE.OBJECT ( sprite x y )
   ROT OBJ>SPRITE ROT SQ * ROT SQ * .SPRITE ;

' SPRITE.OBJECT IS .OBJECT

: PLAY-BMP
   1 ZOOM 1 GAME ;



