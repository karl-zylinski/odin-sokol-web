# Odin + Sokol on the web

![image](https://github.com/user-attachments/assets/af9c11e3-c724-4107-9af4-9f2ac469b88b)

Make programs using [Odin](https://odin-lang.org/) + [Sokol](https://github.com/floooh/sokol) that work on the web!

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

There is also a `build_desktop.bat/sh` that makes a desktop version of your program.

> [!WARNING]
> If the desktop build says that there are libraries missing, then you need to go into `source/sokol` and run one of the `build_clibs...` build scripts.

## How does the web build work?

1. The contents of `source` is compiled with Odin compiler using `js_wasm32` target. It is compiled in `obj` build mode. This means that no libraries are linked. That instead happens in step (3).
2. The `odin.js` environment is copied from `<odin>/core/sys/wasm/js/odin.js` to `build/web`
3. The emscripten compiler is run. It is fed the output of our Odin compilation as well as the Sokol library files. It is also fed a template HTML file that is used as basis for the final `index.html` file. The resulting WASM files and are written to `build/web`

Open the resulting `build/web/index.html`, to see how it starts up the `main` proc in our Odin code.

## Limitations

- Any C library you use in the Odin code needs to be manually linked into `emcc`.
- If you get compile errors related to `vendor:libc` when using any WASM library, then you'll need to remove the `import "vendor:libc"` line from that library. Some libraries, such as `vendor:box2d` and `vendor:stb/image` use `vendor:libc` to remove the need for emscripten. However, this breaks those libs when used in combination with emscripten.
