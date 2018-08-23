-- 通知权限
local SetupUserNotificationTask = class("SetupUserNotificationTask")

local Promise = require("base/Promise")
local Version = require("base/Version")

local Constant = require("common/Constant")
local Event = require("common/Event")
local Navigator = require("common/Navigator")
local Tracking = require("common/Tracking")
local Version = require("base/Version")

local MaxPromotionCount = 3
local OpenCountPeriod = 5

local nativeAnimationCallback

function SetupUserNotificationTask.run(resolve, reject, isNewDevice, isNewInstall)
    print('---Push SetupUserNotificationTask---')
    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        local openNew = response["value"]
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            print('---Push SetupUserNotificationTask New---')
            return aimi.call(resolve)
        else
            print('---Push SetupUserNotificationTask old---')
            return SetupUserNotificationTask.real(resolve, reject, isNewDevice, isNewInstall)
        end
    end)
end

function SetupUserNotificationTask.real(resolve, reject, isNewDevice, isNewInstall)
    if SetupUserNotificationTask.counter_ == nil then
        SetupUserNotificationTask.counter_ = 0
        SetupUserNotificationTask.isShowingPrompt_ = false
        SetupUserNotificationTask.hasStarted_ = false
    
        AMBridge.register(Event.ApplicationResume, function()
            if not SetupUserNotificationTask.isShowingPrompt_ then
                Application.getSharedTaskQueue():push(SetupUserNotificationTask.run)
            end
        end)
    
        local function handleUserNotificationSetting(notificationSettings)
            if SetupUserNotificationTask.isShowingPrompt_ then
                if nativeAnimationCallback then
                    nativeAnimationCallback()
                    SetupUserNotificationTask.isShowingPrompt_ = false
                    return
                end
                Navigator.dismissMask()
                SetupUserNotificationTask.isShowingPrompt_ = false
                aimi.call(resolve)
            end
        end
    
        AMBridge.register(Event.UserNotificationSettings, function(notificationSettings)
            handleUserNotificationSetting(notificationSettings)
        end)
    
        AMBridge.register(Event.UserNotifySettings, function(authorizationOptions)
            handleUserNotificationSetting(authorizationOptions)
        end)
    end
    
    SetupUserNotificationTask.setupUserNotification(resolve, reject, isNewDevice, isNewInstall)
end

function SetupUserNotificationTask.setupUserNotification(resolve, reject, isNewDevice, isNewInstall)
    local storage = aimi.KVStorage.getInstance()

    local promotionInfoKey = "LuaUserNotificationPromotionInfo"
    local function loadPromotionInfo()
        local info = storage:get(promotionInfoKey)
        local promotionCount, openCount, openDay = (info or ""):match("(%d+).(%d+).(%d+)")

        return (tonumber(promotionCount) or 0), (tonumber(openCount) or 0), (tonumber(openDay) or 0)
    end
    local function savePromotionInfo(promotionCount, openCount, openDay)
        storage:set(promotionInfoKey,
            string.format("%s|%s|%s", tostring(promotionCount), tostring(openCount), tostring(openDay)))
    end
    local function savePromotionInfoDelta(promotionCountDelta, openCountDelta, openDayDelta)
        local originalPromotionCount, originalOpenCount, originalOpenDay = loadPromotionInfo()

        savePromotionInfo(originalPromotionCount + (tonumber(promotionCountDelta) or 0),
            originalOpenCount + (tonumber(openCountDelta) or 0),
            originalOpenDay + (tonumber(openDayDelta) or 0))
    end
    local function startPushNotification()
        if SetupUserNotificationTask.hasStarted_ then
            return
        end

        AMBridge.call("AMUserNotification", "start", nil, function(errorCode)
            if errorCode == 0 then
                storage:set(Constant.PendingFirstUserNotificationRegistrationFlagKey, nil)
                SetupUserNotificationTask.hasStarted_ = true
            end
        end)
    end

    local shouldPrompt = (function()
        if aimi.Application.isUserNotificationEnabled() then
            startPushNotification()

            return false
        end

        local today = os.date("*t", now).day
        local promotionCount, openCount, openDay = loadPromotionInfo()

        if promotionCount <= 0 then
            savePromotionInfo(0, 1, today)
            return true
        end

        if promotionCount >= MaxPromotionCount or today == openDay then
            return false
        end

        if openCount >= OpenCountPeriod then
            savePromotionInfo(promotionCount, 1, today)
            return true
        else
            savePromotionInfo(promotionCount, openCount + 1, today)
            return false
        end
    end)()
    local isFirstRegistration = (function()
        if storage:get(Constant.PendingFirstUserNotificationRegistrationFlagKey) ~= nil then
            return true
        end

        local isFirst = false

        if Version.new(aimi.Device.getSystemVersion()) < Version.new("9.0.0") then
            isFirst = isNewDevice
        else
            isFirst = isNewInstall
        end

        if aimi.Application.hasOldVersionFlags() then
            isFirst = false
        end

        if isFirst then
            storage:set(Constant.PendingFirstUserNotificationRegistrationFlagKey, "1")
        end

        return isFirst
    end)()

    if shouldPrompt then
        Tracking.send("event", "open_notify_popup_show", {
            ["page_sn"] = "10002",
            ["page_name"] = "index",
            ["page_section"] = "open_notify_popup",
            ["page_el_sn"] = "99504"
        })
        
        local trackingConfirmClick = function()
            Tracking.send("click", "", {
            ["page_sn"] = "10002",
            ["page_name"] = "index",
            ["page_section"] = "open_notify_popup",
            ["page_element"] = "open_btn",
            ["page_el_sn"] = "99655"
        })
        end

        local trackingClosePushPage = function()
            Tracking.send("click", "", {
            ["page_sn"] = "10002",
            ["page_name"] = "index",
            ["page_section"] = "open_notify_popup",
            ["page_element"] = "close_btn",
            ["page_el_sn"] = "99654"
        })
        end

        if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("2.6.0") then
            Navigator.mask({
                ["type"] = "pdd_push",
                ["props"] = {
                    ["complete"] = function(errorCode, response)
                        if response["confirmed"] ~= 0 then
                            nativeAnimationCallback = response["callback"]
                            startPushNotification()
                            trackingConfirmClick()
                            if not isFirstRegistration then
                                Navigator.dismissMask()
                                SetupUserNotificationTask.isShowingPrompt_ = false
                                AMBridge.call("AMUserNotification", "enable")
                                aimi.call(resolve)
                                return
                            end
                            if  Version.new(aimi.Device.getSystemVersion()) < Version.new("8.0.0") then
                                Navigator.dismissMask()
                                SetupUserNotificationTask.isShowingPrompt_ = false
                                aimi.call(resolve)
                            end
                        else
                            Navigator.dismissMask()
                            trackingClosePushPage()
                            SetupUserNotificationTask.isShowingPrompt_ = false
                            aimi.call(resolve)
                        end
                    end,
                    ["animationComplete"] = function(errorCode, response)
                        Navigator.dismissMask()
                        SetupUserNotificationTask.isShowingPrompt_ = false
                        aimi.call(resolve)
                    end,
                },
            }, function(errorCode)
                if errorCode == 0 then
                    savePromotionInfoDelta(1, 0, 0)
                    SetupUserNotificationTask.isShowingPrompt_ = true
                else
                    aimi.call(resolve)
                end
            end)
        else
            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_open_notification.html",
                    ["opaque"] = false,
                    ["extra"] = {
                        ["complete"] = function(errorCode, response)
                            if response["confirmed"] ~= 0 then
                                startPushNotification()
                                if not isFirstRegistration then
                                    Navigator.dismissMask()
                                    SetupUserNotificationTask.isShowingPrompt_ = false
                                    AMBridge.call("AMUserNotification", "enable")
                                    aimi.call(resolve)
                                    return
                                end
                                if Version.new(aimi.Application.getApplicationVersion()) < Version.new("2.5.0") or 
                                    Version.new(aimi.Device.getSystemVersion()) < Version.new("8.0.0") then
                                    Navigator.dismissMask()
                                    SetupUserNotificationTask.isShowingPrompt_ = false
                                    aimi.call(resolve)
                                end
                            else
                                Navigator.dismissMask()
                                SetupUserNotificationTask.isShowingPrompt_ = false
                                aimi.call(resolve)
                            end
                        end,
                    },
                },
            }, function(errorCode)
                if errorCode == 0 then
                    savePromotionInfoDelta(1, 0, 0)
                    SetupUserNotificationTask.isShowingPrompt_ = true
                else
                    aimi.call(resolve)
                end
            end)
        end
    else
        startPushNotification()
        aimi.call(resolve)
    end
end


return SetupUserNotificationTask