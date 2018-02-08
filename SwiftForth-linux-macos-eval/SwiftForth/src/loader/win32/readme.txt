Flat assembler for Windows is used to generate the template for the
SwiftForth kernel header and loader.

Get flat assembler here:

http://flatassembler.net/

Source file sf-loader.asm has all the sections, code, and icon
resource definition to generate sf-loader.img.

The SwiftForth target compiler concatenates the binary kernel image to
the end of sf-loader.img and updates the size and checksum fields in the
PE header.

The SwiftForth turnkey compiler does the same with a full image of the
dictionary plus the cross-reference table and can optionally update
the application icon.

The icon file must be 32x32 pixels with 4-bit pixel depth.

Run make.bat to generate a new sf-loader.img (moved to SwiftForth/bin
directory at the end).  The batch file assumes flat assembler is
installed in \fasm.
