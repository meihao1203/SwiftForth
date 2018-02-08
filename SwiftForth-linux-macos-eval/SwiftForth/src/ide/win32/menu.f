{ ====================================================================
Main window menu

Copyright (C) 2001 FORTH, Inc.
Rick VanNorman

==================================================================== }

?( Main window menu)

{ ----------------------------------------------------------------------
This is the main swiftforth menu template.
---------------------------------------------------------------------- }

MENU FORTH-MENU

   POPUP "&File"
      MI_INCLUDE      MENUITEM "&Include"
      MI_EDIT         MENUITEM "&Edit"
      MI_PRINT        MENUITEM "&Print"
                      SEPARATOR
      MI_SAVECOMMAND  MENUITEM "Save &Command Window"
      MI_SAVEHISTORY  MENUITEM "Save Keyboard &History"
      MI_LOGGING      MENUITEM "Session &Log"
                      SEPARATOR
      MI_BREAK        MENUITEM "&Break"
                      SEPARATOR
      MI_EXIT         MENUITEM "E&xit"
   END-POPUP

   POPUP "&Edit"
      MI_COPY      MENUITEM "&Copy"
      MI_PASTE     MENUITEM "&Paste"
                   SEPARATOR
      MI_SELALL    MENUITEM "&Select All"
      MI_CLEAR     MENUITEM "&Wipe All"
   END-POPUP

   POPUP "&View"
      MI_SHOWSTAT  MENUITEM "&Status Line"
      MI_SHOWTOOL  MENUITEM "&Toolbar"
   END-POPUP

   POPUP "&Options"
      MI_FONT        MENUITEM "&Font"
      MI_EDITOR      MENUITEM "&Editor"
      MI_PREFS       MENUITEM "&Preferences"
      MI_WARNCFG     MENUITEM "&Warnings"
      MI_MONCFG      MENUITEM "&Include monitoring"
      MI_FPOPTIONS   GRAYITEM "FP&Math Options"
                     SEPARATOR
      MI_SAVEOPTIONS MENUITEM "&Save Options"
   END-POPUP

   POPUP "&Tools"
      MI_WORDS      MENUITEM "&Words"
      MI_WATCH      MENUITEM "W&atch"
      MI_MEMORY     MENUITEM "&Memory"
      MI_HISTORY    MENUITEM "&History"
      MI_RUN        MENUITEM "&Run"
                    SEPARATOR
         POPUP "&Optional packages"
            MI_OPTIONALS    MENUITEM "Generic Options"
            MI_WINOPTIONALS MENUITEM "Win32 Options"
                            SEPARATOR
            MI_SAMPLES      MENUITEM "Generic Samples"
            MI_WINSAMPLES   MENUITEM "Win32 Samples"
         END-POPUP
   END-POPUP

   POPUP "&Help"
      MI_APIHELP      MENUITEM "&Windows API Help"
      MI_MSDN         MENUITEM "&MSDN Windows API Reference"
                      SEPARATOR
      MI_HANDBOOK     MENUITEM "Forth &Programmer's Handbook"
      MI_USERMANUAL   MENUITEM "&SwiftForth Reference Manual"
      MI_ANSMAN       MENUITEM "ANS &Forth Standard"
      MI_ONLINE       MENUITEM "SwiftForth Programming &References"
                      SEPARATOR
      MI_VERSIONS     MENUITEM "Release &History"
      MI_ABOUT        MENUITEM "&About SwiftForth"
   END-POPUP

END-MENU
