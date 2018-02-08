{ ====================================================================
printerior.f


Copyright (C) 2001 FORTH, Inc.   <br> Rick VanNorman  rvn@forth.com
==================================================================== }

THROW#
   S" PRINTER already open"             >THROW ENUM IOR_PRT_ALREADYOPEN
   S" WINFILE output already vectored"  >THROW ENUM IOR_PRT_REVECTOR
   S" Error starting to print document" >THROW ENUM IOR_PRT_BADSTARTDOC
   S" Error starting to print page"     >THROW ENUM IOR_PRT_BADSTARTPAGE
   S" Error ending printed page"        >THROW ENUM IOR_PRT_BADENDPAGE
   S" Error ending printed document"    >THROW ENUM IOR_PRT_BADENDDOC
   S" Can't get default printer"        >THROW ENUM IOR_PRT_NODEFPRINTER
TO THROW#

