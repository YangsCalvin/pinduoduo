local TaskQueue = class("TaskQueue")

local Promise = require("base/Promise")


function TaskQueue:constructor()
    self.tasks_ = {}
    self.isExecuting_ = false
end

function TaskQueue:push(task)
    if type(task) ~= "function" then
        return
    end

    table.insert(self.tasks_, task)
    self:process_()
end


function TaskQueue:process_()
    if #self.tasks_ <= 0 then
        return
    end

    if self.isExecuting_ then
        return
    else
        self.isExecuting_ = true
    end

    local task = table.remove(self.tasks_, 1)
    local promise = Promise.new(task)

    promise:next(function()
        self.isExecuting_ = false
        self:process_()
    end, function()
        self.isExecuting_ = false
        self:process_()
    end)
end


return TaskQueue