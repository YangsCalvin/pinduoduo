local Config = {}


if Env == nil then
    Config.APIHost = "http://apiv2.yangkeduo.com/"
    Config.TrackingService = "http://t.yangkeduo.com/t.gif"
    Config.TrackingErrorService = "http://e.tracking.yangkeduo.com/e.gif"
    Config.TrackingPerformanceService = "http://p.tracking.yangkeduo.com/p.gif"
    Config.CMTService= "http://cmta.yangkeduo.com/api/batch"
    Config.AM_WEB_HOST = "http://mobile.yangkeduo.com/"
    Config.AppMode = "RELEASE"
    Config.AppScheme = "pinduoduo"
else
    Config.APIHost = Env.AM_API_HOST
    Config.TrackingService = Env.AM_TRACKING_SERVICE or "http://t.yangkeduo.com/t.gif"
    Config.TrackingErrorService = Env.AM_TRACKING_ERROR_SERVICE or "http://e.tracking.yangkeduo.com/e.gif"
    Config.TrackingPerformanceService = Env.AM_TRACKING_PERFORMANCE_SERVICE or "http://p.tracking.yangkeduo.com/p.gif"
    Config.CMTService = Env.AM_CMT_SERVICE or "http://cmta.yangkeduo.com/api/batch"
    Config.AM_WEB_HOST = Env.AM_WEB_HOST or "http://mobile.yangkeduo.com/"
    Config.AppMode =  Env.AM_APP_MODE or "RELEASE"
    Config.AppScheme = Env.AM_APP_SCHEME or "pinduoduo"
end

Config.APICDNHost = "http://api-static.yangkeduo.com/"
Config.MetaHost = "http://meta.yangkeduo.com/"

return Config