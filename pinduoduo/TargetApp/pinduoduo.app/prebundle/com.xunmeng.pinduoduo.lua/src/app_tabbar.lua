TabBar = TabBar or {}

TabBar.Tabs = {}
TabBar.Tabs.Home = 1
TabBar.Tabs.Rank = 2
TabBar.Tabs.Oversea = 3
TabBar.Tabs.Search =  (aimi.appVersion() >= _V("3.38.0") and 3) or 4
TabBar.Tabs.Personal = 5
-- 3.38.0版本后才有
TabBar.Tabs.Chat = 4

TabBar.FriendChatEnableKey = "FriendChatEnabelKey"
TabBar.MallChatEnableKey = "MallChatEnableKey"

TabBar.Types = {}
TabBar.Types.Haitao = 0
TabBar.Types.Mall = 1
TabBar.Types.Friend = 2

local componentDomain = "amcomponent://com.xunmeng.pinduoduo.lua/"
local tabs = {}
local tabItems = {}

local isRecommendTabEnabled = (aimi.appVersion() >= _V("4.0.0"))

local function isActivityTime()
    local startTime = os.time{year=2018, month=6, day=8, hour=0, min=0, sec=0}
    local endTime = os.time{year=2018, month=6, day=20, hour=23, min=59, sec=59}
    local now = os.time()

    if now >= startTime and now < endTime then
        return true
    end

    return false
end

local function getTabIconURLByName(name, selected)
    print('name=',name,'selected=',selected)
    if aimi.appVersion() < _V("3.49.0") then
        return componentDomain .. "image/" .. name
    end

    local imageVersion = "v2"
    if isRecommendTabEnabled then
        imageVersion = "v3"
    end

    local imageFolder = "image/" .. imageVersion .. "/"

    if not selected then
        return componentDomain .. imageFolder .. name
    end

    if isActivityTime() then
        return componentDomain .. "image/v3/activity/" .. name
    end

    return componentDomain .. imageFolder .. name
end

local function getIconHeight()
    -- 3.49.0版本统一调整了tabbar高度为24
    if aimi.appVersion() < _V("3.49.0") then
        return 23
    end

    return 24
end

local function getIconHeightByClickStatus(selected)
    -- 3.49.0版本统一调整了tabbar高度为24
    if aimi.appVersion() < _V("3.49.0") then
        return 23
    end

    if isActivityTime() and selected then
        return 33
    end

    return 24
end

local function prepareReplaceTabs(barType)
    local normalColor = 0x777777
    local highlightedColor = 0xe02e24

    local replaceTabs = {}
    local replaceTabItems = {}

    if aimi.appVersion() < _V("3.47.0") then
        return {}
    end

    -- 如果关掉灰度，如果是新版搜索，换成旧版搜索
    local index = 1
    if tabs[TabBar.Tabs.Search]["style"] == "2" then
        replaceTabItems[index] = {
            ["tab_index"] = TabBar.Tabs.Search - 1,
            ["title"] = "搜索",
            ["normal"] = {
                ["title_color"] = normalColor,
                ["icon"] = {
                    ["url"] =  getTabIconURLByName("search-new-ui.png", false),
                    ["height"] = getIconHeight(),
                },
            },
            ["highlighted"] = {
                ["title_color"] = highlightedColor,
                ["icon"] = {
                    ["url"] = getTabIconURLByName("search-new-ui-hl.png", true),
                    ["height"] = getIconHeightByClickStatus(true),
                },
            },
        }
        replaceTabs[index] = {
            ["type"] = (aimi.appVersion() >= _V("2.1.8")) and "pdd_search" or "web",
            ["props"] = {
                ["url"] = "classification.html",
            },
            ["navigation_bar"] = {
                ["title"] = "搜索",
            },
            ["tab_bar"] = {
                ["hidden"] = false,
            },
            ["tab_bar_item"] = replaceTabItems[index],
            ["style"] = "1"
        }
    end

    return replaceTabs
end

local function prepareTabs()
    if tabs[TabBar.Tabs.Home] ~= nil then
        return
    end

    local normalColor = 0x777777
    local highlightedColor = 0xe02e24

    tabItems[TabBar.Tabs.Home] = {
        ["tab_index"] = TabBar.Tabs.Home - 1,
        ["title"] = "首页",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("home.png", false),
                ["height"] = getIconHeight(),
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("home-hl.png", true),
                ["height"] = getIconHeightByClickStatus(true),
            },
        },
    }
    tabs[TabBar.Tabs.Home] = {
        ["type"] = "pdd_home",
        ["props"] = {
            ["lua_scene"] = "HomeScene",
            ["quick_entrances_each_row"] = 5
        },
        ["navigation_bar"] = {
            ["title"] = "拼多多",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Home],
    }

    local rankTabType = "web"
    local rankTabTitle = "新品"
    if isRecommendTabEnabled then
        rankTabType = "pdd_recommend_tab"
        rankTabTitle = "推荐"
    elseif aimi.appVersion() >= _V("2.3.0") then
        rankTabType = "rank"
        rankTabTitle = "新品"
    end

    tabItems[TabBar.Tabs.Rank] = {
        ["tab_index"] = TabBar.Tabs.Rank - 1,
        ["title"] = rankTabTitle,
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("rank.png", false),
                ["height"] = getIconHeight(),
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("rank-hl.png", true),
                ["height"] = getIconHeightByClickStatus(true),
            },
        },
    }

    tabs[TabBar.Tabs.Rank] = {
        ["type"] = rankTabType,
        ["props"] = {
            ["url"] = "new_arrivals.html",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Rank],
    }


    local tabItemTitle = "海淘"
    local normalIcon = "oversea.png"
    local selectedIcon = "oversea-hl.png"
    
    local pageType = (aimi.appVersion() > _V("2.1.3")) and "pdd_haitao" or "web"
    local pageUrl = "haitao.html"
    local pageTitle = "海淘专区"

    tabItems[TabBar.Tabs.Oversea] = {
        ["tab_index"] = TabBar.Tabs.Oversea - 1,
        ["title"] = tabItemTitle,
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] =  getTabIconURLByName(normalIcon, false),
                ["height"] = getIconHeight(),
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName(selectedIcon, true),
                ["height"] = getIconHeightByClickStatus(true),
            },
        },
    }
    tabs[TabBar.Tabs.Oversea] = {
        ["type"] = pageType,
        ["props"] = {
            ["url"] = pageUrl,
        },
        ["navigation_bar"] = {
            ["title"] = pageTitle,
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Oversea],
    }

    -- 搜索会覆盖海淘
    tabItems[TabBar.Tabs.Search] = {
        ["tab_index"] = TabBar.Tabs.Search - 1,
        ["title"] = "搜索",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("search-new-ui.png", false),
                ["height"] = getIconHeight(),
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("search-new-ui-hl.png", true),
                ["height"] = getIconHeightByClickStatus(true),
            },
        },
    }
    tabs[TabBar.Tabs.Search] = {
        ["type"] = (aimi.appVersion() >= _V("2.1.8")) and "pdd_search" or "web",
        ["props"] = {
            ["url"] = "classification.html",
        },
        ["navigation_bar"] = {
            ["title"] = "搜索",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Search],
        ["style"] = "1"
    }

    if aimi.appVersion() >= _V("3.38.0") then
        tabItems[TabBar.Tabs.Chat] = {
            ["tab_index"] = TabBar.Tabs.Chat - 1,
            ["title"] = "聊天",
            ["normal"] = {
                ["title_color"] = normalColor,
                ["icon"] = {
                    ["url"] = getTabIconURLByName("chat.png"),
                    ["height"] = getIconHeight(),
                },
            },
            ["highlighted"] = {
                ["title_color"] = highlightedColor,
                ["icon"] = {
                    ["url"] = getTabIconURLByName("chat-hl.png", true),
                    ["height"] = getIconHeightByClickStatus(true),
                },
            },
        }
        tabs[TabBar.Tabs.Chat] = {
            ["type"] = "pdd_chat_tab",
            ["props"] = {
            },
            ["navigation_bar"] = {
                ["title"] = "聊天",
            },
            ["tab_bar"] = {
                ["hidden"] = false,
            },
            ["tab_bar_item"] = tabItems[TabBar.Tabs.Chat],
        }
    end

    tabItems[TabBar.Tabs.Personal] = {
        ["tab_index"] = TabBar.Tabs.Personal - 1,
        ["title"] = "个人中心",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = getTabIconURLByName("me.png",false),
                ["height"] = getIconHeight(),
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] =  getTabIconURLByName("me-hl.png", true),
                ["height"] = getIconHeightByClickStatus(true),
            },
        },
    }
    tabs[TabBar.Tabs.Personal] = {
        ["type"] = "personal",
        ["props"] = {
            ["pages"] = {
                ["pdd_myfavorite"] = {
                    ["type"] = aimi.appVersion() <= _V("2.10.0") and "web" or "pdd_myfavorite",
                    ["props"] = {
                        ["url"] = "likes.html",
                    },
                },
                ["addresses"] = {
                    ["type"] = "address",
                },
            },
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Personal],
    }

    -- local FriendChatEnable =  aimi.KVStorage.getInstance():get(TabBar.FriendChatEnableKey)
    -- local MallChatEnable =  aimi.KVStorage.getInstance():get(TabBar.MallChatEnableKey)
    -- local barType = TabBar.Types.Haitao
    -- if FriendChatEnable ~= nil then
    --     barType = TabBar.Types.Friend
    -- elseif MallChatEnable ~= nil then
    --     barType = TabBar.Types.Mall
    -- end

    if aimi.appVersion() >= _V("3.38.0") then
        aimi.KVStorage.getInstance():set(TabBar.MallChatEnableKey, "1")
    end

    local replaceTabs = prepareReplaceTabs(nil)
    for key, value in pairs(replaceTabs) do
        local tabIndex = value["tab_bar_item"]["tab_index"] + 1
        tabs[tabIndex] = value
    end
end

function TabBar.setup(callback)
    prepareTabs()
    print("start call [AMNavigator setup]")
    AMBridge.call("AMNavigator", "setup", {
        ["selected_tab_index"] = 0,
        ["keep_history"] = false,
        ["scenes"] = tabs,
    }, function(error, response)
        print("end call [AMNavigator setup], start call [PDDBoot boot]")
        AMBridge.call("PDDBoot", "boot")

        if callback ~= nil then
            callback()
        end
    end)
end

function TabBar.setBadgeVisible(names, visibles)
    prepareTabs()

    if #names == nil or visibles == nil or #names ~= #visibles then
        return
    end

    local items = {}

    local originX = (aimi.appVersion() >= _V("3.49.0") and 33) or 20

    for i = 1, #names do
        local item = tabItems[names[i]]

        if item ~= nil then
            if visibles[i] then
                item["badge"] = {
                    ["url"] = componentDomain .. "image/badge.png",
                    ["height"] = 9,
                    ["x"] = originX,
                    ["y"] = -2,
                }
            else
                item["badge"] = nil
            end

            table.insert(items, item)
        end
    end

    AMBridge.call("AMNavigator", "setTabBar", {
        ["items"] = items,
    })
end

function TabBar.replace(barType, callback)
    local replaceTabs = prepareReplaceTabs(barType)
    AMBridge.call("AMNavigator", "replaceTabs", {
        ["scenes"] = replaceTabs,
    }, function(error, response)
        if callback ~= nil then
            callback(error)
        end
    end)
end


return TabBar