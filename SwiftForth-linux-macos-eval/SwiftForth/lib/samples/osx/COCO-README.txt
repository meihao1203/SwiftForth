Quick readme for Cocoa interface SwiftForth i386-macOS
----------------------------------------------------------------------

The SwiftForth distribution has the Cocoa interface in SwiftForth/lib/samples/osx.

Generating a coco-sf turnkey:

1) Launch sf and load the Cocoa interface
   REQUIRES new-coco

2) Automaticly saves the turnkey in
   PROGRAM %SwiftForth/bin/osx/coco-sf

3) Exits to the command shell

Launch coco-sf in SwiftForth/bin/osx

For the toy application:

1) Launch sf and load the toy app:
   REQUIRES toy-app

2) Double click the toy app's "ok" icon to run it


Note:
The special OSX fix files in the mac-sf.f loader file will run with all
OSX versions tested (10.6, 10.10 - 10.12). But you can comment them out
for 10.6 Snow Leopard while 10.10 Yosemite doesn't need the 10.11 El Capitan
and 10.12 Sierra fixes.
No doubt next year other OS specific fixes will be added.

OSX 10.11 El Capitan users may also read /mac/doc/codesign.txt
AFAIK coco-sf runs in all gatekeeper configurations and isn't bothered with SIP.
