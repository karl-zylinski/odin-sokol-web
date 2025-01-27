// This program draws a cube with a texture on the sides.
//
// Based on https://github.com/floooh/sokol-odin/tree/main/examples/texcube
package main

import "base:runtime"
import "core:image/png"
import "core:log"
import "core:math/linalg"
import "core:os"
import "core:slice"
import "web"
import sapp "sokol/app"
import sg "sokol/gfx"
import sglue "sokol/glue"
import slog "sokol/log"

_ :: web 
_ :: os

IS_WEB :: ODIN_ARCH == .wasm32 || ODIN_ARCH == .wasm64p32
Mat4 :: matrix[4,4]f32
Vec3 :: [3]f32

state: struct {
	pass_action: sg.Pass_Action,
	pip: sg.Pipeline,
	bind: sg.Bindings,
	rx, ry: f32,
}

custom_context: runtime.Context

Vertex :: struct {
	x, y, z: f32,
	color: u32,
	u, v: u16,
}

main :: proc() {
	when IS_WEB {
		// The WASM allocator doesn't seem to work properly in combination with
		// emscripten. There is some kind of conflict with how they manage
		// memory. So this sets up an allocator that uses emscripten's malloc.
		context.allocator = web.emscripten_allocator()

		// Make temp allocator use new `context.allocator` by re-initing it.
		runtime.init_global_temporary_allocator(1*runtime.Megabyte)
	}

	context.logger = log.create_console_logger(lowest = .Info, opt = {.Level, .Short_File_Path, .Line, .Procedure})
	custom_context = context
	
	sapp.run({
		init_cb = init,
		frame_cb = frame,
		cleanup_cb = cleanup,
		width = 1280,
		height = 720,
		sample_count = 4,
		window_title = IS_WEB ? "Odin + Sokol on the web" : "Odin + Sokol",
		icon = { sokol_default = true },
		logger = { func = slog.func },
		html5_update_document_title = true,
	})
}

init :: proc "c" () {
	context = custom_context
	sg.setup({
		environment = sglue.environment(),
		logger = { func = slog.func },
	})

	/*
		Cube vertex buffer with packed vertex formats for color and texture coords.
		Note that a vertex format which must be portable across all
		backends must only use the normalized integer formats
		(BYTE4N, UBYTE4N, SHORT2N, SHORT4N), which can be converted
		to floating point formats in the vertex shader inputs.
	*/
	vertices := [?]Vertex {
		// pos               color       uvs
		{ -1.0, -1.0, -1.0,  0xFF0000FF,     0,     0 },
		{  1.0, -1.0, -1.0,  0xFF0000FF, 32767,     0 },
		{  1.0,  1.0, -1.0,  0xFF0000FF, 32767, 32767 },
		{ -1.0,  1.0, -1.0,  0xFF0000FF,     0, 32767 },

		{ -1.0, -1.0,  1.0,  0xFF00FF00,     0,     0 },
		{  1.0, -1.0,  1.0,  0xFF00FF00, 32767,     0 },
		{  1.0,  1.0,  1.0,  0xFF00FF00, 32767, 32767 },
		{ -1.0,  1.0,  1.0,  0xFF00FF00,     0, 32767 },

		{ -1.0, -1.0, -1.0,  0xFFFF0000,     0,     0 },
		{ -1.0,  1.0, -1.0,  0xFFFF0000, 32767,     0 },
		{ -1.0,  1.0,  1.0,  0xFFFF0000, 32767, 32767 },
		{ -1.0, -1.0,  1.0,  0xFFFF0000,     0, 32767 },

		{  1.0, -1.0, -1.0,  0xFFFF007F,     0,     0 },
		{  1.0,  1.0, -1.0,  0xFFFF007F, 32767,     0 },
		{  1.0,  1.0,  1.0,  0xFFFF007F, 32767, 32767 },
		{  1.0, -1.0,  1.0,  0xFFFF007F,     0, 32767 },

		{ -1.0, -1.0, -1.0,  0xFFFF7F00,     0,     0 },
		{ -1.0, -1.0,  1.0,  0xFFFF7F00, 32767,     0 },
		{  1.0, -1.0,  1.0,  0xFFFF7F00, 32767, 32767 },
		{  1.0, -1.0, -1.0,  0xFFFF7F00,     0, 32767 },

		{ -1.0,  1.0, -1.0,  0xFF007FFF,     0,     0 },
		{ -1.0,  1.0,  1.0,  0xFF007FFF, 32767,     0 },
		{  1.0,  1.0,  1.0,  0xFF007FFF, 32767, 32767 },
		{  1.0,  1.0, -1.0,  0xFF007FFF,     0, 32767 },
	}
	state.bind.vertex_buffers[0] = sg.make_buffer({
		data = { ptr = &vertices, size = size_of(vertices) },
	})

	// create an index buffer for the cube
	indices := [?]u16 {
		0, 1, 2,  0, 2, 3,
		6, 5, 4,  7, 6, 4,
		8, 9, 10,  8, 10, 11,
		14, 13, 12,  15, 14, 12,
		16, 17, 18,  16, 18, 19,
		22, 21, 20,  23, 22, 20,
	}
	state.bind.index_buffer = sg.make_buffer({
		type = .INDEXBUFFER,
		data = { ptr = &indices, size = size_of(indices) },
	})

	if img_data, img_data_ok := read_entire_file("assets/round_cat.png", context.temp_allocator); img_data_ok {
		if img, img_err := png.load_from_bytes(img_data, allocator = context.temp_allocator); img_err == nil {
			state.bind.images[IMG_tex] = sg.make_image({
				width = i32(img.width),
				height = i32(img.height),
				data = {
					subimage = {
						0 = {
							0 = { ptr = raw_data(img.pixels.buf), size = uint(slice.size(img.pixels.buf[:])) },
						},
					},
				},
			})
		} else {
			log.error(img_err)
		}
	} else {
		log.error("Failed loading texture")
	}

	// a sampler with default options to sample the above image as texture
	state.bind.samplers[SMP_smp] = sg.make_sampler({})

	// shader and pipeline object
	state.pip = sg.make_pipeline({
		shader = sg.make_shader(texcube_shader_desc(sg.query_backend())),
		layout = {
			attrs = {
				ATTR_texcube_pos = { format = .FLOAT3 },
				ATTR_texcube_color0 = { format = .UBYTE4N },
				ATTR_texcube_texcoord0 = { format = .SHORT2N },
			},
		},
		index_type = .UINT16,
		cull_mode = .BACK,
		depth = {
			compare = .LESS_EQUAL,
			write_enabled = true,
		},
	})

	// default pass action, clear to blue-ish
	state.pass_action = {
		colors = {
			0 = { load_action = .CLEAR, clear_value = { 0.41, 0.68, 0.83, 1 } },
		},
	}
}

frame :: proc "c" () {
	context = custom_context
	dt := f32(sapp.frame_duration())
	state.rx += 60.0 * dt
	state.ry += 120.0 * dt

	// vertex shader uniform with model-view-projection matrix
	vs_params := Vs_Params {
		mvp = compute_mvp(state.rx, state.ry),
	}

	sg.begin_pass({ action = state.pass_action, swapchain = sglue.swapchain() })
	sg.apply_pipeline(state.pip)
	sg.apply_bindings(state.bind)
	sg.apply_uniforms(UB_vs_params, { ptr = &vs_params, size = size_of(vs_params) })

	// 36 is the number of indices
	sg.draw(0, 36, 1)

	sg.end_pass()
	sg.commit()

	free_all(context.temp_allocator)
}

cleanup :: proc "c" () {
	context = custom_context
	sg.shutdown()

	// This is "the end of the program": sokol is shutting down. When on web
	// there is no definitive point to run all procs tagged with @(fini). This
	// will run those procedures now.
	when IS_WEB {
		runtime._cleanup_runtime()
	}
}

compute_mvp :: proc (rx, ry: f32) -> Mat4 {
	proj := linalg.matrix4_perspective(60.0 * linalg.RAD_PER_DEG, sapp.widthf() / sapp.heightf(), 0.01, 10.0)
	view := linalg.matrix4_look_at_f32({0.0, -1.5, -6.0}, {}, {0.0, 1.0, 0.0})
	view_proj := proj * view
	rxm := linalg.matrix4_rotate_f32(rx * linalg.RAD_PER_DEG, {1.0, 0.0, 0.0})
	rym := linalg.matrix4_rotate_f32(ry * linalg.RAD_PER_DEG, {0.0, 1.0, 0.0})
	model := rxm * rym
	return view_proj * model
}

// read and write files. Works with both desktop OS and also emscripten virtual
// file system.

@(require_results)
read_entire_file :: proc(name: string, allocator := context.allocator, loc := #caller_location) -> (data: []byte, success: bool) {
	when IS_WEB {
		return web.read_entire_file(name, allocator, loc)
	} else {
		return os.read_entire_file(name, allocator, loc)
	}
}

write_entire_file :: proc(name: string, data: []byte, truncate := true) -> (success: bool) {
	when IS_WEB {
		return web.write_entire_file(name, data, truncate)
	} else {
		return os.write_entire_file(name, data, truncate)
	}
}