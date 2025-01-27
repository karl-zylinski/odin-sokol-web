@echo off
echo Building shaders...
sokol-shdc\win32\sokol-shdc -i source/shader.glsl -o source/shader.odin -l glsl300es:hlsl4:glsl430 -f sokol_odin
IF %ERRORLEVEL% NEQ 0 exit /b 1

set OUT_DIR=build\desktop
if not exist %OUT_DIR% mkdir %OUT_DIR%

odin build source -out:%OUT_DIR%\game_desktop.exe -debug
IF %ERRORLEVEL% NEQ 0 exit /b 1

xcopy /y /e /i assets %OUT_DIR%\assets >nul
IF %ERRORLEVEL% NEQ 0 exit /b 1

echo Desktop build created in %OUT_DIR%