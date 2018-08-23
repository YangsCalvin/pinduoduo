local ABTest = require("common/ABTest")
local Version = require("base/Version")
local Utils = require("common/Utils")
local ComponentManager = require("common/ComponentManager")
local Config = require("common/Config")
local Navigator = require("common/Navigator")

local RECORD_TRACKING_ROUTE_ERROR_COUNT = 0

local ROUTE_PASS_TROUGH_KEY = "push_passthrough"
local ROUTE_EX_PASS_THROUGH_KEY = "ex_push_passthrough"
local ROUTE_PROPS_KEY = "props"
local ROUTE_IS_PUSH_KEY = "is_push"
local ROUTE_PROPS_URL_KEY = "url"
local ROUTE_PROPS_PROPERTIES_CONTAINER_KEY = "properties_container"

local function reRouteForiOS6(route)
    local osVersion = Version.new(aimi.Device.getSystemVersion())
    if osVersion >= Version.new("7.0.0") then
        return
    end

    if route["type"] == "pdd_order_checkout" and route["props"] ~= nil then
        local url = route["props"]["url"]
        if url ~= nil and #url > 0 then
            route["type"] = "web"
        else 
            url = Utils.buildURL("order_checkout.html", route["props"])
            route["props"]["url"] = url
            route["type"] = "web"
        end
    elseif route["type"] == "pdd_goods_detail" and route["props"] ~= nil then
        local url = route["props"]["url"]
        if url ~= nil and #url > 0 then
            route["type"] = "web"
        end
    end
end

local function addPassthrough(route)

    if type(route) ~= "table" then
        return
    end

    local isPush = route["is_push"] or false

    if isPush then
        return
    end

    local props = route[ROUTE_PROPS_KEY]
    if type(props) ~= "table" then
        return
    end

    local url = props[ROUTE_PROPS_URL_KEY]

    local mergedPassThrough = {}
    local passThroughFromProps = Navigator.parsePassThroughFromTable(props)
    Utils.mergeTable(mergedPassThrough, passThroughFromProps)
    local passThroughFromUrl = Navigator.parsePassThroughFromUrl(url)
    Utils.mergeTable(mergedPassThrough, passThroughFromUrl)

    if mergedPassThrough ~= nil and type(mergedPassThrough) == "table" then
        route[ROUTE_PASS_TROUGH_KEY] = mergedPassThrough
    end

    local mergedExPassThrough = {}
    local exPassthroughFromProps = Navigator.parseExPassThroughFromTable(props)
    Utils.mergeTable(mergedExPassThrough, exPassthroughFromProps)
    local exPassthroughFromUrl = Navigator.parseExPassThroughFromUrl(url)
    Utils.mergeTable(mergedExPassThrough, exPassthroughFromUrl)
    
    if mergedExPassThrough ~= nil and type(mergedExPassThrough) == "table" then
        route[ROUTE_EX_PASS_THROUGH_KEY] = mergedExPassThrough
    end
end

function addPropertiesContainer(route)

    if Version.new(aimi.Application.getApplicationVersion()) < Version.new("4.10.0") then
        return
    end

    if type(route) ~= "table" then
        return
    end

    local props = route[ROUTE_PROPS_KEY]
    if type(props) ~= "table" then
        return
    end
    local propertiesContainer = Navigator.parsePropertiesContainer(props)
    if propertiesContainer ~= nil then
        route[ROUTE_PROPS_PROPERTIES_CONTAINER_KEY] = propertiesContainer
    end
end

local function checkResource(properties)
    if type(properties) ~= "table" then
        return
    end

    local props = properties["props"]
    if type(props) ~= 'table' then
        return
    end
    
    local url = props["url"]
    if type(url) ~= "string" or #url == 0 then
        return
    end

    local pageType = properties["type"]
    if (pageType == "web" or pageType == "pdd_web" or pageType == "pdd_card_discount_web") and string.find(url, "^http") == nil  then
        local fileName = string.match(url,"^[^/]+%.html", 1)
        if fileName == nil then
            if string.find(url, "^pinduoduo://.+%.html", 1) ~= nil then
                fileName = string.match(url, "[^/]+%.html")
                local pos = string.find(url, "[^/]+%.html")
                if pos ~= nil then
                    url = string.sub(url, pos)
                    props["url"] = url
                end
            end
        end
        
        if fileName == nil or string.find(fileName, "/") then
            print("fileName is invalid, fileName=",fileName)

            -- invalid url, set empty type
            if string.find(url, "^pinduoduo://") ~= nil then
                properties["type"] = ""
            end

            return
        end

        if not ComponentManager.isFileExist(ComponentManager.WebComponentName, fileName) then
            url = Config.AM_WEB_HOST .. url
            print("load web url " .. url)
            props["url"] = url
        end
    end
end

if aimi.Navigator ~= nil and aimi.Navigator.setRewriteFunction ~= nil then
    aimi.Navigator.setRewriteFunction(function(route) 
        Navigator.updateRouteToNative(route)

        if route["type"] == "superbrand" then
            route = {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "subjects.html?subjects_id=14",
                },
            }
        end

        if type(ABTest) ~= "table" then
            print("ABTest.reRoutePageType failed, send lua_error")
            if RECORD_TRACKING_ROUTE_ERROR_COUNT < 1 then
                RECORD_TRACKING_ROUTE_ERROR_COUNT = RECORD_TRACKING_ROUTE_ERROR_COUNT + 1
                local Tracking = require("common/Tracking")
                Tracking.send("lua_error", "", {
                    ["error"] = 'ABTest moudle type is' .. tostring(type(ABTest)),
                    ["error_msg"] = "ABTest rewrite route failed",
                    ["lua_error_code"] = "10002"
                })
            end
            return route
        end
        
        local version = Version.new(aimi.Application.getApplicationVersion())
        local newMall = tostring(aimi.KVStorage.getInstance():get("pdd_mall_newVersion"))
        if route["type"] == "pdd_mall" and route["props"] ~= nil and version >= Version.new("4.13.0") and newMall == "1" then
            route["type"] = "pdd_new_mall"
        end
        
        local rewriteType = ABTest.reRoutePageType(route["type"])
        local props = route["props"]
        if (rewriteType == "web" or rewriteType == "pdd_web") and props ~= nil then
            local url = props["url"]
            if url ~= nil and #url > 0 then
                route["type"] = rewriteType
            end
        end


        reRouteForiOS6(route)
        -- fix goods detail crash on ios7
        local osVersion = Version.new(aimi.Device.getSystemVersion())
        if route["type"] == "pdd_goods_detail" and route["props"] ~= nil and osVersion < Version.new("8.0.0") and version <= Version.new("3.21.0") then
            local url = route["props"]["url"]
            if url ~= nil and #url > 0 then
                route["type"] = "web"
            end
        end

        -- fix issue pdd_1008
        if route["type"] == "pdd_orders" and version < Version.new("3.7.0") then
            local orderType = 0
            if route["props"] ~= nil and route["props"]["type"] ~= nil then
                orderType = route["props"]["type"]
            end
            route = {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = string.format("%s%d","orders.html?type=" ,orderType),
                },
            }
        end
        
        if route["type"] == "pdd_order" or route["type"] == "pdd_order_checkout" then
            route["type"] = "web"
        end

        -- fix system keyboard input issue
        if route["type"] == "pdd_express_complaint" and version < Version.new("3.14.0") then
            route["type"] = "web"
        end

        -- home banner route to web page
        if route["type"] == "pdd_subject" then
            if route["props"] ~= nil and route["props"]["subject_id"] == "3166" then
                route = {
                    ["type"] = "web",
                    ["props"] = {
                        ["url"] = "rate_your_voice.html"
                    }
                }
            end

            if route["props"] ~= nil and route["props"]["subject_id"] == "2202" 
                and route["props"]["url"] ~= nil and #route["props"]["url"] > 0 
                and version < Version.new("3.66.0") then
                route["type"] = "web"
            end
        end

        -- fix bug, versions less than 4.4.0 do not support friend feature
        if (route["type"] == "pdd_friend_chat" or route["type"] == "pdd_requesting_friends" or route["type"] == "pdd_friends") 
            and version < Version.new("4.4.0") then
            route["type"] = ""
        end

        -- native comment list page support since iOS version 3.49.0
        if route["type"] == "pdd_comment_list" and version < Version.new("3.49.0") then
            route["type"] = "web"
        end

        local function checkWeb()
            if route["type"] == "web" and version >= Version.new("2.7.0") then
                route["type"] = "pdd_web"
                
            end

            checkResource(route)

        end      

        checkWeb()

        addPassthrough(route)
        addPropertiesContainer(route)

        return route
    end)
end
