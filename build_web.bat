@echo off

echo Building shaders...
sokol-shdc\win32\sokol-shdc -i source/shader.glsl -o source/shader.odin -l glsl300es:hlsl4:glsl430 -f sokol_odin
IF %ERRORLEVEL% NEQ 0 exit /b 1

:: Point this to where you installed emscripten.
set EMSCRIPTEN_SDK_DIR=c:\SDK\emsdk
set OUT_DIR=build\web

if not exist %OUT_DIR% mkdir %OUT_DIR%

set EMSDK_QUIET=1
call %EMSCRIPTEN_SDK_DIR%\emsdk_env.bat

odin build source -target:js_wasm32 -build-mode:obj -vet -strict-style -out:%OUT_DIR%\game -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

for /f %%i in ('odin root') do set "ODIN_PATH=%%i"

:: This is the Odin JS runtime that is required for using the `js_wasm32` target
copy %ODIN_PATH%\core\sys\wasm\js\odin.js %OUT_DIR% > nul

:: Note how we link in the Sokol libs here. The Sokol bindings just link to
:: "env.o", which is the WASM environment.
set files=%OUT_DIR%\game.wasm.o source\sokol\app\sokol_app_wasm_gl_release.a source\sokol\glue\sokol_glue_wasm_gl_release.a source\sokol\gfx\sokol_gfx_wasm_gl_release.a source\sokol\shape\sokol_shape_wasm_gl_release.a source\sokol\log\sokol_log_wasm_gl_release.a source\sokol\gl\sokol_gl_wasm_gl_release.a

:: index_template.html contains the javascript code that starts the program.
set flags=-sWASM_BIGINT -sWARN_ON_UNDEFINED_SYMBOLS=0 -sMAX_WEBGL_VERSION=2 -sASSERTIONS --shell-file source\web\index_template.html --preload-file assets

:: For debugging: Add `-g` to `emcc` (gives better error callstack in chrome)
::
:: This uses `cmd /c` to avoid emcc stealing the whole command prompt. Otherwise
:: it does not run the lines that follow it.
cmd /c emcc -g -o %OUT_DIR%\index.html %files% %flags%
IF %ERRORLEVEL% NEQ 0 exit /b 1

del %OUT_DIR%\game.wasm.o 

echo Web build created in %OUT_DIR%