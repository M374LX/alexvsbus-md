/*
 * level-conv
 * Copyright (C) 2026 M374LX
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 */

#include <ctype.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LEVEL_BLOCK_SIZE 24

//Maximum numbers
#define MAX_COLUMNS 480
#define MAX_COINS 128
#define MAX_OBJS 64
#define MAX_OVERHEAD_SIGNS 8
#define MAX_PARKED_VEHICLES 64
#define MAX_PASSAGEWAYS 4
#define MAX_RESPAWN_POINTS 32
#define MAX_TRIGGERS 8
#define MAX_SOLIDS 96

//Objects with a fixed Y position
#define GUSH_CRACK_Y 260
#define GUSH_INITIAL_Y 232
#define HYDRANT_Y 240
#define PARKED_CAR_Y 208
#define PARKED_TRUCK_Y 136
#define ROPE_Y 144
#define PUSHABLE_CRATE_Y 240

//Level column types
enum {
	LVLCOL_NORMAL_FLOOR = 0,
	LVLCOL_DEEP_HOLE_LEFT = 1,
	LVLCOL_DEEP_HOLE_MIDDLE = 2,
	LVLCOL_DEEP_HOLE_RIGHT = 3,
	LVLCOL_PASSAGEWAY_LEFT = 4,
	LVLCOL_PASSAGEWAY_MIDDLE = 5,
	LVLCOL_PASSAGEWAY_RIGHT = 6,
};

//Object types
enum {
	OBJ_NULL = 0,
	OBJ_BANANA_PEEL = 1,
	OBJ_GUSH = 2,
	OBJ_GUSH_CRACK = 3,
	OBJ_PUSH_CRATE = 4,
	OBJ_PUSH_CRATE_WITH_ARROW = 5,
	OBJ_ROPE = 6,
	OBJ_SPRING = 7,
};

//Parked vehicle types
enum {
	PARKED_NONE = 0,
	PARKED_CAR_BLUE = 1,
	PARKED_CAR_SILVER = 2,
	PARKED_CAR_YELLOW = 3,
	PARKED_TRUCK = 4,
};

//What can be triggered
enum {
	TRIGGER_CAR_BLUE = 0,
	TRIGGER_CAR_SILVER = 1,
	TRIGGER_CAR_YELLOW = 2,
	TRIGGER_HEN = 3,
};

//Solid types
enum {
	SOL_FULL = 0,
	SOL_VERTICAL = 1,
	SOL_SLOPE_UP = 2,
	SOL_SLOPE_DOWN = 3,
	SOL_KEEP_ON_TOP = 4,
	SOL_PASSAGEWAY_ENTRY = 5,
	SOL_PASSAGEWAY_EXIT = 6,
};

static uint8_t  level_num;
static char     difficulty;

static uint16_t num_columns;
static uint8_t  sky_color;
static uint8_t  bgm;
static uint8_t  goal_scene;
static uint8_t  num_objs;
static uint8_t  num_coins;
static uint8_t  num_gushes;
static uint8_t  num_gush_cracks;
static uint8_t  num_overhead_signs;
static uint8_t  num_parked_vehicles;
static uint8_t  num_passageways;
static uint8_t  num_respawn_points;
static uint8_t  num_solids;
static uint8_t  num_triggers;

static struct {
	uint16_t type;
	uint16_t num_crates;
	bool     has_hydrant;
	bool     has_rope;
} columns[MAX_COLUMNS];

static struct {
	bool     gold;
	uint16_t x;
	uint16_t y;
} coins[MAX_COINS];

static struct {
	uint16_t type;
	uint16_t x;
	uint16_t y;
} objs[MAX_OBJS];

static struct {
	uint16_t x;
	uint16_t y;
} overhead_signs[MAX_OVERHEAD_SIGNS];

static struct {
	uint16_t type;
	uint16_t x;
} parked_vehicles[MAX_PARKED_VEHICLES];

static struct {
	uint16_t left;
	uint16_t right;
} passageways[MAX_PASSAGEWAYS];

static struct {
	uint16_t x;
	uint16_t y;
} respawn_points[MAX_RESPAWN_POINTS];

static struct {
	uint16_t type;
	uint16_t left;
	uint16_t right;
	uint16_t top;
	uint16_t bottom;
} solids[MAX_SOLIDS];

static struct {
	uint16_t x;
	uint16_t what;
} triggers[MAX_TRIGGERS];

static bool str_starts_with(const char* str, const char* prefix)
{
	return strncmp(str, prefix, strlen(prefix)) == 0;
}

static void find_tokens(const char* str, int* tokens)
{
	int num_tokens = 0;
	int len = strlen(str);
	int i;

	tokens[0] = 0;
	tokens[1] = 0;
	tokens[2] = 0;

	for (i = 1; i < len; i++) {
		if (isdigit(str[i]) && str[i - 1] == ' ') {
			if (num_tokens >= 3) {
				break;
			}

			tokens[num_tokens] = i;
			num_tokens++;
		}
	} 
}

static void add_coin(bool gold, int x, int y)
{
	if (num_coins >= MAX_COINS) {
		return;
	}

	coins[num_coins].gold = gold;
	coins[num_coins].x = x;
	coins[num_coins].y = y;

	num_coins++;
}

static void add_obj(int type, int x, int y)
{
	if (num_objs >= MAX_OBJS) {
		return;
	}

	objs[num_objs].type = type;
	objs[num_objs].x = x;
	objs[num_objs].y = y;

	num_objs++;
}

static void add_parked_vehicle(int type, int x)
{
	if (num_parked_vehicles >= MAX_PARKED_VEHICLES) {
		return;
	}

	parked_vehicles[num_parked_vehicles].type = type;
	parked_vehicles[num_parked_vehicles].x = x;

	num_parked_vehicles++;
}

static void add_deep_hole(int x, int w)
{
	int i;

	for (i = 1; i < w - 1; i++) {
		columns[x + i].type = LVLCOL_DEEP_HOLE_MIDDLE;
	}

	columns[x].type = LVLCOL_DEEP_HOLE_LEFT;
	columns[x + w - 1].type = LVLCOL_DEEP_HOLE_RIGHT;
}

static void add_passageway(int x, int w)
{
	int i;

	if (num_passageways >= MAX_PASSAGEWAYS) {
		return;
	}

	for (i = 1; i < w - 1; i++) {
		columns[x + i].type = LVLCOL_PASSAGEWAY_MIDDLE;
	}

	columns[x].type = LVLCOL_PASSAGEWAY_LEFT;
	columns[x + w - 1].type = LVLCOL_PASSAGEWAY_RIGHT;

	passageways[num_passageways].left  = x * 24;
	passageways[num_passageways].right = (x + w) * 24;
	num_passageways++;
}

static void add_crates(int x, int w, int h)
{
	int i;

	for (i = 0; i < w; i++) {
		columns[x + i].num_crates = h;
	}
}

static void add_horizontal_rope(int x)
{
	int i;

	for (i = 0; i < 16; i++) {
		columns[x + i + 1].has_rope = true;
	}
}

static void add_hydrant(int x)
{
	columns[x].has_hydrant = true;
}

static void add_overhead_sign(int x, int y)
{
	if (num_overhead_signs >= MAX_OVERHEAD_SIGNS) {
		return;
	}

	overhead_signs[num_overhead_signs].x = x;
	overhead_signs[num_overhead_signs].y = y;

	num_overhead_signs++;
}

static void add_respawn_point(int x, int y)
{
	if (num_respawn_points >= MAX_RESPAWN_POINTS) {
		return;
	}

	respawn_points[num_respawn_points].x = (x * 24) + 3;
	respawn_points[num_respawn_points].y = (y * 24) - 12;

	num_respawn_points++;
}

static void add_trigger(int x, int what)
{
	//One less than MAX_TRIGGERS because one position is reserved for a dummy
	//trigger that indicates the end of the list
	if (num_triggers >= MAX_TRIGGERS - 1) {
		return;
	}

	triggers[num_triggers].x = (x * 24);
	triggers[num_triggers].what = what;

	num_triggers++;
}

static void convert_obj_pos()
{
	int i;

	for (i = 0; i < num_coins; i++) {
		coins[i].x *= 24;
		coins[i].x += 8;

		coins[i].y *= 24;
	}

	for (i = 0; i < num_objs; i++) {
		int x = objs[i].x * 24;
		int y = objs[i].y * 24;

		switch (objs[i].type) {
			case OBJ_BANANA_PEEL:
				x += 16;
				y += 16;
				break;

			case OBJ_GUSH:
				y = GUSH_INITIAL_Y;
				break;

			case OBJ_GUSH_CRACK:
				y = GUSH_CRACK_Y;
				break;

			case OBJ_PUSH_CRATE:
			case OBJ_PUSH_CRATE_WITH_ARROW:
				y = PUSHABLE_CRATE_Y;
				break;

			case OBJ_ROPE:
				x += 32;
				y = ROPE_Y + 5;
				break;

			case OBJ_SPRING:
				x += 8;
				y += 8;
				break;
		}

		objs[i].x = x;
		objs[i].y = y;
	}

	for (i = 0; i < MAX_OVERHEAD_SIGNS; i++) {
		int x = overhead_signs[i].x;
		int y = overhead_signs[i].y;

		overhead_signs[i].x = (x * 24);
		overhead_signs[i].y = (y * 24) + 16;
	}

	for (i = 0; i < num_parked_vehicles; i++) {
		//Convert the X position of each vehicle from level blocks to
		//tiles
		parked_vehicles[i].x *= 3;
	}
}

static void add_solid(int type, int x, int y, int width, int height)
{
	if (num_solids >= MAX_SOLIDS) {
		return;
	}

	solids[num_solids].type   = type;
	solids[num_solids].left   = x;
	solids[num_solids].right  = x + width;
	solids[num_solids].top    = y;
	solids[num_solids].bottom = y + height;

	num_solids++;
}

static void add_solids()
{
	int i;

	/*
	if (invalid) {
		return;
	}
	*/

	//Add first floor solid
	add_solid(SOL_FULL, 0, 264, LEVEL_BLOCK_SIZE, 80);

	//Add other floor solids
	for (i = 1; i < num_columns; i++) {
		int x;

		switch (columns[i].type) {
			case LVLCOL_NORMAL_FLOOR:
				solids[num_solids - 1].right += LEVEL_BLOCK_SIZE;
				break;

			case LVLCOL_DEEP_HOLE_LEFT:
				solids[num_solids - 1].right += 12;
				break;

			case LVLCOL_DEEP_HOLE_RIGHT:
				x = (LEVEL_BLOCK_SIZE * i) + 14;
				add_solid(SOL_FULL, x, 264, 10, 80);
				break;

			case LVLCOL_PASSAGEWAY_LEFT:
				solids[num_solids - 1].right += 6;
				break;

			case LVLCOL_PASSAGEWAY_RIGHT:
				x = (LEVEL_BLOCK_SIZE * (i + 1));
				add_solid(SOL_FULL, x, 264, 0, 80);
				break;
		}

		//Too many solids
		/*
		if (invalid) {
			return;
		}
		*/
	}

	//Add passageway solids
	for (i = 0; i < num_passageways; i++) {
		int x = passageways[i].left;
		int w = passageways[i].right - x;

		//Bottom solid
		add_solid(SOL_FULL, x + 8, 360, w - 8, 4);

		//Passageway entry solid
		add_solid(SOL_PASSAGEWAY_ENTRY, x + 6, 264, 18, 13);

		//Top floor solid
		x += LEVEL_BLOCK_SIZE;
		w -= (LEVEL_BLOCK_SIZE * 2);
		add_solid(SOL_FULL, x, 264, w, 13);

		//Passageway exit solid
		x += w;
		add_solid(SOL_PASSAGEWAY_EXIT, x, 264, 22, 13);
	}

	//Add solids for unpushable crates
	for (i = 1; i < num_columns; i++) {
		int num_crates = columns[i].num_crates;
		int num_crates_prev = columns[i - 1].num_crates;

		if (num_crates == 0) continue;

		if (num_crates == num_crates_prev) {
			//If multiple consecutive level columns share the same number of
			//crates, just extend the previous solid instead of adding a new one
			solids[num_solids - 1].right += LEVEL_BLOCK_SIZE;
		} else {
			int x = i * LEVEL_BLOCK_SIZE;
			int y = (11 - num_crates) * LEVEL_BLOCK_SIZE;
			int w = LEVEL_BLOCK_SIZE;
			int h = num_crates * LEVEL_BLOCK_SIZE;

			add_solid(SOL_FULL, x, y, w, h);

			//Too many solids
			/*
			if (invalid) {
				return;
			}
			*/
		}
	}

	//Add vehicle solids
	for (i = 0; i < num_parked_vehicles; i++) {
		int x = parked_vehicles[i].x * 8;
		int y;

		switch (parked_vehicles[i].type) {
			case PARKED_CAR_BLUE:
			case PARKED_CAR_SILVER:
			case PARKED_CAR_YELLOW:
				y = PARKED_CAR_Y;
				add_solid(SOL_FULL, x + 4, y + 18, 20, 4);
				add_solid(SOL_SLOPE_UP, x + 27, y + 2, 15, 15);
				add_solid(SOL_VERTICAL, x + 48, y + 2, 16, 4);
				add_solid(SOL_SLOPE_DOWN, x + 66, y + 2, 18, 18);
				add_solid(SOL_KEEP_ON_TOP, x + 88, y + 20, 16, 4);
				add_solid(SOL_KEEP_ON_TOP, x + 104, y + 22, 16, 4);
				add_solid(SOL_FULL, x + 120, y + 24, 8, 4);
				break;

			case PARKED_TRUCK:
				y = PARKED_TRUCK_Y;
				add_solid(SOL_FULL, x, y + 4, 224, 96);
				add_solid(SOL_FULL, x + 224, y + 23, 55, 80);
				break;
		}
	}

	//Add hydrant solids
	for (i = 0; i < num_columns; i++) {
		int x = i * 24;
		int y = HYDRANT_Y;

		if (columns[i].has_hydrant) {
			add_solid(SOL_FULL, x + 4, y + 8, 8, 4);
		}
	}

	//Add overhead sign solids
	for (i = 0; i < num_overhead_signs; i++) {
		int x = overhead_signs[i].x;
		int y = overhead_signs[i].y;

		add_solid(SOL_FULL, x + 12, y, 4, 32);
	}
}

static bool read_file(const char* filename)
{
	FILE* fp = fopen(filename, "r");
	char buffer[64];
	int tokens[3];
	int x_next = 20;
	int i;

	if (fp == NULL) {
		return false;
	}

	sky_color = -1;
	bgm = -1;
	num_columns = 0;
	num_objs = 0;
	num_coins = 0;
	num_gushes = 0;
	num_gush_cracks = 0;
	num_overhead_signs = 0;
	num_parked_vehicles = 0;
	num_respawn_points = 0;
	num_triggers = 0;
	num_solids = 0;

	for (i = 0; i < MAX_COLUMNS; i++) {
		columns[i].type = LVLCOL_NORMAL_FLOOR;
	}

	for (i = 0; i < MAX_PASSAGEWAYS; i++) {
		passageways[i].left  = 0;
		passageways[i].right = 0;
	}

	for (i = 0; i < MAX_TRIGGERS; i++) {
		triggers[i].x = 0;
		triggers[i].what = 0;
	}

	while (!feof(fp)) {
		if (fgets(buffer, 60, fp) == NULL) {
			break;
		}

		find_tokens(buffer, tokens);

		for (i = 0; i < 3; i++) {
			if (tokens[i] > 0) {
				tokens[i] = atoi(&buffer[tokens[i]]);
			}
		}

		if (str_starts_with(buffer, "level-size ")) {
			num_columns = tokens[0] * 20;
		} else if (str_starts_with(buffer, "sky-color ")) {
			sky_color = tokens[0] - 1;
		} else if (str_starts_with(buffer, "bgm ")) {
			bgm = tokens[0] - 1;
		} else if (str_starts_with(buffer, "goal-scene ")) {
			goal_scene = tokens[0] - 1;
		} else if (str_starts_with(buffer, "banana-peel ")) {
			x_next += tokens[0];
			add_obj(OBJ_BANANA_PEEL, x_next, tokens[1]);
		} else if (str_starts_with(buffer, "car-blue ")) {
			x_next += tokens[0];
			add_parked_vehicle(PARKED_CAR_BLUE, x_next);
		} else if (str_starts_with(buffer, "car-silver ")) {
			x_next += tokens[0];
			add_parked_vehicle(PARKED_CAR_SILVER, x_next);
		} else if (str_starts_with(buffer, "car-yellow ")) {
			x_next += tokens[0];
			add_parked_vehicle(PARKED_CAR_YELLOW, x_next);
		} else if (str_starts_with(buffer, "coin-silver ")) {
			x_next += tokens[0];
			add_coin(false, x_next, tokens[1]);
		} else if (str_starts_with(buffer, "coin-gold ")) {
			x_next += tokens[0];
			add_coin(true, x_next, tokens[1]);
		} else if (str_starts_with(buffer, "crates ")) {
			x_next += tokens[0];
			add_crates(x_next, tokens[1], tokens[2]);
		} else if (str_starts_with(buffer, "gush ")) {
			x_next += tokens[0];
			add_obj(OBJ_GUSH, x_next, 0);
			num_gushes++;
		} else if (str_starts_with(buffer, "gush-crack ")) {
			x_next += tokens[0];
			add_obj(OBJ_GUSH_CRACK, x_next, 0);
			num_gush_cracks++;
		} else if (str_starts_with(buffer, "hydrant ")) {
			x_next += tokens[0];
			add_hydrant(x_next);
		} else if (str_starts_with(buffer, "overhead-sign ")) {
			x_next += tokens[0];
			add_overhead_sign(x_next, tokens[1]);
		} else if (str_starts_with(buffer, "rope ")) {
			x_next += tokens[0];
			add_horizontal_rope(x_next);
			add_obj(OBJ_ROPE, x_next, tokens[1]);
		} else if (str_starts_with(buffer, "spring ")) {
			x_next += tokens[0];
			add_obj(OBJ_SPRING, x_next, 10);
		} else if (str_starts_with(buffer, "truck ")) {
			x_next += tokens[0];
			add_parked_vehicle(PARKED_TRUCK, x_next);
		} else if (str_starts_with(buffer, "trigger-car-blue ")) {
			x_next += tokens[0];
			add_trigger(x_next, TRIGGER_CAR_BLUE);
		} else if (str_starts_with(buffer, "trigger-car-silver ")) {
			x_next += tokens[0];
			add_trigger(x_next, TRIGGER_CAR_SILVER);
		} else if (str_starts_with(buffer, "trigger-car-yellow ")) {
			x_next += tokens[0];
			add_trigger(x_next, TRIGGER_CAR_YELLOW);
		} else if (str_starts_with(buffer, "trigger-hen ")) {
			x_next += tokens[0];
			add_trigger(x_next, TRIGGER_HEN);
		} else if (str_starts_with(buffer, "respawn-point ")) {
			x_next += tokens[0];
			add_respawn_point(x_next, tokens[1]);
		} else if (str_starts_with(buffer, "deep-hole ")) {
			x_next += tokens[0];
			add_deep_hole(x_next, tokens[1]);
		} else if (str_starts_with(buffer, "passageway ")) {
			x_next += tokens[0];
			add_passageway(x_next, tokens[1]);
			add_obj(OBJ_PUSH_CRATE, x_next, 0);
			add_obj(OBJ_SPRING, x_next + tokens[1] - 1, 14);
		} else if (str_starts_with(buffer, "passageway-arrow ")) {
			x_next += tokens[0];
			add_passageway(x_next, tokens[1]);
			add_obj(OBJ_PUSH_CRATE_WITH_ARROW, x_next, 0);
			add_obj(OBJ_SPRING, x_next + tokens[1] - 1, 14);
		}
	}

	convert_obj_pos();
	add_solids();

	//Add a dummy trigger to the end of the list
	num_triggers++;

	fclose(fp);

	return true;
}

static int encode_column(int col)
{
	int type = columns[col].type;
	int num_crates = columns[col].num_crates;
	bool has_hydrant = columns[col].has_hydrant;
	bool has_rope = columns[col].has_rope;

	return (has_rope ? 0x80 : 0) | (has_hydrant ? 0x40 : 0) | (type << 3) | num_crates;
}

static void out8(FILE* fp, int val)
{
	fputc((val & 0xFF), fp);
}

static void out16be(FILE* fp, int val)
{
	fputc(((val >> 8) & 0xFF), fp);
	fputc((val & 0xFF), fp);
}

static void output_data(FILE* fp)
{
	int i;

	out16be(fp, num_columns);
	out8(fp, sky_color);
	out8(fp, bgm);
	out8(fp, goal_scene);
	out8(fp, num_coins);
	out8(fp, num_objs);
	out8(fp, num_overhead_signs);
	out8(fp, num_parked_vehicles);
	out8(fp, num_respawn_points);
	out8(fp, num_solids);
	out8(fp, num_triggers);

	for (i = 0; i < num_columns; i++) {
		out8(fp, encode_column(i));
	}

	for (i = 0; i < num_coins; i++) {
		out16be(fp, coins[i].x);
		out16be(fp, coins[i].y | (coins[i].gold ? 0x8000 : 0));
	}

	for (i = 0; i < num_objs; i++) {
		out16be(fp, objs[i].type);
		out16be(fp, objs[i].x);
		out16be(fp, objs[i].y);
		out16be(fp, 0);
	}

	for (i = 0; i < num_overhead_signs; i++) {
		out16be(fp, overhead_signs[i].x);
		out16be(fp, overhead_signs[i].y);
	}

	for (i = 0; i < num_parked_vehicles; i++) {
		out16be(fp, parked_vehicles[i].type);
		out16be(fp, parked_vehicles[i].x);
	}

	for (i = 0; i < MAX_PASSAGEWAYS; i++) {
		out16be(fp, passageways[i].left);
		out16be(fp, passageways[i].right);
	}

	for (i = 0; i < num_respawn_points; i++) {
		out16be(fp, respawn_points[i].x);
		out16be(fp, respawn_points[i].y);
	}

	for (i = 0; i < num_solids; i++) {
		out16be(fp, solids[i].left);
		out16be(fp, solids[i].right);
		out16be(fp, solids[i].top);
		out16be(fp, solids[i].bottom);
		out16be(fp, solids[i].type);
	}

	for (i = 0; i < num_triggers; i++) {
		out16be(fp, triggers[i].x);
		out16be(fp, triggers[i].what);
	}
}

void output_stats()
{
	printf("Level columns: %d\n", num_columns);
	printf("Objects in RAM_objs: %d\n", num_objs);
	printf("Coins: %d\n", num_coins);
	printf("Gushes: %d\n", num_gushes);
	printf("Gushes plus gush cracks: %d\n", num_gushes + num_gush_cracks);
	printf("Parked vehicles: %d\n", num_parked_vehicles);
}

void print_usage(char* argv[])
{
	printf("Usage: %s [-s] <in-file> [out-file]\n", argv[0]);
}

int main(int argc, char* argv[])
{
	char* filename;
	bool output_mode_stats = false;
	int len;

	if (argc < 3) {
		print_usage(argv);

		return 0;
	}

	filename = argv[1];

	if (argv[1][0] == '-' && argv[1][1] == 's') {
		if (argc < 3) {
			print_usage(argv);

			return 0;
		}

		output_mode_stats = true;
		filename = argv[2];
	}

	len = strlen(filename);

	level_num = (filename[len - 2] - '0');
	difficulty = filename[len - 1];

	if (level_num < 1 || level_num > 5) {
		printf("Invalid level number\n");

		return 1;
	}

	if (difficulty != 'n' && difficulty != 'h' && difficulty != 's'
			&& difficulty != 't') {

		printf("Invalid difficulty\n");

		return 1;
	}

	if (!read_file(filename)) {
		printf("Read error\n");

		return 1;
	}

	if (!output_mode_stats) {
		FILE* fp = fopen(argv[2], "wb");

		if (fp == NULL) {
			printf("Cannot open output file\n");

			return 1;
		}

		output_data(fp);

		fclose(fp);
	} else {
		output_stats();
	}

	return 0;
}

