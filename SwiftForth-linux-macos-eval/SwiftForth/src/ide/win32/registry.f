{ ====================================================================
Windows registry access

Copyright 2001  FORTH, Inc.

The Windows registry contains two basic elements: keys and values.

Registry keys are similar to folders; each key can contain subkeys,
which may contain further subkeys, and so on.  Keys are referenced with
a syntax similar to Windows path names, using backslashes to indicate
levels of hierarchy.  Each subkey has a mandatory name, which is a
non-empty string that cannot contain any backslash or null character,
and whose letter case is insignificant.

Registry values are name/data pairs stored within keys.  Registry
values are referenced separately from registry keys.  Each value
stored in a registry key has a unique name whose letter case is not
significant. The Windows API functions that query and manipulate
registry values take value names separately from the key path and/or
handle that identifies the parent key.  Registry values may contain
backslashes in their name but doing so makes them difficult to
distinguish from their key paths, so avoid that.
==================================================================== }

?( ... Registry keys)

{ --------------------------------------------------------------------
Product registry key

PRODUCT-REGISTRY holds the base product registry key.  Change this for
each unique product or end application, and each will have its own
settings in the registry.

GETREGKEY opens the base product registry (creating it if necessary)
and returns its handle hKey.
-------------------------------------------------------------------- }

256 BUFFER: PRODUCT-REGISTRY
   S" SOFTWARE\FORTH, Inc.\SwiftForth"  PRODUCT-REGISTRY ZPLACE

: GETREGKEY ( -- hKey )
   0 SP@ HKEY_CURRENT_USER PRODUCT-REGISTRY ROT RegCreateKey DROP ;

{ --------------------------------------------------------------------
Registry values

WRITE-REG writes binary data from the buffer [addr len] to the value
whose name is the null-terminated string zaddr under the registry key
specified by hKey.  Returns the result (0=good).  The key handle hKey
could be from GETREGKEY above or from some other call to RegCreateKey.

READ-REG reads binary value data from the value whose name is the
null-teriminated string zaddr into the buffer [addr len1].  Returns
the number of bytes read from the value len2 and result ior (0=good).
-------------------------------------------------------------------- }

: READ-REG ( addr len1 zaddr hKey -- len2 ior )
   SWAP 0 0 2ROT >R RP@ RegQueryValueEx R> SWAP ;

: WRITE-REG ( addr len zaddr hKey -- ior )
   SWAP 0 REG_BINARY 2ROT RegSetValueEx ;

{ --------------------------------------------------------------------
Registry values

REG@ reads a named integer value from the product registry and
The length of the binary value in the registry must be one cell (4
bytes) or the call to READ-REG will fail and REG@ returns 0.

REG! writes an integer value to the product registry.
-------------------------------------------------------------------- }

: REG@ ( zaddr -- x )
   GETREGKEY >R >R  0 SP@ CELL R> R@ READ-REG 2DROP
   R> RegCloseKey DROP ;

: REG! ( x zaddr -- )
   GETREGKEY >R >R  SP@ CELL R> R@ WRITE-REG 2DROP
   R> RegCloseKey DROP ;

{ ----------------------------------------------------------------------
Registry access routines for arbitrary HKCU/Software/... repositories.

These words are useful enough to exist. Kept separate because porting
the old uses of registry key management to this method might break
existing code.

In these routines, data is read or written at HKCU/Software/"zkey" for
value name "zname"
---------------------------------------------------------------------- }

: OPEN-REG-KEY ( zkey -- hkey )
   R-BUF  S" Software\" R@ ZPLACE  ZCOUNT R@ ZAPPEND
   0 SP@  HKEY_CURRENT_USER R> ROT RegCreateKey DROP ;

: WRITE-REG-DATA ( addr len zname zkey -- ior )
   OPEN-REG-KEY  DUP >R  WRITE-REG    R> REGCLOSEKEY DROP ;

: READ-REG-DATA ( addr len zname zkey -- len ior )
   OPEN-REG-KEY  DUP >R  READ-REG  R> REGCLOSEKEY DROP ;

