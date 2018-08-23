local GoodsConfig = class("GoodsConfig")
local Version = require("base/Version")
local Promise = require("base/Promise")

function GoodsConfig.initialize(resolve, reject)
	GoodsConfig.updateConfig("")
	Promise.all():next(resolve, reject)
end

function GoodsConfig.updateConfig(config)
	if config == nil then
		return
	end

    AMBridge.call("PDDGoodsDetailConfig", "update", {
        ["unsupportedTypes"] = config
        }, function(errorCode, response)
    end)
end

return GoodsConfig