-- 优惠券 H5
local CheckCashCouponTask = class("CheckCashCouponTask")
local Constant = require("common/Constant")

local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Version = require("base/Version")

local LAST_SHOW_CASH_COUPON_KEY = "LuaLastShowCashCoupon"

function CheckCashCouponTask.run(resolve)

    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        local openNew = response["value"] 
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            return aimi.call(resolve)
        else 
            return CheckCashCouponTask.real(resolve)   
        end
    end)

end

function CheckCashCouponTask.real(resolve)

    AMBridge.call("PDDAppConfig","getConfiguration",{["key"]=Constant.PDD_popup_window_switch,["def"]="1",}, function(errorCode, response)
        local openNew = response["value"] 
        if openNew == "1" then
            if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0") then
                return aimi.call(resolve)
            end
        end
    end)

    print('---------------info:CheckCashCouponTask run-----------------------')
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken <= 0 then
        return aimi.call(resolve)
    end

    local today = os.date("*t", os.time()).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(LAST_SHOW_CASH_COUPON_KEY))

    if today == lastDay then
        return aimi.call(resolve)
    end

    -- check current visible page
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.50.0") and tostring(aimi.Navigator.getVisiblePage()) ~= "pdd_home" then
        return aimi.call(resolve)
    end

    local url = "api/lisbon/query_cash_coupon"
    APIService.getJSON(url):next(function(response)
        local discount = response.responseJSON["discount"]
        local couponID = response.responseJSON["coupon_id"]

        return Promise.new(function(resolve, reject)
            if type(discount) ~= "number" or discount <= 0 then
                return reject("No cash coupon")
            end

            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_cash_coupon_popup.html?_x_src=homepop&_x_platform=ios",
                    ["opaque"] = false,
                    ["extra"] = {
                        ["result"] = response.responseJSON,
                        ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            local confirmed = response["confirmed"]
                            if response["confirmed"] == 0 then
                                reject("User cancelled")
                            else
                                local forwardURL = "coupon_newbee.html?coupon_id=" .. tostring(couponID) .. "&_x_src=homepop&_x_platform=ios"
                                resolve(forwardURL)
                            end
                        end,
                    },
                },
            }, function(errorCode)
                if errorCode == 0 then
                    aimi.KVStorage.getInstance():set(LAST_SHOW_CASH_COUPON_KEY, tostring(today))
                else
                    reject("Cannot show mask")
                end
            end)
        end)
    end):next(function(forwardURL)
        if forwardURL ~= nil and #forwardURL > 0 then
            Navigator.forward(Navigator.getTabIndex(), {
                ["is_push"] = 1,
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

function CheckCashCouponTask.reset()
    aimi.KVStorage.getInstance():set(LAST_SHOW_CASH_COUPON_KEY, nil)
end

return CheckCashCouponTask
