/*
 * gen-sprite-constants
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

#include <stdio.h>
#include <string.h>

int main(int argc, char* argv[])
{
	FILE* fp;
	char buffer[128];
	int sprite_num = 0;

	if (argc < 2) {
		printf("Usage: %s <file>\n", argv[0]);

		return 0;
	}

	fp = fopen(argv[1], "r");

	if (fp == NULL) {
		printf("Cannot open file.\n");

		return 1;
	}

	while (!feof(fp)) {
		int len;
		int w;
		int h;

		if (fgets(buffer, 124, fp) == NULL) {
			break;
		}

		len = strlen(buffer);

		//Remove final newline
		if (buffer[len - 1] == '\n') {
			buffer[len - 1] = '\0';
		}

		if (buffer[0] == '\0' || buffer[0] == '#') {
			continue;
		}

		w = buffer[0] - '0';
		h = buffer[2] - '0';

		printf("%s: equ SPR_INITIAL+$%04X\n", &buffer[6], sprite_num);

		sprite_num += ((w + 1) * (h + 1));
	}

	fclose(fp);

	return 0;
}

