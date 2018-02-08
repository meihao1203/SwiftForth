{ ====================================================================
Shell interface

Copyright (C) 2008  FORTH, Inc.  All rights reserved.

$ consumes the rest of the line (including any comments) and passes
them to the shell specified in $SHELL (or /bin/sh if $SHELL is unset).
==================================================================== }

DECIMAL

{ --------------------------------------------------------------------
Shell access

$SHELL returns the path to the shell.

>SHELL invokes the shell with the string as its argument.
The shell is invoked as
   $SHELL -c ARG2
The exit status (code) from the child is returned in EXITSTATUS.

$ consumes the rest of the line as a command for the shell.  The line
is deliberately untrimmed, so any leading and/or trailing whitespace
(aside from the first space after $) will be included in the argument.
This is more useful for interactive testing...it works precisely the
same way it would at the shell prompt.
-------------------------------------------------------------------- }

FUNCTION: fork ( -- pid )
FUNCTION: waitpid ( pid *status opt -- pid )
FUNCTION: execve ( *filename *argv *envp -- ior )

: $SHELL ( -- z-addr )
   S" SHELL" FIND-ENV AND 0= IF  DROP  Z" /bin/sh"  THEN ;

: >SHELL ( addr u -- )
   R-BUF R@ ZPLACE  fork ?DUP IF
      EXITSTATUS 0 waitpid DROP
      ELSE  0  R@  Z" -c"  $SHELL SP@ OVER SWAP 'ENV execve sys_exit
   THEN  R> DROP ;

: $ ( <string> -- )   CR  0 WORD COUNT >SHELL ;
