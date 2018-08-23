AMBridge = AMBridge or {}


function AMBridge.error(message)
    print("----------------------------------------")
    print("Lua Error: " .. tostring(message))
    print(debug.traceback("", 2))
    print("----------------------------------------")
end


return AMBridge