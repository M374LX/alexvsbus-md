/*
 * tiles-conv
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

#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

//------------------------------------------------------------------------------

//Prevent build failure when using the Tiny C Compiler
#ifdef __TINYC__
#define STBI_NO_SIMD
#endif

#define STBI_ONLY_PNG
#define STBI_NO_HDR
#define STB_IMAGE_IMPLEMENTATION
#include "stb_image.h"

//------------------------------------------------------------------------------

#define MAX_WIDTH_TILES  64
#define MAX_HEIGHT_TILES 128

#define FLIP_NONE 0x0000
#define FLIP_H    0x0800
#define FLIP_V    0x1000
#define FLIP_HV   0x1800

#define MAX_TILES 256
#define MAX_TILE_NUMBER 2047
#define TILEMAP_MAX_SIZE (MAX_WIDTH_TILES * MAX_HEIGHT_TILES)

#define IMG_MAX_WIDTH  (MAX_WIDTH_TILES  * 8)
#define IMG_MAX_HEIGHT (MAX_HEIGHT_TILES * 8)
#define IMG_BPP 4

#define NUM_PALETTES 5

//Output types
enum {
	OUTTYPE_TILESET    = 0,
	OUTTYPE_PRETILESET = 1,
	OUTTYPE_TILEMAP    = 2,
	OUTTYPE_BLOCKS     = 3,
	OUTTYPE_METADATA   = 4,
	OUTTYPE_STATS      = 5,
};

//Error types
enum {
	ERR_NONE = 0,
	ERR_INVALID_OUTPUT_TYPE = 1,
	ERR_INVALID_PALETTE_NUMBER = 2,
	ERR_INVALID_BASE_TILE_NUMBER = 3,
	ERR_CANNOT_OPEN_IMAGE = 4,
	ERR_IMAGE_TOO_BIG = 5,
	ERR_INVALID_IMAGE_SIZE = 6,
	ERR_INVALID_COLOR = 7,
	ERR_TOO_MANY_TILES = 8,
	ERR_VRAM_OVERFLOW = 9,
	ERR_NO_OUTPUT_FILE = 10,
	ERR_FILE_OUTPUT = 11,
};

//------------------------------------------------------------------------------

const static uint32_t pals[] = {
	//Palette 0
	0x000000, //$000
	0xFFFFFF, //$EEE
	0x000000, //$000
	0x555555, //$444
	0xAAAAAA, //$AAA
	0xAA5500, //$04A
	0x550000, //$004
	0xFFAA00, //$0AE
	0x0055FF, //$E40
	0x00AAFF, //$EA0
	0x00FF00, //$0E0
	0x005500, //$040
	0x000000, //$000
	0x000000, //$000
	0x000000, //$000
	0xAAAAFF, //$EAA

	//Palette 1
	0x000000, //$000
	0xFFFFFF, //$EEE
	0x000000, //$000
	0xAAAA00, //$0AA
	0xFFFF00, //$0EE
	0xAA5500, //$04A
	0x555555, //$444
	0xAAAAAA, //$AAA
	0x000055, //$400
	0x0000AA, //$A00
	0x0000FF, //$E00
	0x005500, //$040
	0xAAFFFF, //$EEA
	0xFFAAAA, //$AAE
	0xFF0000, //$00E
	0xFF5500, //$04E

	//Palette 2
	0x000000, //$000
	0xFFFFFF, //$EEE
	0x000000, //$000
	0xFFFFAA, //$AEE
	0x000000, //$000
	0xAA5500, //$04A
	0x555555, //$444
	0xAAAAAA, //$AAA
	0xFFFF00, //$0EE
	0x0055FF, //$E40
	0x00FF00, //$0E0
	0xAAAA00, //$0AA
	0xAAFFFF, //$EEA
	0xFFAAAA, //$AAE
	0xFF0000, //$00E
	0xFF5500, //$04E

	//Palette 3
	0x000000, //$000
	0xFFFFFF, //$EEE
	0x000000, //$000
	0x000000, //$000
	0x000000, //$000
	0xAA5500, //$04A
	0x555555, //$444
	0xAAAAAA, //$AAA
	0x000055, //$400
	0x005500, //$040
	0x0000FF, //$E00
	0xFFAA00, //$0AE
	0xAAFFFF, //$EEA
	0xFFAAAA, //$AAE
	0xFF0000, //$00E
	0xFF5500, //$04E

	//Palette 4
	0x000000, //$000
	0xFFFFFF, //$EEE
	0x000000, //$000
	0x555555, //$444
	0x550000, //$004
	0xAA0000, //$00A
	0xFF0000, //$00E
	0x005500, //$040
	0x00AA00, //$0A0
	0x00FF00, //$0E0
	0x000000, //$000
	0x000000, //$000
	0x000000, //$000
	0x000000, //$000
	0x000000, //$000
	0x000000, //$000
};

//------------------------------------------------------------------------------

static int output_type;
static int error_type = ERR_NONE;

//Size in tiles of both the input image and the tilemap
static int width_tiles;
static int height_tiles;

static uint32_t cur_tile[8];
static uint32_t cur_tile_noflip[8];

static int tileset_size;
static uint32_t tileset[MAX_TILES * 8];

static int tilemap_size;
static uint16_t tilemap[TILEMAP_MAX_SIZE];

static int base_tile_number;
static int pal_number;

static uint8_t* img_data = NULL;

//------------------------------------------------------------------------------

void load_image(char* filename)
{
	int w;
	int h;
	int channels;

	if (error_type != ERR_NONE) {
		return;
	}

	img_data = stbi_load(filename, &w, &h, &channels, 4);

	if (img_data == NULL) {
		error_type = ERR_CANNOT_OPEN_IMAGE;
		return;
	}

	if (w > IMG_MAX_WIDTH || h > IMG_MAX_HEIGHT) {
		error_type = ERR_IMAGE_TOO_BIG;
		return;
	}

	//The width and height of the image must be multiples of 8
	if (w % 8 != 0 || h % 8 != 0) {
		error_type = ERR_INVALID_IMAGE_SIZE;
		return;
	}

	width_tiles  = w / 8;
	height_tiles = h / 8;
}

void unload_image()
{
	if (img_data != NULL) {
		stbi_image_free(img_data);
		img_data = NULL;
	}
}

int get_pixel(int x, int y)
{
	int w = width_tiles * 8;
	int offs = (y * w + x) * IMG_BPP;

	int r = img_data[offs + 0];
	int g = img_data[offs + 1];
	int b = img_data[offs + 2];
	int a = img_data[offs + 3];

	return (r << 24) | (g << 16) | (b << 8) | a;
}

int get_color_index(int pal, int color)
{
	if ((color & 0xFF) == 0) { //Transparent
		return 0;
	} else {
		int i;

		//Discard alpha channel
		color >>= 8;
		color &= 0xFFFFFF;

		for (i = 1; i < 16; i++) {
			if (pals[pal * 16 + i] == color) return i;
		}

		return -1;
	}
}

void check_colors()
{
	int x;
	int y;
	int w = width_tiles * 8;
	int h = height_tiles * 8;

	if (error_type != ERR_NONE) {
		return;
	}

	for (y = 0; y < h; y++) {
		for (x = 0; x < w; x++) {
			int pixel = get_pixel(x, y);
			int col = get_color_index(pal_number, pixel);

			if (col == -1) {
				error_type = ERR_INVALID_COLOR;
				return;
			}
		}
	}
}

void get_tile_from_image(uint32_t tile_num)
{
	int img_x = (tile_num % width_tiles) * 8;
	int img_y = (tile_num / width_tiles) * 8;
	
	int ix;
	int iy;

	for (iy = 0; iy < 8; iy++) {
		uint32_t row_val = 0;

		for (ix = 0; ix < 8; ix++) {
			int pixel = get_pixel(img_x + ix, img_y + iy);
			int col = get_color_index(pal_number, pixel);

			row_val <<= 4;
			row_val |= (col & 0xF);
		}

		cur_tile[iy] = row_val;
		cur_tile_noflip[iy] = row_val;
	}
}

bool tile_in_set_equals(int tile)
{
	int row;

	for (row = 0; row < 8; row++) {
		if (cur_tile[row] != tileset[tile * 8 + row]) {
			return false;
		}
	}

	return true;
}

void flip_tile(int flip_flags)
{
	bool h = (flip_flags & FLIP_H);
	bool v = (flip_flags & FLIP_V);
	int  i;

	for (i = 0; i < 8; i++) {
		int tmp1 = cur_tile_noflip[v ? (7 - i) : i];
		int tmp2 = tmp1;

		if (h) {
			tmp2 = 0;
			tmp2 |= ((tmp1 & 0xF0000000) >> 28);
			tmp2 |= ((tmp1 & 0x0F000000) >> 20);
			tmp2 |= ((tmp1 & 0x00F00000) >> 12);
			tmp2 |= ((tmp1 & 0x000F0000) >> 4);
			tmp2 |= ((tmp1 & 0x0000F000) << 4);
			tmp2 |= ((tmp1 & 0x00000F00) << 12);
			tmp2 |= ((tmp1 & 0x000000F0) << 20);
			tmp2 |= ((tmp1 & 0x0000000F) << 28);
		}

		cur_tile[i] = tmp2;
	}
}

int find_tile_in_tileset()
{
	int tile;

	for (tile = 0; tile < tileset_size; tile++) {
		if (tile_in_set_equals(tile)) {
			return tile;
		}
	}

	return -1;
}

int find_tile_in_tileset_flipped()
{
	int flip_flags = FLIP_NONE;
	int tile = find_tile_in_tileset();

	if (tile == -1) {
		flip_flags = FLIP_H;
		flip_tile(flip_flags);
		tile = find_tile_in_tileset();
	}
	if (tile == -1) {
		flip_flags = FLIP_V;
		flip_tile(flip_flags);
		tile = find_tile_in_tileset();
	}
	if (tile == -1) {
		flip_flags = FLIP_HV;
		flip_tile(flip_flags);
		tile = find_tile_in_tileset();
	}
	if (tile == -1) {
		flip_flags = FLIP_NONE;
	}

	flip_tile(flip_flags);

	return flip_flags | tile;
}

void add_tile_to_tileset()
{
	int row;

	for (row = 0; row < 8; row++) {
		tileset[tileset_size * 8 + row] = cur_tile[row];
	}

	tileset_size++;
}

void generate_tileset_optimized()
{
	int num_tiles = width_tiles * height_tiles;
	int i;

	if (error_type != ERR_NONE) {
		return;
	}

	//Start with a cleared tileset
	for (i = 0; i < MAX_TILES * 8; i++) {
		tileset[i] = 0;
	}

	//Start with one fully transparent tile
	tileset_size = 1;

	for (i = 0; i < num_tiles; i++) {
		int tile;

		if (tileset_size > MAX_TILES) {
			error_type = ERR_TOO_MANY_TILES;
			return;
		}

		get_tile_from_image(i);
		tile = find_tile_in_tileset_flipped();

		//If the tile has not been found, add it to the tileset
		if (tile == -1) {
			add_tile_to_tileset();
		}
	}
}

void generate_tileset_pre()
{
	int num_tiles = width_tiles * height_tiles;
	int i;

	if (error_type != ERR_NONE) {
		return;
	}

	//Start with a cleared tileset
	for (i = 0; i < MAX_TILES * 8; i++) {
		tileset[i] = 0;
	}

	tileset_size = 0;

	for (i = 0; i < num_tiles; i++) {
		if (tileset_size > MAX_TILES) {
			error_type = ERR_TOO_MANY_TILES;
			return;
		}

		get_tile_from_image(i);
		add_tile_to_tileset();
	}
}

void generate_tileset(bool pre)
{
	pre ? generate_tileset_pre() : generate_tileset_optimized();
}

void generate_tilemap(bool blocks)
{
	int num_tiles = width_tiles * height_tiles;
	int i;

	if (error_type != ERR_NONE) {
		return;
	}

	tilemap_size = 0;

	for (i = 0; i < num_tiles; i++) {
		bool hiprio = false;
		int tile;
		int tile_number;
		int tile_flags;

		if (blocks) {
			//Each level block is 3x3 tiles, but the data is padded to 4x4 with
			//zeros
			if (i % 4 == 3 || i % 16 >= 0xC) {
				tilemap[tilemap_size] = 0;
				tilemap_size++;

				continue;
			}

			//Block with a crate, which is high priority
			if (i >= (23 * 16)) {
				hiprio = true;
			}
		}

		get_tile_from_image(i);

		tile = find_tile_in_tileset_flipped();
		tile_number = (tile & 0x07FF) + base_tile_number;
		tile_flags = (tile & 0xF800);

		if (hiprio) {
			tile_flags |= 0x8000;
		}

		if (tile_number > MAX_TILE_NUMBER) {
			error_type = ERR_VRAM_OVERFLOW;
			return;
		}

		tilemap[tilemap_size] = tile_flags | tile_number;
		tilemap_size++;
	}
}

void output_tileset(FILE* fp)
{
	int i;

	for (i = 0; i < tileset_size; i++) {
		int row;

		for (row = 0; row < 8; row++) {
			int val = tileset[i * 8 + row];

			fputc(((val >> 24) & 0xFF), fp);
			fputc(((val >> 16) & 0xFF), fp);
			fputc(((val >> 8) & 0xFF), fp);
			fputc((val & 0xFF), fp);
		}
	}
}

void output_tilemap(FILE* fp)
{
	int len = width_tiles * height_tiles;
	int i;

	for (i = 0; i < len; i++) {
		int val = tilemap[i];

		fputc(((val >> 8) & 0xFF), fp);
		fputc((val & 0xFF), fp);
	}
}

void output_metadata()
{
	printf("; Width = %d; Height = %d; Initial tile = $%04X\n",
		width_tiles, height_tiles, base_tile_number);
}

void output_stats()
{
	printf("Number of tiles: %d\n", tileset_size);
	printf("Map size (tiles): %dx%d\n", width_tiles, height_tiles);
}

void output(char* filename)
{
	FILE* fp = NULL;

	//For output types that output to a file, rather than stdio, open the file
	//for writing
	if (output_type != OUTTYPE_METADATA && output_type != OUTTYPE_STATS) {
		fp = fopen(filename, "wb");

		if (fp == NULL) {
			error_type = ERR_FILE_OUTPUT;
		}
	}

	if (error_type != ERR_NONE) {
		return;
	}

	switch (output_type) {
		case OUTTYPE_TILESET:
			output_tileset(fp);
			break;

		case OUTTYPE_PRETILESET:
			output_tileset(fp);
			break;

		case OUTTYPE_TILEMAP:
			output_tilemap(fp);
			break;

		case OUTTYPE_BLOCKS:
			output_tilemap(fp);
			break;

		case OUTTYPE_METADATA:
			output_metadata();
			break;

		case OUTTYPE_STATS:
			output_stats();
			break;
	}

	if (fp != NULL) {
		fclose(fp);
	}
}

void print_error()
{
	fprintf(stderr, "Error: ");

	switch (error_type) {
		case ERR_INVALID_OUTPUT_TYPE:
			fprintf(stderr, "Invalid output type.");
			break;

		case ERR_INVALID_PALETTE_NUMBER:
			fprintf(stderr, "Invalid palette number.");
			break;

		case ERR_INVALID_BASE_TILE_NUMBER:
			fprintf(stderr, "Invalid base tile number.");
			break;

		case ERR_CANNOT_OPEN_IMAGE:
			fprintf(stderr, "Cannot open image file.");
			break;

		case ERR_IMAGE_TOO_BIG:
			fprintf(stderr, "The image is too big.");
			break;

		case ERR_INVALID_IMAGE_SIZE:
			fprintf(stderr, "Invalid image size.");
			break;

		case ERR_INVALID_COLOR:
			fprintf(stderr, "Invalid color found.");
			break;

		case ERR_TOO_MANY_TILES:
			fprintf(stderr, "Too many tiles.");
			break;

		case ERR_VRAM_OVERFLOW:
			fprintf(stderr, "VRAM overflow.");
			break;

		case ERR_NO_OUTPUT_FILE:
			fprintf(stderr, "No output file specified.");
			break;

		case ERR_FILE_OUTPUT:
			fprintf(stderr, "File output error.");
			break;
	}

	fprintf(stderr, "\n");
}

int main(int argc, char* argv[])
{
	bool  pre;
	bool  blocks;
	char* img_filename;
	char* output_type_param;
	char* out_filename;

	if (argc < 4 || argc > 6) {
		fprintf(stderr,
			"Usage: %s <output type> <input image file> <palette number> [base tile number] [output file]\n\n",
			argv[0]);

		fprintf(stderr, "Valid output types: tileset|pretileset|tilemap|blocks|metatada|stats\n");

		return 1;
	}

	output_type_param = argv[1];
	img_filename = argv[2];
	pal_number = (int)strtol(argv[3], NULL, 10);

	base_tile_number = 0;
	if (argc >= 5) {
		base_tile_number = (int)strtol(argv[4], NULL, 16);
	}

	out_filename = NULL;
	if (argc == 6) {
		out_filename = argv[5];
	}

	if (pal_number < 0 || pal_number >= NUM_PALETTES) {
		error_type = ERR_INVALID_PALETTE_NUMBER;
	}
	if (base_tile_number < 0 || base_tile_number > MAX_TILE_NUMBER) {
		error_type = ERR_INVALID_BASE_TILE_NUMBER;
	}

	if (error_type != ERR_NONE) {
		print_error();

		return 1;
	}

	//Determine output type
	if (strcmp(output_type_param, "tileset") == 0) {
		output_type = OUTTYPE_TILESET;
	} else if (strcmp(output_type_param, "pretileset") == 0) {
		output_type = OUTTYPE_PRETILESET;
	} else if (strcmp(output_type_param, "tilemap") == 0) {
		output_type = OUTTYPE_TILEMAP;
	} else if (strcmp(output_type_param, "blocks") == 0) {
		output_type = OUTTYPE_BLOCKS;
	} else if (strcmp(output_type_param, "metadata") == 0) {
		output_type = OUTTYPE_METADATA;
	} else if (strcmp(output_type_param, "stats") == 0) {
		output_type = OUTTYPE_STATS;
	} else {
		error_type = ERR_INVALID_OUTPUT_TYPE;
		print_error();

		return 1;
	}

	//Output types other than "metadata" and "states" require an output file to
	//be specified
	if (output_type != OUTTYPE_METADATA && output_type != OUTTYPE_STATS) {
		if (out_filename == NULL) {
			error_type = ERR_NO_OUTPUT_FILE;
			print_error();

			return 1;
		}
	}

	//Check if we should convert a pre-existing tileset without optimizing it
	pre = (output_type == OUTTYPE_PRETILESET);

	//Determine whether to generate level blocks or a regular tilemap
	blocks = (output_type == OUTTYPE_BLOCKS);

	load_image(img_filename);
	check_colors();
	generate_tileset(pre);
	generate_tilemap(blocks);
	unload_image();
	output(out_filename);

	if (error_type != ERR_NONE) {
		print_error();

		return 1;
	}

	return 0;
}

