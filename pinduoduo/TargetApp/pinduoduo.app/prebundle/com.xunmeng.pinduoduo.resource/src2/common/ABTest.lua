local ABTest = class("ABTest")

local Promise = require("base/Promise")
local Version = require("base/Version")
local Event = require("common/Event")
local APIService = require("common/APIService")
local ComponentManager = require("common/ComponentManager")
local Config = require("common/Config")
local MD5 = require("common/MD5")
local bit = require("common/bit")

local ABTEST_CONFIG_LIST_KEY = "config_list"
local ABTEST_TREE_KEY = "tree"
local ABTEST_PROP_KEY = "prop"
local ABTEST_OP_KEY = "op"
local ABTEST_DISABLE_WHITE_LIST_KEY = "disable_white_list"
local ABTEST_EXTRA_WHITE_LIST_KEY = "extra_white_list"
local ABTEST_VAL_KEY = "val"
local ABTEST_SON_KEY = "son"
local ABTEST_PER_KEY = "per"
local ABTEST_MASK_KEY = "mask"
local ABTEST_BUCKETS_KEY = "buckets"
local ABTEST_NAME_KEY = "name"
local ABTEST_TYPE_KEY = "type"
local ABTEST_WHITE_LIST_KEY = "white_list"
local ABTEST_BLACK_LIST_KEY = "black_list"
local ABTEST_ALGO_KEY = "algo"
local ABTEST_SALT_KEY = "salt"
local ABTEST_BUCKET_COUNT_KEY = "bucket_count"

local ABTEST_PROP_APP_VERSION = "app_version"
local ABTEST_PROP_APP_CHANNEL = "app_channel"
local ABTEST_PROP_SYSTEM_VERSION = "system_version"
local ABTEST_PROP_UID = "uid"
local ABTEST_OP_EQ = "eq"
local ABTEST_OP_IN = "in"
local ABTEST_OP_NOT_IN = "not_in"
local ABTEST_OP_GE = "ge"
local ABTEST_OP_LE = "le"
local ABTEST_UID_LIMIT = "limit"

local ABTEST_TYPE_FEATURE = "feature"
local ABTEST_TYPE_ROUTE = "route"

local ABTEST_KEY = "LuaABTest"

local ABTEST_DATA_FROM_CONFIGURE_CENTER = Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.52.0")
local ABTEST_CONFIGURE_CENTER_CONFIGURE_KEY = "base.abtest_config"

function ABTest.initialize(resolve, reject)
    ABTest.loadABTestConf()
    AMBridge.register(Event.UserLogin, function()
        print('user login')
        ABTest.updateGrayStrategies()
    end)
    AMBridge.register(Event.UserLogout, function()
        print('user logout')
        ABTest.updateGrayStrategies()
    end)

    AMBridge.register(Event.ApplicationResume, function()
        --ABTest.getABTestConfFromServer()
        ABTest.fetchABTestConfigure()
        ABTest.updateGrayStrategies()
    end)

    if ABTEST_DATA_FROM_CONFIGURE_CENTER == true then
        AMBridge.register(Event.PDDAppConfigureCenterUpdateNotification, function()
            print('ABTest:------app configure center updated, try update abtest configure-------')
            ABTest.getABTestConfFromConfigureCenter()
        end)
    end

    Promise.all():next(resolve, reject)
end

function ABTest.loadABTestConf()
    AMBridge.call("AMStorage", "getObject", {
        ["key"] = ABTEST_KEY,
    }, function(error, response)
        local abtestConf = nil
        if response ~= nil and response["value"] ~= nil then
            print('------get ab from cache--------')
            abtestConf = response["value"]
        else
            print('-------get ab from local file-------')
            abtestConf = ABTest.getlocalABTestConf()
        end
        ABTest.setABTestConf(abtestConf)
        --ABTest.getABTestConfFromServer()
        ABTest.fetchABTestConfigure()
    end)
end

function ABTest.fetchABTestConfigure()
    if ABTEST_DATA_FROM_CONFIGURE_CENTER == true then
        ABTest.getABTestConfFromConfigureCenter()
    else
        ABTest.getABTestConfFromServer()
    end
end

function ABTest.getABTestConfFromServer()
    local appMode = Config.AppMode
    local appVersion = aimi.Application.getApplicationVersion()
    if Version.new(appVersion) < Version.new("3.10.0") then
        return
    end
    Promise.new(function(resolve, reject)
        local userID = aimi.User.getUserID()
        local deviceVersion = aimi.Device.getSystemVersion()
        local deviceId = aimi.Device.getDeviceIdentifier()
        local url = string.format("ab_config?os=iOS&app_version=%s&user_id=%s&device_version=%s&device_id=%s",appVersion,userID,deviceVersion,deviceId)
        print('--------------get ab from remote-------------')
        return APIService.getJSON(url):next(function(response)
            resolve(response)
        end):catch(function(reason)
            reject(reason)
        end)
    end):next(function(response)
        local abtestConf = response.responseJSON["result"]
        ABTest.setABTestConf(abtestConf)
    end)
end

function ABTest.getABTestConfFromConfigureCenter()
    if ABTEST_DATA_FROM_CONFIGURE_CENTER ~= true then
        return
    end
    print('ABTest:--------------get ab from configure center-------------')

    AMBridge.call("PDDAppConfig", "getConfiguration", {
            ["key"] = ABTEST_CONFIGURE_CENTER_CONFIGURE_KEY
        },function(error, response)
            if type(response) ~= 'table' then
                return
            end
            local configureString = response["value"]
            if type(configureString) ~= 'string' then
                return
            end
            xpcall(function ()
                local abTestConf = json.decode(configureString)
                if type(abTestConf) == 'table'  then
                    ABTest.setABTestConf(abTestConf["result"])
                    print('ABTest:--------------success update ab configure from configure center-------------')
                end
            end, function(message)
                print('ABTest:------------error parse json string : ' .. tostring(configureString),'--- error message : ' , tostring(message))
            end)
            
        end)
end

function ABTest.setABTestConf(abTestConf)
    if abTestConf == nil then
        print('error: abTestConf is nil')
        return
    end
    
    ABTest.abTestConf_ = abTestConf
    ABTest.makeDecisonByConf(abTestConf)
    ABTest.saveABTestConf(abTestConf)
end

function ABTest.updateGrayStrategies()
    ABTest.makeDecisonByConf(ABTest.abTestConf_)
end

function ABTest.getlocalABTestConf()
    local fileContent = ComponentManager.getFileContent(ComponentManager.LuaComponentName, "raw/ab.json")
    if fileContent == nil then
        print('error: local abtest conf is nil')
        return
    end
    
    local abtestConf = json.decode(fileContent)
    if abtestConf ~= nil  then
        return abtestConf["result"]
    end
end

function ABTest.saveABTestConf(abtestConf)
    if abtestConf == nil then
        print('-----------------error:abTestConf is nil----------------------')
        return
    end
    
    AMBridge.call("AMStorage", "setObject", {
        ["key"] = ABTEST_KEY,
        ["value"] = abtestConf,
    })
end

function ABTest.makeDecisonByConf(abtestConf)
    if abtestConf == nil then
        print('error: makeDecisonByConf faied, abtestConf is nil')
        return
    end

    local startTime = os.time()

    local whiteList = abtestConf[ABTEST_WHITE_LIST_KEY]
    local whiteListUsers= {}
    if whiteList ~= nil and type(whiteList) == "string"  then
        for uid in string.gmatch(whiteList, '([^,]+)') do
            table.insert(whiteListUsers, uid)
        end
    end

    local blackList = abtestConf[ABTEST_BLACK_LIST_KEY]
    local blackListUsers = {}
    if blackList ~= nil and type(blackList) == "string" then
        for uid in string.gmatch(blackList, '([^,]+)') do
            table.insert(blackListUsers, uid)
        end
    end

    local configs = abtestConf[ABTEST_CONFIG_LIST_KEY]
    if configs == nil then
        print('configs is nil')
        return
    end

    local grayFeatures = {}
    local grayRouteTable = {}

    local isBlackUser = ABTest.isBlackListUser(blackListUsers)
    local isWhiteUser = ABTest.isWhiteListUser(whiteListUsers)
    local uid = ABTest.uniqueID()

    for _, v in ipairs(configs) do
        local decided = false
        local isTest = 0
        local disableWhiteList = v[ABTEST_DISABLE_WHITE_LIST_KEY] or 0
        local extraWhiteListString = v[ABTEST_EXTRA_WHITE_LIST_KEY]

        local isExtraWhiteList = false
        if extraWhiteListString ~= nil and type(extraWhiteListString) == "string" and uid ~= "" then
            for extraUid in string.gmatch(extraWhiteListString, '([^,]+)') do
                if uid == extraUid then
                    isExtraWhiteList = true
                    break
                end
            end
        end

        if isBlackUser then
            decided = true
            isTest = 0
        elseif isWhiteUser then
            if disableWhiteList == 0 then
                decided = true
                isTest = 1
            end
        elseif isExtraWhiteList then
            decided = true
            isTest = 1
        end

        local tree = v[ABTEST_TREE_KEY]
        while tree ~= nil and decided == false do
            local nodes = tree[ABTEST_SON_KEY]
            local prop = tree[ABTEST_PROP_KEY]
            local op = tree[ABTEST_OP_KEY]
            local value = tree[ABTEST_VAL_KEY]
            local val = {}
            if value ~= nil and type(value) == "string"  then
                for str in string.gmatch(value, '([^,]+)') do
                    table.insert(val, str)
                end
            end

            local function makeDecisionByCondition(condition)
                if condition then
                    if nodes ~= nil and #nodes >= 1 then
                        tree = nodes[1]
                    else
                        decided = true
                        isTest = 0
                    end
                else
                    if nodes ~= nil and #nodes >= 2 then
                        tree = nodes[2]
                    else
                        decided = true
                        isTest = 0
                    end
                end
            end

            local function makeDecisionByCompareVersion(currentVersion)
                local limitedVersion = Version.new(value)
                if op == ABTEST_OP_EQ then
                    makeDecisionByCondition(currentVersion == limitedVersion)
                elseif op == ABTEST_OP_IN then
                    makeDecisionByCondition(ABTest.isInTestVersion(val, currentVersion))
                elseif op == ABTEST_OP_NOT_IN then
                    local notTestVersion = not ABTest.isInTestVersion(val, currentVersion)
                    makeDecisionByCondition(notTestVersion)
                elseif op == ABTEST_OP_GE then
                    makeDecisionByCondition(currentVersion >= limitedVersion)
                elseif op == ABTEST_OP_LE then
                    makeDecisionByCondition(currentVersion <= limitedVersion)
                else
                    print('error: unexpected op, op=', op)
                    decided = true
                    isTest = 0
                end
            end
            if prop == ABTEST_PROP_UID then
                local per = tree[ABTEST_PER_KEY]
                local mask = tree[ABTEST_MASK_KEY]
                local algo = tree[ABTEST_ALGO_KEY]
                if algo then
                    local uidLength = string.len(uid)
                    if algo == "mask" then
                        local maskLength = string.len(mask)
                        if uidLength >= maskLength then
                            local subUid = string.sub(uid, uidLength - maskLength + 1)
                            local s = ""
                            for i = 1, maskLength do
                                if string.sub(mask, i, i) == "1" then
                                    s = s .. string.sub(subUid, i, i)
                                end
                            end

                            local buckets = tree[ABTEST_BUCKETS_KEY]
                            for bucket in string.gmatch(buckets,'([^|]+)') do
                                local t = {}
                                for interval in string.gmatch(bucket,'([^,]+)') do
                                    table.insert(t,interval)
                                end

                                if #t == 2 then
                                    local startIndex = tonumber(t[1])
                                    local endIndex = tonumber(t[2])
                                    local str = "[" .. startIndex .. "," .. endIndex .. "]"
                                    print('----------------------interval ', str,'s=',s)
                                    if tonumber(s) >= startIndex and tonumber(s) <= endIndex then
                                        decided = true
                                        isTest = 1
                                        break
                                    end
                                end
                            end
                        end
                    elseif algo == "salt" then
                        local salt = tree[ABTEST_SALT_KEY] or ""
                        local buckets = tree[ABTEST_BUCKETS_KEY]
                        local bucketsTable = {}
                        if buckets and uidLength > 0 then
                            for bkt in string.gmatch(buckets, '([^,]+)') do
                                if bkt:find("-") then
                                    for k, v in string.gmatch(bkt, "(%d+)-(%d+)") do
                                        local startIndex = tonumber(k)
                                        local endIndex = tonumber(v)
                                        if type(startIndex) == "number" and type(startIndex) == "number" then
                                            for i=startIndex, endIndex do
                                                table.insert(bucketsTable, tostring(i))
                                            end
                                        end
                                    end
                                else
                                    table.insert(bucketsTable, bkt)
                                end
                            end

                            local startMD5CalcTime = os.time()
                            local sourceVal = tostring(salt) .. uid
                            local saltMD5 = ""
                            if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.42.0") then
                                local storageValue = aimi.KVStorage.getInstance():get(sourceVal)
                                saltMD5 = tostring(storageValue)

                                if type(saltMD5) ~= "string" or #saltMD5 ~= 32 then
                                    saltMD5 = string.upper(MD5.sumhexa(sourceVal))
                                    aimi.KVStorage.getInstance():set(sourceVal, tostring(saltMD5))
                                    print('----------no match data, sourceVal=',sourceVal, "calc saltMD5=", saltMD5, "save result to storage")
                                end
                            else
                                saltMD5 = string.upper(aimi.DataCrypto.md5(sourceVal))
                            end

                            local endMD5CalcTime = os.time()
                            print("----------calc sourceVal=", sourceVal, " ,saltMD5=",saltMD5," ,cost=", endMD5CalcTime - startMD5CalcTime)
                            local hashCode =ABTest.hashCode(saltMD5)
                            local bucketCount = tree[ABTEST_BUCKET_COUNT_KEY]
                            if bucketCount == nil then
                                bucketCount = 100
                            end
                            local res = hashCode % tonumber(bucketCount)
                            res = res < 0 and res + tonumber(bucketCount) or res
                            print('----------salt='.. tostring(salt), 'saltMD5=' .. saltMD5 .. ',hashCode='.. hashCode ..',bucket='..res)

                            for _, v in ipairs(bucketsTable) do
                                if tostring(res)  == v then
                                    decided = true
                                    isTest = 1
                                    break
                                end
                            end
                        end
                    end
                elseif per ~= nil then
                    if per == 100 then
                        decided = true
                        isTest = 1
                    else
                        local limit = tree["limit"]
                        if uid ~= "" then
                            if limit == nil then
                                if tonumber(uid) % 100 < per then
                                    decided = true
                                    isTest = 1
                                end
                            else
                                local uid = tonumber(uid) - limit
                                if  uid >= 0 and uid % 100 < per then
                                    decided = true
                                    isTest = 1
                                end
                            end
                        end
                    end
                elseif op == ABTEST_OP_IN then
                    if ABTest.isWhiteListUser(val) then
                        decided = true
                        isTest = 1
                    end
                elseif op == ABTEST_OP_EQ then
                    if uid == value then
                        decided = true
                        isTest = 1
                    end
                end

                if not decided then
                    decided = true
                    isTest = 0
                end
            elseif prop == ABTEST_PROP_APP_VERSION then
                local currentAppVersion = Version.new(aimi.Application.getApplicationVersion())
                makeDecisionByCompareVersion(currentAppVersion)
            elseif prop == ABTEST_PROP_SYSTEM_VERSION then
                local currentSystemVersion = Version.new(aimi.Device.getSystemVersion())
                makeDecisionByCompareVersion(currentSystemVersion)
            else
                print('error: unexpected prop, prop=', prop)
                decided = true
                isTest = 0
            end
        end

        local name = v[ABTEST_NAME_KEY]
        local testType = v[ABTEST_TYPE_KEY]
        if testType == ABTEST_TYPE_FEATURE then
            grayFeatures[name] = isTest
        elseif testType == ABTEST_TYPE_ROUTE then
            if isTest == 0 then
                grayRouteTable[name] = "web"
            end
        end
    end

    local endTime = os.time()
    print('---------------info:make decision cost ', endTime - startTime, ' seconds')

    local function appendDeprecatedABTestItems()
        local deprecatedABTestKeys = {
            ["pdd_tracking_ad_dispatch"] = 0,
            ["pdd_bottombar_simplified"] = 0,
            ["pdd_category_sort"] = 0,
            ["pdd_image_render_using_gpu"] = 0,
            ["pdd_search_result_remove_price_sort_gray"] = 0,
            ["pdd_home_subject_ui"] = 0,
            ["pdd_lucky_bag_popup_v2"] = 0,
            ["pdd_sign_in_popup"] = 0,
            ["pdd_image_https_regex_match"] = 0,
            ["pdd_goods_detail_lucky_goods_hide_direct_buy"] = 0,
            ["pdd_goodsdetail_single_group_btn_right"] = 0,
            ["pdd_home_icons_go_shopping_pos"] = 0,
            ["pdd_image_https"] = 0,
            ["pdd_home_spike_new_red"] = 0,
            ["pdd_alipay_priority"] = 0,
            ["pdd_home_show_new_top_navi"] = 0,
            ["pdd_home_opt_new_style"] = 0,
            ["pdd_rank_mall_new_arrivals"] = 0,
            ["pdd_search_result_hot_badge"] = 0,
            ["pdd_vpc_host_apiv2"] = 0,
            ["pdd_data_transmission_encryption"] = 0
        }

        for key, value in pairs(deprecatedABTestKeys) do
            if grayFeatures[key] == nil then
                grayFeatures[key] = value
            end
        end
    end

    appendDeprecatedABTestItems()

    local function saveSpecialGrayNames()
        local function saveGrayFeatureByABTestKey(abTestKey)
            if type(abTestKey) ~= "string" or #abTestKey == 0 then
                return
            end
            
            if grayFeatures[abTestKey] == 1 then
                aimi.KVStorage.getInstance():set(abTestKey, tostring("1"))
            else
                aimi.KVStorage.getInstance():set(abTestKey, tostring("0"))
            end
        end

        local specialGrayNames = {
            "pdd_lucky_bag_popup",
            "pdd_lucky_bag_popup_v2",
            "pdd_sign_in_popup",
            "pdd_help_free_group_icon",
            "pdd_recommend_tab",
            "pdd_mall_newVersion"
        }

        for _, abTestKey in ipairs(specialGrayNames) do
            saveGrayFeatureByABTestKey(abTestKey)
        end
    end

    saveSpecialGrayNames()

    ABTest.updateGrayFeatures(grayFeatures, whiteListUsers)
    ABTest.setABTestRouteTable(grayRouteTable)
end

function ABTest.updateGrayFeatures(grayFeatures)
    ABTest.updateGrayFeatures(grayFeatures,  nil)
end

function ABTest.updateGrayFeatures(grayFeatures, whiteListUsers)
    if grayFeatures == nil or type(grayFeatures) ~= "table" then
        return
    end

    local needUpdate = true
    xpcall(function()
        if type(ABTest.lastGrayFeatures_) == "table" and tostring(json.encode(ABTest.lastGrayFeatures_)) == tostring(json.encode(grayFeatures)) then
            print("grayFeatures equals, will not call update method, ABTest.lastGrayFeatures_=",ABTest.lastGrayFeatures_, tostring(json.encode(grayFeatures)))
            needUpdate = false
        else
            print('grayFeatures not equals, need call update method, ABTest.lastGrayFeatures_=', ABTest.lastGrayFeatures_)
            ABTest.lastGrayFeatures_ = grayFeatures
        end
    end, AMBridge.error)

    if needUpdate then
        if type(whiteListUsers) == "table" then
            table.insert(whiteListUsers, "1968556406")
            table.insert(whiteListUsers, "5265750334")
            table.insert(whiteListUsers, "6343449391")
            table.insert(whiteListUsers, "6522211557")
            table.insert(whiteListUsers, "4160152009")
            table.insert(whiteListUsers, "4823622275")
        end

        AMBridge.call("PDDABTest", "update", {
            ["gray_features"] = grayFeatures,
            ["white_list_users"] = whiteListUsers
        }, function(errorCode, response)
        end)
    end
end

function ABTest.isWhiteListUser(whiteList)
    local uid = ABTest.uniqueID()
    if whiteList == nil or uid == "" then
        return false
    end

    for _, v in ipairs(whiteList) do
        if v == uid then
            return true
        end
    end

    local scheme = Config.AppScheme
    if scheme == "hutaojie" then
        return true
    end

    return false
end

function ABTest.isBlackListUser(blackList)
    local uid = ABTest.uniqueID()
    if blackList == nil or uid == "" then
        return false
    end

    for _, v in ipairs(blackList) do
        if v == uid then
            return true
        end
    end

    local scheme = Config.AppScheme
    if scheme == "hutaojie" then
        return false
    end

    return false
end

function ABTest.isInTestVersion(versions, currentVersion)
    if versions == nil then
        return false
    end

    for _, v in ipairs(versions) do
        if Version.new(v) == currentVersion then
            return true
        end
    end
    return false
end

function ABTest.setABTestRouteTable(abTestRouteRouteTable)
    if abTestRouteRouteTable == nil then
        return
    end

    ABTest.abTestRouteTable_ = abTestRouteRouteTable
    print('abtest route table, userid =', aimi.User.getUserID(), 'uniqueID=',ABTest.uniqueID())
    for k,v in pairs(ABTest.abTestRouteTable_) do
        print(k,'->',v)
    end
end

function ABTest.reRoutePageType(type)
    if ABTest.abTestRouteTable_ then
        return ABTest.abTestRouteTable_[type] or type
    end

    return type
end

function ABTest.numberOverflow(number)
    if number >= -2147483648 and number <= 0x7fffffff then
        return number
    end

    local temp = number
    if number < 0 then
        number = number * (-1)
    end

    local overflowNumber = bit.band(number, 0x80000000)
    if overflowNumber == 0x80000000 then
        overflowNumber = bit.band(number, 0xffffffff) - 0x100000000
    else
        overflowNumber = bit.band(number, 0xffffffff)
    end

    if temp < 0 then
        overflowNumber = overflowNumber * (-1)
    end

    return overflowNumber
end

function ABTest.hashCode(str)
    if type(str) ~= "string" then
        return
    end

    local h = 0
    local length = #str
    if h == 0 and length > 0 then
        for i = 1,length do
            h = ABTest.numberOverflow(ABTest.numberOverflow(h * 31) + string.byte(str,i))
        end
    end
    return h
end

function ABTest.uniqueID()
    local userID = aimi.User.getUserID()
    if  type(userID) == "string" and #userID > 0 then
        print("use userid as uniqueID,userID=", userID)
        return userID
    end
    
    local deviceId = aimi.Device.getDeviceIdentifier()
    if  type(deviceId) == "string" and #deviceId > 0 then
        local uid = math.abs(tonumber(ABTest.hashCode(deviceId)))
        print("use deviceId's hashCode as uniqueID, uniqueID=", uid)
        return uid
    end

    print("error, get uniqueID failed")
    return ""
end

return ABTest