/*

SDG                                                                                  JJ

                                Blank Page Game Jam
                                     Math

	Some important conventions:

	* The game world operates in a Left-Handed Coordinate Space.
	* Rotation Matrices are defined in row-major form. They're still stored in
 	 in column major form. If row-major proves to be faster, it should be trivial
	  to change.
	* Rotation matrices are from child-space to parent space, with the child vector
	  as a row-vector on the right. 
	  So a rotation from object-space to world space would look like v' = vA
	  If you see something like v' = Av, then this is actually a transformation from
	  the parent space to the child space (ie from world-space to object space).
	* Rotation Data is generally stored as quaternions. Whether it's composed via
	  quaternion multiplication (which is an intrinsic) or via matrix composition
	  is tbd based on performance.
	
	These conventions are in keeping with the conventions used in the book: 3D Math 
	Primer for Graphics and Game Development, which can be read freely at 
	https://gamemath.com 
	Many thanks to Dunn and Parbury for making the resource available.

	Some additional numerical conventions:

	* We use f32 unless we need the space of an f64 for some reason. This is what what
 	 the graphics card expects, so that's what we'll give it.
*/
package drill

import "core:math"
//import "core:math/linalg"


PI :: 3.14159265358979323846264338327950288
SQRT_2 :: 1.41421356237309504880168872420969808
SQRT_3 :: 1.732050807568877293527446341505872367


vec3 :: [3]f32
vec4 :: [4]f32

mat3 :: matrix[3, 3]f32
mat4 :: matrix[4, 4]f32

cos :: math.cos
sin :: math.sin
tan :: math.tan
acos :: math.acos
asin :: math.asin
atan :: math.atan
atan2 :: math.atan2

/* === Useful Conversions === */

rotation_from_quaternion :: proc(q: quaternion128) -> mat3 {
	assert(abs(q) == 1.0)
	w, x, y, z := q.w, q.x, q.y, q.z
	
    // odinfmt:disable
	return mat3{
		1 - 2 * y * y - 2 * z * z,	2 * x * y + 2 * w * z,		2 * x * z - 2 * w * y, 
		2 * x * y - 2 * w * z,		1 - 2 * x * x - 2 * z * z,	2 * y * z + 2 * w * x, 
		2 * x * z + 2 * w * y,		2 * y * z - 2 * w * x,		1 - 2 * x * x - 2 * y * y, 
	}
    // odinfmt:enable
}


// only used for display purposes
euler_from_quaternion :: proc(q: quaternion128) -> (pitch, heading, bank: f32) {
	sin_pitch := -2 * (q.y * q.z - q.w * q.x)

	if (abs(sin_pitch) == 1) { 	// possible precision issues here
		pitch = PI / 2
		heading = atan2(-q.x * q.z + q.w * q.y, 0.5 - q.y * q.y - q.z * q.z)
		bank = 0
	} else {
		pitch = asin(sin_pitch)
		heading = atan2(q.x * q.z + q.w * q.y, 0.5 - q.x * q.x - q.y * q.y)
		bank = atan2(q.x * q.y + q.w * q.z, 0.5 - q.x * q.x - q.z * q.z)
	}
	return
}

// only used for human entry
quaternion_from_euler :: proc(pitch, heading, bank: f32) -> (q: quaternion128) {
	cp, sp := cos(pitch / 2), sin(pitch / 2)
	ch, sh := cos(heading / 2), sin(heading / 2)
	cb, sb := cos(bank / 2), sin(bank / 2)

	q.w = ch * cp * cb + sh * sp * sb
	q.x = ch * sp * cb - sh * cp * sb
	q.y = sh * cp * cb - ch * sp * sb 
	q.z = ch * cp * sb - ch * sp * sb 
	return
}


/* === Projection Matrices (in when blocks to account for platform differences) === */

when ODIN_OS == .Darwin {
	// when the z value clips from [0, 1] ie metal or directx

	// TODO(caleb): If we ever decide to use directx, then this would also apply
	perspective_projection_matrix :: proc(
		vertical_fov, aspect_ratio, near_distance, far_distance: f32,
	) -> (
		m: mat4,
	) {
		zoom_x := atan(vertical_fov / 2.0)
		zoom_y := zoom_x / aspect_ratio

		depth_z := far_distance / (far_distance - near_distance)
		depth_w := (-1 * far_distance + near_distance) / (far_distance - near_distance)

		return mat4{zoom_x, 0, 0, 0, 0, zoom_y, 0, 0, 0, 0, depth_z, 1, 0, 0, depth_w, 0}
	}

	orthographic_projection_matrix :: proc(
		vertical_fov, aspect_ratio, near_distance, far_distance: f32,
	) -> (
		m: mat4,
	) {
		zoom_x := atan(vertical_fov / 2.0)
		zoom_y := zoom_x / aspect_ratio

		depth_z := 1 / (far_distance - near_distance)
		depth_w := near_distance / (near_distance - far_distance)

		return mat4{zoom_x, 0, 0, 0, 0, zoom_y, 0, 0, 0, 0, depth_z, 1, 0, 0, depth_w, 0}
	}

} else {
	// when the z value clips from [-1, 1] in clip space
	perspective_projection_matrix :: proc(
		vertical_fov, aspect_ratio, near_distance, far_distance: f32,
	) -> (
		m: mat4,
	) {
		zoom_x := atan(vertical_fov / 2.0)
		zoom_y := zoom_x / aspect_ratio

		depth_z := (far_distance + near_distance) / (far_distance - near_distance)
		depth_w := (-2 * far_distance + near_distance) / (far_distance - near_distance)

		return mat4{zoom_x, 0, 0, 0, 0, zoom_y, 0, 0, 0, 0, depth_z, 1, 0, 0, depth_w, 0}
	}

	orthographic_projection_matrix :: proc(
		vertical_fov, aspect_ratio, near_distance, far_distance: f32,
	) -> (
		m: mat4,
	) {
		zoom_x := atan(vertical_fov / 2.0)
		zoom_y := zoom_x / aspect_ratio

		depth_z := 2 / (far_distance - near_distance)
		depth_w := -1 * (near_distance + far_distance) / (far_distance - near_distance)

		return mat4{zoom_x, 0, 0, 0, 0, zoom_y, 0, 0, 0, 0, depth_z, 1, 0, 0, depth_w, 0}
	}
}
