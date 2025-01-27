#!/bin/bash -eu

echo "Building shaders..."
sokol-shdc/linux/sokol-shdc -i source/shader.glsl -o source/shader.odin -l glsl300es:hlsl4 -f sokol_odin

SHDC_FOLDER="linux"

case $(uname) in
"Darwin")
	case $(uname -m) in
		"arm64") SHDC_FOLDER="osx-arm64" ;;
		*)       SHDC_FOLDER="osx" ;;
	esac
*)
	case $(uname -m) in
		"arm64") SHDC_FOLDER="linux-arm64" ;;
		*)       SHDC_FOLDER="linux" ;;
	esac
esac

sokol-shdc/$SHDC_FOLDER/sokol-shdc -i source/shader.glsl -o source/shader.odin -l glsl300es:hlsl4 -f sokol_odin

OUT_DIR="build/desktop"
mkdir -p $OUT_DIR
odin build source/main_desktop -out:$OUT_DIR/game_desktop.bin
cp -R ./assets/ ./$OUT_DIR/assets/
echo "Desktop build created in ${OUT_DIR}"