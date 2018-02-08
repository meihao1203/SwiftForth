{ ====================================================================
Configuration saving in the system registry

Copyright 2001  FORTH, Inc.
Rick VanNorman

WARNING: Beware saving an xt or address in the system registry! If you
recompile and try to restore and run, the xt or address might no
longer be valid. Provide a validation and default for any xt behavior
you need to save!
==================================================================== }

{ --------------------------------------------------------------------
Configs wordlist

The registry functions require a word defined in the CONFIG wordlist
that returns an address and count to be written or read in the
registry.

CONFIG: defines a colon definition in the CONFIG list.
LOCALCONFIG: defines a colon definition in the LOCALCONFIG list.
------------------------------------------------------------------------ }

PACKAGE CONFIGURATION-MANAGER

1 STRANDS CONSTANT CONFIGS
1 STRANDS CONSTANT LOCALCONFIGS

PUBLIC

: CONFIG: ( -- )
   GET-CURRENT >R  CONFIGS SET-CURRENT  :  R> SET-CURRENT ;

: LOCALCONFIG: ( -- )
   GET-CURRENT >R  LOCALCONFIGS SET-CURRENT  :  R> SET-CURRENT ;

PRIVATE

{ ------------------------------------------------------------------------
Process config chain

Configuration management via registry entries is accomplished by an
execution chain.

(CONFIG) traverses the chain, executing xt for each node in the chain.
Each configuration item defined by CONFIG: must return an address and
length.  This buffer is read and restored from the key named by
CONFIG: on start and exit of SwiftForth.

SAVE-CONFIGURATION writes the configuration chain to the registry.
RESTORE-CONFIGURATION reads the configuration from the registry.
------------------------------------------------------------------------ }

: GETLOCALREGKEY ( -- hKey )   R-BUF
   PRODUCT-REGISTRY ZCOUNT  MAX_PATH OVER R@ + 2- GetCurrentDirectory
   OVER R@ + 1+ SWAP  BOUNDS DO  I C@ [CHAR] \ = IF  [CHAR] $ I C!  THEN  LOOP
   R@ SWAP CMOVE  0 SP@ HKEY_CURRENT_USER R> ROT RegCreateKey DROP ;

: (CONFIG) ( hKey wid xt -- )
   >R  +ORIGIN CELL+
   BEGIN  @REL ?DUP WHILE  2DUP L>NAME R@ EXECUTE  REPEAT
   RegCloseKey  R> 2DROP ;

: CFGDUMP ( hKey nfa -- )       \ hKey not used - may be null
   CR DUP COUNT TYPE NAME> EXECUTE DUMP DROP ;

: CFGREAD ( hKey nfa -- )
   DUP NAME> EXECUTE  2SWAP 1+ SWAP READ-REG 2DROP ;

: CFGWRITE ( hKey nfa -- )
   DUP NAME> EXECUTE  2SWAP 1+ SWAP WRITE-REG DROP ;

PUBLIC

: .CONFIGURATION ( -- )
   CR ." ***GLOBAL***"  0 CONFIGS ['] CFGDUMP (CONFIG)
   CR ." ***LOCAL***"  0 LOCALCONFIGS ['] CFGDUMP (CONFIG) ;

: RESTORE-CONFIGURATION ( -- )
   GETREGKEY CONFIGS ['] CFGREAD (CONFIG)
   GETLOCALREGKEY LOCALCONFIGS ['] CFGREAD (CONFIG) ;

: SAVE-CONFIGURATION ( -- )
   GETREGKEY CONFIGS ['] CFGWRITE (CONFIG)
   GETLOCALREGKEY LOCALCONFIGS ['] CFGWRITE (CONFIG) ;

:ONENVEXIT ( -- )   SAVE-CONFIGURATION ;

CONFIG: WARNING ( -- addr n )   WARNING 2 CELLS ;
CONFIG: SCROLLMODE ( -- addr u )   SCROLLMODE CELL ;

END-PACKAGE

{ ---------------------------------------------------------------------
Configuration file access

CONFIGFILE holds the path name to the configuration file.
/CONFIGFILE sets the path and file name in CONFIGFILE.

@CONFIG takes the zaddr string of the key name and looks for it in
the [CONFIG] section of the config file.  If found, the key value
is placed into buffer at addr whose max length is u1.  Returns
actual length of string placed in buffer (not including the
trailing null).

!CONFIG takes key name zaddr1 and value zaddr2 and writes them to
the config file.
--------------------------------------------------------------------- }

FUNCTION: GetPrivateProfileString ( zsect zkey zdef dest size zfile -- n )
FUNCTION: WritePrivateProfileString ( zsect zkey zstr zfile -- bool )

MAX_PATH BUFFER: CONFIGFILE

: @CONFIG ( zsect zkey zvalue -- )
   MAX_PATH CELL+ R-ALLOC  2DUP 2>R MAX_PATH CONFIGFILE
   GetPrivateProfileString DROP  2R> ZCOUNT ROT ZPLACE ;

: !CONFIG ( zsect zkey zvalue -- )
   CONFIGFILE WritePrivateProfileString DROP ;

DEFER PARSE-CONFIG-FILE    0 IS PARSE-CONFIG-FILE

: /INCLUSION ( -- )   R-BUF  R@ OFF
   Z" STARTUP" Z" INCLUDE" R@  @CONFIG
   R@ C@ IF  R@ ZCOUNT FILENAME-FIXUP DROP INCLUDED  THEN  R> DROP ;

: ZEVAL ( z -- )   ZCOUNT EVALUATE ;

: /EVALUATIONS ( -- )  R-BUF  0 BEGIN  R@ OFF
      Z" EVAL" OVER Z(.) R@ @CONFIG  R@ C@ WHILE
      R@  SWAP >R  ['] ZEVAL CATCH IF DROP THEN  R> 1+
   REPEAT DROP R> DROP ;

: CONFIG-FILE ( addr len -- )   CONFIGFILE ZPLACE
   PARSE-CONFIG-FILE  /EVALUATIONS  /INCLUSION ;

: -P ( -- )   0 WORD COUNT
   OVER C@ [CHAR] " = IF  1 /STRING  THEN
   2DUP + 1- C@ [CHAR] " = +  CONFIG-FILE GILD ;

:ONSYSLOAD ( -- )   0 CONFIGFILE ! ;

: PRJFILE ( -- addr len )   \ no path info here
   CONFIGFILE C@ IF ( configfile specified?)
      CONFIGFILE ZCOUNT -PATH
   ELSE S" PROJECT.FI" THEN ;

DEFER HAS-PRJ ( zstr -- flag )

: HAS-NONEVAL-PRJ ( zstr -- flag )
   MAX_PATH R-ALLOC  >R  ZCOUNT R@ PLACE   S" \" R@ APPEND
   PRJFILE R@ APPEND
   R> COUNT FILE-STATUS NIP 0= ;

' HAS-NONEVAL-PRJ IS HAS-PRJ
