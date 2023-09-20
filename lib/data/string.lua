local stringbuilder = require(".PortOS.lib.data.stringbuilder")

getmetatable('').__index = function(str, i)
    if type(i) == "number" then
        return string.sub(str, i, i)
    else
        return string[i]
    end
end

string.locate = function(str, value)
    if type(str) ~= "string" then
        error("First argument expected string, got " .. type(str), 2)
    end
    for idx = 0, #str do
        local val = str[idx]
        if val == value then
            return idx
        end
    end
    return -1
end
string.split = function(str, char)
    if char == nil then
        char = ""
    end
    if type(str) ~= "string" then
        error("First argument expected string, got " .. type(str), 2)
    end
    if type(char) ~= "string" then
        error("Second argument expected string, got " .. type(char), 2)
    end
    local result = {}
    if char == nil or #char == 0 then
        for c in string.gmatch(str, ".") do
            table.insert(result, c)
        end
    else
        for c in string.gmatch(str, "([^" .. char .. "]+)") do
            table.insert(result, c)
        end
    end

    return result
end

string.wrap = function(str, width)
    if width < 1 then
        error("Width expected to be 1 or greater (1 > " .. width .. ")", 2)
    end

    local words = str:split(" ")
    local hadBadSplit = true

    while hadBadSplit do
        hadBadSplit = false
        local splits = {}
        for idx, word in pairs(words) do
            if #word > width then
                hadBadSplit = true
                table.insert(splits, word:sub(1, width))
                if width + 1 <= #word then
                    table.insert(splits, word:sub(width + 1))
                end
            else
                table.insert(splits, word)
            end
        end
        words = splits
    end

    local lines = {}
    local line = new(stringbuilder)()
    for _, word in pairs(words) do
        if line:length() + #word + 1 > width then
            table.insert(lines, line:remove(1, 1):build())
            line:clear()
        end
        line:append(" " .. word)
    end
    table.insert(lines, line:remove(1, 1):build())

    return lines
end

string.pad = function(str, width, padding)
    if width < 1 then
        error("Width expected to be 1 or greater (1 > " .. width .. ")", 2)
    end
    padding = padding or " "
    if #str >= width then
        return str
    else
        local pad = (width - #str) / 2
        local padsLeft = math.ceil(math.ceil(pad) / #padding)
        local padsRight = math.floor(math.floor(pad) / #padding)
        return (string.rep(padding, padsLeft)) .. str .. (string.rep(padding, padsRight))
    end
end
