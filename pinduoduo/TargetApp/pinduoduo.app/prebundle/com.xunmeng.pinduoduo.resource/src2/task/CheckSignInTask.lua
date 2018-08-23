local CheckSignInTask = class("CheckSignInTask")
local Constant = require("common/Constant")

local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Version = require("base/Version")

local LAST_SHOW_SIGN_IN_KEY = "LuaLastShowSignInPopup"

function CheckSignInTask.run(resolve)
    print('---------------info:CheckSignInTask run-----------------------')
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken <= 0 then
        return aimi.call(resolve)
    end

    local today = os.date("*t", os.time()).day
    local lastDay = tonumber(aimi.KVStorage.getInstance():get(LAST_SHOW_SIGN_IN_KEY))

    if today == lastDay then
        return aimi.call(resolve)
    end

    -- check current visible page
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.50.0") and tostring(aimi.Navigator.getVisiblePage()) ~= "pdd_home" then
        return aimi.call(resolve)
    end

    local flag = tonumber(aimi.KVStorage.getInstance():get("pdd_sign_in_popup"))
    print("CheckSignInTask flag=",flag)
    if flag == nil or flag == 0 then
        return aimi.call(resolve)
    end

    local url = "api/amazon/rome/v5/home_window"
    APIService.getJSON(url):next(function(response)
        local showWindow = response.responseJSON["show_window"]
        print("showWindow=", showWindow)

        return Promise.new(function(resolve, reject)
            if not showWindow then
                return reject("Don't need show sigin in popup")
            end

            Navigator.mask({
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "app_daily_bonus_popup.html",
                    ["opaque"] = false,
                    ["extra"] = {
                        ["result"] = response.responseJSON,
                        ["complete"] = function(errorCode, response)
                            Navigator.dismissMask()
                            local confirmed = response["confirmed"]
                            if response["confirmed"] == 0 then
                                reject("User cancelled")
                            else
                                local forwardURL = "mkt_daily_bonus.html?refer_page_el_sn=98447"
                                resolve(forwardURL)
                            end
                        end,
                    },
                },
            }, function(errorCode)
                if errorCode == 0 then
                    aimi.KVStorage.getInstance():set(LAST_SHOW_SIGN_IN_KEY, tostring(today))
                else
                    reject("Cannot show mask")
                end
            end)
        end)
    end):next(function(forwardURL)
        if forwardURL ~= nil and #forwardURL > 0 then
            Navigator.forward(Navigator.getTabIndex(), {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = forwardURL,
                },
                ["transient_refer_page_context"] = {
                    ["page_el_sn"] = "98447"
                }
            }, function()
                aimi.call(resolve)
            end)
        end
    end):catch(function()
        aimi.call(resolve)
    end)
end

function CheckSignInTask.reset()
    aimi.KVStorage.getInstance():set(LAST_SHOW_SIGN_IN_KEY, nil)
end

return CheckSignInTask
