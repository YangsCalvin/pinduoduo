-- 打点 营销(包含888) H5为主
local CheckCommonActivityTaskV2 = class("CheckCommonActivityTaskV2")
local Promise = require("base/Promise")
local APIService = require("common/APIService")
local Navigator = require("common/Navigator")
local Version = require("base/Version")
local Tracking = require("common/Tracking")
local MD5 = require("common/MD5")
local COMMON_LAST_SHOW_ACTIVITY_DAY_KEY = "CommonLuaLastShowActivityDay_"
local COMMON_LAST_SHOW_ACTIVITY_TRACKING_DAY_KEY = "CommonLuaLastShowActivityTrackingDay_"

function CheckCommonActivityTaskV2.run(resolve)

    AMBridge.call("PDDElasticLayerManager", "getWindowSwitch", nil, function(errorCode, response)
        local openNew = response["value"] 
        if openNew == "1" and (Version.new(aimi.Application.getApplicationVersion()) >= Version.new("4.12.0")) then
            return aimi.call(resolve)
        else 
            return CheckCommonActivityTaskV2.real(resolve)   
        end
    end)

end

function CheckCommonActivityTaskV2.real(resolve) 

    local hasPushPageFlag = tonumber(aimi.KVStorage.getInstance():get("LUA_HAS_PUSH_PAGE_FLAG_KEY"))
    if hasPushPageFlag == 1 then
        return aimi.call(resolve)
    end

    if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.50.0") and tostring(aimi.Navigator.getVisiblePage()) ~= "pdd_home" then
        return aimi.call(resolve)
    end

    AMBridge.call("AMNetwork", "info", nil, function(error, payload)
        if type(payload) ~= "table" or payload["reachable"] == 0 then
            return aimi.call(resolve)
        end
        
        local function checkMarketActivityV2(pddId)
            local md5DeviceID = ""
            if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.42.0") then
                md5DeviceID = MD5.sumhexa("34d699" .. aimi.Device.getDeviceIdentifier())
            else
                md5DeviceID = aimi.DataCrypto.md5("34d699" .. aimi.Device.getDeviceIdentifier())
            end

            local apiUrl = "api/flow/hungary/window/query"
            APIService.postJSON(apiUrl, {
                ["device_id"] = md5DeviceID
            }):next(function(response)
                local activitys = response.responseJSON["list"]

                return Promise.new(function(resolve, reject)
                      if activitys == nil or type(activitys) ~= "table" or #activitys <= 0 then
                          return reject("No has activity")
                      end

                      local function isSameDayToNow(t1)
                          if t1 == nil then
                            return false
                          end

                          local d1 = os.date("*t", t1)
                          local d2 = os.date("*t", os.time())
                          return d1.year == d2.year and d1.month == d2.month and d1.day == d2.day
                      end
                      
                      local activity = nil
                      for _,value in ipairs(activitys) do
                          if activity ~= nil then
                            break
                          end

                          local actPopWay = tonumber(value["pop_way"])
                          local actWindowId = tostring(value["window_id"])
                          local actStyle = tonumber(value["style"])
                          local actSceneId = tostring(value["scene_id"])
                          local lastDay = ""
                          if actStyle == 5 then
                              lastDay = tonumber(aimi.KVStorage.getInstance():get(COMMON_LAST_SHOW_ACTIVITY_TRACKING_DAY_KEY .. actSceneId))
                          else
                              lastDay = tonumber(aimi.KVStorage.getInstance():get(COMMON_LAST_SHOW_ACTIVITY_DAY_KEY .. actWindowId))
                          end


                          if actPopWay == 0 then
                              activity = value
                          elseif actPopWay == 1 then
                              if not isSameDayToNow(lastDay) then
                                  activity = value
                              end
                          elseif actPopWay == 2 then 
                              if lastDay == nil then
                                  activity = value
                              end
                          elseif actPopWay == 3 then
                              if lastDay == nil or (os.time() - lastDay > 30 * 24 * 3600) then
                                  activity = value
                              end
                          end
                      end

                      if type(activity) ~= "table" or activity == nil then
                          return reject("Activity is invalid")
                      end

                      local windowId = tostring(activity["window_id"])
                      local style = tonumber(activity["style"])
                      local webUrl = activity["url"]
                      local params = activity["params"]
                      local popWay = tonumber(activity["pop_way"])
                      local sceneId = tostring(activity["scene_id"])

                      local function trackingPopup(targetUrl)
                          local attr = {}
                          attr["sub_op"] = "auto_forward"
                          if type(targetUrl) == "string" and #targetUrl > 0 then 
                              attr["target_url"] = string.encodeURI(targetUrl)
                          end
                          if type(windowId) == "string" and #windowId > 0 then
                              attr["window_id"] = windowId
                          end
                          attr["style"] = tostring(style)
                          if type(sceneId) == "string" and #sceneId > 0 then
                              attr["scene_id"] = sceneId
                          end

                          if type(pddId) == "string" then 
                              if #pddId > 0 then
                                  local pddIdMD5 = ""
                                  if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.42.0") then
                                      pddIdMD5 = MD5.sumhexa(pddId)
                                  else
                                      pddIdMD5 = aimi.DataCrypto.md5(pddId)
                                  end
                                  attr["pdd_id"] = pddIdMD5
                              elseif #pddId == 0 then
                                  attr["pdd_id"] = ""
                              end
                          end

                          Tracking.send("event", "index_popup_event", attr)
                      end
                      
                      if style == 1 then
                          if type(webUrl) ~= "string" or #webUrl == 0 then
                              reject("Invalid mask url")
                              return
                          end

                          trackingPopup(webUrl)

                          Navigator.mask({
                              ["type"] = "web",
                              ["props"] = {
                                  ["url"] = webUrl,
                                  ["opaque"] = false,
                                  ["extra"] = {
                                      ["result"] = activity,
                                      ["complete"] = function(errorCode, response)
                                          Navigator.dismissMask()
                                          local confirmed = response["confirmed"]
                                          if confirmed == 0 then
                                              reject("User cancelled")
                                          else
                                              local maskUrls = params["mask_urls"]
                                              local forwardUrl = maskUrls[confirmed]
                                              if type(forwardUrl) == "string" and #forwardUrl > 0 then
                                                  resolve(forwardUrl)
                                              else 
                                                  reject("Invalid forward url")
                                              end
                                          end
                                      end,
                                  },
                              },
                          }, function(errorCode)
                              if errorCode == 0 then
                                  if popWay ~= 0 then
                                      aimi.KVStorage.getInstance():set(COMMON_LAST_SHOW_ACTIVITY_DAY_KEY .. windowId, tostring(os.time()))
                                  end
                              else
                                  reject("Cannot show mask")
                              end
                          end)
                      elseif style == 2 then
                          if type(webUrl) ~= "string" or #webUrl == 0 then
                              reject("Invalid forward url")
                              return
                          end

                          trackingPopup(webUrl)

                          Navigator.forward(Navigator.getTabIndex(), {
                              ["type"] = "web",
                              ["props"] = {
                                  ["url"] = webUrl,
                              },
                          }, function(errorCode)
                              if errorCode == 0 then
                                  if popWay ~= 0 then
                                      aimi.KVStorage.getInstance():set(COMMON_LAST_SHOW_ACTIVITY_DAY_KEY .. windowId, tostring(os.time()))
                                  end
                              end
                              reject("Forward complete")
                          end)
                      elseif style == 3 then
                          if type(webUrl) ~= "string" or #webUrl == 0 then
                              reject("Invalid base url")
                              return
                          end

                          local forwardURL = webUrl
                          if type(forwardURL) == "string" and #forwardURL > 0 then
                              if string.find(forwardURL, "?") then
                                  forwardURL = webUrl .. "&_x_platform=ios"
                              else
                                  forwardURL = webUrl .. "?_x_platform=ios"
                              end
                          end

                          local trackInfo = {}
                          if type(sceneId) == "string" and #sceneId > 0 then
                              trackInfo["scene_id"] = sceneId
                          end

                          if Version.new(aimi.Application.getApplicationVersion()) >= Version.new("3.65.0") then
                              Navigator.mask({
                                  ["type"] = "pdd_activity_promot_popup",
                                  ["props"] = {
                                      ["extra"] = {
                                          ["result"] = params,
                                          ["window_id"] = windowId,
                                          ["forward_url"] = webUrl,
                                          ["track_info"] = trackInfo,
                                          ["complete"] = function(errorCode, response)
                                              Navigator.dismissMask()
                                              local confirmed = response["confirmed"]
                                              if confirmed == 0 then
                                                  reject("User cancelled")
                                              else
                                                  if type(forwardURL) == "string" and #forwardURL > 0 then
                                                      resolve(forwardURL)
                                                  else 
                                                      reject("Invalid forward url")
                                                  end
                                              end
                                          end
                                      },
                                  },
                              }, function(errorCode)
                                  if errorCode == 0 then
                                      if popWay ~= 0 then
                                          aimi.KVStorage.getInstance():set(COMMON_LAST_SHOW_ACTIVITY_DAY_KEY .. windowId, tostring(os.time()))
                                      end
                                  else
                                      reject("Cannot show mask")
                                  end
                              end)
                          else 
                              reject("Cannot support native popup")
                          end
                      elseif style == 4 then
                          if type(webUrl) ~= "string" or #webUrl == 0 then
                              reject("Invalid mask url")
                              return
                          end

                          trackingPopup(webUrl)

                          Navigator.mask({
                              ["type"] = "web",
                              ["props"] = {
                                  ["url"] = webUrl,
                                  ["opaque"] = false,
                                  ["extra"] = {
                                      ["result"] = activity,
                                      ["complete"] = function(errorCode, response)
                                          Navigator.dismissMask()
                                          local confirmed = response["confirmed"]
                                          if confirmed == 0 then
                                              reject("User cancelled")
                                          else
                                              local forwardURLString = response["url"]
                                              if type(forwardURLString) == "string" and #forwardURLString > 0 then
                                                  resolve(forwardURLString)
                                              else 
                                                  reject("Invalid forward url")
                                              end
                                          end
                                      end,
                                  },
                              },
                          }, function(errorCode)
                              if errorCode == 0 then
                                  if popWay ~= 0 then
                                      aimi.KVStorage.getInstance():set(COMMON_LAST_SHOW_ACTIVITY_DAY_KEY .. windowId, tostring(os.time()))
                                  end
                              else
                                  reject("Cannot show mask")
                              end
                          end)
                      elseif style == 5 then
                          local function trackingIndexPopup(winId, sceId)
                              local attributies = {}
                              attributies["page_sn"] = "10002"
                              attributies["page_el_sn"] = "98084"
                              if type(winId) == "string" and #winId > 0 then
                                  attributies["window_id"] = winId
                              end
                              if type(sceId) == "string" and #sceId > 0 then
                                  attributies["scene_id"] = sceId
                              end

                              Tracking.send("impr", "index_popup_impr", attributies)
                          end

                          trackingIndexPopup(windowId, sceneId)
                          
                          if popWay ~= 0 then
                              aimi.KVStorage.getInstance():set(COMMON_LAST_SHOW_ACTIVITY_TRACKING_DAY_KEY .. sceneId, tostring(os.time()))
                          end

                          reject("tracking finished")
                      end
                end)
            end):next(function(url)
                Navigator.forward(Navigator.getTabIndex(), {
                    ["type"] = "web",
                    ["props"] = {
                        ["url"] = url,
                    },
                }, function()
                    aimi.call(resolve)
                end)
            end):catch(function(error)
                aimi.call(resolve)
            end)
        end
        
        if Version.new(aimi.Application.getApplicationVersion()) < Version.new("3.44.0") then
            checkMarketActivityV2()
        else
            AMBridge.call("PDDMeta", "info", nil, function(errorCode, response)
                if type(response) ~= "table" then
                    return aimi.call(resolve)
                end

                local pddid = response["pdd_id"]
                if type(pddid) ~= "string" or #pddid == 0 then
                    return aimi.call(resolve)
                end

                checkMarketActivityV2(pddid)
            end)
        end
    end)
end

return CheckCommonActivityTaskV2