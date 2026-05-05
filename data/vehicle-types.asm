DATA_vehicle_types:
	; Type 0 - None
	dc.w 0     ; Palette and priority
	dc.b 0     ; Initial screen line
	dc.b 0     ; Number of screen lines
	dc.b 0     ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 1 - Parked car (blue)
	dc.w $E000 ; Palette and priority
	dc.b 16-26 ; Initial screen line
	dc.b 7     ; Number of screen lines
	dc.b 16    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 2 - Parked car (silver)
	dc.w $C000 ; Palette and priority
	dc.b 16-26 ; Initial screen line
	dc.b 7     ; Number of screen lines
	dc.b 16    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 3 - Parked car (yellow)
	dc.w $A000 ; Palette and priority
	dc.b 16-26 ; Initial screen line
	dc.b 7     ; Number of screen lines
	dc.b 16    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 4 - Parked Truck
	dc.w $A000 ; Palette and priority
	dc.b 16-17 ; Initial screen line
	dc.b 16    ; Number of screen lines
	dc.b 35    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 5 - Bus
	dc.w $6000 ; Palette and priority
	dc.b 16-16 ; Initial screen line
	dc.b 15    ; Number of screen lines
	dc.b 50    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 6 - Ending sequence car (blue)
	dc.w $6000 ; Palette and priority
	dc.b 16-23 ; Initial screen line
	dc.b 7     ; Number of screen lines
	dc.b 16    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 7 - Ending sequence car (silver)
	dc.w $4000 ; Palette and priority
	dc.b 16-23 ; Initial screen line
	dc.b 7     ; Number of screen lines
	dc.b 16    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding

	; Type 8 - Ending car (yellow)
	dc.w $2000 ; Palette and priority
	dc.b 16-23 ; Initial screen line
	dc.b 7     ; Number of screen lines
	dc.b 16    ; Width in tiles
	dc.b 0     ; Padding
	dc.w 0     ; Padding



DATA_vehicle_tilemaps:
	dc.l 0                  ; Type 0 - None
	dc.l DATA_tilemap_car   ; Type 1 - Parked car (blue)
	dc.l DATA_tilemap_car   ; Type 2 - Parked car (silver)
	dc.l DATA_tilemap_car   ; Type 3 - Parked car (yellow)
	dc.l DATA_tilemap_truck ; Type 4 - Parked truck
	dc.l DATA_tilemap_bus   ; Type 5 - Bus
	dc.l DATA_tilemap_car   ; Type 6 - Ending car (blue)
	dc.l DATA_tilemap_car   ; Type 7 - Ending car (silver)
	dc.l DATA_tilemap_car   ; Type 8 - Ending car (yellow)

