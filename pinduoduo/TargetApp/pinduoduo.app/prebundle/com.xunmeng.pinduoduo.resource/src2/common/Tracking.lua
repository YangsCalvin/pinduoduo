local Tracking = class("Tracking")

local AimiString = require("runtime/aimi_string")
local APIService = require("common/APIService")
local Config = require("common/Config")
local Constant = require("common/Constant")
local Utils = require("common/Utils")
local Version = require("base/Version")
local Promise = require("base/Promise")

local LAST_UPLOAD_DEVICE_INFO_KEY = "LuaLastUploadDeviceInfo"
local PDD_BOOT_ID_KEY = "boot_id"

local RECORD_TRACKING_COUNT = 0
local GET_BOOT_ID_COUNT_FLAG = 0 

local function getAPIUID(url)
    local cookies = aimi.HTTPCookieStorage.getInstance():getCookiesForURL(url) or {}

    return cookies["api_uid"]
end


function Tracking.send(operation, event, params)
    params = params or {}
    params["op"] = operation
    params["event"] = event

    params["user_id"] = aimi.User.getUserID()
    if operation == "lua_error" then
        params["vender_id"] = aimi.Device.getVenderIdentifier()
        params["uuid"] = aimi.Device.getDeviceIdentifier()
    end

    local  url = Config.TrackingService
    if operation == "lua_error" then
        url = Config.TrackingErrorService
    end

    -- From 3.28.0 let PDDAnalyse handle the sending, so we don't need to write same logic in two places
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.28.0") then
        AMBridge.call("PDDAnalyse", "send", {
            ["url"] = url,
            ["params"] = params
        })
    else
        -- Keep compatible of old verion
        local now = aimi.Device.getSystemTime == nil and (os.time() * 1000) or
            aimi.Device.getSystemTime()

        params["time"] = now
        params["cookie"] = getAPIUID(Config.TrackingService)
        params["app_version"] = aimi.Application.getApplicationVersion()
        params["platform"] = "iOS"

        if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.27.0") then
            params["model"] = aimi.Device.getModel()
        end

        local version = Version.new(aimi.Application.getApplicationVersion())
        if version < Version.new("3.26.0") then
            Tracking.directSend(url, operation, event, params)
        else
            AMBridge.call("PDDABTest", "check", {
                ["name"] = "pdd_tracking_batch_send"
            }, function(error, response)
                if response and response["is_enabled"] == 1 then
                    AMBridge.call("AMAnalytics", "send", {
                        ["url"] = url,
                        ["value"] = params,
                        ["realtime"] = 1 
                    })
                else
                    Tracking.directSend(url, operation, event, params)
                end
            end)
        end
    end

    if event == "user_trace" or operation == "lua_error" then
        Tracking.log(params)
    end
   
end

function Tracking.directSend( url, operation, event, params )
    local tokens = {}

    for key, value in pairs(params) do
        table.insert(tokens, string.format("%s=%s",
            string.encodeURI(tostring(key)), string.encodeURI(tostring(value))))
    end

    local request = aimi.HTTPRequest.create(url)
    local body = table.concat(tokens, "&")

    request:setMethod("POST")
    request:setBody(body)
    aimi.HTTPRequestOperation.create(request):start()
end

function Tracking.log(params)
    local tokens = {}

    local trackingFailed = false
    if type(string.encodeURI) == "function" then
        for key, value in pairs(params) do
            table.insert(tokens, string.format("%s=%s",string.encodeURI(tostring(key)), string.encodeURI(tostring(value))))
        end
    else
        trackingFailed = true
    end

    if trackingFailed and RECORD_TRACKING_COUNT < 1 then
        print('trackingFailed=', trackingFailed, "RECORD_TRACKING_COUNT=", RECORD_TRACKING_COUNT)
        RECORD_TRACKING_COUNT = RECORD_TRACKING_COUNT + 1
        local s = ""
        if type(string.encodeURI) == "nil" then
            s = "string.encodeURI is nil"
        end

        s = s .. ", string contains methods:"
        if type(string) == "table" then
            for key,value in pairs(string) do
              if type(key) == "string" then
                s = s .. key .. "|"
              end
            end
        end

        s = s .. ", AimiString type=" .. type(AimiString) ..","
        Tracking.send("lua_error", "", {
            ["error"] = tostring(s),
            ["error_msg"] = "string encode/decode failed",
            ["lua_error_code"] = "10000"
        })
    end

    local body = table.concat(tokens, "&")

    AMBridge.call("AMLog", "log", {
        ["message"] = os.date("[%Y%m%d%H%M%S]") .. body
    })
end

function Tracking.userTrace(isNewInstall, forceUpate)
    AMBridge.call("AMUserNotification", "check", nil, function(errorCode, response)
        local isEnabled = response["is_enabled"]
        local pushEnabled = (type(isEnabled) == "number") and (isEnabled == 1)
        local isPushEnabled = pushEnabled and "1" or "0"
        local bootID = ""
        if GET_BOOT_ID_COUNT_FLAG == 0 then
            GET_BOOT_ID_COUNT_FLAG = 1
            bootID = aimi.KVStorage.getInstance():get(PDD_BOOT_ID_KEY)
        end

        local userTraceTable = {
            ["device_token"] = aimi.Device.getDeviceToken(),
            ["system_version"] = aimi.Device.getSystemVersion(),
            ["vender_id"] = aimi.Device.getVenderIdentifier(),
            ["uuid"] = aimi.Device.getDeviceIdentifier(),
            ["idfa"] = aimi.Device.getAdvertisingIdentifier(),
            ["is_push_enabled"] = isPushEnabled,
            ["new_install"] = isNewInstall and "1" or "0",
        }

        if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.18.0") then
            local installToken = aimi.KVStorage.getInstance():get("__LUA_APP_INSTALL_TOKEN__")
            if type(installToken) == "string" and #installToken > 0 then
                userTraceTable["install_token"] = installToken
            end
        end

        if type(bootID) == "string" and #bootID > 0 then
            print("user_trace bootID=", bootID)
            userTraceTable["boot_id"] = bootID
        end

        Tracking.send("event", "user_trace", userTraceTable)

        Tracking.uploadDeviceInfo(1, forceUpate, isPushEnabled)

        -- AMBridge.call("PDDABTest", "check", {
        --     ["name"] = "pdd_upload_device_info",
        --     ["default_value"] = 0
        -- }, function (error, response)
        --     if response ~= nil and response["is_enabled"] == 1 then
        --         Tracking.uploadDeviceInfo(1)
        --     end
        -- end)
    end)
end

function Tracking.uploadDeviceInfo(retryCount, forceUpate, isPushEnabled)
    if retryCount > 3 then
        return
    end

    retryCount = retryCount + 1

    local ext = {
        ["device_token"] = aimi.Device.getDeviceToken(),
        ["uuid"] = aimi.Device.getDeviceIdentifier(),
        ["vender_id"] = aimi.Device.getVenderIdentifier(),
        ["is_push_enabled"] = isPushEnabled
    }

    -- use this variable to depend whether need send api to server
    local deviceInfo = {
        ["platform"] = "iOS",
        ["app_version"] = aimi.Application.getApplicationVersion(),
        ["user_id"] = aimi.User.getUserID(),
        ["ext"] = ext
    }

    local now = aimi.Device.getSystemTime == nil and (os.time() * 1000) or
                aimi.Device.getSystemTime()
    local userTraceVO = {
        ["log_time"] = now,
        ["platform"] = "iOS",
        ["app_version"] = aimi.Application.getApplicationVersion(),
        ["user_id"] = aimi.User.getUserID(),
        ["ext"] = ext
    }

    local needSendApi = true;
    xpcall(function()
        if forceUpate == false then
            local value = aimi.KVStorage.getInstance():get(LAST_UPLOAD_DEVICE_INFO_KEY)
            if type(value) == "string" and value == tostring(json.encode(deviceInfo)) then
                print("user_trace equals return")
                needSendApi = false
            end
        end
    end, AMBridge.error)

    if not needSendApi then
        print("user_trace since deviceInfo is equal, will not send api")
        return
    end

    print("----------start user_trace request record-------")
    Promise.new(function(resolve, reject)
        return APIService.postJSON("api/galen/app_device/record", {
            ["user_trace_vo"] = userTraceVO
        }):next(function(response)
            resolve(response)
        end):catch(function(reason)
            -- aimi.Scheduler.getInstance():schedule(30, function()
            --     Tracking.uploadDeviceInfo(retryCount, forceUpate)
            -- end)
            reject(reason)
        end)
    end):next(function(response)
        print("user_trace", response)
        xpcall(function()
            aimi.KVStorage.getInstance():set(LAST_UPLOAD_DEVICE_INFO_KEY, tostring(json.encode(deviceInfo)))
            print("user_trace: save deviceInfo",tostring(json.encode(deviceInfo)))
        end, AMBridge.error)
    end)
end

function Tracking.appLifeCycleEvent(event)
    -- Tracking.send("event", nil, {
    --     ["sub_op"] = event,
    --     ["pdd_id"] = aimi.KVStorage.getInstance():getSecure(Constant.PDD_ID_KEY),
    -- })
end

function Tracking.monitorNetwork()
    local  appVersion = Version.new(aimi.Application.getApplicationVersion())
    if  appVersion < Version.new("3.26.0") or appVersion >= Version.new("3.33.0") then
        return
    end

    local whitelist = {
        "(?!/[a-z]\\.gif|/api/batch|/d$).*"
    }

    AMBridge.call("AMNetworkMonitor", "setup", {
        ["upload_url"] =  Config.CMTService,
        ["event_max_count"] = 1000,
        ["event_batch_size"] = 20,
        ["event_upload_period_seconds"] = 10,
        ["gzip_body"] = 1,
        ["whitelist"] = whitelist
    })
end

return Tracking