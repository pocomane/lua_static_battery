
Lua static battery
==================

This is a script to build a static version of lua, using gcc and the musl C
library.  The toolchain are downloaded from [musl.cc](http://musl.cc). Some
usefull libraries are included too.

The script can build linux, windows and mac binaries. Linux binaries are built
for both x86 (natively) and arm with hard float (through cross-compile).
Windows binaries are built through cross-compile from linux. The mac binaries
are built with a default LLVM toolchain, without musl.

Library list and documentation
==============================

Here a link to the documentation of the included software:

- [Lua 5.4.0](https://www.lua.org/manual/5.4), the standalone interpreter is in the generated `lua.exe`
- [Lua File System](https://keplerproject.github.io/luafilesystem/manual.html#reference), it is enabled with `local lfs = require "lfs"`
- [Lua Socket](http://w3.impa.br/~diego/software/luasocket/reference.html), it is enabled with `local socket = require "socket"`
- [Lua Child](https://github.com/pocomane/luachild), it is enabled with `local child = require "luachild"`
- [LuaProc](https://github.com/pocomane/luaproc-extended), it is enabled with `local proc = require "luaproc"`
- [Glua](https://github.com/pocomane/glua), it is a lua+script embedding utility

