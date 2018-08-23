local Activity = class("Activity")

local Promise = require("base/Promise")
local Version = require("base/Version")

local Event = require("common/Event")
local Navigator = require("common/Navigator")
local APIService = require("common/APIService")
local ComponentManager = require("common/ComponentManager")

local LAST_ACTIVITY_BANNER_IMAGE_URL = "LuaLastActivityBannerImageURL"
local LAST_ACTIVITY_BANNER_IMAGE_HEIGHT_KEY = "LuaLastActivityBannerImageHeight" 
local LAST_ACTIVITY_BANNER_IMAGE_WIDTH_KEY = "LuaLastActivityBannerImageWidth"

local LAST_ACTIVITY_BUTTON_IMAGE_URL = "LuaLastActivityButtonImageURL"

function Activity.startTime()
    return os.time{year=2018, month=6, day=8, hour=0, min=0, sec=0}
end

function Activity.endTime()
    return os.time{year=2018, month=6, day=20, hour=23, min=59, sec=59}
end

function Activity.activityURL()
    local now = os.time()
    if Activity.isActivityPeriod() then
        return "promotion.html?type=1&id=58"
    else
        return "subject.html?subject_id=947"
    end
end


function Activity.activityPopupURL()
    return "app_act_promo_popup.html"
end

function Activity.isActivityPeriod()
    local now = os.time()
    if now > Activity.startTime() and now < Activity.endTime() then
        return true
    else
        return false
    end
end


function Activity.fetchData()
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.9.0") then
        print('--------------fetch acivity data, new version return------------------')
        return;
    end

    print('--------------fetch acivity data------------------')
    if not Activity.isActivityPeriod() then
        Activity.resetActivity()
        print('--------------fetch acivity data, not send request------------------')
        return
    end

    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/carnival/image_list?types[]=home_banner&types[]=floating_window"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        if response ~= nil and response.responseJSON ~= nil then
            local carnivalImages = response.responseJSON["carnival_images"]

            local needSetActivity = true;
            xpcall(function()
                if type(Activity.lastCarnivalImages_) == "table" and tostring(json.encode(Activity.lastCarnivalImages_)) == tostring(json.encode(carnivalImages)) then
                    print("carnival images equals, will not reset activity, Activity.lastCarnivalImages_=",Activity.lastCarnivalImages_,tostring(json.encode(carnivalImages)))
                    needSetActivity = false
                else
                    print("carnival images not equals, need reset activity")
                    Activity.lastCarnivalImages_ = carnivalImages
                end
            end, AMBridge.error)

            for _, v in ipairs(carnivalImages) do
                if v ~= nil then
                    local imageType = v["type"]
                    local imageUrl = v["image_url"]
                    if imageType == "home_banner" and imageUrl ~= nil and #imageUrl > 0 then
                        local height = v["height"]
                        local width = v["width"]
                        print('height=',height,"type=",type(height),"width=",width,"typ=",type(width))
                        -- 之前的版本加载gif banner会白屏，这里放置兜底图片
                        if  (Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.42.0")) and imageUrl:find("%.gif$") then
                            imageUrl = ""
                        end

                        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BANNER_IMAGE_URL, imageUrl)
                        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BANNER_IMAGE_WIDTH_KEY, width)
                        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BANNER_IMAGE_HEIGHT_KEY, height)
                        Activity.banner_ = Activity.bannerByImageUrl(imageUrl, tonumber(width), tonumber(height))
                    elseif imageType == "floating_window" and imageUrl ~= nil and #imageUrl > 0 then
                        Activity.button_ = Activity.buttonByImageUrl(imageUrl)
                        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BUTTON_IMAGE_URL, imageUrl)
                    end
                end
            end

            if needSetActivity then
                Activity.resetActivity()
            end
        end
    end)
end

function Activity.bannerByImageUrl(bannerUrl, width, height)
    if bannerUrl == nil or #bannerUrl == 0 then
        return nil
    end

    if type(width) ~= "number" or width == 0 then
        return nil
    end

    if type(height) ~= "number" or height == 0 then
        return nil
    end

    local activityBanner = {
        ["imgUrl"] = bannerUrl,
        ["width"] = width,
        ["height"] = height,
        ["forwardURL"] = Activity.activityURL(),
        ["onClick"] = function()
            Navigator.forward(Navigator.getTabIndex(), {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = Activity.activityURL(),
                },
                ["transient_refer_page_context"] = {
                    ["page_element"] = "campaign_banner"
                }
            })
        end,
    }

    return activityBanner
end

function Activity.banner()
    if not Activity.isActivityPeriod() then
        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BANNER_IMAGE_URL, "")
        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BANNER_IMAGE_WIDTH_KEY, "")
        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BANNER_IMAGE_HEIGHT_KEY, "")
    end

    if Activity.banner_ == nil then
        local bannerUrlFromCache = aimi.KVStorage.getInstance():get(LAST_ACTIVITY_BANNER_IMAGE_URL)
        local bannerImageHeight = aimi.KVStorage.getInstance():get(LAST_ACTIVITY_BANNER_IMAGE_HEIGHT_KEY)
        local bannerImageWidth = aimi.KVStorage.getInstance():get(LAST_ACTIVITY_BANNER_IMAGE_WIDTH_KEY)
        return Activity.bannerByImageUrl(bannerUrlFromCache, tonumber(bannerImageWidth), tonumber(bannerImageHeight))
    end

    return Activity.banner_
end

function Activity.buttonByImageUrl(buttonUrl)
    if buttonUrl == nil or #buttonUrl == 0 then
        return nil
    end

    local model = ""
    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.27.0") then
        model = aimi.Device.getModel()
    end

    local bottom2 = (model == "iPhone10,3" or model == "iPhone10,6") and 159 or 125
    local activityButton = {
        ["imgUrl"] = buttonUrl,
        ["width"] = 70,
        ["height"] = 60,
        ["right"] = 0,
        ["bottom"] = 61,
        ["bottom2"] = bottom2,
        ["onClick"] = function()
            Navigator.forward(Navigator.getTabIndex(), {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = Activity.activityURL(),
                },
                ["transient_refer_page_context"] = {
                    ["page_element"] = "floating_window"
                }
            })
        end,
    }
    return activityButton
end

function Activity.button()
    if not Activity.isActivityPeriod()then
        aimi.KVStorage.getInstance():set(LAST_ACTIVITY_BUTTON_IMAGE_URL, "")
    end

    if Activity.button_ == nil then
        local buttonUrlFromCache = aimi.KVStorage.getInstance():get(LAST_ACTIVITY_BUTTON_IMAGE_URL)
        return Activity.buttonByImageUrl(buttonUrlFromCache)
    end

    return Activity.button_
end

function Activity.resetActivity()
    local activity = {
        ["activity_period"] = {
            ["start_time"] = Activity.startTime(),
            ["end_time"] = Activity.endTime()
        },
        ["activity_banner"] = Activity.banner(),
        ["activity_button"] = Activity.button(),
        ["show_activity_splash"] = 0,
        ["sync_time"] = 0
    }
    AMBridge.call("PDDActivity", "set", activity, function(errorCode, response)
    end)
end

return Activity
