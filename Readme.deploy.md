
Lua static battery
===================

This is a static version of lua in the sense that it should run without
requiring any external library. It lets you to embed a script in the
executable and provides also some useful libraries.

All the softwares is released under MIT-style license.

Library list and documentation
==============================

Here a link to the documentation of the included software:

- [Lua 5.4.7](https://www.lua.org/manual/5.4), the standalone interpreter is in the generated `lua.exe`
- [Lua File System](https://keplerproject.github.io/luafilesystem/manual.html#reference), it is enabled with `local lfs = require "lfs"`
- [Lua Socket](http://w3.impa.br/~diego/software/luasocket/reference.html), it is enabled with `local socket = require "socket"`
- [Lua Child](https://github.com/pocomane/luachild), it is enabled with `local child = require "luachild"`
- [LuaProc](https://github.com/pocomane/luaproc-extended), it is enabled with `local proc = require "luaproc"`
- [Glua](https://github.com/pocomane/glua), the core of the inject system

Usage
=====

This application let you to embed a lua script in a standalone executable.

As example:

```
echo "print'hello world!" > hello_world.lua
./lua_static_library.exe hello_world.lua
```

(or drag `hello_world.lua` on `lua_static_library.exe`). It will create `glued.exe`
that contain the script. Launch it and the message `hello world!` will be
displayed in the console.

Please, be aware that `lua_static_library.exe` is (deliberately) an extremly simple tool. It
does not try to reduce size, or to embed other lua modules. For such advanced
operation you can use something like [lua squish](http://matthewwild.co.uk/projects/squish/home) and then use glua.exe
on the resulting file.

This is application behaves differently according to the last argument passed.
If the last argumnent is not one of the following it acts like it was passed
`--run-or-marge` one.  It follows a description of all the commands avaiable.

```
./lua_static_battery.exe script.lua --merge
```

This command copies `lua_static_battery.exe` the target `glued.exe` file, injecting the
script passed as argument. If there was already another script embeded, than
the new one will be appended.

```
./lua_static_battery.exe [arg1] ... [argN] --run
```

This command executes the lua script embedded in the executable. Initially
there is no script so this command does nothing. If you used the `--merge`
command previously, and use the `--run` command on the output, the injected
script will be run.

When executed, the last argument is removed, then script will be run with all
the other command line arguments.  The defaults lua globals will be avaiable.
Moreover the libraries defined in [preload.c](preload.c) are embedded.

If you want to embed lua VM code, use the default luac compiler and run `lua_static_battery`
on the its output. As described in the lua manual, the lua bytecode is
compatible across machine with the same word size and byte order.

```
./lua_static_battery.exe [arg1] ... [argN] --merge-or-run
```

If a script is embeded this is exactly like `--run`, otherwise it run the
`--merge` command. Note that this is the default command in case no specific one
is selected as last argument. In such case, if there is a script, the last argument
is not removed, preserving '[argN]' for the emebed script.

```
./lua_static_battery.exe [arg1] ... [argN] --lua
```

This command fallback to the stanard `lua` command line operation. For example
running it without any other arguments, launche the interactive interpreter.
However, all the extra globals shown in the `--run` command are avaiable also in
this mode.

```
./lua_static_battery.exe [arg1] ... [argN] --clear
```

... work in progress (implement and write documentation) ...

