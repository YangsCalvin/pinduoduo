local BaseScene = class("BaseScene", function()
    return aimi.Scene.create()
end)


function BaseScene:constructor(props, tabIndex, contextID)
    self.tabIndex_ = tabIndex or 0
    self.contextID_ = contextID or 0
    self:registerSceneEvents()
end

function BaseScene:getTabIndex()
    return self.tabIndex_
end

function BaseScene:getContextID()
    return self.contextID_
end

function BaseScene:registerSceneEvents()
    self:registerEventListener("sceneWillAppear", function(...)
        if self.sceneWillAppear ~= nil then
            self.sceneWillAppear(self, ...)
        end
    end)
    self:registerEventListener("sceneDidAppear", function(...)
        if self.sceneDidAppear ~= nil then
            self.sceneDidAppear(self, ...)
        end
    end)
    self:registerEventListener("sceneWillDisappear", function(...)
        if self.sceneWillDisappear ~= nil then
            self.sceneWillDisappear(self, ...)
        end
    end)
    self:registerEventListener("sceneDidDisappear", function(...)
        if self.sceneDidDisappear ~= nil then
            self.sceneDidDisappear(self, ...)
        end
    end)
end


return BaseScene