table = table or {}


function table.get(instance, keys, default)
    if instance == nil then
        return default
    end

    if type(keys) == "string" then
        keys = { keys }
    end

    local value = nil

    for _, key in ipairs(keys) do
        value = instance[key]

        if value ~= nil then
            return value
        end
    end

    return default
end


return table