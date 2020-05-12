
Lua static battery
===================

This is a static version of lua in the sense that it should run without
requiring any external library. It embeds also some useful libraries.

See [lua_static_battery](http://github.com/pocomane/lua_static_battery) for more
details.

All the software is released under MIT-style license.

Library list and documentation
==============================

Here a link to the documentation of the included software:

- [Lua](https://www.lua.org/manual/5.3), the standalone interpreter is in the generated `lua.exe`
- [Lua File System](https://keplerproject.github.io/luafilesystem/manual.html#reference), it is enabled with `local lfs = require "lfs"`
- [Lua Socket](http://w3.impa.br/~diego/software/luasocket/reference.html), it is enabled with `local socket = require "socket"`
- [Lua Child](https://github.com/pocomane/luachild), it is enabled with `local child = require "luachild"`
- [LuaProc](https://github.com/pocomane/luaproc-extended), it is enabled with `local proc = require "luaproc"`
- [Glua](https://github.com/pocomane/glua), for the `lua_merge.exe` tool

Tools
======

The package contains several tool. Each binary does not depend on any other:
they are fully standalone.

lua.exe
--------

The standard lua interpreter, as documented at `lua.org`

lua_merge.exe
--------------

It is a tool to generate standalone executable embedding lua as well as user
scripts.

It takes a lua script as command line argument, and it will generate the
`glued.exe` file. When executed, the script will be run with all the command
line arguments.  The defaults lua globals will be avaiable plus the libraries
previously discussed.

As example:

```
echo "print'hello world!" > hello_world.lua
./lua_merge.exe hello_world.lua
```

(or drag `hello_world.lua` on `lua_merge.exe`). It will create `glued.exe`
that contain the script. Launch it and the message `hello world!` will be
displayed in the console.

Note: if the script is bigger than 32k, it will be appended at end of the
output executabled. This is useful because no integrity check is performed at
startup, so you can open the output binary in a text editor, and change the
script at its end. You can force such condition asking `lua_merge.exe` to embed
a fake big script (e.g. 32k of white spaces), that you can change later.

If you want to avoid to store the script in human-readable/writable form, you
can preliminarly compile it to lua bytecode with the standard lua facility
(i.e. `load` + `srting.dump`).
