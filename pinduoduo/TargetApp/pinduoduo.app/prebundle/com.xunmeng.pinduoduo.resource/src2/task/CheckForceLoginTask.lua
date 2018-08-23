-- 强制登录
local CheckForceLoginTask = class("CheckForceLoginTask")
local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Promise = require("base/Promise")
local Version = require("base/Version")

local HAS_SHOW_FORCE_LOGIN_FLAG_KEY = "HAS_SHOW_FORCE_LOGIN_FLAG_KEY"
local USER_LOGIN_CHANNEL_FLAG_KEY = "USER_LOGIN_CHANNEL_FLAG_KEY"

function CheckForceLoginTask.run(resolve)

    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        local openNew = response["value"] 
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            return aimi.call(resolve)
        else 
            return CheckForceLoginTask.real(resolve)   
        end
    end)

end

function CheckForceLoginTask.real(resolve)

	local accessToken = aimi.User.getAccessToken()
    if accessToken ~= nil and #accessToken > 0 then
        return aimi.call(resolve)
    end

	local hasShowForceLoginSn = aimi.KVStorage.getInstance():get(HAS_SHOW_FORCE_LOGIN_FLAG_KEY)
    if hasShowForceLoginSn == "1" then
        return aimi.call(resolve)
    end

    local url = "api/market/pelican/activity/login/query"
    APIService.getJSON(url):next(function(response)
        local needsLogin = response.responseJSON["result"]
        local loginChannel = response.responseJSON["login_channel"];
        if loginChannel ~= nil then 
            aimi.KVStorage.getInstance():set(USER_LOGIN_CHANNEL_FLAG_KEY, tostring(loginChannel))
        end

        return Promise.new(function(resolve, reject)
        	if not needsLogin then
        		reject("not need force login")
    		end

	        if needsLogin then
	            Navigator.modal({
	                ["type"] = "login",
	                ["props"] = {
                        ["force_wechat_login"] = "1",
	                    ["complete"] = function(errorCode, response)
	                        resolve(response)
	                    end
	                }
	            }, function(errorCode)
	                if errorCode == 0 then
		                aimi.KVStorage.getInstance():set(HAS_SHOW_FORCE_LOGIN_FLAG_KEY, tostring(1))
	                else
	                    reject("Cannot model loginViewController")
	                end
	            end)
	        end
        end)
    end):next(function(response)
        if response ~= nil and response["access_token"] ~= nil then
            aimi.call(resolve)
        else
            aimi.call(resolve)
        end
    end):catch(function()
        aimi.call(resolve)
    end)
end

return CheckForceLoginTask