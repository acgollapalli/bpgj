/*

SDG                                                                                  JJ

Blank Page Game Jam
Entry Point

*/

package drill

import "core:fmt"
import "core:mem"
import sdl "vendor:sdl3"

SHADER_FORMAT : sdl.GPUShaderFormat

Vertex :: struct {
    position: [3]f32,
    color: [3]f32,
}

UniformCamera :: struct {
    position: [3]f32,
    //rotation: quaternion128,
}

KeyboardState :: struct {
    w: bool,
    a: bool,
    s: bool,
    d: bool,
}

SQRT_2 :: 1.41421356237 
SQRT_3 :: 1.73205080757

CAMERA_MOVEMENT_SPEED :: 0.01

main :: proc () {
    when ODIN_OS != .Darwin {
        SHADER_FORMAT = { .SPIRV }
        shader_code_vert := #load("../assets/shaders/base_vert.spv")
        vert_info := sdl.GPUShaderCreateInfo {
            code_size =            len(shader_code_vert),
            code =                 raw_data(shader_code_vert),
            entrypoint =           "main",
            format =               {.SPIRV},
            stage =                .VERTEX,
            num_samplers =         0, // TODO(caleb): change when we have samplers
            num_storage_textures = 0,
            num_storage_buffers=   0,
            num_uniform_buffers=   1,
            props =                0,
        }
        
        shader_code_frag := #load("../assets/shaders/base_frag.spv")
        frag_info := sdl.GPUShaderCreateInfo {
            code_size =            len(shader_code_frag),
            code =                 raw_data(shader_code_frag),
            entrypoint =           "main",
            format =               {.SPIRV},
            stage =                .FRAGMENT,
            num_samplers =         0, // TODO(caleb): change when we have samplers
            num_storage_textures = 0,
            num_storage_buffers=   0,
            num_uniform_buffers=   0,
            props =                0,
        }
    } else {
        SHADER_FORMAT = { .MSL }
    }
    
    vertices := []Vertex{ 
        {{ 0.0, 0.5, 0.0}, { 1.0, 0.0, 0.0 }},
        {{ -0.5, -0.5, 0.0 }, { 0.0, 1.0, 0.0 }},
        {{ 0.5, -0.5, 0.0 }, { 0.0, 0.0, 1.0 }}
    }
    
    vertex_buffer_descriptions := []sdl.GPUVertexBufferDescription{{
            slot = 0,
            pitch = size_of(Vertex),
            input_rate = .VERTEX,
        }
    }
    vertex_buffer_attributes := []sdl.GPUVertexAttribute{
        {
            location = 0,
            buffer_slot = 0,
            format = .FLOAT3,
            offset = 0,
        },
        {
            location = 1,
            buffer_slot = 0,
            format = .FLOAT3,
            offset = auto_cast offset_of(Vertex, color)
        },
    }
    
    // FIXME(caleb): fill in
    vertex_input_state := sdl.GPUVertexInputState {
        vertex_buffer_descriptions =  raw_data(vertex_buffer_descriptions), 
        num_vertex_buffers =          auto_cast len(vertex_buffer_descriptions),
        vertex_attributes =           raw_data(vertex_buffer_attributes),
        num_vertex_attributes =       auto_cast len(vertex_buffer_attributes),
    }
    
    // TODO(caleb): define window flags here
    windowFlags : sdl.WindowFlags = {}
    
    window := sdl.CreateWindow("Drill: The Blank Page Game Jam Game", 1920, 1080, windowFlags)
        fmt.assertf(window != nil, "Could not get window!")
        
        device := sdl.CreateGPUDevice(SHADER_FORMAT, ODIN_DEBUG, nil)
        claimed := sdl.ClaimWindowForGPUDevice(device, window)
        fmt.assertf(claimed, "Window not claimed by gpu device!")
        // TODO(caleb): check to ensure GPU supports present modes 
        // TODO(caleb): check to ensure GPU supports swapchain composition
        swapchain_format := sdl.GetGPUSwapchainTextureFormat(device, window)
        
        vert_shader := sdl.CreateGPUShader(device, vert_info)
        defer sdl.ReleaseGPUShader(device, vert_shader)
        frag_shader := sdl.CreateGPUShader(device, frag_info)
        defer sdl.ReleaseGPUShader(device, frag_shader)
        
        transfer_buffer_init := sdl.CreateGPUTransferBuffer(device, sdl.GPUTransferBufferCreateInfo {
                                                                usage = .UPLOAD,
                                                                size = size_of(Vertex)*u32(len(vertices)), // TODO(caleb): we may need two buffers
                                                                // props go here
                                                            })
    {
        host_side_transfer_buffer := sdl.MapGPUTransferBuffer(device, transfer_buffer_init, true)
            assert(host_side_transfer_buffer != nil)
            mem.copy_non_overlapping(host_side_transfer_buffer, raw_data(vertices), size_of(Vertex)*len(vertices))
            sdl.UnmapGPUTransferBuffer(device, transfer_buffer_init)
            
    }
    
    vertex_buffer_create_info := sdl.GPUBufferCreateInfo {
        usage = { .VERTEX }, // MAYBE(caleb): also storage for colors?
        size = size_of(Vertex)*u32(len(vertices)),
    }
    assert(vertex_buffer_create_info.size > 0)
        vertices_buffer_init := sdl.CreateGPUBuffer(device, vertex_buffer_create_info)
        
        command_buf_init := sdl.AcquireGPUCommandBuffer(device)
        copy_pass := sdl.BeginGPUCopyPass(command_buf_init)
        sdl.UploadToGPUBuffer(copy_pass, 
                              sdl.GPUTransferBufferLocation { 
                                  transfer_buffer = transfer_buffer_init, 
                                  offset = 0 
                              },
                              sdl.GPUBufferRegion {
                                  buffer = vertices_buffer_init, 
                                  offset = 0, 
                                  size = size_of(Vertex)*u32(len(vertices))
                              },
                              true)
        sdl.EndGPUCopyPass(copy_pass)
        fence_init := sdl.SubmitGPUCommandBufferAndAcquireFence(command_buf_init)
        
        rasterizer_state := sdl.GPURasterizerState {
        fill_mode = .FILL,
        cull_mode = .BACK,
        front_face = .COUNTER_CLOCKWISE,
        // TODO(caleb): DEPTH PARAMS HERE
    }
    multisample_state := sdl.GPUMultisampleState {} // FIXME(caleb): fill in
    depth_stencil_state := sdl.GPUDepthStencilState {} // FIXME(caleb): fill in
    
    base_blend_state := sdl.GPUColorTargetBlendState { // TODO(caleb): fill in
        src_color_blendfactor = .ONE,
        dst_color_blendfactor = .ZERO, // TODO(caleb): add alpha blending
        color_blend_op = .ADD,
        src_alpha_blendfactor = .ONE,
        dst_alpha_blendfactor = .ZERO,
        alpha_blend_op = .ADD,
        color_write_mask = {},
        enable_blend = true,
        enable_color_write_mask = false,
    }
    
    color_target_descriptions := []sdl.GPUColorTargetDescription{
        {
            format = swapchain_format,
            blend_state = base_blend_state,
        }
    }
    
    target_info := sdl.GPUGraphicsPipelineTargetInfo {
        color_target_descriptions = raw_data(color_target_descriptions),
        num_color_targets = auto_cast len(color_target_descriptions),
        // TODO(caleb): fill in the rest when we add depth tests
    }
    
    pipeline_create_info := sdl.GPUGraphicsPipelineCreateInfo {
        vertex_shader =       vert_shader,
        fragment_shader =     frag_shader,
        vertex_input_state =  vertex_input_state,
        primitive_type =      .TRIANGLELIST,
        rasterizer_state =    rasterizer_state,
        multisample_state =   multisample_state,
        depth_stencil_state = depth_stencil_state,
        target_info =         target_info
    }
    
    pipeline := sdl.CreateGPUGraphicsPipeline(device, pipeline_create_info); 
    
    for !sdl.QueryGPUFence(device, fence_init) {}
    sdl.ReleaseGPUFence(device, fence_init);
    
    uniform_camera : UniformCamera
        
        keyboard_state : KeyboardState
        event : sdl.Event
        mainloop: for  {
        if (sdl.PollEvent(&event)) { // handle input events
#partial switch event.type {
            case .KEY_DOWN:
            
            switch {
                case event.key.key == sdl.K_W: keyboard_state.w = true
                    case event.key.key == sdl.K_A: keyboard_state.a = true
                    case event.key.key == sdl.K_S: keyboard_state.s = true
                    case event.key.key == sdl.K_D: keyboard_state.d = true
            }
            case .KEY_UP:
            switch {
                case event.key.key == sdl.K_W: keyboard_state.w = false
                    case event.key.key == sdl.K_A: keyboard_state.a = false
                    case event.key.key == sdl.K_S: keyboard_state.s = false
                    case event.key.key == sdl.K_D: keyboard_state.d = false
            }
            case .WINDOW_CLOSE_REQUESTED:	  break; // TODO(caleb): cleanup here
            case .QUIT:						break mainloop;
        }
    }
    
    // TODO(caleb): game computation goes here
    dPos : [3]f32 // TODO(caleb): not really an accurate name for this
        if keyboard_state.w do dPos.y += 1
        if keyboard_state.s do dPos.y -= 1
        if keyboard_state.a do dPos.x -= 1
        if keyboard_state.d do dPos.x += 1
        
        if dPos.x != 0 && dPos.y != 0 do dPos /= SQRT_2
        
        uniform_camera.position += (CAMERA_MOVEMENT_SPEED * dPos)
        
        // begin rendering
        swapchain_texture : ^sdl.GPUTexture;
    w,h : u32;
    
    command_buf_render := sdl.AcquireGPUCommandBuffer(device);
    // TODO(caleb): replace the wait and acquire with fences like a proper graphics programmer
    texture_ok := sdl.WaitAndAcquireGPUSwapchainTexture(command_buf_render, window, &swapchain_texture, &w, &h);
    fmt.assertf(texture_ok, "Failed to acquire swapchain texture!");
    
    sdl.PushGPUVertexUniformData(command_buf_render, 0, &uniform_camera, size_of(UniformCamera))
        
        color_targets := []sdl.GPUColorTargetInfo{
        {
            texture = swapchain_texture,
            //mip_level = 0,
            //layer = 0,
            clear_color = sdl.FColor {0, 0, 0, 1},
            load_op = .CLEAR,
            store_op = .STORE,
            // other props here
            
        }
    }
    
    render_pass := sdl.BeginGPURenderPass(command_buf_render, raw_data(color_targets), auto_cast len(color_targets), {});
    sdl.BindGPUGraphicsPipeline(render_pass, pipeline);
    viewport := sdl.GPUViewport {
        w = f32(w),
        h = f32(h),
        min_depth = 0.1,
        max_depth = 1.0, // TODO(caleb): fill out the full struct maybe
    }
    sdl.SetGPUViewport(render_pass, viewport);
    // TODO(caleb): maybe set a scissor here??
    
    
    vertex_bindings := []sdl.GPUBufferBinding{
        {
            buffer = vertices_buffer_init,
            offset = 0
        }
    }
    
    
    sdl.BindGPUVertexBuffers(render_pass, 0, raw_data(vertex_bindings), auto_cast len(vertex_bindings));
    
    // TODO(caleb): bind vertex samplers here
    sdl.DrawGPUPrimitives(render_pass, 3, 1, 0, 0);
    sdl.EndGPURenderPass(render_pass);
    submit_ok := sdl.SubmitGPUCommandBuffer(command_buf_render);
    fmt.assertf(submit_ok, "Failed to sumbit command buffer!");
}
}