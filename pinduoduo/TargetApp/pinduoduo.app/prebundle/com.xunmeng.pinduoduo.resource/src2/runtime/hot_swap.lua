HotSwap = class("HotSwap")

local Event = require("common/Event")

function HotSwap.get()
    if HotSwap.instance_ == nil then
        HotSwap.instance_ = HotSwap.new()
    end

    return HotSwap.instance_
end


function HotSwap:constructor()
    self.skips_ = {}
end

function HotSwap:setup()
    if self.hasSetup_ then
        return
    else
        self.hasSetup_ = true
    end

    for key, _ in pairs(package.loaded) do
        self.skips_[key] = true
    end
end

function HotSwap:run()
    if self ~= HotSwap.get() then
        return
    end

    -- local modules = {}
    -- for key, _ in pairs(package.loaded) do
    --     if not self.skips_[key] then
    --         modules[key] = true
    --     end
    -- end

    -- local filePath = debug.getinfo(2, "S").source:sub(2)
    -- AMBridge.call("PDDABTest", "check", {
    --     ["name"] = "pdd_lua_hot_swap",
    --     ["default_value"] = 0
    -- }, function (error, response)
    --     if response then
    --         local enabled = response["is_enabled"]
    --         if type(enabled) == "number" and enabled == 1 then
    --             local hotSwapImplPath = "runtime/lua_hot_swap_impl"
    --             package.loaded[hotSwapImplPath] = nil
    --             local HotSwapImpl = require(hotSwapImplPath)

    --             local componentsPath = filePath:match("(.*/Components/)")
    --             if componentsPath ~= nil and #componentsPath > 0 then
    --                 local destFilePath = componentsPath .. "com.xunmeng.pinduoduo.resource/src2/"
    --                 print("will start hot swap at path", destFilePath)

    --                 HotSwapImpl.Init("runtime/hot_swap_file_list", destFilePath, AMBridge.error)
    --                 HotSwapImpl.Update()

    --                 AMBridge.message(Event.LuaHotSwapped, {})
    --             end
    --         else
    --             print("hot swap doesn't enabled")
    --         end
    --     end
    -- end)
end

return HotSwap