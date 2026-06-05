/*
 * fps-values-conv
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
#include <stdio.h>
#include <string.h>

//Velocity and acceleration values use 16.16 fixed point
#define FIXED_UNIT (1 << 16)

#define MAX_ENTRIES 256

int num_entries;

struct {
	char type;
	float value;
	int value_ntsc;
	int value_pal;
} entries[MAX_ENTRIES];

void read_num_from_str(const char* src, char* dst)
{
	int i = 0;

	while (1) {
		char c = src[i];

		if (isdigit(c) || c == '-' || c == '.') {
			dst[i] = c;
			i++;
		} else {
			break;
		}
	}

	dst[i] = '\0';
}

float str_to_float(const char* str)
{
	float ret = 0;
	float div = 1;
	int pos = 0;
	bool neg = false;
	bool dot_found = false;

	if (str[0] == '-') {
		neg = true;
		pos++;
	}

	while (1) {
		char c = str[pos];

		if (isdigit(c)) {
			int digit = str[pos] - '0';

			ret *= 10;
			ret += digit;

			if (dot_found) {
				div *= 10;
			}
		} else if (c == '.') {
			dot_found = true;
		} else {
			break;
		}

		pos++;
	}

	if (neg) {
		ret = -ret;
	}

	ret /= div;

	return ret;
}

bool read_file(FILE* fp)
{
	char type = ' ';
	char prev_type = ' ';
	char line[128];
	char read_num[32];

	num_entries = 0;

	while (1) {
		fgets(line, 128, fp);

		if (feof(fp)) {
			break;
		}

		if (line[1] != ' ') {
			return false;
		}

		if (num_entries >= MAX_ENTRIES) {
			return false;
		}

		type = line[0];

		//Ensure there are no invalid value types and they are in the order:
		//time delays, velocities, and accelerations
		if (type != prev_type) {
			if (type == 't') {
				if (prev_type != ' ') {
					return false;
				}
			} else if (type == 'v') {
				if (prev_type != 't') {
					return false;
				}
			} else if (type == 'a') {
				if (prev_type != 'v') {
					return false;
				}
			} else {
				return false;
			}
		}

		read_num_from_str(&line[2], read_num);

		entries[num_entries].type = type;
		entries[num_entries].value = str_to_float(read_num);
		num_entries++;

		prev_type = type;
	}

	return true;
}

void calculate_values()
{
	int i;

	for (i = 0; i < num_entries; i++) {
		float value = entries[i].value;
		char type = entries[i].type;
		int value_ntsc = 0;
		int value_pal = 0;

		switch (type) {
			case 't': //Time delay
				value_ntsc = (int)(value * 60);
				value_pal  = (int)(value * 50);
				break;

			case 'v': //Velocity
				value_ntsc = (int)((value / 60) * FIXED_UNIT);
				value_pal  = (int)((value / 50) * FIXED_UNIT);
				break;

			case 'a': //Acceleration
				value_ntsc = (int)((value / (60 * 60)) * FIXED_UNIT);
				value_pal  = (int)((value / (50 * 50)) * FIXED_UNIT);
				break;
		}

		entries[i].value_ntsc = value_ntsc;
		entries[i].value_pal  = value_pal;
	}
}

int determine_data_size()
{
	int byte_index = 0;
	int i;

	for (i = 0; i < num_entries; i++) {
		if (entries[i].type == 't') {
			byte_index++;
		} else {
			//Ensure the value is aligned to an even address
			if (byte_index & 1) {
				byte_index++;
			}

			byte_index += 4;
		}
	}

	return byte_index;
}

void out_asm_constants()
{
	int byte_index = 0;
	int i;

	for (i = 0; i < num_entries; i++) {
		char const_name[32];
		char type = entries[i].type;
		float value = entries[i].value;
		int j;

		sprintf(const_name, "FPSVAL_%g_", value);
		switch (type) {
			case 't':
				strcat(const_name, "S:");
				break;

			case 'v':
				strcat(const_name, "PXS:");
				break;

			case 'a':
				strcat(const_name, "PXSS:");
				break;
		}

		//Replace invalid characters in a constant name
		j = 0;
		while (const_name[j] != '\0') {
			if (const_name[j] == '-') {
				const_name[j] = 'M';
			} else if (const_name[j] == '.') {
				const_name[j] = '_';
			}

			j++;
		}

		printf("%-31s equ ", const_name);

		//Ensure the value is aligned to an even address
		if (type != 't' && (byte_index & 1)) {
			byte_index++;
		}

		printf("RAM_fpsvals+$%02X\n", byte_index);

		if (type == 't') {
			byte_index++;
		} else {
			byte_index += 4;
		}
	}
}

void out_asm_table(bool pal)
{
	int byte_index = 0;
	int i;

	for (i = 0; i < num_entries; i++) {
		char type = entries[i].type;
		float value = entries[i].value;
		int fps_value = pal ? entries[i].value_pal : entries[i].value_ntsc;

		if (type == 't') {
			printf("\tdc.b    %-15d ; %4g s\n", fps_value, value);

			byte_index++;
		} else {
			//Ensure the value is aligned to an even address
			if (byte_index & 1) {
				puts("\tdc.b    0               ; (Padding)");

				byte_index++;
			}

			printf("\tdc.l    %-15d ; %4g ", fps_value, value);

			if (type == 'v') {
				puts("px/s");
			} else {
				puts("px/ss");
			}

			byte_index += 4;
		}
	}
}

void out_asm()
{
	printf("FPSVALS_SIZE:                   equ %d\n\n", determine_data_size());

	out_asm_constants();

	puts("\nDATA_fps_values_ntsc:");
	out_asm_table(false);
	puts("\teven");

	puts("\nDATA_fps_values_pal:");
	out_asm_table(true);
	puts("\teven");

	puts("");
}

void out_list()
{
	int i;

	for (i = 0; i < num_entries; i++) {
		char type      = entries[i].type;
		float value    = entries[i].value;
		int value_ntsc = entries[i].value_ntsc;
		int value_pal  = entries[i].value_pal;

		printf("%c %-8g %-8d %-8d\n", type, value, value_ntsc, value_pal);
	}
}

void print_usage(char* argv0)
{
	fprintf(stderr, "Usage: %s [-l] <input file>\n", argv0);
}

int main(int argc, char* argv[])
{
	FILE* fp;
	char* filename = NULL;
	bool list = false;

	if (argc != 2 && argc != 3) {
		print_usage(argv[0]);

		return 0;
	}

	filename = argv[1];
	list = false;

	if (argv[1][0] == '-') {
		if (argv[1][1] == 'l') {
			if (argc != 3) {
				print_usage(argv[0]);

				return 0;
			}

			filename = argv[2];
			list = true;
		} else {
			print_usage(argv[0]);

			return 0;
		}
	}

	fp = fopen(filename, "r");

	if (fp == NULL) {
		perror(argv[1]);

		return 1;
	}

	if (!read_file(fp)) {
		fprintf(stderr, "Invalid file: %s\n", filename);

		fclose(fp);
		return 1;
	}

	fclose(fp);

	calculate_values();

	if (list) {
		out_list();
	} else {
		out_asm();
	}

	return 0;
}

