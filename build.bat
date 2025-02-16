@echo off

set opts=-vet -debug
set code=%cd%
copy %code%\tools\odin\vendor\sdl3\sdl3.dll %code%\

glslc.exe .\assets\shaders\base.frag -o .\assets\shaders\base_frag.spv
glslc.exe .\assets\shaders\base.vert -o .\assets\shaders\base_vert.spv

%code%\tools\odin\odin.exe run %code%\src %opts% -out:bpgj.exe
popd
