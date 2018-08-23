local CheckAppRedPacketGroupTask = class("CheckAppRedPacketGroupTask")

local Promise = require("base/Promise")
local Navigator = require("common/Navigator")

local RED_PACKET_GROUP_ACTIVITY_START_TIME = os.time{year=2017, month=12, day=24, hour=0, min=0, sec=0}
local RED_PACKET_GROUP_ACTIVITY_END_TIME = os.time{year=2017, month=12, day=31, hour=23, min=59, sec=59}

local RED_PACKET_GROUP_POPUP_SHOW_FLAG = "RedPacketGroupPopupShowFlag"
local RED_PACKET_GROUP_POPUP_URL = "app_red_packet_group_popup.html"
local RED_PACKET_GROUP_ACTIVITY_URL = "promo_d12_red_group.html?refer_page_sn=10002&refer_page_el_sn=98950"

function CheckAppRedPacketGroupTask.run(resolve)
    print('---------------info:CheckAppRedPacketGroupTask run-----------------------')
    local now = os.time()
    if now < RED_PACKET_GROUP_ACTIVITY_START_TIME or now > RED_PACKET_GROUP_ACTIVITY_END_TIME then
        print("not activity time,now=",now)
        return aimi.call(resolve)
    end

    local showRedPacketGroupFlag = tonumber(aimi.KVStorage.getInstance():get(RED_PACKET_GROUP_POPUP_SHOW_FLAG))
    if showRedPacketGroupFlag == 1 then
        print("red packet group popup has showed")
        return aimi.call(resolve)
    end

    -- check current visible page
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.50.0") and tostring(aimi.Navigator.getVisiblePage()) ~= "pdd_home" then
        return aimi.call(resolve)
    end

    -- 3.41.0版本提供了接口判断网络状态，没有网的时候不需要弹框
    AMBridge.call("AMNetwork", "info", nil, function(error, payload)
        print(type(payload),payload["reachable"])
        if type(payload) ~= "table" or payload["reachable"] == 0 then
            print('---------------error:network unavailability-----------------------')
            return aimi.call(resolve)
        end

        print('---------------will show app red packet group popup-----------------------')
        Promise.new(function(resolve, reject)
            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = RED_PACKET_GROUP_POPUP_URL,
                    ["opaque"] = false,
                    ["extra"] = {
                        ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            if response["confirmed"] == 0 then
                                reject("User cancelled")
                            else
                                resolve(RED_PACKET_GROUP_ACTIVITY_URL)
                            end
                        end,
                    },
                }
            }, function(errorCode)
                if errorCode == 0 then
                    aimi.KVStorage.getInstance():set(RED_PACKET_GROUP_POPUP_SHOW_FLAG, "1")
                else
                    reject("Cannot show red packet group mask")
                end
            end)
        end):next(function(url)
            Navigator.forward(Navigator.getTabIndex(), {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = url,
                },
                ["transient_refer_page_context"] = {
                }
            }, function()
                aimi.call(resolve)
            end)
        end):catch(function()
            aimi.call(resolve)
        end)
    end)
end

return CheckAppRedPacketGroupTask