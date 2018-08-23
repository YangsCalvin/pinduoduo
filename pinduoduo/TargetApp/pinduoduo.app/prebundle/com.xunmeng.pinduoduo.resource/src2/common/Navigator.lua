local Navigator = class("Navigator")

local Version = require("base/Version")

local ErrorCode = require("common/ErrorCode")
local ComponentManager = require("common/ComponentManager")
local Config = require("common/Config")
local Constant = require("common/Constant")
local Utils = require("common/Utils")

local ROUTE_WEB_TO_NATIVE_PAGE_MAPPING = {
    ["subjects.html"] = {
        ["type"] = "pdd_subjects",
        ["app_version"] = "3.25.0"
    },
    ["subject.html"] = {
        ["type"] = "pdd_subject",
        ["app_version"] = "3.24.0"
    },
    ["catgoods.html"] = {
        ["type"] = "pdd_category",
        ["app_version"] = "3.25.0"
    },
    ["pincard_museum.html"] = {
        ["type"] = "pdd_card_gallery",
        ["app_version"] = "3.38.0"
    },
    ["pincard_reward.html"] = {
        ["type"] = "pdd_card_reward",
        ["app_version"] = "3.38.0"
    },
    ["chat_detail.html"] = {
        ["type"] = "chat",
        ["app_version"] = "3.40.0"
    },
    ["goods.html"] = {
        ["type"] = "pdd_goods_detail",
        ["app_version"] = "3.37.0"
    },
    ["haitao.html"] = {
        ["type"] = "pdd_haitao",
        ["app_version"] = "3.41.0"
    },
    ["orders.html"] = {
        ["type"] = "pdd_orders",
        ["app_version"] = "3.40.0"
    },
    ["goods_express.html"] = {
        ["type"] = "pdd_express",
        ["app_version"] = "3.40.0"
    },
    ["mall_page.html"] = {
        ["type"] = "pdd_mall",
        ["app_version"] = "3.51.0"
    },
    ["personal_profile.html"] = {
        ["type"] = "pdd_personal_profile",
        ["app_version"] = "3.54.0"
    },
    ["timeline.html"] = {
        ["type"] = "pdd_moments",
        ["app_version"] = "3.54.0"
    },
    ["timeline_detail_launch.html"] = {
        ["type"] = "pdd_moments_detail",
        ["app_version"] = "4.5.0"
    },
    ["app_act_promo_popup.html"] = {
        ["type"] = "pdd_activity_promot_popup",
        ["app_version"] = "3.65.0"
    }
}

function Navigator.updateRouteToNative(route)
    if route == nil then
        return
    end

    local props = route["props"]
    if (route["type"] ~= "web" and route["type"] ~= "pdd_web") or props == nil then
        return
    end

    local url = props["url"]
    if url == nil or #url == 0 then
        return
    end

    if url:match("^http") ~= nil then
        return
    end

    local webPageName = string.match(url, "[^/%?]+%.html")
    if webPageName == nil or #webPageName == 0 or string.find(webPageName, "/") then
        return
    end

    local nativePageInfo = ROUTE_WEB_TO_NATIVE_PAGE_MAPPING[webPageName]
    if nativePageInfo == nil then
        return
    end

    local nativeType = nativePageInfo["type"]
    if nativeType == nil then
        return
    end

    local appVersion = nativePageInfo["app_version"]
    local currentAppVersion = Version.new(aimi.Application.getApplicationVersion())
    if appVersion ~= nil and currentAppVersion < Version.new(appVersion) then
        return
    end

    local function parseQuery(query)
        if query == nil or #query == 0 then
            return
        end

        local props = {}
        for key, val in query:gmatch(string.format('([^%q]+)=([^%q]*)', '&', '&')) do
            props[key] = val
        end

        if props["force_use_web_bundle"] == "1" then
            return -1
        end

        return props
    end

    local _, pos = url:find(string.format("%s%s", webPageName, "%?"))
    if pos ~= nil then
        local queryString = string.sub(url, pos + 1, -1)
        local propsFromQueryString = parseQuery(queryString)
        if propsFromQueryString == -1 then
            return
        end
        -- 跳native页面
        if propsFromQueryString ~= nil then
            for key, value in pairs(propsFromQueryString) do
                if props[key] == nil then
                    props[key] = string.decodeURI(value)
                end
            end
        end
    end

    route["type"] = nativeType
    if nativeType == "pdd_subjects" and props ~= nil then
        local subjectsID = props["subjects_id"]
        local noSpike = props["no_spike"]
        if subjectsID ~= nil and Constant.SUBJECTS_ID_EXTRA_PARAMETERS[subjectsID] ~= nil then
            for k,v in pairs(Constant.SUBJECTS_ID_EXTRA_PARAMETERS[subjectsID]) do
                if not(k == "spike_url" and noSpike == "1") then
                    props[k] = v
                end
            end
        end
    end

    return route

end

function Navigator.parsePassThroughFromTable(param)
    if param == nil then
        return
    end

    local passthrough = {}
    local hasPassthrough = false

    for key,value in pairs(param) do
        local _, s = string.match(key, "^(_x_)(.+)")
        if s ~= nil then
            hasPassthrough = true
            passthrough[key] = value
        end
    end

    if hasPassthrough then
        return passthrough
    end
end

function Navigator.parsePassThroughFromUrl(url)
    if type(url) ~= "string" then
        return
    end
    if url ~= nil and #url > 0 then
        local query = Utils.parseQueryFromURL(url)
        local urlPassthrough = Navigator.parsePassThroughFromTable(query)
        if urlPassthrough ~= nil then
            return urlPassthrough
        end
    end
end

function  Navigator.parsePassThroughParameter(props)
    if props == nil then
        return
    end

    -- 从url捕获透传参数
    local url = props["url"]
    local urlPassthrough = Navigator.parsePassThroughFromUrl(url)
    if urlPassthrough ~= nil then
        return urlPassthrough
    end

    -- 从props中捕获透传信息
    return Navigator.parsePassThroughFromTable(props)
end

function Navigator.parseExPassThroughFromTable(param)
    if param == nil then
        return
    end

    local passthrough = {}
    local hasPassthrough = false

    local specialKeyMapping = {
        ["msgid"] = "_x_msgid",
        ["refer_share_id"] = "_x_share_id"
    };

    for key,value in pairs(param) do

        local _, pos = string.find(key,"_ex_")
        if pos ~= nil then
            local passthroughKey = nil
            local subKey = string.sub(key, pos+1)
            if subKey ~= nil and #subKey > 0 then
                passthroughKey = string.format("%s%s","_x_",subKey)
            end
            if passthroughKey ~= nil and #passthroughKey > 0 then
                hasPassthrough = true
                passthrough[passthroughKey] = value
            end
        elseif specialKeyMapping[key] ~= nil then
            hasPassthrough = true
            local mappedKey = specialKeyMapping[key]
            passthrough[mappedKey] = value
        end
    end

    if hasPassthrough then
        return passthrough
    end
end

function Navigator.parseExPassThroughFromUrl(url)
    if type(url) ~= "string" then
        return
    end
    if url ~= nil and #url > 0 then
        local query = Utils.parseQueryFromURL(url)
        local urlExPassthrough = Navigator.parseExPassThroughFromTable(query)
        if urlExPassthrough ~= nil then
            return urlExPassthrough
        end
    end
end

function Navigator.parseExPassThroughParameter(props)
    if props == nil then
        return
    end

    -- 从url捕获透传参数
    local url = props["url"]
    local urlExPassthrough = Navigator.parseExPassThroughFromUrl(url)
    if urlExPassthrough ~= nil then
        return urlExPassthrough
    end

    -- 从props中捕获透传信息
    return Navigator.parseExPassThroughFromTable(props)
end

function Navigator.parsePropertiesContainer(props)
    if props == nil then
        return
    end

    local propertiesContainer = {}
    local hasProperties = false
    local pvTrackingKey = "pv_tracking"

    for key,value in pairs(props) do

        --PV Tracking
        local _, s = string.match(key, "^(_p_)(.+)")
        if s ~= nil then
            hasProperties = true
            local pvTrackingProperties = propertiesContainer[pvTrackingKey]
            if pvTrackingProperties ~= nil then
                pvTrackingProperties[key] = value
            else
                propertiesContainer[pvTrackingKey] = {
                    [key] = value
                }
            end
        end
    end

    if hasProperties then
        return propertiesContainer
    end
end

-- the method is deprecated, use getTabIndex instead
function Navigator.getSelectedTabIndex()
    return aimi.Navigator.getSelectedTabIndex()
end

--We should use this method to forward if tabIndex is negative. For example, if the viewcontroller is presentd by modal
function Navigator.getTabIndex()
    if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.6.0") then
        return Navigator.getSelectedTabIndex()
    end

    return aimi.Navigator.getTabIndex()
end

function Navigator.selectTab(tabIndex, callback)
    AMBridge.call("AMNavigator", "selectTab", {
        ["tab_index"] = tabIndex,
    }, callback)
end

function Navigator.forward(tabIndex, properties, callback)
    if type(properties) ~= "table" then
        return aimi.call(callback, ErrorCode.Generic)
    end

    -- 检测到push foward，需要特殊处理
    local isPush = properties["is_push"] or false
    local passThroughSupport = Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.64.0")
    if isPush and passThroughSupport then
        local props = properties["props"]

        local passthroughParameter = Navigator.parsePassThroughParameter(props)
        local exPassthroughParameter = Navigator.parseExPassThroughParameter(props)
        local passthroughInfo = {}

        if passthroughParameter ~= nil then

            -- 添加到foward参数
            properties["push_passthrough"] = passthroughParameter
            passthroughInfo["push_passthrough"] = passthroughParameter
        end
        
        if exPassthroughParameter then

            properties["ex_push_passthrough"] = exPassthroughParameter
            passthroughInfo["ex_push_passthrough"] = exPassthroughParameter
        end

        -- 通知boot外部启动透传参数
        AMBridge.call("PDDBoot", "setPushInfo", passthroughInfo)
    end

    properties["tab_index"] = tabIndex
    AMBridge.call("AMNavigator", "forward", properties, callback)
end

function Navigator.back(tabIndex, callback)
    AMBridge.call("AMNavigator", "back", {
        ["tab_index"] = tabIndex,
    }, callback)
end

function Navigator.backToRoot(tabIndex, callback)
    AMBridge.call("AMNavigator", "reset", {
        ["tab_index"] = tabIndex,
    }, callback)
end

function Navigator.modal(properties, callback)
    AMBridge.call("AMNavigator", "modal", properties, callback)
end

function Navigator.dismissModal(callback)
    AMBridge.call("AMNavigator", "dismissModal", nil, callback)
end

function Navigator.mask(properties, callback)    
    AMBridge.call("AMNavigator", "mask", properties, callback)
end

function Navigator.dismissMask(callback)
    AMBridge.call("AMNavigator", "dismissMask", nil, callback)
end

function Navigator.showTabBarNote(properties, callback)
    AMBridge.call("PDDTabBarNote", "show", properties, callback)
end

function Navigator.dissmissTabBarNote(properties, callback)
    AMBridge.call("PDDTabBarNote", "dismiss", properties, callback)
end

function Navigator.forwardToNative(properties)
    --其实在route那里做了处理
    Navigator.forward(Navigator.getTabIndex(), properties)
end

function Navigator.forwardToNativeFromPush(properties)
    local route = Navigator.updateRouteToNative(properties)
    if route == nil or route["props"] == nil then
        if properties ~= nil then
            properties["is_push"] = true
        end

        Navigator.forward(Navigator.getTabIndex(), properties)
        return
    end

    local props = route["props"]
    local channels = {}
    local channelKeys = {"src", "campaign", "cid", "msgid"}
    local hasChannels = false
    for _, v in pairs(channelKeys) do
        if props[v] then
            hasChannels = true
            local key = "channel_" .. tostring(v)
            channels[key] = props[v]
        end
    end

    for key,value in pairs(props) do
        local _, s = string.match(key, "(_ex_)(.+)")
        if s ~= nil then
            hasChannels = true
            channels[s] = value
        end
    end

    if hasChannels then
        route["transient_refer_page_context"] = channels
    end

    route["is_push"] = true

    Navigator.forward(Navigator.getTabIndex(), route)
end

function Navigator.forwardToNativeByURL(url)
    if url == nil or #url == 0 then
        return
    end

    local properties = {
        ["type"] = "web",
        ["props"] = {
            ["url"] = url
        }
    }

    Navigator.forwardToNative(properties)
end

function Navigator.forwardToNativeByURLFromPush(url)
    if url == nil or #url == 0 then
        return
    end

    local properties = {
        ["type"] = "web",
        ["props"] = {
            ["url"] = url
        }
    }

    Navigator.forwardToNativeFromPush(properties)
end

require("runtime/module_manager")
AMBridgeModule.export("Navigator", "forwardToNative", Navigator.forwardToNative)

return Navigator