local componentName = "com.xunmeng.pinduoduo.lua"

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

    require("bridge")
    require("tabbar")
    require("boot").run()
end)
