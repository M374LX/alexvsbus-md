/*
 * bgm-conv
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
#include <string.h>

#define NOTE_NONE -1
#define NOTE_OFF -2

struct {
	struct {
		int note;
		int octave;
		int instr;
		int effect;
		int effect_param;
	} chans[9];
} rows[4096];

int speed = 0;
int num_rows = 0;
int out_data_size = 0;
unsigned char out_data[1024 * 8];

void out_write_byte(int b)
{
	if (out_data_size > (1024 * 8)) {
		return;
	}

	out_data[out_data_size] = (unsigned char)b;
	out_data_size++;
}

void out_bin(FILE* fp)
{
	int i;

	for (i = 0; i < out_data_size; i++) {
		fputc((out_data[i] & 0xFF), fp);
	}
}

bool str_starts_with(char* str, char* start)
{
	int len = strlen(start);
	int i;

	for (i = 0; i < len; i++) {
		if (str[i] != start[i]) {
			return false;
		}
	}

	return true;
}

int semitone_from_note_name(char note)
{
	switch (note) {
		case 'C': return 0;
		case 'D': return 2;
		case 'E': return 4;
		case 'F': return 5;
		case 'G': return 7;
		case 'A': return 9;
		case 'B': return 11;
	}

	return -1;
}

int hex_digit(char c)
{
	if (c >= '0' && c <= '9') {
		return (int)c - '0';
	} else if (c >= 'A' && c <= 'F') {
		return (int)c - 'A' + 10;
	} else if (c >= 'a' && c <= 'f') {
		return (int)c - 'a' + 10;
	}

	return 0;
}

int esf_chan(int chan)
{
	switch (chan) {
		case 0: return 0x0;
		case 1: return 0x1;
		case 2: return 0x2;
		case 3: return 0x4;
		case 4: return 0x5;
		case 5: return 0xC;
		case 6: return 0x8;
		case 7: return 0x9;
		case 8: return 0xA;
	}

	return 0;
}

void read_file(FILE* f)
{
	int chan;
	int chan_instrs[9];
	bool search_speed = true;
	bool search_order = false;
	char buf[1024];

	while (1) {
		int len;

		fgets(buf, 1024, f);

		if (feof(f)) break;

		len = strlen(buf);
		if (len == 0) continue;

		if (search_speed) {
			if (str_starts_with(buf, "- speeds: ")) {
				speed = buf[10] - '0';
				search_speed = false;
				search_order = true;
			}
		} else if (search_order) {
			if (str_starts_with(buf, "----- ORDER ")) {
				search_order = false;
			}
		} else {
			if (str_starts_with(buf, "----- ORDER ")) {
				continue;
			}

			//Read row
			for (chan = 0; chan < 9; chan++) {
				char* chan_buf;
				int note;
				int octave = 0;
				int instr = -1;
				int effect = -1;
				int effect_param = 0;

				chan_buf = &buf[15 * chan];

				//Determine note and octave
				if (chan_buf[4] == '.') {
					note = NOTE_NONE;
				} else if (chan_buf[4] == 'O') {
					note = NOTE_OFF;
				} else {
					note = semitone_from_note_name(chan_buf[4]);

					if (chan_buf[5] == '#') {
						note++;
					}

					octave = chan_buf[6] - '0';
				}

				//Determine instrument
				if (chan_buf[8] != '.') {
					instr  = hex_digit(chan_buf[8]) << 4;
					instr |= hex_digit(chan_buf[9]);
				}

				//Determine effect
				if (chan_buf[14] != '.') {
					effect  = hex_digit(chan_buf[14]) << 4;
					effect |= hex_digit(chan_buf[15]);
				}

				//Determine effect parameter
				if (chan_buf[16] != '.') {
					effect_param  = hex_digit(chan_buf[16]) << 4;
					effect_param |= hex_digit(chan_buf[17]);
				}

				rows[num_rows].chans[chan].note   = note;
				rows[num_rows].chans[chan].octave = octave;
				rows[num_rows].chans[chan].instr  = instr;
				rows[num_rows].chans[chan].effect = effect;
				rows[num_rows].chans[chan].effect_param = effect_param;
			}

			num_rows++;
		}
	}
}

void process()
{
	int row;
	int chan;
	int chan_instrs[9];
	int delay = 0;

	for (chan = 0; chan < 9; chan++) {
		chan_instrs[chan] = -1;
	}

	//Loop start
	out_write_byte(0xFD);

	for (row = 0; row < num_rows; row++) {
		bool end_reached = false;
		bool new_delay = false;

		//Check order jump effects
		for (chan = 0; chan < 9; chan++) {
			int effect = rows[row].chans[chan].effect;

			if (effect == 0x0D) {
				//Jump to next order effect

				row &= ~0x1F;
				row += 0x1F;

				continue;
			} else if (effect == 0x0B) {
				//Jump to another order effect (treated as the end of the stream)
				end_reached = true;

				break;
			}
		}

		//Check instrument changes
		for (chan = 0; chan < 9; chan++) {
			int instr = rows[row].chans[chan].instr;

			//Skip DAC channel
			if (chan == 5) continue;

			if (instr != -1 && instr != chan_instrs[chan]) {
				out_write_byte(0x40 + esf_chan(chan));

				//While Furnace uses a single set for all instruments, the game
				//uses separate sets for FM and PSG instruments, with 4 being
				//the first number used in Furnace project files for PSG
				//instruments
				if (chan >= 6) {
					out_write_byte(instr - 4);
				} else {
					out_write_byte(instr);
				}

				chan_instrs[chan] = instr;
			}
		}

		//Insert notes
		for (chan = 0; chan < 9; chan++) {
			int note = rows[row].chans[chan].note;
			int octave = rows[row].chans[chan].octave;

			if (note != NOTE_NONE) {
				new_delay = true;

				if (note == NOTE_OFF) {
					out_write_byte(0x10 + esf_chan(chan));
				} else {
					out_write_byte(0x00 + esf_chan(chan));

					if (chan < 5) { //FM channel
						out_write_byte(32 * octave + 2 * note + 1);
					} else if (chan == 5) { //DAC channel
						if (note == 0) {
							//Kick
							out_write_byte(0x00);
						} else if (note == 2) {
							//Snare
							out_write_byte(0x01);
						}
					} else if (chan < 9) { //PSG tone channel
						out_write_byte(24 * (octave - 1) + 2 * note);
					}
				}
			}
		}

		//Insert vibrato effects (PSG tone channels only)
		for (chan = 6; chan < 9; chan++) {
			if (rows[row].chans[chan].effect == 0x04) {
				new_delay = true;

				if (rows[row].chans[chan].effect_param == 0) {
					//Disable vibrato
					out_write_byte(0xC0 + esf_chan(chan));
				} else {
					//Enable vibrato
					out_write_byte(0xB0 + esf_chan(chan));
				}
			}
		}

		//Insert delay
		if (new_delay) {
			delay = speed;

			out_write_byte(0xD0 + speed);
		} else {
			int prev_delay = delay;

			delay += speed;

			if (delay < 0x10) {
				out_data[out_data_size - 1] = 0xD0 + delay;
			} else if (delay >= 0x10 && prev_delay < 0x10) {
				out_data[out_data_size - 1] = 0xFE;
				out_write_byte(delay);
			} else {
				out_data[out_data_size - 1] = delay;
			}
		}

		if (end_reached) break;
	}

	//Go to loop
	out_write_byte(0xFC);
}

int main(int argc, char* argv[])
{
	FILE* f;

	if (argc != 3) {
		printf("Usage: %s <in-file> <out-file>\n", argv[0]);

		return 1;
	}

	f = fopen(argv[1], "r");

	if (f == NULL) {
		perror(argv[1]);

		return 1;
	}

	read_file(f);
	fclose(f);

	f = fopen(argv[2], "wb");

	if (f == NULL) {
		perror(argv[2]);

		return 1;
	}

	process();
	out_bin(f);
	fclose(f);

	return 0;
}

