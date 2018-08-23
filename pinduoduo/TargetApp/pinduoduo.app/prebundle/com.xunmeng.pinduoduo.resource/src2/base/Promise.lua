local Promise = class("Promise")


Promise.State = {
    Pending = 0,
    Fullfilled = 1,
    Rejected = 2,
}


local PromiseInternal = class("PromiseInternal")

function PromiseInternal:constructor(promise)
    self.promise_ = promise
end

function PromiseInternal:transit(state, value)
    if self.promise_.state_ == state then
        return
    end

    if self.promise_.state_ ~= Promise.State.Pending then
        return
    end

    if state ~= Promise.State.Fullfilled and state ~= Promise.State.Rejected then
        return
    end

    self.promise_.state_ = state
    self.promise_.value_ = value
    self:run()
end

function PromiseInternal:run()
    if self.promise_.state_ == Promise.State.Pending then
        return
    end

    if #(self.promise_.queue_) <= 0 then
        return
    end

    aimi.Scheduler.getInstance():schedule(0, function()
        while #(self.promise_.queue_) > 0 do
            local item = table.remove(self.promise_.queue_, 1)
            local func = (self.promise_.state_ == Promise.State.Fullfilled and
                (item.resolve or function(x)
                    return x
                end) or
                (item.reject or function(x)
                    error(x)
                end))
            local ret, message = pcall(function()
                self:resolve(item.promise, func(self.promise_.value_))
            end)

            if not ret then
                item.promise.internal_:transit(Promise.State.Rejected, message)
            end
        end
    end)
end

function PromiseInternal:resolve(promise, x)
    if promise == x then
        return promise.internal_:transit(Promise.State.Rejected, "TypeError")
    end

    if getmetatable(x) == Promise then
        if x.state_ == Promise.State.Pending then
            x:next(function(value)
                promise.internal_:transit(Promise.State.Fullfilled, value)
            end, function(reason)
                promise.internal_:transit(Promise.State.Rejected, reason)
            end)
        else
            promise.internal_:transit(x.state_, x.value_)
        end

        return
    end

    if type(x) == "table" then
        local nextfunc = x["next"]

        if type(nextfunc) == "function" then
            local called = false
            local call = function(func)
                if called then
                    return
                end

                called = true
                func()
            end

            local ret, message = pcall(function()
                nextfunc(x, function(value)
                    call(function()
                        promise.internal_:resolve(promise, value)
                    end)
                end, function(reason)
                    call(function()
                        promise.internal_:transit(Promise.State.Rejected, reason)
                    end)
                end)
            end)

            if not ret then
                call(function()
                    promise.internal_:transit(Promise.State.Rejected, message)
                end)
            end
        else
            promise.internal_:transit(Promise.State.Fullfilled, x)
        end

        return
    end

    promise.internal_:transit(Promise.State.Fullfilled, x)
end


local function toPromiseList(...)
    local arguments = { ... }
    local promises = {}
    local function extractPromise(value)
        local tag = type(value)

        if tag == "function" then
            table.insert(promises, Promise.new(value))
        elseif getmetatable(value) == Promise then
            table.insert(promises, value)
        elseif tag == "table" then
            for _, elem in ipairs(value) do
                extractPromise(elem)
            end
        end
    end

    extractPromise(arguments)

    return promises
end

function Promise.all(...)
    local promises = toPromiseList(...)

    if #promises <= 0 then
        return Promise.new():resolve({})
    end

    return Promise.new(function(resolve, reject)
        local count = 0
        local values = {}
        local called = false
        local function call(func)
            if called then
                return
            end

            called = true
            func()
        end

        for index, promise in ipairs(promises) do
            promise:next(function(value)
                count = count + 1
                values[index] = value

                if count == #promises then
                    call(function()
                        resolve(values)
                    end)
                end
            end, function(reason)
                call(function()
                    reject(reason)
                end)
            end)
        end
    end)
end

function Promise.sequence(...)
    local promises = toPromiseList(...)

    if #promises <= 0 then
        return Promise.new():resolve({})
    end

    return Promise.new(function(resolve, reject)
        local values = {}
        local index = 1
        local function process()
            if index > #promises then
                return resolve(values)
            end

            local promise = promises[index]

            promise:next(function(value)
                values[index] = value
                index = index + 1
                process()
            end, function(reason)
                reject(reason)
            end)
        end

        process()
    end)
end

function Promise:constructor(func)
    self.internal_ = PromiseInternal.new(self)
    self.state_ = Promise.State.Pending
    self.value_ = nil
    self.queue_ = {}

    if type(func) == "function" then
        local ret, message = pcall(function()
            func(function(value)
                self:resolve(value)
            end, function(reason)
                self:reject(reason)
            end)
        end)

        if not ret then
            self:reject(message)
        end
    end
end

function Promise:state()
    return self.state_
end

function Promise:next(resolve, reject)
    local promise = Promise.new()

    table.insert(self.queue_, {
        resolve = resolve,
        reject = reject,
        promise = promise,
    })

    self.internal_:run()

    return promise
end

function Promise:catch(reject)
    return self:next(nil, reject)
end

function Promise:resolve(value)
    self.internal_:transit(Promise.State.Fullfilled, value)

    return self
end

function Promise:reject(reason)
    self.internal_:transit(Promise.State.Rejected, reason)

    return self
end


return Promise