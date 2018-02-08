{ ====================================================================
Applescript

Copyright (c) 2002-2017 Roelf Toxopeus

SwiftForth version.
Applescripting from within Forth.
Last: 11 April 2014 08:55:32 CEST    -rt
==================================================================== }

{ --------------------------------------------------------------------
Applescript is very touchy about the layout.
See a simple example at end of file
See GDB.f for example of combining scriptparts into one script.
Note: for now start new line after </SCRIPT> !!!
      else the "<" from </SCRIPT> will be included in script
      to lazy to fix
Note: /SOURCE might not be the safest/portable way to do this!!!!!!!
For now it suffice, but ...
Info on AppleEvent stuff, AEReplaceDescData etc.:
AE.h in AE.framework inside CoreServices.framework
Info on Applescript:
OSA.h in OpenScripting.framework inside Carbon.framework

HELLO-SCRIPT -- get scripting component.
BYE-SCRIPT -- release scripting component.
SOURCE>SCRIPT -- prepare source text for compiling, initiating AEDesc.
DOSCRIPT -- execute string as script, using AEDesc.
<SCRIPT> -- compile text between <SCRIPT> and </SCRIPT> as a zstring.
-------------------------------------------------------------------- }

/FORTH
DECIMAL

LACKING Carbon.framework FRAMEWORK Carbon.framework

Carbon.framework

LACKING OpenDefaultComponent  FUNCTION: OpenDefaultComponent ( type subtype -- component )
LACKING CloseComponent        FUNCTION: CloseComponent ( component -- result )
FUNCTION: OSADispose ( Component scriptID -- result )

: HELLO-SCRIPT ( -- component )
	ASCII osa! 1- ASCII ascr OpenDefaultComponent ;

: BYE-SCRIPT ( component scriptID -- )
	>R DUP R> OSADispose DROP
	CloseComponent DROP ;

FUNCTION: AEReplaceDescData ( type *data datasize *AEDesc -- result )

CREATE AEDesc 0 , 0 ,

: SOURCE>SCRIPT ( zstring -- )   ASCII TEXT SWAP ZCOUNT AEDesc AEReplaceDescData DROP ;

FUNCTION: OSACompileExecute ( scriptcomponent *AEDesc context flags *scriptid -- result )

0 CONSTANT kOSANullScript
$30 CONSTANT kAEAlwaysInteract

: DOSCRIPT ( zstring -- )
	SOURCE>SCRIPT
	HELLO-SCRIPT
	DUP AEDesc kOSANullScript kAEAlwaysInteract 0 >R RP@ OSACompileExecute DROP R>
	BYE-SCRIPT ;

: <SCRIPT> ( -- )
	POSTPONE (Z")
	/SOURCE DROP
	S" </SCRIPT>" DUP >R SKIPS
	/SOURCE DROP OVER - R> - STRING, ; IMMEDIATE

cr .( applescript interface)

\\ ( eof )

\ --- examples:

: "test"
<script>
tell application "Terminal"
	activate
	do script with command "ls"
end tell </script>
;                     ( <= put semi-colon on new line !!! )

: tt   "test" doscript ;

\ alternative without <SCRIPT>
: "test2"
	s\" tell application \"System Preferences\"\l" 	pad zplace
	s\" activate\l" 											pad zappend
	s" end tell"	 											pad zappend
	pad ;

: ss   "test2" doscript ;

\\ ( eof )