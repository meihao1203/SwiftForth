{ ====================================================================
Dictionary pruning

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

{ --------------------------------------------------------------------
Routines to prune the Forth dictionary.

Dependencies: H CELL- ( HLIM ) holds top of dictionary available space
              H CELL+ holds bottom of dictionary
              STATUS 2+ holds task follower
              @REL !REL ,REL -ORIGIN +ORIGIN CALLS
              <LINK LAST WID> >WID WIDS VLINK

Exports: ?PRUNED ?PRUNED UNLINKS :REMEMBER :PRUNE REMEMBER MARKER
         GILD EMPTY
-------------------------------------------------------------------- }

?( Dictionary pruning)

{ ------------------------------------------------------------------------
Pruning support

?PRUNED  returns true if the given address is not in the dictionary.
Typically, this address is located in the pruning structure that is
traversed as the dictionary is pruned.  Consequently, this definition
returns true when the instance is removed.

?PRUNE  returns true if the current definition is being pruned.
Typically, this means that an entire utility is being globally
discarded.

UNLINK  breaks the link of the given entry, resetting it to the link
pointed to by the element on top of the stack.

UNLINKS  scans the given linked list, unlinking anything that is
not located within the current dictionary bounds.  The linked
list must terminate with a 0 link.
------------------------------------------------------------------------ }

: ?PRUNED ( a -- t )   HLIM 2@ WITHIN ;

: ?PRUNE ( -- t )   R@ ?PRUNED ;

: -PRUNED ( -- t )   R@ ?PRUNED 0= ;

: UNLINK ( a a' -- a )   @REL OVER !REL ;

: UNLINKS ( a -- )
   BEGIN  DUP @REL WHILE
      DUP @REL  ?PRUNED IF
         DUP @REL UNLINK
      ELSE  @REL
   THEN  REPEAT  DROP ;

{ --------------------------------------------------------------------
CLIP unlinks one wordlist and
CROP unlinks all of the wordlists.
-------------------------------------------------------------------- }

: CLIP ( wid -- )
   WID> @+ 0 DO ( t )
      DUP UNLINKS CELL+
   LOOP DROP ;

: CROP ( -- )
   WIDS BEGIN ( a wl )
      @REL ?DUP WHILE
      DUP CELL+ >WID CLIP
   REPEAT ;

{ ------------------------------------------------------------------------
Pruning structure

'REMEMBER  and  'PRUNE  contained lists of marker extensions.
:REMEMBER  and  :PRUNE  extend the dictionary markers.

The pruning structure is created by the :REMEMBER extensions and
traversed by the :PRUNE extensions.  Every byte that is laid down in a
:REMEMBER using C, or , must be passed over by a corresponding :PRUNE
function.  The :PRUNE extension is passed the address which
corresponds to the top of the dictionary when the :REMEMBER extension
was executed.  It is the :PRUNE extension's responsibility to return
the address which corresponds to the top of the dictionary after the
:REMEMBER extension is finished.  The structure contains:

   |ptr to x|follower|<what :REMEMBER built>|x

PRUNE is passed the address of a pruning structure.  It aborts if that
address is not presently within the dictionary.  Otherwise, it resets
the dictionary and executes the pruning linked list, passing the
address of the pruning structure to each element in the list.  It is
the responsibility of the pruning word to traverse any items that have
been laid down by its corresponding remember extension.

REMEMBER defines dictionary markers that restore the dictionary to its
state after they were defined.  This is more powerful than FORGET and
can be extended by using the defining words :REMEMBER and :PRUNE.

For example, a pointer named 'H can be added like this:

   :REMEMBER   'H @ , ;

   :PRUNE ( a -- a' )
      ?PRUNE IF                          \ If pruning this extension
         [ 'H @ ] LITERAL DUP ?PRUNED IF \ If prior extension is
            DROP 'H @                    \    also pruned.
      THEN  ELSE  CELL SIZED @           \ Else get remembered
      THEN  'H ! ;                       \ Restore value

Note that this extension makes a distinction between a marker that is
defined before this extension was defined and those that follow it.
If the marker was defined prior to this extension, then the :REMEMBER
data had not been saved, and 'H needs to be restored to the value it had
when this extension was compiled.  It also accounts for some other
extension touching the same location.  If that other extension is also
being removed, then we assume it has already set the location to the
proper value and we leave it alone this time.

MARKER  defines dictionary markers that forget themselves when they are
executed.
------------------------------------------------------------------------ }

?( ... MARKER and REMEMBER)

VARIABLE 'REMEMBER
VARIABLE 'PRUNE

: :REMEMBER   'REMEMBER <LINK  LAST OFF ] ;
: :PRUNE   'PRUNE <LINK  LAST OFF ] ;

: PRUNE ( a -- )
   DUP @REL  'EMPTY @REL U< ABORT" Can't prune protected memory region"
   @+REL H !  CROP  WIDS UNLINKS  VLINK UNLINKS
   'PRUNE CALLS  'REMEMBER UNLINKS  'PRUNE UNLINKS  DROP ;

: (REMEMBER) ( -- )
   HERE 0 ,  'REMEMBER CALLS  HERE SWAP !REL ;

: REMEMBER ( -- )       \ Usage: REMEMBER <name>
   CREATE (REMEMBER)  DOES>  PRUNE ;

: MARKER ( -- )         \ Usage: MARKER <name>
   HERE -ORIGIN (REMEMBER) CREATE ,
   DOES> @ +ORIGIN DUP PRUNE H ! ;

{ ------------------------------------------------------------------------
EMPTY Support

GILDS sets the beginning of the task's dictionary given by H CELL+ .
GILDED resets H to the beginning of the task's dictionary.

GILD compiles a prune structure using (REMEMBER) and leaves 'EMPTY
pointing to it.  H is set to the contents of H CELL+ .

EMPTY restores H and if 'EMPTY points to a prune list, passes its
address to PRUNE .

------------------------------------------------------------------------ }

?( ... GILD and EMPTY)

: GILDS ( -- )   HERE H CELL+ !REL ;
: GILDED ( -- )   H CELL+ @REL H ! ;

: GILD ( -- )   HERE 'EMPTY !REL  (REMEMBER)  GILDS ;

: EMPTY   GILDED  'EMPTY @REL ?DUP IF  PRUNE  THEN ;

{ --------------------------------------------------------------------
Set up the prune chain for the already defined chains.
-------------------------------------------------------------------- }

: UNLINK-CHAINS
   CHAINS BEGIN
      @REL ?DUP WHILE
      DUP CELL- UNLINKS
   REPEAT
   CHAINS UNLINKS ;

: UNLINK-SWITCHES
   SWITCHES BEGIN
      @REL ?DUP WHILE
      DUP 2 CELLS - UNLINKS
   REPEAT
   SWITCHES UNLINKS ;

:PRUNE   UNLINK-CHAINS UNLINK-SWITCHES ;

:REMEMBER   #USER ,  THROW# , ;
:PRUNE ( addr1 -- addr2 )   @+ TO #USER  @+ TO THROW# ;
