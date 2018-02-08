{ ====================================================================
Local variable compiler as objects

Copyright (C) 2001-2011 FORTH, Inc.
Rick VanNorman
==================================================================== }

{ --------------------------------------------------------------------
The basic definition of a named-entity is that it has a name and an
offset in a structure.  The base class keeps the displacement and name
(31 bytes max!), and provides a means to add a new name and to see if
the name matches (nocaps!) a given string.
-------------------------------------------------------------------- }

CLASS ENTITY

   VARIABLE SPOT                \ housekeeping common variable

   32 BUFFER: NAME              \ name, counted string, 31 chars max

   : NAMED ( a n -- )           \ remember a name
      31 MIN  NAME PLACE ;

   : MATCHES ( a n -- f )       \ see if the name matches a string
      31 MIN NAME COUNT 31 MIN COMPARE(NC) 0= ;

END-CLASS

{ --------------------------------------------------------------------
Having a class to represent a local entity, we need a class for a
group of them.  ENTITIES provides this, and via the judicious use of
deferred methods, allows it to be the superclass basis for a generic
entity type.

N has total the number of entities defined.

NV is the number of arg entities (not initialized runtime). Included
in total N count.

The deferred operations assume that they are operating in the context
of the subclass.

#N  has the max number of entities allowed.
ANOTHER  adds entity N.
INITIALIZE  compiles initialization code for entity N.
LOOPUP compares the string to entity N.
PREPARE is the generic subclass initialization routine.

?ROOM checks for the name table full.
NAMED adds a string to the name table.
NEW-NAME parses a word and adds it to the name table.
FIND-NAME looks for the string in the name table.
FINISH uses the subclass initialization routine, then calls
   the entity initialization routine for each defined entity.
RESET prepares the name table.
CLEAR sets the name table to "ready to be used".
ANY? is true if there are any names in the table.
-------------------------------------------------------------------- }

THROW#
   S" No room for named entity" >THROW ENUM IOR_ENTITY_NOROOM
TO THROW#

CLASS ENTITIES

   VARIABLE N
   VARIABLE NV

   : NODEFER ( -- )   IOR_UNRESOLVED THROW ;

   DEFER: #N            NODEFER ;   ( -- n )   \ just a constant!
   DEFER: ANOTHER       NODEFER ;   ( a u n -- )
   DEFER: INITIALIZE    NODEFER ;   ( n -- )
   DEFER: LOOKUP        NODEFER ;   ( a u n -- flag )
   DEFER: PREPARE       NODEFER ;   ( -- )
   DEFER: DOT           NODEFER ;   ( n -- )

   : ?ROOM ( -- )
      N @ #N >= IOR_ENTITY_NOROOM ?THROW ;

   : FINISH ( -- )
      PREPARE  N @ 0 ?DO  I INITIALIZE  LOOP ;

   : RESET ( -- )   0 N !  0 NV ! ;
   : CLEAR ( -- )   -1 N !  0 NV ! ;
   : ANY? ( -- flag )   N @ 0< NOT ;

   \ let NAMED guarantee that N is positive, since CLEAR leave
   \ it negative. The CLEAR init is done by /LOCALS; this fix
   \ should make it possible for (LOCAL) to be used as by Ertl.

   : NAMED ( i*x addr u -- )
      N @ 0 MAX N !
      ?ROOM  N @ ANOTHER  N ++ ;

   : NEW-NAME ( -- )   BL WORD COUNT NAMED ;

   : FIND-NAME ( addr n -- n true | 0 )
      N @ 0 ?DO
         2DUP I LOOKUP IF
            2DROP I -1 UNLOOP EXIT
         THEN
      LOOP 2DROP 0 ;

END-CLASS

{ --------------------------------------------------------------------
LSPACE allocates n bytes of temporary space on the return stack, sets
the local variable frame pointer 'LF, and leaves the return stack frame
so that an exit will remove the frame from the stack.
-------------------------------------------------------------------- }

LABEL L-GO-ON
   EAX JMP                          \ jump to address eax
   END-CODE

CODE LSPACE ( n -- )
   EAX POP                          \ get my return address into eax
   'LF [U] PUSH                     \ save the local object frame
   ESP ECX MOV                      \ save esp in ecx
   EBX ESP SUB                      \ allocate EBX bytes below esp
   ESP 'LF [U] MOV                  \ set new local object frame
   ECX PUSH                         \ push saved ESP onto return stack
   POP(EBX)
   L-GO-ON CALL                     \ make return to LSPACE 's caller
                                    \ when LSPACE 's caller returns, it
HERE ( *)
   ECX POP                          \ comes here, reads the old esp
   ECX ESP MOV                      \ and write back to discard space
   'LF [U] POP                      \ restore the old local object frame
   RET END-CODE
( *) ORIGIN - CONSTANT 'LSPACE

{ --------------------------------------------------------------------
These two classes work in concert.  LOCAL-VARIABLE extends the ENTITY
class to provide the methods for local variable access. Then,
LOCAL-VARIABLES (note: plural) extends ENTITIES to manage a set of
local variables.  These classes are only used during compilation; at
run time, all appropriate code has been compiled. and the classes are
not needed.

FETCH returns the value of the local variable,
STORE writes a value to the local variable, and
ADDTO adds an arbitrary number to it.

SPOT here will contain at compile time the offset from the base to the
instance, and 'LF contains the base address of the frame.
-------------------------------------------------------------------- }

ENTITY SUBCLASS LOCAL-VARIABLE

   : FETCH ( -- n )   [+ASM]
         PUSH(EBX)
         'LF [U] EBX MOV
         SPOT @ [EBX] EBX MOV
      [-ASM] ;

   : STORE ( n -- )   [+ASM]
         'LF [U] EAX MOV
         EBX SPOT @ [EAX] MOV
         POP(EBX)
      [-ASM] ;

   : ADDTO ( n -- )   [+ASM]
         'LF [U] EAX MOV
         EBX SPOT @ [EAX] ADD
         POP(EBX)
      [-ASM] ;

   : ADDROF ( n -- )   [+ASM]
         PUSH(EBX)
         'LF [U] EBX MOV
         SPOT @ [EBX] EBX LEA
      [-ASM] ;

END-CLASS

{ --------------------------------------------------------------------
#N is how many local variables this class can support
POOL[] is the array of local variables
-------------------------------------------------------------------- }

ENTITIES SUBCLASS LOCAL-VARIABLES

   16 CONSTANT NLOCALS

   : #N ( -- n )   NLOCALS ;

   NLOCALS LOCAL-VARIABLE BUILDS[] POOL[]

   : LOOKUP ( a u n -- flag )
      POOL[] MATCHES ;

   : PREPARE ( -- )
      N @ CELLS POSTPONE LITERAL POSTPONE LSPACE ;

   : INITIALIZE ( n -- )   POOL[] STORE ;

   : LOCAL? ( -- n true | false )
      0  STATE @ -EXIT  N @ 1 < ?EXIT  DROP
      >IN @  BL WORD COUNT FIND-NAME DUP IF
         ROT DROP  ELSE  SWAP >IN !  THEN ;

   : TO-LOCAL ( -- flag )
      LOCAL? DUP IF SWAP POOL[] STORE THEN ;

   : +TO-LOCAL ( -- flag )
      LOCAL? DUP IF SWAP POOL[] ADDTO THEN ;

   : &OF-LOCAL ( -- flag )
      LOCAL? DUP IF SWAP POOL[] ADDROF THEN ;

   : AT-LOCAL ( -- flag )
      LOCAL? DUP IF SWAP POOL[] FETCH THEN ;

   : PARSE-LOCALS| ( -- )
      RESET  BEGIN  NEXT-WORD
         2DUP S" |" COMPARE WHILE  NAMED
      REPEAT 2DROP  FINISH ;

\ {: a b c | d e f -- x :}

   : <FINISH ( -- )
      PREPARE  N @ NV @ - ?DUP IF  0 SWAP 1- DO  I INITIALIZE  -1 +LOOP THEN ;

   : DROP-VARS} ( -- )
      BEGIN  NEXT-WORD S" :}" COMPARE 0= UNTIL  <FINISH ;

   : PARSE-VARS} ( -- )
      BEGIN  NEXT-WORD
         2DUP S" --" COMPARE 0= IF  2DROP DROP-VARS}  EXIT  THEN
         2DUP S" :}" COMPARE WHILE  NAMED  NV ++
      REPEAT 2DROP <FINISH ;

   : PARSE-LOCALS} ( -- )
      RESET  BEGIN  NEXT-WORD
         2DUP S" |" COMPARE 0= IF  2DROP PARSE-VARS}  EXIT  THEN
         2DUP S" --" COMPARE 0= IF  2DROP DROP-VARS}  EXIT  THEN
         2DUP S" :}" COMPARE WHILE  NAMED
      REPEAT 2DROP <FINISH ;

   \ ANOTHER is called by NAMED to create the named local entity.
   \ If ANOTHER is called with a zero length name, assume that
   \ it means the end of the local instantiation for this definition,
   \ and FINISH the local pre-processing.

   : ANOTHER ( a u n -- )
      OVER IF ( a real name to define)
         DUP CELLS OVER POOL[] SPOT !  POOL[] NAMED
      ELSE ( 0 length, end of names, FINISH supplied by NAMED)
         2DROP DROP  FINISH
      THEN ;

   : REFERENCE ( n -- )
      POOL[] FETCH ;

END-CLASS

LOCAL-VARIABLES BUILDS LVAR-COMP

{ --------------------------------------------------------------------
Standard words

(LOCAL) passes a message to the system that has one of two meanings.
If u is non-zero, the message identifies a new local whose definition
name is given by the string of characters identified by c-addr u. If u
is zero, the message is "last local" and c-addr has no significance.
The result of executing (LOCAL) during compilation of a definition is
to create a set of named local identifiers, each of which is a
definition name, that only have execution semantics within the scope
of that definition’s source.

LOCALS| defines a list of locals variables.
Usage: LOCALS| name1 name2 ... namen |
Compilation: Create local identifiers by repeatedly skipping leading
spaces, parsing name, and creating local names. The list of locals to
be defined is terminated by | . Append the run-time semantics given
below to the current definition.
Run-time: ( xn ... x2 x1 -- ) Initialize local identifiers each of
which takes as its initial value the top stack item, removing it from
the stack. Identifier name1 is initialized with x1, identifier name2
with x2, etc. When invoked, each local will return its value. The
value of a local may be changed using TO.
Note: This word is obsolescent and is included as a concession to
existing implementations.
}

\  {: defines a list of local variables and provides for both initialized
\  and uninitialized locals.
\  Usage: {: i*(arg) [| i*(val)] [-- i*(out)] :}
\  where (arg), (val), and (out) are local names.
\  Run-time:: Create locals for all (arg) and (val) names. The (out)
\  names are ignored. The (arg) names are initialized from the data
\  stack, with the top of the stack being assigned to the right most
\  (arg) name; (val) names are uninitialized.

: (LOCAL) ( addr u -- )   LVAR-COMP NAMED ;

: LOCALS| ( -- )   LVAR-COMP PARSE-LOCALS| ; IMMEDIATE

: {: ( -- )   LVAR-COMP PARSE-LOCALS} ;  IMMEDIATE

-? : TO  ( -- )   LVAR-COMP  TO-LOCAL ?EXIT  POSTPONE  TO ; IMMEDIATE
-? : +TO ( -- )   LVAR-COMP +TO-LOCAL ?EXIT  POSTPONE +TO ; IMMEDIATE
-? : &OF ( -- )   LVAR-COMP &OF-LOCAL ?EXIT  POSTPONE &OF ; IMMEDIATE

LABEL O-GO-ON
   EAX JMP                          \ jump to address eax
   END-CODE

CODE OSPACE ( n -- )                \ n is size in cells to reserve
   EAX POP                          \ get my return address into eax
   'OB [U] PUSH                     \ save the local object frame
   $DEADBEEF # PUSH                 \ dummy pointer tag
   BEGIN
      0 # PUSH
      EBX DEC
   0= UNTIL
   ESP 'OB [U] MOV                  \ set new local object frame
   POP(EBX)
   O-GO-ON CALL                     \ make return to OSPACE 's caller
                                    \ when OSPACE 's caller returns, it
                                    \ comes here, and undoes the frame
HERE ( *)
   BEGIN
      $DEADBEEF # 0 [ESP] CMP 0<> WHILE   \ while not zero
      8 # 4 [ESP] CMP  0<> IF             \ local instantiation size can't be 8
         PUSH(EBX)                     \ onto the stack
         0 [ESP] EBX MOV               \ with the address of the object
         ' DESTRUCT-OBJECT >CODE CALL  \ and destruct it
      THEN
      4 [ESP] ESP ADD
   REPEAT
   4 # ESP ADD                      \ discard the zero
   'OB [U] POP                      \ restore the old local object frame
   RET END-CODE

( *) ORIGIN - CONSTANT 'OSPACE

{ --------------------------------------------------------------------
THE OBJECT STACK FRAME NEEDS TO BE MODIFIED TO BUILD FULL OBJECTS
AND THE O-GO-ON NEEDS TO MAKE SURE TO SEND THE DESTROY MESSAGE FOR
EACH OBJECT IN THE LIST.

The local objects are referenced via two different methods; the address
of an existing object may be passed on the stack or the space for the
object may be allocated on the stack.

Assuming an example that looks like

   : TEST ( point -- )   [OBJECTS FOO MAKES JOE   FOO NAMES SAM
      FOO MAKES SUE OBJECTS]  ... ;
   : TRY TEST ;

Executing TRY builds builds a return stack frame that looks like
this at the point where the "..." would have executed.

top>   return to o-go-on
       addr of joe
       len of record, 6 cells
       objtag
       foo
       joe.x
       joe.y
       addr of sam
       len of record, 2 cells
       addr of sue
       len of record, 6 cells
       objtag
       foo
       sue.x
       sue.y
       "deadbeef"                a dummy pointer, end of frame
       old 'ob
       return to try
       <<rest of stack frame from interpreter>>

-------------------------------------------------------------------- }

{ --------------------------------------------------------------------
LOCAL-OBJECT is a single entity. These routines are compiler
extensions that lay down the proper code for the entity.  They all
assume that the return stack pool has been initialized properly.

During compilation, SPOT contains the offset from the base to the
instance, and 'OB contains the base address of the frame.

INIT-POINTER initializes the local record of an object to point to a
supplied address. It is assumed that the address is on the stack when
the code that was laid down is executed.

INIT-LOCAL initializes an object in the return stack record and then
points the local record to the return stack memory.
-------------------------------------------------------------------- }

: EVEN-SIZED ( class -- n )   SIZEOF 3 + -4 AND ;

ENTITY SUBCLASS LOCAL-OBJECT

   VARIABLE CLASS
   VARIABLE IS-LOCAL

\ spot is addr of object        pointer to either local or given data
\ spot+4 is size of record      8 for pointers, sizeof(class)+16 otherwise
\ spot+8 is objtag              not present in pointer
\ spot+12 is class              not present in pointer
\ spot+16 is object             not present in pointer

   : INIT-POINTER ( addr -- )   [+ASM]
         'OB [U] EAX MOV
         EBX SPOT @ [EAX] MOV
         8 # SPOT @ CELL+ [EAX] MOV
         POP(EBX)
      [-ASM] ;

   : INIT-LOCAL ( -- )
      [+ASM]                                    \
         PUSH(EBX)                              \
         'OB [U] EAX MOV                        \
         SPOT @ 16 + [EAX] EBX LEA              \ ob+spot+16 is local object
         CLASS @ # -4 [EBX] MOV                 \ ob+spot+12 is class
         OBJTAG # -8 [EBX] MOV                  \ ob+spot+8 is objtag
         CLASS @ EVEN-SIZED 16 + # -12 [EBX] MOV    \ ob+spot+4 is size
         EBX -16 [EBX] MOV                      \ ob+spot is local pointer
      [-ASM]                                    \
      ( object) POSTPONE CONSTRUCT-OBJECT ;     \ only local objects get construct

   : ADDRESS ( -- )   [+ASM]
         PUSH(EBX)
         'OB [U] EBX MOV
         SPOT @ [EBX] EBX MOV
      [-ASM] ;

   : NEW-ADDRESS ( -- )   [+ASM]
         'OB [U] ECX MOV
         EBX SPOT @ [ECX] MOV
         POP(EBX)
      [-ASM] ;

END-CLASS

{ --------------------------------------------------------------------
#N is how many local variables this class can support
POOL[] is the array of local variables
: BROADCAST ( class object message -- )   2>R
-------------------------------------------------------------------- }

ENTITIES SUBCLASS LOCAL-OBJECTS

   20 CONSTANT NOBJECTS

   VARIABLE TOTAL

   : #N ( -- n )   NOBJECTS ;

   NOBJECTS LOCAL-OBJECT BUILDS[] POOL[]

   : LOOKUP ( a u n -- flag )
      POOL[] MATCHES ;

   : PREPARE ( -- )   TOTAL @ -EXIT
      TOTAL @ CELL/ POSTPONE LITERAL POSTPONE OSPACE ;

   : LOCAL? ( -- n true | false )
      0  STATE @ -EXIT  N @ 1 < ?EXIT  DROP
      >IN @  BL WORD COUNT FIND-NAME DUP IF
         ROT DROP  ELSE  SWAP >IN !  THEN ;

   : TO-LOCAL ( -- flag )
      >IN @ >R  LOCAL? DUP IF NIP 1 'METHOD ! THEN R> >IN ! ;

   : +TO-LOCAL ( -- flag )
      >IN @ >R  LOCAL? DUP IF NIP 2 'METHOD ! THEN R> >IN ! ;

   : &OF-LOCAL ( -- flag )
      >IN @ >R  LOCAL? DUP IF NIP 3 'METHOD ! THEN R> >IN ! ;

   : INITIALIZE ( n -- )
      DUP POOL[] IS-LOCAL @ IF
         POOL[] INIT-LOCAL
      ELSE
         POOL[] INIT-POINTER
      THEN ;

   : OPEN ( -- )   STATE @ 0= IOR_COMPILEONLY ?THROW
      POSTPONE [  RESET 0 TOTAL ! ;

   : ANOTHER ( class local addr u n -- )   >R
      2SWAP ( addr u class local)
      DUP R@ POOL[] IS-LOCAL !
      OVER R@ POOL[] CLASS !
      TOTAL @ R@ POOL[] SPOT !
      2SWAP R> POOL[] NAMED
      ( local) IF  EVEN-SIZED 3 CELLS +
      ELSE ( pointer) DROP CELL THEN CELL+
      TOTAL +! ;

   : OBJ-LOCAL ( class local -- )
      BL WORD COUNT NAMED ( calls ANOTHER with n) ;

   : NAMING ( class -- )   0 OBJ-LOCAL ;
   : MAKING ( class -- )   1 OBJ-LOCAL ;

   \ reference should set the class and add members to the
   \ search order, but cannot due to the fact that
   \ it belongs to a class with virtual members -- and the
   \ code compiled to call reference includes saving, setting
   \ and restoring 'THIS which subverts the act of using >THIS
   \ sigh...

   : REFERENCE ( n -- class )
      DUP POOL[] ADDRESS   POOL[] CLASS @ ;

   : SHOW
      N @ 0 DO I POOL[] NAME COUNT TYPE SPACE LOOP ;

END-CLASS

{ --------------------------------------------------------------------
Local objects

[OBJECTS begins instantiation of local objects, terminated by OBJECTS].
It must be used inside a definition. There may be multiple objects
instantiated or named (using MAKES and/or NAMES) between [OBJECTS and
OBJECTS], but there may be only one such region in a definition.

OBJECTS] terminates the instantiation of local objects.
-------------------------------------------------------------------- }

LOCAL-OBJECTS BUILDS LOBJ-COMP

: NAMES ( class -- )   LOBJ-COMP NAMING ;
: MAKES ( class -- )   LOBJ-COMP MAKING ;

: OBJECTS] ( check -- )
   ['] LOBJ-COMP <> IOR_UNBALANCED ?THROW  ]  LOBJ-COMP FINISH ;

: [OBJECTS ( -- check )
   LOBJ-COMP OPEN  ['] LOBJ-COMP ; IMMEDIATE

{ --------------------------------------------------------------------
-------------------------------------------------------------------- }

: CLEAR-LOCALS ( -- )    LOBJ-COMP CLEAR  LVAR-COMP CLEAR ;

' CLEAR-LOCALS IS /LOCALS

LVAR-COMP #N CONSTANT #LOCALS

{ ------------------------------------------------------------------------
Locals search

This extends the interpreter to look for local variables before running
the normal search mechanism. Should only be used if the local mechanism
is active, ie has values in the table.
------------------------------------------------------------------------ }

: SEARCH-LOCAL-SPACE ( c-addr len -- 0 | xt flag )
   STATE @ IF
      MEMBERS ?ORDER >R  LOBJ-COMP ANY? IF
         2DUP LOBJ-COMP FIND-NAME IF
            NIP NIP LOBJ-COMP REFERENCE ( class) >THIS +MEMBERS
            R> DROP  ['] NOOP 1  EXIT
         THEN
      THEN
      LVAR-COMP ANY? IF
         2DUP LVAR-COMP FIND-NAME IF
            NIP NIP LVAR-COMP REFERENCE
            R> IF +MEMBERS THEN  ['] NOOP 1  EXIT
         THEN
      THEN
      R> IF +MEMBERS THEN
   THEN 2DROP 0 ;

' SEARCH-LOCAL-SPACE IS (FINDEXT)

{ --------------------------------------------------------------------
Very nice to be able to rename a named local object
-------------------------------------------------------------------- }

: BECOMES ( -- )   BL WORD COUNT
   LOBJ-COMP FIND-NAME 0= ABORT" Can't find local object"
   LOBJ-COMP POOL[] NEW-ADDRESS ; IMMEDIATE

AKA BECOMES =: IMMEDIATE
