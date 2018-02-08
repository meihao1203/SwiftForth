{ ====================================================================
A simple example showing class build procedure.

Copyright (c) 2008-2017 Roelf Toxopeus

SwiftForth version.
Creating class with methods and instance variable(s).
Last: 16 October 2014 13:21:23 CEST -rt
==================================================================== }

{ --------------------------------------------------------------------
Create and test a class in 7 steps.
Instructions precede the code, which is assumed to be self explaining.

Still some notes:
To differentiate a callback for ObjC from a executable word in Forth,
normally a leading * character is used. Similar to the pointer
directive in C declararions. Here it looks to confusing so ' tick is
used in stead.

Another diverging from the used style in the cocoa interface:
A leading @ character is normaly used while defining methods using
COCOA:. Here it's ommited.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

\ --- 1. create the class using NSObject as super class

NSObject new.class myClass

\ --- 2. add methods, 

CALLBACK: '/me ( rec sel -- void )   $deadbeef 0" mydata" _PARAM_0 !IVAR  0 ; 
: /METYPES   0" v@:" ;
'/me /METYPES 0" /me" myClass ADD.METHOD

CALLBACK: 'me ( rec sel -- n )   0" mydata" _PARAM_0 @IVAR ; 
: METYPES   0" i@:" ;
'me METYPES 0" me" myClass ADD.METHOD

\ --- 3. add some ivars

: MYDATATYPE  0" i" ;
MYDATATYPE 0" mydata" myClass ADD.IVAR

\ --- 4. now add/register the class

myClass ADD.CLASS

\ --- 5. make instance etc.

\ cocoaclass myClass   \ <-- don't need this, we have the ref!
myClass @alloc @init VALUE MYOMY

\ --- 6. define the methods for Forth usage
COCOA: /me ( -- ret )

COCOA: me ( -- n )

\ --- 7. test it
(*
MYOMY /me DROP
MYOMY me .H
0 0" mydata"  MYOMY !IVAR
MYOMY me .H
*)

\\ ( eof )