{ ====================================================================
Windows registry class for SWOOP

Copyright 2001  FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

OPTIONAL REPOSITORY A Windows registry class for SWOOP

{ --------------------------------------------------------------------
Need to configure
1) path for files
2) com port

We will use the ini nomenclature for these, since Forth uses KEY
-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
The repository class is designed for using the system registry as
a place to keep configuration data. The basic technique is that
all data goes under the major heading HKEY_CURRENT_USER, in a
subkey defined by KEYPATH, at a specific key NAME. All data is string
data, with a max length of MAX_PATH bytes.

NAME is the specific leaf where the data will be written. It must
be explicitly set before an object of the class may be used.

KEYPATH must be resolved in a subclass; this is so each product
can have its own registry area.

READ and WRITE are the main user features of the class. They read
and write strings to the registry. Each returns an ior, which if
nonzero means an error happened.
-------------------------------------------------------------------- }

CLASS REPOSITORY

PUBLIC

   MAX_PATH BUFFER: NAME
   MAX_PATH BUFFER: DATA

PROTECTED

   DEFER: KEYPATH ( -- z )   -1 ABORT" NO PATH" ;

   VARIABLE HANDLE
   VARIABLE SIZE

   DEFER: MAJOR-KEY ( -- hkey )   HKEY_CURRENT_USER ;

   : OPEN-KEY ( -- ior )
      MAJOR-KEY KEYPATH HANDLE RegCreateKey ;

   : CLOSE-KEY ( -- ior )
      HANDLE @ RegCloseKey 0 HANDLE ! ;

   : (READ) ( -- ior )   OPEN-KEY ?DUP ?EXIT
      HANDLE @ NAME 0 0 DATA SIZE RegQueryValueEx ?DUP ?EXIT
      CLOSE-KEY ;

   : (WRITE) ( -- ior )   OPEN-KEY ?DUP ?EXIT
      HANDLE @ NAME 0 REG_BINARY DATA SIZE @ RegSetValueEx ?DUP ?EXIT
      CLOSE-KEY ;

PUBLIC

   : READ ( -- addr len ior )
      MAX_PATH SIZE !  (READ)  DATA SIZE @  ROT ;

   : WRITE ( addr len -- ior )
      DUP SIZE !  DATA SWAP CMOVE  (WRITE) ;

END-CLASS

\\
\ Example of use:

REPOSITORY SUBCLASS MYDATA

   : KEYPATH ( -- z )   Z" MyCompany\MyApp" ;

END-CLASS

MYDATA BUILDS FNAME S" FileName" FNAME NAME ZPLACE

\ FNAME READ ( -- addr len ior )
\ FNAME WRITE ( addr len -- ior )
