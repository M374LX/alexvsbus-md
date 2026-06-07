/*
 * fix-rom
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

#define ROM_SIZE (512 * 1024)

int read16(unsigned char* ptr)
{
	int b0 = *(ptr + 0);
	int b1 = *(ptr + 1);

	return (b0 << 8) | b1;
}

int read32(unsigned char* ptr)
{
	int b0 = *(ptr + 0);
	int b1 = *(ptr + 1);
	int b2 = *(ptr + 2);
	int b3 = *(ptr + 3);

	return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3;
}

int main(int argc, char* argv[])
{
	FILE* fp;
	unsigned char rom[ROM_SIZE];
	int checksum;
	int i;

	if (argc != 2) {
		fprintf(stderr, "Usage: %s <ROM>\n", argv[0]);

		return 1;
	}

	fp = fopen(argv[1], "r");

	if (fp == NULL) {
		perror(argv[1]);

		return 1;
	}

	fseek(fp, 0, SEEK_END);

	//Check if the ROM has the correct size
	if (ftell(fp) != ROM_SIZE) {
		fclose(fp);
		fprintf(stderr, "Incorrect ROM size (it must be 512 kB)\n");

		return 1;
	}

	fseek(fp, 0, SEEK_SET);
	i = 0;

	//Read entire ROM
	while (!feof(fp)) {
		rom[i] = fgetc(fp);
		i++;
	}

	fclose(fp);

	//Check if it is a valid Sega Genesis/Mega Drive ROM
	if (strncmp(&rom[0x100], "SEGA GENESIS    ", 16) != 0) {
		if (strncmp(&rom[0x100], "SEGA MEGA DRIVE ", 16) != 0) {
			fprintf(stderr, "Not a valid Sega Genesis/Mega Drive ROM\n");

			return 1;
		}
	}

	//Check if the ROM end address declared in the header is correct
	if (read32(&rom[0x1A4]) != 0x7FFFF) {
		fprintf(stderr,
			"The ROM end address declared in the header is incorrect "
			"(it must be $0007FFFF)\n"
		);

		return 1;
	}

	checksum = 0;

	//Calculate checksum
	for (i = 0x200; i < ROM_SIZE; i += 2) {
		int val = read16(&rom[i]);

		checksum += val;
		checksum &= 0xFFFF;
	}

	printf("Calculated checksum: $%04X\n", checksum);

	//If the ROM already has the correct checksum, nothing more to do
	if (read16(&rom[0x18E]) == checksum) {
		printf("It is already correct\n");

		return 0;
	}

	//Fix checksum in the ROM
	rom[0x18E] = (checksum >> 8) & 0xFF;
	rom[0x18F] = (checksum & 0xFF);

	fp = fopen(argv[1], "w");

	if (fp == NULL) {
		perror(argv[1]);

		return 1;
	}

	//Save fixed ROM
	for (i = 0; i < ROM_SIZE; i++) {
		fputc(rom[i], fp);
	}

	fclose(fp);

	printf("It has been fixed\n");

	return 0;
}

