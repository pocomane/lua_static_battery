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

DWN_LUA="http://www.lua.org/ftp/lua-5.3.5.tar.gz"
DWN_LFS="https://github.com/keplerproject/luafilesystem"
DWN_LSOCKET="https://github.com/diegonehab/luasocket"
DWN_LCHILD="https://github.com/pocomane/luachild"
DWN_LPROC="https://github.com/pocomane/luaproc-extended"
DWN_GLUA="https://github.com/pocomane/glua"

if [ "$DOWNLOAD_GCC_TOOLCHAIN" != "" ]; then
  echo "downloading $DOWNLOAD_GCC_TOOLCHAIN"
  curl "$DOWNLOAD_GCC_TOOLCHAIN" --output cc_toolchain.tar.gz ||diw
  tar -xzf cc_toolchain.tar.gz ||die
fi
echo "downloading lua"
curl "$DWN_LUA" --output lua.tar.gz ||die
tar -xzf lua.tar.gz ||die
git clone "$DWN_LFS" ||die
git clone "$DWN_LSOCKET" ||die
git clone "$DWN_LCHILD" ||die
git clone "$DWN_LPROC" ||die
git clone "$DWN_GLUA" ||die

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

cd glua/ ||die
mv preload.c preload.c.bck
$CC $CFLAGS $CFLAGS_GLUA -DENABLE_STANDARD_LUA_CLI='"../lua-5.3.5/src/lua.c"' -DBINJECT_ARRAY_SIZE=32768 -DUSE_WHEREAMI -I . -I ../lua-5.3.5/src/ -c *.c ||die
mv preload.c.bck preload.c ||die
cd .. ||die

$CC $CFLAGS $CFLAGS_PRELOAD -DLUA_MAIN_FILE='"lua-5.3.5/src/lua.c"' -I . -I lua-5.3.5/src -I luafilesystem/src -I luasocket/src -I luachild -I luaproc-extended/src -c ../preload.c -o ./preload.o ||die
$CC $CFLAGS $CFLAGS_PRELOAD -DLUA_MAIN_FILE='"lua-5.3.5/src/lua.c"' -I . -I lua-5.3.5/src -I luafilesystem/src -I luasocket/src -I luachild -I luaproc-extended/src -c ../lua_patch.c -o ./lua_patch.o ||die

$CC -o lua.exe ./lua_patch.o ./preload.o lua-5.3.5/src/*.o luafilesystem/src/*.o luasocket/src/*.o luachild/*.o luaproc-extended/src/*.o $LDFLAGS $LDFLAGS_PRELOAD ||die
$STRIP lua.exe ||die

$CC -o lua_merge.exe ./preload.o lua-5.3.5/src/*.o luafilesystem/src/*.o luasocket/src/*.o luachild/*.o luaproc-extended/src/*.o glua/*.o $LDFLAGS $LDFLAGS_PRELOAD ||die
$STRIP lua_merge.exe ||die

cp ../Readme.deploy.md ./wip ||die
echo -n "\n" >> ./wip ||die
echo -n "\nVersion report" >> ./wip ||die
echo -n "\n###############" >> ./wip ||die
echo -n "\n" >> ./wip ||die
echo -n "\nlua static battery version $(cd ..; git describe --tags)" >> ./wip ||die
echo -n "\nlua static battery link http://github.com/pocomane/lua_static_version $(cd ..; git rev-parse HEAD)" >> ./wip ||die
echo -n "\ntoolchain version $DOWNLOAD_GCC_TOOLCHAIN" >> ./wip ||die
echo -n "\nlua version 5.3.5 $DWN_LUA" >> ./wip ||die
echo -n "\nluafilesystem version $DWN_LFS $(cd luafilesystem && git rev-parse HEAD)" >> ./wip ||die
echo -n "\nluasocket version $DWN_LSOCKET $(cd luasocket && git rev-parse HEAD)" >> ./wip ||die
echo -n "\nluachild version $DWN_LCHILD $(cd luachild && git rev-parse HEAD)" >> ./wip ||die
echo -n "\nluaproc version $DWN_LPROC $(cd luaproc-extended && git rev-parse HEAD)" >> ./wip ||die
echo -n "\nglua version $DWN_GLUA $(cd glua && git rev-parse HEAD)" >> ./wip ||die
echo >> ./wip ||die
cp ./wip ./Readme.md ||die

mkdir -p deploy
if [ "$TARGET" = "linux" ]; then
  tar -zcf deploy/lua_static_battery_linux.tar.gz Readme.md lua.exe lua_merge.exe ||die
elif [ "$TARGET" = "windows" ]; then
  zip -r deploy/lua_static_battery_windows.zip Readme.md lua.exe lua_merge.exe ||die
elif [ "$TARGET" = "mac" ]; then
  tar -zcf deploy/lua_static_battery_mac.tar.gz Readme.md lua.exe lua_merge.exe ||die
fi
ls -lha deploy

