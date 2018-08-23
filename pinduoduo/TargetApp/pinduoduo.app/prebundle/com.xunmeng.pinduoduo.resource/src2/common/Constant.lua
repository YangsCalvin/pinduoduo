local Constant = Constant or {}

local Version = require("base/Version")

Constant.OldDeviceFlagKey = "__LUA_OLD_DEVICE_FLAG__"
Constant.OldInstallFlagKey = "__LUA_OLD_INSTALL_FLAG__"
Constant.PendingFirstUserNotificationRegistrationFlagKey =
    "__LUA_PENDING_FIRST_USER_NOTIFICATION_REGISTRATION_FLAG__"
Constant.PDD_ID_KEY = "__PDD_ID__"
Constant.APP_START = "app_start"
Constant.APP_PAUSE = "app_pause"
Constant.APP_RESUME = "app_resume"
Constant.APP_STOP = "app_stop"

Constant.LoginTypeKey = "__AUTHORIZATION_TYPE__"
Constant.LoginTypeWeChat = 3
Constant.LoginTypeQQ = 4
Constant.CDNURLPrefix = "http://pinduoduoimg.yangkeduo.com/ios/"
Constant.LUA_HAS_COMMON_TASK_IN_QUEUE = "LUA_HAS_COMMON_TASK_IN_QUEUE"
Constant.LUA_HAS_COMMON_ACTIVITY_FLAG_KEY = "LUA_HAS_COMMON_ACTIVITY_FLAG_KEY"
Constant.LUA_NO_HAS_COMMON_ACTIVITY_FLAG_KEY = "LUA_NO_HAS_COMMON_ACTIVITY_FLAG_KEY"

Constant.SUBJECTS_ID_EXTRA_PARAMETERS = {
    ["11"] = {
        ["url"] = "subjects.html?subjects_id=11",
        ["subjects_id"] = "11",
        ["subjects_title"] = "品质水果",
        ["spike_url"] = "spike/19/goods",
        ["spike_title"] = "每日抢鲜",
        ["goods_main_title"] = "24H闪电发货  闪电退款"
    },
    ["14"] = {
        ["subjects_id"] = "14",
        ["url"] = "subjects.html?subjects_id=14",
        ["spike_url"] = "spike/6/goods",
        ["super_brand_goods_header_view_height"] = 8
    },
    ["15"] = {
        ["url"] = "subjects.html?subjects_id=15",
        ["subjects_id"] = "15",
        ["subjects_title"] = "爱逛街",
        ["spike_url"] = "spike_go_shopping",
        ["spike_title"] = "新品特惠",
        ["goods_header_view_height"] = 8
    },
    ["17"] = {
        ["url"] = "subjects.html?subjects_id=17",
        ["subjects_id"] = "17",
        ["subjects_title"] = "食品超市",
        ["spike_url"] = "spike/7/goods",
        ["spike_url_v2"] = "spike/7/goods",
        ["recommend_url_v2"] = "v2/subject/4922/goods?page=1&size=30",
        ["spike_title"] = "每日秒杀",
        ["goods_main_title"] = "发现美食",
        ["rec_goods_collection_header_view_height"] = 42,
        ["goods_header_view_height"] = 8
    },
    ["18"] = {
        ["url"] = "subjects.html?subjects_id=18",
        ["subjects_id"] = "18",
        ["spike_url"] = "spike/8/goods",
        ["spike_title"] = "优品速抢",
        ["goods_main_title"] = "品质生活",
        ["goods_desc_title"] = "一站购齐·买退无忧"
    },
    ["20"] = {
        ["url"] = "subjects.html?subjects_id=20",
        ["subjects_id"] = "20",
        ["spike_url"] = "spike_mother_baby"
    },
    ["21"] = {
        ["url"] = "economical_brand.html",
        ["subjects_id"] = "21",
        ["spike_url"] = "spike/23/goods",
        ["spike_title"] = "品牌限时购",
        ["goods_main_title"] = "精选推荐",
        ["goods_desc_title"] = "品牌好货 每日上新",
        ["goods_header_view_height"] = 8
    },
    ["23"] = {
        ["url"] = "subjects.html?subjects_id=23",
        ["subjects_id"] = "23",
        ["spike_url"] = "spike/18/goods",
        ["spike_title"] = "品牌限时抢",
        ["goods_main_title"] = "官方大牌",
        ["goods_desc_title"] = "7天退换·全国联保"
    },
    ["22"] = {
        ["url"] = "subjects.html?subjects_id=22",
        ["subjects_id"] = "22",
        ["spike_url"] = "api/spike/spike_list?type=22",
        ["spike_title"] = "每日疯抢",
        ["goods_main_title"] = "潮流精选",
        ["goods_desc_title"] = "每日上新 买手推荐",
        ["goods_header_view_height"] = 8
    },
    ["12"] = {
        ["url"] = "subjects.html?subjects_id=12",
        ["subjects_id"] = "12",
        ["recommend_url"] = "v2/subject/918/goods?page=1&size=30",
        ["spike_title"] = "今日推荐",
        ["goods_main_title"] = "优选好货",
        ["goods_desc_title"] = "每天9点·14点·20点更新",
        ["rec_goods_collection_header_view_height"] = 42,
        ["goods_desc_title_hidden"] = 1,
        ["goods_header_icon_hidden"] = 1,
        ["goods_main_title_v2"] = "每天早10点·晚8点上新",
        ["goods_header_view_height_v2"] = 50
    },
    ["125"] = {
        ["url"] = "subjects.html?subjects_id=125",
        ["subjects_id"] = "125",
        ["recommend_url"] = "v2/subject/6789/goods?page=1&size=30",
        ["spike_left_title"] = "必抢好货",
        ["rec_goods_collection_header_view_height"] = 44,
        ["goods_header_view_height"] = 8,
        ["rec_collection_view_cell_height"] = 175,
        ["rec_goods_collection_width_height"] = 128,
        ["rec_collection_view_cell_line_spacing"] = 8,
        ["rec_goods_collection_view_cell_style"] = 1
    }
}

Constant.ICON_GROUP = {
    ["Spike"] = "1",
    ["SuperSpike"] = "2",
    ["EconomicalBrand"] = "3",
    ["LuckyBag"] = "4",
    ["AssistFreeCoupon"] = "5";
    ["GoShopping"] = "6",
    ["Bargain"] = "7",
    ["SignIn"] = "8",
    ["FoodV2"] = "9",
    ["CommercialBargainList"] = "10",
    ["ChargeCenter"] = "11",
    ["Roulette"] = "12",
    ["SlightlyLuxurious"] = "13",
    ["Oversea"] = "14",
    ["Fruits"] = "15",
    ["FreeTrial"] = "16",
    ["Family"] = "17",
    ["LoveLux"] = "18",
    ["ElectricalAppliance"] = "18",
    ["Food"] = "19",
    ["Furniture"] = "20",
    ["Maternal"] = "21",
    ["NewCustomer"] = "22",
    ["BrowseAd"] = "23",
    ["RankHot"] = "24",
    ["OneCent"] = "26",
    ["OneCentPrice"] = "27",
    ["NewVoice"] = "28",
    ["MoneyTree"] = "42",
}

Constant.ICON_PARAM = {
    ["2"] = {
        ["type"] = (Version.new(aimi.Application.getApplicationVersion()) <= Version.new("3.25.0")) and "web" or (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.61.0")) and "pdd_subjects" or "pdd_superbrand",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["14"],
    },

    ["3"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.57.0") and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["21"],
    },

    ["6"] = {
        ["type"] = (Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.10.0")) and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["15"],
    },

    ["7"] = {
        ["type"] = (Version.new(aimi.Application.getApplicationVersion()) <= Version.new("2.14.0")) and "web" or (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.61.0")) and "pdd_subjects" or "pdd_bargain",
        ["props"] = (Version.new(aimi.Application.getApplicationVersion()) <= Version.new("4.7.0")) and Constant.SUBJECTS_ID_EXTRA_PARAMETERS["12"] or  
            {
                ["url"] = "subjects.html?subjects_id=12",
                ["subjects_id"] = "12",
                ["goods_header_view_height_v2"] = 50,
                ["spike_title"] = "今日推荐",
                ["rec_goods_collection_header_view_height"] = 45,
                ["goods_main_title_v2"] = "每天早10点·晚8点上新",
                ["goods_desc_title_hidden"] = 1,
                ["goods_header_icon_hidden"] = 1,
                ["rec_collection_view_cell_height"] = 206,
                ["rec_goods_collection_view_cell_style"] = 2,
                ["rec_collection_view_cell_line_spacing"] = 20,
                ["rec_spike_url_from_api"] = 1,
                ["rec_header_gift_icon"] = 1
            }
    },

    ["13"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.4.0") and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["22"],
    },

    ["14"] =  {
        ["type"] = "pdd_haitao",
        ["props"] = {
            ["title_when_pushed"] = "海淘专区"
        }
    },

    ["15"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.24.0") and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["18"],
    },

    ["18"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.24.0") and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["23"],
    },

    ["19"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.20.0") and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["17"],
    },

    ["21"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.13.0") and "web" or "pdd_subjects",
        ["props"] = Constant.SUBJECTS_ID_EXTRA_PARAMETERS["20"],
    },
    ["45"] = {
        ["type"] = Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.13.0") and "web" or "pdd_subjects",
        ["props"] = Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.5.0") and Constant.SUBJECTS_ID_EXTRA_PARAMETERS["125"] or 
                {
                    ["url"] = "subjects.html?subjects_id=125",
                    ["subjects_id"] = "125",
                },
    },
}

Constant.PDD_TENCENT_VIDIO_SCHEME = "qngaccv79cv29i"
Constant.PDD_OPEN_SCHEME = "pddopen"

Constant.PDD_CI_Upgrade = "person_setting.CIUpgradeEnable"
Constant.PDD_popup_window_switch = "home.pdd_popup_window_switch"

return Constant
