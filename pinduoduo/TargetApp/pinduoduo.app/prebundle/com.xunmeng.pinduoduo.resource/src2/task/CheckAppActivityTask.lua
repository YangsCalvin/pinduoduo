-- 大促 Native
local CheckAppActivityTask = class("CheckAppActivityTask")

local Promise = require("base/Promise")
local Version = require("base/Version")
local Navigator = require("common/Navigator")
local APIService = require("common/APIService")

local LAST_SHOW_ACTIVITY_DAY_KEY = "LuaLastShowActivityDay"
local rejectForInvalidData = "invalid response popup data"

local function appActivityPopRequest(completed)
    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/carnival/image_list/v2?types[]=popup,popup_button"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        if response ~= nil and response.responseJSON ~= nil then
            local carnivalImages = response.responseJSON["carnival_images"]
            local activityPopUpModel = {}

            for _,value in ipairs(carnivalImages) do
                local imageType = value["type"]
                if imageType == "popup" then
                    activityPopUpModel['pageurl'] = value["page_url"]
                    activityPopUpModel['start_time'] = (value["show_start_time"] / 1000)
                    activityPopUpModel['end_time'] = (value["show_end_time"] / 1000)
                    activityPopUpModel['main_pic'] = value["image_url"]
                    activityPopUpModel['main_pic_width'] = value["width"]
                    activityPopUpModel['main_pic_height'] = value["height"]
                end
                if imageType == "popup_button" then
                    activityPopUpModel['cross_pic'] = value["image_url"]
                    activityPopUpModel['cross_pic_width'] = value["width"]
                    activityPopUpModel['cross_pic_height'] = value["height"]
                end
            end
            local now = os.time()
            if now > activityPopUpModel["start_time"] and now < activityPopUpModel["end_time"] then
                if activityPopUpModel['main_pic_width'] > 0 and
                    activityPopUpModel['main_pic_height'] > 0 and
                    activityPopUpModel['cross_pic_width'] > 0 and
                    activityPopUpModel['cross_pic_height'] > 0 and
                    activityPopUpModel['main_pic'] ~= nil and
                    activityPopUpModel['cross_pic'] ~= nil and
                    activityPopUpModel['pageurl'] ~= nil then
                    completed(activityPopUpModel)
                else
                    reject(rejectForInvalidData)
                end
            else
                reject(rejectForInvalidData)
            end
        else
            reject(rejectForInvalidData)
        end
    end):catch(function(reason)
        completed(nil)
    end)
end



function CheckAppActivityTask.run(resolve)

    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        print('------Activity PDDElasticLayerManager------')
        local openNew = response["value"] 
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            print('------Activity openNew------')
            return aimi.call(resolve)
        else 
            print('------Activity openOld------')
            return CheckAppActivityTask.real(resolve)   
        end
    end)

end

function CheckAppActivityTask.real(resolve)

    local today = os.date("*t", now).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(LAST_SHOW_ACTIVITY_DAY_KEY))
    if today == lastDay then
        print('---------------Activity popup showed Today------------------')
        return aimi.call(resolve)
    end

    local hasPushPageFlag = tonumber(aimi.KVStorage.getInstance():get("LUA_HAS_PUSH_PAGE_FLAG_KEY"))
    if hasPushPageFlag == 1 then
        print('---------------Activity LUA_HAS_PUSH_PAGE_FLAG_KEY-----------------------')
        return aimi.call(resolve)
    end

    -- 3.41.0, check network status
    AMBridge.call("AMNetwork", "info", nil, function(error, payload)

        print(type(payload),payload["reachable"])
        if type(payload) ~= "table" or payload["reachable"] == 0 then
            return aimi.call(resolve)
        end

        appActivityPopRequest(function(popupValue)

            if popupValue == nil then
                return aimi.call(resolve)
            end

            -- check current visible page
            if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.50.0") and tostring(aimi.Navigator.getVisiblePage()) ~= "pdd_home" then
                return aimi.call(resolve)
            end
            Promise.new(function(resolve, reject)
                Navigator.mask({
                    ["type"] = "web",
                    ["props"] = {
                        ["url"] = "app_act_promo_popup.html",
                        ["opaque"] = false,
                        ["extra"] = {
                            --native bridgeCallback
                            ["complete"] = function(errorCode, response)
                                Navigator.dismissMask()
                                if response["confirmed"] == 0 then
                                    reject("User cancelled")
                                else
                                    resolve(popupValue["pageurl"])
                                end
                            end,
                            ["result"] = popupValue
                        },  
                    },
                }, function(errorCode)
                    if errorCode == 0 then
                        aimi.KVStorage.getInstance():set(LAST_SHOW_ACTIVITY_DAY_KEY, tostring(today))
                    else
                        reject("Cannot show mask")
                    end
                end)
            end):next(function(url)
                Navigator.forward(Navigator.getTabIndex(), {
                    ["type"] = "web",
                    ["props"] = {
                        ["url"] = url,
                    },
                    ["transient_refer_page_context"] = {
                        ["page_el_sn"] = "98381"
                    }
                }, function()
                    aimi.call(resolve)
                end)
            end):catch(function()
                aimi.call(resolve)
            end)

        end)

    end)
end

return CheckAppActivityTask
