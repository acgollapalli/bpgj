#!/bin/bash

code="$PWD"
opts=-vet
cd build > /dev/null
$code/tools/odin/odin build $opts $code
cd $code > /dev/null
