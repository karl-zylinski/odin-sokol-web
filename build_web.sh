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

# Point this to where you installed emscripten. Optional on systems that already
# have `emcc` in the path.
EMSCRIPTEN_SDK_DIR="$HOME/repos/emsdk"
OUT_DIR="build/web"

mkdir -p $OUT_DIR

export EMSDK_QUIET=1
[[ -f "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh" ]] && . "$EMSCRIPTEN_SDK_DIR/emsdk_env.sh"

# This builds our game code, note that it uses obj build mode: No linking
# happens. The required libs to link are fed into `emcc` below.
odin build source -target:js_wasm32 -build-mode:obj -vet -strict-style -out:$OUT_DIR/game -debug

ODIN_PATH=$(odin root)

# This is the Odin JS runtime that is required for using the `js_wasm32` target
cp $ODIN_PATH/core/sys/wasm/js/odin.js $OUT_DIR

# Note how we link in the Sokol libs here. The Sokol bindings just link to
# "env.o", which is the WASM environment.
files="$OUT_DIR/game.wasm.o source/sokol/app/sokol_app_wasm_gl_release.a source/sokol/glue/sokol_glue_wasm_gl_release.a source/sokol/gfx/sokol_gfx_wasm_gl_release.a source/sokol/shape/sokol_shape_wasm_gl_release.a source/sokol/log/sokol_log_wasm_gl_release.a source/sokol/gl/sokol_gl_wasm_gl_release.a"

# index_template.html contains the javascript code that starts the program.
flags="-sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sMAX_WEBGL_VERSION=2 -sASSERTIONS --shell-file source/web/index_template.html --preload-file assets"

# For debugging: Add `-g` to `emcc` (gives better error callstack in chrome)
emcc -o $OUT_DIR/index.html $files $flags

rm $OUT_DIR/game.wasm.o

echo "Web build created in ${OUT_DIR}"