local Network = class("Network")

local Promise = require("base/Promise")


function Network.request(method, url, data, headers)
    if Promise == nil then
        return
    end

    return Promise.new(function(resolve, reject)
        local request = aimi.HTTPRequest.create(url)

        request:setMethod(method)

        if type(data) == "table" then
            request:setBody(json.encode(data))
            request:setHeader("Content-Type", "application/json;charset=UTF-8")
        elseif data ~= nil then
            request:setBody(data)
        end

        if type(headers) == "table" then
            for key, value in pairs(headers) do
                request:setHeader(key, value)
            end
        end

        aimi.HTTPRequestOperation.create(request, function(errorCode, response)
            if errorCode == 0 then
                resolve(response)
            else
                reject("Network failure: " .. tostring(errorCode))
            end
        end):start()
    end)
end


return Network