
Lua static battery
==================

This is a script to build a static version of lua, using gcc and the musl C
library.  The toolchain are downloaded from [musl.cc](http://musl.cc). Some
usefull libraries are included too.

The script can build linux, windows and mac binaries. Windows binaries are
built through cross-building from linux. The mac binaries are built with a
default LLVM toolchain, without musl.

Library list and documentation
==============================

Here a link to the documentation of the included software:

- [Lua](https://www.lua.org/manual/5.3), the standalone interpreter is in the generated `lua.exe`
- [Lua File System](https://keplerproject.github.io/luafilesystem/manual.html#reference), it is enabled with `local lfs = require "lfs"`
- [Lua Socket](http://w3.impa.br/~diego/software/luasocket/reference.html), it is enabled with `local socket = require "socket"`
- [Lua Child](https://github.com/pocomane/luachild), it is enabled with `local child = require "luachild"`
- [LuaProc](https://github.com/pocomane/luaproc-extended), it is enabled with `local proc = require "luaproc"`

Automatic Release
=================

This repository is configured to automatically publish release files, thanks to
[Travis-CI](https://travis-ci.org).  To give the right tag to a release, commit
and tag informations must be pushed together, e.g.:

```
git commit -a -m 'Changes summary'
git commit tag 0.1_wip
git commit push origin : 0.1_wip
```

