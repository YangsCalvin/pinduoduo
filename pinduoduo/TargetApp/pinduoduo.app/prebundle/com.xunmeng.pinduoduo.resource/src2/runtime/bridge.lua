AMBridge = AMBridge or {}


local handleSeed = 0
local eventNamesByHandle = {}
local eventHandlers = {}


function AMBridge.message(name, payload)
    if eventHandlers[name] == nil then
        return
    end

    for _, handler in pairs(eventHandlers[name]) do
        handler(payload)
    end
end

function AMBridge.register(name, handler, onComplete)
    local function complete()
        if onComplete ~= nil then
            onComplete()
        end
    end

    if name == nil or #name <= 0 or handler == nil then
        return complete()
    end

    local handle = handleSeed + 1

    handleSeed = handleSeed + 1

    local function registerMessageHandler()
        eventHandlers[name][handle] = handler
        eventNamesByHandle[handle] = name
        complete()
    end

    if eventHandlers[name] == nil then
        eventHandlers[name] = {}
        AMBridge.call("AMNotification", "register", {
            ["name"] = name,
        }, function()
            registerMessageHandler()
        end)
    else
        registerMessageHandler()
    end

    return handle
end

function AMBridge.unregister(handle)
    local name = eventNamesByHandle[handle]

    if eventHandlers[name] == nil then
        return
    end

    eventHandlers[name][handle] = nil
    eventNamesByHandle[handle] = nil

    local count = 0

    for _ in pairs(eventHandlers[name]) do
        count = count + 1
    end

    if count <= 0 then
        eventHandlers[name] = nil
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
