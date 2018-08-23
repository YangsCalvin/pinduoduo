aimi = aimi or {}


function aimi.handler(instance, method)
    return function(...)
        return method(instance, ...)
    end
end

function aimi.call(func, ...)
    if func ~= nil then
        func(...)
    end
end


return aimi
