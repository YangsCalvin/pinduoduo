TabBar = TabBar or {}


TabBar.Tabs = {}
TabBar.Tabs.Home = "home"
TabBar.Tabs.Rank = "rank"
TabBar.Tabs.Oversea = "oversea"
TabBar.Tabs.Search = "search"
TabBar.Tabs.Personal = "personal"

local tabs = {}
local tabItems = {}
local componentDomain = "amcomponent://com.xunmeng.pinduoduo.lua/"
local homeQuickEntrance = {{
    ["name"] = "秒杀",
    ["imgUrl"] = componentDomain .. "image/spike.png",
    ["tipUrl"] = componentDomain .. "image/activity_new_tip.png",
    ["forwardUrl"] = "spike.html",
    ["showTip"] = true,
    ["key"] = "index_spike",
    ["priority"] = 1,
    ["spClass"] = "",
    ["show"] = true,
},{
    ["name"] = "超值大牌",
    ["imgUrl"] = componentDomain .. "image/super_spike.png",
    ["tipUrl"] = componentDomain .. "image/activity_hot_tip.png",
    ["forwardUrl"] = "super_spike.html",
    ["showTip"] = true,
    ["key"] = "index_super_spike",
    ["priority"] = 1.5,
    ["spClass"] = "",
    ["show"] = true,
},{
    ["name"] = "9块9特卖",
    ["imgUrl"] = componentDomain .. "image/bargain.png",
    ["tipUrl"] = componentDomain .. "image/activity_new_tip.png",
    ["forwardUrl"] = "subject.html?subject_id=384&a=b",
    ["showTip"] = true,
    ["key"] = "index_bargain",
    ["priority"] = 2,
    ["spClass"] = "",
    ["show"] = true,
},{
    ["name"] = "抽奖",
    ["imgUrl"] = componentDomain .. "image/lottery.png",
    ["tipUrl"] = componentDomain .. "image/activity_new_tip.png",
    ["forwardUrl"] = "lottery.html",
    ["showTip"] = true,
    ["key"] = "index_lottery",
    ["priority"] = 3,
    ["spClass"] = "",
    ["show"] = true,
}, {
    ["name"] = "食品",
    ["imgUrl"] = componentDomain .. "image/cat_2.png",
    ["forwardUrl"] = "catgoods.html?opt_id=1&opt_type=1&all=true",
    ["showTip"] = false,
    ["key"] = "index_cat_2",
    ["priority"] = 5,
    ["spClass"] = "",
    ["show"] = true,
}, {
    ["name"] = "服饰箱包",
    ["imgUrl"] = componentDomain .. "image/cat_1.png",
    ["forwardUrl"] = "catgoods.html?opt_id=14&opt_type=1&all=true",
    ["showTip"] = false,
    ["priority"] = 6,
    ["spClass"] = "",
    ["show"] = true,
}, {
    ["name"] = "家居生活",
    ["imgUrl"] = componentDomain .. "image/cat_3.png",
    ["forwardUrl"] = "catgoods.html?opt_id=15&opt_type=1&all=true",
    ["showTip"] = false,
    ["key"] = "index_cat_3",
    ["priority"] = 7,
    ["spClass"] = "",
    ["show"] = true,
}, {
    ["name"] = "母婴",
    ["imgUrl"] = componentDomain .. "image/cat_77.png",
    ["forwardUrl"] = "catgoods.html?opt_id=4&opt_type=1&all=true",
    ["showTip"] = false,
    ["priority"] = 8,
    ["spClass"] = "",
    ["show"] = true,
}, {
    ["name"] = "美妆护肤",
    ["imgUrl"] = componentDomain .. "image/cat_69.png",
    ["forwardUrl"] = "catgoods.html?opt_id=16&opt_type=1&all=true",
    ["showTip"] = false,
    ["priority"] = 9,
    ["spClass"] = "",
    ["show"] = true,
}, {
    ["name"] = "海淘",
    ["imgUrl"] = componentDomain .. "image/cat_18.png",
    ["tipUrl"] = componentDomain .. "image/activity_new_tip.png",
    ["forwardUrl"] = "haitao.html",
    ["showTip"] = true,
    ["key"] = "index_haitao",
    ["priority"] = 10,
    ["spClass"] = "",
    ["show"] = true,
}}

local function prepareTabs()
    local normalColor = 0x777777
    local highlightedColor = 0xff0000
    local iconHeight = 22

    local tabIndex = 0

    tabItems[TabBar.Tabs.Home] = {
        ["tab_index"] = tabIndex,
        ["title"] = "首页",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/home.png",
                ["height"] = iconHeight,
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/home-hl.png",
                ["height"] = iconHeight,
            },
        },
    }
    tabs[TabBar.Tabs.Home] = {
        ["type"] = "pdd_home",
        ["props"] = {
            ["entrances"] = homeQuickEntrance
        },
        ["navigation_bar"] = {
            ["title"] = "拼多多",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Home],
    }

    tabIndex = tabIndex + 1
    tabItems[TabBar.Tabs.Rank] = {
        ["tab_index"] = tabIndex,
        ["title"] = "新品",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/rank.png",
                ["height"] = iconHeight,
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/rank-hl.png",
                ["height"] = iconHeight,
            },
        },
    }
    tabs[TabBar.Tabs.Rank] = {
        ["type"] = "web",
        ["props"] = {
            ["url"] = "new_arrivals.html",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Rank],
    }

    tabIndex = tabIndex + 1
    tabItems[TabBar.Tabs.Oversea] = {
        ["tab_index"] = tabIndex,
        ["title"] = "海淘",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/oversea.png",
                ["height"] = iconHeight,
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/oversea-hl.png",
                ["height"] = iconHeight,
            },
        },
    }
    tabs[TabBar.Tabs.Oversea] = {
        ["type"] = "web",
        ["props"] = {
            ["url"] = "haitao.html",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Oversea],
    }

    tabIndex = tabIndex + 1
    tabItems[TabBar.Tabs.Search] = {
        ["tab_index"] = tabIndex,
        ["title"] = "搜索",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/search.png",
                ["height"] = iconHeight,
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/search-hl.png",
                ["height"] = iconHeight,
            },
        },
    }
    tabs[TabBar.Tabs.Search] = {
        ["type"] = "web",
        ["props"] = {
            ["url"] = "classification.html",
        },
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Search],
    }

    tabIndex = tabIndex + 1
    tabItems[TabBar.Tabs.Personal] = {
        ["tab_index"] = tabIndex,
        ["title"] = "个人中心",
        ["normal"] = {
            ["title_color"] = normalColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/me.png",
                ["height"] = iconHeight,
            },
        },
        ["highlighted"] = {
            ["title_color"] = highlightedColor,
            ["icon"] = {
                ["url"] = componentDomain .. "image/me-hl.png",
                ["height"] = iconHeight,
            },
        },
    }
    tabs[TabBar.Tabs.Personal] = {
        ["type"] = "personal",
        ["tab_bar"] = {
            ["hidden"] = false,
        },
        ["tab_bar_item"] = tabItems[TabBar.Tabs.Personal],
    }
end


function TabBar.setup(callback)
    AMBridge.call("AMNavigator", "setup", {
        ["selected_tab_index"] = 0,
        ["keep_history"] = false,
        ["scenes"] = {
            tabs[TabBar.Tabs.Home],
            tabs[TabBar.Tabs.Rank],
            tabs[TabBar.Tabs.Oversea],
            tabs[TabBar.Tabs.Search],
            tabs[TabBar.Tabs.Personal],
        },
    }, function(error, response)
        AMBridge.call("PDDBoot", "boot")

        if callback ~= nil then
            callback()
        end
    end)
end

function TabBar.setBadgeVisible(names, visibles)
    if #names == nil or visibles == nil or #names ~= #visibles then
        return
    end

    local items = {}

    for i = 1, #names do
        local item = tabItems[names[i]]

        if item ~= nil then
            if visibles[i] then
                item["badge"] = {
                    ["url"] = componentDomain .. "image/badge.png",
                    ["height"] = 9,
                    ["x"] = 20,
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


prepareTabs()


return TabBar
