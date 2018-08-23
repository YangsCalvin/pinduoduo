-- 更新 H5
local CheckAppUpdateTask = class("CheckAppUpdateTask")

local Version = require("base/Version")

local Navigator = require("common/Navigator")
local Constant = require("common/Constant")
local CIUpgradeEnable = Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.9.0")

function CheckAppUpdateTask.run(resolve)

    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        print('------App update Task------')
        local openNew = response["value"] 
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            print('------App update Task new------')
            return aimi.call(resolve)
        else 
            print('------App update Task old------')
            return CheckAppUpdateTask.real(resolve)   
        end
    end)

end

function CheckAppUpdateTask.real(resolve)

    if CIUpgradeEnable ~= true then
        return CheckAppUpdateTask.oldUpgrade(resolve)
    end
    AMBridge.call("PDDAppConfig","getConfiguration",{["key"]=Constant.PDD_CI_Upgrade,["def"]="false",}, function(errorCode, response)
        local ciupgrade = response["value"] 
        if ciupgrade == "true" then
            AMBridge.call("PDDMeta","checkUpgrade",nil, function(errorCode, response)
                                                        return aimi.call(resolve)
                        end)
        else
            CheckAppUpdateTask.oldUpgrade(resolve)
        end
    end)
end

function CheckAppUpdateTask.oldUpgrade(resolve)
    local lastPromptUpdateDayKey = "LuaLastPromptUpdateDay"
    local today = os.date("*t", os.time()).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(lastPromptUpdateDayKey))

    if lastDay == today then
        return aimi.call(resolve)
    end

    AMBridge.call("PDDMeta", "get", nil, function(errorCode, response)
        local currentVersion = Version.new(response["cur_version"])

        if Version.new(aimi.Application.getApplicationVersion()) >= currentVersion then
            return aimi.call(resolve)
        end

        aimi.KVStorage.getInstance():set(lastPromptUpdateDayKey, tostring(today))
         Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_update.html",
                    ["opaque"] = false,
                    ["extra"] = {
                         ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            aimi.call(resolve)

                            if response["confirmed"] ~= 0 then
                                AMBridge.call("AMLinking", "openURL", {
                                    ["url"] = "itms-apps://itunes.apple.com/us/app/apple-store/id1044283059"
                                })
                            end
                        end,
                        },
                },
         }, function(errorCode)
                if errorCode ~= 0 then
                    aimi.call(resolve)
                end
            end)
    end)
end


return CheckAppUpdateTask