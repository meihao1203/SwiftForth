{ ====================================================================
Exception handler context interpreter

Copyright 2012  FORTH, Inc.

This file defines the register offsets in the machine context record
captured by the SIGNAL handler.
==================================================================== }

PACKAGE ERROR-HANDLERS

{ --------------------------------------------------------------------
Registers

The ENUMs below define the order of the registers at the beginning of
the TRACEBACK buffer.
-------------------------------------------------------------------- }

0
ENUM REG_GS
ENUM REG_FS
ENUM REG_ES
ENUM REG_DS
ENUM REG_EDI
ENUM REG_ESI
ENUM REG_EBP
ENUM REG_ESP
ENUM REG_EBX
ENUM REG_EDX
ENUM REG_ECX
ENUM REG_EAX
ENUM REG_TRAPNO
ENUM REG_ERR
ENUM REG_EIP
ENUM REG_CS
ENUM REG_EFL
ENUM REG_UESP
ENUM REG_SS
DROP

END-PACKAGE
