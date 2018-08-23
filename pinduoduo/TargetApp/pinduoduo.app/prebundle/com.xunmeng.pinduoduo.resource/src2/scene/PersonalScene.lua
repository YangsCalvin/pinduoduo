local PersonalScene = class("PersonalScene")
local Event = require("common/Event")

function PersonalScene.setup()
    PersonalScene.configLottery()
    PersonalScene.registerEvents()
end

function PersonalScene.configLottery()
    AMBridge.call("PersonalScene", "configLottery", {
        ["hide_lottery"] = 1,
    })
end

function PersonalScene.registerEvents()
    AMBridge.register(Event.UserLogin, function()
        PersonalScene.configLottery()
    end)

    AMBridge.register(Event.UserLogout, function()
        PersonalScene.configLottery()
    end)
end

return PersonalScene