local CheckFreeCouponsTask = class("CheckFreeCouponsTask")

local Promise = require("base/Promise")

local APIService = require("common/APIService")
local Navigator = require("common/Navigator")

local LAST_SHOW_FREE_COUPONS_DAY_KEY = "LuaLastShowFreeCouponsDay"

function CheckFreeCouponsTask.run(resolve)
    local accessToken = aimi.User.getAccessToken()

    if accessToken == nil or #accessToken <= 0 then
        return aimi.call(resolve)
    end

    local today = os.date("*t", os.time()).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(LAST_SHOW_FREE_COUPONS_DAY_KEY))

    if today == lastDay then
        return aimi.call(resolve)
    end

    local futureTime = os.time() + 7*24*60*60
    local url = "coupon/v2/query_validity_coupons?page=1&size=10&fc_version=1.0&sort_rule=coupon_end_time&coupon_endtime_before=" .. futureTime
    APIService.getJSON(url):next(function(response)
        local infos = response.responseJSON["coupons"]
        local totalSize = response.responseJSON["total_size"]

        return Promise.new(function(resolve, reject)
            if infos == nil or #infos <= 0 then
                return reject("No free coupon")
            end

            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_coupon_popup.html",
                    ["opaque"] = false,
                    ["extra"] = {
                        ["list"] = infos,
                        ["total_size"] = totalSize,
                        ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            resolve(response)
                        end,
                    },
                },
            }, function(errorCode)
                if errorCode == 0 then
                    aimi.KVStorage.getInstance():set(LAST_SHOW_FREE_COUPONS_DAY_KEY, tostring(today))
                else
                    reject("Cannot show mask")
                end
            end)
        end)
    end):next(function(response)
        if response ~= nil then
            Navigator.forward(Navigator.getTabIndex(), response, function()
                aimi.call(resolve)
            end)
        else
            aimi.call(resolve)
        end
    end):catch(function()
        aimi.call(resolve)
    end)
end

function CheckFreeCouponsTask.reset()
    aimi.KVStorage.getInstance():set(LAST_SHOW_FREE_COUPONS_DAY_KEY, nil)
end


return CheckFreeCouponsTask