local BaseScene = require("scene/BaseScene")
local HomeScene = class("HomeScene", BaseScene)

local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Utils = require("common/Utils")
local ComponentManager = require("common/ComponentManager")
local Event = require("common/Event")
local Navigator = require("common/Navigator")
local Activity = require("common/Activity")
local Constant = require("common/Constant")
local MD5 = require("common/MD5")
local FriendGray = require("common/FriendGray")

local CheckMarketActivityTask = require("task/CheckMarketActivityTask")
local CheckAssistFreeCouponTask = require("task/CheckAssistFreeCouponTask")
local CheckUnpaidOrderTask = require("task/CheckUnpaidOrderTask")
local CheckCashCouponTask = require("task/CheckCashCouponTask")
local Version = require("base/Version")
local FriendGray = require("common/FriendGray")
local CheckAppActivityTask = require("task/CheckAppActivityTask")
local CheckSignInTask = require("task/CheckSignInTask")
local CheckCommonActivityTaskV2 = require("task/CheckCommonActivityTaskV2")

local LAST_VIEW_FLAG_KEY = "LastViewQuickEntranceFlag"
local LAST_VIEW_UPDATED_TIME_KEY = "LastViewQuickEntranceUpdatedTime"

 
local INDEX_SUPER_SPIKE_KEY ="index_super_spike"
local INDEX_SPIKE_KEY = "index_spike"
local ECONOMICAL_BRAND_KEY = "economical_brand"
local CHARGE_CENTER_KEY = "charge_center"
local ASSIST_FREE_COUPON_KEY = "assist_free_coupon"
local SIGN_KEY = "attendance"
local COMMERCIAL_BARGAIN_LIST_KEY = "commercial_bargain_list"
local ROULETTE_KEY = "roulette"
local LUCKY_BAG_KEY = "lucky_bag"
local BROWSE_AD_KEY = "browse_ad"

local RESTRICTED_USER_FLAG_KEY = "RESTRICTED_USER_FLAG"
local USER_EGRP_KEY = "LUA_USER_EGRP"
local RED_PACKET_QUESTION_FLAG_KEY = "LUA_RED_PACKET_QUESTION_FLAG"
local NEW_CUSTOMER_FLAG_KEY= "LUA_NEW_CUSTOMER_FLAG"
local SIGN_IN_ENTRY_FLAG_KEY = "LUA_SIGN_IN_ENTRY_FLAG"
local ASSIST_FREE_COUPON_FLAG_KEY = "LUA_ASSIST_FREE_COUPON_FLAG"
local TWELEVE_ICON_FLAG_KEY = "LUA_TWELEVE_ICON_FLAG_KEY"
local NEW_SIGN_IN_SHOW_FLAG_KEY = "LUA_NEW_SIGN_IN_SHOW_FLAG"

local HOME_ICONS_SIGN_IN_TODAY_FLAG_KEY = "LUA_SIGN_IN_TODAY_FLAG"
local HOME_ICONS_SIGN_IN_REWARD_NUMBER_NUMBER_FLAG_KEY = "LUA_SIGN_IN_REWARD_NUMBER_NUMBER_FLAG"
local HOME_ICONS_LUCKY_BAG_NUMBER_FLAG_KEY = "HOME_ICONS_LUCKY_BAG_NUMBER_FLAG"
local HOME_ICONS_MONEY_TREE_NUMBER_FLAG_KEY = "HOME_ICONS_Money_Tree_NUMBER_FLAG_KEY"

local NEW_HOME_VERSION = Version.new("2.7.0")
local NEW_HOME_TEN_ICONS_VERSION = Version.new("3.3.0")
local NEW_HOME_ENTRANCE_SUPPORT_SIDESLIP_VERSION = Version.new("3.23.0")
local TWELEVE_ICONS_VERSION = Version.new("3.34.0")
-- 新人礼包
local NEW_HOME_ENTRANCE_SUPPORT_NEW_CUSTOMER = Version.new("3.27.0")
-- icons大小作了调整
local NEW_HOME_ENTRANCE_ICONS = Version.new("3.31.0")
-- icons的GIF图加载做了优化，支持非均匀的动画，3.42.0版本生效
local NEW_HOME_ENTRANCE_ICONS_GIF = Version.new("3.42.0")
-- 首页顶部标签（家居、母婴、电器）改版
local HOME_ICONS_WITH_NEW_OPT_UI = Version.new("3.50.0")
-- 后端配置icon图
local HOME_ICONS_SERVER_CONFIG = Version.new("3.66.0")

local HOME_ACTIVITY_INTEGRATION_START_TIME = os.time{year=2018, month=1, day=15, hour=0, min=0, sec=0}
local HOME_ACTIVITY_INTEGRATION_END_TIME = os.time{year=2018, month=1, day=21, hour=23, min=59, sec=59}

local HOME_SERVER_ICONS_CACHE_KEY = "LUA_HOME_SERVER_ICONS_CACHE"

function HomeScene.instance()
    return HomeScene.instance_
end

function HomeScene.setInstance(instance)
    math.randomseed(os.time())
    if instance == nil or HomeScene.instance_ ~= nil then
        return
    end

    for key, value in pairs(HomeScene) do
        instance[key] = value
    end

    instance.__class = HomeScene
    HomeScene.instance_ = instance
    instance:replaceSearchTab()
    instance:loadNewSignInFlag()
    instance:loadSignInEntryFlag()
    instance:loadBrowseAdIconFlag()
    instance:loadRestrictedUserFlag()
    instance:loadUserEgrp()
    instance:loadSignIconStatus()
    instance:loadLuckyBagIconStatus()
    instance:loadMoneyTreeIconStatus()
    instance:loadFlagByKeyWithValue("pdd_home_icon_config", 1)
    instance:loadFlagByKeyWithValue("pdd_bargin_expose_number", 0)
    instance:setFlag("pdd_bargin_expose_number", instance.flags_["pdd_bargin_expose_number"] + 1)


    instance:setActivity(Activity.isActivityPeriod())
    instance:fillMenuTitleData()
    instance:updateMenuTitles()

    instance:fillQuickEntranceData()

    instance:registerBridgeEvents()
    instance:registerSceneEvents()

    instance:loadQuickEntranceRelated()
    instance:setQuickEntranceDirty(true)
    instance:updateQuickEntrances()

    -- Must update entrance after entrace data has already set
    AMBridge.register(Event.PDDUpdateGrayFeaturesNotification, function (payload)
        print('-----------------gray feature updated')
        instance:updateFlagByKey("pdd_home_icon_config", "pdd_home_icon_config")
        instance:fetchHomeIconList()
        instance:fetchSignIconsStatus()
        instance:fetchBrowseAdIconFlag()
        instance:fetchLuckyBagIconsStatus()
        instance:fetchMoneyTreeIconsStatus()
    end)

    AMBridge.register(Event.PDDListUpdatedTimeNotification, function(payload)
        print("update home icons")
        instance:updateFlagByKey("pdd_home_icon_config", "pdd_home_icon_config")
        instance:fetchSignIconsStatus()
        instance:fetchLuckyBagIconsStatus()
        instance:fetchMoneyTreeIconsStatus()
        instance:fetchBrowseAdIconFlag()
        Activity.fetchData()
        instance:fetchHomeIconList()
        instance:setQuickEntranceDirty(true)
        instance:updateQuickEntrances()
    end)

    -- AMBridge.register(Event.LuaHotSwapped, function(payload)
    --     for key, value in pairs(HomeScene) do
    --         instance[key] = value
    --     end

    --     instance:setQuickEntranceDirty(true)
    --     instance:updateQuickEntrances()

    --     AMBridge.error("hot swap HomeScene instance functions success")
    -- end)

    --instance:getHomeIconList()
    instance:checkUser()

    instance:loadBootInfo()
    instance:addTaskToQueue()
end

function HomeScene:replaceSearchTab()
    local appVersion = aimi.Application.getApplicationVersion()
    if Version.new(appVersion) >= Version.new("3.47.0") then
        AMBridge.call("AMLog", "log", {
            ["message"] = os.date("[%Y%m%d%H%M%S]") .. "call replace search tab"
        })

        TabBar.replace(nil, function (errorCode)
            print('replace search errorCode=',errorCode)
        end)
    end
end

function HomeScene:fillMenuTitleData()
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_VERSION then
        return
    end

    if HomeScene.MenuTitle ~= nil then
        return
    end

    local categoryType = (Version.new(aimi.Application.getApplicationVersion()) < Version.new("2.14.0")) and "pdd_child_category" or "pdd_home_category"
    HomeScene.MenuTitle = {}
    HomeScene.MenuTitle.Recommend = {
        ["title"] = "热点",
        ["type"] = "pdd_home_recommend",
        ["props"] = {
            ["quick_entrances_each_row"] = 5
        }
    }
    HomeScene.MenuTitle.Clothes = {
        ["title"] = "服饰",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "14",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.Household = {
        ["title"] = "家居",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "15",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.Food = {
        ["title"] = "美食",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "1",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.DigitalAppliances = {
        ["title"] = "电器",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "18",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.Textile = {
        ["title"] = "家纺",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "818",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.Fruits = {
        ["title"] = "水果",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "13",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.Maternity = {
        ["title"] = "母婴",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "4",
            ["category_type"] = "1"
        }
    }
    HomeScene.MenuTitle.Cosmetics = {
        ["title"] = "美妆",
        ["type"] = categoryType,
        ["props"] = {
            ["category_id"] = "16",
            ["category_type"] = "1"
        }
    }
end

function HomeScene:fillQuickEntranceData()
    if HomeScene.QuickEntrance ~= nil then
        return
    end

    local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    local function tryRemoveQuickEntranceBadge(entrance)
        if entrance == nil or entrance["tipUrl"] == nil then
            return
        else
            entrance["tipUrl"] = nil
        end

        local key = entrance["key"]
        if key == SIGN_KEY then
            return
        end

        self:updateLastViewQuickEntranceFlags(key)
        self:setQuickEntranceDirty(true)
        self:updateQuickEntrances()
    end

    local function getPageReference(entrance)
        if entrance == nil or entrance["pageElSn"] == nil then
            return {}
        end
        local pageReference = {
            ["page_el_sn"] = entrance["pageElSn"] or "",
            ["page_sn"] = "10002",
        }
        return pageReference
    end

    --old home
    HomeScene.QuickEntrance = {}
    HomeScene.QuickEntrance.Spike = {
        ["name"] = "秒杀",
        ["imgUrl"] =  host .. "image/spike.png",
        ["badge"] = host .. "image/activity_new_tip.png",
        ["key"] =  "index_spike",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.Spike)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "spike.html",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.Bargain = {
        ["name"] =  "9块9特卖",
        ["imgUrl"] =  host .. "image/bargain.png",
        ["badge"] = host .. "image/activity_new_tip.png",
        ["key"] =  "index_bargain",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.Bargain)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "subject.html?promotion_type=spec99",
                    ["subject_id"] = "384",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.OneYuanBuy = {
        ["name"] =  "一元购",
        ["imgUrl"] =  host .. "image/one_yuan_buy.png",
        ["badge"] = host .. "image/activity_new_tip.png",
        ["key"] =  "one_yuan_buy",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.OneYuanBuy)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "subject.html?subject_id=452",
                    ["subject_id"] = "452",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.Lottery = {
        ["name"] =  "抽奖",
        ["imgUrl"] =  host .. "image/lottery.png",
        ["badge"] = host .. "image/activity_new_tip.png",
        ["key"] =  "index_lottery",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.Lottery)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "lottery.html",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.FreeTrial = {
        ["name"] =  "免费试用团",
        ["imgUrl"] =  host .. "image/free_trial.png",
        ["badge"] = host .. "image/activity_free_tip.png",
        ["key"] =  "index_free_trial",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.FreeTrial)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "free_trial_page.html",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.SuperSpike = {
        ["name"] =  "超值大牌",
        ["imgUrl"] =  host .. "image/super_spike.png",
        ["badge"] = host .. "image/activity_hot_tip.png",
        ["key"] =  INDEX_SUPER_SPIKE_KEY,
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.SuperSpike)
            Navigator.forward(0, {
                ["type"] = "superbrand",
            })
        end,
    }
    HomeScene.QuickEntrance.Food = {
        ["name"] =  "食品",
        ["imgUrl"] =  host .. "image/cat_2.png",
        ["key"] =  "index_cat_2",
        ["onClick"] = function()
            Navigator.forward(0, {
                ["type"] = "pdd_category",
                ["props"] = {
                    ["category_id"] = "1",
                    ["category_type"] = "1",
                    ["category_name"] = "食品",
                    ["url"] = "catgoods.html?opt_id=1&opt_type=1&all=true",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.Clothes = {
        ["name"] =  "服饰箱包",
        ["imgUrl"] =  host .. "image/cat_1.png",
        ["key"] =  "index_cat_1",
        ["onClick"] = function()
            Navigator.forward(0, {
                ["type"] = "pdd_category",
                ["props"] = {
                    ["category_id"] = "14",
                    ["category_type"] = "1",
                    ["category_name"] = "服饰箱包",
                    ["url"] = "catgoods.html?opt_id=14&opt_type=1&all=true",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.Household = {
        ["name"] =  "家居生活",
        ["imgUrl"] =  host .. "image/cat_3.png",
        ["key"] =  "index_cat_3",
        ["onClick"] = function()
            Navigator.forward(0, {
                ["type"] = "pdd_category",
                ["props"] = {
                    ["category_id"] = "15",
                    ["category_type"] = "1",
                    ["category_name"] = "家居生活",
                    ["url"] = "catgoods.html?opt_id=15&opt_type=1&all=true",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.DigitalAppliances = {
        ["name"] =  "数码电器",
        ["imgUrl"] =  host .. "image/digital_appliances.png",
        ["key"] =  "index_cat_3",
        ["onClick"] = function()
            AMBridge.call("AMNavigator", "forward", {
                ["type"] = "pdd_category",
                ["props"] = {
                    ["category_id"] = "18",
                    ["category_type"] = "1",
                    ["category_name"] = "数码电器",
                    ["url"] = "catgoods.html?opt_id=18&opt_type=1&all=true",
                },
            }, nil, HomeScene.instance():getContextID())
        end,
    }
    HomeScene.QuickEntrance.Maternity = {
        ["name"] =  "母婴",
        ["imgUrl"] =  host .. "image/cat_77.png",
        ["key"] =  "index_cat_77",
        ["onClick"] = function()
            Navigator.forward(0, {
                ["type"] = "pdd_category",
                ["props"] = {
                    ["category_id"] = "4",
                    ["category_type"] = "1",
                    ["category_name"] = "母婴",
                    ["url"] = "catgoods.html?opt_id=4&opt_type=1&all=true",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.Cosmetics = {
        ["name"] =  "美妆护肤",
        ["imgUrl"] =  host .. "image/cat_69.png",
        ["key"] =  "index_cat_69",
        ["onClick"] = function()
            Navigator.forward(0, {
                ["type"] = "pdd_category",
                ["props"] = {
                    ["category_id"] = "16",
                    ["category_type"] = "1",
                    ["category_name"] = "美妆护肤",
                    ["url"] = "catgoods.html?opt_id=16&opt_type=1&all=true",
                },
            })
        end,
    }
    HomeScene.QuickEntrance.Oversea = {
        ["name"] =  "海淘",
        ["imgUrl"] =  host .. "image/cat_18.png",
        ["badge"] = host .. "image/activity_new_tip.png",
        ["key"] = "index_haitao",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.QuickEntrance.Oversea)
            Navigator.selectTab(2)
        end,
    }

    HomeScene.NewQuickEntrance = {}
    HomeScene.NewQuickEntrance.Spike = {
        ["name"] = "限时秒杀",
        ["imgUrl"] = self:getSpikeImageURL(),
        ["tipWidth"] = 18,
        ["tipHeight"] = 16,
        ["tipTop"] = -5,
        ["tipTrailing"] = 12,
        ["key"] = INDEX_SPIKE_KEY,
        ["pageElement"] = "time_spike",
        ["pageElSn"] = "99956",
        ["link"] = "spike.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Spike)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "spike.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Spike)
            })
        end,
    }    

    local superbrandType = (Version.new(aimi.Application.getApplicationVersion()) <= Version.new("3.25.0")) and "web" or Version.new(aimi.Application.getApplicationVersion()) > Version.new("3.61.0")  and "pdd_subjects" or "pdd_superbrand"
    HomeScene.NewQuickEntrance.SuperSpike = {
        ["name"] = "品牌清仓",
        ["imgUrl"] = self:getSuperSpikeImageURL(),
        ["key"] = INDEX_SUPER_SPIKE_KEY,
        ["pageElement"] = "super_spike",
        ["pageElSn"] = "99955",
        ["link"] = "subjects.html?subjects_id=14",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.SuperSpike)
            Navigator.forward(0, {
                ["type"] = superbrandType,
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["14"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.SuperSpike)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Fruits = {
        ["name"] = (Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_TEN_ICONS_VERSION) and "品质水果团" or "品质水果",
        ["imgUrl"] = self:getHomeIconByName("fruits.png"),
        ["key"] =  "index_fruits",
        ["pageElement"] = "good_fruit",
        ["pageElSn"] = "99950",
        ["link"] = "subjects.html?subjects_id=11",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Fruits)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["11"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Fruits)
            })
        end,
    }
    HomeScene.NewQuickEntrance.GoShopping = {
        ["name"] = "爱逛街",
        ["imgUrl"] = self:getHomeIconByName("go_shopping.png"),
        ["key"] = "index_go_shopping",
        ["pageElement"] = "go_shopping",
        ["pageElSn"] = "99290",
        ["link"] = "subjects.html?subjects_id=15",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.GoShopping)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.10.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["15"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.GoShopping)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Bargain = {
        ["name"] =  "9块9特卖",
        ["imgUrl"] =  self:getHomeIconByName("bargain_new.png"),
        ["key"] =  "index_bargain",
        ["pageElement"] = "bargain",
        ["pageElSn"] = "99952",
        ["link"] = "subjects.html?subjects_id=12",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Bargain)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) <= Version.new("2.14.0") and "web" or Version.new(aimi.Application.getApplicationVersion()) > Version.new("3.61.0")  and "pdd_subjects" or "pdd_bargain",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["12"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Bargain)
            })
        end,
    }
    HomeScene.NewQuickEntrance.FreeTrial = {
        ["name"] = (Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_TEN_ICONS_VERSION) and "免费试用团" or "免费试用",
        ["imgUrl"] = self:getHomeIconByName("free_trial_new.png"),
        ["key"] = "index_free_trial",
        ["pageElement"] = "free_try",
        ["pageElSn"] = "99954",
        ["link"] = "free_trial_page.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.FreeTrial)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "free_trial_page.html",
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.FreeTrial)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Family = {
        ["name"] = "省钱控",
        ["imgUrl"] = self:getHomeIconByName("family.png"),
        ["key"] = "index_family",
        ["pageElement"] = "preferential_family",
        ["pageElSn"] = "99947",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Family)
            Navigator.forward(0, {
                ["type"] = "pdd_subject",
                ["props"] = {
                    ["subject_id"] = "559"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Family)
            })
        end,
    }
    HomeScene.NewQuickEntrance.SlightlyLuxurious = {
        ["name"] = "时尚穿搭",
        ["imgUrl"] = self:getHomeIconByName("aiqingshe.png"),
        ["key"] = "index_slightly_luxurious",
        ["pageElement"] = "entry_lux",
        ["pageElSn"] = "99946",
        ["link"] = "subjects.html?subjects_id=22",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.SlightlyLuxurious)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.4.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["22"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.SlightlyLuxurious)
            })
        end,
    }
    HomeScene.NewQuickEntrance.LoveLux = {
        ["name"] = "爱轻奢",
        ["imgUrl"] = self:getHomeIconByName("lovelux.png"),
        ["key"] = "love_lux",
        ["pageElement"] = "love_lux",
        ["pageElSn"] = "99295",
        ["link"] = "subjects.html?subjects_id=24",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.LoveLux)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.4.0") and "web" or "pdd_subjects",
                ["props"] = {
                    ["url"] = "subjects.html?subjects_id=24",
                    ["subjects_id"] = "24"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.LoveLux)
            })
        end,
    }
    HomeScene.NewQuickEntrance.ElectricalAppliance = {
        ["name"] =  "电器城",
        ["imgUrl"] =  self:getHomeIconByName("electrical_appliance.png"),
        ["key"] =  "index_electric_city",
        ["pageElement"] = "electric_city",
        ["pageElSn"] = "99284",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.ElectricalAppliance)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.24.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["23"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.ElectricalAppliance)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Oversea = {
        ["name"] =  "海淘",
        ["imgUrl"] =  self:getHomeIconByName("global_shop.png"),
        ["key"] = "index_haitao",
        ["pageElement"] = "haitao_code",
        ["pageElSn"] = "99948",
        ["link"] = "haitao.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Oversea)
            if FriendGray.isChatTabEnabled() then 
                local now = os.time()
                local startTime = os.time{year=2017, month=11, day=22, hour=0, min=0, sec=0}
                local endTime = os.time{year=2017, month=11, day=24, hour=23, min=59, sec=59}
                if now >= startTime and now < endTime then
                    Navigator.forward(0, {
                        ["type"] = "web",
                        ["props"] = {
                            ["url"] = "promo_bfri.html",
                        },
                        ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Oversea)
                    })
                else
                    Navigator.forward(0, {
                        ["type"] =  "pdd_haitao",
                        ["props"] = {
                            ["url"] = "haitao.html",
                            ["title_when_pushed"] = "海淘专区",
                        },
                        ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Oversea)
                    })
                end
            else
                AMBridge.call("AMNavigator", "selectTab", {
                ["tab_index"] = 2,
                 }, nil, HomeScene.instance():getContextID())
            end
        end,
    }
    HomeScene.NewQuickEntrance.Food = {
        ["name"] = "美食汇",
        ["imgUrl"] = self:getHomeIconByName("food.png"),
        ["key"] = "food",
        ["pageElement"] = "food",
        ["pageElSn"] = "99291",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Food)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.20.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["17"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Food)
            })
        end,
    }
    HomeScene.NewQuickEntrance.FoodV2 = {
        ["name"] = "食品超市",
        ["imgUrl"] = self:getHomeIconByName("food_v2.png"),
        ["key"] = "food",
        ["pageElement"] = "food",
        ["pageElSn"] = "99291",
        ["link"] = "subjects.html?subjects_id=17",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.FoodV2)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.20.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["17"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.FoodV2)
            })
        end,
    }
    HomeScene.NewQuickEntrance.HelpFreeGroup = {
        ["name"] = "帮帮免费团",
        ["imgUrl"] = self:getHomeIconByName("assist_group.png"),
        ["key"] = "assist_group",
        ["pageElSn"] = "97974",
        ["link"] = "help_free_group.html",
        ["onClick"] = function ()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.HelpFreeGroup)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "help_free_group.html",
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.HelpFreeGroup)
            })
        end
    }
    HomeScene.NewQuickEntrance.Furniture = {
        ["name"] =  "家居优品",
        ["imgUrl"] = self:getHomeIconByName("furniture.png"),
        ["key"] =  "furniture",
        ["pageElement"] = "furniture",
        ["pageElSn"] = "99292",
        ["link"] = "subjects.html?subjects_id=18",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Furniture)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.24.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["18"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Furniture)
            })

        end,
    }
    HomeScene.NewQuickEntrance.ChargeCenter = {
        ["name"] =  "手机充值",
        ["imgUrl"] = self:getHomeIconByName("charge_center.png"),
        ["key"] =  CHARGE_CENTER_KEY,
        ["pageElement"] = "charge_center",
        ["pageElSn"] = "99293",
        ["url"] = "deposit.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.ChargeCenter)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "deposit.html",
                    ["subjects_title"] = "手机充值"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.ChargeCenter)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Maternal = {
        ["name"] =  "省钱妈咪",
        ["imgUrl"] = self:getHomeIconByName("maternal.png"),
        ["key"] =  "maternal",
        ["pageElement"] = "maternal",
        ["pageElSn"] = "99944",
        ["link"] = "subjects.html?subjects_id=20",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Maternal)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) <= Version.new("3.13.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["20"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Maternal)
            })
        end,
    }
    HomeScene.NewQuickEntrance.NewCustomer = {
        ["name"] =  "新人专享礼",
        ["imgUrl"] =  self:getHomeIconByName("new_customer.png"),
        ["key"] =  "coupon_newuser",
        ["pageElement"] = "coupon_newuser",
        ["pageElSn"] = "99957",
        ["link"] = "coupon_newuser.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.NewCustomer)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "coupon_newuser.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.NewCustomer)
            })
        end,
    }

    HomeScene.NewQuickEntrance.EconomicalBrand = {
        ["name"] =  "名品折扣",
        ["imgUrl"] =  self:getHomeIconByName("economical_brand.png"),
        ["key"] =  ECONOMICAL_BRAND_KEY,
        ["pageElement"] = "economical_brand",
        ["pageElSn"] = "99294",
        ["link"] = "mkt_award.html",
        ["url"] = "economical_brand.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.EconomicalBrand)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) <= Version.new("4.1.0") and "web" or "pdd_subjects",
                ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["21"],
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.EconomicalBrand)
            })
        end,
    }
    HomeScene.NewQuickEntrance.BrowseAd = {
        ["name"] =  "边逛边赚", 
        ["imgUrl"] =  self:getHomeIconByName("browse_ad.png"),
        ["key"] =  BROWSE_AD_KEY,
        ["pageElSn"] = "98205",
        ["link"] = "mkt_award.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.BrowseAd)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_award.html",
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.BrowseAd)
            })
        end,
    }
    HomeScene.NewQuickEntrance.SignIn = {
        ["name"] =  "现金签到",
        ["imgUrl"] =  self:getHomeIconByName("sign_in.png"),
        ["key"] = SIGN_KEY,
        ["tipWidth"] = 17,
        ["tipHeight"] = 17,
        ["tipTop"] = -5,
        ["tipTrailing"] = 12,
        ["pageElement"] = "attendance",
        ["pageElSn"] = "99288",
        ["link"] = "mkt_daily999.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.SignIn)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_daily999.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.SignIn)
            })
        end,
    }
    HomeScene.NewQuickEntrance.AssistFreeCoupon = {
        ["name"] =  "助力享免单",
        ["imgUrl"] =  self:getHomeIconByName("assist_free_coupon.png"),
        ["key"] =  ASSIST_FREE_COUPON_KEY,
        ["pageElement"] = "assist_free_coupon",
        ["pageElSn"] = "99287",
        ["link"] = "mkt_assist_free.html?cid=assist_icon_new",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.AssistFreeCoupon)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_assist_free.html?cid=assist_icon_new"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.AssistFreeCoupon)
            })
        end,
    }
    HomeScene.NewQuickEntrance.CommercialBargainList = {
        ["name"] =  "砍价免费拿",
        ["imgUrl"] =  self:getHomeIconByName("commercial_bargain_list.png"),
        ["key"] =  COMMERCIAL_BARGAIN_LIST_KEY,
        ["pageElSn"] = "99003",
        ["link"] = "mkt_bargain_list1.html?src=ios&campaign=cutprice&cid=ios_icon",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.CommercialBargainList)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_bargain_list1.html?src=ios&campaign=cutprice&cid=ios_icon"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.CommercialBargainList)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Roulette = {
        ["name"] =  "转盘领现金",
        ["imgUrl"] =  self:getHomeIconByName("roulette.png"),
        ["key"] =  ROULETTE_KEY,
        ["pageElSn"] = "98791",
        ["link"] = "mkt_roulette.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Roulette)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_roulette.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Roulette)
            })
        end,
    }
    HomeScene.NewQuickEntrance.Pinvote = {
        ["name"] = "秀萌宝",
        ["imgUrl"] = self:getHomeIconByName("pinvote.png"),
        ["pageElSn"] = "10259",
        ["link"] = "mkt_pinvote.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.Pinvote)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_pinvote.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.Pinvote)
            })
        end,
    }

    HomeScene.NewQuickEntrance.RankHot = {
        ["name"] =  "同城排行",
        ["imgUrl"] =  self:getHomeIconByName("rank_hot.png"),
        ["key"] =  "rank_hot",
        ["pageElement"] = "rank_hot",
        ["link"] = "rank_hot.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.RankHot)
            Navigator.forward(0, {
                ["type"] = Version.new(aimi.Application.getApplicationVersion()) <= NEW_HOME_TEN_ICONS_VERSION and "web" or "rank_hot",
                ["props"] = {
                    ["url"] = "rank_hot.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.RankHot)
            })
        end,
    }
    HomeScene.NewQuickEntrance.OneCent = {
        ["name"] =  "1分抽大奖",
        ["imgUrl"] =  self:getHomeIconByName("one_cent.png"),
        ["key"] =  "one_cent",
        ["pageElement"] = "one_cent",
        ["pageElSn"] = "99167",
        ["link"] = "subject.html?subject_id=2742&force_use_web_bundle=1",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.OneCent)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "subject.html?subject_id=2742&force_use_web_bundle=1"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.OneCent)
            })
        end,
    }
    HomeScene.NewQuickEntrance.LuckyBag = {
        ["name"] =  "天天领现金",
        ["imgUrl"] =  self:getHomeIconByName("lucky_bag.png"),
        ["key"] =  LUCKY_BAG_KEY,
        ["pageElSn"] = "98484",
        ["link"] = "mkt_lucky_bag.html",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.LuckyBag)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_lucky_bag.html"
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.LuckyBag)
            })
        end,
    }
    HomeScene.NewQuickEntrance.MoneyTree = {
        ["name"] = "现金摇钱树",
        ["imgUrl"] = self:getHomeIconByName("money_tree.png"),
        ["pageElSn"] = "97797",
        ["key"] = "money_tree",
        ["group"] = "42",
        ["link"] = "mkt_lucky_tree.html?",
        ["onClick"] = function()
            tryRemoveQuickEntranceBadge(HomeScene.NewQuickEntrance.MoneyTree)
            Navigator.forward(0, {
                ["type"] = "web",
                ["props"] = {
                    ["url"] = "mkt_lucky_tree.html?",
                },
                ["transient_refer_page_context"] = getPageReference(HomeScene.NewQuickEntrance.MoneyTree)
            })
        end,
    }
    self:setBadge()
end

function HomeScene:fillQuickEntranceDataFromResponse(icons)
    if type(icons) ~= "table" then
        return
    end

    local function tryRemoveQuickEntranceBadge(entrance)
        if entrance == nil or entrance["tipUrl"] == nil then
            return
        else
            entrance["tipUrl"] = nil
        end

        local key = entrance["group"]
        if key == Constant.ICON_GROUP.SignIn then
            return
        end

        self:updateLastViewQuickEntranceFlags(key)
        self:setQuickEntranceDirty(true)
        self:updateQuickEntrances()
    end

    local function extractRightForwardParam(item)
            local group = item["group"]
            local param = Constant.ICON_PARAM[group]
            if param == nil then
                param = {
                    ["type"] = "web",
                    ["props"] = {
                    },
                }
            end
            param["transient_refer_page_context"] = {
                ["page_el_sn"] = item["pageElSn"] or "",
                ["page_sn"] = "10002",
            }
            if item["group"] ~= "45" then
                param["props"]["url"] = item["link"]
            end
            return param
    end

    HomeScene.HostConfigQuickEntrance = {}
    for i, item in pairs(icons) do
        local icon = {
            ["name"] = item["title"],
            ["imgUrl"] = item["image"],
            ["pageElSn"] = tostring(item["log_sn"]),
            ["group"] = tostring(item["group"]),
            ["style"] = tostring(item["style"]),
            ["link"] = item["link"],
        }
        icon["onClick"] = function()
            tryRemoveQuickEntranceBadge(icon)
            if icon["pageElSn"] == "99948" and FriendGray.isChatTabEnabled() == false then --海淘
                AMBridge.call("AMNavigator", "selectTab", {
                    ["tab_index"] = 2,
                }, nil, HomeScene.instance():getContextID())
                return
            end 
            Navigator.forward(0, extractRightForwardParam(icon))
        end
        
        table.insert(HomeScene.HostConfigQuickEntrance, icon)
    end

    local entrances = {}
    local offset = math.ceil(#HomeScene.HostConfigQuickEntrance / 2);
    for i = 1, offset do
        local item = HomeScene.HostConfigQuickEntrance[i] or {}
        table.insert(entrances, item)

        local itemWithOffset = HomeScene.HostConfigQuickEntrance[i + offset] or {}
        if i + offset <= #HomeScene.HostConfigQuickEntrance then
            table.insert(entrances, itemWithOffset)
        end
    end

    HomeScene.HostConfigQuickEntrance = entrances
end

function HomeScene:setBadge()

    local now = os.time()
    local allIntegrationTime = now > os.time{year=2018, month=6, day=16, hour=0, min=0, sec=0} and now < os.time{year=2018, month=6, day=18, hour=23, min=59, sec=59}
    if allIntegrationTime then
        return
    end

   local function getBadgeImageByName(name)
        local domain = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
        -- local startTime = HOME_ACTIVITY_INTEGRATION_START_TIME
        -- local endTime = HOME_ACTIVITY_INTEGRATION_END_TIME
        local now = os.time()

        local appVersion = aimi.Application.getApplicationVersion()
        -- 一体化是3.49.0版本上的
        -- if now >= startTime and now < endTime and Version.new(appVersion) >= Version.new("3.54.0")  then
        --     return domain .. "image/badge/" .. name
        -- end
        return domain .. "image/" .. name
    end

    local function getSignInIconBadge(SignIn)
        SignIn["tipWidth"] = 17
        SignIn["tipHeight"] = 16
        SignIn["tipTop"] = -5
        SignIn["tipTrailing"] = 11
        if type(self.signInToday_) == "number" and self.signInToday_ == 0 then
            return getBadgeImageByName("sign_badge.gif")
        end

        if type(self.rewardNum_) == "number" and self.rewardNum_ > 0 and self.rewardNum_ <= 10 then
            SignIn["tipWidth"] = 17
            SignIn["tipHeight"] = 17
            SignIn["tipTop"] = -1
            SignIn["tipTrailing"] = 7
            return getBadgeImageByName("sign_reward_num_" .. tostring(self.rewardNum_) .. ".png")
        end

        return
    end

    local function getLuckyBagIconBadge(LuckyBag)
        LuckyBag["tipWidth"] = 17
        LuckyBag["tipHeight"] = 17
        LuckyBag["tipTop"] = -5
        LuckyBag["tipTrailing"] = 7
        if type(self.luckyBagNum_) == "number" and self.luckyBagNum_ > 0 and self.luckyBagNum_ <= 9 then
            return getBadgeImageByName("sign_reward_num_" .. tostring(self.luckyBagNum_) .. ".png")
        end

        if type(self.luckyBagNum_) == "number" and self.luckyBagNum_ >= 10 then
            LuckyBag["tipWidth"] = 23
            LuckyBag["tipTrailing"] = 12.5
            return getBadgeImageByName("lucky_bag_num.png")
        end

        return
    end

    local function getMoneyTreeBadge(MoneyTree)
        MoneyTree["tipWidth"] = 17
        MoneyTree["tipHeight"] = 17
        MoneyTree["tipTop"] = -5
        MoneyTree["tipTrailing"] = 7
        if type(self.moneyTreeNum_) == "number" and self.moneyTreeNum_ > 0 and self.moneyTreeNum_ <= 9 then
            return getBadgeImageByName("sign_reward_num_" .. tostring(self.moneyTreeNum_) .. ".png")
        end

        if type(self.moneyTreeNum_) == "number" and self.moneyTreeNum_ >= 10 then
            MoneyTree["tipWidth"] = 23
            MoneyTree["tipTrailing"] = 12.5
            return getBadgeImageByName("lucky_bag_num.png")
        end

        return
    end

    local function getSpikeBadge(Spike)
        Spike["tipWidth"] = 18
        Spike["tipHeight"] = 16
        Spike["tipTop"] = -5
        Spike["tipTrailing"] = 12

        if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.15.0") then
            return host .. "image/red_dot.png"
        else
            return getBadgeImageByName("red_dot2.gif")
        end
    end

    local function setIconNewBadge(icon)
        icon["tipWidth"] = 18
        icon["tipHeight"] = 16
        icon["tipTop"] = -5
        icon["tipTrailing"] = 12
        if group == Constant.ICON_GROUP.Spike then
            icon["badge"] = getSpikeBadge(icon)
        else 
            icon["badge"] = getBadgeImageByName("red_dot2.gif")
        end
    end

    local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    if Version.new(aimi.Application.getApplicationVersion()) >= HOME_ICONS_SERVER_CONFIG and self.flags_["pdd_home_icon_config"] == 1  then

        if HomeScene.HostConfigQuickEntrance == nil or HomeScene.HostConfigQuickEntrance == {} then
            return
        end

        for index, icon in pairs(HomeScene.HostConfigQuickEntrance) do
            local group = icon["group"] or ""
            local style = icon["style"] or "0"

            if style == "1" then
                icon["badge"] = getBadgeImageByName("red_dot.png")
            elseif style == "2" then
                setIconNewBadge(icon)
            elseif style == "0" then
                icon["badge"] = nil
            end 

            if group ==  Constant.ICON_GROUP.SignIn then
                icon["badge"] = getSignInIconBadge(icon)
            end

            if group == Constant.ICON_GROUP.LuckyBag then
                icon["badge"] = getLuckyBagIconBadge(icon)
            end

            if group == Constant.ICON_GROUP.MoneyTree then
                icon["badge"] = getMoneyTreeBadge(icon)
            end

            if group == Constant.ICON_GROUP.CommercialBargainList and self.flags_["pdd_bargin_expose_number"] ~= nil and self.flags_["pdd_bargin_expose_number"] > 3 then 
                icon["badge"] = nil
            end
        end
        return
    end

    
    if self:isNewRedLogicVersion() then
        HomeScene.NewQuickEntrance.LuckyBag["badge"] = getBadgeImageByName("red_dot.png")
        HomeScene.NewQuickEntrance.SuperSpike["badge"] = getBadgeImageByName("red_dot.png")
        HomeScene.NewQuickEntrance.MoneyTree["badge"] = getBadgeImageByName("red_dot.png")

        local spikeRedURL = getBadgeImageByName("red_dot2.gif")
        -- if self.spikeNewRedFlag_ == 1 then
        --     spikeRedURL = host .. "image/red_dot.png"
        -- end

        HomeScene.NewQuickEntrance.Spike["badge"] = spikeRedURL
        if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.15.0") then
            HomeScene.NewQuickEntrance.Spike["badge"] = host .. "image/red_dot.png"
        end
        HomeScene.NewQuickEntrance.SignIn["badge"] = getSignInIconBadge(HomeScene.NewQuickEntrance.SignIn)
        HomeScene.NewQuickEntrance.LuckyBag["badge"] = getLuckyBagIconBadge(HomeScene.NewQuickEntrance.LuckyBag)
        HomeScene.NewQuickEntrance.MoneyTree["badge"] = getMoneyTreeBadge(HomeScene.NewQuickEntrance.MoneyTree)
    end
end

function HomeScene:getHomeIconByName(name)
    local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    local newHomeIcons = Version.new(aimi.Application.getApplicationVersion()) >= NEW_HOME_ENTRANCE_ICONS

    if name == "activity/spike_new.png" and newHomeIcons then
        local now = os.time()
        local startTime = os.time{year=2018, month=6, day=17, hour=0, min=0, sec=0}
        local endTime = os.time{year=2018, month=6, day=17, hour=23, min=59, sec=59}
        if now >= startTime and now < endTime then
            name = "activity/spike_new.gif"
        end
    end

    local imageURL = host .. "image/" .. name
    -- 首页icons调整大小后的图片都放到image2下面
    if newHomeIcons then
        imageURL = host .. "image2/" .. name
    end

    return imageURL
end

function HomeScene:isNewRedLogicVersion()
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_VERSION then
        return false
    end
    return true
end

function HomeScene:registerBridgeEvents()
    AMBridge.register(Event.ApplicationResume, function()
        -- local isActivityTime = Activity.isActivityPeriod()
        -- if self.isActivity_ ~= isActivityTime then
        --     self:setActivity(isActivityTime)
        --     self:setQuickEntranceDirty(true)
        -- end
        -- Application.getSharedTaskQueue():push(CheckMarketActivityTask.run)
        -- Application.getSharedTaskQueue():push(CheckAssistFreeCouponTask.run)
        Application.getSharedTaskQueue():push(CheckCommonActivityTaskV2.run)

        self:setQuickEntranceDirty(true)
        self:updateQuickEntrances()
        self:checkUser()

        self:fetchSignIconsStatus()
        self:fetchLuckyBagIconsStatus()
        self:fetchMoneyTreeIconsStatus()
        self:fetchBrowseAdIconFlag()
        self:fetchHomeIconList()
        Application.getSharedTaskQueue():push(CheckSignInTask.run)

    end)

    AMBridge.register(Event.UserLogin, function()
        CheckUnpaidOrderTask.reset()
        -- CheckFreeCouponsTask.reset()
        self:checkUser()
        -- Application.getSharedTaskQueue():push(CheckMarketActivityTask.run)
        -- Application.getSharedTaskQueue():push(CheckAssistFreeCouponTask.run)
        Application.getSharedTaskQueue():push(CheckSignInTask.run)
    end)

    AMBridge.register(Event.UserLogout, function()
        self:checkUser()
    end)

    self.currentViewQuickEntranceDays_ = {}
    -- AMBridge.register(Event.PDDListUpdatedTimeNotification, function(payload)
        -- if payload ~= nil then
        --     local keyMapping = {
        --         ["lucky_draw"] = "index_lottery",
        --         ["fruit_group"] = "index_fruits",
        --     }
        --     for key, value in pairs(payload) do
        --         print(key, value)
        --         if keyMapping[key] ~= nil then
        --             self.currentViewQuickEntranceDays_[keyMapping[key]] = value
        --         end
        --     end
        --     self:updateQuickEntrances()
        -- end
    -- end)
end

function HomeScene:sceneWillAppear()
    local isActivityTime = Activity.isActivityPeriod()
    if self.isActivity_ ~= isActivityTime then
        self:setActivity(isActivityTime)
        self:setQuickEntranceDirty(true)
        self:updateQuickEntrances()
    end
    self:fetchSignIconsStatus()
    self:fetchLuckyBagIconsStatus()
    self:fetchMoneyTreeIconsStatus()
    -- if self.signInEntryFlag_ == 1 then
    --     self:fetchSignInEntryFlag()
    -- end
    self:fetchBrowseAdIconFlag()
    self:fetchHomeIconList()

    -- if self.newCustomerFlag_ == 1 then
    --     self:getHomeIconList()
    -- end
end

function HomeScene:sceneDidAppear()
    self:addTaskToQueue2()
end

function HomeScene:setQuickEntranceDirty(dirty)
    self.isQuickEntranceDirty_ = dirty
end

function HomeScene:loadFlagByKey(key)
    local flag = tonumber(aimi.KVStorage.getInstance():get(key))
    if flag == nil then
        flag = 0
    end
    self:setFlag(key, flag)
end

function HomeScene:loadFlagByKeyWithValue(key, defaultValue)
    local flag = tonumber(aimi.KVStorage.getInstance():get(key))
    if flag == nil then
        if type(defaultValue) ~= "number" then
            flag = 0
        else
            flag = defaultValue
        end
    end

    print("--------,key=",key,"flag=",flag)
    self:setFlag(key, flag)
end

function HomeScene:updateFlagByKey(key, abTestName)
    print('updateFlagByKey,key=',key,'abTestName=',abTestName)
    AMBridge.call("PDDABTest", "check", {
        ["name"] = abTestName,
        ["default_value"] = 0
    }, function (error, response)
        if response then
            local flag = response["is_enabled"]
            if self.flags_ == nil or self.flags_[key] ~= flag then
                self:setFlag(key, flag)
                self:setQuickEntranceDirty(true)
                self:updateQuickEntrances()
            end
        end
    end)
end

function HomeScene:setFlag(key, value)
    print('setFlag with key =', key, 'value=', value)

    if self.flags_ == nil then
        self.flags_ = {}
    end

    if self.flags_[key] == value then
        return
    end


    self.flags_[key] = value
    self:saveFlag(key, value)
end

function HomeScene:saveFlag(key, value)
    aimi.KVStorage.getInstance():set(key, tostring(value))
end

function HomeScene:loadNewCustomerFlag()
    local newCustomerFlag = tonumber(aimi.KVStorage.getInstance():get(NEW_CUSTOMER_FLAG_KEY))
    if newCustomerFlag == nil then
        newCustomerFlag = -1
    end

    self:setNewCustomerFlag(newCustomerFlag)
end

function HomeScene:setNewCustomerFlag(newCustomerFlag)
    if self.newCustomerFlag_ ~= newCustomerFlag then
        self.newCustomerFlag_ = newCustomerFlag
        self:saveNewCustomFlag(newCustomerFlag)
    end
end

function HomeScene:saveNewCustomFlag(newCustomerFlag)
    aimi.KVStorage.getInstance():set(NEW_CUSTOMER_FLAG_KEY, tostring(newCustomerFlag))
end

function HomeScene:getHomeIconList()
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_ENTRANCE_SUPPORT_NEW_CUSTOMER then
        return
    end

    if self.newCustomerFlag_ == 0 then
        return
    end

    local function checkIsNewCustomer()
        Promise.new(function(resolve, reject)
            local md5DeviceID = MD5.sumhexa("34d699" .. aimi.Device.getDeviceIdentifier())
            return APIService.getJSON("home_icon_list?device_id=" .. md5DeviceID):next(function(response)
                resolve(response)
            end):catch(function(reason)
                reject(reason)
            end)
        end):next(function(response)
            local isNewCustomer = response.responseJSON["is_new_custom"]
            print('------------isNewCustomer=',isNewCustomer)
            AMBridge.call("AMLog", "log", {
                ["message"] = "isNewCustomer=".. isNewCustomer
            })

            if isNewCustomer == nil then
                return
            end

            if self.newCustomerFlag_ ~=  isNewCustomer then
                self:setNewCustomerFlag(isNewCustomer)

                self:setQuickEntranceDirty(true)
                self:updateQuickEntrances()
            end
        end)
    end

    if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.44.0") then
        checkIsNewCustomer()
    else
        AMBridge.call("PDDMeta", "info", nil, function(errorCode, response)
            checkIsNewCustomer()
        end)
    end
end


function HomeScene:loadRestrictedUserFlag()
    local restrictedUserFlag = tonumber(aimi.KVStorage.getInstance():get(RESTRICTED_USER_FLAG_KEY))
    if restrictedUserFlag == nil then
        restrictedUserFlag = 1
    end

    self:setRestrictedUserFlag(restrictedUserFlag)
end

function HomeScene:setRestrictedUserFlag(restrictedUserFlag)
    if self.restrictedUserFlag_ ~= restrictedUserFlag then
        self.restrictedUserFlag_ = restrictedUserFlag
        self:saveRestrictedUserFlag(restrictedUserFlag)
    end
end

function HomeScene:saveRestrictedUserFlag(restrictedUserFlag)
    aimi.KVStorage.getInstance():set(RESTRICTED_USER_FLAG_KEY, tostring(restrictedUserFlag))
end

function HomeScene:loadNewSignInFlag()
    local newSignFlag = tonumber(aimi.KVStorage.getInstance():get(NEW_SIGN_IN_SHOW_FLAG_KEY))
    self:saveNewSignFlag(newSignFlag)
end

function HomeScene:loadBrowseAdIconFlag()
    local browseAdIconFlag = tonumber(aimi.KVStorage.getInstance():get(BROWSE_AD_KEY))
    if browseAdIconFlag == nil then
        browseAdIconFlag = 0
    end
    self:setBrowseAdEntryFlag(browseAdIconFlag)
end

function HomeScene:saveBrowseAdIconFlag(browseAdIconFlag)
    aimi.KVStorage.getInstance():set(BROWSE_AD_KEY, tostring(browseAdIconFlag))
end

function HomeScene:setBrowseAdEntryFlag(browseAdIconFlag)
    print("setBrowseAdEntryFlag" .. browseAdIconFlag)
    if self.browseAdIconFlag_ ~= browseAdIconFlag then
        self.browseAdIconFlag_ = browseAdIconFlag
        self:saveBrowseAdIconFlag(browseAdIconFlag)
    end
end

function HomeScene:saveNewSignFlag(newSignFlag)
    if self.newSignFlag_ ~= newSignFlag then
        self.newSignFlag_ = newSignFlag
        aimi.KVStorage.getInstance():set(NEW_SIGN_IN_SHOW_FLAG_KEY, tostring(newSignFlag))
    end
end

function HomeScene:loadUserEgrp()
    local egrp = tonumber(aimi.KVStorage.getInstance():get(USER_EGRP_KEY))
    if egrp == nil then
        egrp = 2
    end
    
    self:setUserEgrp(egrp)
end

function HomeScene:setUserEgrp(egrp)
    if self.egrp_ ~= egrp then
        self.egrp_ = egrp
        self:saveUserEgrp(egrp)
    end
end

function HomeScene:saveUserEgrp(egrp)
    aimi.KVStorage.getInstance():set(USER_EGRP_KEY, tostring(egrp))
end

function HomeScene:loadSignIconStatus()
    local signInToday = tonumber(aimi.KVStorage.getInstance():get(HOME_ICONS_SIGN_IN_TODAY_FLAG_KEY))
    local rewardNum = tonumber(aimi.KVStorage.getInstance():get(HOME_ICONS_SIGN_IN_REWARD_NUMBER_NUMBER_FLAG_KEY))    
 
    if signInToday == nil then
        signInToday = 0
    end
    self.signInToday_ = signInToday

    if rewardNum == nil then
        rewardNum = 0
    end
    self.rewardNum_ = rewardNum
end

function HomeScene:fetchSignIconsStatus()
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken == 0 then
        if self.signInToday_ ~= 0 or self.rewardNum_ ~= 0 then
            self:setSignIconStatus(0, 0)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
        return
    end

    print('start fetchSignIconsStatus')
    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/amazon/rome/v4/query_icon_status"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local signInToday = response.responseJSON["sign_in_today"]
        if type(signInToday) == "boolean" then
            if signInToday == false then
                signInToday = 0
            else
                signInToday = 1
            end
        end

        signInToday = tonumber(signInToday)
        local rewardNum = tonumber(response.responseJSON["reward_num"])
        if type(signInToday) == "number" and type(rewardNum) == "number" then
            AMBridge.call("AMLog", "log", {
                ["message"] = "signInToday=" .. tostring(signInToday) .. ",rewardNum=".. tostring(rewardNum) .. ",self.signInToday_=" ..tostring(self.signInToday_) .. ",self.rewardNum_=" .. tostring(self.rewardNum_)
            })
            if rewardNum > 10 then
                rewardNum = 10
            end

            if self.signInToday_ ~= signInToday or self.rewardNum_ ~= rewardNum then
                self:setSignIconStatus(signInToday, rewardNum)
                self:setQuickEntranceDirty(true)
                self:updateQuickEntrances()
            end
        else
            local error = "signInToday's type=" .. type(signInToday) .. ",rewardNum's type" .. type(rewardNum)
            AMBridge.call("AMLog", "log", {
                ["message"] = error
            })
        end
    end)
end

function HomeScene:setSignIconStatus(signInToday, rewardNum)
    if type(signInToday) == "number" and self.signInToday_ ~= signInToday  then
        self.signInToday_ = signInToday
        self:saveSignInTodayFlag(signInToday)
    end

    if type(rewardNum) == "number" and self.rewardNum_ ~= rewardNum then
        if rewardNum > 10 then
            rewardNum = 10
        end
        self.rewardNum_ = rewardNum
        self:saveRewardNumFlag(rewardNum)
    end
end

function HomeScene:saveSignInTodayFlag(signInTodayFlag)
    aimi.KVStorage.getInstance():set(HOME_ICONS_SIGN_IN_TODAY_FLAG_KEY, tostring(signInTodayFlag))
end

function HomeScene:saveRewardNumFlag(rewardNumFlag)
    aimi.KVStorage.getInstance():set(HOME_ICONS_SIGN_IN_REWARD_NUMBER_NUMBER_FLAG_KEY, tostring(rewardNumFlag))
end

-- 拆红包badge
function HomeScene:loadLuckyBagIconStatus()
    local luckyBagNum = tonumber(aimi.KVStorage.getInstance():get(HOME_ICONS_LUCKY_BAG_NUMBER_FLAG_KEY))    

    if luckyBagNum == nil then
        luckyBagNum = 0
    end
    self.luckyBagNum_ = luckyBagNum
end

function HomeScene:setLuckyBagIconStatus(luckyBagNum)
    if type(luckyBagNum) == "number" and self.luckyBagNum_ ~= luckyBagNum then
        if luckyBagNum >= 10 then
            luckyBagNum = 10
        end
        self.luckyBagNum_ = luckyBagNum
        self:saveLuckyBagNumFlag(luckyBagNum)
    end
end

function HomeScene:saveLuckyBagNumFlag(luckyBagNumFlag)
    aimi.KVStorage.getInstance():set(HOME_ICONS_LUCKY_BAG_NUMBER_FLAG_KEY, tostring(luckyBagNumFlag))
end

function HomeScene:fetchLuckyBagIconsStatus()
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken == 0 then
        if self.luckyBagNum_ ~= 0 then
            self:setLuckyBagIconStatus(0)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
        return
    end

    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/market/helen/grab_badge"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local luckyBagNum = tonumber(response.responseJSON["grab_badge"])
        if type(luckyBagNum) == "number" then
            if luckyBagNum >= 10 then
                luckyBagNum = 10
            end

            if self.luckyBagNum_ ~= luckyBagNum then
                self:setLuckyBagIconStatus(luckyBagNum)
                self:setQuickEntranceDirty(true)
                self:updateQuickEntrances()
            end
        end
    end)
end
--  摇钱树的badge
function HomeScene:loadMoneyTreeIconStatus()
    local moneyTreeNum = tonumber(aimi.KVStorage.getInstance():get(HOME_ICONS_MONEY_TREE_NUMBER_FLAG_KEY))    

    if moneyTreeNum == nil then
        moneyTreeNum = 0
    end
    self.moneyTreeNum_ = moneyTreeNum
end

function HomeScene:setMoneyTreeIconStatus(moneyTreeNum)
    if type(moneyTreeNum) == "number" and self.moneyTreeNum_ ~= moneyTreeNum then
        if moneyTreeNum >= 10 then
            moneyTreeNum = 10
        end
        self.moneyTreeNum_ = moneyTreeNum
        self:saveMoenyTreeNumFlag(moneyTreeNum)
    end
end

function HomeScene:saveMoenyTreeNumFlag(moneyTreeNum)
    aimi.KVStorage.getInstance():set(HOME_ICONS_MONEY_TREE_NUMBER_FLAG_KEY, tostring(moneyTreeNum))
end

function HomeScene:fetchMoneyTreeIconsStatus()
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken == 0 then
        if self.moneyTreeNum ~= 0 then
            self:setMoneyTreeIconStatus(0)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
        return
    end

    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/market/faust/grab_badge"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local moneyTreeNum = tonumber(response.responseJSON["grab_badge"])
        if type(moneyTreeNum) == "number" then
            if moneyTreeNum >= 10 then
                moneyTreeNum = 10
            end

            if self.moneyTreeNum_ ~= moneyTreeNum then
                self:setMoneyTreeIconStatus(moneyTreeNum)
                self:setQuickEntranceDirty(true)
                self:updateQuickEntrances()
            end
        end
    end)
end

function HomeScene:loadSignInEntryFlag()
    local signInEntryFlag = tonumber(aimi.KVStorage.getInstance():get(SIGN_IN_ENTRY_FLAG_KEY))
    if signInEntryFlag == nil then
        signInEntryFlag = 1
    end

    self.signInEntryFlag_ = signInEntryFlag
end


function HomeScene:setSignInEntryFlag(signInEntryFlag)
    if self.signInEntryFlag_ ~= signInEntryFlag then
        self.signInEntryFlag_ = signInEntryFlag
        self:saveSignInEntryFlag(signInEntryFlag)
    end
end

function HomeScene:saveSignInEntryFlag(signInEntryFlag)
    aimi.KVStorage.getInstance():set(SIGN_IN_ENTRY_FLAG_KEY, tostring(signInEntryFlag))
end

-- sign icon is alway show, will not call this metod
function HomeScene:fetchSignInEntryFlag()
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_ENTRANCE_SUPPORT_SIDESLIP_VERSION then
        return
    end

    -- 用户未登录
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken == 0 then
        local signInEntryFlag = 1
        if self.signInEntryFlag_ ~= signInEntryFlag then
            self:setSignInEntryFlag(signInEntryFlag)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
        return
    end

    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/amazon/rome/show_entry"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local signInEntryFlag = response.responseJSON["show_entry"]
        if signInEntryFlag == true then
            signInEntryFlag = 1
        end

        if signInEntryFlag == false then
            signInEntryFlag = 0
        end

        print('------------signInEntryFlag=',signInEntryFlag)
        AMBridge.call("AMLog", "log", {
            ["message"] = "signInEntryFlag=".. signInEntryFlag
        })

        if self.signInEntryFlag_ ~= signInEntryFlag then
            self:setSignInEntryFlag(signInEntryFlag)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
    end)
end

function HomeScene:fetchBrowseAdIconFlag()
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_ENTRANCE_SUPPORT_SIDESLIP_VERSION then
        return
    end

    -- 用户未登录
    local accessToken = aimi.User.getAccessToken()
    if accessToken == nil or #accessToken == 0 then
        local browseAdIconFlag = 0
        if self.browseAdIconFlag_ ~= browseAdIconFlag then
            self:setBrowseAdEntryFlag(browseAdIconFlag)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
        return
    end

    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/market/avengers/icon_gray"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local browseAdIconFlag = response.responseJSON["in_gray"]
        AMBridge.call("AMLog", "log", {
            ["message"] = "browseAdIconFlag=".. browseAdIconFlag
        })

        if self.browseAdIconFlag_ ~= browseAdIconFlag then
            self:setBrowseAdEntryFlag(browseAdIconFlag)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
    end)
end

function HomeScene:fetchHomeIconList()
    if Version.new(aimi.Application.getApplicationVersion()) < HOME_ICONS_SERVER_CONFIG or self.flags_["pdd_home_icon_config"] == nil or self.flags_["pdd_home_icon_config"] == 0 then
        return
    end

    local function isValidIconList(icons)
        if icons == nil then
            return false
        end

        for key, icon in pairs(icons) do
            if icon == nil 
                or icon["log_sn"] == nil
                or icon["link"] == nil or icon["link"] == "" 
                or icon["style"] == nil
                or icon["image"] == nil or icon["image"] == "" 
                or icon["title"] == nil or icon["title"] == "" 
                or icon["group"] == nil then
                return false
            end
        end
        return true
    end


    local function updateHomeIconsList(icons)
        if not isValidIconList(icons) and self.iconsReady_ ~= true then
             -- read last home icons config from disk
            xpcall(function()
                -- todo: put json in file
                local defaultCachedIcons = "{\"icons\":[{\"title\":\"限时秒杀\",\"image\":\"http://t04img.yangkeduo.com/images/2018-03-29/abaf733d423c66bb0d0dcde75861c537.png\",\"link\":\"spike.html\",\"style\":2,\"log_sn\":99956,\"group\":1},{\"title\":\"品牌清仓\",\"image\":\"http://t01img.yangkeduo.com/images/2018-03-29/a8cf508cbf09a5851ad48db9fc1dedcf.png\",\"link\":\"subjects.html?subjects_id=14\",\"style\":1,\"log_sn\":99955,\"group\":2},{\"title\":\"名品折扣\",\"image\":\"http://t01img.yangkeduo.com/images/2018-03-29/4b0602e5f14505e05888d55d6b1147f7.png\",\"link\":\"subjects.html?subjects_id=21\",\"style\":0,\"log_sn\":99294,\"group\":3},{\"title\":\"天天领现金\",\"image\":\"http://t01img.yangkeduo.com/images/2018-03-29/242551c4d32ea8eb537af7ae5b7ffbf3.png\",\"link\":\"mkt_lucky_bag736.html\",\"style\":0,\"log_sn\":98477,\"group\":4},{\"title\":\"助力享免单\",\"image\":\"http://t05img.yangkeduo.com/images/2018-03-29/8380bf07fc168aeaf0c223299da6488c.png\",\"link\":\"mkt_assist_free.html?cid=assist_icon_new\",\"style\":0,\"log_sn\":99287,\"group\":5},{\"title\":\"手机充值\",\"image\":\"http://t03img.yangkeduo.com/images/2018-03-29/c010ce6da8ec9476f2de5ea874e4683f.png\",\"link\":\"deposit.html\",\"style\":0,\"log_sn\":99293,\"group\":11},{\"title\":\"转盘领现金\",\"image\":\"http://t05img.yangkeduo.com/images/2018-03-29/1370c1fd45e72601cf59cf845031217c.png\",\"link\":\"mkt_roulette.html\",\"style\":0,\"log_sn\":98791,\"group\":12},{\"title\":\"爱逛街\",\"image\":\"http://t08img.yangkeduo.com/images/2018-03-29/abcf947ba7e0a86a50c2416a27923602.png\",\"link\":\"subjects.html?subjects_id=15\",\"style\":0,\"log_sn\":99290,\"group\":6},{\"title\":\"9块9特卖\",\"image\":\"http://t08img.yangkeduo.com/images/2018-03-30/a00ca10171f3cc646aac37e7fcca8a27.png\",\"link\":\"subjects.html?subjects_id=12\",\"style\":0,\"log_sn\":99952,\"group\":7},{\"title\":\"现金签到\",\"image\":\"http://t08img.yangkeduo.com/images/2018-03-29/03ae5bb1d47ef2470be4d378f9042c50.png\",\"link\":\"mkt_daily_bonus999.html\",\"style\":0,\"log_sn\":99288,\"group\":8},{\"title\":\"食品超市\",\"image\":\"http://t03img.yangkeduo.com/images/2018-03-29/ee7a0c657a8753e97e772af9a7af8d86.png\",\"link\":\"subjects.html?subjects_id=17\",\"style\":0,\"log_sn\":99291,\"group\":9},{\"title\":\"砍价免费拿\",\"image\":\"http://t10img.yangkeduo.com/images/2018-03-29/e5a427e67858d57a1bcdbfd8bdcff26d.png\",\"link\":\"mkt_bargain_list.html\",\"style\":0,\"log_sn\":99003,\"group\":10},{\"title\":\"时尚穿搭\",\"image\":\"http://t10img.yangkeduo.com/images/2018-03-29/dc0feb5bb50439ddf02725186c4a578a.png\",\"link\":\"subjects.html?subjects_id=22\",\"style\":0,\"log_sn\":99946,\"group\":13},{\"title\":\"海淘\",\"image\":\"http://t05img.yangkeduo.com/images/2018-03-29/678e4fe87877488fa8c8e5d5174395b1.png\",\"link\":\"haitao.html\",\"style\":0,\"log_sn\":99948,\"group\":14}],\"size\":14}"
                local cachedIcons = aimi.KVStorage.getInstance():get(HOME_SERVER_ICONS_CACHE_KEY)
                if Version.new(aimi.Application.getApplicationVersion()) < Version.new("4.7.0") then
                    cachedIcons = defaultCachedIcons;
                end

                if type(cachedIcons) ~= "string" or #cachedIcons == 0 then
                    cachedIcons = defaultCachedIcons
                end
                
                if type(cachedIcons) == "string" and #cachedIcons > 0 then
                    local result = json.decode(cachedIcons)
                    if type(result) == "table" then
                        icons = result["icons"]
                    end
                end

                if not isValidIconList(icons) then
                    local result = json.decode(defaultCachedIcons)
                    if type(result) == "table" then
                        icons = result["icons"]
                    end
                end

            end, AMBridge.error)
        end

        if isValidIconList(icons) then
            self:fillQuickEntranceDataFromResponse(icons)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
    end

    Promise.new(function(resolve, reject)
        return APIService.getJSON("api/cappuccino/icon_set?platform=1&version=3"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            updateHomeIconsList(nil)
            reject(reason)
        end)
    end):next(function(response)
        local icons = response.responseJSON["icons"]
        AMBridge.call("AMLog", "log", {
            ["message"] = "icons=".. tostring(icons) .. " size = " .. tostring(response.responseJSON["size"])
        })
        updateHomeIconsList(icons)

        if isValidIconList then
            xpcall(function()
                local cachedIcons = tostring(json.encode(response.responseJSON))
                if type(cachedIcons) == "string" and #cachedIcons > 0 then
                    aimi.KVStorage.getInstance():set(HOME_SERVER_ICONS_CACHE_KEY, cachedIcons)
                end
            end, AMBridge.error)
        end
    end)
end

function HomeScene:checkUser()
    Promise.new(function(resolve, reject)
        return APIService.getJSON("user/is_ab"):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local egrp = response.responseJSON["egrp"]
        local restrictedUserFlag = 1
        if egrp ~= nil and egrp ~= 2 and egrp ~= 3 then
            restrictedUserFlag = 0
        end

        print('------------egrp=',egrp)
        AMBridge.call("AMLog", "log", {
            ["message"] = "egrp=".. egrp
        })

        if self.restrictedUserFlag_ ~= restrictedUserFlag then
            self:setRestrictedUserFlag(restrictedUserFlag)
        end

        if self.egrp_ ~= egrp then
            self:setUserEgrp(egrp)
            self:setQuickEntranceDirty(true)
            self:updateQuickEntrances()
        end
    end)
end

function HomeScene:dailyShowRedBadge(key)
    if key == COMMERCIAL_BARGAIN_LIST_KEY or key == Constant.ICON_GROUP.CommercialBargainList then
        return self.flags_["pdd_bargin_expose_number"] == nil or self.flags_["pdd_bargin_expose_number"] <= 3
    end

    if key == "money_tree" then
        return true
    end

    if key == LUCKY_BAG_KEY or key == Constant.ICON_GROUP.LuckyBag then
        return true
    end

    if key == INDEX_SUPER_SPIKE_KEY or key == Constant.ICON_GROUP.SuperSpike then
        return true
    end

    if key == "index_go_shopping" or key == Constant.ICON_GROUP.GoShopping then
        local now = os.time()
        local startTime = os.time{year=2018, month=3, day=13, hour=0, min=0, sec=0}
        local endTime = os.time{year=2018, month=3, day=19, hour=23, min=59, sec=59}

        if now >= startTime and now < endTime then 
            return true
        end
            return false
    end

    -- if key == INDEX_SUPER_SPIKE_KEY then
    --     local now = os.time()
    --     local startTime = os.time{year=2017, month=10, day=23, hour=0, min=0, sec=0}
    --     local endTime = os.time{year=2017, month=10, day=25, hour=23, min=59, sec=59}

    --     if now >= startTime and now < endTime then 
    --         return false
    --     end
    --     return true
    -- end

    if key == INDEX_SPIKE_KEY or key == Constant.ICON_GROUP.Spike then
        return true
    end

    if key == SIGN_KEY or key == Constant.ICON_GROUP.SignIn then
        return true
    end

    return false
end

function HomeScene:updateQuickEntrances()
    local dailyBadgeEntrances = {}
    local updated = false

    self:setBadge()

    local now = os.time()
    local today = os.date("*t", now).day
    if Version.new(aimi.Application.getApplicationVersion()) >= HOME_ICONS_SERVER_CONFIG and self.flags_["pdd_home_icon_config"] == 1 then
        if HomeScene.HostConfigQuickEntrance == nil or  HomeScene.HostConfigQuickEntrance == {} then
            self:configQuickEntrances()
            return
        end

        for key, entrance in pairs(HomeScene.HostConfigQuickEntrance) do
            if entrance["group"] ~= nil then
               dailyBadgeEntrances[entrance["group"]] = entrance 
           end
        end

        for key, entrance in pairs(dailyBadgeEntrances) do
            if (key == Constant.ICON_GROUP.SignIn or key == Constant.ICON_GROUP.LuckyBag) and (entrance["tipUrl"] == nil or entrance["tipUrl"] ~= entrance["badge"]) then
                entrance["tipUrl"] = entrance["badge"]
                updated = true
            elseif self.lastViewQuickEntranceDays_[key] ~= today and (entrance["tipUrl"] == nil or entrance["tipUrl"] ~= entrance["badge"]) then
                entrance["tipUrl"] = entrance["badge"]
                updated = true
            end
        end
    else 
        if self:isNewRedLogicVersion() then
            dailyBadgeEntrances[HomeScene.NewQuickEntrance.SuperSpike["key"]] = HomeScene.NewQuickEntrance.SuperSpike
            dailyBadgeEntrances[HomeScene.NewQuickEntrance.Spike["key"]] = HomeScene.NewQuickEntrance.Spike
            dailyBadgeEntrances[SIGN_KEY] = HomeScene.NewQuickEntrance.SignIn
            dailyBadgeEntrances[HomeScene.NewQuickEntrance.LuckyBag["key"]] = HomeScene.NewQuickEntrance.LuckyBag
            dailyBadgeEntrances[HomeScene.NewQuickEntrance.MoneyTree["key"]] = HomeScene.NewQuickEntrance.MoneyTree

            for key, entrance in pairs(dailyBadgeEntrances) do
                if self:dailyShowRedBadge(key) then
                    if (key == SIGN_KEY or key == LUCKY_BAG_KEY or key == "money_tree") and (entrance["tipUrl"] == nil or entrance["tipUrl"] ~= entrance["badge"]) then
                        entrance["tipUrl"] = entrance["badge"]
                        updated = true
                    elseif self.lastViewQuickEntranceDays_[key] ~= today and (entrance["tipUrl"] == nil or entrance["tipUrl"] ~= entrance["badge"]) then
                        entrance["tipUrl"] = entrance["badge"]
                        updated = true
                    end
                end
            end
        else
            dailyBadgeEntrances[HomeScene.QuickEntrance.SuperSpike["key"]] = HomeScene.QuickEntrance.SuperSpike
            for key, entrance in pairs(dailyBadgeEntrances) do
                if self.lastViewQuickEntranceFlags_[key] ~= 1 and entrance["tipUrl"] == nil then
                    entrance["tipUrl"] = entrance["badge"]
                    updated = true
                end
            end
        end
    end  

    if not updated and not self.isQuickEntranceDirty_ then
        return
    end

    if updated then
        self:saveLastViewQuickEntranceFlags()
    end

    self:configQuickEntrances()
end

function HomeScene:configQuickEntrances()
    self:setQuickEntranceDirty(false)
    local entrances = {}
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_VERSION then
        table.insert(entrances, HomeScene.QuickEntrance.Spike)
        table.insert(entrances, HomeScene.QuickEntrance.SuperSpike)
        table.insert(entrances, HomeScene.QuickEntrance.Bargain)
        table.insert(entrances, HomeScene.QuickEntrance.OneYuanBuy)
        table.insert(entrances, HomeScene.QuickEntrance.FreeTrial)
        table.insert(entrances, HomeScene.QuickEntrance.Lottery)
        table.insert(entrances, HomeScene.QuickEntrance.Food)
        table.insert(entrances, HomeScene.QuickEntrance.Clothes)
        table.insert(entrances, HomeScene.QuickEntrance.Household)
        table.insert(entrances, HomeScene.QuickEntrance.DigitalAppliances)
        table.insert(entrances, HomeScene.QuickEntrance.Maternity)
        table.insert(entrances, HomeScene.QuickEntrance.Cosmetics)
        table.insert(entrances, HomeScene.QuickEntrance.Oversea)
    elseif Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_TEN_ICONS_VERSION then
        entrances = self:entrancesWithEightIcons()
    elseif Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_ENTRANCE_SUPPORT_SIDESLIP_VERSION then
        entrances = self:entrancesWithTenIcons()
    elseif Version.new(aimi.Application.getApplicationVersion()) < HOME_ICONS_WITH_NEW_OPT_UI then
        entrances = self:entrancesSupportSideslip()
    elseif Version.new(aimi.Application.getApplicationVersion()) < HOME_ICONS_SERVER_CONFIG then
        entrances = self:entrancesWithNewOpt()
    else
        entrances = self:entranceConfigByHost()
    end

    if type(entrances) == "table" and #entrances > 0 then
        self.iconsReady_ = true
        AMBridge.call("HomeScene", "configQuickEntries", {
            ["entrances"] = entrances,
        }, nil, HomeScene.instance():getContextID())
    end
end

function HomeScene:entrancesWithEightIcons()
    local entrances = {}
    table.insert(entrances, HomeScene.NewQuickEntrance.Spike)
    table.insert(entrances, HomeScene.NewQuickEntrance.SuperSpike)
    table.insert(entrances, HomeScene.NewQuickEntrance.Maternal)
    table.insert(entrances, HomeScene.NewQuickEntrance.ChargeCenter)
    table.insert(entrances, HomeScene.NewQuickEntrance.Fruits)
    table.insert(entrances, HomeScene.NewQuickEntrance.GoShopping)
    table.insert(entrances, HomeScene.NewQuickEntrance.Furniture)
    table.insert(entrances, HomeScene.NewQuickEntrance.Food)
    return entrances
end

function HomeScene:entrancesWithTenIcons()
    local entrances = {}
    table.insert(entrances, HomeScene.NewQuickEntrance.Spike)
    table.insert(entrances, HomeScene.NewQuickEntrance.SuperSpike)
    table.insert(entrances, HomeScene.NewQuickEntrance.EconomicalBrand)
    table.insert(entrances, HomeScene.NewQuickEntrance.Fruits)
    table.insert(entrances, HomeScene.NewQuickEntrance.Maternal)

    table.insert(entrances, HomeScene.NewQuickEntrance.GoShopping)
    table.insert(entrances, HomeScene.NewQuickEntrance.Bargain)
    table.insert(entrances, HomeScene.NewQuickEntrance.SignIn)
    table.insert(entrances, HomeScene.NewQuickEntrance.Food)
    table.insert(entrances, HomeScene.NewQuickEntrance.ChargeCenter)

    return entrances
end

function HomeScene:updateEntranceName()
    local activityDay = false
    local nowTime = os.time()
    if nowTime >= os.time{year=2017, month=12, day=12, hour=0, min=0, sec=0} and nowTime < os.time{year=2017, month=12, day=13, hour=0, min=0, sec=0} then
        activityDay = true
    end

    HomeScene.NewQuickEntrance.SuperSpike["name"] = (activityDay and "清仓会场") or "品牌清仓"
    HomeScene.NewQuickEntrance.EconomicalBrand["name"] = (activityDay and "品牌会场") or "名品折扣"
    HomeScene.NewQuickEntrance.Food["name"] = (activityDay and "美食会场") or "美食汇"
    HomeScene.NewQuickEntrance.FoodV2["name"] = (activityDay and "美食会场") or "食品超市"
    HomeScene.NewQuickEntrance.GoShopping["name"] = (activityDay and "服饰会场") or "爱逛街"
    HomeScene.NewQuickEntrance.SlightlyLuxurious["name"] = (activityDay and "潮流会场") or "时尚穿搭"
    HomeScene.NewQuickEntrance.Oversea["name"] = (activityDay and "海淘会场") or "海淘"
    HomeScene.NewQuickEntrance.ChargeCenter["name"] = (activityDay and "充值会场") or "手机充值"
end

function HomeScene:entrancesSupportSideslip()
    self:updateEntranceName()

    local entrances = {}
    -- 16 icons
    table.insert(entrances, HomeScene.NewQuickEntrance.Spike)
    table.insert(entrances, HomeScene.NewQuickEntrance.GoShopping)

    table.insert(entrances, HomeScene.NewQuickEntrance.SuperSpike)
    table.insert(entrances, HomeScene.NewQuickEntrance.Bargain)

    table.insert(entrances, HomeScene.NewQuickEntrance.EconomicalBrand)
    if self.signInEntryFlag_ == 1 then
        table.insert(entrances, HomeScene.NewQuickEntrance.SignIn)
    else
        table.insert(entrances, HomeScene.NewQuickEntrance.Fruits)
    end

    table.insert(entrances, HomeScene.NewQuickEntrance.Oversea)
    table.insert(entrances, HomeScene.NewQuickEntrance.FoodV2)

    table.insert(entrances, HomeScene.NewQuickEntrance.AssistFreeCoupon)
    table.insert(entrances, HomeScene.NewQuickEntrance.CommercialBargainList)

    table.insert(entrances, HomeScene.NewQuickEntrance.ChargeCenter)
    table.insert(entrances, HomeScene.NewQuickEntrance.ElectricalAppliance)

    table.insert(entrances, HomeScene.NewQuickEntrance.Furniture)
    table.insert(entrances, HomeScene.NewQuickEntrance.SlightlyLuxurious)

    table.insert(entrances, HomeScene.NewQuickEntrance.Maternal)
    table.insert(entrances, HomeScene.NewQuickEntrance.OneCent)

    self:replaceActivityEntrancesIcons(entrances)

    return entrances
end

function HomeScene:entranceConfigByHost()
    if self.flags_["pdd_home_icon_config"] == nil or  self.flags_["pdd_home_icon_config"] == 0 then
        return self:entrancesWithNewOpt()
    end

    if HomeScene.HostConfigQuickEntrance == nil or HomeScene.HostConfigQuickEntrance == {} then
        return
    end

    local entrances = HomeScene.HostConfigQuickEntrance
    self:resetConfigImageUrl(entrances);
    return entrances
end

function HomeScene:resetConfigImageUrl(entrances)
    local now = os.time()
    local allIntegrationTime = now > os.time{year=2018, month=6, day=16, hour=0, min=0, sec=0} and now < os.time{year=2018, month=6, day=18, hour=23, min=59, sec=59}
    if not allIntegrationTime then
        return;
    end

    for key, entrance in pairs(entrances) do
        local group = entrance["group"]
        if group == "1" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/spike_new.png")
        elseif group == "2" then
             entrance["imgUrl"] = self:getHomeIconByName("activity/super_spike_new.png")
        elseif group == "3" then
           entrance["imgUrl"] = self:getHomeIconByName("activity/economical_brand.png")
        elseif group == "4" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/lucky_bag.png")
        elseif group == "5" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/assist_free_coupon.png")
        elseif group == "11" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/charge_center.png")
        elseif group == "41" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/assist_group.png")
        elseif group == "6" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/go_shopping.png")
        elseif group == "7" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/bargain_new.png")
        elseif group == "8" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/sign_in.png")
        elseif group == "9" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/food_v2.png")
        elseif group == "10" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/commercial_bargain_list.png")
        elseif group == "13" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/aiqingshe.png")
        elseif group == "14" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/global_shop.png")
        elseif group == "12" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/roulette.png")
        elseif group == "26" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/one_cent.png")
        elseif group == "24" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/browse_ad.png")
        elseif group == "45" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/man_group.png")
        elseif group == "46" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/lucky_group.png")
        elseif group == "47" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/world_cup.png")
        elseif group == "48" then
            entrance["imgUrl"] = self:getHomeIconByName("activity/daily_mission.png")
        end
    end
end

function HomeScene:needReplaceRoulette(icon)
    local now = os.time()
    local endTime = os.time{year=2018, month=4, day=11, hour=0, min=0, sec=0}

    if now < endTime then
        return true
    else
        return false
    end
end

function HomeScene:entrancesWithNewOpt()
    local loginByQQ = false
    local loginType = tonumber(aimi.KVStorage.getInstance():getSecure(Constant.LoginTypeKey))
    print("loginType=",loginType)
    if loginType ~= nil and loginType == Constant.LoginTypeQQ then
        loginByQQ = true
    end

    if loginByQQ then
        return self:entrancesLoginTyQQ()
    end

    print("entrancesWithNewOpt function address", self["entrancesWithNewOpt"], HomeScene["entrancesWithNewOpt"]) 
    self:updateEntranceName()

    local entrances = {}
    -- 16 icons
    table.insert(entrances, HomeScene.NewQuickEntrance.Spike)
    table.insert(entrances, HomeScene.NewQuickEntrance.GoShopping)

    table.insert(entrances, HomeScene.NewQuickEntrance.SuperSpike)
    table.insert(entrances, HomeScene.NewQuickEntrance.Bargain)

    if self.browseAdIconFlag_ == 1 then
        table.insert(entrances, HomeScene.NewQuickEntrance.BrowseAd)
    else
        table.insert(entrances, HomeScene.NewQuickEntrance.EconomicalBrand)
    end
    if self.signInEntryFlag_ == 1 then
        table.insert(entrances, HomeScene.NewQuickEntrance.SignIn)
    else
        table.insert(entrances, HomeScene.NewQuickEntrance.Maternal)
    end

    table.insert(entrances, HomeScene.NewQuickEntrance.LuckyBag)
    table.insert(entrances, HomeScene.NewQuickEntrance.FoodV2)        
    table.insert(entrances, HomeScene.NewQuickEntrance.OneCent)    
    table.insert(entrances, HomeScene.NewQuickEntrance.CommercialBargainList)
    table.insert(entrances, HomeScene.NewQuickEntrance.ChargeCenter)
    table.insert(entrances, HomeScene.NewQuickEntrance.SlightlyLuxurious)
    table.insert(entrances, HomeScene.NewQuickEntrance.AssistFreeCoupon)
    table.insert(entrances, HomeScene.NewQuickEntrance.Oversea)
    table.insert(entrances, HomeScene.NewQuickEntrance.Roulette)
    table.insert(entrances, HomeScene.NewQuickEntrance.HelpFreeGroup)
    self:replaceActivityEntrancesIcons(entrances)

    return entrances
end

function HomeScene:entrancesLoginTyQQ()
    self:updateEntranceName()

    local entrances = {}
    -- 16 icons
    table.insert(entrances, HomeScene.NewQuickEntrance.Spike)
    table.insert(entrances, HomeScene.NewQuickEntrance.GoShopping)

    table.insert(entrances, HomeScene.NewQuickEntrance.SuperSpike)
    table.insert(entrances, HomeScene.NewQuickEntrance.Bargain)

    if self.browseAdIconFlag_ == 1 then
        table.insert(entrances, HomeScene.NewQuickEntrance.BrowseAd)
    else
        table.insert(entrances, HomeScene.NewQuickEntrance.EconomicalBrand)
    end
    if self.signInEntryFlag_ == 1 then
        table.insert(entrances, HomeScene.NewQuickEntrance.SignIn)
    else
        table.insert(entrances, HomeScene.NewQuickEntrance.Maternal)
    end

    table.insert(entrances, HomeScene.NewQuickEntrance.AssistFreeCoupon)    
    table.insert(entrances, HomeScene.NewQuickEntrance.FoodV2)
    table.insert(entrances, HomeScene.NewQuickEntrance.CommercialBargainList)
    table.insert(entrances, HomeScene.NewQuickEntrance.Roulette)
    table.insert(entrances, HomeScene.NewQuickEntrance.ChargeCenter)
    table.insert(entrances, HomeScene.NewQuickEntrance.SlightlyLuxurious)
    table.insert(entrances, HomeScene.NewQuickEntrance.LuckyBag)
    table.insert(entrances, HomeScene.NewQuickEntrance.Oversea)
    table.insert(entrances, HomeScene.NewQuickEntrance.OneCent)
    table.insert(entrances, HomeScene.NewQuickEntrance.HelpFreeGroup)
    self:replaceActivityEntrancesIcons(entrances)

    return entrances
end

function HomeScene:needsShowHaitaoIcon()
    return FriendGray.isChatTabEnabled()
end

function HomeScene:setActivity(activity)
    self.isActivity_ = activity
end

function HomeScene:setEntrancesSideslipFlag(flag)
    self.entrancesSideslipFlag_ = flag
end

function HomeScene:replaceActivityEntrancesIcons(entrances)
    -- local function updateForDoule11Activity1()
    --     local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    --     for i, entrance in ipairs(entrances) do
    --         entrance["imgUrl"] = self:getHomeIconByName("activity/1204/" .. i ..".png")
    --     end
    -- end

    -- local function updateForActivity()
    --     local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    --     local newHomeIcons = Version.new(aimi.Application.getApplicationVersion()) >= NEW_HOME_ENTRANCE_ICONS
    --     if not newHomeIcons then
    --         return
    --     end

    --     if #entrances == 14 then
    --         for i, entrance in ipairs(entrances) do
    --             entrance["imgUrl"] = self:getHomeIconByName("activity/14icons/" .. i ..".png")
    --         end
    --     elseif #entrances == 16 then
    --         for i, entrance in ipairs(entrances) do
    --             entrance["imgUrl"] = self:getHomeIconByName("activity/16icons/" .. i ..".png")
    --         end
    --     end
    -- end

    -- local now = os.time()
    -- if now >= HOME_ACTIVITY_INTEGRATION_START_TIME and now < HOME_ACTIVITY_INTEGRATION_END_TIME then
    --     updateForActivity()
    -- else
    --     self:resetEntrancesIcons()
    -- end

    self:resetEntrancesIcons()
end

function HomeScene:getSpikeImageURL()
    local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    local newHomeIcons = Version.new(aimi.Application.getApplicationVersion()) >= NEW_HOME_ENTRANCE_ICONS

    local spikeImageName = "spike_new.png"
    return self:getHomeIconByName(spikeImageName)
end

function HomeScene:getSuperSpikeImageURL()
    local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    local superSpikeImageName = "super_spike_new.png"
    local now = os.time()
    local startTime = os.time{year=2018, month=3, day=25, hour=0, min=0, sec=0}
    local endTime = os.time{year=2018, month=3, day=27, hour=23, min=59, sec=59}
    if now >= startTime and now < endTime then
        local newHomeIcons = Version.new(aimi.Application.getApplicationVersion()) >= NEW_HOME_ENTRANCE_ICONS
        if newHomeIcons then
            superSpikeImageName = "super_spike_new_activity.gif"
        end
        print('superSpikeImageName=',superSpikeImageName)
    end
    return self:getHomeIconByName(superSpikeImageName)
end

function HomeScene:resetEntrancesIcons()

    local host = ComponentManager.getComponentHost(ComponentManager.LuaComponentName)
    HomeScene.NewQuickEntrance.Spike["imgUrl"] = self:getSpikeImageURL()
    HomeScene.NewQuickEntrance.SuperSpike["imgUrl"] = self:getSuperSpikeImageURL()
    HomeScene.NewQuickEntrance.Fruits["imgUrl"] = self:getHomeIconByName("fruits.png")
    HomeScene.NewQuickEntrance.GoShopping["imgUrl"] = self:getHomeIconByName("go_shopping.png")
    HomeScene.NewQuickEntrance.Bargain["imgUrl"] = self:getHomeIconByName("bargain_new.png")
    HomeScene.NewQuickEntrance.FreeTrial["imgUrl"] = self:getHomeIconByName("free_trial_new.png")
    HomeScene.NewQuickEntrance.Family["imgUrl"] = self:getHomeIconByName("family.png")
    HomeScene.NewQuickEntrance.SlightlyLuxurious["imgUrl"] = self:getHomeIconByName("aiqingshe.png")
    HomeScene.NewQuickEntrance.ElectricalAppliance["imgUrl"] = self:getHomeIconByName("electrical_appliance.png")
    HomeScene.NewQuickEntrance.Oversea["imgUrl"] = self:getHomeIconByName("global_shop.png")
    HomeScene.NewQuickEntrance.Food["imgUrl"] = self:getHomeIconByName("food.png")
    HomeScene.NewQuickEntrance.FoodV2["imgUrl"] = self:getHomeIconByName("food_v2.png")
    HomeScene.NewQuickEntrance.Furniture["imgUrl"] = self:getHomeIconByName("furniture.png")
    HomeScene.NewQuickEntrance.ChargeCenter["imgUrl"] = self:getHomeIconByName("charge_center.png")
    HomeScene.NewQuickEntrance.Maternal["imgUrl"] = self:getHomeIconByName("maternal.png")
    HomeScene.NewQuickEntrance.EconomicalBrand["imgUrl"] = self:getHomeIconByName("economical_brand.png")
    HomeScene.NewQuickEntrance.BrowseAd["imgUrl"] = self:getHomeIconByName("browse_ad.png")
    HomeScene.NewQuickEntrance.NewCustomer["imgUrl"] = self:getHomeIconByName("new_customer.png")
    HomeScene.NewQuickEntrance.SignIn["imgUrl"] = self:getHomeIconByName("sign_in.png")
    HomeScene.NewQuickEntrance.AssistFreeCoupon["imgUrl"] = self:getHomeIconByName("assist_free_coupon.png")
    HomeScene.NewQuickEntrance.LoveLux["imgUrl"] = self:getHomeIconByName("lovelux.png")
    HomeScene.NewQuickEntrance.OneCent["imgUrl"] = self:getHomeIconByName("one_cent.png")
    HomeScene.NewQuickEntrance.CommercialBargainList["imgUrl"] = self:getHomeIconByName("commercial_bargain_list.png")
    HomeScene.NewQuickEntrance.Roulette["imgUrl"] = self:getHomeIconByName("roulette.png")
    HomeScene.NewQuickEntrance.RankHot["imgUrl"] = self:getHomeIconByName("rank_hot.png")
    HomeScene.NewQuickEntrance.LuckyBag["imgUrl"] = self:getHomeIconByName("lucky_bag.png")
    HomeScene.NewQuickEntrance.MoneyTree["imgUrl"] = self:getHomeIconByName("money_tree.png")
    HomeScene.NewQuickEntrance.HelpFreeGroup["imgUrl"] = self:getHomeIconByName("assist_group.png")
end

function HomeScene:updateMenuTitles()
    if Version.new(aimi.Application.getApplicationVersion()) < NEW_HOME_VERSION then
        return
    end

    local menuTitles = {}
    table.insert(menuTitles, HomeScene.MenuTitle.Recommend)
    table.insert(menuTitles, HomeScene.MenuTitle.Clothes)
    table.insert(menuTitles, HomeScene.MenuTitle.Maternity)
    table.insert(menuTitles, HomeScene.MenuTitle.Food)
    table.insert(menuTitles, HomeScene.MenuTitle.Household)
    table.insert(menuTitles, HomeScene.MenuTitle.DigitalAppliances)

    table.insert(menuTitles, HomeScene.MenuTitle.Textile)
    table.insert(menuTitles, HomeScene.MenuTitle.Fruits)
    table.insert(menuTitles, HomeScene.MenuTitle.Cosmetics)


    AMBridge.call("HomeScene", "configMenuTitles", {
        ["menuTitles"] = menuTitles
    }, nil, HomeScene.instance():getContextID())
end

function HomeScene:loadQuickEntranceRelated()
    if self:isNewRedLogicVersion() then
        self:loadQuickEntranceRelated2()
        return
    end

    if self.lastViewQuickEntranceFlags_ ~= nil then
        return
    end

    xpcall(function()
        local value = aimi.KVStorage.getInstance():get(LAST_VIEW_FLAG_KEY)
        self.lastViewQuickEntranceFlags_ = value and json.decode(value)
    end, AMBridge.error)

    if self.lastViewQuickEntranceFlags_ == nil then
        self.lastViewQuickEntranceFlags_ = {}
    end
end

function HomeScene:loadQuickEntranceRelated2()
    if self.lastViewQuickEntranceDays_ ~= nil then
        return
    end

    xpcall(function()
        local value = aimi.KVStorage.getInstance():get(LAST_VIEW_UPDATED_TIME_KEY)
        self.lastViewQuickEntranceDays_ = value and json.decode(value)
    end, AMBridge.error)

    if self.lastViewQuickEntranceDays_ == nil then
        self.lastViewQuickEntranceDays_ = {}
    end
end

function HomeScene:updateLastViewQuickEntranceFlags(key)
    if self:isNewRedLogicVersion() then
        self:updateLastViewQuickEntranceDays(key)
        return
    end

    if self.lastViewQuickEntranceFlags_[key] ~= 1 then
        self.lastViewQuickEntranceFlags_[key] = 1
        self:saveLastViewQuickEntranceFlags()
    end
end

function HomeScene:saveLastViewQuickEntranceFlags()
    if self:isNewRedLogicVersion() then
        self:saveLastViewQuickEntranceDays()
        return
    end

    aimi.KVStorage.getInstance():set(LAST_VIEW_FLAG_KEY, json.encode(self.lastViewQuickEntranceFlags_))
end

function HomeScene:updateLastViewQuickEntranceDays(key)
    local today = os.date("*t", os.time()).day
    if self.lastViewQuickEntranceDays_[key] ~= today then
        self.lastViewQuickEntranceDays_[key] = today
        self:saveLastViewQuickEntranceDays()
    end
end

function HomeScene:saveLastViewQuickEntranceDays()
    aimi.KVStorage.getInstance():set(LAST_VIEW_UPDATED_TIME_KEY, json.encode(self.lastViewQuickEntranceDays_))
end

function HomeScene:loadBootInfo()
    AMBridge.call("PDDBoot", "info", nil, function(errorCode, response)
        if response == nil then
            return
        end

        if response["type"] == 1 then
            self:setNeedsDelayReq(true)
        end
    end)
end

function HomeScene:setNeedsDelayReq(needsDelayReq)
    self.needsDelayReq_ = needsDelayReq
end

function HomeScene:addTaskToQueue()
    local delayTime = 0
    if self.needsDelayReq_ == true then
        delayTime = math.random(30)
    end
    
    aimi.Scheduler.getInstance():schedule(delayTime, function()
        -- Application.getSharedTaskQueue():push(CheckMarketActivityTask.run)
        -- Application.getSharedTaskQueue():push(CheckAssistFreeCouponTask.run)
        Application.getSharedTaskQueue():push(CheckCommonActivityTaskV2.run)
        Application.getSharedTaskQueue():push(CheckUnpaidOrderTask.run)
        Application.getSharedTaskQueue():push(CheckCashCouponTask.run)
        Application.getSharedTaskQueue():push(CheckSignInTask.run)
    end)
end

function HomeScene:addTaskToQueue2()
    aimi.Scheduler.getInstance():schedule(0, function()
        -- Application.getSharedTaskQueue():push(CheckMarketActivityTask.run)
        -- Application.getSharedTaskQueue():push(CheckAssistFreeCouponTask.run)
        Application.getSharedTaskQueue():push(CheckCommonActivityTaskV2.run)        
        Application.getSharedTaskQueue():push(CheckUnpaidOrderTask.run)
        Application.getSharedTaskQueue():push(CheckCashCouponTask.run)
        Application.getSharedTaskQueue():push(CheckSignInTask.run)
        Application.getSharedTaskQueue():push(CheckAppActivityTask.run)
    end)
end

return HomeScene