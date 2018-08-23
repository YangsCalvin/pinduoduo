local AppManager = class("AppManager")

local Promise = require("base/Promise")
local Version = require("base/Version")
local Event = require("common/Event")
local APIService = require("common/APIService")
local ComponentManager = require("common/ComponentManager")
local Config = require("common/Config")

local LAST_DETECT_APP_MANAGER_KEY = "LuaLastDetectAppManager"

function AppManager.initialize(resolve, reject)
    AppManager.detectInstalledApps()

    Promise.all():next(resolve, reject)
end

function AppManager.detectInstalledApps()
    local today = os.date("*t", now).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(LAST_DETECT_APP_MANAGER_KEY))
    if today == lastDay then
        return
    end

    local apps = {"taobao", "openApp.jdMobile", "vipshop", "snssdk141", "weibo"}
    AMBridge.call("AMApplication", "detect", {
        ["apps"] = apps,
    }, function(error, response)
        print("error=",error,"response=",response)
        if error ~= nil and type(response) ~= "table" then
            return
        end

        local result = response["installed"]
        if type(result) ~= "table" then
            return
        end

        Promise.new(function(resolve, reject)
            return APIService.postJSON("api/durin/apps/info_rpt", {
                ["info_type"] = 0,
                ["info"] = {
                    ["apps"] = result,
                    ["os_version"] = aimi.Device.getSystemVersion(),
                    ["app_version"] = aimi.Application.getApplicationVersion(),
                    ["model"] = aimi.Device.getModel(),
                    ["platform"] = "iOS",
                    ["user_id"] = aimi.User.getUserID()
                }
            }):next(function(response)
                aimi.KVStorage.getInstance():set(LAST_DETECT_APP_MANAGER_KEY, tostring(today))
                resolve(response)
            end):catch(function(reason)
                aimi.KVStorage.getInstance():set(LAST_DETECT_APP_MANAGER_KEY, tostring(today))
                reject(reason)
            end)
        end)
    end)
end

return AppManager