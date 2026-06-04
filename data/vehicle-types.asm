; Data about vehicle types, with eight bytes per entry in the following
; format:
;
; +$00 W - Palette number and priority
; +$02 B - Initial screen line
; +$03 B - Number of screen lines
; +$04 B - Width in tiles
;
DATA_vehicle_types:
	; Type 0 - None
	dc.w    0
	dc.b    0
	dc.b    0
	dc.b    0
	dc.b    0
	dc.w    0

	; Type 1 - Parked car (blue)
	dc.w    $E000
	dc.b    16-26
	dc.b    7
	dc.b    16
	dc.b    0
	dc.w    0

	; Type 2 - Parked car (silver)
	dc.w    $C000
	dc.b    16-26
	dc.b    7
	dc.b    16
	dc.b    0
	dc.w    0

	; Type 3 - Parked car (yellow)
	dc.w    $A000
	dc.b    16-26
	dc.b    7
	dc.b    16
	dc.b    0
	dc.w    0

	; Type 4 - Parked Truck
	dc.w    $A000
	dc.b    16-17
	dc.b    16
	dc.b    35
	dc.b    0
	dc.w    0

	; Type 5 - Bus
	dc.w    $6000
	dc.b    16-16
	dc.b    15
	dc.b    50
	dc.b    0
	dc.w    0

	; Type 6 - Ending sequence car (blue)
	dc.w    $6000
	dc.b    16-23
	dc.b    7
	dc.b    16
	dc.b    0
	dc.w    0

	; Type 7 - Ending sequence car (silver)
	dc.w    $4000
	dc.b    16-23
	dc.b    7
	dc.b    16
	dc.b    0
	dc.w    0

	; Type 8 - Ending car (yellow)
	dc.w    $2000
	dc.b    16-23
	dc.b    7
	dc.b    16
	dc.b    0
	dc.w    0

DATA_vehicle_tilemaps:
	dc.l    0                  ; Type 0 - None
	dc.l    DATA_tilemap_car   ; Type 1 - Parked car (blue)
	dc.l    DATA_tilemap_car   ; Type 2 - Parked car (silver)
	dc.l    DATA_tilemap_car   ; Type 3 - Parked car (yellow)
	dc.l    DATA_tilemap_truck ; Type 4 - Parked truck
	dc.l    DATA_tilemap_bus   ; Type 5 - Bus
	dc.l    DATA_tilemap_car   ; Type 6 - Ending car (blue)
	dc.l    DATA_tilemap_car   ; Type 7 - Ending car (silver)
	dc.l    DATA_tilemap_car   ; Type 8 - Ending car (yellow)

