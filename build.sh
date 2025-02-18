#!/bin/bash

code="$PWD"

# xcrun -sdk macosx metal -o $code/assets/shaders/metal/base_vert.ir  -c $code/assets/shaders/metal/base_vert.metal
# xcrun -sdk macosx metal -o $code/assets/shaders/metal/base_frag.ir  -c $code/assets/shaders/metal/base_frag.metal

opts="-vet -debug"
$code/tools/odin/odin run $code/src $opts -out:bpgj
cd $code > /dev/null
