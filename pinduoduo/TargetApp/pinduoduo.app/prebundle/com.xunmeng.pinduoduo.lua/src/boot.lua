local boot = {}

local meta = {}

local function checkOverseaBadge()
    local lastViewOverseaDayKey = "LastViewOverseaDay"

    AMBridge.call("AMStorage", "get", {
        ["key"] = lastViewOverseaDayKey,
    }, function(error, response)
        local thisDay = os.date("*t", os.time()).day
        local lastDay = tonumber(response["value"])

        if thisDay == lastDay then
            return
        end

        TabBar.setBadgeVisible({ TabBar.Tabs.Oversea }, { true })
    end)
end

local function handleSocketMessage()
    AMBridge.register("PDDReceiveSocketMessage", function(payload)
        if payload == nil then
            return
        end

        if payload["response"] ~= "latest_conversations" or payload["result"] ~= "ok" then
            return
        end

        local conversations = payload["conversations"] or {}
        local hasUnread = false

        for _, conversation in ipairs(conversations) do
            if conversation["status"] ~= "read" then
                hasUnread = true
                break
            end
        end

        TabBar.setBadgeVisible({
            TabBar.Tabs.Personal,
        }, {
            hasUnread,
        })
    end, function()
        AMBridge.call("PDDSocket", "send", {
            ["cmd"] = "latest_conversations",
            ["page"] = 1,
            ["size"] = 20,
        })
    end)
end

local function registerApplicationResume()
    AMBridge.register("onApplicationResume", function()
        checkOverseaBadge()
    end)
end

local function loadMeta()
    AMBridge.call("PDDMeta", "get", nil, function(error, response)
        meta = response
        TabBar.setup(function()
            checkOverseaBadge()
            handleSocketMessage()
            registerApplicationResume()
        end)
    end)
end

function boot.run()
    loadMeta()
end


return boot
