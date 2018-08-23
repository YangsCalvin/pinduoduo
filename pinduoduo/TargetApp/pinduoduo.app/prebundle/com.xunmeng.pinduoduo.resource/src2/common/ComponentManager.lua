local ComponentManager = class("ComponentManager")

local Promise = require("base/Promise")
local Version = require("base/Version")

local Event = require("common/Event")


local COMPONENT_NAME_KEY = "name"
local COMPONENT_VERSION_KEY = "version"

local COMPONENT_PROTOCOL = "amcomponent"


ComponentManager.WebComponentName =
    Env and Env.AM_PREBUNDLE_WEB_NAME or "com.xunmeng.pinduoduo"
ComponentManager.BootComponentName =
    Env and Env.AM_PREBUNDLE_BOOT_NAME or "com.xunmeng.pinduoduo.lua"
ComponentManager.LuaComponentName =
    Env and Env.AM_PREBUNDLE_LUA_NAME or "com.xunmeng.pinduoduo.resource"
ComponentManager.MobileGroupComponentName =
    Env and Env.AM_PREBUNDLE_MOBILE_GROUP_NAME or "com.xunmeng.pinduoduo.mobile-group"
ComponentManager.MarketComponentName =
    Env and Env.AM_PREBUNDLE_MOBILE_MARKET_NAME or "com.xunmeng.pinduoduo.market"
ComponentManager.PersonalComponentName = 
    Env and Env.AM_PREBUNDLE_MOBILE_PERSONAL_NAME or "com.xunmeng.pinduoduo.personal"


function ComponentManager.initialize(resolve, reject)
    ComponentManager.initializeComponents()

    AMBridge.register(Event.ComponentUpdated, function(payload)
        print('component updated name=',payload["component_name"])
        ComponentManager.updateComponent(payload["component_name"])
    end)

    local tasks = {}

    for name, _ in pairs(ComponentManager.Components) do
        table.insert(tasks, ComponentManager.updateComponent(name))
    end

    Promise.all(tasks):next(resolve, reject)
end

function ComponentManager.getComponentVersion(name)
    if ComponentManager.Components == nil then
        return nil
    end

    local component = ComponentManager.Components[name]

    if component == nil then
        return Version.new()
    end

    return component[COMPONENT_VERSION_KEY]
end

function ComponentManager.getComponentHost(name)
    return COMPONENT_PROTOCOL .. "://" .. tostring(name) .. "/"
end


function ComponentManager.initializeComponents()
    local function addComponent(name)
        local component = {}

        component[COMPONENT_NAME_KEY] = name
        component[COMPONENT_VERSION_KEY] = Version.new()
        ComponentManager.Components[name] = component
    end

    ComponentManager.Components = {}
    addComponent(ComponentManager.WebComponentName)
    addComponent(ComponentManager.BootComponentName)
    addComponent(ComponentManager.LuaComponentName)
    addComponent(ComponentManager.MobileGroupComponentName)
    addComponent(ComponentManager.MarketComponentName)
    addComponent(ComponentManager.PersonalComponentName)
end

function ComponentManager.updateComponent(name)
    local component = ComponentManager.Components[name]

    if component == nil then
        print("---------------Lua error: component name=",name)
        return
    end

    return Promise.new(function(resolve, reject)
        AMBridge.call("AMComponent", "info", {
            ["name"] = name,
        }, function(errorCode, response)
            local bundles = response["bundles"]
            local bundle = bundles[#bundles]

            if bundle ~= nil then
                component[COMPONENT_VERSION_KEY] = Version.new(bundle["version"])
            end

            resolve()
        end)
    end)
end

function ComponentManager.isFileExist(name, path)
    local filePath = debug.getinfo(2, "S").source:sub(2)
    local componentsPath = filePath:match("(.*/Components/)")
    local destFilePath = componentsPath .. name .. "/" .. path

    local file, msg = io.open(destFilePath, "r")
    if file == nil then
        print("error:", msg)
        return false
    end

    io.close(file)
    return true
end

function ComponentManager.getFileContent(name, path)
    local filePath = debug.getinfo(2, "S").source:sub(2)
    local componentsPath = filePath:match("(.*/Components/)")
    local destFilePath = componentsPath .. name .. "/" .. path

    local file, msg = io.open(destFilePath, "r")
    if file == nil then
        print("error:", msg)
        return
    end

    local fileContent = file:read("*all")
    io.close(file)
    return fileContent
end

return ComponentManager