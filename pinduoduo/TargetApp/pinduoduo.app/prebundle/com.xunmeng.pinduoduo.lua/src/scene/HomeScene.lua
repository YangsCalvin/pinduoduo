local HomeScene = class("HomeScene", function()
    return aimi.Scene.create()
end)


function HomeScene.instance()
    if HomeScene.instance_ == nil then
        return {
            getContextID = function()
            end
        }
    else
        return HomeScene.instance_
    end
end

function HomeScene:constructor(props, tabIndex, contextID)
    self.tabIndex_ = tabIdex or 0
    self.contextID_ = contextID or 0

    if HomeScene.instance_ == nil then
        HomeScene.instance_ = self
    end
end

function HomeScene:getContextID()
    return self.contextID_
end


return HomeScene
