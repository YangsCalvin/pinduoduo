local CheckMarketActivityTask = class("CheckMarketActivityTask")
local Constant = require("common/Constant")

local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Version = require("base/Version")

local LAST_SHOW_RED_PACKET_SN_KEY = "LuaLastShowRedPacketSN"

function CheckMarketActivityTask.run(resolve)
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken <= 0 then
        return aimi.call(resolve)
    end

    local loginType = tonumber(aimi.KVStorage.getInstance():getSecure(Constant.LoginTypeKey))
    if loginType ~= nil and loginType ~= Constant.LoginTypeWeChat then
        return aimi.call(resolve)
    end

    local url = "api/market/mononoke/buddy/rp/pop"
    APIService.getJSON(url):next(function(response)
        local redPacketSN = response.responseJSON["red_packet_sn"]

        return Promise.new(function(resolve, reject)
            if redPacketSN == nil or #redPacketSN <= 0 then
                return reject("No red packet")
            end

            local lastReadPacketSN = aimi.KVStorage.getInstance():get(LAST_SHOW_RED_PACKET_SN_KEY)
            if tostring(lastReadPacketSN) == tostring(redPacketSN) then
                return reject("Red packet sn has showed, will not show again, red packet sn=", redPacketSN)
            end

            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_red_packet_popup.html",
                    ["opaque"] = false,
                    ["extra"] = {
                        ["result"] = response.responseJSON,
                        ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            local confirmed = response["confirmed"]
                            if response["confirmed"] == 0 then
                                reject("User cancelled")
                            else
                                local forwardURL = "coupons.html"
                                resolve(forwardURL)
                            end
                        end,
                    },
                },
            }, function(errorCode)
                if errorCode == 0 then
                    aimi.KVStorage.getInstance():set(LAST_SHOW_RED_PACKET_SN_KEY, tostring(redPacketSN))
                else
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

function CheckMarketActivityTask.reset()
    aimi.KVStorage.getInstance():set(LAST_SHOW_RED_PACKET_SN_KEY, nil)
end

return CheckMarketActivityTask