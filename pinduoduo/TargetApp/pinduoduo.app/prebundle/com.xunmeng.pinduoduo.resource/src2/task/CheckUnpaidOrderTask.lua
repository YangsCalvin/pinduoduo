-- 未支付 H5
local CheckUnpaidOrderTask = class("CheckUnpaidOrderTask")

local Promise = require("base/Promise")
local Version = require("base/Version")

local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Tracking = require("common/Tracking")
local ComponentManager = require("common/ComponentManager")
local Config = require("common/Config")
local Constant = require("common/Constant")

local LAST_SHOW_UNPAID_ORDER_DAY_KEY = "LuaLastShowUnpaidOrderDay"

function CheckUnpaidOrderTask.run(resolve)

    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        local openNew = response["value"] 
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            return aimi.call(resolve)
        else 
            return CheckUnpaidOrderTask.real(resolve)   
        end
    end)

end

function CheckUnpaidOrderTask.real(resolve)

    print('---------------info:CheckUnpaidOrderTask run-----------------------')
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken <= 0 then
        return aimi.call(resolve)
    end

    local today = os.date("*t", os.time()).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(LAST_SHOW_UNPAID_ORDER_DAY_KEY))

    if today == lastDay then
        return aimi.call(resolve)
    end

    -- check current visible page
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.50.0") and tostring(aimi.Navigator.getVisiblePage()) ~= "pdd_home" then
        return aimi.call(resolve)
    end

    local function checkUnpaidOrders()
        APIService.getJSON("ordersv2/unpaid?size=1&page=1"):next(function(response)
            local orders = response.responseJSON["orders"]

            return Promise.new(function(resolve, reject)
                if orders == nil or #orders <= 0 then
                    return reject("No unpaid order")
                end

                local latestOrder = orders[1]
                local latestOrderGoodsList = latestOrder["order_goods"]
                if latestOrderGoodsList == nil or #latestOrderGoodsList <= 0 then
                    return reject("No unpaid order goods")
                end

                local goods = latestOrderGoodsList[1]
                Navigator.mask({
                    ["type"] = "web",
                    ["props"] = {
                        ["url"] = "app_unpayed_alarm.html?_x_src=homepop&_x_platform=ios",
                        ["opaque"] = false,
                        ["extra"] = {
                            ["goods"] = goods,
                            ["complete"] = function(errorCode, response)
                                Navigator.dismissMask()
                                if response["confirmed"] ~= 0 then
                                    resolve()
                                     Tracking.send("click", "pay_btn_click", {
                                        ["page_name"] = "index",
                                        ["page_sn"] = "10002",
                                        ["page_section"] = "popup",
                                        ["page_element"] = "pay_btn",
                                        ["goods_id"] = goods["goods_id"]
                                    })
                                else
                                    TabBar.setBadgeVisible({
                                        TabBar.Tabs.Personal,
                                    }, {
                                        true,
                                    })

                                     Tracking.send("click", "knowed_btn_click", {
                                        ["page_name"] = "index",
                                        ["page_sn"] = "10002",
                                        ["page_section"] = "popup",
                                        ["page_element"] = "knowed_btn",
                                        ["goods_id"] = goods["goods_id"]
                                    })
                                end
                            end,
                        },
                    },
                }, function(errorCode)
                    if errorCode == 0 then
                        aimi.KVStorage.getInstance():set(LAST_SHOW_UNPAID_ORDER_DAY_KEY, tostring(today))
                    else
                        reject("Cannot show mask")
                    end
                end)
            end)
        end):next(function()
            Navigator.forward(Navigator.getTabIndex(), {
                ["type"] = ("web" and Version.new(aimi.Application.getApplicationVersion()) < Version.new("2.14.0")) or "pdd_orders",
                ["props"] = {
                    ["type"] = 1,
                    ["url"] = "orders.html?type=1&refer_page_name=index&refer_page_element=index_popup&_x_src=homepop&_x_platform=ios"
                },
                ["transient_refer_page_context"] = {
                    ["page_name"] = "index",
                    ["page_sn"] = "10002",
                    ["page_section"] = "popup",
                    ["page_element"] = "pay_btn",
                },
                ["push_passthrough"] = {
                    ["_x_src"] = "homepop",
                    ["_x_platform"] = "ios"
                },
                ["is_push"] = 1
            }, function()
                aimi.call(resolve)
            end)
        end):catch(function()
            aimi.call(resolve)
        end)
    end

    AMBridge.call("PDDABTest", "check", {
        ["name"] = "pdd_unpay_pop"
    }, function(error, response)
        if response and response["is_enabled"] == 1 then
            checkUnpaidOrders()
        end
    end)

    aimi.call(resolve)
end

function CheckUnpaidOrderTask.reset()
    aimi.KVStorage.getInstance():set(LAST_SHOW_UNPAID_ORDER_DAY_KEY, nil)
end

return CheckUnpaidOrderTask