local APIService = class("APIService")

local Network = require("base/Network")
local Promise = require("base/Promise")
local Version = require("base/Version")
local Config  = require("common/Config")


local function request(method, path, data)
    local headers = {}
    local accessToken = aimi.User.getAccessToken()

    if accessToken ~= nil and #accessToken > 0 then
        headers["AccessToken"] = accessToken
    end

    local url = Config.APIHost .. tostring(path)
    return Network.request(method, url, data, headers):next(function(response)
        local statusCode = response:getStatusCode()
        local responseData = response:getResponseData()

        return {
            statusCode = statusCode,
            responseString = responseData,
        }
    end)
end

local function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function requestJSONWithPDDNetwork(method, path, data)
    return Promise.new(function(resolve, reject)
                AMBridge.call("PDDNetwork", "request", {
                        ["method"] = method,
                        ["url"] = path,
                        ["data"] = data
                    }, function(responseError, response)
                        
                        if responseError ~= 0 then
                            print('----------------- PDDNetwork: ', path, "error:", responseError)
                            return reject(error("Response error: " .. tostring(responseError)))
                        end

                        if response.response ~= nil and #(response.response) > 0 then
                            response.responseString = string.decodeURI(response.response)
                        end

                        response.response = nil

                        if response.responseString == nil or #(response.responseString) <= 0 then
                            response.responseJSON = {}
                        else
                            response.responseJSON = json.decode(response.responseString)
                        end

                        if response.responseJSON == nil then
                            return reject(error("Response is not valid JSON"))
                        end

                        local errorCode = tonumber(response.responseJSON["error_code"])

                        print('----------------- PDDNetwork: ', path, "response: ", dump(response))

                        if errorCode ~= nil then
                            return reject(error("Response error: " .. tostring(errorCode)))
                        end


                        return resolve(response)
                end)
           end)
end

local function requestJSONWithAMNetwork(method, path, data)
    return request(method, path, data):next(function(response)
        if response.responseString == nil or #(response.responseString) <= 0 then
            response.responseJSON = {}
        else
            response.responseJSON = json.decode(response.responseString)
        end

        if response.responseJSON == nil then
            return error("Response is not valid JSON")
        end

        local errorCode = tonumber(response.responseJSON["error_code"])

        print('----------------- AMNetwork: ', path, "response: ", dump(response))

        if errorCode ~= nil then
            return error("Response error: " .. tostring(errorCode))
        end

        return response
    end)
end

local function requestJSON(method, path, data)
    if Version.new(aimi.Application.getApplicationVersion()) < Version.new("4.18.0") then
        return requestJSONWithAMNetwork(method, path, data)
    else
        return requestJSONWithPDDNetwork(method, path, data)
    end
end

function APIService.get(path)
    return request("GET", path)
end

function APIService.post(path, data)
    return request("POST", path, data)
end

function APIService.getJSON(path)
    return requestJSON("GET", path)
end

function APIService.getJSON(path, data)
    return requestJSON("GET", path, data)
end

function APIService.postJSON(path, data)
    return requestJSON("POST", path, data)
end


return APIService