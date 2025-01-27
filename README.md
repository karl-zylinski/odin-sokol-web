# Odin + Sokol on the web

![image](https://github.com/user-attachments/assets/af9c11e3-c724-4107-9af4-9f2ac469b88b)

Make games using [Odin](https://odin-lang.org/) + [Sokol](https://github.com/floooh/sokol) that work on the web!

Live example: https://zylinski.se/odin-sokol-web/

## Getting started

This assumes you have a recent Odin compiler installed.

1. [Install emscripten](https://emscripten.org/docs/getting_started/downloads.html#installation-instructions-using-the-emsdk-recommended)
2. Clone this repository
3. Run `build_web.bat` or `build_web.sh` depending on platform.

Web build is in `build/web`

> [!NOTE]
> Use `python -m http.server` while inside `build/web` to launch a web server. Go to `localhost:8000` to run your web program.
> Launching the `index.html` in there may not work due to CORS errors.

