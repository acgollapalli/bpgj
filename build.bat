@echo off

set opts=-vet -debug
set code=%cd%
copy %code%\tools\odin\vendor\sdl3\sdl3.dll %code%\

glslc.exe .\assets\shaders\vulkan\base.frag -o .\assets\shaders\vulkan\base_frag.spv
glslc.exe .\assets\shaders\vulkan\base.vert -o .\assets\shaders\vulkan\base_vert.spv

%code%\tools\odin\odin.exe run %code%\src %opts% -out:bpgj.exe
popd
