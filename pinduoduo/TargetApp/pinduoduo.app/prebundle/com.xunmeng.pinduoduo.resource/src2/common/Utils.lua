local Utils = Utils or {}


function Utils.buildURL(urlString, ...)
    local paramList = { ... }
    local params = {}

    for _, paramItem in ipairs(paramList) do
        if type(paramItem) == "table" then
            for key, value in pairs(paramItem) do
                params[tostring(key)] = value
            end
        end
    end

    local count = 0
    local tokens = {}

    for key, value in pairs(params) do
        count = count + 1
        table.insert(tokens, string.format("%s=%s", key, tostring(value)))
    end

    if count <= 0 then
        return urlString
    end

    if urlString:find("?") == nil then
        return urlString .. "?" .. table.concat(tokens, "&")
    else
        return urlString .. "&" .. table.concat(tokens, "&")
    end
end


function Utils.parseQueryFromURL(url)
    local url = tostring(url or '')

    local function parseQuery(query)
        if query == nil or #query == 0 then
            return
        end

        local props = {}
        for key, val in query:gmatch(string.format('([^%q]+)=([^%q]*)', '&', '&')) do
            props[key] = val
        end

        return props
    end

    local _, pos = string.find(url, '?')

    if pos ~= nil then
        local query = string.sub(url, pos + 1, -1)
        return parseQuery(query)
    end
end

function Utils.mergeTable(targetTable, sourceTable)
    if type(targetTable) ~= "table" then
        return
    end
    if type(sourceTable) ~= "table" then
        return targetTable
    end
    for key, value in pairs(sourceTable) do
        targetTable[key] = value
    end
    return targetTable
end

return Utils