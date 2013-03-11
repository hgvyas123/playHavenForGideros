/*
 
 (C) 2013 Harshit Vyas (hgvyas123)
 
 */

#include "gideros.h"
#include "lua.h"
#include "lauxlib.h"
#import "PlayHavenSDK.h"

// some Lua helper functions
#ifndef abs_index
#define abs_index(L, i) ((i) > 0 || (i) <= LUA_REGISTRYINDEX ? (i) : lua_gettop(L) + (i) + 1)
#endif

static void luaL_newweaktable(lua_State *L, const char *mode)
{
	lua_newtable(L);			// create table for instance list
	lua_pushstring(L, mode);
	lua_setfield(L, -2, "__mode");	  // set as weak-value table
	lua_pushvalue(L, -1);             // duplicate table
	lua_setmetatable(L, -2);          // set itself as metatable
}

static void luaL_rawgetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_rawget(L, idx);
}

static void luaL_rawsetptr(lua_State *L, int idx, void *ptr)
{
	idx = abs_index(L, idx);
	lua_pushlightuserdata(L, ptr);
	lua_insert(L, -2);
	lua_rawset(L, idx);
}

static char keyWeak = ' ';

class GPlayHavenPlugin : public GEventDispatcherProxy
{
    public:
        GPlayHavenPlugin(lua_State *L) : L(L)
        {}
    
        ~GPlayHavenPlugin()
        {}
    
        void showInterStitial(const char* Token,const char* Secret, const char* Placement)
        {
            NSString *myToken = [NSString stringWithUTF8String:Token];
            NSString *mySecret = [NSString stringWithUTF8String:Secret];
            NSString *myPlacement = [NSString stringWithUTF8String:Placement];

            PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:myToken secret:mySecret placement:myPlacement delegate:nil];
            
            /* PHPublisherContentRequest *request = [PHPublisherContentRequest requestForApp:(NSString *)token secret:(NSString *)secret placement:(NSString *)placement delegate:(id)delegate];
             */
            request.showsOverlayImmediately = YES; //optional, see next.
            [request send];
        }
    
    private:
        lua_State *L;
};

static int destruct(lua_State* L)
{
	void *ptr =*(void**)lua_touserdata(L, 1);
	GReferenced* object = static_cast<GReferenced*>(ptr);
	GPlayHavenPlugin *instance = static_cast<GPlayHavenPlugin*>(object->proxy());
	instance->unref();
    
	return 0;
}

static int showInterStitial(lua_State *L)
{
	GReferenced *object = static_cast<GReferenced*>(g_getInstance(L, "playHaven", 1));
	GPlayHavenPlugin *instance = static_cast<GPlayHavenPlugin*>(object->proxy());
	
	const char *Token = lua_tostring(L, 2);
    const char *Secret = lua_tostring(L, 3);
    const char *Placement = lua_tostring(L, 4);
	
	instance->showInterStitial(Token,Secret,Placement);
	
	return 0;
}


static int loader(lua_State *L)
{
    
	const luaL_Reg functionList[] = {
		{"showInterStitial", showInterStitial},
		{NULL, NULL}
	};
    
    g_createClass(L, "playHaven", "EventDispatcher", NULL, destruct, functionList);
    
    // create a weak table in LUA_REGISTRYINDEX that can be accessed with the address of keyWeak
	luaL_newweaktable(L, "v");
	luaL_rawsetptr(L, LUA_REGISTRYINDEX, &keyWeak);
    
    GPlayHavenPlugin *instance = new GPlayHavenPlugin(L);
	g_pushInstance(L, "playHaven", instance->object());
    
	luaL_rawgetptr(L, LUA_REGISTRYINDEX, &keyWeak);
	lua_pushvalue(L, -2);
	luaL_rawsetptr(L, -2, instance);
	lua_pop(L, 1);
    
	lua_pushvalue(L, -1);
	lua_setglobal(L, "playHaven");
     return 1;
}

static void g_initializePlugin(lua_State *L)
{
    lua_getglobal(L, "package");
	lua_getfield(L, -1, "preload");
    
	lua_pushcfunction(L, loader);
	lua_setfield(L, -2, "playHaven");
    
	lua_pop(L, 2);
}

static void g_deinitializePlugin(lua_State *L)
{
    
}

REGISTER_PLUGIN("playHaven", "1")
