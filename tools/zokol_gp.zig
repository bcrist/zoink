
// Minimal efficient cross platform 2D graphics painter for Sokol GFX.
// sokol_gp - v0.6.0 - 25/Jul/2024
// Eduardo Bart - edub4rt@gmail.com
// https://github.com/edubart/sokol_gp

// # Sokol GP

// Minimal efficient cross platform 2D graphics painter in pure C
// using modern graphics API through the excellent [Sokol GFX](https://github.com/floooh/sokol) library.

// Sokol GP, or in short SGP, stands for Sokol Graphics Painter.

// ![sample-primitives](https://raw.githubusercontent.com/edubart/sokol_gp/master/screenshots/sample-primitives.png)

// ## Features

// * Made and optimized only for **2D rendering only**, no 3D support.
// * Minimal, in a pure single C header.
// * Use modern unfixed pipeline graphics APIs for more efficiency.
// * Cross platform (backed by Sokol GFX).
// * D3D11/OpenGL 3.3/Metal/WebGPU graphics backends (through Sokol GFX).
// * **Automatic batching** (merge recent draw calls into batches automatically).
// * **Batch optimizer** (rearranges the ordering of draw calls to batch more).
// * Uses preallocated memory (no allocations at runtime).
// * Supports drawing basic 2D primitives (rectangles, triangles, lines and points).
// * Supports the classic 2D color blending modes (color blend, add, modulate, multiply).
// * Supports 2D space transformations and changing 2D space coordinate systems.
// * Supports drawing the basic primitives (rectangles, triangles, lines and points).
// * Supports multiple texture bindings.
// * Supports custom fragment shaders with 2D primitives.
// * Can be mixed with projects that are already using Sokol GFX.

// ## Why?

// Sokol GFX is an excellent library for rendering using unfixed pipelines
// of modern graphics cards, but it is too complex to use for simple 2D drawing,
// and it's API is too generic and specialized for 3D rendering. To draw 2D stuff, the programmer
// usually needs to setup custom shaders when using Sokol GFX, or use its Sokol GL
// extra library, but Sokol GL also has an API with 3D design in mind, which
// incurs some costs and limitations.

// This library was created to draw 2D primitives through Sokol GFX with ease,
// and by not considering 3D usage it is optimized for 2D rendering only,
// furthermore it features an **automatic batch optimizer**, more details of it will be described below.

// ## Automatic batch optimizer

// When drawing the library creates a draw command queue of all primitives yet to be drawn,
// every time a new draw command is added the batch optimizer looks back up to the last
// 8 recent draw commands (this is adjustable), and try to rearrange and merge drawing commands
// if it finds a previous draw command that meets the following criteria:

// * The new draw command and previous command uses the *same primitive pipeline*
// * The new draw command and previous command uses the *same shader uniforms*
// * The new draw command and previous command uses the *same texture bindings*
// * The new draw command and previous command does not have another intermediary
// draw command *that overlaps* in-between them.

// By doing this the batch optimizer is able for example to merge textured draw calls,
// even if they were drawn with other intermediary different textures draws between them.
// The effect is more efficiency when drawing, because less draw calls will be dispatched
// to the GPU,

// This library can avoid a lot of work of making an efficient 2D drawing batching system,
// by automatically merging draw calls behind the scenes at runtime,
// thus the programmer does not need to manage batched draw calls manually,
// nor he needs to sort batched texture draw calls,
// the library will do this seamlessly behind the scenes.

// The batching algorithm is fast, but it has `O(n)` CPU complexity for every new draw command added,
// where `n` is the `SGP_BATCH_OPTIMIZER_DEPTH` configuration.
// In experiments using `8` as the default is a good default,
// but you may want to try out different values depending on your case.
// Using values that are too high is not recommended, because the algorithm may take too long
// scanning previous draw commands, and that may consume more CPU resources.

// The batch optimizer can be disabled by setting `SGP_BATCH_OPTIMIZER_DEPTH` to 0,
// you can use that to measure its impact.

// In the samples directory of this repository there is a
// benchmark example that tests drawing with the bath optimizer enabled/disabled.
// On my machine that benchmark was able to increase performance in a 2.2x factor when it is enabled.
// In some private game projects the gains of the batch optimizer proved to increase FPS performance
// above 1.5x by just replacing the graphics backend with this library, with no internal
// changes to the game itself.

// ## Design choices

// The library has some design choices with performance in mind that will be discussed briefly here.

// Like Sokol GFX, Sokol GP will never do any allocation in the draw loop,
// so when initializing you must configure beforehand the maximum size of the
// draw command queue buffer and the vertices buffer.

// All the 2D space transformation (functions like `sgp_rotate`) are done by the CPU and not by the GPU,
// this is intentionally to avoid adding extra overhead in the GPU, because typically the number
// of vertices of 2D applications are not that large, and it is more efficient to perform
// all the transformation with the CPU right away rather than pushing extra buffers to the GPU
// that ends up using more bandwidth of the CPU<->GPU bus.
// In contrast 3D applications usually dispatches vertex transformations to the GPU using a vertex shader,
// they do this because the amount of vertices of 3D objects can be very large
// and it is usually the best choice, but this is not true for 2D rendering.

// Many APIs to transform the 2D space before drawing a primitive are available, such as
// translate, rotate and scale. They can be used as similarly as the ones available in 3D graphics APIs,
// but they are crafted for 2D only, for example when using 2D we don't need to use a 4x4 or 3x3 matrix
// to perform vertex transformation, instead the code is specialized for 2D and can use a 2x3 matrix,
// saving extra CPU float computations.

// All pipelines always use a texture associated with it, even when drawing non textured primitives,
// because this minimizes graphics pipeline changes when mixing textured calls and non textured calls,
// improving efficiency.

// The library is coded in the style of Sokol GFX headers, reusing many macros from there,
// you can change some of its semantics such as custom allocator, custom log function, and some
// other details, read `sokol_gfx.h` documentation for more on that.

// ## Usage

// Copy `sokol_gp.h` along with other Sokol headers to the same folder. Setup Sokol GFX
// as you usually would, then add call to `sgp_setup(desc)` just after `sg_setup(desc)`, and
// call to `sgp_shutdown()` just before `sg_shutdown()`. Note that you should usually check if
// SGP is valid after its creation with `sgp_is_valid()` and exit gracefully with an error if not.

// In your frame draw function add `sgp_begin(width, height)` before calling any SGP
// draw function, then draw your primitives. At the end of the frame (or framebuffer) you
// should **ALWAYS call** `sgp_flush()` between a Sokol GFX begin/end render pass,
// the `sgp_flush()` will dispatch all draw commands to Sokol GFX. Then call `sgp_end()` immediately
// to discard the draw command queue.

// An actual example of this setup will be shown below.

// ## Quick usage example

// The following is a quick example on how to this library with Sokol GFX and Sokol APP:

// ```c
// // This is an example on how to set up and use Sokol GP to draw a filled rectangle.

// // Includes Sokol GFX, Sokol GP and Sokol APP, doing all implementations.
// #define SOKOL_IMPL
// #include "sokol_gfx.h"
// #include "sokol_gp.h"
// #include "sokol_app.h"
// #include "sokol_glue.h"
// #include "sokol_log.h"

// #include <stdio.h> // for fprintf()
// #include <stdlib.h> // for exit()
// #include <math.h> // for sinf() and cosf()

// // Called on every frame of the application.
// static void frame(void) {
//     // Get current window size.
//     int width = sapp_width(), height = sapp_height();
//     float ratio = width/(float)height;

//     // Begin recording draw commands for a frame buffer of size (width, height).
//     sgp_begin(width, height);
//     // Set frame buffer drawing region to (0,0,width,height).
//     sgp_viewport(0, 0, width, height);
//     // Set drawing coordinate space to (left=-ratio, right=ratio, top=1, bottom=-1).
//     sgp_project(-ratio, ratio, 1.0f, -1.0f);

//     // Clear the frame buffer.
//     sgp_set_color(0.1f, 0.1f, 0.1f, 1.0f);
//     sgp_clear();

//     // Draw an animated rectangle that rotates and changes its colors.
//     float time = sapp_frame_count() * sapp_frame_duration();
//     float r = sinf(time)*0.5+0.5, g = cosf(time)*0.5+0.5;
//     sgp_set_color(r, g, 0.3f, 1.0f);
//     sgp_rotate_at(time, 0.0f, 0.0f);
//     sgp_draw_filled_rect(-0.5f, -0.5f, 1.0f, 1.0f);

//     // Begin a render pass.
//     sg_pass pass = {.swapchain = sglue_swapchain()};
//     sg_begin_pass(&pass);
//     // Dispatch all draw commands to Sokol GFX.
//     sgp_flush();
//     // Finish a draw command queue, clearing it.
//     sgp_end();
//     // End render pass.
//     sg_end_pass();
//     // Commit Sokol render.
//     sg_commit();
// }

// // Called when the application is initializing.
// static void init(void) {
//     // Initialize Sokol GFX.
//     sg_desc sgdesc = {
//         .environment = sglue_environment(),
//         .logger.func = slog_func
//     };
//     sg_setup(&sgdesc);
//     if (!sg_isvalid()) {
//         fprintf(stderr, "Failed to create Sokol GFX context!\n");
//         exit(-1);
//     }

//     // Initialize Sokol GP, adjust the size of command buffers for your own use.
//     sgp_desc sgpdesc = {0};
//     sgp_setup(&sgpdesc);
//     if (!sgp_is_valid()) {
//         fprintf(stderr, "Failed to create Sokol GP context: %s\n", sgp_get_error_message(sgp_get_last_error()));
//         exit(-1);
//     }
// }

// // Called when the application is shutting down.
// static void cleanup(void) {
//     // Cleanup Sokol GP and Sokol GFX resources.
//     sgp_shutdown();
//     sg_shutdown();
// }

// // Implement application main through Sokol APP.
// sapp_desc sokol_main(int argc, char* argv[]) {
//     (void)argc;
//     (void)argv;
//     return (sapp_desc){
//         .init_cb = init,
//         .frame_cb = frame,
//         .cleanup_cb = cleanup,
//         .window_title = "Rectangle (Sokol GP)",
//         .logger.func = slog_func,
//     };
// }
// ```

// To run this example, first copy the `sokol_gp.h` header alongside with other Sokol headers
// to the same folder, then compile with any C compiler using the proper linking flags (read `sokol_gfx.h`).

// ## Complete Examples

// In folder `samples` you can find the following complete examples covering all APIs of the library:

// * [sample-primitives.c](https://github.com/edubart/sokol_gp/blob/master/samples/sample-primitives.c): This is an example showing all drawing primitives and transformations APIs.
// * [sample-blend.c](https://github.com/edubart/sokol_gp/blob/master/samples/sample-blend.c): This is an example showing all blend modes between 3 rectangles.
// * [sample-framebuffer.c](https://github.com/edubart/sokol_gp/blob/master/samples/sample-framebuffer.c): This is an example showing how to use multiple `sgp_begin()` with frame buffers.
// * [sample-sdf.c](https://github.com/edubart/sokol_gp/blob/master/samples/sample-sdf.c): This is an example on how to create custom shaders.
// * [sample-effect.c](https://github.com/edubart/sokol_gp/blob/master/samples/sample-effect.c): This is an example on how to use custom shaders for 2D drawing.
// * [sample-bench.c](https://github.com/edubart/sokol_gp/blob/master/samples/sample-bench.c): This is a heavy example used for benchmarking purposes.

// These examples are used as the test suite for the library, you can build them by typing `make`.

// ## Error handling

// It is possible that after many draw calls the command or vertex buffer may overflow,
// in that case the library will set an error error state and will continue to operate normally,
// but when flushing the drawing command queue with `sgp_flush()` no draw command will be dispatched.
// This can happen because the library uses pre allocated buffers, in such
// cases the issue can be fixed by increasing the prefixed command queue buffer and the vertices buffer
// when calling `sgp_setup()`.

// Making invalid number of push/pops of `sgp_push_transform()` and `sgp_pop_transform()`,
// or nesting too many `sgp_begin()` and `sgp_end()` may also lead to errors, that
// is a usage mistake.

// ## Blend modes

// The library supports the most usual blend modes used in 2D, which are the following:

// - `SGP_BLENDMODE_NONE` - No blending (`dstRGBA = srcRGBA`).
// - `SGP_BLENDMODE_BLEND` - Alpha blending (`dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))` and `dstA = srcA + (dstA * (1-srcA))`)
// - `SGP_BLENDMODE_ADD` - Color add (`dstRGB = (srcRGB * srcA) + dstRGB` and `dstA = dstA`)
// - `SGP_BLENDMODE_MOD` - Color modulate (`dstRGB = srcRGB * dstRGB` and `dstA = dstA`)
// - `SGP_BLENDMODE_MUL` - Color multiply (`dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))` and `dstA = (srcA * dstA) + (dstA * (1-srcA))`)

// ## Changing 2D coordinate system

// You can change the screen area to draw by calling `sgp_viewport(x, y, width, height)`.
// You can change the coordinate system of the 2D space by calling `sgp_project(left, right, top, bottom)`,
// with it.

// ## Transforming 2D space

// You can translate, rotate or scale the 2D space before a draw call, by using the transformation
// functions the library provides, such as `sgp_translate(x, y)`, `sgp_rotate(theta)`, etc.
// Check the cheat sheet or the header for more.

// To save and restore the transformation state you should call `sgp_push_transform()` and
// later `sgp_pop_transform()`.

// ## Drawing primitives

// The library provides drawing functions for all the basic primitives, that is,
// for points, lines, triangles and rectangles, such as `sgp_draw_line()` and `sgp_draw_filled_rect()`.
// Check the cheat sheet or the header for more.
// All of them have batched variations.

// ## Drawing textured primitives

// To draw textured rectangles you can use `sgp_set_image(0, img)` and then sgp_draw_filled_rect()`,
// this will draw an entire texture into a rectangle.
// You should later reset the image with `sgp_reset_image(0)` to restore the bound image to default white image,
// otherwise you will have glitches when drawing a solid color.

// In case you want to draw a specific source from the texture,
// you should use `sgp_draw_textured_rect()` instead.

// By default textures are drawn using a simple nearest filter sampler,
// you can change the sampler with `sgp_set_sampler(0, smp)` before drawing a texture,
// it's recommended to restore the default sampler using `sgp_reset_sampler(0)`.

// ## Color modulation

// All common pipelines have color modulation, and you can modulate
// a color before a draw by setting the current state color with `sgp_set_color(r,g,b,a)`,
// later you should reset the color to default (white) with `sgp_reset_color()`.

// ## Custom shaders

// When using a custom shader, you must create a pipeline for it with `sgp_make_pipeline(desc)`,
// using shader, blend mode and a draw primitive associated with it. Then you should
// call `sgp_set_pipeline()` before the shader draw call. You are responsible for using
// the same blend mode and drawing primitive as the created pipeline.

// Custom uniforms can be passed to the shader with `sgp_set_uniform(data, size)`,
// where you should always pass a pointer to a struct with exactly the same schema and size
// as the one defined in the shader.

// Although you can create custom shaders for each graphics backend manually,
// it is advised should use the Sokol shader compiler [SHDC](https://github.com/floooh/sokol-tools/blob/master/docs/sokol-shdc.md),
// because it can generate shaders for multiple backends from a single `.glsl` file,
// and this usually works well.

// By default the library uniform buffer per draw call has just 4 float uniforms
// (`SGP_UNIFORM_CONTENT_SLOTS` configuration), and that may be too low to use with custom shaders.
// This is the default because typically newcomers may not want to use custom 2D shaders,
// and increasing a larger value means more overhead.
// If you are using custom shaders please increase this value to be large enough to hold
// the number of uniforms of your largest shader.

// ## Library configuration

// The following macros can be defined before including to change the library behavior:

// - `SGP_BATCH_OPTIMIZER_DEPTH` - Number of draw commands that the batch optimizer looks back at. Default is 8.
// - `SGP_UNIFORM_CONTENT_SLOTS` - Maximum number of floats that can be stored in each draw call uniform buffer. Default is 4.
// - `SGP_TEXTURE_SLOTS` - Maximum number of textures that can be bound per draw call. Default is 4.

// ## License

// MIT, see LICENSE file or the end of `sokol_gp.h` file.


// Number of draw commands that the batch optimizer looks back at.
// 8 is a fair default value, but could be tuned per application.
// 1 makes the batch optimizer try to merge only the very last draw call.
// 0 disables the batch optimizer
const batch_optimizer_depth = 8;

// Number of uniform floats (4-bytes) slots that can be set in a shader.
// Increase this value if you need to use shader with many uniforms.
const uniform_content_slots = 4;

// Number of texture slots that can be bound in a pipeline.
const texture_slots = 4;

const Blend_Mode = enum {
    /// No blending.
    ///dstRGBA = srcRGBA
    none,

    /// Alpha blending.
    /// dstRGB = (srcRGB * srcA) + (dstRGB * (1-srcA))
    /// dstA = srcA + (dstA * (1-srcA))
    blend,

    /// Color add.
    /// dstRGB = (srcRGB * srcA) + dstRGB
    /// dstA = dstA
    add,

    /// Color modulate.
    /// dstRGB = srcRGB * dstRGB
    /// dstA = dstA
    mod,

    /// Color multiply.
    /// dstRGB = (srcRGB * dstRGB) + (dstRGB * (1-srcA))
    /// dstA = (srcA * dstA) + (dstA * (1-srcA))
    mul,

    pub fn blend_state(self: Blend_Mode) sokol.gfx.BlendState {
        var blend: sokol.gfx.BlendState = .{};
        switch (self) {
            .none => {
                blend.enabled = false;
                blend.src_factor_rgb = .ONE;
                blend.dst_factor_rgb = .ZERO;
                blend.op_rgb = .ADD;
                blend.src_factor_alpha = .ONE;
                blend.dst_factor_alpha = .ZERO;
                blend.op_alpha = .ADD;
            },
            .blend => {
                blend.enabled = true;
                blend.src_factor_rgb = .SRC_ALPHA;
                blend.dst_factor_rgb = .ONE_MINUS_SRC_ALPHA;
                blend.op_rgb = .ADD;
                blend.src_factor_alpha = .ONE;
                blend.dst_factor_alpha = .ONE_MINUS_SRC_ALPHA;
                blend.op_alpha = .ADD;
            },
            .add => {
                blend.enabled = true;
                blend.src_factor_rgb = .SRC_ALPHA;
                blend.dst_factor_rgb = .ONE;
                blend.op_rgb = .ADD;
                blend.src_factor_alpha = .ZERO;
                blend.dst_factor_alpha = .ONE;
                blend.op_alpha = .ADD;
            },
            .mod => {
                blend.enabled = true;
                blend.src_factor_rgb = .DST_COLOR;
                blend.dst_factor_rgb = .ZERO;
                blend.op_rgb = .ADD;
                blend.src_factor_alpha = .ZERO;
                blend.dst_factor_alpha = .ONE;
                blend.op_alpha = .ADD;
            },
            .mul => {
                blend.enabled = true;
                blend.src_factor_rgb = .DST_COLOR;
                blend.dst_factor_rgb = .ONE_MINUS_SRC_ALPHA;
                blend.op_rgb = .ADD;
                blend.src_factor_alpha = .DST_ALPHA;
                blend.dst_factor_alpha = .ONE_MINUS_SRC_ALPHA;
                blend.op_alpha = .ADD;
            },
        }
        return blend;
    }
};

const vs_attr_coord = 0;
const vs_attr_color = 1;

fn Size(comptime T: type) type {
    return struct {
        w: T,
        h: T,
    };
}

fn Rect(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        w: T,
        h: T,
    };
}

const ISize = Size(i32);
const IRect = Rect(i32);
const FRect = Rect(f32);

const Textured_Rect = struct {
    dest: FRect,
    src: FRect,
};

const Vec2 = extern struct {
    x: f32,
    y: f32,

    pub const zeroes: Vec2 = .{ .x = 0, .y = 0 };
};

const Point = Vec2;

const Line = extern struct {
    a: Point,
    b: Point,
};

const Quad = extern struct {
    a: Point, // bottom left
    b: Point, // bottom right
    c: Point, // top right
    d: Point, // top left
};

const Triangle = extern struct {
    a: Point,
    b: Point,
    c: Point,
};

const Mat2x3 = struct {
    v: [2][3]f32,

    pub const identity: Mat2x3 = .{ .v = .{
        .{ 1.0, 0.0, 0.0 },
        .{ 0.0, 1.0, 0.0 },
    }};
};

pub const Color = struct {
    r: f32,
    g: f32,
    b: f32,
    a: f32 = 1.0,
};

pub const Color_UB4 = extern struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub const white: Color_UB4 = .{
        .r = 255,
        .g = 255,
        .b = 255,
    };
};

pub const Vertex = extern struct {
    position: Vec2,
    texcoord: Vec2,
    color: Color_UB4,
};

const Index = u32;

const Uniform = struct {
    size: u32 = 0,
    content: [uniform_content_slots]u32 = .{ 0 } ** uniform_content_slots,
    
    pub fn bytes(self: *const Uniform) []const u8 {
        return std.mem.asBytes(self)[0..self.size];
    }
};

const Textures_Uniform = struct {
    count: u32 = 0,
    images: [texture_slots]sokol.gfx.Image = @splat(.{}),
    samplers: [texture_slots]sokol.gfx.Sampler = @splat(.{}),

    pub fn active_images(self: *const Textures_Uniform) []const sokol.gfx.Image {
        return self.images[0..self.count];
    }
    pub fn active_samplers(self: *const Textures_Uniform) []const sokol.gfx.Sampler {
        return self.samplers[0..self.count];
    }
};

const State = struct {
    frame_size: ISize,
    viewport: IRect,
    scissor: IRect,
    proj: Mat2x3,
    transform: Mat2x3,
    mvp: Mat2x3,
    thickness: f32,
    color: Color_UB4,
    textures: Textures_Uniform,
    uniform: Uniform,
    blend_mode: Blend_Mode,
    pipeline: sokol.gfx.Pipeline,
};

// Structure that defines SGP setup parameters.
const Desc = struct {
    allocator: std.mem.Allocator,
    max_indices: u32 = default_max_indices,
    max_vertices: u32 = default_max_vertices,
    max_commands: u32 = default_max_commands,
    color_format: ?sokol.gfx.PixelFormat = null, // Color format for creating pipelines, defaults to the same as the Sokol GFX context.
    depth_format: ?sokol.gfx.PixelFormat = null, // Depth format for creating pipelines, defaults to the same as the Sokol GFX context.
    sample_count: ?i32 = null, // Sample count for creating pipelines, defaults to the same as the Sokol GFX context.
};

// Structure that defines SGP custom pipeline creation parameters.
const Pipeline_Desc = struct {
    shader: sokol.gfx.Shader,
    primitive_type: sokol.gfx.PrimitiveType = .TRIANGLES,
    blend_mode: Blend_Mode = .none,
    color_format: ?sokol.gfx.PixelFormat = null,
    depth_format: ?sokol.gfx.PixelFormat = null,
    sample_count: ?i32 = null,
    has_vs_color: bool, // If true, the current color state will be passed as an attribute to the vertex shader.
};


// Initializes the SGP context, and should be called after `sg_setup`.
pub fn setup(desc: Desc) !void {
    std.debug.assert(sgp.init_cookie == 0);

    if (!sokol.gfx.isvalid()) return error.SokolInvalid;

    sgp.init_cookie = init_cookie;
    errdefer sgp.init_cookie = 0;

    const env_defaults = sokol.gfx.queryDesc().environment.defaults;

    sgp.desc = desc;
    sgp.desc.max_indices = desc.max_indices;
    sgp.desc.max_vertices = desc.max_vertices;
    sgp.desc.max_commands = desc.max_commands;
    sgp.desc.color_format = desc.color_format orelse env_defaults.color_format;
    sgp.desc.depth_format = desc.depth_format orelse env_defaults.depth_format;
    sgp.desc.sample_count = desc.sample_count orelse env_defaults.sample_count;

    sgp.indices = try desc.allocator.alloc(Index, sgp.desc.max_indices);
    errdefer sgp.desc.allocator.free(sgp.indices);
    @memset(sgp.indices, 0);

    sgp.vertices = try desc.allocator.alloc(Vertex, sgp.desc.max_vertices);
    errdefer sgp.desc.allocator.free(sgp.vertices);
    @memset(sgp.vertices, .{
        .position = .{ .x = 0, .y = 0 },
        .texcoord = .{ .x = 0, .y = 0 },
        .color = Color_UB4.white,
    });

    sgp.uniforms = try desc.allocator.alloc(Uniform, sgp.desc.max_commands);
    errdefer sgp.desc.allocator.free(sgp.uniforms);
    @memset(sgp.uniforms, .{});

    sgp.commands = try desc.allocator.alloc(Command, sgp.desc.max_commands);
    errdefer sgp.desc.allocator.free(sgp.commands);
    @memset(sgp.commands, .none);

    // create index buffer
    sgp.index_buf = sokol.gfx.makeBuffer(.{
        .size = sgp.indices.len * @sizeOf(Index),
        .usage = .{
            .stream_update = true,
            .index_buffer = true,
        },
    });
    errdefer if (sgp.index_buf.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyBuffer(sgp.index_buf);
    };

    // create vertex buffer
    sgp.vertex_buf = sokol.gfx.makeBuffer(.{
        .size = sgp.vertices.len * @sizeOf(Vertex),
        .usage = .{
            .vertex_buffer = true,
            .stream_update = true,
        },
    });
    errdefer if (sgp.vertex_buf.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyBuffer(sgp.vertex_buf);
    };
    if (sokol.gfx.queryBufferState(sgp.vertex_buf) != .VALID) return error.MakeVertexBufferFailed;

    // create white texture
    const pixels: [4]u32 = .{ 0xFFFF_FFFF } ** 4;
    var white_img_desc: sokol.gfx.ImageDesc = .{
        .type = ._2D,
        .width = 2,
        .height = 2,
        .pixel_format = .RGBA8,
        .label = "sgp-white-texture",
    };
    white_img_desc.data.subimage[0][0].ptr = &pixels;
    white_img_desc.data.subimage[0][0].size = @sizeOf(u32) * pixels.len;
    
    sgp.white_img = sokol.gfx.makeImage(white_img_desc);
    errdefer if (sgp.white_img.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyImage(sgp.white_img);
    };
    if (sokol.gfx.queryImageState(sgp.white_img) != .VALID) return error.MakeWhiteImageFailed;

    // create nearest sampler
    sgp.nearest_smp = sokol.gfx.makeSampler(.{
        .label = "sgp-nearest-sampler",
    });
    errdefer if (sgp.nearest_smp.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroySampler(sgp.nearest_smp);
    };
    if (sokol.gfx.querySamplerState(sgp.nearest_smp) != .VALID) return error.MakeNearestSamplerFailed;

    // create common shader
    sgp.shader = make_common_shader();
    errdefer if (sgp.shader.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyShader(sgp.shader);
    };
    if (sokol.gfx.queryShaderState(sgp.shader) != .VALID) return error.MakeCommonShaderFailed;

    // create common pipelines
    errdefer for (sgp.pipelines) |pip| {
        if (pip.id != sokol.gfx.invalid_id) {
            sokol.gfx.destroyPipeline(pip);
        }
    };
    if ((try lookup_pipeline(.TRIANGLES, .none)).id == sokol.gfx.invalid_id) return error.MakeCommonPipelineFailed;
    if ((try lookup_pipeline(.TRIANGLES, .blend)).id == sokol.gfx.invalid_id) return error.MakeCommonPipelineFailed;
    if ((try lookup_pipeline(.POINTS, .none)).id == sokol.gfx.invalid_id) return error.MakeCommonPipelineFailed;
    if ((try lookup_pipeline(.POINTS, .blend)).id == sokol.gfx.invalid_id) return error.MakeCommonPipelineFailed;
    if ((try lookup_pipeline(.LINES, .none)).id == sokol.gfx.invalid_id) return error.MakeCommonPipelineFailed;
    if ((try lookup_pipeline(.LINES, .blend)).id == sokol.gfx.invalid_id) return error.MakeCommonPipelineFailed;
}

// Destroys the SGP context.
pub fn shutdown() void {
    if (sgp.init_cookie == 0) {
        return; // not initialized
    }
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state == 0);
    
    sgp.desc.allocator.free(sgp.indices);
    sgp.desc.allocator.free(sgp.vertices);
    sgp.desc.allocator.free(sgp.uniforms);
    sgp.desc.allocator.free(sgp.commands);

    for (sgp.pipelines) |pip| {
        if (pip.id != sokol.gfx.invalid_id) {
            sokol.gfx.destroyPipeline(pip);
        }
    }
    if (sgp.shader.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyShader(sgp.shader);
    }
    if (sgp.vertex_buf.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyBuffer(sgp.vertex_buf);
    }
    if (sgp.index_buf.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyBuffer(sgp.index_buf);
    }
    if (sgp.white_img.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroyImage(sgp.white_img);
    }
    if (sgp.nearest_smp.id != sokol.gfx.invalid_id) {
        sokol.gfx.destroySampler(sgp.nearest_smp);
    }

    sgp.init_cookie = 0;
}

pub fn is_valid() bool {
    return sgp.init_cookie == init_cookie;
}

// Creates a custom shader pipeline to be used with SGP.
pub fn make_pipeline(desc: *const Pipeline_Desc) !sokol.gfx.Pipeline {
    return make_pipeline_internal(
        desc.shader,
        desc.primitive_type,
        desc.blend_mode,
        desc.color_format orelse sgp.desc.color_format,
        desc.depth_format orelse sgp.desc.depth_format,
        desc.sample_count orelse sgp.desc.sample_count,
        desc.has_vs_color
    );
}

// Begins a new SGP draw command queue.
pub fn begin(width: i32, height: i32) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    if (sgp.cur_state >= max_stack_depth) return error.StateStackOverflow;

    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);

    // save current state
    sgp.state_stack[sgp.cur_state] = sgp.state;
    sgp.cur_state += 1;

    // reset to default state
    sgp.state.frame_size.w = width; sgp.state.frame_size.h = height;
    sgp.state.viewport.x = 0; sgp.state.viewport.y = 0;
    sgp.state.viewport.w = width; sgp.state.viewport.h = height;
    sgp.state.scissor.x = 0; sgp.state.scissor.y = 0;
    sgp.state.scissor.w = -1; sgp.state.scissor.h = -1;
    sgp.state.proj = default_proj(width, height);
    sgp.state.transform = Mat2x3.identity;
    sgp.state.mvp = sgp.state.proj;
    sgp.state.thickness = @max(1.0 / w, 1.0 / h);
    sgp.state.color = Color_UB4.white;
    sgp.state.uniform = .{};
    sgp.state.uniform.size = 0;
    sgp.state.blend_mode = .none;
    std.debug.assert(sgp.cur_index == 0);
    std.debug.assert(sgp.cur_vertex == 0);
    std.debug.assert(sgp.cur_uniform == 0);
    std.debug.assert(sgp.cur_command == 0);

    for (&sgp.state.textures.images, &sgp.state.textures.samplers) |*img, *sampler| {
        img.* = .{};
        sampler.* = sgp.nearest_smp;
    }
    sgp.state.textures.images[0] = sgp.white_img;
    sgp.state.textures.count = 1;
}

// Dispatch current Sokol GFX draw commands.
pub fn render() !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);

    const end_command = sgp.cur_command;
    const end_vertex = sgp.cur_vertex;
    const end_index = sgp.cur_index;

    // rewind indexes
    sgp.cur_index = 0;
    sgp.cur_vertex = 0;
    sgp.cur_uniform = 0;
    sgp.cur_command = 0;

    // nothing to be drawn
    if (end_command <= 0) return;

    // upload indices
    const num_indices = end_index;
    const index_range: sokol.gfx.Range = .{ .ptr = sgp.indices.ptr, .size = num_indices * @sizeOf(Index) };
    const index_offset = sokol.gfx.appendBuffer(sgp.index_buf, index_range);
    if (sokol.gfx.queryBufferOverflow(sgp.index_buf)) return error.IndexBufferOverflow;

    // upload vertices
    const num_vertices = end_vertex;
    const vertex_range: sokol.gfx.Range = .{ .ptr = sgp.vertices.ptr, .size = num_vertices * @sizeOf(Vertex) };
    const vertex_offset = sokol.gfx.appendBuffer(sgp.vertex_buf, vertex_range);
    if (sokol.gfx.queryBufferOverflow(sgp.vertex_buf)) return error.VertexBufferOverflow;

    var cur_pip_id: u32 = impossible_id;
    var cur_uniform_index: u32 = impossible_id;
    var cur_imgs_id: [texture_slots]u32 = .{ impossible_id } ** texture_slots;

    // define the resource bindings
    var bind: sokol.gfx.Bindings = .{};
    bind.index_buffer = sgp.index_buf;
    bind.index_buffer_offset = index_offset;
    bind.vertex_buffers[0] = sgp.vertex_buf;
    bind.vertex_buffer_offsets[0] = vertex_offset;

    // flush commands
    for (sgp.commands[0..end_command]) |cmd| {
        switch (cmd) {
            .none => {},
            .viewport => |rect| {
                sokol.gfx.applyViewport(rect.x, rect.y, rect.w, rect.h, true);
            },
            .scissor => |rect| {
                sokol.gfx.applyScissorRect(rect.x, rect.y, rect.w, rect.h, true);
            },
            .draw => |args| {
                if (args.num_indices == 0) continue;
                var apply_bindings = false;
                // pipeline
                if (args.pip.id != cur_pip_id) {
                    // when pipeline changes we need to re-apply uniforms and bindings
                    cur_uniform_index = impossible_id;
                    apply_bindings = true;
                    cur_pip_id = args.pip.id;
                    sokol.gfx.applyPipeline(args.pip);
                }
                // bindings
                for (0..texture_slots) |j| {
                    var img_id: u32 = sokol.gfx.invalid_id;
                    var smp_id: u32 = sokol.gfx.invalid_id;
                    if (j < args.textures.count) {
                        img_id = args.textures.images[j].id;
                        if (img_id != sokol.gfx.invalid_id) {
                            smp_id = args.textures.samplers[j].id;
                        }
                    }
                    if (cur_imgs_id[j] != img_id) {
                        // when an image binding change we need to re-apply bindings
                        cur_imgs_id[j] = img_id;
                        bind.images[j].id = img_id;
                        bind.samplers[j].id = smp_id;
                        apply_bindings = true;
                    }
                }
                if (apply_bindings) {
                    sokol.gfx.applyBindings(bind);
                }
                // uniforms
                if (cur_uniform_index != args.uniform_index) {
                    cur_uniform_index = args.uniform_index;
                    const uniform = &sgp.uniforms[cur_uniform_index];
                    if (uniform.size > 0) {
                        const uniform_range: sokol.gfx.Range = .{ .ptr = &uniform.content, .size = uniform.size };
                        sokol.gfx.applyUniforms(0, uniform_range);
                    }
                }
                //  draw
                sokol.gfx.draw(args.first_index, args.num_indices, 1);
            },
        }
    }
}

// End current draw command queue, discarding it.
pub fn end() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);

    // restore old state
    sgp.cur_state -= 1;
    sgp.state = sgp.state_stack[sgp.cur_state];
}

// Set the coordinate space boundary in the current viewport.
pub fn project(left: f32, right: f32, top: f32, bottom: f32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    const w: f32 = right - left;
    const h: f32 = top - bottom;
    const proj: Mat2x3 = .{ .v = .{
        .{ 2.0/w,   0.0,  -(right+left)/w },
        .{ 0.0,   2.0/h,  -(top+bottom)/h },
    }};
    sgp.state.proj = proj;
    sgp.state.mvp = mul_proj_transform(proj, sgp.state.transform);
}

// Resets the coordinate space to default (coordinate of the viewport).
pub fn reset_project() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.proj = default_proj(sgp.state.viewport.w, sgp.state.viewport.h);
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}



// Saves current transform matrix, to be restored later with a pop.
pub fn push_transform() !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (sgp.cur_transform >= max_stack_depth) return error.TransformStackOverflow;
    sgp.transform_stack[sgp.cur_transform] = sgp.state.transform;
    sgp.cur_transform += 1;
}

// Restore transform matrix to the same value of the last push.
pub fn pop_transform() !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (sgp.cur_transform <= 0) return error.TransformStackUnderflow;
    sgp.cur_transform -= 1;
    sgp.state.transform = sgp.transform_stack[sgp.cur_transform];
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}

// Resets the transform matrix to identity (no transform).
pub fn reset_transform() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.transform = Mat2x3.identity;
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}

// Translates the 2D coordinate space.
pub fn translate(x: f32, y: f32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    // multiply by translate matrix:
    // 1.0f, 0.0f,    x,
    // 0.0f, 1.0f,    y,
    // 0.0f, 0.0f, 1.0f,
    sgp.state.transform.v[0][2] += x*sgp.state.transform.v[0][0] + y*sgp.state.transform.v[0][1];
    sgp.state.transform.v[1][2] += x*sgp.state.transform.v[1][0] + y*sgp.state.transform.v[1][1];
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}

// Rotates the 2D coordinate space around the origin.
pub fn rotate(theta: f32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    const sin_theta = @sin(theta);
    const cos_theta = @cos(theta);
    // multiply by rotation matrix:
    // cost, -sint, 0.0f,
    // sint,  cost, 0.0f,
    // 0.0f,  0.0f, 1.0f,
    const transform: Mat2x3 = .{ .v = .{
       .{ cos_theta*sgp.state.transform.v[0][0]+sin_theta*sgp.state.transform.v[0][1], -sin_theta*sgp.state.transform.v[0][0]+cos_theta*sgp.state.transform.v[0][1], sgp.state.transform.v[0][2] },
       .{ cos_theta*sgp.state.transform.v[1][0]+sin_theta*sgp.state.transform.v[1][1], -sin_theta*sgp.state.transform.v[1][0]+cos_theta*sgp.state.transform.v[1][1], sgp.state.transform.v[1][2] },
    }};
    sgp.state.transform = transform;
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}

// Rotates the 2D coordinate space around a point.
pub fn rotate_at(theta: f32, x: f32, y: f32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    translate(x, y);
    rotate(theta);
    translate(-x, -y);
}

// Scales the 2D coordinate space around the origin.
pub fn scale(sx: f32, sy: f32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    // multiply by scale matrix:
    //   sx, 0.0f, 0.0f,
    // 0.0f,   sy, 0.0f,
    // 0.0f, 0.0f, 1.0f,
    sgp.state.transform.v[0][0] *= sx;
    sgp.state.transform.v[1][0] *= sx;
    sgp.state.transform.v[0][1] *= sy;
    sgp.state.transform.v[1][1] *= sy;
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}

// Scales the 2D coordinate space around a point.
pub fn scale_at(sx: f32, sy: f32, x: f32, y: f32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    translate(x, y);
    scale(sx, sy);
    translate(-x, -y);
}





// Sets current draw pipeline.
pub fn set_pipeline(pip: sokol.gfx.Pipeline) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    sgp.state.pipeline = pip;

    // reset uniforms
    sgp.state.uniform = .{};
}

// Resets to the current draw pipeline to default (builtin pipelines).
pub fn reset_pipeline() void {
    set_pipeline(.{});
}

// Sets uniform buffer for a custom pipeline.
pub fn set_uniform(data: anytype) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.state.pipeline.id != sokol.gfx.invalid_id);
    const T = @TypeOf(data);
    const size = @sizeOf(T);
    std.debug.assert(size <= @sizeOf(f32) * uniform_content_slots);

    const bytes: []u8 = std.mem.asBytes(&sgp.state.uniform.content);
    if (size < sgp.state.uniform.size) {
        @memset(bytes[size..sgp.state.uniform.size], 0);
    }
    if (size > 0) {
        @memcpy(bytes.ptr, std.mem.asBytes(&data));
    }
    sgp.state.uniform.size = size;
}

// Resets uniform buffer to default (current state color).
pub fn reset_uniform() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.state.pipeline.id != sokol.gfx.invalid_id);
    set_uniform({});
}





// Sets current blend mode.
pub fn set_blend_mode(blend_mode: Blend_Mode) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    sgp.state.blend_mode = blend_mode;
}
pub fn reset_blend_mode() void {
    set_blend_mode(.none);
}

// Sets current color modulation.
pub fn set_color(color: Color) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.color = .{
        .r = @intFromFloat(std.math.clamp(color.r * 255.0, 0.0, 255.0)),
        .g = @intFromFloat(std.math.clamp(color.g * 255.0, 0.0, 255.0)),
        .b = @intFromFloat(std.math.clamp(color.b * 255.0, 0.0, 255.0)),
        .a = @intFromFloat(std.math.clamp(color.a * 255.0, 0.0, 255.0)),
    };
}

pub fn set_color_unorm(color: Color_UB4) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.color = color;
}

pub fn set_color_unorm_rgb(r: u8, g: u8, b: u8) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.color = .{
        .r = r,
        .g = g,
        .b = b,
        .a = 255,
    };
}

pub fn set_color_unorm_rgba(r: u8, g: u8, b: u8, a: u8) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.color = .{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    };
}

pub fn set_color_rgb(r: f32, g: f32, b: f32) void {
    set_color(.{
        .r = r,
        .g = g,
        .b = b,
    });
}
pub fn set_color_rgba(r: f32, g: f32, b: f32, a: f32) void {
    set_color(.{
        .r = r,
        .g = g,
        .b = b,
        .a = a,
    });
}

// Resets current color modulation to default (white).
pub fn reset_color() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    sgp.state.color = Color_UB4.white;
}

// Sets current bound image in a texture channel.
pub fn set_image(channel: i32, image: sokol.gfx.Image) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    std.debug.assert(channel >= 0 and channel < texture_slots);
    if (sgp.state.textures.images[channel].id == image.id) return;
    sgp.state.textures.images[channel] = image;

    // recalculate textures count
    var textures_count: i32 = @intCast(sgp.state.textures.count);
    var i: i32 = @max(channel, textures_count - 1);
    while (i >= 0) : (i -= 1) {
        if (sgp.state.textures.images[i].id != sokol.gfx.invalid_id) {
            textures_count = i + 1;
            break;
        }
    }
    sgp.state.textures.count = @intCast(textures_count);
}

// Remove current bound image in a texture channel (no texture).
pub fn unset_image(channel: i32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    set_image(channel, .{});
}

// Resets current bound image in a texture channel to default (white texture).
pub fn reset_image(channel: i32) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    if (channel == 0) {
        // channel 0 always use white image
        set_image(channel, sgp.white_img);
    } else {
        set_image(channel, .{});
    }
}

// Sets current bound sampler in a texture channel.
pub fn set_sampler(channel: i32, sampler: sokol.gfx.Sampler) void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    std.debug.assert(channel >= 0 and channel < texture_slots);
    sgp.state.textures.samplers[channel] = sampler;
}

// Resets current bound sampler in a texture channel to default (nearest sampler).
pub fn reset_sampler(channel: i32) void {
    set_sampler(channel, sgp.nearest_smp);
}

// Sets the screen area to draw into.
pub fn viewport(vp: IRect) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);

    // skip in case of the same viewport
    if (sgp.state.viewport.x == vp.x and sgp.state.viewport.y == vp.y and sgp.state.viewport.w == vp.w and sgp.state.viewport.h == vp.h) {
        return;
    }

    // try to reuse last command otherwise use the next one
    const cmd = try prev_or_next_command(.viewport);
    cmd.* = .{ .viewport = vp };

    // adjust current scissor relative offset
    if (!(sgp.state.scissor.w < 0 and sgp.state.scissor.h < 0)) {
        sgp.state.scissor.x += vp.x - sgp.state.viewport.x;
        sgp.state.scissor.y += vp.y - sgp.state.viewport.y;
    }

    const w: f32 = @floatFromInt(vp.w);
    const h: f32 = @floatFromInt(vp.h);

    sgp.state.viewport = vp;
    sgp.state.thickness = @max(1.0 / w, 1.0 / h);
    sgp.state.proj = default_proj(vp.w, vp.h);
    sgp.state.mvp = mul_proj_transform(sgp.state.proj, sgp.state.transform);
}

// Reset viewport to default values (0, 0, width, height).
pub fn reset_viewport() !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    try viewport(.{
        .x = 0,
        .y = 0,
        .w = sgp.state.frame_size.w,
        .h = sgp.state.frame_size.h,
    });
}

// Set clip rectangle in the viewport.
pub fn scissor(rect: IRect) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);

    // skip in case of the same scissor
    if (sgp.state.scissor.x == rect.x and sgp.state.scissor.y == rect.y and sgp.state.scissor.w == rect.w and sgp.state.scissor.h == rect.h) return;

    const viewport_scissor: IRect = if (rect.w < 0 and rect.h < 0) .{
        .x = 0,
        .y = 0,
        .w = sgp.state.frame_size.w,
        .h = sgp.state.frame_size.h,
    } else .{
        .x = sgp.state.viewport.x + rect.x,
        .y = sgp.state.viewport.y + rect.y,
        .w = rect.w,
        .h = rect.h,
    };

    // try to reuse last command otherwise use the next one
    const cmd = try prev_or_next_command(.scissor);
    cmd.* = .{ .scissor = viewport_scissor };

    sgp.state.scissor = rect;
}

// Resets clip rectangle to default (viewport bounds).
pub fn reset_scissor() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    scissor(.{
        .x = 0,
        .y = 0,
        .w = -1,
        .h = -1,
    });
}

// Reset all state to default values.
pub fn reset_state() void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    reset_viewport();
    reset_scissor();
    reset_project();
    reset_transform();
    reset_blend_mode();
    reset_color();
    reset_uniform();
    reset_pipeline();
}

// Clears the current viewport using the current state color.
pub fn clear() !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);

    const first_index = sgp.cur_index;
    const first_vertex = sgp.cur_vertex;

    const color = sgp.state.color;
    (try next_vertices_array(4)).* = .{
        .{ .position = .{ .x = -1, .y = -1 }, .texcoord = .{ .x = 0, .y = 0 }, .color = color },
        .{ .position = .{ .x =  1, .y = -1 }, .texcoord = .{ .x = 0, .y = 0 }, .color = color },
        .{ .position = .{ .x =  1, .y =  1 }, .texcoord = .{ .x = 0, .y = 0 }, .color = color },
        .{ .position = .{ .x = -1, .y =  1 }, .texcoord = .{ .x = 0, .y = 0 }, .color = color },
    };

    (try next_indices_array(6)).* = .{
        first_vertex,
        first_vertex + 1,
        first_vertex + 2,
        first_vertex + 3,
        first_vertex + 0,
        first_vertex + 2,
    };

    const region: Region = .{
        .x1 = -1.0, .y1 = -1.0,
        .x2 = 1.0,  .y2 = 1.0,
    };

    const pip = try lookup_pipeline(.TRIANGLES, .none);
    try queue_draw(pip, region, first_index, 6, 4, .TRIANGLES);
}

pub fn draw(primitive_type: sokol.gfx.PrimitiveType, vertices: []const Vertex) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (vertices.len == 0) return;

    const first_vertex = sgp.cur_vertex;
    const num_vertices: u32 = @intCast(vertices.len);
    const vb = try next_vertices(num_vertices);

    const thickness = get_thickness(primitive_type);
    const mvp = sgp.state.mvp;
    var region = Region.max;
    for (vb, vertices) |*out, vertex| {
        const p = mat3_vec2_mul(mvp, vertex.position);
        region.expand(p, thickness);
        out.* = .{ .position = p, .texcoord = vertex.texcoord, .color = vertex.color };
    }

    try add_indices_and_draw(primitive_type, region, first_vertex, num_vertices);
}

fn add_indices_and_draw(primitive_type: sokol.gfx.PrimitiveType, region: Region, first_vertex: u32, num_vertices: usize) !void {
    const first_index = sgp.cur_index;
    var num_indices: u32 = undefined;
    switch (primitive_type) {
        .LINE_STRIP => {
            // Line strips break batching pretty badly and since we're doing instanced rendering,
            // they don't actually give much advantage anyway, so we just convert them into lines:
            num_indices = @intCast((num_vertices - 1) * 2);
            const ib = try next_indices(num_indices);

            for (0 .. num_vertices - 1) |i| {
                ib[i * 2 ..][0..2].* = .{
                    @intCast(first_vertex + i),
                    @intCast(first_vertex + i + 1),
                };
            }
        },
        .TRIANGLE_STRIP => {
            // Triangle strips break batching pretty badly and since we're doing instanced rendering,
            // they don't actually give much advantage anyway, so we just convert them into triangles:
            num_indices = @intCast((num_vertices - 2) * 3);
            const ib = try next_indices(num_indices);

            var i: usize = 0;
            while (i + 3 < num_vertices) : (i += 2) {
                ib[i * 3 ..][0..6].* = .{
                    @intCast(first_vertex + i),
                    @intCast(first_vertex + i + 1),
                    @intCast(first_vertex + i + 2),
                    @intCast(first_vertex + i + 2),
                    @intCast(first_vertex + i + 1),
                    @intCast(first_vertex + i + 3),
                };
            }
            if (i + 3 == num_vertices) {
                ib[i * 3 ..][0..3].* = .{
                    @intCast(first_vertex + i),
                    @intCast(first_vertex + i + 1),
                    @intCast(first_vertex + i + 2),
                };
            }
        },
        else => {
            num_indices = @intCast(num_vertices);
            const ib = try next_indices(num_indices);
            for (first_vertex.., ib) |n, *out| out.* = @intCast(n);
        },
    }
    const pip = try lookup_pipeline(primitive_type, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, num_indices, @intCast(num_vertices), primitive_type);
}

pub fn draw_solid(primitive_type: sokol.gfx.PrimitiveType, points: []const Point) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (points.len == 0) return;

    const first_vertex = sgp.cur_vertex;
    const num_vertices: u32 = @intCast(points.len);
    const vb = try next_vertices(num_vertices);

    const thickness = get_thickness(primitive_type);
    const color = sgp.state.color;
    const mvp = sgp.state.mvp;
    var region = Region.max;
    for (vb, points) |*out, point| {
        const p = mat3_vec2_mul(mvp, point);
        region.expand(p, thickness);
        out.* = .{ .position = p, .texcoord = .{ .x = 0, .y = 0 }, .color = color };
    }

    try add_indices_and_draw(primitive_type, region, first_vertex, num_vertices);
}

pub fn draw_indexed(primitive_type: sokol.gfx.PrimitiveType, vertices: []const Vertex, local_indices: []const u16) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (vertices.len == 0) return;

    const first_index = sgp.cur_index;
    const first_vertex = sgp.cur_vertex;

    const ib = try next_indices(@intCast(local_indices.len));
    const vb = try next_vertices(@intCast(vertices.len));

    for (ib, local_indices) |*out, local_index| {
        out.* = first_vertex + local_index;
    }

    const thickness = get_thickness(primitive_type);
    const mvp = sgp.state.mvp;
    var region = Region.max;
    for (vb, vertices) |*out, vertex| {
        const p = mat3_vec2_mul(mvp, vertex.position);
        region.expand(p, thickness);
        out.* = .{ .position = p, .texcoord = vertex.texcoord, .color = vertex.color };
    }

    const pip = try lookup_pipeline(primitive_type, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, @intCast(ib.len), @intCast(vb.len), primitive_type);
}

pub fn draw_solid_indexed(primitive_type: sokol.gfx.PrimitiveType, vertices: []const Vec2, local_indices: []const u16) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (vertices.len == 0) return;

    const first_index = sgp.cur_index;
    const first_vertex = sgp.cur_vertex;

    const ib = try next_indices(@intCast(local_indices.len));
    const vb = try next_vertices(@intCast(vertices.len));

    for (ib, local_indices) |*out, local_index| {
        out.* = first_vertex + local_index;
    }

    const thickness = get_thickness(primitive_type);
    const color = sgp.state.color;
    const mvp = sgp.state.mvp; // copy to stack for more efficiency
    var region = Region.max;
    for (vb, vertices) |*out, vertex| {
        const p = mat3_vec2_mul(mvp, vertex);
        region.expand(p, thickness);
        out.* = .{ .position = p, .texcoord = .{ .x = 0, .y = 0 }, .color = color };
    }

    const pip = try lookup_pipeline(primitive_type, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, @intCast(ib.len), @intCast(vb.len), primitive_type);
}

pub fn draw_points(points: []const Point) !void {
    try draw_solid(.POINTS, points);
}

pub fn draw_point(x: f32, y: f32) !void {
    try draw_solid(.POINTS, .{ .x = x, .y = y });
}

pub fn draw_lines(lines: []const Line) !void {
    const ptr: [*]const Point = @ptrCast(lines.ptr);
    try draw_solid(.LINES, ptr[0 .. lines.len * 2]);
}

pub fn draw_line(a: Point, b: Point) !void {
    try draw_solid(.LINES, &.{ a, b });
}

pub fn draw_line_strip(points: []const Point) !void {
    try draw_solid(.LINE_STRIP, points);
}

pub fn draw_triangles(triangles: []const Triangle) !void {
    const ptr: [*]const Point = @ptrCast(triangles.ptr);
    try draw_solid(.TRIANGLES, ptr[0 .. triangles.len * 3]);
}

pub fn draw_triangle(a: Point, b: Point, c: Point) !void {
    try draw_solid(.TRIANGLES, &.{ a, b, c });
}

pub fn draw_triangle_strip(points: []const Point) !void {
    try draw_solid(.TRIANGLE_STRIP, points);
}

pub fn draw_triangle_fan(points: []const Point) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (points.len < 3) return;

    const first_vertex = sgp.cur_vertex;
    const num_vertices: u32 = @intCast(points.len);
    const vb = try next_vertices(num_vertices);

    const color = sgp.state.color;
    const mvp = sgp.state.mvp;
    var region = Region.max;
    for (vb, points) |*out, point| {
        const p = mat3_vec2_mul(mvp, point);
        region.expand(p, 0);
        out.* = .{ .position = p, .texcoord = .{ .x = 0, .y = 0 }, .color = color };
    }

    const first_index = sgp.cur_index;
    const num_indices: u32 = @intCast((num_vertices - 2) * 3);
    const ib = try next_indices(num_indices);

    for (0 .. num_vertices - 2) |i| {
        ib[i * 3 ..][0..3].* = .{
            first_vertex,
            first_vertex + i + 1,
            first_vertex + i + 2,
        };
    }

    const pip = try lookup_pipeline(.TRIANGLES, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, num_indices, num_vertices, .TRIANGLES);
}

pub fn draw_quads(quads: []const Quad) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (quads.len == 0) return;

    const first_vertex = sgp.cur_vertex;
    const num_vertices: u32 = @intCast(quads.len * 4);
    const vb = try next_vertices(num_vertices);

    const color = sgp.state.color;
    const mvp = sgp.state.mvp;
    for (0.., quads) |i, quad| {
        (vb[i * 4 ..][0..4]).* = .{
            .{ .position = mat3_vec2_mul(mvp, quad.a), .texcoord = .{ .x = 0.0, .y = 1.0 }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, quad.b), .texcoord = .{ .x = 1.0, .y = 1.0 }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, quad.c), .texcoord = .{ .x = 1.0, .y = 0.0 }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, quad.d), .texcoord = .{ .x = 0.0, .y = 0.0 }, .color = color },
        };
    }

    var region = Region.max;
    for (vb) |v| region.expand(v.position, 0);

    const first_index = sgp.cur_index;
    const num_indices: u32 = @intCast(quads.len * 6);
    const ib = try next_indices(num_indices);

    for (0..quads.len) |i| {
        const base = first_vertex + i * 4;
        (ib[i * 6 ..][0..6]).* = .{
            base,
            base + 1,
            base + 2,
            base + 3,
            base,
            base + 2,
        };
    }

    const pip = try lookup_pipeline(.TRIANGLES, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, num_indices, num_vertices, .TRIANGLES);
}

pub fn draw_quad(a: Point, b: Point, c: Point, d: Point) !void {
    try draw_quads(&.{ .{ .a = a, .b = b, .c = c, .d = d } });
}

pub fn draw_rects(rects: []const FRect) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (rects.len == 0) return;

    const first_vertex = sgp.cur_vertex;
    const num_vertices: u32 = @intCast(rects.len * 4);
    const vb = try next_vertices(num_vertices);

    const color = sgp.state.color;
    const mvp = sgp.state.mvp;
    for (0.., rects) |i, rect| {
        (vb[i * 4 ..][0..4]).* = .{
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.x,          .y = rect.y + rect.h }), .texcoord = .{ .x = 0.0, .y = 1.0 }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.x + rect.w, .y = rect.y + rect.h }), .texcoord = .{ .x = 1.0, .y = 1.0 }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.x + rect.w, .y = rect.y }),          .texcoord = .{ .x = 1.0, .y = 0.0 }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.x,          .y = rect.y }),          .texcoord = .{ .x = 0.0, .y = 0.0 }, .color = color },
        };
    }

    var region = Region.max;
    for (vb) |v| region.expand(v.position, 0);

    const first_index = sgp.cur_index;
    const num_indices: u32 = @intCast(rects.len * 6);
    const ib = try next_indices(num_indices);

    for (0..rects.len) |i| {
        const base: u32 = @intCast(first_vertex + i * 4);
        (ib[i * 6 ..][0..6]).* = .{
            base,
            base + 1,
            base + 2,
            base + 3,
            base,
            base + 2,
        };
    }

    const pip = try lookup_pipeline(.TRIANGLES, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, num_indices, num_vertices, .TRIANGLES);
}

pub fn draw_rect(x: f32, y: f32, w: f32, h: f32) !void {
    try draw_rects(&.{ .{
        .x = x, .y = y,
        .w = w, .h = h,
    }});
}

pub fn draw_bordered_rect(x: f32, y: f32, w: f32, h: f32, bw: f32, bh: f32, border_color: Color_UB4) !void {
    const x0 = x - bw;
    const x1 = x;
    const x2 = x + w;
    const x3 = x + w + bw;

    const y0 = y - bh;
    const y1 = y;
    const y2 = y + h;
    const y3 = y + h + bh;

    const v = [_]Vertex {
        .{ .position = .{ .x = x0, .y = y0 }, .texcoord = Vec2.zeroes, .color = border_color },
        .{ .position = .{ .x = x3, .y = y0 }, .texcoord = Vec2.zeroes, .color = border_color },
        .{ .position = .{ .x = x2, .y = y1 }, .texcoord = Vec2.zeroes, .color = border_color },
        .{ .position = .{ .x = x1, .y = y1 }, .texcoord = Vec2.zeroes, .color = border_color },

        .{ .position = .{ .x = x1, .y = y2 }, .texcoord = Vec2.zeroes, .color = border_color },
        .{ .position = .{ .x = x0, .y = y3 }, .texcoord = Vec2.zeroes, .color = border_color },

        .{ .position = .{ .x = x3, .y = y3 }, .texcoord = Vec2.zeroes, .color = border_color },
        .{ .position = .{ .x = x2, .y = y2 }, .texcoord = Vec2.zeroes, .color = border_color },


        .{ .position = .{ .x = x1, .y = y1 }, .texcoord = Vec2.zeroes, .color = sgp.state.color },
        .{ .position = .{ .x = x2, .y = y1 }, .texcoord = Vec2.zeroes, .color = sgp.state.color },
        .{ .position = .{ .x = x2, .y = y2 }, .texcoord = Vec2.zeroes, .color = sgp.state.color },
        .{ .position = .{ .x = x1, .y = y2 }, .texcoord = Vec2.zeroes, .color = sgp.state.color },
    };

    const i =  [_]u16 {
        0, 1, 2,
        0, 2, 3,

        0, 3, 4,
        0, 4, 5,

        5, 4, 6,
        4, 6, 7,

        7, 6, 2,
        6, 2, 1,

        8, 9, 10,
        8, 10, 11,
    };

    try draw_indexed(.TRIANGLES, &v, &i);
}

// Draws a batch textured rectangle, each from a source region.
pub fn draw_textured_rects(channel: i32, rects: []const Textured_Rect) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    std.debug.assert(channel >= 0 and channel < texture_slots);
    if (rects.len == 0) return;

    const image = sgp.state.textures.images[channel];
    if (image.id == sokol.gfx.invalid_id) return error.InvalidImage;

    const first_vertex = sgp.cur_vertex;
    const num_vertices: u32 = @intCast(rects.len * 4);
    const vb = try next_vertices(num_vertices);

    const color = sgp.state.color;
    const mvp = sgp.state.mvp;
    for (0.., rects) |i, rect| {
        (vb[i * 4 ..][0..4]).* = .{
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.dst.x,              .y = rect.dst.y + rect.dst.h }), .texcoord = .{ .x = rect.src.x,              .y = rect.src.y + rect.src.h }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.dst.x + rect.dst.w, .y = rect.dst.y + rect.dst.h }), .texcoord = .{ .x = rect.src.x + rect.src.w, .y = rect.src.y + rect.src.h }, .color = color },
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.dst.x + rect.dst.w, .y = rect.dst.y }),              .texcoord = .{ .x = rect.src.x + rect.src.w, .y = rect.src.y },              .color = color },
            .{ .position = mat3_vec2_mul(mvp, .{ .x = rect.dst.x,              .y = rect.dst.y }),              .texcoord = .{ .x = rect.src.x,              .y = rect.src.y },              .color = color },
        };
    }

    var region = Region.max;
    for (vb) |v| region.expand(v.position, 0);

    const first_index = sgp.cur_index;
    const num_indices: u32 = @intCast(rects.len * 6);
    const ib = try next_indices(num_indices);

    for (0..rects.len) |i| {
        const base = first_vertex + i * 4;
        (ib[i * 6 ..][0..6]).* = .{
            base,
            base + 1,
            base + 2,
            base + 3,
            base,
            base + 2,
        };
    }

    // queue draw
    const pip = try lookup_pipeline(.TRIANGLES, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, num_indices, num_vertices, .TRIANGLES);
}

// Draws a single textured rectangle from a source region.
pub fn draw_textured_rect(channel: i32, dest: FRect, src: FRect) !void {
    try draw_textured_rects(channel, &.{ .{
        .dest = dest,
        .src = src,
    }});
}

const Draw_Grid_Options = struct {
    max_points: usize = 8192,
    axis_lines: bool = false,
};

pub fn draw_grid(dx: f32, dy: f32, comptime options: Draw_Grid_Options) !bool {
    const mvp = sgp.state.mvp.v;
    if (mvp[0][1] == 0 and mvp[1][0] == 0) {
        const xl = (-1 - mvp[0][2]) / mvp[0][0];
        const xr = (1 - mvp[0][2]) / mvp[0][0];
        const minx = @min(xl, xr);
        const maxx = @max(xl, xr);
        var x: i32 = @intFromFloat(@divFloor(minx, dx));
        if (@mod(minx, dx) != 0) x += 1;
        const x0 = x;
        const x1: i32 = @intFromFloat(@divFloor(maxx, dx) + 1);
        var xc: usize = @intCast(x1 - x);

        const yb = (-1 - mvp[1][2]) / mvp[1][1];
        const yt = (1 - mvp[1][2]) / mvp[1][1];
        const miny = @min(yb, yt);
        const maxy = @max(yb, yt);
        var y: i32 = @intFromFloat(@divFloor(miny, dy));
        if (@mod(miny, dy) != 0) y += 1;
        const y0 = y;
        const y1: i32 = @intFromFloat(@divFloor(maxy, dy) + 1);
        var yc: usize = @intCast(y1 - y);
        
        if (options.axis_lines) {
            if (x <= 0 and x1 > 0) xc -= 1;
            if (y <= 0 and y1 > 0) yc -= 1;

            const x0f: f32 = @floatFromInt(x0 - 1);
            const x1f: f32 = @floatFromInt(x1);
            const y0f: f32 = @floatFromInt(y0 - 1);
            const y1f: f32 = @floatFromInt(y1);
            try draw_lines(&.{
                .{
                    .a = .{ .x = x0f * dx, .y = 0 },
                    .b = .{ .x = x1f * dx, .y = 0 },
                },
                .{
                    .a = .{ .x = 0, .y = y0f * dy },
                    .b = .{ .x = 0, .y = y1f * dy },
                },
            });
        }

        if (xc * yc > options.max_points) return false;

        var pts: [options.max_points]Point = undefined;

        var i: usize = 0;
        while (y < y1) {
            defer {
                y += 1;
                x = x0;
            }

            if (options.axis_lines and y == 0) continue;
            var yf: f32 = @floatFromInt(y);
            yf *= dy;
            while (x < x1) : (x += 1) {
                if (options.axis_lines and x == 0) continue;
                var xf: f32 = @floatFromInt(x);
                xf *= dx;
                pts[i] = .{ .x = xf, .y = yf };
                i += 1;
            }
        }
        
        if (i > 0) try draw_points(pts[0..i]);

        return true;
    } else {
        // rotated views not currently supported
        // TODO implement this by flood fill
        return false;
    }
}

pub fn query_state() *State {
    return sgp.state;
}

pub fn query_desc() Desc {
    return sgp.desc;
}

const impossible_id = 0xffffffff;

const init_cookie = 0xACAFEDAD;
const default_max_indices = 32768;
const default_max_vertices = 65536;
const default_max_commands = 8192;
const max_move_indices = 144;
const max_stack_depth = 64;

const Region = struct {
    x1: f32,
    y1: f32,
    x2: f32,
    y2: f32,

    pub const max: Region = .{
        .x1 = std.math.floatMax(f32),
        .y1 = std.math.floatMax(f32),
        .x2 = -std.math.floatMax(f32),
        .y2 = -std.math.floatMax(f32),
    };

    pub fn expand(self: *Region, p: Point, thickness: f32) void {
        self.x1 = @min(self.x1, p.x - thickness);
        self.y1 = @min(self.y1, p.y - thickness);
        self.x2 = @max(self.x2, p.x + thickness);
        self.y2 = @max(self.y2, p.y + thickness);
    }
};

const Draw_Args = struct {
    pip: sokol.gfx.Pipeline,
    textures: Textures_Uniform,
    region: Region,
    uniform_index: u32,
    first_index: u32,
    num_indices: u32,
};

const Command = union (enum) {
    none,
    draw: Draw_Args,
    viewport: IRect,
    scissor: IRect,
};

const Context = struct {
    init_cookie: u32,
    desc: Desc,

    // resources
    shader: sokol.gfx.Shader,
    index_buf: sokol.gfx.Buffer,
    vertex_buf: sokol.gfx.Buffer,
    white_img: sokol.gfx.Image,
    nearest_smp: sokol.gfx.Sampler,
    pipelines: [@typeInfo(Blend_Mode).@"enum".fields.len * @intFromEnum(sokol.gfx.PrimitiveType.NUM)]sokol.gfx.Pipeline,

    // command queue
    cur_index: u32,
    cur_vertex: u32,
    cur_uniform: u32,
    cur_command: u32,
    indices: []Index,
    vertices: []Vertex,
    uniforms: []Uniform,
    commands: []Command,

    // state tracking
    state: State,

    // matrix stack
    cur_transform: u32,
    cur_state: u32,
    transform_stack: [max_stack_depth]Mat2x3,
    state_stack: [max_stack_depth]State,
};

var sgp: Context = undefined;

////////////////////////////////////////////////////////////////////////////////
// Shaders

//     #version 410
//
//     layout(location = 0) in vec4 coord;
//     layout(location = 0) out vec2 texUV;
//     layout(location = 1) out vec4 iColor;
//     layout(location = 1) in vec4 color;
//
//     void main()
//     {
//         gl_Position = vec4(coord.xy, 0.0, 1.0);
//         texUV = coord.zw;
//         iColor = color;
//     }
const vs_source_glsl410: [266]u8 = .{
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x34,0x31,0x30,0x0a,0x0a,0x6c,0x61,
    0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,
    0x30,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x34,0x20,0x63,0x6f,0x6f,0x72,0x64,
    0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,
    0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x32,0x20,
    0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,
    0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x31,0x29,0x20,0x6f,0x75,0x74,0x20,
    0x76,0x65,0x63,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x6c,0x61,0x79,
    0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x31,
    0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,
    0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,
    0x3d,0x20,0x76,0x65,0x63,0x34,0x28,0x63,0x6f,0x6f,0x72,0x64,0x2e,0x78,0x79,0x2c,
    0x20,0x30,0x2e,0x30,0x2c,0x20,0x31,0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x74,0x65,0x78,0x55,0x56,0x20,0x3d,0x20,0x63,0x6f,0x6f,0x72,0x64,0x2e,0x7a,0x77,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x63,
    0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};

//     #version 410
//
//     uniform sampler2D iTexChannel0_iSmpChannel0;
//
//     layout(location = 0) out vec4 fragColor;
//     layout(location = 0) in vec2 texUV;
//     layout(location = 1) in vec4 iColor;
//
//     void main()
//     {
//         fragColor = texture(iTexChannel0_iSmpChannel0, texUV) * iColor;
//     }
const fs_source_glsl410: [261]u8 = .{
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x34,0x31,0x30,0x0a,0x0a,0x75,0x6e,
    0x69,0x66,0x6f,0x72,0x6d,0x20,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x32,0x44,0x20,
    0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x5f,0x69,0x53,0x6d,
    0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x3b,0x0a,0x0a,0x6c,0x61,0x79,0x6f,
    0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,
    0x20,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x34,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,
    0x6c,0x6f,0x72,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,
    0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,
    0x32,0x20,0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,
    0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x31,0x29,0x20,0x69,0x6e,
    0x20,0x76,0x65,0x63,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x76,
    0x6f,0x69,0x64,0x20,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x74,0x65,0x78,
    0x74,0x75,0x72,0x65,0x28,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,
    0x30,0x5f,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2c,0x20,
    0x74,0x65,0x78,0x55,0x56,0x29,0x20,0x2a,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,
    0x0a,0x7d,0x0a,0x0a,0x00,
};

//     #version 300 es
//
//     layout(location = 0) in vec4 coord;
//     out vec2 texUV;
//     out vec4 iColor;
//     layout(location = 1) in vec4 color;
//
//     void main()
//     {
//         gl_Position = vec4(coord.xy, 0.0, 1.0);
//         texUV = coord.zw;
//         iColor = color;
//     }
const vs_source_glsl300es: [227]u8 = .{
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x33,0x30,0x30,0x20,0x65,0x73,0x0a,
    0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,
    0x20,0x3d,0x20,0x30,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,0x63,0x34,0x20,0x63,0x6f,
    0x6f,0x72,0x64,0x3b,0x0a,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x32,0x20,0x74,0x65,
    0x78,0x55,0x56,0x3b,0x0a,0x6f,0x75,0x74,0x20,0x76,0x65,0x63,0x34,0x20,0x69,0x43,
    0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,
    0x61,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x31,0x29,0x20,0x69,0x6e,0x20,0x76,0x65,
    0x63,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x76,0x6f,0x69,0x64,0x20,
    0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,
    0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x76,0x65,0x63,0x34,0x28,
    0x63,0x6f,0x6f,0x72,0x64,0x2e,0x78,0x79,0x2c,0x20,0x30,0x2e,0x30,0x2c,0x20,0x31,
    0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3d,
    0x20,0x63,0x6f,0x6f,0x72,0x64,0x2e,0x7a,0x77,0x3b,0x0a,0x20,0x20,0x20,0x20,0x69,
    0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x7d,
    0x0a,0x0a,0x00,
};

//     #version 300 es
//     precision mediump float;
//     precision highp int;
//
//     uniform highp sampler2D iTexChannel0_iSmpChannel0;
//
//     layout(location = 0) out highp vec4 fragColor;
//     in highp vec2 texUV;
//     in highp vec4 iColor;
//
//     void main()
//     {
//         fragColor = texture(iTexChannel0_iSmpChannel0, texUV) * iColor;
//     }
const fs_source_glsl300es: [292]u8 = .{
    0x23,0x76,0x65,0x72,0x73,0x69,0x6f,0x6e,0x20,0x33,0x30,0x30,0x20,0x65,0x73,0x0a,
    0x70,0x72,0x65,0x63,0x69,0x73,0x69,0x6f,0x6e,0x20,0x6d,0x65,0x64,0x69,0x75,0x6d,
    0x70,0x20,0x66,0x6c,0x6f,0x61,0x74,0x3b,0x0a,0x70,0x72,0x65,0x63,0x69,0x73,0x69,
    0x6f,0x6e,0x20,0x68,0x69,0x67,0x68,0x70,0x20,0x69,0x6e,0x74,0x3b,0x0a,0x0a,0x75,
    0x6e,0x69,0x66,0x6f,0x72,0x6d,0x20,0x68,0x69,0x67,0x68,0x70,0x20,0x73,0x61,0x6d,
    0x70,0x6c,0x65,0x72,0x32,0x44,0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,
    0x65,0x6c,0x30,0x5f,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,
    0x3b,0x0a,0x0a,0x6c,0x61,0x79,0x6f,0x75,0x74,0x28,0x6c,0x6f,0x63,0x61,0x74,0x69,
    0x6f,0x6e,0x20,0x3d,0x20,0x30,0x29,0x20,0x6f,0x75,0x74,0x20,0x68,0x69,0x67,0x68,
    0x70,0x20,0x76,0x65,0x63,0x34,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,
    0x3b,0x0a,0x69,0x6e,0x20,0x68,0x69,0x67,0x68,0x70,0x20,0x76,0x65,0x63,0x32,0x20,
    0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x69,0x6e,0x20,0x68,0x69,0x67,0x68,0x70,0x20,
    0x76,0x65,0x63,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x76,0x6f,
    0x69,0x64,0x20,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,
    0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x74,0x65,0x78,0x74,
    0x75,0x72,0x65,0x28,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,
    0x5f,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2c,0x20,0x74,
    0x65,0x78,0x55,0x56,0x29,0x20,0x2a,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,
    0x7d,0x0a,0x0a,0x00,
};

//     static float4 gl_Position;
//     static float4 coord;
//     static float2 texUV;
//     static float4 iColor;
//     static float4 color;
//
//     struct SPIRV_Cross_Input
//     {
//         float4 coord : TEXCOORD0;
//         float4 color : TEXCOORD1;
//     };
//
//     struct SPIRV_Cross_Output
//     {
//         float2 texUV : TEXCOORD0;
//         float4 iColor : TEXCOORD1;
//         float4 gl_Position : SV_Position;
//     };
//
//     void vert_main()
//     {
//         gl_Position = float4(coord.xy, 0.0f, 1.0f);
//         texUV = coord.zw;
//         iColor = color;
//     }
//
//     SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
//     {
//         coord = stage_input.coord;
//         color = stage_input.color;
//         vert_main();
//         SPIRV_Cross_Output stage_output;
//         stage_output.gl_Position = gl_Position;
//         stage_output.texUV = texUV;
//         stage_output.iColor = iColor;
//         return stage_output;
//     }
const vs_source_hlsl4: [758]u8 = .{
    0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,
    0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,
    0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,
    0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,0x65,
    0x78,0x55,0x56,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,
    0x74,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,
    0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,
    0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,
    0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,
    0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6f,0x72,0x64,0x20,0x3a,0x20,0x54,
    0x45,0x58,0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x54,0x45,0x58,
    0x43,0x4f,0x4f,0x52,0x44,0x31,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,
    0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,
    0x75,0x74,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,
    0x74,0x32,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,
    0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,0x4f,0x4f,
    0x52,0x44,0x31,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,
    0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3a,0x20,0x53,0x56,
    0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x76,
    0x6f,0x69,0x64,0x20,0x76,0x65,0x72,0x74,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,
    0x7b,0x0a,0x20,0x20,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,
    0x6e,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x63,0x6f,0x6f,0x72,0x64,
    0x2e,0x78,0x79,0x2c,0x20,0x30,0x2e,0x30,0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x29,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3d,0x20,0x63,0x6f,
    0x6f,0x72,0x64,0x2e,0x7a,0x77,0x3b,0x0a,0x20,0x20,0x20,0x20,0x69,0x43,0x6f,0x6c,
    0x6f,0x72,0x20,0x3d,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x7d,0x0a,0x0a,0x53,
    0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,
    0x74,0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,
    0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,
    0x6e,0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x63,0x6f,0x6f,0x72,
    0x64,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,
    0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x20,0x20,0x20,0x20,0x63,0x6f,0x6c,0x6f,0x72,
    0x20,0x3d,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x63,
    0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x76,0x65,0x72,0x74,0x5f,0x6d,
    0x61,0x69,0x6e,0x28,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x53,0x50,0x49,0x52,0x56,
    0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x73,0x74,
    0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,0x20,0x20,0x20,0x20,
    0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x67,0x6c,0x5f,
    0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x67,0x6c,0x5f,0x50,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,
    0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x74,0x65,0x78,0x55,0x56,0x20,0x3d,
    0x20,0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,
    0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,
    0x3d,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,
    0x74,0x75,0x72,0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,0x74,0x70,0x75,
    0x74,0x3b,0x0a,0x7d,0x0a,0x00,
};

//     Texture2D<float4> iTexChannel0 : register(t0);
//     SamplerState iSmpChannel0 : register(s0);
//
//     static float4 fragColor;
//     static float2 texUV;
//     static float4 iColor;
//
//     struct SPIRV_Cross_Input
//     {
//         float2 texUV : TEXCOORD0;
//         float4 iColor : TEXCOORD1;
//     };
//
//     struct SPIRV_Cross_Output
//     {
//         float4 fragColor : SV_Target0;
//     };
//
//     void frag_main()
//     {
//         fragColor = iTexChannel0.Sample(iSmpChannel0, texUV) * iColor;
//     }
//
//     SPIRV_Cross_Output main(SPIRV_Cross_Input stage_input)
//     {
//         texUV = stage_input.texUV;
//         iColor = stage_input.iColor;
//         frag_main();
//         SPIRV_Cross_Output stage_output;
//         stage_output.fragColor = fragColor;
//         return stage_output;
//     }
const fs_source_hlsl4: [650]u8 = .{
    0x54,0x65,0x78,0x74,0x75,0x72,0x65,0x32,0x44,0x3c,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x3e,0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x20,0x3a,
    0x20,0x72,0x65,0x67,0x69,0x73,0x74,0x65,0x72,0x28,0x74,0x30,0x29,0x3b,0x0a,0x53,
    0x61,0x6d,0x70,0x6c,0x65,0x72,0x53,0x74,0x61,0x74,0x65,0x20,0x69,0x53,0x6d,0x70,
    0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x20,0x3a,0x20,0x72,0x65,0x67,0x69,0x73,
    0x74,0x65,0x72,0x28,0x73,0x30,0x29,0x3b,0x0a,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,
    0x72,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,
    0x20,0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x73,0x74,0x61,0x74,0x69,0x63,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x0a,0x73,
    0x74,0x72,0x75,0x63,0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,
    0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,
    0x6f,0x61,0x74,0x32,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3a,0x20,0x54,0x45,0x58,
    0x43,0x4f,0x4f,0x52,0x44,0x30,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,
    0x74,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x54,0x45,0x58,0x43,
    0x4f,0x4f,0x52,0x44,0x31,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,
    0x74,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x4f,0x75,
    0x74,0x70,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,
    0x34,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x53,0x56,
    0x5f,0x54,0x61,0x72,0x67,0x65,0x74,0x30,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x76,0x6f,
    0x69,0x64,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x0a,0x7b,
    0x0a,0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,
    0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2e,0x53,0x61,
    0x6d,0x70,0x6c,0x65,0x28,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,
    0x30,0x2c,0x20,0x74,0x65,0x78,0x55,0x56,0x29,0x20,0x2a,0x20,0x69,0x43,0x6f,0x6c,
    0x6f,0x72,0x3b,0x0a,0x7d,0x0a,0x0a,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,
    0x73,0x73,0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x28,0x53,
    0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,0x5f,0x49,0x6e,0x70,0x75,0x74,
    0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x29,0x0a,0x7b,0x0a,
    0x20,0x20,0x20,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,
    0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x20,
    0x20,0x20,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x73,0x74,0x61,0x67,
    0x65,0x5f,0x69,0x6e,0x70,0x75,0x74,0x2e,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x66,0x72,0x61,0x67,0x5f,0x6d,0x61,0x69,0x6e,0x28,0x29,0x3b,
    0x0a,0x20,0x20,0x20,0x20,0x53,0x50,0x49,0x52,0x56,0x5f,0x43,0x72,0x6f,0x73,0x73,
    0x5f,0x4f,0x75,0x74,0x70,0x75,0x74,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,0x75,
    0x74,0x70,0x75,0x74,0x3b,0x0a,0x20,0x20,0x20,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x6f,0x75,0x74,0x70,0x75,0x74,0x2e,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,
    0x20,0x3d,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,
    0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x73,0x74,0x61,0x67,0x65,0x5f,0x6f,
    0x75,0x74,0x70,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x00,
};

//     #include <metal_stdlib>
//     #include <simd/simd.h>
//
//     using namespace metal;
//
//     struct main0_out
//     {
//         float2 texUV [[user(locn0)]];
//         float4 iColor [[user(locn1)]];
//         float4 gl_Position [[position]];
//     };
//
//     struct main0_in
//     {
//         float4 coord [[attribute(0)]];
//         float4 color [[attribute(1)]];
//     };
//
//     vertex main0_out main0(main0_in in [[stage_in]])
//     {
//         main0_out out = {};
//         out.gl_Position = float4(in.coord.xy, 0.0, 1.0);
//         out.texUV = in.coord.zw;
//         out.iColor = in.color;
//         return out;
//     }
const vs_source_metal_macos: [497]u8 = .{
    0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x20,0x3c,0x6d,0x65,0x74,0x61,0x6c,0x5f,
    0x73,0x74,0x64,0x6c,0x69,0x62,0x3e,0x0a,0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,
    0x20,0x3c,0x73,0x69,0x6d,0x64,0x2f,0x73,0x69,0x6d,0x64,0x2e,0x68,0x3e,0x0a,0x0a,
    0x75,0x73,0x69,0x6e,0x67,0x20,0x6e,0x61,0x6d,0x65,0x73,0x70,0x61,0x63,0x65,0x20,
    0x6d,0x65,0x74,0x61,0x6c,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,
    0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x5b,0x5b,0x75,0x73,
    0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x5b,
    0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,0x31,0x29,0x5d,0x5d,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x5b,0x5b,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,
    0x6e,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,
    0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6f,0x72,0x64,0x20,0x5b,0x5b,0x61,0x74,
    0x74,0x72,0x69,0x62,0x75,0x74,0x65,0x28,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x20,0x20,
    0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x5b,
    0x5b,0x61,0x74,0x74,0x72,0x69,0x62,0x75,0x74,0x65,0x28,0x31,0x29,0x5d,0x5d,0x3b,
    0x0a,0x7d,0x3b,0x0a,0x0a,0x76,0x65,0x72,0x74,0x65,0x78,0x20,0x6d,0x61,0x69,0x6e,
    0x30,0x5f,0x6f,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x28,0x6d,0x61,0x69,0x6e,
    0x30,0x5f,0x69,0x6e,0x20,0x69,0x6e,0x20,0x5b,0x5b,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x69,0x6e,0x5d,0x5d,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x6d,0x61,0x69,0x6e,
    0x30,0x5f,0x6f,0x75,0x74,0x20,0x6f,0x75,0x74,0x20,0x3d,0x20,0x7b,0x7d,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x6f,0x75,0x74,0x2e,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x69,0x6e,0x2e,
    0x63,0x6f,0x6f,0x72,0x64,0x2e,0x78,0x79,0x2c,0x20,0x30,0x2e,0x30,0x2c,0x20,0x31,
    0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x6f,0x75,0x74,0x2e,0x74,0x65,0x78,
    0x55,0x56,0x20,0x3d,0x20,0x69,0x6e,0x2e,0x63,0x6f,0x6f,0x72,0x64,0x2e,0x7a,0x77,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x6f,0x75,0x74,0x2e,0x69,0x43,0x6f,0x6c,0x6f,0x72,
    0x20,0x3d,0x20,0x69,0x6e,0x2e,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x6f,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x0a,
    0x00,
};

//     #include <metal_stdlib>
//     #include <simd/simd.h>
//
//     using namespace metal;
//
//     struct main0_out
//     {
//         float4 fragColor [[color(0)]];
//     };
//
//     struct main0_in
//     {
//         float2 texUV [[user(locn0)]];
//         float4 iColor [[user(locn1)]];
//     };
//
//     fragment main0_out main0(main0_in in [[stage_in]], texture2d<float> iTexChannel0 [[texture(0)]], sampler iSmpChannel0 [[sampler(0)]])
//     {
//         main0_out out = {};
//         out.fragColor = iTexChannel0.sample(iSmpChannel0, in.texUV) * in.iColor;
//         return out;
//     }
const fs_source_metal_macos: [478]u8 = .{
    0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x20,0x3c,0x6d,0x65,0x74,0x61,0x6c,0x5f,
    0x73,0x74,0x64,0x6c,0x69,0x62,0x3e,0x0a,0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,
    0x20,0x3c,0x73,0x69,0x6d,0x64,0x2f,0x73,0x69,0x6d,0x64,0x2e,0x68,0x3e,0x0a,0x0a,
    0x75,0x73,0x69,0x6e,0x67,0x20,0x6e,0x61,0x6d,0x65,0x73,0x70,0x61,0x63,0x65,0x20,
    0x6d,0x65,0x74,0x61,0x6c,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,
    0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,
    0x5b,0x5b,0x63,0x6f,0x6c,0x6f,0x72,0x28,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,
    0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,
    0x6e,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,
    0x65,0x78,0x55,0x56,0x20,0x5b,0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,
    0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x5b,0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,
    0x6f,0x63,0x6e,0x31,0x29,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x66,0x72,0x61,
    0x67,0x6d,0x65,0x6e,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x20,
    0x6d,0x61,0x69,0x6e,0x30,0x28,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x20,0x69,
    0x6e,0x20,0x5b,0x5b,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x5d,0x5d,0x2c,0x20,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x32,0x64,0x3c,0x66,0x6c,0x6f,0x61,0x74,0x3e,
    0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x20,0x5b,0x5b,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x30,0x29,0x5d,0x5d,0x2c,0x20,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x72,0x20,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,
    0x6c,0x30,0x20,0x5b,0x5b,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x28,0x30,0x29,0x5d,
    0x5d,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,
    0x75,0x74,0x20,0x6f,0x75,0x74,0x20,0x3d,0x20,0x7b,0x7d,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x6f,0x75,0x74,0x2e,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,
    0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2e,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x28,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,
    0x30,0x2c,0x20,0x69,0x6e,0x2e,0x74,0x65,0x78,0x55,0x56,0x29,0x20,0x2a,0x20,0x69,
    0x6e,0x2e,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,
    0x74,0x75,0x72,0x6e,0x20,0x6f,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};

//     #include <metal_stdlib>
//     #include <simd/simd.h>
//
//     using namespace metal;
//
//     struct main0_out
//     {
//         float2 texUV [[user(locn0)]];
//         float4 iColor [[user(locn1)]];
//         float4 gl_Position [[position]];
//     };
//
//     struct main0_in
//     {
//         float4 coord [[attribute(0)]];
//         float4 color [[attribute(1)]];
//     };
//
//     vertex main0_out main0(main0_in in [[stage_in]])
//     {
//         main0_out out = {};
//         out.gl_Position = float4(in.coord.xy, 0.0, 1.0);
//         out.texUV = in.coord.zw;
//         out.iColor = in.color;
//         return out;
//     }
const vs_source_metal_ios: [497]u8 = .{
    0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x20,0x3c,0x6d,0x65,0x74,0x61,0x6c,0x5f,
    0x73,0x74,0x64,0x6c,0x69,0x62,0x3e,0x0a,0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,
    0x20,0x3c,0x73,0x69,0x6d,0x64,0x2f,0x73,0x69,0x6d,0x64,0x2e,0x68,0x3e,0x0a,0x0a,
    0x75,0x73,0x69,0x6e,0x67,0x20,0x6e,0x61,0x6d,0x65,0x73,0x70,0x61,0x63,0x65,0x20,
    0x6d,0x65,0x74,0x61,0x6c,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,
    0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x5b,0x5b,0x75,0x73,
    0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x5b,
    0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,0x31,0x29,0x5d,0x5d,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x67,0x6c,0x5f,0x50,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x5b,0x5b,0x70,0x6f,0x73,0x69,0x74,0x69,0x6f,
    0x6e,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,
    0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6f,0x72,0x64,0x20,0x5b,0x5b,0x61,0x74,
    0x74,0x72,0x69,0x62,0x75,0x74,0x65,0x28,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x20,0x20,
    0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x5b,
    0x5b,0x61,0x74,0x74,0x72,0x69,0x62,0x75,0x74,0x65,0x28,0x31,0x29,0x5d,0x5d,0x3b,
    0x0a,0x7d,0x3b,0x0a,0x0a,0x76,0x65,0x72,0x74,0x65,0x78,0x20,0x6d,0x61,0x69,0x6e,
    0x30,0x5f,0x6f,0x75,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x28,0x6d,0x61,0x69,0x6e,
    0x30,0x5f,0x69,0x6e,0x20,0x69,0x6e,0x20,0x5b,0x5b,0x73,0x74,0x61,0x67,0x65,0x5f,
    0x69,0x6e,0x5d,0x5d,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x6d,0x61,0x69,0x6e,
    0x30,0x5f,0x6f,0x75,0x74,0x20,0x6f,0x75,0x74,0x20,0x3d,0x20,0x7b,0x7d,0x3b,0x0a,
    0x20,0x20,0x20,0x20,0x6f,0x75,0x74,0x2e,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,
    0x69,0x6f,0x6e,0x20,0x3d,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,0x28,0x69,0x6e,0x2e,
    0x63,0x6f,0x6f,0x72,0x64,0x2e,0x78,0x79,0x2c,0x20,0x30,0x2e,0x30,0x2c,0x20,0x31,
    0x2e,0x30,0x29,0x3b,0x0a,0x20,0x20,0x20,0x20,0x6f,0x75,0x74,0x2e,0x74,0x65,0x78,
    0x55,0x56,0x20,0x3d,0x20,0x69,0x6e,0x2e,0x63,0x6f,0x6f,0x72,0x64,0x2e,0x7a,0x77,
    0x3b,0x0a,0x20,0x20,0x20,0x20,0x6f,0x75,0x74,0x2e,0x69,0x43,0x6f,0x6c,0x6f,0x72,
    0x20,0x3d,0x20,0x69,0x6e,0x2e,0x63,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x6f,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x0a,
    0x00,
};

//     #include <metal_stdlib>
//     #include <simd/simd.h>
//
//     using namespace metal;
//
//     struct main0_out
//     {
//         float4 fragColor [[color(0)]];
//     };
//
//     struct main0_in
//     {
//         float2 texUV [[user(locn0)]];
//         float4 iColor [[user(locn1)]];
//     };
//
//     fragment main0_out main0(main0_in in [[stage_in]], texture2d<float> iTexChannel0 [[texture(0)]], sampler iSmpChannel0 [[sampler(0)]])
//     {
//         main0_out out = {};
//         out.fragColor = iTexChannel0.sample(iSmpChannel0, in.texUV) * in.iColor;
//         return out;
//     }
const fs_source_metal_ios: [478]u8 = .{
    0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,0x20,0x3c,0x6d,0x65,0x74,0x61,0x6c,0x5f,
    0x73,0x74,0x64,0x6c,0x69,0x62,0x3e,0x0a,0x23,0x69,0x6e,0x63,0x6c,0x75,0x64,0x65,
    0x20,0x3c,0x73,0x69,0x6d,0x64,0x2f,0x73,0x69,0x6d,0x64,0x2e,0x68,0x3e,0x0a,0x0a,
    0x75,0x73,0x69,0x6e,0x67,0x20,0x6e,0x61,0x6d,0x65,0x73,0x70,0x61,0x63,0x65,0x20,
    0x6d,0x65,0x74,0x61,0x6c,0x3b,0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,
    0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,
    0x6c,0x6f,0x61,0x74,0x34,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,
    0x5b,0x5b,0x63,0x6f,0x6c,0x6f,0x72,0x28,0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,
    0x0a,0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,
    0x6e,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x32,0x20,0x74,
    0x65,0x78,0x55,0x56,0x20,0x5b,0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,0x6f,0x63,0x6e,
    0x30,0x29,0x5d,0x5d,0x3b,0x0a,0x20,0x20,0x20,0x20,0x66,0x6c,0x6f,0x61,0x74,0x34,
    0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x5b,0x5b,0x75,0x73,0x65,0x72,0x28,0x6c,
    0x6f,0x63,0x6e,0x31,0x29,0x5d,0x5d,0x3b,0x0a,0x7d,0x3b,0x0a,0x0a,0x66,0x72,0x61,
    0x67,0x6d,0x65,0x6e,0x74,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,0x75,0x74,0x20,
    0x6d,0x61,0x69,0x6e,0x30,0x28,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x69,0x6e,0x20,0x69,
    0x6e,0x20,0x5b,0x5b,0x73,0x74,0x61,0x67,0x65,0x5f,0x69,0x6e,0x5d,0x5d,0x2c,0x20,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x32,0x64,0x3c,0x66,0x6c,0x6f,0x61,0x74,0x3e,
    0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x20,0x5b,0x5b,
    0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x28,0x30,0x29,0x5d,0x5d,0x2c,0x20,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x72,0x20,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,
    0x6c,0x30,0x20,0x5b,0x5b,0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x28,0x30,0x29,0x5d,
    0x5d,0x29,0x0a,0x7b,0x0a,0x20,0x20,0x20,0x20,0x6d,0x61,0x69,0x6e,0x30,0x5f,0x6f,
    0x75,0x74,0x20,0x6f,0x75,0x74,0x20,0x3d,0x20,0x7b,0x7d,0x3b,0x0a,0x20,0x20,0x20,
    0x20,0x6f,0x75,0x74,0x2e,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,
    0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2e,0x73,0x61,
    0x6d,0x70,0x6c,0x65,0x28,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,
    0x30,0x2c,0x20,0x69,0x6e,0x2e,0x74,0x65,0x78,0x55,0x56,0x29,0x20,0x2a,0x20,0x69,
    0x6e,0x2e,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x3b,0x0a,0x20,0x20,0x20,0x20,0x72,0x65,
    0x74,0x75,0x72,0x6e,0x20,0x6f,0x75,0x74,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};

//     diagnostic(off, derivative_uniformity);
//
//     var<private> coord : vec4f;
//
//     var<private> texUV : vec2f;
//
//     var<private> iColor : vec4f;
//
//     var<private> color : vec4f;
//
//     var<private> gl_Position : vec4f;
//
//     fn main_1() {
//       let x_19 : vec4f = coord;
//       let x_20 : vec2f = vec2f(x_19.x, x_19.y);
//       gl_Position = vec4f(x_20.x, x_20.y, 0.0f, 1.0f);
//       let x_30 : vec4f = coord;
//       texUV = vec2f(x_30.z, x_30.w);
//       let x_34 : vec4f = color;
//       iColor = x_34;
//       return;
//     }
//
//     struct main_out {
//       @builtin(position)
//       gl_Position : vec4f,
//       @location(0)
//       texUV_1 : vec2f,
//       @location(1)
//       iColor_1 : vec4f,
//     }
//
//     @vertex
//     fn main(@location(0) coord_param : vec4f, @location(1) color_param : vec4f) -> main_out {
//       coord = coord_param;
//       color = color_param;
//       main_1();
//       return main_out(gl_Position, texUV, iColor);
//     }
const vs_source_wgsl: [790]u8 = .{
    0x64,0x69,0x61,0x67,0x6e,0x6f,0x73,0x74,0x69,0x63,0x28,0x6f,0x66,0x66,0x2c,0x20,
    0x64,0x65,0x72,0x69,0x76,0x61,0x74,0x69,0x76,0x65,0x5f,0x75,0x6e,0x69,0x66,0x6f,
    0x72,0x6d,0x69,0x74,0x79,0x29,0x3b,0x0a,0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,0x69,
    0x76,0x61,0x74,0x65,0x3e,0x20,0x63,0x6f,0x6f,0x72,0x64,0x20,0x3a,0x20,0x76,0x65,
    0x63,0x34,0x66,0x3b,0x0a,0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,0x69,0x76,0x61,0x74,
    0x65,0x3e,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3a,0x20,0x76,0x65,0x63,0x32,0x66,
    0x3b,0x0a,0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,0x69,0x76,0x61,0x74,0x65,0x3e,0x20,
    0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x3b,0x0a,
    0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,0x69,0x76,0x61,0x74,0x65,0x3e,0x20,0x63,0x6f,
    0x6c,0x6f,0x72,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x3b,0x0a,0x0a,0x76,0x61,
    0x72,0x3c,0x70,0x72,0x69,0x76,0x61,0x74,0x65,0x3e,0x20,0x67,0x6c,0x5f,0x50,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x3b,0x0a,
    0x0a,0x66,0x6e,0x20,0x6d,0x61,0x69,0x6e,0x5f,0x31,0x28,0x29,0x20,0x7b,0x0a,0x20,
    0x20,0x6c,0x65,0x74,0x20,0x78,0x5f,0x31,0x39,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,
    0x66,0x20,0x3d,0x20,0x63,0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x20,0x20,0x6c,0x65,0x74,
    0x20,0x78,0x5f,0x32,0x30,0x20,0x3a,0x20,0x76,0x65,0x63,0x32,0x66,0x20,0x3d,0x20,
    0x76,0x65,0x63,0x32,0x66,0x28,0x78,0x5f,0x31,0x39,0x2e,0x78,0x2c,0x20,0x78,0x5f,
    0x31,0x39,0x2e,0x79,0x29,0x3b,0x0a,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,
    0x74,0x69,0x6f,0x6e,0x20,0x3d,0x20,0x76,0x65,0x63,0x34,0x66,0x28,0x78,0x5f,0x32,
    0x30,0x2e,0x78,0x2c,0x20,0x78,0x5f,0x32,0x30,0x2e,0x79,0x2c,0x20,0x30,0x2e,0x30,
    0x66,0x2c,0x20,0x31,0x2e,0x30,0x66,0x29,0x3b,0x0a,0x20,0x20,0x6c,0x65,0x74,0x20,
    0x78,0x5f,0x33,0x30,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x20,0x3d,0x20,0x63,
    0x6f,0x6f,0x72,0x64,0x3b,0x0a,0x20,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3d,0x20,
    0x76,0x65,0x63,0x32,0x66,0x28,0x78,0x5f,0x33,0x30,0x2e,0x7a,0x2c,0x20,0x78,0x5f,
    0x33,0x30,0x2e,0x77,0x29,0x3b,0x0a,0x20,0x20,0x6c,0x65,0x74,0x20,0x78,0x5f,0x33,
    0x34,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x20,0x3d,0x20,0x63,0x6f,0x6c,0x6f,
    0x72,0x3b,0x0a,0x20,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x78,0x5f,
    0x33,0x34,0x3b,0x0a,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x3b,0x0a,0x7d,0x0a,
    0x0a,0x73,0x74,0x72,0x75,0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x5f,0x6f,0x75,0x74,
    0x20,0x7b,0x0a,0x20,0x20,0x40,0x62,0x75,0x69,0x6c,0x74,0x69,0x6e,0x28,0x70,0x6f,
    0x73,0x69,0x74,0x69,0x6f,0x6e,0x29,0x0a,0x20,0x20,0x67,0x6c,0x5f,0x50,0x6f,0x73,
    0x69,0x74,0x69,0x6f,0x6e,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x2c,0x0a,0x20,
    0x20,0x40,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x28,0x30,0x29,0x0a,0x20,0x20,
    0x74,0x65,0x78,0x55,0x56,0x5f,0x31,0x20,0x3a,0x20,0x76,0x65,0x63,0x32,0x66,0x2c,
    0x0a,0x20,0x20,0x40,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x28,0x31,0x29,0x0a,
    0x20,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x5f,0x31,0x20,0x3a,0x20,0x76,0x65,0x63,
    0x34,0x66,0x2c,0x0a,0x7d,0x0a,0x0a,0x40,0x76,0x65,0x72,0x74,0x65,0x78,0x0a,0x66,
    0x6e,0x20,0x6d,0x61,0x69,0x6e,0x28,0x40,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,
    0x28,0x30,0x29,0x20,0x63,0x6f,0x6f,0x72,0x64,0x5f,0x70,0x61,0x72,0x61,0x6d,0x20,
    0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x2c,0x20,0x40,0x6c,0x6f,0x63,0x61,0x74,0x69,
    0x6f,0x6e,0x28,0x31,0x29,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x5f,0x70,0x61,0x72,0x61,
    0x6d,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x29,0x20,0x2d,0x3e,0x20,0x6d,0x61,
    0x69,0x6e,0x5f,0x6f,0x75,0x74,0x20,0x7b,0x0a,0x20,0x20,0x63,0x6f,0x6f,0x72,0x64,
    0x20,0x3d,0x20,0x63,0x6f,0x6f,0x72,0x64,0x5f,0x70,0x61,0x72,0x61,0x6d,0x3b,0x0a,
    0x20,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x63,0x6f,0x6c,0x6f,0x72,0x5f,
    0x70,0x61,0x72,0x61,0x6d,0x3b,0x0a,0x20,0x20,0x6d,0x61,0x69,0x6e,0x5f,0x31,0x28,
    0x29,0x3b,0x0a,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x20,0x6d,0x61,0x69,0x6e,
    0x5f,0x6f,0x75,0x74,0x28,0x67,0x6c,0x5f,0x50,0x6f,0x73,0x69,0x74,0x69,0x6f,0x6e,
    0x2c,0x20,0x74,0x65,0x78,0x55,0x56,0x2c,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x29,
    0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};

//     diagnostic(off, derivative_uniformity);
//
//     var<private> fragColor : vec4f;
//
//     @group(1) @binding(48) var iTexChannel0 : texture_2d<f32>;
//
//     @group(1) @binding(64) var iSmpChannel0 : sampler;
//
//     var<private> texUV : vec2f;
//
//     var<private> iColor : vec4f;
//
//     fn main_1() {
//       let x_23 : vec2f = texUV;
//       let x_24 : vec4f = textureSample(iTexChannel0, iSmpChannel0, x_23);
//       let x_27 : vec4f = iColor;
//       fragColor = (x_24 * x_27);
//       return;
//     }
//
//     struct main_out {
//       @location(0)
//       fragColor_1 : vec4f,
//     }
//
//     @fragment
//     fn main(@location(0) texUV_param : vec2f, @location(1) iColor_param : vec4f) -> main_out {
//       texUV = texUV_param;
//       iColor = iColor_param;
//       main_1();
//       return main_out(fragColor);
//     }
//
const fs_source_wgsl: [682]u8 = .{
    0x64,0x69,0x61,0x67,0x6e,0x6f,0x73,0x74,0x69,0x63,0x28,0x6f,0x66,0x66,0x2c,0x20,
    0x64,0x65,0x72,0x69,0x76,0x61,0x74,0x69,0x76,0x65,0x5f,0x75,0x6e,0x69,0x66,0x6f,
    0x72,0x6d,0x69,0x74,0x79,0x29,0x3b,0x0a,0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,0x69,
    0x76,0x61,0x74,0x65,0x3e,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,
    0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x3b,0x0a,0x0a,0x40,0x67,0x72,0x6f,0x75,0x70,
    0x28,0x31,0x29,0x20,0x40,0x62,0x69,0x6e,0x64,0x69,0x6e,0x67,0x28,0x34,0x38,0x29,
    0x20,0x76,0x61,0x72,0x20,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,
    0x30,0x20,0x3a,0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x5f,0x32,0x64,0x3c,0x66,
    0x33,0x32,0x3e,0x3b,0x0a,0x0a,0x40,0x67,0x72,0x6f,0x75,0x70,0x28,0x31,0x29,0x20,
    0x40,0x62,0x69,0x6e,0x64,0x69,0x6e,0x67,0x28,0x36,0x34,0x29,0x20,0x76,0x61,0x72,
    0x20,0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x20,0x3a,0x20,
    0x73,0x61,0x6d,0x70,0x6c,0x65,0x72,0x3b,0x0a,0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,
    0x69,0x76,0x61,0x74,0x65,0x3e,0x20,0x74,0x65,0x78,0x55,0x56,0x20,0x3a,0x20,0x76,
    0x65,0x63,0x32,0x66,0x3b,0x0a,0x0a,0x76,0x61,0x72,0x3c,0x70,0x72,0x69,0x76,0x61,
    0x74,0x65,0x3e,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3a,0x20,0x76,0x65,0x63,
    0x34,0x66,0x3b,0x0a,0x0a,0x66,0x6e,0x20,0x6d,0x61,0x69,0x6e,0x5f,0x31,0x28,0x29,
    0x20,0x7b,0x0a,0x20,0x20,0x6c,0x65,0x74,0x20,0x78,0x5f,0x32,0x33,0x20,0x3a,0x20,
    0x76,0x65,0x63,0x32,0x66,0x20,0x3d,0x20,0x74,0x65,0x78,0x55,0x56,0x3b,0x0a,0x20,
    0x20,0x6c,0x65,0x74,0x20,0x78,0x5f,0x32,0x34,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,
    0x66,0x20,0x3d,0x20,0x74,0x65,0x78,0x74,0x75,0x72,0x65,0x53,0x61,0x6d,0x70,0x6c,
    0x65,0x28,0x69,0x54,0x65,0x78,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2c,0x20,
    0x69,0x53,0x6d,0x70,0x43,0x68,0x61,0x6e,0x6e,0x65,0x6c,0x30,0x2c,0x20,0x78,0x5f,
    0x32,0x33,0x29,0x3b,0x0a,0x20,0x20,0x6c,0x65,0x74,0x20,0x78,0x5f,0x32,0x37,0x20,
    0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x20,0x3d,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,
    0x3b,0x0a,0x20,0x20,0x66,0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,
    0x28,0x78,0x5f,0x32,0x34,0x20,0x2a,0x20,0x78,0x5f,0x32,0x37,0x29,0x3b,0x0a,0x20,
    0x20,0x72,0x65,0x74,0x75,0x72,0x6e,0x3b,0x0a,0x7d,0x0a,0x0a,0x73,0x74,0x72,0x75,
    0x63,0x74,0x20,0x6d,0x61,0x69,0x6e,0x5f,0x6f,0x75,0x74,0x20,0x7b,0x0a,0x20,0x20,
    0x40,0x6c,0x6f,0x63,0x61,0x74,0x69,0x6f,0x6e,0x28,0x30,0x29,0x0a,0x20,0x20,0x66,
    0x72,0x61,0x67,0x43,0x6f,0x6c,0x6f,0x72,0x5f,0x31,0x20,0x3a,0x20,0x76,0x65,0x63,
    0x34,0x66,0x2c,0x0a,0x7d,0x0a,0x0a,0x40,0x66,0x72,0x61,0x67,0x6d,0x65,0x6e,0x74,
    0x0a,0x66,0x6e,0x20,0x6d,0x61,0x69,0x6e,0x28,0x40,0x6c,0x6f,0x63,0x61,0x74,0x69,
    0x6f,0x6e,0x28,0x30,0x29,0x20,0x74,0x65,0x78,0x55,0x56,0x5f,0x70,0x61,0x72,0x61,
    0x6d,0x20,0x3a,0x20,0x76,0x65,0x63,0x32,0x66,0x2c,0x20,0x40,0x6c,0x6f,0x63,0x61,
    0x74,0x69,0x6f,0x6e,0x28,0x31,0x29,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x5f,0x70,
    0x61,0x72,0x61,0x6d,0x20,0x3a,0x20,0x76,0x65,0x63,0x34,0x66,0x29,0x20,0x2d,0x3e,
    0x20,0x6d,0x61,0x69,0x6e,0x5f,0x6f,0x75,0x74,0x20,0x7b,0x0a,0x20,0x20,0x74,0x65,
    0x78,0x55,0x56,0x20,0x3d,0x20,0x74,0x65,0x78,0x55,0x56,0x5f,0x70,0x61,0x72,0x61,
    0x6d,0x3b,0x0a,0x20,0x20,0x69,0x43,0x6f,0x6c,0x6f,0x72,0x20,0x3d,0x20,0x69,0x43,
    0x6f,0x6c,0x6f,0x72,0x5f,0x70,0x61,0x72,0x61,0x6d,0x3b,0x0a,0x20,0x20,0x6d,0x61,
    0x69,0x6e,0x5f,0x31,0x28,0x29,0x3b,0x0a,0x20,0x20,0x72,0x65,0x74,0x75,0x72,0x6e,
    0x20,0x6d,0x61,0x69,0x6e,0x5f,0x6f,0x75,0x74,0x28,0x66,0x72,0x61,0x67,0x43,0x6f,
    0x6c,0x6f,0x72,0x29,0x3b,0x0a,0x7d,0x0a,0x0a,0x00,
};

////////////////////////////////////////////////////////////////////////////////

fn make_pipeline_internal(shader: sokol.gfx.Shader, primitive_type: sokol.gfx.PrimitiveType, blend_mode: Blend_Mode, color_format: sokol.gfx.PixelFormat, depth_format: sokol.gfx.PixelFormat, sample_count: i32, has_vs_color: bool) !sokol.gfx.Pipeline {
    var pip_desc: sokol.gfx.PipelineDesc = .{
        .shader = shader,
        .sample_count = sample_count,
        .depth = .{
            .pixel_format = depth_format,
        },
        .primitive_type = primitive_type,
        .index_type = .UINT32,
    };
    
    pip_desc.layout.buffers[0].stride = @sizeOf(Vertex);
    pip_desc.layout.attrs[vs_attr_coord].offset = @offsetOf(Vertex, "position");
    pip_desc.layout.attrs[vs_attr_coord].format = .FLOAT4;
    if (has_vs_color) {
        pip_desc.layout.attrs[vs_attr_color].offset = @offsetOf(Vertex, "color");
        pip_desc.layout.attrs[vs_attr_color].format = .UBYTE4N;
    }
    pip_desc.colors[0].pixel_format = color_format;
    pip_desc.colors[0].blend = blend_mode.blend_state();

    const pip = sokol.gfx.makePipeline(pip_desc);
    if (pip.id != sokol.gfx.invalid_id and sokol.gfx.queryPipelineState(pip) != .VALID) {
        sokol.gfx.destroyPipeline(pip);
        return error.MakePipelineFailed;
    }
    return pip;
}

fn lookup_pipeline(primitive_type: sokol.gfx.PrimitiveType, blend_mode: Blend_Mode) !sokol.gfx.Pipeline {
    const primitive_type_index: usize = @intCast(@intFromEnum(primitive_type));
    const pip_index: u32 = @intCast((primitive_type_index * @typeInfo(Blend_Mode).@"enum".fields.len) + @intFromEnum(blend_mode));
    
    if (sgp.pipelines[pip_index].id != sokol.gfx.invalid_id) {
        return sgp.pipelines[pip_index];
    }

    const pip = try make_pipeline_internal(sgp.shader, primitive_type, blend_mode, sgp.desc.color_format.?, sgp.desc.depth_format.?, sgp.desc.sample_count.?, true);
    sgp.pipelines[pip_index] = pip;
    return pip;
}

fn make_common_shader() sokol.gfx.Shader {
    const backend = sokol.gfx.queryBackend();
    var desc: sokol.gfx.ShaderDesc = .{};
    desc.images[0].used = true;
    desc.images[0].multisampled = false;
    desc.images[0].image_type = ._2D;
    desc.images[0].sample_type = .FLOAT;
    desc.samplers[0].used = true;
    desc.samplers[0].sampler_type = .FILTERING;
    desc.image_sampler_pairs[0].used = true;
    desc.image_sampler_pairs[0].image_slot = 0;
    desc.image_sampler_pairs[0].sampler_slot = 0;

    // GLCORE / GLES3 only
    desc.attrs[vs_attr_color].name = "coord";
    desc.attrs[vs_attr_color].name = "color";
    desc.image_sampler_pairs[0].glsl_name = "iTexChannel0_iSmpChannel0";

    // D3D11 only
    desc.attrs[vs_attr_coord].sem_name = "TEXCOORD";
    desc.attrs[vs_attr_coord].sem_index = 0;
    desc.attrs[vs_attr_color].sem_name = "TEXCOORD";
    desc.attrs[vs_attr_color].sem_index = 1;
    desc.d3d11_target = "vs_4_0";
    desc.fs.d3d11_target = "ps_4_0";

    // entry
    switch (backend) {
        .METAL_MACOS,
        .METAL_IOS,
        .METAL_SIMULATOR => {
            desc.vs.entry = "main0";
            desc.fs.entry = "main0";
        },
        else => {
            desc.vs.entry = "main";
            desc.fs.entry = "main";
        },
    }

    // source
    switch (backend) {
        .GLCORE => {
            desc.vs.source = @ptrCast(&vs_source_glsl410);
            desc.fs.source = @ptrCast(&fs_source_glsl410);
        },
        .GLES3 => {
            desc.vs.source = @ptrCast(&vs_source_glsl300es);
            desc.fs.source = @ptrCast(&fs_source_glsl300es);
        },
        .D3D11 => {
            desc.vs.source = @ptrCast(&vs_source_hlsl4);
            desc.fs.source = @ptrCast(&fs_source_hlsl4);
        },
        .METAL_MACOS => {
            desc.vs.source = @ptrCast(&vs_source_metal_macos);
            desc.fs.source = @ptrCast(&vs_source_metal_macos);
        },
        .METAL_IOS, .METAL_SIMULATOR => {
            desc.vs.source = @ptrCast(&vs_source_metal_ios);
            desc.fs.source = @ptrCast(&fs_source_metal_ios);
        },
        .WGPU => {
            desc.vs.source = @ptrCast(&vs_source_wgsl);
            desc.fs.source = @ptrCast(&fs_source_wgsl);
        },
        .DUMMY => {
            desc.vs.source = "";
            desc.fs.source = "";
        },
    }

    return sokol.gfx.makeShader(desc);
}

inline fn default_proj(width: i32, height: i32) Mat2x3 {
    const w: f32 = @floatFromInt(width);
    const h: f32 = @floatFromInt(height);

    // matrix to convert screen coordinate system
    // to the usual the coordinate system used on the backends
    return .{ .v = .{
        .{ 2.0 / w,      0.0, -1.0 },
        .{     0.0, -2.0 / h,  1.0 },
    }};
}

inline fn mul_proj_transform(proj: Mat2x3, transform: Mat2x3) Mat2x3 {
    // this actually multiply matrix projection and transform matrix in an optimized way
    const x = proj.v[0][0];
    const y = proj.v[1][1];
    return .{ .v = .{
        .{ x*transform.v[0][0], x*transform.v[0][1], x*transform.v[0][2]+proj.v[0][2] },
        .{ y*transform.v[1][0], y*transform.v[1][1], y*transform.v[1][2]+proj.v[1][2] },
    }};
}

fn next_indices(count: u32) ![]Index {
    const index = sgp.cur_index;
    if (index + count > sgp.indices.len) return error.IndexBufferFull;
    sgp.cur_index += count;
    return sgp.indices[index..][0..count];
}

fn next_indices_array(comptime count: u32) !*[count]Index {
    const index = sgp.cur_index;
    if (index + count > sgp.indices.len) return error.IndexBufferFull;
    sgp.cur_index += count;
    return sgp.indices[index..][0..count];
}

fn next_vertices(count: u32) ![]Vertex {
    const vertex_index = sgp.cur_vertex;
    if (vertex_index + count > sgp.vertices.len) return error.VertexBufferFull;
    sgp.cur_vertex += count;
    return sgp.vertices[vertex_index..][0..count];
}

fn next_vertices_array(comptime count: u32) !*[count]Vertex {
    const vertex_index = sgp.cur_vertex;
    if (vertex_index + count > sgp.vertices.len) return error.VertexBufferFull;
    sgp.cur_vertex += count;
    return sgp.vertices[vertex_index..][0..count];
}

fn prev_uniform() ?*Uniform {
    return if (sgp.cur_uniform > 0) &sgp.uniforms[sgp.cur_uniform - 1] else null;
}

fn next_uniform() !*Uniform {
    if (sgp.cur_uniform == sgp.uniforms.len) return error.UniformsFull;

    sgp.cur_uniform += 1;
    return &sgp.uniforms[sgp.cur_uniform - 1];
}

fn prev_command(offset: u32) ?*Command {
    if (sgp.cur_command >= offset) {
        return &sgp.commands[sgp.cur_command - offset];
    } else {
        return null;
    }
}

fn next_command() !*Command {
    if (sgp.cur_command == sgp.commands.len) return error.CommandsFull;
    sgp.cur_command += 1;
    return &sgp.commands[sgp.cur_command - 1];
}

fn prev_or_next_command(tag: std.meta.Tag(Command)) !*Command {
    if (prev_command(1)) |cmd| {
        if (cmd.* == tag) return cmd;
    }

    return try next_command();
}

fn get_thickness(primitive_type: sokol.gfx.PrimitiveType) f32 {
    return switch (primitive_type) {
        .POINTS, .LINES, .LINE_STRIP => sgp.state.thickness,
        else => 0.0,
    };
}

inline fn region_overlaps(a: Region , b: Region) bool {
    return !(a.x2 <= b.x1 or b.x2 <= a.x1 or a.y2 <= b.y1 or b.y2 <= a.y1);
}

fn merge_batch_command(pip: sokol.gfx.Pipeline, textures: Textures_Uniform, uniform: ?*Uniform, region: Region, first_index: u32, num_indices: u32) bool {//vertex_index: u32, num_vertices: u32) bool {
    if (batch_optimizer_depth == 0) return false;

    var maybe_prev_cmd: ?*Command = null;
    var inter_cmds_buf: [batch_optimizer_depth]*Command = undefined;
    var inter_cmds: []*Command = inter_cmds_buf[0..0];

    // Find a command that is a good candidate to batch
    var lookup_depth: u32 = batch_optimizer_depth;
    var depth: u32 = 0;
    while (depth < lookup_depth) : (depth += 1) {
        const cmd = prev_command(@intCast(depth + 1)) orelse break;
        switch (cmd.*) {
            .none => {
                // command was optimized away, search deeper
                lookup_depth += 1;
                continue;
            },
            .draw => |args| {
                // can only batch commands with the same bindings and uniforms
                if (args.pip.id == pip.id
                    and std.meta.eql(textures.active_images(), args.textures.active_images())
                    and std.meta.eql(textures.active_samplers(), args.textures.active_samplers())
                    and (uniform == null or std.mem.eql(u8, uniform.?.bytes(), sgp.uniforms[args.uniform_index].bytes()))
                ) {
                    maybe_prev_cmd = cmd;
                    break;
                } else {
                    inter_cmds.len += 1;
                    inter_cmds[inter_cmds.len - 1] = cmd;
                }
            },
            // stop on scissor/viewport
            else => break,
        }
    }
    const prev_cmd = maybe_prev_cmd orelse return false;

    // Allow batching only if the region of the current or previous draw is not touched by intermediate commands
    // Without this, we might mess up Z-ordering since we're not using the depth buffer
    var overlaps_next = false;
    var overlaps_prev = false;
    var prev_region = prev_cmd.draw.region;
    for (inter_cmds) |inter_cmd| {
        const inter_region = inter_cmd.draw.region;
        if (region_overlaps(region, inter_region)) {
            overlaps_next = true;
            if (overlaps_prev) {
                return false;
            }
        }
        if (region_overlaps(prev_region, inter_region)) {
            overlaps_prev = true;
            if (overlaps_next) {
                return false;
            }
        }
    }

    if (!overlaps_next) { // batch in the previous draw command
        if (inter_cmds.len > 0) {
            const prev_end_index: u32 = prev_cmd.draw.first_index + prev_cmd.draw.num_indices;
            const num_indices_after_prev_end: u32 = sgp.cur_index - prev_end_index;

            if (num_indices_after_prev_end > max_move_indices) return false;

            if (sgp.cur_index + num_indices <= sgp.indices.len) {
                // We could just use std.mem.rotate all the time, but if we have extra space, this should usually
                // require fewer total copies and probably will be easier on the branch predictor/prefetcher:
                std.mem.copyBackwards(Index, sgp.indices[prev_end_index + num_indices ..], sgp.indices[prev_end_index..][0..num_indices_after_prev_end]);
                @memcpy(sgp.indices[prev_end_index..].ptr, sgp.indices[first_index + num_indices ..][0..num_indices]);
            } else {
                std.mem.rotate(Index, sgp.indices[prev_end_index..sgp.cur_index], num_indices_after_prev_end - num_indices);
            }

            for (inter_cmds) |cmd| {
                cmd.draw.first_index += num_indices;
            }
        }

        // update draw region and indices
        prev_region.x1 = @min(prev_region.x1, region.x1);
        prev_region.y1 = @min(prev_region.y1, region.y1);
        prev_region.x2 = @max(prev_region.x2, region.x2);
        prev_region.y2 = @max(prev_region.y2, region.y2);
        prev_cmd.draw.num_indices += num_indices;
        prev_cmd.draw.region = prev_region;
    } else { // batch in the next draw command
        std.debug.assert(inter_cmds.len > 0);
        const prev_cmd_first_index = prev_cmd.draw.first_index;
        if (first_index - prev_cmd_first_index > max_move_indices) return false;

        const cmd = next_command() catch return false;

        const prev_cmd_num_indices = prev_cmd.draw.num_indices;
        std.mem.rotate(Index, sgp.indices[prev_cmd_first_index..first_index], prev_cmd_num_indices);

        for (inter_cmds) |inter_cmd| {
            inter_cmd.draw.first_index -= prev_cmd_num_indices;
        }

        // update draw region and vertices
        prev_region.x1 = @min(prev_region.x1, region.x1);
        prev_region.y1 = @min(prev_region.y1, region.y1);
        prev_region.x2 = @max(prev_region.x2, region.x2);
        prev_region.y2 = @max(prev_region.y2, region.y2);
        
        const final_first_index = first_index - prev_cmd_num_indices;
        const final_num_indices = prev_cmd.draw.num_indices + num_indices;

        // configure the draw command
        cmd.* = .{ .draw = .{
            .pip = pip,
            .textures = textures,
            .region = prev_region,
            .uniform_index = prev_cmd.draw.uniform_index,
            .first_index = final_first_index,
            .num_indices = final_num_indices,
        }};

        // force skipping the previous draw command
        prev_cmd.* = .none;
    }
    return true;
}

fn queue_draw(pip: sokol.gfx.Pipeline, region: Region, first_index: u32, num_indices: u32, num_private_vertices: u32, primitive_type: sokol.gfx.PrimitiveType) !void {
    // override pipeline
    var maybe_uniform: ?*Uniform = null;
    var final_pip = pip;
    if (sgp.state.pipeline.id != sokol.gfx.invalid_id) {
        final_pip = sgp.state.pipeline;
        maybe_uniform = &sgp.state.uniform;
    }

    errdefer {
        if (first_index + num_indices == sgp.cur_index) sgp.cur_index = first_index;
        sgp.cur_vertex -= num_private_vertices;
    }

    // invalid pipeline
    if (final_pip.id == sokol.gfx.invalid_id) return error.InvalidPipeline;

    // region is out of screen bounds
    if (region.x1 > 1.0 or region.y1 > 1.0 or region.x2 < -1.0 or region.y2 < -1.0) {
        if (first_index + num_indices == sgp.cur_index) sgp.cur_index = first_index;
        sgp.cur_vertex -= num_private_vertices;
        return;
    }

    // try to merge on previous command to draw in a batch
    switch (primitive_type) {
        .TRIANGLE_STRIP, .LINE_STRIP => {},
        else => if (merge_batch_command(final_pip, sgp.state.textures, maybe_uniform, region, first_index, num_indices)) return,
    }

    // setup uniform, try to reuse previous uniform when possible
    var uniform_index: u32 = impossible_id;
    if (maybe_uniform) |uniform| {
        var reuse_uniform = false;
        if (prev_uniform()) |prev| {
            reuse_uniform = std.mem.eql(u8, uniform.bytes(), prev.bytes());
        }
        if (!reuse_uniform) {
            const new_uniform = try next_uniform();
            new_uniform.* = sgp.state.uniform;
        }
        uniform_index = sgp.cur_uniform - 1;
    }

    const cmd = try next_command();
    cmd.* = .{ .draw = .{
        .pip = final_pip,
        .textures = sgp.state.textures,
        .region = region,
        .uniform_index = uniform_index,
        .first_index = first_index,
        .num_indices = num_indices,
    }};
}

inline fn mat3_vec2_mul(m: Mat2x3, v: Vec2) Vec2 {
    return .{
        .x = m.v[0][0]*v.x + m.v[0][1]*v.y + m.v[0][2],
        .y = m.v[1][0]*v.x + m.v[1][1]*v.y + m.v[1][2],
    };
}

fn transform_vec2(matrix: Mat2x3, dst: []Vec2, src: []const Vec2) void {
    for (dst, src) |*d, s| {
        d.* = mat3_vec2_mul(matrix, s);
    }
}

fn draw_solid_pip(primitive_type: sokol.gfx.PrimitiveType, vertices: []const Vec2, local_indices: []const u16) !void {
    std.debug.assert(sgp.init_cookie == init_cookie);
    std.debug.assert(sgp.cur_state > 0);
    if (vertices.len == 0) return;

    const first_index = sgp.cur_index;
    const first_vertex = sgp.cur_vertex;
    const ib = try next_indices(@intCast(local_indices.len));
    const vb = try next_vertices(@intCast(vertices.len));

    for (ib, local_indices) |*out, local_index| {
        out.* = first_vertex + local_index;
    }

    const thickness: f32 = switch (primitive_type) {
        .POINTS, .LINES, .LINE_STRIP => sgp.state.thickness,
        else => 0.0,
    };
    const color = sgp.state.color;
    const mvp = sgp.state.mvp; // copy to stack for more efficiency
    var region = Region.max;
    for (vb, vertices) |*out, vertex| {
        const p = mat3_vec2_mul(mvp, vertex);
        region.expand(p, thickness);
        out.* = .{ .position = p, .texcoord = .{ .x = 0, .y = 0 }, .color = color };
    }

    const pip = try lookup_pipeline(primitive_type, sgp.state.blend_mode);
    try queue_draw(pip, region, first_index, @intCast(ib.len), @intCast(vb.len), primitive_type);
}

const sokol = @import("sokol");
const std = @import("std");

// Copyright (c) 2020-2024 Eduardo Bart (https://github.com/edubart/sokol_gp)

// Permission is hereby granted, free of charge, to any person obtaining a copy of
// this software and associated documentation files (the "Software"), to deal in
// the Software without restriction, including without limitation the rights to
// use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
// of the Software, and to permit persons to whom the Software is furnished to do
// so.

// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
