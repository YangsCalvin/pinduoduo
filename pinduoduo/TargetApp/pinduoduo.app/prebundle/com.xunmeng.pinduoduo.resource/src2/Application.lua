Application = Application or class("Application")

local TaskQueue = require("base/TaskQueue")
local Promise = require("base/Promise")

local ComponentManager = require("common/ComponentManager")
local ABTest =  require("common/ABTest")
local GoodsConfig = require("common/GoodsConfig")
local FriendGray = require("common/FriendGray")
local Constant = require("common/Constant")
local Event = require("common/Event")
local Navigator = require("common/Navigator")
local Tracking = require("common/Tracking")
local Activity = require("common/Activity")
local APIService = require("common/APIService")
local AppManager = require("common/AppManager")

local CheckAppGroupTask = require("task/CheckAppGroupTask")
local CheckAppUpdateTask = require("task/CheckAppUpdateTask")
local SetupUserNotificationTask = require("task/SetupUserNotificationTask")
local CheckAppActivityTask = require("task/CheckAppActivityTask")
local CheckMarketActivityTask = require("task/CheckMarketActivityTask")
local CheckForceLoginTask = require("task/CheckForceLoginTask")

local SettingsScene = require("scene/SettingsScene")

function Application.run()
    math.randomseed(os.time())
    Application.beforeRun(function(isNewDevice, isNewInstall)
        Application.getSharedTaskQueue():push(ComponentManager.initialize)

        if type(ABTest) == "table" then
            Application.getSharedTaskQueue():push(ABTest.initialize)
        else
            print("ABTest.initialize failed, send lua_error")
            xpcall(function()
                print('handle lua error')
                local loadPackages = "package.loaded:";
                for key, value in pairs(package.loaded) do
                    loadPackages = loadPackages ..tostring(key) .. "," .. type(value) .. "|"
                end

                local abTestModuleName = "common/ABTest"
                package.loaded[abTestModuleName] = nil
                ABTest = require(abTestModuleName)

                if type(ABTest) == "table" then
                    Application.getSharedTaskQueue():push(ABTest.initialize)
                    loadPackages = loadPackages .. "ABTest is table"
                end

                local abTestModuleMD5 = ""
                local fileContent = ComponentManager.getFileContent(ComponentManager.LuaComponentName, "src2/" .. abTestModuleName .. ".lua")
                if type(fileContent) == "string" and Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.42.0") then
                    abTestModuleMD5 = tostring(aimi.DataCrypto.md5(fileContent))
                end

                local extraInfo = ""
                fileContent = ComponentManager.getFileContent(ComponentManager.LuaComponentName, "src2/runtime/route.lua")
                if type(fileContent) == "string" and Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.42.0") then
                    extraInfo = "route.lua," .. tostring(aimi.DataCrypto.md5(fileContent))
                end

                print('loadPackages=', loadPackages, abTestModuleName, " md5=" .. abTestModuleMD5 .. ", extraInfo=",extraInfo)
                local version = ComponentManager.getComponentVersion(ComponentManager.LuaComponentName)
                Tracking.send("lua_error", "", {
                    ["error"] = "ABTest moudle type is ".. tostring(type(ABTest)),
                    ["error_msg"] = "ABTest.initialize failed",
                    ["lua_error_code"] = "10001",
                    ["lua_package_loaded"] = loadPackages,
                    ["version"] = tostring(version),
                    ["module_name"] = abTestModuleName,
                    ["module_md5"] = abTestModuleMD5,
                    ["extra_info"] = extraInfo
                })
            end, AMBridge.error)
        end

        Application.getSharedTaskQueue():push(FriendGray.initialize)
        
        Application.getSharedTaskQueue():push(CheckForceLoginTask.run)
        Application.getSharedTaskQueue():push(function(resolve, reject)
            SetupUserNotificationTask.run(resolve, reject, isNewDevice, isNewInstall)
        end)

        xpcall(function()
            local CheckAppRedPacketGroupTask = require("task/CheckAppRedPacketGroupTask")
            Application.getSharedTaskQueue():push(CheckAppRedPacketGroupTask.run)
        end, AMBridge.error)

        Application.getSharedTaskQueue():push(CheckAppUpdateTask.run)
        -- Application.getSharedTaskQueue():push(function(resolve, reject)
            -- CheckAppGroupTask.run(resolve, reject, isNewInstall)
        -- end)
        Application.getSharedTaskQueue():push(CheckAppActivityTask.run)
        Application.getSharedTaskQueue():push(GoodsConfig.initialize)

        if Version.new(aimi.Application.getApplicationVersion()) > Version.new("3.44.0") and 
            Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.56.0") then
            Application.getSharedTaskQueue():push(AppManager.initialize)
        end

        Tracking.monitorNetwork()
        Application.handleEvents()
        -- Application.resetActivity()
        Activity.fetchData()
        Application.reloadHomeScene()
        Application.reloadChatListScene()
        Application.reloadPersonalScene()
        --Application.reloadOrderScene()
        Application.updateFavorite()
        Application.clearGeneratedImageCache()

        -- Tracking.appLifeCycleEvent(Constant.APP_START)
        Tracking.userTrace(isNewInstall, false)
        aimi.Scheduler.getInstance():schedule(30, function()
            Tracking.userTrace(false, false)
        end)
    end)
end

function Application.getSharedTaskQueue()
    if Application.sharedTaskQueue_ == nil then
        Application.sharedTaskQueue_ = TaskQueue.new()
    end

    return Application.sharedTaskQueue_
end

function Application.beforeRun(run)
    local function isEmpty(value)
        return value == nil or #value <= 0
    end

    local isNewDevice = isEmpty(aimi.KVStorage.getInstance():getSecure(Constant.OldDeviceFlagKey))
    local isNewInstall = isEmpty(aimi.KVStorage.getInstance():get(Constant.OldInstallFlagKey))

    run(isNewDevice, isNewInstall)

    if isNewDevice then
        aimi.KVStorage.getInstance():setSecure(Constant.OldDeviceFlagKey, "1")
    end

    if isNewInstall then
        aimi.KVStorage.getInstance():set(Constant.OldInstallFlagKey, "1")
    end
end

function Application.handleEvents()
    -- AMBridge.register(Event.ApplicationResume, function()
    --     HotSwap.get():run()
    -- end)
    AMBridge.register(Event.ComponentUpdated, function(payload)
        if payload["component_name"] == ComponentManager.LuaComponentName then
            HotSwap.get():run()
        end
    end)

    AMBridge.register(Event.DeviceToken, function(payload)
        if payload ~= nil then
            print("------------device_token=",payload["device_token"])
        end

        Tracking.userTrace(false, false)
    end)

    AMBridge.register(Event.ApplicationResume, function()
        aimi.KVStorage.getInstance():set("LUA_HAS_PUSH_PAGE_FLAG_KEY" , "0")
        xpcall(function()
            local CheckAppRedPacketGroupTask = require("task/CheckAppRedPacketGroupTask")
            Application.getSharedTaskQueue():push(CheckAppRedPacketGroupTask.run)
        end, AMBridge.error)

        Application.getSharedTaskQueue():push(CheckAppUpdateTask.run)
        -- Application.getSharedTaskQueue():push(CheckAppGroupTask.run)
        Application.getSharedTaskQueue():push(CheckAppActivityTask.run)
        Activity.fetchData()
        --fix ios6 issue
        -- local osVersion = Version.new(aimi.Device.getSystemVersion())
        -- if osVersion >= Version.new("7.0.0") then
        --     Application.resetActivity()
        -- end

        Application.updateFavorite()
        -- Tracking.appLifeCycleEvent(Constant.APP_RESUME)
    end)

    AMBridge.register(Event.ApplicationPause, function()
        -- Tracking.appLifeCycleEvent(Constant.APP_PAUSE)
    end)

    AMBridge.register(Event.ApplicationStop, function()
        -- Tracking.appLifeCycleEvent(Constant.APP_STOP)
    end)

    AMBridge.register(Event.PDDUpdateFriendChatGrayFeautresNotification,function()
        Application.reloadChatListScene()
    end)

    AMBridge.register(Event.UserLogin, function()
        Tracking.userTrace(false, true)
        -- Application.resetActivity()
    end)
    AMBridge.register(Event.UserLogout, function()
        Tracking.userTrace(false, true)
        TabBar.setBadgeVisible({
            TabBar.Tabs.Personal,
        }, {
            false,
        })
        -- Application.resetActivity()
    end)

    AMBridge.register(Event.ExternalNotification, function(payload)
        AMBridge.call("AMLog", "log", {
            ["message"] = os.date("[%Y%m%d%H%M%S]") .. json.encode(payload)
        })
        local function handleOpenUrl(url, payload)
            if (url == nil or #url <= 0) then
                return true, url
            end
            local start, ends = url:find("://")
            if start == nil or ends == nil then
                return true, url
            end

            local scheme = string.sub(url, 1, start - 1)

            if scheme == nil then
                return true, url
            end

            if scheme == Constant.PDD_OPEN_SCHEME then
                AMBridge.call("PDDOpenPlatform", "show", payload)
                url = payload["h5Url"]
                return true, url
            end

            if scheme == Constant.PDD_TENCENT_VIDIO_SCHEME then
                AMBridge.call("PDDAdvertise", "show", {
                    ["title"] = "腾讯视频",
                    ["tap_callback"] = function()
                        local tencentVideoLink = string.format('tenvideo2://?action=66&from=%s',Constant.PDD_TENCENT_VIDIO_SCHEME)
                        if tencentVideoLink ~= nil then
                        AMBridge.call("AMLinking", "openURL", {
                            ["url"] = tencentVideoLink
                        })
                        end
                    end,
                    ["close_callback"] = function()
                    end,
                })
                return false, url
            end
            return true, url
        end

        local active = payload["is_application_active"]

        if active ~= nil and active ~= 0 then
            return
        end

        local url = table.get(payload, { "url", "share_url", "content" })
        local nativePageType = payload["native_type"]
        if (url == nil or #url <= 0) and (nativePageType == nil or #nativePageType == 0) then
            return
        end
        local continueProcess = true
        continueProcess, url = handleOpenUrl(url, payload)

        if continueProcess == false then
           return
        end

        local function parseQuery(str)
            local props = {}
            for key,val in str:gmatch(string.format('([^%q]+)=([^%q]*)', '&', '&')) do
                props[key] = string.decodeURI(val)
            end
            return props
        end
        
        local function forwardPage(url, nativePageType)
            -- 优先使用原生的页面进行跳转
            if nativePageType ~= nil and #nativePageType > 0 then
                local props = payload["props"] or {}
                if type(props) == "table" then
                    local needsLogin = payload["needs_login"] or false
                    if needsLogin then
                        local accessToken = aimi.User.getAccessToken()
                        if accessToken ~= nil and #accessToken > 0 then
                            needsLogin = false
                        end
                    end

                    if needsLogin then
                        Navigator.modal({
                            ["type"] = "login",
                            ["props"] = {
                                ["complete"] = function(errorCode, response)
                                    if response["access_token"] ~= nil then
                                        Navigator.forward(Navigator.getTabIndex(), {
                                            ["type"] = nativePageType,
                                            ["props"] = props,
                                            ["is_push"] = true
                                        })
                                    end
                                end
                            }
                        })
                    else
                        Navigator.forward(Navigator.getTabIndex(), {
                            ["type"] = nativePageType,
                            ["props"] = props,
                            ["is_push"] = true

                        })
                    end
                end
            elseif url ~= nil and #url > 0 then
                -- check whether url match universal link
                if url:match("universal%-link%?originalUrl=") then
                    print("url match universal-link")
                    local _, pos = string.find(url, "scheme=")
                    if pos ~= nil then
                        url = string.decodeURI(string.sub(url, pos + 1))
                        print("decode url", url)
                        AMBridge.call("AMLog", "log", {
                            ["message"] = "decode url=" .. url
                        })
                    end
                end

                -- 这种格式少用
                local _, pos = url:find("native_forward%?")
                if pos ~= nil then
                    local queryString = string.sub(url, pos + 1, -1)
                    local props = parseQuery(queryString)
                    local pddType = props["type"]
                    if pddType ~= nil then
                        props["type"] = nil
                        Navigator.forward(Navigator.getTabIndex(), {
                            ["type"] = pddType,
                            ["props"] = props,
                            ["is_push"] = true

                        })
                    else
                        Navigator.forwardToNativeByURLFromPush(url)
                    end
                else
                    Navigator.forwardToNativeByURLFromPush(url)
                end
            end
        end

        -- 打个标记，这个时候有push页面不需要弹活动弹窗
        aimi.KVStorage.getInstance():set("LUA_HAS_PUSH_PAGE_FLAG_KEY" , "1")

        if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.35.0") then
            forwardPage(url, nativePageType)
        else 
            Navigator.dismissMask(function()
                Navigator.dismissModal(function()
                    forwardPage(url, nativePageType)
                end)
            end)
        end

        local msgType = payload["msg_type"]
        -- 本地通知的时候才有notification_id
        local notificationID = payload["notification_id"]
        if msgType ~= nil then
            Tracking.send("click", "app_push_msg_clk", {
                ["page_name"] = "global",
                ["page_element"] = "app_push_msg",
                ["msg_type"] = msgType
            })
        elseif notificationID ~= nil then
            Tracking.send("click", "", {
                ["page_section"] = "user_notification",
                ["page_el_sn"] = "99638",
                ["notification_id"] = notificationID,
                ["push_url"] = url
            })
        end
    end)

    if not FriendGray.isChatTabEnabled() then
        if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("2.6.0") then
            AMBridge.register(Event.ReceiveSocketMessage, function(payload)
                if payload == nil then
                    return
                end

                if payload["response"] ~= "unread_msg_count" or payload["result"] ~= "ok" then
                    return
                end

                local count = payload["count"] or 0
                local hasUnread = false
                if count > 0 then
                    hasUnread = true
                end

                if not FriendGray.isChatTabEnabled() then
                    TabBar.setBadgeVisible({
                        TabBar.Tabs.Personal,
                    }, {
                        hasUnread,
                    })
                end  
            end, function()
                AMBridge.call("PDDPushSocket", "send", {
                    ["cmd"] = "unread_msg_count",
                    ["page"] = 1,
                    ["size"] = 20,
                })
            end)
        else
            AMBridge.register(Event.ReceiveSocketMessage, function(payload)
                if payload == nil then
                    return
                end

                if payload["response"] ~= "latest_conversations" or payload["result"] ~= "ok" then
                    return
                end

                local conversations = payload["conversations"] or {}
                local hasUnread = false

                for _, conversation in ipairs(conversations) do
                    if conversation["status"] ~= "read" then
                        hasUnread = true
                        break
                    end
                end

                if not FriendGray.isChatTabEnabled() then
                    TabBar.setBadgeVisible({
                        TabBar.Tabs.Personal,
                    }, {
                        hasUnread,
                    })
                end  
            end, function()
                AMBridge.call("PDDSocket", "send", {
                    ["cmd"] = "latest_conversations",
                    ["page"] = 1,
                    ["size"] = 20,
                })
            end)
        end
    end


    -- Application.checkOverseaBadge()
end

function Application.reloadHomeScene()
    local HOME_SCENE_NAME = "scene/HomeScene"
    local HomeScene = require(HOME_SCENE_NAME)
    local homeScene = HomeScene.instance()

    package.loaded[HOME_SCENE_NAME] = nil
    HomeScene = require(HOME_SCENE_NAME)
    HomeScene.setInstance(homeScene)
end

function Application.reloadChatListScene()
    local CHAT_LIST_SCENE_NAME = "scene/ChatListScene"
    if FriendGray.isEnabled() == nil or FriendGray.isEnabled() == false then
        package.loaded[CHAT_LIST_SCENE_NAME] = nil
        return
    end  

    if package.loaded[CHAT_LIST_SCENE_NAME] == nil then
        return
    end

    local ChatListScene = require(CHAT_LIST_SCENE_NAME)
    local chatListScene = ChatListScene.instance()

    package.loaded[CHAT_LIST_SCENE_NAME] = nil
    ChatListScene = require(CHAT_LIST_SCENE_NAME)
    ChatListScene.setInstance(chatListScene)
end

function Application.reloadPersonalScene( )
    local PERSONAL_SCENE_NAME = "scene/PersonalScene"
    local PersonalScene = require(PERSONAL_SCENE_NAME)
    PersonalScene.setup()
end

function Application.reloadOrderScene( )
    local ORDER_SCENE_NAME = "scene/OrderScene"

    package.loaded[ORDER_SCENE_NAME] = nil
    require(ORDER_SCENE_NAME)
end

function Application.updateFavorite()
    AMBridge.call("PDDFavorite", "update", nil, nil)
end

function Application.clearGeneratedImageCache()
    if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.52.0") then
        return
    end

    AMBridge.call("PDDImage", "clearDisk", nil, nil)
end

function Application.checkOverseaBadge()
    if Version.new(aimi.Application.getApplicationVersion()) < Version.new("2.7.0") then
        return
    end

    if Activity.isActivityPeriod() then
        return
    end

    local HAITAO_UPDATED_TIME_KEY = "PDDHaitaoUpdateTime"
    local haitaoUpdatedTime = -1
    AMBridge.register(Event.PDDListUpdatedTimeNotification, function(payload)
        if payload ~= nil and payload["haitao"] ~= nil then
            haitaoUpdatedTime = payload["haitao"]
            local haitaoLastUpdatedTime = tonumber(aimi.KVStorage.getInstance():get(HAITAO_UPDATED_TIME_KEY))
            if haitaoUpdatedTime ~= haitaoLastUpdatedTime  then
                if not FriendGray.isChatTabEnabled() then
                    TabBar.setBadgeVisible({
                        TabBar.Tabs.Oversea,
                    }, {
                        true,
                    })
                end
            end
        end
    end)
    AMBridge.register(Event.PDDClearBadgeNotification, function(payload)
        if payload ~= nil and payload["key"] == "tabbar_haitao" then
            aimi.KVStorage.getInstance():set(HAITAO_UPDATED_TIME_KEY, json.encode(haitaoUpdatedTime))
        end
    end)
end


return Application
