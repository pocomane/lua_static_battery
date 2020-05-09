#!/bin/sh

set -x

die(){
  echo "ERROR"
  exit -1
}

export DOWNLOAD_GCC_TOOLCHAIN="http://musl.cc/i686-linux-musl-native.tgz"

# this should be the same of CC=" musl-gcc "
# export CC=" cc -specs /usr/share/dpkg/no-pie-compile.specs -specs /usr/share/dpkg/no-pie-link.specs -specs /usr/lib/x86_64-linux-musl/musl-gcc.specs "

export CC=" gcc "
export CFLAGS=" -std=gnu99 -O2 -I ../lua-5.3.5/src -I ../../lua-5.3.5/src "
export LDFLAGS=" -static -ldl "
export STRIP=" strip "

export TARGET_LUA="posix"
export CFLAGS_LUA=" -DLUA_USE_DLOPEN "
export LDFLAGS_LUA=" -ldl "

export TARGET_LUAFILESYSTEM=""
export CFLAGS_LUAFILESYSTEM=""

export TARGET_LUASOCKET="linux"
export EXTRA_TARGET_LUASOCKET="mime.o serial.o unix.o unixstream.o unixdgram.o"
export CFLAGS_LUASOCKET=""

export TARGET_LUACHILD=""
export CFLAGS_LUACHILD=" -DUSE_POSIX " ||die
export EXTRA_TARGET_LUACHILD="-c luachild_posix.c -o luachild_posix.o "

export TARGET_LUAPROC=""
export CFLAGS_LUAPROC=""

export TARGET_LUAPROC=""
export CFLAGS_PRELOAD=""
export LDFLAGS_PRELOAD=" -lm -ldl "

if [ "$TARGET" = "" ]; then
  export TARGET="linux"
fi

if   [ "$TARGET" = "linux" ]; then
  echo "building for linux"

  export CC="$PWD/build/i686-linux-musl-native/bin/i686-linux-musl-gcc"
  export STRIP="$PWD/build/i686-linux-musl-native/bin/strip"

elif [ "$TARGET" = "windows" ]; then
  echo "building for windows"

  export DOWNLOAD_GCC_TOOLCHAIN="http://musl.cc/i686-w64-mingw32-cross.tgz"

  export CC="$PWD/build/i686-w64-mingw32-cross/bin/i686-w64-mingw32-gcc"
  export LDFLAGS=" -static "
  export STRIP="$PWD/build/i686-w64-mingw32-cross/bin/i686-w64-mingw32-strip"

  export TARGET_LUA="mingw"
  export CFLAGS_LUA=""
  export LDFLAGS_LUA=""

  export TARGET_LUASOCKET="mingw"
  export EXTRA_TARGET_LUASOCKET=""
  export CFLAGS_LUASOCKET=" -DLUASOCKET_INET_PTON "

  export CFLAGS_LUACHILD=" -DUSE_WINDOWS " ||die
  export EXTRA_TARGET_LUACHILD=" -c luachild_windows.c -o luachild_windows.o "

  export CFLAGS_PRELOAD=" -DPRELOAD_FOR_WINDOWS "
  export LDFLAGS_PRELOAD=" -lm -lwsock32 -lws2_32 -lpthread "

elif [ "$TARGET" = "mac" ]; then
  echo "building for mac"

  export DOWNLOAD_GCC_TOOLCHAIN=""
  export CC=" gcc "
  export LDFLAGS=" -ldl "

  export TARGET_LUA="macosx"

else
  echo "unknown target '$TARGET'"
  exit -1
fi

mkdir -p build ||die
cd build ||die

if [ "$DOWNLOAD_GCC_TOOLCHAIN" != "" ]; then
  echo "downloading $DOWNLOAD_GCC_TOOLCHAIN"
  curl "$DOWNLOAD_GCC_TOOLCHAIN" --output cc_toolchain.tar.gz ||diw
  tar -xzf cc_toolchain.tar.gz ||die
fi
echo "downloading lua"
curl http://www.lua.org/ftp/lua-5.3.5.tar.gz --output lua-5.3.5.tar.gz ||die
tar -xzf lua-5.3.5.tar.gz ||die
git clone https://github.com/keplerproject/luafilesystem ||die
git clone https://github.com/diegonehab/luasocket ||die
git clone https://github.com/pocomane/luachild
git clone https://github.com/pocomane/luaproc-extended

cd lua-5.3.5 ||die
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUA" LDFLAGS="$LDFLAGS $LDFLAGS_LUA" $TARGET_LUA ||die
rm src/lua.o src/luac.o ||die
cd .. ||die

cd luafilesystem ||die
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUAFILESYSTEM" src/lfs.o ||die
cd .. ||die

cd luasocket ||die
if [ "$EXTRA_TARGET_LUASOCKET" != "" ]; then
  cd src
  make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUASOCKET" $EXTRA_TARGET_LUASOCKET ||die
  cd ..
fi
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUASOCKET" $TARGET_LUASOCKET # TODO : check it succeeded
echo "static " > ../socket_lua.c
xxd -i src/socket.lua >> ../socket_lua.c
cd .. ||die

cd luachild ||die
$CC $CFLAGS $CFLAGS_LUACHILD -c luachild_common.c -o luachild_common.o ||die
$CC $CFLAGS $CFLAGS_LUACHILD -c luachild_lua_5_3.c -o luachild_lua_5_3.o ||die
$CC $CFLAGS $CFLAGS_LUACHILD $EXTRA_TARGET_LUACHILD ||die
cd .. ||die

cd luaproc-extended ||die
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUAPROC" src/lpsched.o src/luaproc.o ||die
cd .. ||die

$CC $CFLAGS $CFLAGS_PRELOAD -DLUA_MAIN_FILE='"lua-5.3.5/src/lua.c"' -I . -I lua-5.3.5/src -I luafilesystem/src -I luasocket/src -I luachild -I luaproc-extended/src -c ../preload.c -o ./preload.o ||die
$CC -o lua.exe ./preload.o lua-5.3.5/src/*.o luafilesystem/src/*.o luasocket/src/*.o luachild/*.o luaproc-extended/src/*.o $LDFLAGS $LDFLAGS_PRELOAD ||die
$STRIP lua.exe

mkdir -p deploy
if [ "$TARGET" = "linux" ]; then
  tar -zcf deploy/lua_static_battery_linux.tar.gz lua.exe ||die
elif [ "$TARGET" = "windows" ]; then
  zip -r deploy/lua_static_battery_windows.zip lua.exe ||die
elif [ "$TARGET" = "mac" ]; then
  tar -zcf deploy/lua_static_battery_mac.tar.gz lua.exe ||die
fi
ls -lha deploy

