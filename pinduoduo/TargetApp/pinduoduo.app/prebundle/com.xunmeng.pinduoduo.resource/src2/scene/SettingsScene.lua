local SettingsScene = class("SettingsScene")

local Navigator = require("common/Navigator")

function SettingsScene.maskComments()
    print('---------------------SettingsScene.maskComments called---------------------')
    Navigator.mask({
        ["type"] = "web",
        ["props"] = {
            ["url"] = "app_store_comments.html",
            ["opaque"] = false,
            ["extra"] = {
                ["complete"] = function(errorCode, response)
                    Navigator.dismissMask()

                    local confirmed = response["confirmed"]
                    if confirmed == 1 then
                        AMBridge.call("AMLinking", "openURL",{ 
                            ["url"] = "itms-apps://itunes.apple.com/us/app/apple-store/id1044283059" 
                        })
                    elseif confirmed == 2 then
                        Navigator.forward(Navigator.getTabIndex(), {
                            ["type"] = "pdd_feedback_category"
                        })
                    end
                end
            }
        }
    })
end

AMBridgeModule.export("SettingsScene", "maskComments", SettingsScene.maskComments)

return SettingsScene