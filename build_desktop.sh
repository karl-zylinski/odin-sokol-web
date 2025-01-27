#!/bin/bash -eu

echo "Building shaders..."

SHDC_PLATFORM="linux"
SHDC_ARCH=""

UNAME=$(uname -ma)

case UNAME in 
"Darwin")
	SHDC_PLATFORM = "osx" ;;
esac

case UNAME in
"arm64")
	SHDC_ARCH = "_arm64" ;;
esac

sokol-shdc/$SHDC_PLATFORM$SHDC_ARCH/sokol-shdc -i source/shader.glsl -o source/shader.odin -l glsl300es:hlsl4:glsl430 -f sokol_odin

OUT_DIR="build/desktop"
mkdir -p $OUT_DIR
odin build source -out:$OUT_DIR/game_desktop.bin
cp -R ./assets/ ./$OUT_DIR/assets/
echo "Desktop build created in ${OUT_DIR}"