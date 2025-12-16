#!/bin/sh

set -x

die(){
  echo "ERROR"
  exit -1
}

SCRDIR="$(realpath $(dirname "$0"))"
BUILDDIR="$SCRDIR/build"
mkdir -p "$BUILDDIR"
cd "$BUILDDIR"

# this should be the same of CC=" musl-gcc "
# export CC=" cc -specs /usr/share/dpkg/no-pie-compile.specs -specs /usr/share/dpkg/no-pie-link.specs -specs /usr/lib/x86_64-linux-musl/musl-gcc.specs "

export CC=" gcc "
export CFLAGS=" -std=gnu99 -O2 -I $BUILDDIR/lua/src "
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

  export CC="$PWD/muslcc/bin/i686-linux-musl-gcc"
  export STRIP="$PWD/muslcc/bin/strip"

elif [ "$TARGET" = "windows" ]; then
  echo "building for windows"

  export CC="$PWD/muslcc/bin/i686-w64-mingw32-gcc"
  export LDFLAGS=" -static "
  export STRIP="$PWD/muslcc/bin/i686-w64-mingw32-strip"

  export TARGET_LUA="mingw"
  export CFLAGS_LUA=""
  export LDFLAGS_LUA=""

  export TARGET_LUASOCKET="mingw"
  export EXTRA_TARGET_LUASOCKET=""
  export CFLAGS_LUASOCKET=" "

  export CFLAGS_LUACHILD=" -DUSE_WINDOWS " ||die
  export EXTRA_TARGET_LUACHILD=" -c luachild_windows.c -o luachild_windows.o "

  export CFLAGS_PRELOAD=" -DPRELOAD_FOR_WINDOWS "
  export LDFLAGS_PRELOAD=" -lm -lwsock32 -lws2_32 -lpthread "

elif [ "$TARGET" = "mac" ]; then
  echo "building for mac"

  export CC=" gcc "
  export LDFLAGS=" -ldl "

  export TARGET_LUA="macosx"

elif [ "$TARGET" = "arm_linux" ]; then
  echo "building for arm_linux"

  export CC="$PWD/muslcc/bin/arm-linux-musleabihf-gcc"
  export STRIP="$PWD/muslcc/bin/arm-linux-musleabihf-strip"

else
  echo "unknown target '$TARGET'"
  exit -1
fi

cd "$BUILDDIR"/lua ||die
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUA" LDFLAGS="$LDFLAGS $LDFLAGS_LUA" $TARGET_LUA ||die
rm src/lua.o src/luac.o ||die

cd "$BUILDDIR"/luafilesystem ||die
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUAFILESYSTEM" src/lfs.o ||die

cd "$BUILDDIR"/luasocket ||die
if [ "$EXTRA_TARGET_LUASOCKET" != "" ]; then
  cd src
  make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUASOCKET" $EXTRA_TARGET_LUASOCKET ||die
  cd ..
fi
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUASOCKET" $TARGET_LUASOCKET # TODO : check it succeeded
echo "static " > ../socket_lua.c
xxd -i src/socket.lua >> ../socket_lua.c

cd "$BUILDDIR"/luachild ||die
$CC $CFLAGS $CFLAGS_LUACHILD -c luachild_common.c -o luachild_common.o ||die
$CC $CFLAGS $CFLAGS_LUACHILD -c luachild_lua_5_3.c -o luachild_lua_5_3.o ||die
$CC $CFLAGS $CFLAGS_LUACHILD $EXTRA_TARGET_LUACHILD ||die

cd "$BUILDDIR"/luaproc-extended ||die
make CC="$CC" CFLAGS="$CFLAGS $CFLAGS_LUAPROC" src/lpsched.o src/luaproc.o ||die
cd .. ||die


cd "$BUILDDIR"/glua ||die
mv preload.c preload.c.bck
export QUOTED_OPTION="-DENABLE_STANDARD_LUA_CLI=\"../lua/src/lua.c\""
$CC $CFLAGS $CFLAGS_GLUA $QUOTED_OPTION -DBINJECT_ARRAY_SIZE=32768 -DUSE_WHEREAMI -I . -I "../lua-$LUAVER/src/" -c *.c ||die
mv preload.c.bck preload.c ||die

cd "$BUILDDIR" ||die

export QUOTED_OPTION="-DLUA_MAIN_FILE=\"lua/src/lua.c\""
$CC $CFLAGS $CFLAGS_PRELOAD $QUOTED_OPTION -I . -I "lua/src" -I luafilesystem/src -I luasocket/src -I luachild -I luaproc-extended/src -c "$SCRDIR"/preload.c -o ./preload.o ||die
$CC $CFLAGS $CFLAGS_PRELOAD $QUOTED_OPTION -I . -I "lua/src" -I luafilesystem/src -I luasocket/src -I luachild -I luaproc-extended/src -c "$SCRDIR"/lua_patch.c -o ./lua_patch.o ||die

$CC -o lua.exe ./lua_patch.o ./preload.o lua/src/*.o luafilesystem/src/*.o luasocket/src/*.o luachild/*.o luaproc-extended/src/*.o $LDFLAGS $LDFLAGS_PRELOAD ||die
$STRIP lua.exe ||die

$CC -o lua_merge.exe ./preload.o lua/src/*.o luafilesystem/src/*.o luasocket/src/*.o luachild/*.o luaproc-extended/src/*.o glua/*.o $LDFLAGS $LDFLAGS_PRELOAD ||die
$STRIP lua_merge.exe ||die

git_repo_ver(){
  A="$(cd "$1" && git config --get remote.origin.url)"
  B="$(cd "$1" && git rev-parse HEAD)"
  echo "$A $B"
}

VER_STATICBAT="$(git_repo_ver pack)"
A="$(cat lua/src/lua.h|grep -i lua_version_major|head -n 1|sed 's:.*"\(.*\)".*:\1:')"
B="$(cat lua/src/lua.h|grep -i lua_version_minor|head -n 1|sed 's:.*"\(.*\)".*:\1:')"
C="$(cat lua/src/lua.h|grep -i lua_version_release|head -n 1|sed 's:.*"\(.*\)".*:\1:')"
VER_LUA="$A.$B.$C"
VER_MUSLCC="$(ls muslcc/lib/gcc/i686-linux-musl |head -n 1)"
VER_LFS="$(git_repo_ver luafilesystem)"
VER_LSOCKET="$(git_repo_ver luasocket)"
VER_LCHILD="$(git_repo_ver luachild)"
VER_LPROC="$(git_repo_ver luaproc-extended)"
VER_GLUA="$(git_repo_ver glua)"

cp "$SCRDIR"/Readme.deploy.md ./wip ||die
echo "" >> ./wip ||die
echo "Version report" >> ./wip ||die
echo "###############" >> ./wip ||die
echo "" >> ./wip ||die
echo "lua static battery version: $VER_STATICBAT" >> ./wip ||die
echo "muslcc version: $VER_MUSLCC " >> ./wip ||die
echo "lua version: $VER_LUA" >> ./wip ||die
echo "luafilesystem version: $VER_LFS" >> ./wip ||die
echo "luasocket version: $VER_LSOCKET" >> ./wip ||die
echo "luachild version: $VER_LCHILD" >> ./wip ||die
echo "luaproc version: $VER_LPROC" >> ./wip ||die
echo "glua version: $VER_GLUA" >> ./wip ||die
echo >> ./wip ||die
cp ./wip ./Readme.md ||die

mkdir -p deploy
if [ "$TARGET" = "windows" ]; then
  zip -r deploy/lua_static_battery_windows.zip Readme.md lua.exe lua_merge.exe ||die
else
  tar -zcf "deploy/lua_static_battery_$TARGET.tar.gz" Readme.md lua.exe lua_merge.exe ||die
fi
ls -lha deploy

