FPSVALS_SIZE:                   equ 200

FPSVAL_0_S:                     equ RAM_fpsvals+$00
FPSVAL_1_S:                     equ RAM_fpsvals+$01
FPSVAL_2_S:                     equ RAM_fpsvals+$02
FPSVAL_3_S:                     equ RAM_fpsvals+$03
FPSVAL_4_S:                     equ RAM_fpsvals+$04
FPSVAL_0_1_S:                   equ RAM_fpsvals+$05
FPSVAL_0_2_S:                   equ RAM_fpsvals+$06
FPSVAL_0_5_S:                   equ RAM_fpsvals+$07
FPSVAL_0_7_S:                   equ RAM_fpsvals+$08
FPSVAL_0_02_S:                  equ RAM_fpsvals+$09
FPSVAL_0_05_S:                  equ RAM_fpsvals+$0A
FPSVAL_6_PXS:                   equ RAM_fpsvals+$0C
FPSVAL_15_PXS:                  equ RAM_fpsvals+$10
FPSVAL_30_PXS:                  equ RAM_fpsvals+$14
FPSVAL_60_PXS:                  equ RAM_fpsvals+$18
FPSVAL_72_PXS:                  equ RAM_fpsvals+$1C
FPSVAL_84_PXS:                  equ RAM_fpsvals+$20
FPSVAL_120_PXS:                 equ RAM_fpsvals+$24
FPSVAL_126_PXS:                 equ RAM_fpsvals+$28
FPSVAL_132_PXS:                 equ RAM_fpsvals+$2C
FPSVAL_144_PXS:                 equ RAM_fpsvals+$30
FPSVAL_150_PXS:                 equ RAM_fpsvals+$34
FPSVAL_180_PXS:                 equ RAM_fpsvals+$38
FPSVAL_204_PXS:                 equ RAM_fpsvals+$3C
FPSVAL_210_PXS:                 equ RAM_fpsvals+$40
FPSVAL_252_PXS:                 equ RAM_fpsvals+$44
FPSVAL_258_PXS:                 equ RAM_fpsvals+$48
FPSVAL_300_PXS:                 equ RAM_fpsvals+$4C
FPSVAL_360_PXS:                 equ RAM_fpsvals+$50
FPSVAL_408_PXS:                 equ RAM_fpsvals+$54
FPSVAL_720_PXS:                 equ RAM_fpsvals+$58
FPSVAL_1200_PXS:                equ RAM_fpsvals+$5C
FPSVAL_M6_PXS:                  equ RAM_fpsvals+$60
FPSVAL_M12_PXS:                 equ RAM_fpsvals+$64
FPSVAL_M15_PXS:                 equ RAM_fpsvals+$68
FPSVAL_M24_PXS:                 equ RAM_fpsvals+$6C
FPSVAL_M30_PXS:                 equ RAM_fpsvals+$70
FPSVAL_M60_PXS:                 equ RAM_fpsvals+$74
FPSVAL_M90_PXS:                 equ RAM_fpsvals+$78
FPSVAL_M102_PXS:                equ RAM_fpsvals+$7C
FPSVAL_M120_PXS:                equ RAM_fpsvals+$80
FPSVAL_M144_PXS:                equ RAM_fpsvals+$84
FPSVAL_M150_PXS:                equ RAM_fpsvals+$88
FPSVAL_M156_PXS:                equ RAM_fpsvals+$8C
FPSVAL_M162_PXS:                equ RAM_fpsvals+$90
FPSVAL_M192_PXS:                equ RAM_fpsvals+$94
FPSVAL_M204_PXS:                equ RAM_fpsvals+$98
FPSVAL_M246_PXS:                equ RAM_fpsvals+$9C
FPSVAL_M408_PXS:                equ RAM_fpsvals+$A0
FPSVAL_M720_PXS:                equ RAM_fpsvals+$A4
FPSVAL_M510_PXS:                equ RAM_fpsvals+$A8
FPSVAL_198_PXSS:                equ RAM_fpsvals+$AC
FPSVAL_216_PXSS:                equ RAM_fpsvals+$B0
FPSVAL_234_PXSS:                equ RAM_fpsvals+$B4
FPSVAL_252_PXSS:                equ RAM_fpsvals+$B8
FPSVAL_504_PXSS:                equ RAM_fpsvals+$BC
FPSVAL_M216_PXSS:               equ RAM_fpsvals+$C0
FPSVAL_M252_PXSS:               equ RAM_fpsvals+$C4

DATA_fps_values_ntsc:
	dc.b    0               ;    0 s
	dc.b    60              ;    1 s
	dc.b    120             ;    2 s
	dc.b    180             ;    3 s
	dc.b    240             ;    4 s
	dc.b    6               ;  0.1 s
	dc.b    12              ;  0.2 s
	dc.b    30              ;  0.5 s
	dc.b    42              ;  0.7 s
	dc.b    1               ; 0.02 s
	dc.b    3               ; 0.05 s
	dc.b    0               ; (Padding)
	dc.l    6553            ;    6 px/s
	dc.l    16384           ;   15 px/s
	dc.l    32768           ;   30 px/s
	dc.l    65536           ;   60 px/s
	dc.l    78643           ;   72 px/s
	dc.l    91750           ;   84 px/s
	dc.l    131072          ;  120 px/s
	dc.l    137625          ;  126 px/s
	dc.l    144179          ;  132 px/s
	dc.l    157286          ;  144 px/s
	dc.l    163840          ;  150 px/s
	dc.l    196608          ;  180 px/s
	dc.l    222822          ;  204 px/s
	dc.l    229376          ;  210 px/s
	dc.l    275251          ;  252 px/s
	dc.l    281804          ;  258 px/s
	dc.l    327680          ;  300 px/s
	dc.l    393216          ;  360 px/s
	dc.l    445644          ;  408 px/s
	dc.l    786432          ;  720 px/s
	dc.l    1310720         ; 1200 px/s
	dc.l    -6553           ;   -6 px/s
	dc.l    -13107          ;  -12 px/s
	dc.l    -16384          ;  -15 px/s
	dc.l    -26214          ;  -24 px/s
	dc.l    -32768          ;  -30 px/s
	dc.l    -65536          ;  -60 px/s
	dc.l    -98304          ;  -90 px/s
	dc.l    -111411         ; -102 px/s
	dc.l    -131072         ; -120 px/s
	dc.l    -157286         ; -144 px/s
	dc.l    -163840         ; -150 px/s
	dc.l    -170393         ; -156 px/s
	dc.l    -176947         ; -162 px/s
	dc.l    -209715         ; -192 px/s
	dc.l    -222822         ; -204 px/s
	dc.l    -268697         ; -246 px/s
	dc.l    -445644         ; -408 px/s
	dc.l    -786432         ; -720 px/s
	dc.l    -557056         ; -510 px/s
	dc.l    3604            ;  198 px/ss
	dc.l    3932            ;  216 px/ss
	dc.l    4259            ;  234 px/ss
	dc.l    4587            ;  252 px/ss
	dc.l    9175            ;  504 px/ss
	dc.l    -3932           ; -216 px/ss
	dc.l    -4587           ; -252 px/ss
	even

DATA_fps_values_pal:
	dc.b    0               ;    0 s
	dc.b    50              ;    1 s
	dc.b    100             ;    2 s
	dc.b    150             ;    3 s
	dc.b    200             ;    4 s
	dc.b    5               ;  0.1 s
	dc.b    10              ;  0.2 s
	dc.b    25              ;  0.5 s
	dc.b    35              ;  0.7 s
	dc.b    1               ; 0.02 s
	dc.b    2               ; 0.05 s
	dc.b    0               ; (Padding)
	dc.l    7864            ;    6 px/s
	dc.l    19660           ;   15 px/s
	dc.l    39321           ;   30 px/s
	dc.l    78643           ;   60 px/s
	dc.l    94371           ;   72 px/s
	dc.l    110100          ;   84 px/s
	dc.l    157286          ;  120 px/s
	dc.l    165150          ;  126 px/s
	dc.l    173015          ;  132 px/s
	dc.l    188743          ;  144 px/s
	dc.l    196608          ;  150 px/s
	dc.l    235929          ;  180 px/s
	dc.l    267386          ;  204 px/s
	dc.l    275251          ;  210 px/s
	dc.l    330301          ;  252 px/s
	dc.l    338165          ;  258 px/s
	dc.l    393216          ;  300 px/s
	dc.l    471859          ;  360 px/s
	dc.l    534773          ;  408 px/s
	dc.l    943718          ;  720 px/s
	dc.l    1572864         ; 1200 px/s
	dc.l    -7864           ;   -6 px/s
	dc.l    -15728          ;  -12 px/s
	dc.l    -19660          ;  -15 px/s
	dc.l    -31457          ;  -24 px/s
	dc.l    -39321          ;  -30 px/s
	dc.l    -78643          ;  -60 px/s
	dc.l    -117964         ;  -90 px/s
	dc.l    -133693         ; -102 px/s
	dc.l    -157286         ; -120 px/s
	dc.l    -188743         ; -144 px/s
	dc.l    -196608         ; -150 px/s
	dc.l    -204472         ; -156 px/s
	dc.l    -212336         ; -162 px/s
	dc.l    -251658         ; -192 px/s
	dc.l    -267386         ; -204 px/s
	dc.l    -322437         ; -246 px/s
	dc.l    -534773         ; -408 px/s
	dc.l    -943718         ; -720 px/s
	dc.l    -668467         ; -510 px/s
	dc.l    5190            ;  198 px/ss
	dc.l    5662            ;  216 px/ss
	dc.l    6134            ;  234 px/ss
	dc.l    6606            ;  252 px/ss
	dc.l    13212           ;  504 px/ss
	dc.l    -5662           ; -216 px/ss
	dc.l    -6606           ; -252 px/ss
	even

