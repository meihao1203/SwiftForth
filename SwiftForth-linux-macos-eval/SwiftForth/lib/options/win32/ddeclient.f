{ ====================================================================
DDE client

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL DDECLIENT Simple DDE Client interface

LIBRARY USER32

FUNCTION: DdeAbandonTransaction ( idInst hConv idTransaction -- b )
FUNCTION: DdeAccessData ( hData pcbDataSize -- c-addr )
FUNCTION: DdeAddData ( hData pSrc cb cbOff -- h )
FUNCTION: DdeClientTransaction ( pData cbData hConv hszItem wFmt wType dwTimeout pdwResult -- h )
FUNCTION: DdeCmpStringHandles ( hsz1 hsz2 -- n )
FUNCTION: DdeConnect ( idInst hszService hszTopic pCC -- h )
FUNCTION: DdeConnectList ( idInst hszService hszTopic hConvList pCC -- h )
FUNCTION: DdeCreateDataHandle ( idInst pSrc cb cbOff hszItem wFmt afCmd -- h )
FUNCTION: DdeCreateStringHandle ( idInst psz iCodePage -- h )
FUNCTION: DdeDisconnect ( hConv -- b )
FUNCTION: DdeDisconnectList ( hConvList -- b )
FUNCTION: DdeEnableCallback ( idInst hConv wCmd -- b )
FUNCTION: DdeFreeDataHandle ( hData -- b )
FUNCTION: DdeFreeStringHandle ( idInst hsz -- b )
FUNCTION: DdeGetData ( hData pDst cbMax cbOff -- n )
FUNCTION: DdeGetLastError ( idInst -- u )
FUNCTION: DdeImpersonateClient ( hConv -- b )
FUNCTION: DdeInitialize ( pidInst pfnCallback afCmd ulRes -- u )
FUNCTION: DdeKeepStringHandle ( idInst hsz -- b )
FUNCTION: DdeNameService ( idInst hsz1 hsz2 afCmd -- b )
FUNCTION: DdePostAdvise ( idInst hszTopic hszItem -- b )
FUNCTION: DdeQueryConvInfo ( Conv idTransaction pConvInfo -- u )
FUNCTION: DdeQueryNextServer ( hConvList hConvPrev -- u )
FUNCTION: DdeQueryString ( idInst hsz psz cchMax iCodePage -- u )
FUNCTION: DdeReconnect ( hConv -- h )
FUNCTION: DdeSetUserHandle ( hConv id _PTR hUser -- b )
FUNCTION: DdeUnaccessData ( hData -- b )
FUNCTION: DdeUninitialize ( idInst -- b )

{ --------------------------------------------------------------------
Extend the asciiz string wordset
-------------------------------------------------------------------- }

: ZSTRING ( addr -- )
   0 WORD DUP C@ IF COUNT ROT ZPLACE ELSE DROP OFF THEN ;

: ZTELL ( zaddr -- )
   CR ZCOUNT BOUNDS ?DO
      I C@ DUP 9 = IF DROP BL THEN  EMIT
   LOOP ;

{ --------------------------------------------------------------------
Extend the error message handler for DDE
-------------------------------------------------------------------- }

[+SWITCH (THROW)
   1000 RUN: S" No server specified" ;
   1001 RUN: S" No topic specified" ;
   1002 RUN: S" No item specified" ;
   1003 RUN: S" DDE already initialized" ;
   1004 RUN: S" DDE initialization failed" ;
   1005 RUN: S" Conversation not established" ;
SWITCH]

{ --------------------------------------------------------------------
Define data structures for the DDE conversation.

_SERVER _TOPIC and _ITEM are asciiz strings for the DDE command.

SERVER TOPIC and ITEM parse strings into the buffers.

?READY checks for all three strings and for a previous unclosed
   dde session.
-------------------------------------------------------------------- }

0 VALUE DDEINST
0 VALUE HSERVICE
0 VALUE HTOPIC
0 VALUE HITEM
0 VALUE HDAT
0 VALUE CONV

CREATE _SERVER   256 ALLOT
CREATE _TOPIC    256 ALLOT
CREATE _ITEM     256 ALLOT

: SERVER  _SERVER ZSTRING ;
: TOPIC   _TOPIC  ZSTRING ;
: ITEM    _ITEM   ZSTRING ;

: ?READY ( -- )
   _SERVER C@ 0= 1000 ?THROW   _TOPIC C@ 0= 1001 ?THROW
   _ITEM C@ 0= 1002 ?THROW     DDEINST 0<> 1003 ?THROW ;

{ --------------------------------------------------------------------
DDE primitives.

DDE-END terminates a conversation by deleting all handles and
   uninitializing the dde instance.

DDE-INIT checks for all necessary data and opens the conversation.
   It will throw 1005 if it can't begin the conversation, which
   normally means that the server isn't running or doesn't recognize
   the topic.

DDE-REQ asks the server a question and returns the address of it's
   asciiz response (at PAD) regarding the item.

DDE-SEND pokes the specified string into the server's item.
-------------------------------------------------------------------- }

: DDE-END ( -- )
   DDEINST HITEM    DdeFreeStringHandle DROP
   DDEINST HSERVICE DdeFreeStringHandle DROP
   DDEINST HTOPIC   DdeFreeStringHandle DROP
   DDEINST DdeUninitialize DROP
   0 TO DDEINST ;

: DDE-INIT ( -- )
   ?READY
   ['] DDEINST >BODY 0 APPCMD_CLIENTONLY 0 DdeInitialize 1004 ?THROW
   DDEINST _SERVER CP_WINANSI DdeCreateStringHandle TO HSERVICE
   DDEINST _TOPIC  CP_WINANSI DdeCreateStringHandle TO HTOPIC
   DDEINST _ITEM   CP_WINANSI DdeCreateStringHandle TO HITEM
   DDEINST HSERVICE HTOPIC 0 DdeConnect DUP TO CONV ?EXIT
   DDE-END 1005 THROW ;

: DDE-REQ ( -- zaddr )
   0 0 CONV HITEM CF_TEXT XTYP_REQUEST 5000 NULL DdeClientTransaction TO HDAT
   HDAT PAD 4096 0 DdeGetData DROP
   HDAT DdeFreeDataHandle DROP
   PAD ;

: DDE-SEND ( addr n -- )
   ( a n) CONV HITEM CF_TEXT XTYP_POKE 5000 0 DdeClientTransaction
   DdeFreeDataHandle DROP ;

{ --------------------------------------------------------------------
The user interface for DDE

TELL sends a string to an item on server and
ASK gets an item from the server.

For example:
SERVER PROGMAN
TOPIC PROGMAN
ASK GROUPS

-------------------------------------------------------------------- }

: TELL ( addr n -- )
   ITEM  DDE-INIT DDE-SEND DDE-END ;

: ASK
   ITEM  DDE-INIT DDE-REQ ( zaddr)  DDE-END  ZTELL ;

{ --------------------------------------------------------------------
\ A set of sample conversations with the program manager and EXCEL

SERVER PROGMAN
TOPIC PROGMAN

ASK GROUPS

ASK ACCESSORIES

\ This conversation assumes that EXCEL is running.
\ If not, you will get a 1005 message.
\ Excel file TEST.XLS must exist in current path.

SERVER EXCEL
TOPIC TEST.XLS

ASK R1C1
ASK R1C2

S\" Rick lives here\n" TELL R1C2
ASK R1C2

TOPIC SYSTEM

ASK SYSITEMS
ASK FORMATS
ASK PROTOCOLS

-------------------------------------------------------------------- }
