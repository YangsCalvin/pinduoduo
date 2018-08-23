function string.decodeURI(str)
    str = string.gsub(str, "%%(%x%x)", function(hex)
        return string.char(tonumber(hex, 16))
    end)
    
    return str
end

function string.encodeURI(str)
    str = string.gsub(str, "([^%w%.%-%_ ])", function(ch)
        return string.format("%%%02X", string.byte(ch))
    end)

    return string.gsub(str, " ", "+")
end