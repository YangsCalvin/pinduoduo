local ChatListScene = class("ChatListScene", function()
    return aimi.Scene.create()
end)


function ChatListScene.instance()
    if ChatListScene.instance_ == nil then
        return {
            getContextID = function()
            end
        }
    else
        return ChatListScene.instance_
    end
end

function ChatListScene:constructor(props, tabIndex, contextID)
    self.tabIndex_ = tabIdex or 0
    self.contextID_ = contextID or 0

    if ChatListScene.instance_ == nil then
        ChatListScene.instance_ = self
    end
end

function ChatListScene:getContextID()
    return self.contextID_
end


return ChatListScene