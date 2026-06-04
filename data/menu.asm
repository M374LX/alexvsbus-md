DATA_menu_titles:
	; A "-" as the first character means that the menu type has no title
	dc.b    "-                               "
	dc.b    "             PAUSE              "
	dc.b    "       DIFFICULTY SELECT        "
	dc.b    "          LEVEL SELECT          "
	dc.b    "          LEVEL SELECT          "
	dc.b    "            JUKEBOX             "
	dc.b    "          CONFIRMATION          "
	dc.b    "          CONFIRMATION          "
	dc.b    "          CONFIRMATION          "
	dc.b    "             ABOUT              "
	dc.b    "            CREDITS             "

DATA_menu_texts:
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    0
	dc.w    (DATA_menu_text_about-DATA_menu_texts)
	dc.w    (DATA_menu_text_credits-DATA_menu_texts)

DATA_menu_text_about:
	dc.w    $0202
	dc.b    $1B, "Alex vs Bus: The Race (MD port)", $0A
	dc.b    $7F, " 2021-2026 M374LX", $0A ; $7F = copyright symbol
	dc.b    $0A 
	dc.b    $1B, "Release", $0A
	dc.b    " pre2", $0A
	dc.b    $0A
	dc.b    $1B, "Repository", $0A
	dc.b    " github.com/M374LX/alexvsbus-md", $0A
	dc.b    $0A
	dc.b    $1B, "Licenses", $0A
	dc.b    " The code is under GNU GPLv3, while", $0A
	dc.b    " the assets are under CC BY-SA 4.0.", $0A
	dc.b    $0A
	dc.b    " www.gnu.org/licenses/gpl-3.0.en.html", $0A
	dc.b    " creativecommons.org/licenses/by-sa/4.0", 0
	even

DATA_menu_text_credits:
	dc.w    $0202
	dc.b    $1B, "M374LX", $0A
	dc.b    " Game design, programming,", $0A
	dc.b    " music, SFX, graphics", $0A
	dc.b    $0A
	dc.b    $1B, "Hoton Bastos", $0A
	dc.b    " Additional game design", $0A
	dc.b    $0A
	dc.b    $1B, "Harim Pires", $0A
	dc.b    " Testing", $0A
	dc.b    $0A
	dc.b    $1B, "Codeman38", $0A
	dc.b    ' "Press Start 2P" font', $0A
	dc.b    $0A
	dc.b    $1B, "YoWorks", $0A
	dc.b    ' "Telegrama" font', 0
	even

DATA_menu_items:
	dc.w    2, (DATA_menu_items_main-DATA_menu_items)
	dc.w    2, (DATA_menu_items_pause-DATA_menu_items)
	dc.w    3, (DATA_menu_items_difficulty-DATA_menu_items)
	dc.w    5, (DATA_menu_items_level5-DATA_menu_items)
	dc.w    3, (DATA_menu_items_level3-DATA_menu_items)
	dc.w    4, (DATA_menu_items_jukebox-DATA_menu_items)
	dc.w    1, (DATA_menu_items_restart-DATA_menu_items)
	dc.w    1, (DATA_menu_items_try_again-DATA_menu_items)
	dc.w    1, (DATA_menu_items_quit-DATA_menu_items)
	dc.w    1, (DATA_menu_items_about-DATA_menu_items)
	dc.w    0, (DATA_menu_items_credits-DATA_menu_items)

DATA_menu_items_main:
	dc.b    $08, $20, "PLAY          "
	dc.b    $09, $20, "JUKEBOX       "
	dc.b    $0A, $20, "ABOUT         "

DATA_menu_items_pause:
	dc.b    $05, $A0, "RESUME        "
	dc.b    $06, $A0, "RESTART       "
	dc.b    $07, $A0, "QUIT          "

DATA_menu_items_difficulty:
	dc.b    $05, $20, "NORMAL        "
	dc.b    $06, $20, "HARD          "
	dc.b    $07, $20, "SUPER         "
	dc.b    $08, $20, "RETURN        "

DATA_menu_items_level5:
	dc.b    $04, $A0, "LEVEL 1       "
	dc.b    $05, $A0, "LEVEL 2       "
	dc.b    $06, $A0, "LEVEL 3       "
	dc.b    $07, $A0, "LEVEL 4       "
	dc.b    $08, $A0, "LEVEL 5       "
	dc.b    $09, $A0, "RETURN        "

DATA_menu_items_level3:
	dc.b    $05, $20, "LEVEL 1       "
	dc.b    $06, $20, "LEVEL 2       "
	dc.b    $07, $20, "LEVEL 3       "
	dc.b    $08, $20, "RETURN        "

DATA_menu_items_jukebox:
	dc.b    $04, $A0, "BGM 1         "
	dc.b    $05, $A0, "BGM 2         "
	dc.b    $06, $A0, "BGM 3         "
	dc.b    $07, $A0, "BGM 4         "
	dc.b    $08, $A0, "RETURN        "

DATA_menu_items_restart:
	dc.b    $06, $20, "RESTART       "
	dc.b    $07, $20, "CANCEL        "

DATA_menu_items_try_again:
	dc.b    $06, $20, "TRY AGAIN     "
	dc.b    $07, $20, "QUIT          "

DATA_menu_items_quit:
	dc.b    $06, $20, "QUIT          "
	dc.b    $07, $20, "CANCEL        "

DATA_menu_items_about:
	dc.b    $0B, $20, "CREDITS       "
	dc.b    $0C, $20, "RETURN        "

DATA_menu_items_credits:
	dc.b    $0C, $20, "RETURN        "

