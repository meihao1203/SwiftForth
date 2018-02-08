{ --------------------------------------------------------------------
SWOOP interface to the SQLite3 database library

For information about sqlite go to: www.sqlite.org

The SQL-DB class handles operations on a database (essentially opening
and closing the connection to the database).

The SQL-QUERY class handles interaction with the database via SQL
statements and datasets returned from database queries.

To use this library, the sqlite3.dll DLL must be somewhere in the
path.

----------------------------------------------------------------------
    Version:    1.0
    Author:     Tony McClelland <afmcc@btinternet.com>
    Date:       December, 2007

    Still to do (for future versions):
        Implement bind parameters other than simple text (BLOBs,
        integer and floating point numbers).
        Allow user-defined functions.
        Enable more flexible formatting of results (though in practice
        it is likely that calls to these functions would be made in
        a Win32 GUI program, so the formatting can be handled when
        using Windows controls).
        Implement proper error handling with THROW/CATCH - the library
        needs to be more robust.
        Other suggestions?

    This software is made available under the same terms as SQLite
    itself, i.e.:

    The author disclaims copyright to this source code. In place of
    a legal notice, here is a blessing:

    May you do good and not evil.
    May you find forgiveness for yourself and forgive others.
    May you share freely, never taking more than you give.
-------------------------------------------------------------------- }


{ ------------------------------------------------------------
    Utility words.
  ------------------------------------------------------------ }

\ Type out an ASCIIZ string or "NULL" if given a NULL pointer
: ZTYPE  ( addr -- )
   DUP 0= IF  ." NULL"  ELSE  ZCOUNT TYPE  THEN ;

\ Type out an ASCIIZ string in a field of width n
: .ASCIIZ  ( c-addr n -- )
   SWAP ZCOUNT  DUP >R  TYPE  R> -  SPACES ;

\ Create an ASCIIZ string buffer from a counted string
: >ASCIIZ  ( c-addr u -- addr )
   DUP 1+ ALLOCATE THROW           \ Allocate space for the string
   DUP >R  ZPLACE  R> ;            \ Copy the string into the buffer

\ Type a dash
: '-'  ( -- )  [CHAR] - EMIT ;

\ Type a plus sign
: '+'  ( -- )  [CHAR] + EMIT ;

\ Type a line of n - signs
: -LINE-  ( n -- )  0 ?DO  '-' LOOP ;

{ ------------------------------------------------------------
    SQLite return codes
  ------------------------------------------------------------ }
0
ENUM SQLITE_OK					\ Successful result
ENUM SQLITE_ERROR               \ SQL error or missing database
ENUM SQLITE_INTERNAL			\ An internal logic error in SQLite
ENUM SQLITE_PERM               	\ Access permission denied
ENUM SQLITE_ABORT               \ Callback routine requested an abort
ENUM SQLITE_BUSY               	\ The database file is locked
ENUM SQLITE_LOCKED              \ A table in the database is locked
ENUM SQLITE_NOMEM               \ A malloc() failed
ENUM SQLITE_READONLY           	\ Attempt to write a readonly database
ENUM SQLITE_INTERRUPT           \ Operation terminated by sqlite_interrupt()
ENUM SQLITE_IOERR               \ Some kind of disk I/O error occurred
ENUM SQLITE_CORRUPT             \ The database disk image is malformed
ENUM SQLITE_NOTFOUND           	\ (Internal Only) Table or record not found
ENUM SQLITE_FULL               	\ Insertion failed because database is full
ENUM SQLITE_CANTOPEN           	\ Unable to open the database file
ENUM SQLITE_PROTOCOL           	\ Database lock protocol error
ENUM SQLITE_EMPTY               \ (Internal Only) Database table is empty
ENUM SQLITE_SCHEMA              \ The database schema changed
ENUM SQLITE_TOOBIG              \ Too much data for one row of a table
ENUM SQLITE_CONSTRAINT          \ Abort due to contraint violation
ENUM SQLITE_MISMATCH           	\ Data type mismatch
ENUM SQLITE_MISUSE              \ Library used incorrectly
ENUM SQLITE_NOLFS               \ Uses OS features not supported on host
ENUM SQLITE_AUTH               	\ Authorization denied
DROP 100
ENUM SQLITE_ROW                	\ sqlite_step() has another row ready
ENUM SQLITE_DONE               	\ sqlite_step() has finished executing
DROP


{ ------------------------------------------------------------
    SQLite data types
  ------------------------------------------------------------ }
1
ENUM SQLITE_INTEGER
ENUM SQLITE_FLOAT
ENUM SQLITE_TEXT
ENUM SQLITE_BLOB
ENUM SQLITE_NULL
DROP


{ ------------------------------------------------------------
    Other constants used by SQLite
  ------------------------------------------------------------ }
0 CONSTANT SQLITE_STATIC


{ ------------------------------------------------------------
    Import the sqlite3.dll C API functions.
  ------------------------------------------------------------ }
LIBRARY sqlite3.dll

1 CIMPORT: sqlite3_errmsg           \ Return latest error message
1 CIMPORT: sqlite3_errcode          \ Return latest error code
2 CIMPORT: sqlite3_open             \ Open a connection to a database
1 CIMPORT: sqlite3_close            \ Close the database connection
5 CIMPORT: sqlite3_prepare          \ Prepare an SQL statement
1 CIMPORT: sqlite3_reset            \ Reset a prepared SQL statement
5 CIMPORT: sqlite3_bind_text        \ Bind a text parameter to a prepared query
1 CIMPORT: sqlite3_step             \ Execute a prepared SQL statement
1 CIMPORT: sqlite3_column_count     \ No. of columns in a result set
2 CIMPORT: sqlite3_column_type      \ Type of data in this column
2 CIMPORT: sqlite3_column_decltype  \ Return text for the declared type
2 CIMPORT: sqlite3_column_name      \ Return the name of the column
2 CIMPORT: sqlite3_column_text      \ The text in a column of a result set
1 CIMPORT: sqlite3_finalize         \ Release a compiled SQL statement


{ ------------------------------------------------------------
    The SQL-DB class.
    Encapsulate behaviour of a database connection.
  ------------------------------------------------------------ }

CLASS SQL-DB
   VARIABLE HANDLE             \ Handle to an open database
   MAX_PATH 1+ BUFFER: DBNAME  \ Buffer for name of database file

   \ Display an error message if an error occurred
   : .MESSAGE  ( rc -- )
      SQLITE_OK <> IF
         HANDLE @ sqlite3_errmsg ZTYPE
      THEN ;

   \ Open the database whose name is passed
   : OPEN  ( c-addr u -- rc )
      DBNAME ZPLACE                     \ Save the database name
      DBNAME HANDLE sqlite3_open ;   \ Open the database and keep a handle

   \ Close the database
   : CLOSE  ( -- rc )   HANDLE @ sqlite3_close ;

END-CLASS


{ ------------------------------------------------------------
    The SQL-QUERY class
    Encapsulate an SQL statement in SQLite 3
  ------------------------------------------------------------ }
CLASS SQL-QUERY
   VARIABLE DBH                \ Database handle for this statement
   VARIABLE 'SQL               \ Pointer to statement
   VARIABLE 'REMAINING         \ Text of uncompiled SQL
   VARIABLE STH                \ Statement handle
   VARIABLE #WIDTHS            \ How many column widths are stored?
   VARIABLE 'WIDTHS            \ Pointer to array of column widths

   \ Set column widths for output
   : SET-WIDTHS  ( n1 n2 ... nn n -- )
      #WIDTHS !                   \ Save the no. of column widths to set
      'WIDTHS @  FREE THROW       \ Free any existing widths
      \ Create the widths array
      #WIDTHS @ CELLS ALLOCATE THROW  'WIDTHS !

      \ Store the widths (in reverse order as they come off the stack)
      #WIDTHS @  0 DO
         'WIDTHS @  I CELLS +  !
      LOOP ;

   \ Get the width of the nth column
   : ?WIDTH  ( n -- n' )  #WIDTHS @ SWAP - 1- 'WIDTHS @  SWAP CELLS +  @ ;

   \ Prepare the statement
   : PREPARE  ( db c-addr u -- rc )
      >ASCIIZ  'SQL !                 \ Save the SQL text
     ( db) -> HANDLE @ DBH !         \ Save the database handle
     DBH @  'SQL @  -1 STH 'REMAINING  sqlite3_prepare ;

   \ Reset the SQL statement so that it can be used again
   : RESET  ( -- rc )   STH @ sqlite3_reset ;

   \ Bind text parameters to the ? arguments in a prepared query
   \ Pass n counted strings followed by n, the number of strings passed.
   : BIND-TEXT-PARAMS  ( caddr1 u1 ... caddr n un n -- )
      1 SWAP DO       \ Loop downwards so that strings are handled in reverse order
         STH @ I  2SWAP  SQLITE_STATIC sqlite3_bind_text DROP
      -1 +LOOP ;

   \ Execute the SQL statement once
   : STEP  ( -- rc )   STH @ sqlite3_step ;

   \ How many columns in a result set?
   : #COLS  ( -- n )  STH @ sqlite3_column_count ;

   \ Get the name of the nth column in a result set
   : COL-NAME  ( n -- addr )  STH @  SWAP sqlite3_column_name ;

   \ Get the type of the nth column in a result set
   : COL-TYPE  ( n -- n' )  STH @  SWAP sqlite3_column_type ;

   \ Print the column type
   : .COL-TYPE  ( col-type -- )
      CASE
         SQLITE_INTEGER OF ." INTEGER" ENDOF
         SQLITE_FLOAT OF   ." FLOAT"   ENDOF
         SQLITE_TEXT OF    ." TEXT"    ENDOF
         SQLITE_BLOB OF    ." BLOB"    ENDOF
         SQLITE_NULL OF    ." NULL"    ENDOF
         ( Default)        ." UNKNOWN"
      ENDCASE ;

   \ Get the declared type of the nth column in a result set
   : COL-DECLARED-TYPE  ( n -- addr )  STH @  SWAP sqlite3_column_decltype ;

   \ Print a delimiter line like +---+--------+
   : .DELIMITER-LINE  ( -- )
      0 #WIDTHS @ 1- ?DO
         '+'  'WIDTHS @  I CELLS + @  -LINE-
      -1 +LOOP
      '+' CR ;

   \ Print a header row
   : .HEADER  ( -- )
     .DELIMITER-LINE
     #COLS 0 ?DO
        ." |" I COL-NAME  I ?WIDTH  .ASCIIZ
     LOOP
     ." |" CR
     .DELIMITER-LINE ;

   \ Get the text in the nth column of a result set
   : COL-TEXT  ( n -- addr )  STH @  SWAP sqlite3_column_text ;

   \ Print a result row
   : .ROW  ( -- )
      #COLS 0 ?DO
         ." |" I COL-TEXT  I ?WIDTH  .ASCIIZ
      LOOP
      ." |" CR ;

   \ Print all result sets
   : .ROWS  ( -- )
      BEGIN
         STEP  SQLITE_ROW = WHILE
         .ROW
      REPEAT ;

   \ Finish with the statement
   : FINALIZE  ( -- rc )
      STH @ sqlite3_finalize
      'SQL @  FREE THROW
      'WIDTHS @  ?DUP IF  FREE THROW  0 'WIDTHS !  THEN ;

END-CLASS


