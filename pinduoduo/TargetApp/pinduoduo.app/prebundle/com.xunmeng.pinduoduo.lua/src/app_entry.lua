local componentName = "com.xunmeng.pinduoduo.lua"


local function updatePath(callback)
    AMBridge.call("AMComponent", "info", {
        ["name"] = componentName,
    }, function(error, response)
        local bundles = response["bundles"]
        local searchPaths = {}
        local mark = {}

        for i = #bundles, 1, -1 do
            local bundle = bundles[i] or {}
            local path = bundle["local_path"]

            if path ~= nil and not mark[path] then
                mark[path] = true
                table.insert(searchPaths, path .. "/src/?.lua")
            end
        end

        package.path = table.concat(searchPaths, ";")

        if callback ~= nil then
            callback()
        end
    end)
end

local function boot()
    updatePath(function()
        require("app_bridge")
        require("app_class")
        require("app_Version")
        require("app_aimi")
        print("start call [PDDMeta get]")
        AMBridge.call("PDDMeta", "get", nil, function(error, response)
            aimi.meta = response or {}
            require("app_tabbar")
            print("end call [PDDMeta get], start call TabBar.setup")
            TabBar.setup()
        end)
    end)
end


boot()