;
; Alex vs Bus (MD port)
; Copyright (C) 2021-2026 M374LX
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.
;

;
; File:
; ram.asm
;
; Description:
; Definition of RAM locations
;

; ------------------------------------------------------------------------------

; RAM area where frame rate-dependent values are kept
RAM_fpsvals:                    equ $FFFFD000

; RAM area used by the sound system
RAM_sound:                      equ $FFFFE000

RAM_joystate_down:              equ $FFFF8000
RAM_joystate_hit:               equ $FFFF8002
RAM_screen_type:                equ $FFFF8004
RAM_screen_type_next:           equ $FFFF8005
RAM_vtimer:                     equ $FFFF8006
RAM_wait_input_up:              equ $FFFF800A
RAM_delayed_action_type:        equ $FFFF800B
RAM_action_delay:               equ $FFFF800C

RAM_score:                      equ $FFFF8010
RAM_score_add:                  equ $FFFF8014
RAM_difficulty:                 equ $FFFF8018
RAM_level_num:                  equ $FFFF8019
RAM_progress_checked:           equ $FFFF801A
RAM_progress_difficulty:        equ $FFFF801B
RAM_progress_level:             equ $FFFF801C
RAM_progress_cheat_enabled:     equ $FFFF801D
RAM_progress_cheat_pos:         equ $FFFF801E

; Set if a wipe effect is happening and the VDP is not locked for Hint
RAM_wipe_enabled:               equ $FFFF8020

RAM_wipe_cmd:                   equ $FFFF8021
RAM_wipe_value:                 equ $FFFF8022
RAM_wipe_delta:                 equ $FFFF8023
RAM_wipe_delay:                 equ $FFFF8024

RAM_menu_type:                  equ $FFFF8030
RAM_menu_type_prev:             equ $FFFF8031
RAM_menu_selected_item:         equ $FFFF8032
RAM_menu_selected_item_prev:    equ $FFFF8033
RAM_menu_last_item:             equ $FFFF8034
RAM_menu_last_item_prev:        equ $FFFF8035
RAM_menu_disabled_items:        equ $FFFF8036
RAM_menu_action:                equ $FFFF8037
RAM_menu_stack_size:            equ $FFFF8038

; The flags are:
; 0 - Level selected
; 1 - Selected level menu item hidden
RAM_menu_flags:                 equ $FFFF8039
RAM_menu_flags_prev:            equ $FFFF803A

; 8 entries; two bytes per entry; the first byte is the menu type and the
; second byte is the selected item
RAM_menu_stack:                 equ $FFFF8040

; Number to string conversion buffer (8 bytes)
RAM_num_str_buffer:             equ $FFFF8080

RAM_sprite_buffer_next_offs:    equ $FFFF8088
RAM_sprite_buffer_free_slots:   equ $FFFF808A

; Bits 0-1 determine the redraw mode, while bit 2 is set if the right column,
; rather the left one, needs to be redrawn
;
; The redraw modes are:
; 0 - No redraw
; 1 - Redraw only vehicles
; 2 - Redraw one level column
; 3 - Full redraw
RAM_redraw_mode:                equ $FFFF80B0

; Simple flag to force a full redraw
RAM_force_full_redraw:          equ $FFFF80B1

RAM_level_block_buffer:         equ $FFFF8100
RAM_vehicle_buffer:             equ $FFFF8800
RAM_sprite_buffer:              equ $FFFF8A00

RAM_col32:                      equ $FFFF8E00
RAM_col32_prev:                 equ $FFFF8E02
RAM_col32_tiles:                equ $FFFF8E04
RAM_col24:                      equ $FFFF8E06
RAM_draw_col_tiles:             equ $FFFF8E08
RAM_draw_col_plane:             equ $FFFF8E0A

RAM_draw_offset_x:              equ $FFFF8E0C
RAM_draw_offset_y:              equ $FFFF8E0E

; RAM area that is cleared when starting a level
RAM_play_clear_start:           equ $FFFF9000
RAM_play_clear_end:             equ $FFFF99FF

RAM_play_input_down:            equ $FFFF9000
RAM_play_input_hit:             equ $FFFF9001
RAM_jump_timeout:               equ $FFFF9002

; The flags are:
; 0 - Ignore user input
; 1 - Time running
; 2 - Time up
; 3 - Goal reached
; 4 - Counting score
; 5 - Can pause
; 6 - Is last level
; 7 - Is ending sequence
RAM_play_flags:                 equ $FFFF9003

RAM_time:                       equ $FFFF9004
RAM_time_delay:                 equ $FFFF9005

; Bitfield with the passageways whose exits have been opened
RAM_passageway_opened_exits:    equ $FFFF9006

RAM_cur_passageway:             equ $FFFF9007

RAM_hit_spring:                 equ $FFFF9008

RAM_bus_stop_sign1_x:           equ $FFFF900A
RAM_bus_stop_sign2_x:           equ $FFFF900C

RAM_level_size_pixels:          equ $FFFF9010
RAM_level_sky_color:            equ $FFFF9012
RAM_level_bgm:                  equ $FFFF9013
RAM_level_goal_scene:           equ $FFFF9014
RAM_num_coins:                  equ $FFFF9015
RAM_num_banana_peels:           equ $FFFF9016
RAM_num_gushes:                 equ $FFFF9017
RAM_num_overhead_signs:         equ $FFFF9018
RAM_num_parked_vehicles:        equ $FFFF9019
RAM_num_respawn_points:         equ $FFFF901A
RAM_num_ropes:                  equ $FFFF901B
RAM_num_solids:                 equ $FFFF901C
RAM_num_springs:                equ $FFFF901D
RAM_num_triggers:               equ $FFFF901E

RAM_ptr_level_columns:          equ $FFFF9020
RAM_ptr_overhead_signs:         equ $FFFF9024
RAM_ptr_parked_vehicles:        equ $FFFF9028
RAM_ptr_passageways:            equ $FFFF902C
RAM_ptr_respawn_points:         equ $FFFF9030
RAM_ptr_ropes:                  equ $FFFF9034
RAM_ptr_springs:                equ $FFFF9038
RAM_ptr_level_solids:           equ $FFFF903C
RAM_ptr_next_trigger:           equ $FFFF9040

RAM_next_coin_spark:            equ $FFFF9044
RAM_next_crack_particle:        equ $FFFF9045
RAM_crate_push_remaining:       equ $FFFF9046

RAM_sequence_delay:             equ $FFFF9047
RAM_sequence_step:              equ $FFFF9048

; The flags are:
; 0 - Skip initial sequence
; 1 - Wipe in
; 2 - Wipe out
; 3 - Player character reached flagman
; 4 - Hen reached flagman
; 5 - Bus reached flagman
RAM_sequence_flags:             equ $FFFF9049

RAM_camera_x:                   equ $FFFF9050
RAM_camera_y:                   equ $FFFF9054
RAM_camera_xmax:                equ $FFFF9058
RAM_camera_follow_player:       equ $FFFF905A
RAM_camera_xvel:                equ $FFFF9060
RAM_camera_yvel:                equ $FFFF9064
RAM_camera_xdest:               equ $FFFF9068

RAM_player_x:                   equ $FFFF9070
RAM_player_y:                   equ $FFFF9074
RAM_player_xvel:                equ $FFFF9078
RAM_player_yvel:                equ $FFFF907C
RAM_player_acc:                 equ $FFFF9080
RAM_player_dec:                 equ $FFFF9084
RAM_player_grav:                equ $FFFF9088
RAM_player_state:               equ $FFFF908C

; The flags are:
; 0 - Visible
; 1 - On floor
; 2 - Fell
RAM_player_flags:               equ $FFFF908D

RAM_player_anim_type:           equ $FFFF908E
RAM_player_flicker_delay:       equ $FFFF908F
RAM_player_height:              equ $FFFF9090
RAM_player_old_x:               equ $FFFF9092
RAM_player_old_y:               equ $FFFF9096
RAM_player_old_state:           equ $FFFF909A
RAM_player_old_anim_type:       equ $FFFF909B

RAM_bus_x:                      equ $FFFF90A0
RAM_bus_xvel:                   equ $FFFF90A4
RAM_bus_acc:                    equ $FFFF90A8
RAM_bus_init_x:                 equ $FFFF90AC
RAM_bus_route_sign:             equ $FFFF90AE
RAM_bus_num_characters:         equ $FFFF90AF

RAM_grabbed_rope_x:             equ $FFFF90B0
RAM_grabbed_rope_xvel:          equ $FFFF90B4
RAM_grabbed_rope_xmin:          equ $FFFF90B8
RAM_grabbed_rope_xmax:          equ $FFFF90BA
RAM_grabbed_rope_index:         equ $FFFF90BC

RAM_passing_car_x:              equ $FFFF90C0
RAM_passing_car_peel_throw_x:   equ $FFFF90C4
RAM_passing_car_color:          equ $FFFF90C6
RAM_passing_car_threw_peel:     equ $FFFF90C7

RAM_hen_x:                      equ $FFFF90D0
RAM_hen_xvel:                   equ $FFFF90D4
RAM_hen_acc:                    equ $FFFF90D8

RAM_push_arrow_xoffs:           equ $FFFF90E0
RAM_push_arrow_xvel:            equ $FFFF90E4
RAM_push_arrow_delay:           equ $FFFF90E8

; 28 animations, 8 bytes each (224 bytes in total), with the following
; properties:
;
; current frame (B)
; last frame (B)
; delay (B)
; maximum delay (B)
; flags (B) - 0 = running, 1 = reverse, 2 = loop
RAM_anims:                      equ $FFFF9100

; 128 coins, 4 bytes each (512 bytes in total), with the following properties:
;
; x (W)
; y/gold (W) - bits 0-14 for position and bit 15 to determine if it is silver or gold
RAM_coins:                      equ $FFFF9200

; RAM area for banana peels that are not moving, with 48 peels, 4 bytes each
; (192 bytes in total), with the following properties:
;
; x (W)
; y (W)
RAM_banana_peels:               equ $FFFF9400

; Two moving banana peels, 32 bytes each (64 bytes in total), with the following
; properties:
;
; x (L)
; y (L)
; xvel (L)
; yvel (L)
; grav (L)
; xdest (W)
; ydest (W)
RAM_moving_peels:               equ $FFFF94C0

; 16 coin sparks, 4 bytes each (64 bytes in total), with the following
; properties:
;
; x (W)
; y/gold (W) - bits 0-8 for position and bit 15 to determine if it is silver or gold
RAM_coin_sparks:                equ $FFFF9500

; 16 entries, 16 bytes each (256 bytes in total), with the following properties:
;
; x (L)
; y (L)
; xvel (L)
; yvel (L)
RAM_crack_particles:            equ $FFFF9600

; 32 entries, 16 bytes each (512 bytes in total), with the following properties:
;
; x (W)
; y (L)
; yvel (L)
; ydest (W)
; move_pattern_index (B)
; move_pattern_pos (B)
; is_crack (B)
RAM_gushes:                     equ $FFFF9700

; 4 entries, 8 bytes each (32 bytes in total), with the following properties:
;
; x (L)
; xmax (W)
; flags (B)
RAM_pushable_crates:            equ $FFFF9900

; 4 entries, 16 bytes each (64 bytes in total)
RAM_pushable_crate_solids:      equ $FFFF9920

; 2 entries, 32 bytes each (64 bytes in total), with the following properties:
;
; type (B)
; in_bus (B)
; x (L)
; y (L)
; xvel (L)
; yvel (L)
; acc (L)
; grav (L)
RAM_cutscene_objs:              equ $FFFF9960

