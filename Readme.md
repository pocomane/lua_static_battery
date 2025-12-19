
Lua static battery
==================

This is a script to build a static version of lua, using gcc and the musl C
library.  The toolchain are downloaded from [musl.cc](http://musl.cc). Some
usefull libraries are included too.

See the [Release Readme](Readme.deploy.md) for details on how to use the
application or which libraries are included.

The script can build linux, windows and mac binaries. Linux binaries are built
for both x86 (natively) and arm with hard float (through cross-compile).
Windows binaries are built through cross-compile from linux. The mac binaries
are built with a default LLVM toolchain, without musl.

In [Release page](https://github.com/pocomane/lua_static_battery/releases/latest)
you can fine the output binaries for all the supporterd platforms.

Usage
=====

The build script can be run with

```
./build.sh
```

It expects alpine linux and that all the sources the are in specific subfolder
`build`.  However, some workaraound are in place for other environment.

It will produce in the `build/deploy` subfolder a set of packages for different
platform containing the application `lua_static_batter.exe` with some
documentation.

Get the sources
===============

An utility script is provided to download the build script as well a all the
needed dependencies in a `build` folder:

```
./pack.sh update
```

You can use it also to download `lua_static_battery` too:

```
curl -L -k "https://raw.githubusercontent.com/pocomane/lua_static_battery/master/pack.sh" | bash -s update
./build/pack/build.sh
```

To change the download/build directory, you can set the `UPDATER_TARGET`
environment variable.

Build environment
=================

If you are on another linux distribution, you can use `runalp.sh` script, that
will download an Alpine linux image and run it in a container. The syntax is:

```
./runalp.sh ./pack.sh update
./runalp.sh ./build.sh
```

Build options
=============

To select the target architecture you can set the `TARGET` environment variable
to `linux`, `arm_linux`, `windows` or `mac`.

