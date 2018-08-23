local FriendGray = class("FriendGray")

local Promise = require("base/Promise")
local Version = require("base/Version")
local Event = require("common/Event")
local APIService = require("common/APIService")
local ComponentManager = require("common/ComponentManager")
local Config = require("common/Config")
local Utils = require("common/Utils")

function FriendGray.initialize(resolve, reject)

    AMBridge.register(Event.ApplicationResume, function()
        FriendGray.getGrayScaleFromServerIfNeeded()
    end)

    AMBridge.register(Event.UserLogin, function()
        FriendGray.getGrayScaleFromServerIfNeeded()
    end)

    AMBridge.register(Event.PDDUpdateGrayFeaturesNotification, function()
        FriendGray.getGrayScaleFromServerIfNeeded()
    end)

    FriendGray.initGrayFeature()
    FriendGray.getGrayScaleFromServerIfNeeded()
    
    Promise.all():next(resolve, reject)
end

function FriendGray.initGrayFeature()
    local isEnabled = FriendGray.isEnabled() and 1 or 0
    AMBridge.call("PDDABTest", "updateFriendFeature", {
            ["friend_feature"] = isEnabled
        }, function(errorCode, response)
    end)
end

function FriendGray.updateGrayFeature(isEnabled)
    if isEnabled ==  nil or isEnabled == false then
        isEnabled = 0
    else
        isEnabled = 1
    end

    local currentGrayValue = 0
    if FriendGray.isEnabled() == true then
        currentGrayValue = 1
    end

    print("currentGrayValue=",currentGrayValue,"isEnabled=",isEnabled)
    
    if  currentGrayValue ~= isEnabled then
        aimi.KVStorage.getInstance():set(TabBar.FriendChatEnableKey, (isEnabled == 1) and "1" or nil)
        AMBridge.call("PDDABTest", "updateFriendFeature", {
            ["friend_feature"] = isEnabled
        }, function(errorCode, response)
        end)
    end
end

function FriendGray.isChatTabEnabled()
    return FriendGray.isEnabled() or FriendGray.isMallTabEnabled()
end

function FriendGray.isEnabled()
    if not FriendGray.isDBPrepared() then
        return false
    end

    local enable = aimi.KVStorage.getInstance():get(TabBar.FriendChatEnableKey)
    if enable ~= nil then
        return true
    else
        return false
    end
end

function FriendGray.isMallTabEnabled()
    if  TabBar.MallChatEnableKey == nil then
        return false
    end

    local enable = aimi.KVStorage.getInstance():get(TabBar.MallChatEnableKey)
    if enable ~= nil then
        return true
    else
        return false
    end
end

function FriendGray.isDBPrepared()
    local failed = aimi.KVStorage.getInstance():get("PDDFriendRealmFailToPrepare")
    if failed == nil then
        return true
    else
        return false
    end
end

function FriendGray.applyGrayConfig(isWhite)
    local currentAppVersion = Version.new(aimi.Application.getApplicationVersion())
    if (currentAppVersion < Version.new("3.24.0")) then
        return
    end

    FriendGray.checkAndEnableMallTabIfNeeded()
    FriendGray.updateGrayFeature(isWhite)
end

function FriendGray.checkAndEnableMallTabIfNeeded()
    -- 老版本
    local currentAppVersion = Version.new(aimi.Application.getApplicationVersion())
    if (currentAppVersion < Version.new("3.24.0")) then
        return
    end

    -- 较老的boot包，回到海淘版本
    if TabBar.MallChatEnableKey == nil or currentAppVersion < Version.new("3.36.0") then
        if FriendGray.isEnabled() then
            TabBar.replace(false, function (errorCode)
                if errorCode == 0 or errorCode == nil then
                    FriendGray.updateGrayFeature(false)
                end
            end) 
        end
        return
    end

    -- 商家聊天Tab
    AMBridge.call("PDDABTest", "check", {
        ["name"] = "pdd_chat_tab"
    }, function(error, response)
        if response then
            local isEnabled = (response["is_enabled"] == 1)
            local barType = TabBar.Types.Haitao
            local shouldReplaceTab = false
            if isEnabled and (not FriendGray.isMallTabEnabled()) then
                barType = TabBar.Types.Mall
                shouldReplaceTab = true
            elseif (not isEnabled) and (FriendGray.isMallTabEnabled() or FriendGray.isEnabled()) then
                barType = TabBar.Types.Haitao
                shouldReplaceTab = true
            end

            if shouldReplaceTab then
                TabBar.replace(barType, function (errorCode)
                    if errorCode == 0 or errorCode == nil then
                        if barType == TabBar.Types.Mall then
                            aimi.KVStorage.getInstance():set(TabBar.MallChatEnableKey, "1")
                        else
                            aimi.KVStorage.getInstance():set(TabBar.MallChatEnableKey, nil)
                        end
                    end
                end) 
            end
        end       
    end)  
end

function FriendGray.getGrayScaleFromServerIfNeeded()
    local currentAppVersion = Version.new(aimi.Application.getApplicationVersion())
    if (currentAppVersion < Version.new("4.10.0")) then
        FriendGray.applyGrayConfig(false)
        return
    end
end

return FriendGray