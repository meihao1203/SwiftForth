{ ====================================================================
Folder Operations

Copyrights (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
Implement folder/directory creating words
Last: 21 March 2014 07:39:20 CET   -rt
==================================================================== }

/FORTH
DECIMAL

{ -----------------------------------------------------------------------------------------
CREATE-DIR -- create a folder/directory from given name and mode, analogue to CREATE-FILE.
Uses PATHPAD instead of R-BUF, because the pathbuffers in sf are much smaller than the max
path length: MAX-PATH.

DEFAULT-MODE -- see the following from Apple dev docs:

MODES
  Modes may be absolute or symbolic.  An absolute mode is an octal number constructed from the sum of one
  or more of the following values:

Note: these mode numbers are in OCTAL !!!!!

		  4000    (the set-user-ID-on-execution bit) Executable files with this bit set will run with
					 effective uid set to the uid of the file owner.  Directories with the set-user-id bit set
					 will force all files and sub-directories created in them to be owned by the directory
					 owner and not by the uid of the creating process, if the underlying file system supports
					 this feature: see chmod(2) and the suiddir option to mount(8).
		  2000    (the set-group-ID-on-execution bit) Executable files with this bit set will run with
					 effective gid set to the gid of the file owner.
		  1000    (the sticky bit) See chmod(2) and sticky(8).
		  0400    Allow read by owner.
		  0200    Allow write by owner.
		  0100    For files, allow execution by owner.  For directories, allow the owner to search in the
					 directory.
		  0040    Allow read by group members.
		  0020    Allow write by group members.
		  0010    For files, allow execution by group members.  For directories, allow group members to
					 search in the directory.
		  0004    Allow read by others.
		  0002    Allow write by others.
		  0001    For files, allow execution by others.  For directories allow others to search in the
					 directory.

  For example, the absolute mode that permits read, write and execute by the owner, read and execute by
  group members, read and execute by others, and no set-uid or set-gid behaviour is 755
  (400+200+100+040+010+004+001).

Also see  https://developer.apple.com/library/mac/#documentation/Darwin/Reference/ManPages/man1/chmod.1.html%23//apple_ref/doc/man/1/chmod
and /usr/include/sys/stat.h

FOLDER -- add new directory with given name to current working directory.
Uses default mode, deals with error.
FOLDER+ -- add new directory with given name to current working directory
and make it the new working directory.
FILE -- create file with given name in current working directory and leave
it open. Return file id.
-------------------------------------------------------------------------------------------- }

\ some bitmask modes for directories and files
\ %111000000 constant me-only
\ %111111000 constant me-staff

\ this is the only mode which seems to work properly
OCTAL
400 200 + 100 + 40 + 10 + 4 + 1 + CONSTANT DEFAULT-MODE
DECIMAL

FUNCTION: mkdir ( path mode -- ret )	\ create directory
FUNCTION: chmod ( path mode -- ret ) 	\ change permission

: CREATE-DIR ( a n mode -- ior )
	>R PATHPAD >R
	DUP MAX-PATH > ABORT" Doesn't fit PATHPAD !"
	R@ ZPLACE
   R> R> mkdir ;
	
: FOLDER ( a n -- )
	 CWD DUP >R ZAPPEND  R> DEFAULT-MODE mkdir THROW ;

: FOLDER+ ( a n -- )
	FOLDER PATHPAD ZCOUNT CHWD ;

: FILE ( a n -- fid )
	CWD DUP >R ZAPPEND  R> ZCOUNT R/W CREATE-FILE THROW ;

cr .( new directory creation loaded)
    
\\ ( eof )
