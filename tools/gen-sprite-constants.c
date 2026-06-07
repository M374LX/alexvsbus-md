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
	char buffer[80];
	int sprite_num = 0;

	if (argc < 2) {
		fprintf(stderr, "Usage: %s <file>\n", argv[0]);

		return 0;
	}

	fp = fopen(argv[1], "r");

	if (fp == NULL) {
		perror(argv[1]);

		return 1;
	}

	while (!feof(fp)) {
		char out_line[64];
		int len;
		int w;
		int h;
		int i;

		if (fgets(buffer, 80, fp) == NULL) {
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

		out_line[63] = '\0';

		//Fill out_line with spaces
		for (i = 0; i < 63; i++) {
			out_line[i] = ' ';
		}

		//Copy sprite name into the start of out_line
		i = 0;
		while (1) {
			char c = buffer[6 + i];

			if (c == '\0' || c == '\n') {
				break;
			}

			out_line[i] = c;

			i++;
		}

		out_line[i] = ':';
		snprintf(&out_line[32], 32, "equ SPR_INITIAL+$%04X", sprite_num);

		puts(out_line);

		sprite_num += ((w + 1) * (h + 1));
	}

	//Add a blank line at the end
	puts("");

	fclose(fp);

	return 0;
}

