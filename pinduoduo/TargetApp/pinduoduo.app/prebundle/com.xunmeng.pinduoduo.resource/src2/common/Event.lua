local Event = {}


Event.ApplicationResume = "onApplicationResume"
Event.ApplicationPause = "onApplicationPause"
Event.ApplicationStop = "onApplicationStop"

Event.DeviceToken = "AMDeviceTokenNotification"
Event.UserNotifySettings = "AMUserNotifySettingsNotification"
Event.LuaHotSwapped = "AMLuaHotSwapped"

Event.ComponentUpdated = "PDDComponentUpdatedNotification"
Event.ExternalNotification = "PDDExternalNotification"
Event.ReceiveSocketMessage = "PDDReceiveSocketMessage"
Event.UserLogin = "PDDLoginNotification"
Event.UserLogout = "PDDLogoutNotification"
Event.UserNotificationSettings = "PDDUserNotificationSettings"
Event.PDDListUpdatedTimeNotification = "PDDListUpdatedTimeNotification"
Event.PDDClearBadgeNotification = "PDDClearBadgeNotification"
Event.PDDLuaResourceLoadedNotification = "PDDLuaResourceLoadedNotification"
Event.PDDActivityResourceLoadedNotification = "PDDActivityResourceLoadedNotification"
Event.PDDUpdateGrayFeaturesNotification = "PDDUpdateGrayFeaturesNotification"
Event.PDDUpdateFriendChatGrayFeautresNotification = "PDDUpdateFriendChatGrayFeautresNotification"
Event.PDDAppConfigureCenterUpdateNotification = "PDDConfigurationChangeNotification"

return Event