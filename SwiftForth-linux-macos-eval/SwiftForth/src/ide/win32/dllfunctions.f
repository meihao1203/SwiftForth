{ ====================================================================
Predefined Windows API References

Copyright 2001  FORTH, Inc.
==================================================================== }

?( Predefined Windows API References)

{ --------------------------------------------------------------------
These Windows libraries are required by SwiftForth.
-------------------------------------------------------------------- }

LIBRARY KERNEL32
LIBRARY GDI32
LIBRARY USER32
LIBRARY ADVAPI32
LIBRARY SHELL32
LIBRARY COMDLG32
LIBRARY COMCTL32

{ --------------------------------------------------------------------
Define the external library functions here.
-------------------------------------------------------------------- }

FUNCTION: DrawText                      ( hdc addr n 'rect style -- res )
FUNCTION: PostQuitMessage               ( n -- x )
FUNCTION: DragAcceptFiles               ( hwnd flag -- )
FUNCTION: DragFinish                    ( hdrop -- )
FUNCTION: DragQueryFile                 ( hdrop index zbuf zsiz -- n )
FUNCTION: RegisterClass                 ( wndclass -- atom )
FUNCTION: RegisterClassEx               ( wndclass -- atom )
FUNCTION: Beep                          ( freq duration -- res )
FUNCTION: BeginPaint                    ( hwnd 'paint -- dc )
FUNCTION: CallWindowProc                ( 'old hwnd msg wparam lparam -- res )
FUNCTION: CreateMenu                    ( -- hmenu )
FUNCTION: DeleteDC                      ( dc -- flag )
FUNCTION: DeleteObject                  ( hobj -- flag )
FUNCTION: ExitProcess                   ( res -- x )

FUNCTION: AbortDoc                      ( a -- x )
FUNCTION: AppendMenu                    ( a b c d -- x )
FUNCTION: BitBlt                        ( a b c d e f g h i -- x )
FUNCTION: CheckDlgButton                ( a b c -- x )
FUNCTION: CheckMenuItem                 ( a b c -- x )
FUNCTION: CheckRadioButton              ( a b c d -- x )
FUNCTION: ChooseFont                    ( a -- x )
FUNCTION: ClientToScreen                ( a b -- x )
FUNCTION: CloseClipboard                ( -- x )
FUNCTION: CommConfigDialog              ( a b c -- x )
FUNCTION: CreateCaret                   ( a b c d -- x )
FUNCTION: CreateCompatibleBitmap        ( a b c -- x )
FUNCTION: CreateCompatibleDC            ( a -- x )
FUNCTION: CreateDIBitmap                ( a b c d e f -- x )
FUNCTION: CreateDialogIndirectParam     ( a b c d e -- x )
FUNCTION: CreateFontIndirect            ( a -- x )
FUNCTION: CreatePalette                 ( a -- x )
FUNCTION: CreatePopupMenu               ( -- x )
FUNCTION: CreateSolidBrush              ( a -- x )
FUNCTION: CreateStatusWindow            ( a b c d -- x )
FUNCTION: CreateToolbarEx               ( a b c d e f g h i j k l m -- x )
FUNCTION: CreateWindowEx                ( a b c d e f g h i j k l -- x )
FUNCTION: DefDlgProc                    ( a b c d -- x )
FUNCTION: DefWindowProc                 ( a b c d -- x )
FUNCTION: DestroyCaret                  ( -- x )
FUNCTION: DestroyMenu                   ( a -- x )
FUNCTION: DestroyWindow                 ( a -- x )
FUNCTION: DialogBoxIndirectParam        ( a b c d e -- x )
FUNCTION: DispatchMessage               ( a -- x )
FUNCTION: EmptyClipboard                ( -- x )
FUNCTION: EnableMenuItem                ( a b c -- x )
FUNCTION: EnableWindow                  ( a b -- x )
FUNCTION: EndDialog                     ( a b -- x )
FUNCTION: EndDoc                        ( a -- x )
FUNCTION: EndPage                       ( a -- x )
FUNCTION: EndPaint                      ( a b -- x )
FUNCTION: EnterCriticalSection          ( a -- x )
FUNCTION: EnumChildWindows              ( a b c -- x )
FUNCTION: EnumWindows                   ( a b -- x )
FUNCTION: ExtTextOut                    ( a b c d e f g h -- x )
FUNCTION: FillRect                      ( a b c -- x )
FUNCTION: FindClose                     ( a -- x )
FUNCTION: FindFirstFile                 ( a b -- x )
FUNCTION: FindNextFile                  ( a b -- x )
FUNCTION: FindWindow                    ( a b -- x )
FUNCTION: GdiFlush                      ( -- x )
FUNCTION: GetBkColor                    ( a -- x )
FUNCTION: GetCapture                    ( -- x )
FUNCTION: GetClassInfo                  ( a b c -- x )
FUNCTION: GetClassLong                  ( a b -- x )
FUNCTION: GetClassName                  ( hwnd addr len -- len )
FUNCTION: GetClientRect                 ( a b -- x )
FUNCTION: GetClipboardData              ( a -- x )
FUNCTION: GetCommProperties             ( a b -- x )
FUNCTION: GetCommState                  ( a b -- x )
FUNCTION: GetCurrentProcess             ( -- x )
FUNCTION: GetCursorPos                  ( a -- x )
FUNCTION: GetDC                         ( a -- x )
FUNCTION: GetDateFormat                 ( a b c d e f -- x )
FUNCTION: GetDesktopWindow              ( -- x )
FUNCTION: GetDeviceCaps                 ( a b -- x )
FUNCTION: GetDialogBaseUnits            ( -- x )
FUNCTION: GetDlgCtrlID                  ( a -- x )
FUNCTION: GetDlgItem                    ( a b -- x )
FUNCTION: GetDlgItemInt                 ( a b c d -- x )
FUNCTION: GetDlgItemText                ( a b c d -- x )
FUNCTION: GetEnvironmentVariable        ( a b c -- x )
FUNCTION: GetKeyState                   ( a -- x )
FUNCTION: GetLocalTime                  ( addr -- ior )
FUNCTION: GetSystemTime                 ( addr -- ior )
FUNCTION: GetMenu                       ( a -- x )
FUNCTION: GetMenuState                  ( a b c -- x )
FUNCTION: GetMenuString                 ( a b c d e -- x )
FUNCTION: GetMessage                    ( a b c d -- x )
FUNCTION: GetObject                     ( a b c -- x )
FUNCTION: GetOpenFileName               ( a -- x )
FUNCTION: GetParent                     ( a -- x )
FUNCTION: GetSaveFileName               ( a -- x )
FUNCTION: GetStockObject                ( a -- x )
FUNCTION: GetSubMenu                    ( a b -- x )
FUNCTION: GetSystemMetrics              ( a -- x )
FUNCTION: GetSystemPaletteEntries       ( a b c d -- x )
FUNCTION: GetTextMetrics                ( a b -- x )
FUNCTION: GetTickCount                  ( -- x )
FUNCTION: GetVolumeInformation          ( a b c d e f g h -- x )
FUNCTION: GetWindow                     ( a b -- x )
FUNCTION: GetWindowLong                 ( a b -- x )
FUNCTION: GetWindowRect                 ( a b -- x )
FUNCTION: GetWindowText                 ( a b c -- x )
FUNCTION: GlobalLock                    ( a -- x )
FUNCTION: GlobalReAlloc                 ( a b c -- x )
FUNCTION: GlobalSize                    ( a -- x )
FUNCTION: GlobalUnlock                  ( a -- x )
FUNCTION: HideCaret                     ( a -- x )
FUNCTION: InitCommonControls            ( -- x )
FUNCTION: InvalidateRect                ( a b c -- x )
FUNCTION: IsBadReadPtr                  ( a b -- x )
FUNCTION: IsBadWritePtr                 ( a b -- x )
FUNCTION: IsDialogMessage               ( a b -- x )
FUNCTION: IsDlgButtonChecked            ( a b -- x )
FUNCTION: IsWindowEnabled               ( a -- x )
FUNCTION: KillTimer                     ( a b -- x )
FUNCTION: LeaveCriticalSection          ( a -- x )
FUNCTION: LoadCursor                    ( a b -- x )
FUNCTION: LoadIcon                      ( a b -- x )
FUNCTION: LoadMenuIndirect              ( a -- x )
FUNCTION: MapDialogRect                 ( a b -- x )
Function: MonitorFromWindow             ( hwnd flag -- hwnd )
FUNCTION: MoveWindow                    ( a b c d e f -- x )
FUNCTION: OpenClipboard                 ( a -- x )
FUNCTION: PageSetupDlg                  ( a -- x )
FUNCTION: PeekMessage                   ( a b c d e -- x )
FUNCTION: PostMessage                   ( a b c d -- x )
FUNCTION: PrintDlg                      ( a -- x )
FUNCTION: QueryPerformanceCounter       ( a -- x )
FUNCTION: QueryPerformanceFrequency     ( a -- x )
FUNCTION: RealizePalette                ( a -- x )
FUNCTION: RegCloseKey                   ( h -- x )
FUNCTION: RegCreateKey                  ( h zaddr addr -- x )
FUNCTION: RegDeleteKey                  ( h zaddr -- x )
FUNCTION: RegQueryValueEx               ( a b c d e f -- x )
FUNCTION: RegSetValueEx                 ( a b c d e f -- x )
FUNCTION: ReleaseCapture                ( -- x )
FUNCTION: ReleaseDC                     ( a b -- x )
FUNCTION: RemoveMenu                    ( a b c -- x )
FUNCTION: ScreenToClient                ( a b -- x )
FUNCTION: SelectObject                  ( a b -- x )
FUNCTION: SelectPalette                 ( a b c -- x )
FUNCTION: SendDlgItemMessage            ( a b c d e -- x )
FUNCTION: SendMessage                   ( a b c d -- x )
FUNCTION: SetBkColor                    ( a b -- x )
FUNCTION: SetCapture                    ( a -- x )
FUNCTION: SetCaretPos                   ( a b -- x )
FUNCTION: SetClassLong                  ( a b c -- x )
FUNCTION: SetClipboardData              ( a b -- x )
FUNCTION: SetCommState                  ( a b -- x )
FUNCTION: SetCommTimeouts               ( a b -- x )
FUNCTION: SetCursor                     ( a -- x )
FUNCTION: SetDCBrushColor               ( dc color -- res )
FUNCTION: SetDIBits                     ( a b c d e f g -- x )
FUNCTION: SetDlgItemInt                 ( a b c d -- x )
FUNCTION: SetDlgItemText                ( a b c -- x )
FUNCTION: SetFocus                      ( a -- x )
FUNCTION: GetFocus                      ( -- x )
FUNCTION: GetForegroundWindow           ( -- handle )
FUNCTION: SetForegroundWindow           ( handle -- x )
FUNCTION: SetLocalTime                  ( a -- x )
FUNCTION: SetMenu                       ( a b -- x )
FUNCTION: SetScrollInfo                 ( a b c d -- x )
FUNCTION: SetScrollPos                  ( a b c d -- x )
FUNCTION: SetScrollRange                ( a b c d e -- x )
FUNCTION: SetTextColor                  ( a b -- x )
FUNCTION: SetTimer                      ( a b c d -- x )
FUNCTION: SetUnhandledExceptionFilter   ( a -- x )
FUNCTION: SetWindowLong                 ( a b c -- x )
FUNCTION: SetWindowText                 ( a b -- x )
FUNCTION: ShellExecute                  ( a b c d e f -- x )
FUNCTION: ShowCaret                     ( a -- x )
FUNCTION: ShowScrollBar                 ( a b c -- x )
FUNCTION: ShowWindow                    ( a b -- x )
FUNCTION: Sleep                         ( a -- x )
FUNCTION: StartDoc                      ( a b -- x )
FUNCTION: StartPage                     ( a -- x )
FUNCTION: TerminateProcess              ( a b -- x )
FUNCTION: TextOut                       ( a b c d e -- x )
FUNCTION: TrackPopupMenu                ( a b c d e f g -- x )
FUNCTION: TranslateMessage              ( a -- x )
FUNCTION: UnregisterClass               ( a b -- x )
FUNCTION: UpdateWindow                  ( a -- x )
FUNCTION: VirtualQuery                  ( a b c -- x )
FUNCTION: WaitForInputIdle              ( a b -- x )

FUNCTION: SetWindowPos                  ( hwnd order x y cx cy flags -- bool )
FUNCTION: GetWindowPlacement            ( hwnd 'wndplace -- bool )
FUNCTION: SetWindowPlacement            ( hwnd 'wndplace -- bool )
FUNCTION: IsZoomed                      ( hwnd -- bool )
FUNCTION: GetSystemMenu                 ( hwnd xx -- hmenu )
FUNCTION: IsWindowVisible               ( hwnd -- bool )
FUNCTION: IsIconic                      ( hwnd -- bool )
FUNCTION: GetProp                       ( hwnd zstr -- n )
FUNCTION: RemoveProp                    ( hwnd zstr -- flag )
FUNCTION: SetProp                       ( hwnd zstr n -- bool )
FUNCTION: SystemParametersInfo          ( a b c d -- bool )

FUNCTION: CreateProcess                 ( a b c d e f g h i j -- bool )

FUNCTION: FormatMessage                 ( a b c d e f g -- x )
FUNCTION: LocalFree                     ( a -- x )

PACKAGE LIB-INTERFACE

PUBLIC

: /EXTERNAL-DLLS ( -- )   0LIBS 0PROCS                  \ Clear all
   ['] OPEN-LIBS CATCH IF  1 ExitProcess  THEN          \ Open all required DLLs, bail on error
   ['] RESOLVE-PROCS CATCH IF  1 ExitProcess  THEN      \ Resolve proc calls, bail on error
   InitCommonControls DROP ;

' /EXTERNAL-DLLS IS /IMPORTS            \ Assign extended behavior to kernel start-up

END-PACKAGE

{ --------------------------------------------------------------------
These words are provided to simplifiy the windows api for
RegisterClass.  Windows requires a data structure to be build
just for the purpose of registering a class -- then the info
is discarded.  These words use a temporary structure built
on the return stack, and after windows is through with the
data, the structure is automatically discarded.

DefineClass builds a WNDCLASS structure with the 10 parameters
supplied and registers the class.

DefaultClass builds a WNDCLASS structure with the user specified
values for the class name and the callback address, simple default
values for the other parameters, and registers the class.
-------------------------------------------------------------------- }

?( ... DefineClass and DefaultClass)

: DefineClass ( style callback xclass xwin inst icon cursor brush menu name -- hclass )
   10 CELLS R-ALLOC  0 9 DO ( ... a )
      TUCK  I CELLS + !
   -1 +LOOP RegisterClass ;

: DefaultClass ( zname callback -- hclass )  SWAP >R >R
      CS_OWNDC                     \    each window in the class has its own DC
      CS_HREDRAW OR
      CS_VREDRAW OR
      R>                           \ the address of the callback to use
      0                            \ extra bytes for the class
      0                            \ extra bytes for each window in the class
      HINST                        \ instance value of the executing program
      HINST 101 LoadIcon           \ handle of the icon to represent it
      NULL IDC_ARROW LoadCursor    \ the default cursor
      WHITE_BRUSH GetStockObject   \ the default background brush
      0                            \ no menu
      R>                           \ class name
   DefineClass ;
