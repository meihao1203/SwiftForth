@echo off

rem     =======================================================================
rem     Customization instructions:
rem
rem     1) Make a copy of this file in your local project directory and name
rem     it flash-local.bat so it will not be overwritten by a SwiftX update.
rem
rem     2) Carefully edit the command line below that invokes avrdude.exe with
rem     the correct parameters for your ISP programmer.  The sample here is
rem     for an AVRISP2-compatible programmer that appears as port COM13.
rem
rem     =======================================================================

if "%1"=="" goto missing
if "%2"=="" goto missing
if "%3"=="" goto missing

REM  Arg1 is path to Swiftx\bin folder
REM  Arg2 is fuse high byte
REM  Arg3 is fuse low byte

%1avrdude.exe -c avrisp2 -P COM13 -p m168 -y -U flash:w:target.hex -u -U hfuse:w:0x%2:m -U lfuse:w:0x%3:m
if not errorlevel 1 exit
pause
exit 1

:missing
echo Input argument(s) missing.  Script intended only for use by SwiftX.
pause
exit 1
