local CheckAssistFreeCouponTask = class("CheckAssistFreeCouponTask")
local Constant = require("common/Constant")

local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Version = require("base/Version")

local LAST_SHOW_ASSIT_FREE_COUPON_KEY = "LuaLastShowAssistFreeCoupon"

function CheckAssistFreeCouponTask.run(resolve)
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken <= 0 then
        return aimi.call(resolve)
    end

    local loginType = tonumber(aimi.KVStorage.getInstance():getSecure(Constant.LoginTypeKey))
    if loginType ~= nil and loginType ~= Constant.LoginTypeWeChat and loginType ~= Constant.LoginTypeQQ then
        return aimi.call(resolve)
    end

    local url = "api/market/assist/group/user/download"
    APIService.getJSON(url):next(function(response)
        local result = response.responseJSON["assist_download_status"]
        return Promise.new(function(resolve, reject)
            if result == nil or result == 0 then
                return reject("No assist")
            end

            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_assist_free_coupon_popup.html",
                    ["opaque"] = false,
                    ["extra"] = {
                        ["result"] = response.responseJSON,
                        ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            local confirmed = response["confirmed"]
                            if response["confirmed"] == 0 then
                                reject("User cancelled")
                            else
                                local forwardURL = "assist_free_coupon.html"
                                resolve(forwardURL)
                            end
                        end,
                    },
                },
            }, function(errorCode)
                if errorCode ~= 0 then
                    reject("Cannot show mask")
                end
            end)
        end)
    end):next(function(forwardURL)
        if forwardURL ~= nil and #forwardURL > 0 then
            Navigator.forward(Navigator.getTabIndex(), {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = forwardURL,
                },
            }, function()
                aimi.call(resolve)
            end)
        end
    end):catch(function()
        aimi.call(resolve)
    end)
end

function CheckAssistFreeCouponTask.reset()
end

return CheckAssistFreeCouponTask