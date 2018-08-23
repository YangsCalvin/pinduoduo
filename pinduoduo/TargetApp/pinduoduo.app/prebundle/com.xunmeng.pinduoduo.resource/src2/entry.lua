local CURRENT_LUA_RESOURCE_VERSION = ""

function AMBridge.error(message)
    local traceback = debug.traceback("", 2)

    print("----------------------------------------")
    print("Lua Error: " .. tostring(message))
    print(traceback)
    print("----------------------------------------")

    local ComponentManager = require("common/ComponentManager")
    local Tracking = require("common/Tracking")
    local version = ComponentManager.getComponentVersion(ComponentManager.LuaComponentName)

    xpcall(function()
        local loadedPackages = "package.loaded:";
        for key, value in pairs(package.loaded) do
            loadedPackages = loadedPackages ..tostring(key) .. "," .. type(value) .. "|"
        end

        local version = ComponentManager.getComponentVersion(ComponentManager.LuaComponentName)
        Tracking.send("lua_error", "", {
            ["error"] = tostring(message),
            ["traceback"] = tostring(traceback),
            ["version"] = tostring(version),
            ["lua_package_loaded"] = loadedPackages,
            ["current_lua_resource_version"] = CURRENT_LUA_RESOURCE_VERSION
        })
    end, AMBridge.error)
end

local function updatePath(callback)
    local componentName = Env and Env.AM_PREBUNDLE_LUA_NAME or "com.xunmeng.pinduoduo.resource"
    AMBridge.call("AMComponent", "info", {
        ["name"] = componentName,
    }, function(error, response)
        local pattern = "/src2/?.lua"
        local bundles = response["bundles"]
        local searchPaths = {}
        local mark = {}

        for i = #bundles, 1, -1 do
            local bundle = bundles[i] or {}
            local path = bundle["local_path"]

            if i == #bundles then
                CURRENT_LUA_RESOURCE_VERSION = bundle["version"]
            end

            if path ~= nil and not mark[path] then
                mark[path] = true
                table.insert(searchPaths, path .. pattern)
            end
        end

        package.path = table.concat(searchPaths, ";")

        if callback ~= nil then
            callback()
        end
    end)
end

local function boot()
    updatePath(function()
        require("runtime/runtime")
        require("Application")

        Application.run()

        AMBridge.send("PDDLuaResourceLoadedNotification", nil);

    end)
end

boot()