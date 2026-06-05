#!/bin/sh

gcc -o bgm-conv bgm-conv.c
gcc -o fix-rom fix-rom.c
gcc -o fps-values-conv fps-values-conv.c
gcc -o gen-sprite-constants gen-sprite-constants.c
gcc -o level-conv level-conv.c
gcc -lm -o sprites-conv sprites-conv.c
gcc -lm -o tiles-conv tiles-conv.c

