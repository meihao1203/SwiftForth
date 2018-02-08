{ ====================================================================
application bundle specifics

Copyright (c) 2013-2017 Roelf Toxopeus

SwiftForth version.
define the Info.plist, pkginfo and apprun files here.
Note: the executable is apprun by default
	  the app icon is app.icns by default
Last: 7 Nov 2016 00:38:02 CET  -rt
==================================================================== }

{ --------------------------------------------------------------------
The Info.plist, pkginfo and apprun file contents:

(TXTLINE) -- parse entire line and 'compile' it as a string without count
or terminating zero.
TXTLINE+ -- (TXTLINE) and add a trailing linefeed.
TXTLINE -- (TXTLINE) and add a trailing zero and align, like ,Z" but without
quotes!

INFO.PLIST$1 -- first part of default Info.plist file as a string.
Goes up to
 <key>CFBundleName</key>
 <string>
Used to write out to new Info.plist file in app bundle. App name is
added and second part of default Info.plist file is written out.
INFO.PLIST$2 -- second part of default Info.plist. Starts at
 </string>
 <key>CFBundlePackageType</key>
and goes to end.

PKGINFO$ -- the PkgInfo string. Addjust if necessary.

APPRUN$1 -- first part of shell script in apprun file.
Goes up to
 MYAPP=
Used to write out to apprun shell script file. App name is added and
finished with second part of shell script.
APPRUN$2 -- second part of arrun shell script. Starts at linefeed after
app name.

See turnkey2.f
-------------------------------------------------------------------- }

/FORTH
DECIMAL

: (TXTLINE) ( <text> -- )   0 PARSE BL SKIP -TRAILING  HERE OVER ALLOT SWAP CMOVE ;

: TXTLINE+ ( <text> -- )  (TXTLINE) 10 C, ;

: TXTLINE ( <text> -- )   (TXTLINE) 0 C, ALIGN ;

CREATE INFO.PLIST$1
TXTLINE+ <?xml version="1.0" encoding="UTF-8"?>
TXTLINE+ <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
TXTLINE+ <plist version=\"1.0\">
TXTLINE+ <dict>
TXTLINE+ <key>CFBundleAllowMixedLocalizations</key>
TXTLINE+ <string>true</string>
TXTLINE+ <key>CFBundleDevelopmentRegion</key>
TXTLINE+ <string>English</string>
TXTLINE+ <key>CFBundleExecutable</key>
TXTLINE+ <string>apprun</string>
TXTLINE+ <key>CFBundleIconFile</key>
TXTLINE+ <string>app.icns</string>
TXTLINE+ <key>CFBundleInfoDictionaryVersion</key>
TXTLINE+ <string>6.0</string>
TXTLINE+ <key>CFBundleName</key>
TXTLINE <string>

CREATE INFO.PLIST$2
TXTLINE+ </string>
TXTLINE+ <key>CFBundlePackageType</key>
TXTLINE+ <string>APPL</string>
TXTLINE+ <key>CFBundleSignature</key>
TXTLINE+ <string>4inc</string>
TXTLINE+ <key>CFBundleVersion</key>
TXTLINE+ <string>1.0.5</string>
TXTLINE+ </dict>
TXTLINE </plist>

CREATE PKGINFO$
TXTLINE APPL4inc

CREATE APPRUN$1
TXTLINE+ #!/bin/sh
TXTLINE+
TXTLINE MYAPP=

CREATE APPRUN$2
TXTLINE+
TXTLINE+ WHEREAMI=`dirname "$0"`
TXTLINE+
TXTLINE+ osascript << EOT
TXTLINE+ tell application "System Events" to set terminalOn to (exists process "Terminal")
TXTLINE+ tell application "Terminal"
TXTLINE+    if (terminalOn) then
TXTLINE+         activate
TXTLINE+         do script "nohup '$WHEREAMI/$MYAPP' >/dev/null 2>&1"
TXTLINE+    else
TXTLINE+         do script "nohup '$WHEREAMI/$MYAPP' >/dev/null 2>&1" in front window
TXTLINE+         delay 0.2
TXTLINE+         quit
TXTLINE+    end if
TXTLINE+ end tell
TXTLINE EOT

{ --------------------------------------------------------------------
  The Info.plist, pkginfo and apprun files:
  
  INFOPLIST-FILE -- create Info.plist file, write out the plist strings to this
  file. Insert the given app name in plist.

  PKGINFO-FILE -- create the PKGInfo file, write out the default pkginfo.

  APPRUN-FILE -- create the apprun file, write out the apprun strings and
  insert the appname. Make file executable.

  apprun is a bash shell script, launching sf-app and then detaching it
  from its parental shell. Results in a standalone foreground application.
  Terminal.app can be closed if not needed for anything else:  BYET
-------------------------------------------------------------------- }

: ?WRITE-ERROR ( fid ior -- )
		?DUP IF ." WRITE-FILE error !" SWAP CLOSE-FILE DROP THROW THEN ;

: WRITE-PLIST ( a n fid -- )
	DUP INFO.PLIST$1 ZCOUNT ROT WRITE-FILE ?WRITE-ERROR
	DUP >R WRITE-FILE R> SWAP ?WRITE-ERROR
	INFO.PLIST$2 ZCOUNT ROT WRITE-FILE ?WRITE-ERROR ;

: INFOPLIST-FILE ( a n -- )
	S" Info.plist" FILE DUP >R WRITE-PLIST R> CLOSE-FILE THROW ;
	
: WRITE-PKGINFO ( fid -- )
	PKGINFO$ ZCOUNT ROT WRITE-FILE ?WRITE-ERROR ;

: PKGINFO-FILE ( -- )
	S" Pkginfo" FILE DUP >R WRITE-PKGINFO R> CLOSE-FILE THROW ;
	
: WRITE-APPRUN ( a n fid -- )
	DUP APPRUN$1 ZCOUNT ROT WRITE-FILE ?WRITE-ERROR
	DUP >R WRITE-FILE R> SWAP ?WRITE-ERROR
	APPRUN$2 ZCOUNT ROT WRITE-FILE ?WRITE-ERROR ;

: APPRUN-FILE ( a n -- )
	S" apprun" FILE DUP >R WRITE-APPRUN R> CLOSE-FILE THROW
	CWD DUP S" apprun" ROT ZAPPEND DEFAULT-MODE chmod THROW ;

\\ ( eof )