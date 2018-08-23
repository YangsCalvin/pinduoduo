function class(name, super)
    local tag = type(super)
    local cls = {
        __classname = name,
    }

    if tag ~= "table" and tag ~= "function" then
        super = nil
    end

    if tag == "function" or (tag == "table" and super.__create) then
        if tag == "function" then
            cls.__create = super
            cls.constructor = function()
            end
        else
            cls.__create = super.__create
            cls.super = super

            for key, value in pairs(super) do
                cls[key] = value
            end
        end

        function cls.new(...)
            local instance = cls.__create(...)

            for key, value in pairs(cls) do
                instance[key] = value
            end

            instance.__class = cls
            instance:constructor(...)

            return instance
        end
    else
        if super then
            setmetatable(cls, {
                __index = super,
            })
            cls.super = super
        else
            cls.constructor = function()
            end
        end

        cls.__index = cls

        function cls.new(...)
            local instance = setmetatable({}, cls)

            instance.__class = cls
            instance:constructor(...)

            return instance
        end
    end

    return cls
end