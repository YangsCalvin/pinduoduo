AMBridge = AMBridge or {}


local handleSeed = 0
local namesByHandle = {}
local callbacks = {}


function AMBridge.message(name, payload)
    if callbacks[name] == nil then
        return
    end

    for _, callback in pairs(callbacks[name]) do
        callback(payload)
    end
end

function AMBridge.register(name, callback, onComplete)
    local function complete()
        if onComplete ~= nil then
            onComplete()
        end
    end

    if name == nil or #name <= 0 or callback == nil then
        return complete()
    end

    local handle = handleSeed + 1

    handleSeed = handleSeed + 1

    local function registerCallback()
        callbacks[name][handle] = callback
        namesByHandle[handle] = name
        complete()
    end

    if callbacks[name] == nil then
        callbacks[name] = {}
        AMBridge.call("AMNotification", "register", {
            ["name"] = name,
        }, function()
            registerCallback()
        end)
    else
        registerCallback()
    end

    return handle
end

function AMBridge.unregister(handle)
    local name = namesByHandle[handle]

    if callbacks[name] == nil then
        return
    end

    callbacks[name][handle] = nil
    namesByHandle[handle] = nil

    local count = 0

    for _ in pairs(callbacks[name]) do
        count = count + 1
    end

    if count <= 0 then
        callbacks[name] = nil
        AMBridge.call("AMNotification", "unregister", {
            ["name"] = name,
        })
    end
end

function AMBridge.send(name, payload)
    AMBridge.call("AMNotification", "send", {
        ["name"] = name,
        ["payload"] = payload,
    })
end

return AMBridge
