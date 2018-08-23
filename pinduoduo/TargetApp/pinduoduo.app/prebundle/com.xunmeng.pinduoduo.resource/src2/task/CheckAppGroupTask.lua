local CheckAppGroupTask = class("CheckAppGroupTask")

local Promise = require("base/Promise")

local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Tracking = require("common/Tracking")
local Utils = require("common/Utils")

local NEW_INSTALL_CHECK_APP_GROUP_FLAG_KEY = "LuaNewInstallCheckAppGroupFlag"

function CheckAppGroupTask.run(resolve, reject, isNewInstall)
    local newInstallCheckAppGroupFlag = tonumber(aimi.KVStorage.getInstance():get(NEW_INSTALL_CHECK_APP_GROUP_FLAG_KEY))
    if isNewInstall == true and checkAppGroupFlag ~= 1 then
        APIService.postJSON("app_group/track/match", {
            ["platform"] = "iOS",
            ["version"] = aimi.Device.getSystemVersion()
        }):next(function(response)
            return Promise.new(function(resolve, reject)
                if response ~= nil then
                    aimi.KVStorage.getInstance():set(NEW_INSTALL_CHECK_APP_GROUP_FLAG_KEY, tostring(newInstallCheckAppGroupFlag))
                    local match = response.responseJSON["is_match"]
                    if match ~= true then
                        return reject("No match app group, match is false")
                    end

                    local group = response.responseJSON["group"]
                    local groupOrderID = response.responseJSON["group_order_id"]
                    local confirm = response.responseJSON["confirm"]
                    local goods = response.responseJSON["goods"]

                    local forwardURL = nil
                    if group ~= nil and goods ~=nil and type(goods) == "table" then
                        forwardURL = Utils.buildURL("goods.html", goods)
                    elseif group ~= nil and groupOrderID ~= nil and #groupOrderID ~= 0 then
                        forwardURL = "group7.html?group_order_id=" .. tostring(groupOrderID)
                    end
                    
                    if forwardURL == nil then
                        return reject("No match app group, no valid group or goods info")
                    end

                    Navigator.mask({
                        ["type"] = "web",
                        ["props"] = {
                            ["url"] = "app_group.html",
                            ["opaque"] = false,
                            ["extra"] = {
                                ["group"] = group,
                                ["confirm"] = confirm,
                                ["complete"] = function(errorCode, response)
                                    Navigator.dismissMask()
                                    if response["confirmed"] == 0 then
                                        reject("User cancelled")
                                        Tracking.send("click", nil, {
                                            ["page"] = "index",
                                            ["click"] = "index_app_code_alert_cancel",
                                        })
                                    else
                                        resolve(forwardURL)
                                        Tracking.send("click", nil, {
                                            ["page"] = "index",
                                            ["click"] = "index_app_code_alert_confirm",
                                        })
                                    end
                                end,
                            },
                        },
                    }, function(errorCode)
                        if errorCode ~= 0 then
                            reject("Cannot show mask")
                        end
                    end)
                end
            end)
        end):next(function(forwardURL)
            if forwardURL ~= nil and #forwardURL > 0 then
                Navigator.forward(Navigator.getTabIndex(), {
                    ["type"] = "web",
                    ["props"] = {
                        ["url"] = forwardURL,
                    },
                }, function()
                    aimi.call(resolve)
                end)
            end
        end):catch(function(reason)
            print(reason)
            aimi.call(resolve)
        end)
    else
        aimi.call(resolve)
    end
end

return CheckAppGroupTask