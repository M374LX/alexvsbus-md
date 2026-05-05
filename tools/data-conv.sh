#!/bin/sh

# Note: this script needs to be called from the project root directory, not from
# the "tools" directory

# Character set
./tools/tiles-conv pretileset ./assets/charset.png 0 0 ./data/charset.bin

# Level blocks
./tools/tiles-conv tileset ./assets/level-blocks.png 0 0080 ./data/tileset-background.bin
./tools/tiles-conv blocks  ./assets/level-blocks.png 0 0080 ./data/level-blocks.bin

# Bus tileset and tilemap
./tools/tiles-conv tileset  ./assets/bus.png   3 00D0 ./data/tileset-bus.bin
./tools/tiles-conv tilemap  ./assets/bus.png   3 00D0 ./data/tilemap-bus.bin

# Truck tileset and tilemap
./tools/tiles-conv tileset  ./assets/truck.png 1 0150 ./data/tileset-truck.bin
./tools/tiles-conv tilemap  ./assets/truck.png 1 0150 ./data/tilemap-truck.bin

# Car tileset and tilemap
./tools/tiles-conv tileset  ./assets/car.png   1 01B0 ./data/tileset-car.bin
./tools/tiles-conv tilemap  ./assets/car.png   1 01B0 ./data/tilemap-car.bin

# Logo tileset and tilemap
./tools/tiles-conv tileset  ./assets/logo.png  4 0080 ./data/tileset-logo.bin
./tools/tiles-conv tilemap  ./assets/logo.png  4 0080 ./data/tilemap-logo.bin

# Sprites tileset
./tools/sprites-conv ./assets/sprites-list ./assets/sprites.png ./data/sprites.bin

# BGM tracks
./tools/bgm-conv ./assets/bgm1.txt ./data/bgm1.bin
./tools/bgm-conv ./assets/bgm2.txt ./data/bgm2.bin
./tools/bgm-conv ./assets/bgm3.txt ./data/bgm3.bin
./tools/bgm-conv ./assets/bgmtitle.txt ./data/bgmtitle.bin

# Normal levels
./tools/level-conv ./assets/level1n ./data/level1n.bin
./tools/level-conv ./assets/level2n ./data/level2n.bin
./tools/level-conv ./assets/level3n ./data/level3n.bin
./tools/level-conv ./assets/level4n ./data/level4n.bin
./tools/level-conv ./assets/level5n ./data/level5n.bin

# Hard levels
./tools/level-conv ./assets/level1h ./data/level1h.bin
./tools/level-conv ./assets/level2h ./data/level2h.bin
./tools/level-conv ./assets/level3h ./data/level3h.bin
./tools/level-conv ./assets/level4h ./data/level4h.bin
./tools/level-conv ./assets/level5h ./data/level5h.bin

# Super levels
./tools/level-conv ./assets/level1s ./data/level1s.bin
./tools/level-conv ./assets/level2s ./data/level2s.bin
./tools/level-conv ./assets/level3s ./data/level3s.bin

