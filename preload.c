
#include "lua.h"
#include "lauxlib.h"

#include "build/socket_lua.c"

void luaL_openlibs(lua_State *L);
int luaopen_lfs(lua_State *L);
#ifndef PRELOAD_FOR_WINDOWS
int luaopen_socket_serial(lua_State *L);
int luaopen_mime_core(lua_State *L);
int luaopen_socket_unix(lua_State *L);
#endif // PRELOAD_FOR_WINDOWS
int luaopen_socket_core(lua_State *L);
int luaopen_luachild(lua_State *L);
int luaopen_luaproc(lua_State *L);

static int loader_lua_socket(lua_State *L){
  int args = lua_gettop(L);
  if (LUA_OK != luaL_loadbuffer(L,
    src_socket_lua, sizeof(src_socket_lua)/sizeof(*src_socket_lua),
    "(=socket=loader=)"))
    return 0;
  lua_insert(L, 1); // put the loaded buffer at base of the stack, ready for a call
  lua_call(L, args, 1);
  return 1;
}

static void preload_lua_library(lua_State* L){
  luaL_openlibs(L);  /* open standard libraries */

  luaL_getsubtable(L, LUA_REGISTRYINDEX, LUA_PRELOAD_TABLE);

  lua_pushcfunction(L, luaopen_lfs); lua_setfield(L, -2, "lfs");
#ifndef PRELOAD_FOR_WINDOWS
  lua_pushcfunction(L, luaopen_mime_core); lua_setfield(L, -2, "mime.core");
  lua_pushcfunction(L, luaopen_socket_serial); lua_setfield(L, -2, "socket.serial");
  lua_pushcfunction(L, luaopen_socket_unix); lua_setfield(L, -2, "socket.unix");
#endif // PRELOAD_FOR_WINDOWS
  lua_pushcfunction(L, luaopen_socket_core); lua_setfield(L, -2, "socket.core");
  lua_pushcfunction(L, loader_lua_socket); lua_setfield(L, -2, "socket");
  lua_pushcfunction(L, luaopen_luachild); lua_setfield(L, -2, "luachild");
  lua_pushcfunction(L, luaopen_luaproc); lua_setfield(L, -2, "luaproc");

  lua_pop(L, 1);
}

#define luaL_openlibs(L) preload_lua_library(L)
#include LUA_MAIN_FILE

