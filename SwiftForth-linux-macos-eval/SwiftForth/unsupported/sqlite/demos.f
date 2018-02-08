{ ------------------------------------------------------------
    demos.f

    Demonstrate the classes in the SQLite3 library
 ------------------------------------------------------------ }

EMPTY
REQUIRES sqlite3.f

\ Create the database and statment objects
SQL-DB    BUILDS db
SQL-QUERY BUILDS stmt

\ Perform a simple query on the database
: DEMO1  ( -- )
    \ Open the database
    S" library.db" db OPEN  db .MESSAGE CR

    4 20 20 3 stmt SET-WIDTHS
    db S" SELECT * FROM Authors WHERE firstname=? AND surname=?" stmt PREPARE  db .MESSAGE CR
    S" Frank" S" Mittelbach" 2 stmt BIND-TEXT-PARAMS
    stmt STEP  DROP
    stmt .HEADER
    stmt .ROW
    stmt .ROWS
    stmt .DELIMITER-LINE
    stmt FINALIZE  db .MESSAGE CR

    db CLOSE DROP ;


\ Perform a more complex query involving joins
1024 BUFFER: 'SQL'
: DEMO2  ( -- )
    S" SELECT b.title, p.name AS publisher, b.pub_year AS year "
    'SQL' PLACE
    S" FROM Books b, Authors a, Publishers p, AuthorLink l "
    'SQL' APPEND
    S" WHERE a.id = l.author_id AND b.id = l.book_id AND b.pub_id = p.id "
    'SQL' APPEND
    S" AND a.surname LIKE ? "
    'SQL' APPEND
    S" ORDER BY year DESC"
    'SQL' APPEND

    S" library.db" db OPEN  db .MESSAGE CR

    20 15 4 3 stmt SET-WIDTHS
    db 'SQL' COUNT stmt PREPARE  db .MESSAGE CR
    S" Christiansen" 1 stmt BIND-TEXT-PARAMS
    stmt STEP  DROP
    stmt .HEADER
    stmt .ROW
    stmt .ROWS
    stmt .DELIMITER-LINE
    stmt FINALIZE  db .MESSAGE CR

    db CLOSE  DROP ;

CR .( Type DEMO1 or DEMO2 to see the demos )






