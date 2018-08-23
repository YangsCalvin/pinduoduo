local CouponEvent = class("CouponEvent")


function CouponEvent:constructor(data)
    self:populate(data)
end

function CouponEvent:populate(data)
    self.eventID = nil
    self.startTime = 0
    self.endTime = 0
    self.batchIDs = {}
    self.isTaken = false

    if data == nil then
        return
    end

    self.eventID = data["id"]
    self.startTime = tonumber(data["start_time"]) or 0
    self.endTime = tonumber(data["end_time"]) or 0
    self.batchIDs = data["batch_ids"] or {}
    self.isTaken = data["is_taken"] or false
end

function CouponEvent:data()
    return {
        ["id"] = self.eventID,
        ["start_time"] = self.startTime,
        ["end_time"] = self.endTime,
        ["batch_ids"] = self.batchIDs,
        ["is_taken"] = self.isTaken,
    }
end


return CouponEvent
