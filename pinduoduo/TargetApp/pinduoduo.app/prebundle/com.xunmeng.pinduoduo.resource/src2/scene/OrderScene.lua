
local OrderScene = class("OrderScene")

local errorCodeKey = "error_code"
local errorMsgkey = "error_msg"

local EventType = {
    DEFAULT = 0,
    LUCKY_DRAW = 1,
    SPIKE = 2,
    TZMD = 3,
    GET_EXTRA_FOR_FREE = 4,
    SUPER_SPIKE = 5,
    NEW_USER_GROUP = 6,
    FREE_TRIAL = 7,
    CAPITAL_GIFT = 8,
    CAPITAL_GIFT_LOTTERY = 9,
    YYHG = 10,
    Deposit_Group = 11
}

local GoodsType = {
    DEFAULT = 1,
    IMPORTS = 2,
    OVERSEAS_TRANSSHIP = 3,
    OVERSEAS_DM = 4,
    MOBILE_DATA = 5,
    MOBILE_FARE = 6,
    TRADE_COUPON = 7
}

function OrderScene.supportedPays( payload )
	print("----------- call supported pays")

	local goodsType = payload["goods_type"]
	local eventType = payload["event_type"]
	local pays = payload["pays"]

	if goodsType == nil or eventType == nil or pays == nil then
		return {
			[errorCodeKey] = 60000,
			[errorMsgkey] = "Invalid parameter"
		}
	end

	-- Below is for test, pleas rewrite it necessary
	local oneYuanEventType = "10"
	if eventType == oneYuanEventType and #pays > 0 then
		table.remove(pays, 1)
	end

	return pays
end


function OrderScene.unsupportedAutoCreateGroupEventTypes( payload )
	return {EventType.TZMD, EventType.CAPITAL_GIFT, EventType.CAPITAL_GIFT_LOTTERY, EventType.YYHG, EventType.SPIKE}
end

AMBridgeModule.export("OrderScene", "supportedPays", OrderScene.supportedPays)
AMBridgeModule.export("OrderScene", "unsupportedAutoCreateGroupEventTypes", OrderScene.unsupportedAutoCreateGroupEventTypes)

return OrderScene