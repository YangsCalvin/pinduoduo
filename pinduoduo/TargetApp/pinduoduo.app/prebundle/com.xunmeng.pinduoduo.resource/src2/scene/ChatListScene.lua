local BaseScene = require("scene/BaseScene")
local ChatListScene = class("ChatListScene", BaseScene)

local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Utils = require("common/Utils")
local ComponentManager = require("common/ComponentManager")
local Event = require("common/Event")
local Navigator = require("common/Navigator")
local Activity = require("common/Activity")

local Version = require("base/Version")

function ChatListScene:constructor(props, tabIndex, contextID)
    self.tabIndex_ = tabIdex or 0
    self.contextID_ = contextID or 0

    if ChatListScene.instance_ == nil then
        ChatListScene.instance_ = self
    end
end

function ChatListScene.instance()
    return ChatListScene.instance_
end

function ChatListScene.setInstance(instance)
    if instance == nil or ChatListScene.instance_ ~= nil then
        return
    end

    for key, value in pairs(ChatListScene) do
        instance[key] = value
    end

    instance.__class = ChatListScene
    ChatListScene.instance_ = instance

    instance:registerBridgeEvents()
    instance:registerSceneEvents()
end

function ChatListScene:registerBridgeEvents()
    AMBridge.register(Event.ApplicationResume, function()
    end)

    AMBridge.register(Event.UserLogin, function()
    end)

    AMBridge.register(Event.UserLogout, function()
    end)
end

function ChatListScene:sceneWillAppear()
end

function ChatListScene:sceneDidAppear()
end

return ChatListScene