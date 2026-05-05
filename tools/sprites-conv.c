/*
 * sprites-conv
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

#define IMG_WIDTH 512 //The input image is required to be this exact width
#define IMG_MAX_HEIGHT 512
#define IMG_BPP 4 //Bytes per pixel in the loaded image
#define MAX_SPRITES 255

//Error types
enum {
	ERR_NONE = 0,
	ERR_CANNOT_OPEN_IMAGE = 1,
	ERR_INVALID_IMAGE_WIDTH = 2,
	ERR_INVALID_IMAGE_HEIGHT = 3,
	ERR_CANNOT_OPEN_LIST = 4,
	ERR_INVALID_LIST = 5,
	ERR_LIST_TOO_MANY_SPRITES = 6,
	ERR_INVALID_COLOR = 7,
	ERR_FILE_OUTPUT = 8,
};

typedef struct {
	int num;
	int pal;
	int w;
	int h;
} Sprite;

//------------------------------------------------------------------------------

static const int pals[] = {
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

int error_type = ERR_NONE;

int num_sprites = 0;
Sprite sprites[MAX_SPRITES];

unsigned char* img_data = NULL;
int num_sprite_rows = 0;
int img_max_sprites = 0;

//------------------------------------------------------------------------------

int get_pixel(int x, int y)
{
	int offs = (IMG_WIDTH * y + x) * IMG_BPP;

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
	int spr;

	if (error_type != ERR_NONE) {
		return;
	}

	for (spr = 0; spr < num_sprites; spr++) {
		int x = (spr % 16) * 32;
		int y = (spr / 16) * 32;
		int pal = sprites[spr].pal;
		int ix, iy;

		for (iy = 0; iy < 32; iy++) {
			for (ix = 0; ix < 32; ix++) {
				int pixel = get_pixel(ix + x, iy + y);
				int idx = get_color_index(pal, pixel);

				if (idx == -1) {
					error_type = ERR_INVALID_COLOR;
					return;
				}
			}
		}
	}
}

void check_too_many_sprites()
{
	if (error_type != ERR_NONE) {
		return;
	}

	if (num_sprites > img_max_sprites) {
		error_type = ERR_LIST_TOO_MANY_SPRITES;
		return;
	}
}

void out_tile(FILE* fp, int pal, int x, int y)
{
	int ix, iy;

	for (iy = 0; iy < 8; iy++) {
		for (ix = 0; ix < 4; ix++) {
			int pixel;
			int idx;
			int out;

			pixel = get_pixel(x + (ix * 2), y + iy);
			idx = get_color_index(pal, pixel);
			out = idx << 4;

			pixel = get_pixel(x + (ix * 2 + 1), y + iy);
			idx = get_color_index(pal, pixel);
			out |= idx;

			fputc(out, fp);

			if (ferror(fp)) {
				error_type = ERR_FILE_OUTPUT;

				return;
			}
		}
	}
}

void out_sprites_tileset(char* filename)
{
	int spr;
	FILE* fp;

	fp = fopen(filename, "wb");

	if (fp == NULL) {
		error_type = ERR_FILE_OUTPUT;
	}

	if (error_type != ERR_NONE) {
		return;
	}

	for (spr = 0; spr < num_sprites; spr++) {
		int w = sprites[spr].w;
		int h = sprites[spr].h;
		int pal = sprites[spr].pal;
		int img_x = (spr % 16) * 32;
		int img_y = (spr / 16) * 32;
		int tx;
		int ty;

		for (tx = 0; tx <= w; tx++) {
			for (ty = 0; ty <= h; ty++) {
				out_tile(fp, pal, img_x + tx * 8, img_y + ty * 8);
			}
		}
	}

	if (fp != NULL) {
		fclose(fp);
	}
}

void read_list_file(char* filename)
{
	FILE* fp;
	char buffer[256];
	int next_sprite_num = 0;

	if (error_type != ERR_NONE) {
		return;
	}

	fp = fopen(filename, "r");

	if (fp == NULL) {
		error_type = ERR_CANNOT_OPEN_LIST;
		return;
	}

	while (!feof(fp)) {
		int len;
		int w;
		int h;
		int pal;
		
		fgets(buffer, 250, fp);
		len = strlen(buffer);

		if (len == 0) {
			break;
		}

		//Check maximum line length
		if (len > 80) {
			error_type = ERR_INVALID_LIST;
			break;
		}

		//Ignore comments and blank lines
		if (buffer[0] == '#' || buffer[0] == '\n') {
			continue;
		}

		//Check minimum line length (if it is neither blank nor a comment)
		if (len < 8) {
			error_type = ERR_INVALID_LIST;
			break;
		}

		//Check if there are spaces at the correct positions
		if (buffer[1] != ' ' || buffer[3] != ' ' || buffer[5] != ' ') {
			error_type = ERR_INVALID_LIST;
			break;
		}

		w = (int)buffer[0] - '0';
		h = (int)buffer[2] - '0';
		pal = (int)buffer[4] - '0';

		//Check if the sprite size and palette number are valid
		if (w < 0 || w > 3 || h < 0 || h > 3 || pal < 0 || pal > 3) {
			error_type = ERR_INVALID_LIST;
			break;
		}

		//Check maximum number of sprites
		if (num_sprites > MAX_SPRITES) {
			error_type = ERR_LIST_TOO_MANY_SPRITES;
			break;
		}

		sprites[num_sprites].num = next_sprite_num;
		sprites[num_sprites].w = w;
		sprites[num_sprites].h = h;
		sprites[num_sprites].pal = pal;
		num_sprites++;

		next_sprite_num += (w + 1) * (h + 1);
	}

	fclose(fp);
}

void load_image(const char* filename)
{
	int img_w, img_h, img_channels;

	if (error_type != ERR_NONE) {
		return;
	}

	img_data = stbi_load(filename, &img_w, &img_h, &img_channels, 4);

	if (img_data == NULL) {
		error_type = ERR_CANNOT_OPEN_IMAGE;
		return;
	}
	if (img_w != IMG_WIDTH) {
		error_type = ERR_INVALID_IMAGE_WIDTH;
		return;
	}
	if (img_h > IMG_MAX_HEIGHT || img_h % 32 != 0) {
		error_type = ERR_INVALID_IMAGE_HEIGHT;
		return;
	}

	num_sprite_rows = img_h / 32;
	img_max_sprites = num_sprite_rows * 16;
}

void unload_image()
{
	if (img_data != NULL) {
		stbi_image_free(img_data);
		img_data = NULL;
	}
}

void print_error()
{
	fprintf(stderr, "Error: ");

	switch (error_type) {
		case ERR_CANNOT_OPEN_IMAGE:
			fprintf(stderr, "Cannot open image.");
			break;
			
		case ERR_INVALID_IMAGE_WIDTH:
			fprintf(stderr, "Invalid image width (it must be 512 pixels).");
			break;

		case ERR_INVALID_IMAGE_HEIGHT:
			fprintf(stderr, "Invalid image height.");
			break;

		case ERR_CANNOT_OPEN_LIST:
			fprintf(stderr, "Cannot open sprites list file.");
			break;

		case ERR_INVALID_LIST:
			fprintf(stderr, "Invalid sprites list file.");
			break;

		case ERR_LIST_TOO_MANY_SPRITES:
			fprintf(stderr, "Too many sprites.");
			break;

		case ERR_INVALID_COLOR:
			fprintf(stderr, "Invalid color in image.");
			break;
	}

	fprintf(stderr, "\n");
}

int main(int argc, char* argv[])
{
	if (argc != 4) {
		fprintf(stderr, "Usage: %s <list-file> <image-file> <out-file>\n\n", argv[0]);

		return 1;
	}

	read_list_file(argv[1]);
	load_image(argv[2]);
	check_colors();
	check_too_many_sprites();
	out_sprites_tileset(argv[3]);
	unload_image();

	if (error_type != ERR_NONE) {
		print_error();

		return 1;
	}

	return 0;
}

