OPTIONAL CObject The principal base class.

{ ====================================================================
CObject is the principal base class

Copyright (c) 1972-1999, FORTH, Inc.

CObject is the principal base class for the Swift Foundation Class
Library.  It serves as the root not only for library classes such as
CFile and CObList, but also for the classes that you write

Requires:  SWOOP

Exports: see MFC documentation

==================================================================== }

THROW#
   S" SFC: Not implemented yet" >THROW ENUM IOR_SFC_N/I
TO THROW#

: N/I ( -- )   IOR_SFC_N/I THROW ;

{ --------------------------------------------------------------------
There is one CRuntimeClass structure for each CObject-derived class.

CLASS CRuntimeClass
   VARIABLE m_lpszClassName
   VARIABLE m_nObjectSize
   VARIABLE m_wSchema
   VARIABLE m_pfnCreateObject
   VARIABLE m_pfn_GetBaseClass
   VARIABLE m_pBaseClass
END-CLASS
-------------------------------------------------------------------- }

CLASS CObject

\   CRuntimeClass BUILDS rc

PUBLIC

   DEFER: AssertValid ( -- ) ;
   DEFER: Dump ( dc -- )   DROP DUMP ; ( ???? )

   : IsSerializable ( -- flag )   FALSE ;
   DEFER: Serialize ( CArchive -- )   DROP ;

   : GetRuntimeClass ( -- CRuntimeClass )   N/I ( rc ADDR ) ;

   : IsKindOf ( CRuntimeClass -- flag )   N/I ;
\      CRuntimeClass SIZEOF rc ADDR OVER  BEGIN
\         2OVER 2OVER COMPARE 0= IF
\            2DROP 2DROP TRUE EXIT
\         THEN  DROP USING CRuntimeClass m_pBaseClass @ 2DUP 0=
\      UNTIL  2DROP 2DROP FALSE ;

END-CLASS

