
Lua static battery
===================

This is a static version of lua in the sense that it should run without
requiring any external library. It lets you to embed a script in the
executable and provides also some useful libraries.

All the softwares is released under MIT-style license.

Usage
=====

This application behaves like a standard lua command line tool, you can refer
to the [Official documentation](https://www.lua.org/manual/5.4/manual.html#7).
The difference is that `lua_static_batteries` embeds also some libraries. You can
found the library documentation at the following links:

- [Lua File System](https://keplerproject.github.io/luafilesystem/manual.html#reference), it is enabled with `local lfs = require "lfs"`
- [Lua Socket](http://w3.impa.br/~diego/software/luasocket/reference.html), it is enabled with `local socket = require "socket"`
- [Lua Child](https://github.com/pocomane/luachild), it is enabled with `local child = require "luachild"`
- [LuaProc](https://github.com/pocomane/luaproc-extended), it is enabled with `local proc = require "luaproc"`
- [Lua TUI mode](https://github.com/pocomane/lua_tui_mode), it is enabled with `local tui = require "lua_tui_mode"`
- [Glua](https://github.com/pocomane/glua), it is enabled with `local glua_pack = require "glua_pack"`

Embed a script
===============

As explained in its documentation, the `glua_pack` function can be used to
create a new standalone executable taht embeds a lua script. It will be run
instead of the standard lua interpreter, an obviously it can use all the
emebeded libraries.

As example:

```
echo 'require"glua_pack"(argv[1], "glued.exe")' > embed.lua
./lua_static_battery.exe -e 'require"glua_pack"("embed.lua", "lsb.exe")'
chmod ugo+x lsb.exe
```

Will generate the application `lsb.exe` that run
`require"glua_pack"(argv[1], "glued.exe")` when launched. So you can use itself
to embed other script more easly:

```
echo "print'hello world!" > hello_world.lua
./lsb.exe hello_world.lua
chmod ugo+x glued.exe
```

(or drag `hello_world.lua` on `lsb.exe`). It will create `glued.exe`
that contain the script. Launch it and the message `hello world!` will be
displayed in the console.

Please, be aware that `lua_static_library.exe` is (deliberately) an extremly
simple tool. It does not try to reduce size, or to embed other lua modules. For
such advanced operation you can use something like [lua
squish](http://matthewwild.co.uk/projects/squish/home) and then use glua.exe on
the input file.

