as -arch i386 sf-loader.asm -o sf-loader.o
ld sf-loader.o -lc -arch i386 -x -no_uuid -macosx_version_min 10.6 -segprot __DATA rwx rwx  -o sf-loader.img
rm sf-loader.o
chmod -x sf-loader.img
mv sf-loader.img ../../../bin/osx
