aimi = aimi or {}


local appVersion
local systemVersion

function aimi.appVersion()
    if appVersion == nil then
        appVersion = Version.new(aimi.meta["version"])
    end

    return appVersion
end

function aimi.systemVersion()
    if systemVersion == nil then
        systemVersion = Version.new(aimi.meta["system_version"])
    end

    return systemVersion
end

function aimi.createScene(props, tabIndex, contextID)
    if props == nil then
        return
    end

    local name = props["lua_scene"]

    if name == nil then
        return
    end

    return require("scene/" .. name).new(props, tabIndex, contextID)
end


return aimi
