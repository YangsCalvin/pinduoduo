-- export module to native

AMBridgeModule = AMBridgeModule or {}


local moduleHandlers = {}

local errorCodeKey = "error_code"
local errorMsgkey = "error_msg"
local responseKey = "response"


function AMBridgeModule.call(payload)

	-- print("------- call AMBridgeModule", payload["moduleName"], payload["methodName"])
	
	local moduleName = payload["moduleName"]
	local methodName = payload["methodName"]
	local parameters = payload["parameters"]

	if moduleName == nil or methodName == nil then
		local errorMsg = "module("..moduleName..") method("..methodName..") should not be nil"
		return {
			[errorCodeKey] = 61003,
			[errorMsgkey] = errorMsg
		}
	end

	if moduleHandlers[moduleName] == nil or moduleHandlers[moduleName][methodName] == nil then
		local errorMsg = "could not find handler for "..moduleName.."."..methodName
		return {
			[errorCodeKey] = 61004,
			[errorMsgkey] = errorMsg
		}
	end

	local handler = moduleHandlers[moduleName][methodName]

	
	local result = handler(parameters)
	if result then

		if type(result) == 'table' and result[errorCodeKey] ~= nil then
			return result
		else
			return {
				[responseKey] = result
			}
	end
end

	return {}
end


function AMBridgeModule.export(moduleName, methodName, handler)
	if moduleName == nil or #moduleName <= 0 or methodName == nil or #methodName <=0 or handler == nil then
        return
    end

    if moduleHandlers[moduleName] == nil then
    	moduleHandlers[moduleName] = {}
    end

    moduleHandlers[moduleName][methodName] = handler
end

return AMBridgeModule