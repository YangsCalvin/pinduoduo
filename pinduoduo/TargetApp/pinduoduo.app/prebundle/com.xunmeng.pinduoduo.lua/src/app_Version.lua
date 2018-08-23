Version = Version or class("Version")
_V = Version.new


function Version.__eq(a, b)
    return a:compare(b) == 0
end

function Version.__lt(a, b)
    return a:compare(b) < 0
end

function Version.__le(a, b)
    return a:compare(b) <= 0
end

function Version.__tostring(version)
    return version:toString()
end


function Version:constructor(versionString)
    versionString = type(versionString) == "string" and versionString or ""

    local tokens = {}

    for token in versionString:gmatch("%d+") do
        table.insert(tokens, token)
    end

    local major, minor, patch = tokens[1], tokens[2], tokens[3]

    self.major_ = tonumber(major or 0)
    self.minor_ = tonumber(minor or 0)
    self.patch_ = tonumber(patch or 0)
end

function Version:compare(version)
    if version == nil or type(version) == "string" then
        version = Version.new(version)
    end

    if version.__class ~= Version then
        error("Cannot compare")
    end

    if self.major_ ~= version.major_ then
        return self.major_ - version.major_
    elseif self.minor_ ~= version.minor_ then
        return self.minor_ - version.minor_
    else
        return self.patch_ - version.patch_
    end
end

function Version:toString()
    return tostring(self.major_) .. "." .. tostring(self.minor_) .. "." .. tostring(self.patch_)
end


return Version