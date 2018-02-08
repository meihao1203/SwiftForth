{ ====================================================================
Common dialog constants

Copyright 2001  FORTH, Inc.
==================================================================== }

OPTIONAL COMDLG-CONSTANTS

{ --------------------------------------------------------------------
Extend the dialog compiler just a little
We need a dialog type for ofn child controls and the
stb32 constant to tell the ofn dialog to resize properly
-------------------------------------------------------------------- }

$045f CONSTANT stb32

$0400 CONSTANT ctlFirst
$04ff CONSTANT ctlLast

\
\  Push buttons.
\
$0400 CONSTANT psh1
$0401 CONSTANT psh2
$0402 CONSTANT psh3
$0403 CONSTANT psh4
$0404 CONSTANT psh5
$0405 CONSTANT psh6
$0406 CONSTANT psh7
$0407 CONSTANT psh8
$0408 CONSTANT psh9
$0409 CONSTANT psh10
$040a CONSTANT psh11
$040b CONSTANT psh12
$040c CONSTANT psh13
$040d CONSTANT psh14
$040e CONSTANT psh15
psh15 CONSTANT pshHelp
$040f CONSTANT psh16

\
\  Checkboxes.
\
$0410 CONSTANT chx1
$0411 CONSTANT chx2
$0412 CONSTANT chx3
$0413 CONSTANT chx4
$0414 CONSTANT chx5
$0415 CONSTANT chx6
$0416 CONSTANT chx7
$0417 CONSTANT chx8
$0418 CONSTANT chx9
$0419 CONSTANT chx10
$041a CONSTANT chx11
$041b CONSTANT chx12
$041c CONSTANT chx13
$041d CONSTANT chx14
$041e CONSTANT chx15
$041f CONSTANT chx16

\
\  Radio buttons.
\
$0420 CONSTANT rad1
$0421 CONSTANT rad2
$0422 CONSTANT rad3
$0423 CONSTANT rad4
$0424 CONSTANT rad5
$0425 CONSTANT rad6
$0426 CONSTANT rad7
$0427 CONSTANT rad8
$0428 CONSTANT rad9
$0429 CONSTANT rad10
$042a CONSTANT rad11
$042b CONSTANT rad12
$042c CONSTANT rad13
$042d CONSTANT rad14
$042e CONSTANT rad15
$042f CONSTANT rad16

\
\ Groups, frames, rectangles, and icons.
\
$0430 CONSTANT grp1
$0431 CONSTANT grp2
$0432 CONSTANT grp3
$0433 CONSTANT grp4
$0434 CONSTANT frm1
$0435 CONSTANT frm2
$0436 CONSTANT frm3
$0437 CONSTANT frm4
$0438 CONSTANT rct1
$0439 CONSTANT rct2
$043a CONSTANT rct3
$043b CONSTANT rct4
$043c CONSTANT ico1
$043d CONSTANT ico2
$043e CONSTANT ico3
$043f CONSTANT ico4

\
\  Static text.
\
$0440 CONSTANT stc1
$0441 CONSTANT stc2
$0442 CONSTANT stc3
$0443 CONSTANT stc4
$0444 CONSTANT stc5
$0445 CONSTANT stc6
$0446 CONSTANT stc7
$0447 CONSTANT stc8
$0448 CONSTANT stc9
$0449 CONSTANT stc10
$044a CONSTANT stc11
$044b CONSTANT stc12
$044c CONSTANT stc13
$044d CONSTANT stc14
$044e CONSTANT stc15
$044f CONSTANT stc16
$0450 CONSTANT stc17
$0451 CONSTANT stc18
$0452 CONSTANT stc19
$0453 CONSTANT stc20
$0454 CONSTANT stc21
$0455 CONSTANT stc22
$0456 CONSTANT stc23
$0457 CONSTANT stc24
$0458 CONSTANT stc25
$0459 CONSTANT stc26
$045a CONSTANT stc27
$045b CONSTANT stc28
$045c CONSTANT stc29
$045d CONSTANT stc30
$045e CONSTANT stc31
$045f CONSTANT stc32

\
\  Listboxes.
\
$0460 CONSTANT lst1
$0461 CONSTANT lst2
$0462 CONSTANT lst3
$0463 CONSTANT lst4
$0464 CONSTANT lst5
$0465 CONSTANT lst6
$0466 CONSTANT lst7
$0467 CONSTANT lst8
$0468 CONSTANT lst9
$0469 CONSTANT lst10
$046a CONSTANT lst11
$046b CONSTANT lst12
$046c CONSTANT lst13
$046d CONSTANT lst14
$046e CONSTANT lst15
$046f CONSTANT lst16

\
\  Combo boxes.
\
$0470 CONSTANT cmb1
$0471 CONSTANT cmb2
$0472 CONSTANT cmb3
$0473 CONSTANT cmb4
$0474 CONSTANT cmb5
$0475 CONSTANT cmb6
$0476 CONSTANT cmb7
$0477 CONSTANT cmb8
$0478 CONSTANT cmb9
$0479 CONSTANT cmb10
$047a CONSTANT cmb11
$047b CONSTANT cmb12
$047c CONSTANT cmb13
$047d CONSTANT cmb14
$047e CONSTANT cmb15
$047f CONSTANT cmb16

\
\  Edit controls.
\
$0480 CONSTANT edt1
$0481 CONSTANT edt2
$0482 CONSTANT edt3
$0483 CONSTANT edt4
$0484 CONSTANT edt5
$0485 CONSTANT edt6
$0486 CONSTANT edt7
$0487 CONSTANT edt8
$0488 CONSTANT edt9
$0489 CONSTANT edt10
$048a CONSTANT edt11
$048b CONSTANT edt12
$048c CONSTANT edt13
$048d CONSTANT edt14
$048e CONSTANT edt15
$048f CONSTANT edt16

\
\  Scroll bars.
\
$0490 CONSTANT scr1
$0491 CONSTANT scr2
$0492 CONSTANT scr3
$0493 CONSTANT scr4
$0494 CONSTANT scr5
$0495 CONSTANT scr6
$0496 CONSTANT scr7
$0497 CONSTANT scr8
