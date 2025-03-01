/*

SDG                                                                                  JJ

                                Blank Page Game Jam
                                   Asset Loading
*/

package drill

import "core:encoding/hxa"
import "core:fmt"
import "core:strings"

ASSET_DIR :: "./assets/meshes/"

Vertex :: struct {
	position: [3]f32,
	color:    [3]f32,
}

Index :: u32

get_mesh_data :: proc(
	mesh_name: string,
	alloc := context.allocator,
) -> (
	hxa.File,
	[]Vertex,
	[dynamic]Index,
) {
	file_name := strings.concatenate([]string{ASSET_DIR, mesh_name})
	defer delete(file_name)

	mesh_file, read_err := hxa.read_from_file(file_name)
	fmt.assertf(read_err == nil, "could not load mesh %v because %v", mesh_name, read_err)

	// TODO(caleb): write a version of this that works on more than teapot 
	geometry_node := mesh_file.nodes[0].content.(hxa.Node_Geometry)
	vertex_count := int(geometry_node.vertex_count)
	vertices_flat_array := geometry_node.vertex_stack[0].data.([]f64le)

	vertices := make([]Vertex, vertex_count, alloc)

	fmt.printfln("num vertices %v", vertex_count)
	fmt.printfln("meta: %v", mesh_file.nodes[0].meta_data)
	fmt.printfln("num corner %v", geometry_node.edge_corner_count)
	fmt.printfln("num faces %v", geometry_node.face_count)

	for i := 0; i * 3 < vertex_count; i += 1 {
		vertices[i].position.x = f32(vertices_flat_array[i * 3])
		vertices[i].position.y = f32(vertices_flat_array[i * 3 + 1])
		vertices[i].position.z = f32(vertices_flat_array[i * 3 + 2])

		vertices[i].color = {1.0, 1.0, 1.0}
	}


	// TODO(caleb): this sucks
	indices := make([dynamic]Index, alloc)

	// TODO(caleb): account for the fact that not all of these are guaranteed to
	// be triangles
	j := 0
	num_triangles, num_quads: int
	index_stack := geometry_node.corner_stack[0].data.([]i32le)
	for index, i in index_stack {
		when false {
			if index < 0 do fmt.printfln("num corners %v", j + 1)
			if index == 0 do fmt.printfln("FOUND_A_ZERO")

			if index < 0 do j = 0
			else do j += 1
		}

		// TODO(caleb): decompose into triangles here
		// NOTE(caleb): This should only be done in preprocessing, meshes that ship should have triangles in threes
		{
			//fmt.println("i:", index);
			if index < 0 {
				if j == 2 {
					j = 0
					num_triangles += 1
					append(&indices, auto_cast -index)
				} else {
					fmt.assertf(
						j == 3,
						"We only support primitives of triangles and quads, not %v, in %v",
						index,
						index_stack[:i + 1],
						j,
					)
					num_quads += 1
					append(&indices, auto_cast index_stack[i - 1])
					append(&indices, auto_cast -index)
					append(&indices, auto_cast index_stack[i - j])
					j = 0
				}
			} else {
				//fmt.printfln("Appending %v", index)
				append(&indices, auto_cast index)
				j += 1
			}
		}
	}
	//fmt.printfln("Num triangles: %v", num_triangles)
	//fmt.printfln("Num quads: %v", num_quads)
	//fmt.printfln("index stack %v", index_stack)
	//fmt.printfln("indices %v", indices)
	return mesh_file, vertices, indices
}

destroy_resources :: proc(file: hxa.File, vertices: []Vertex, indices: [dynamic]Index) {
	hxa.file_destroy(file)
	delete(vertices)
	delete(indices)
}
