local function find(tbl, value)
    if type(tbl) ~= "table" then
        error("First argument expected table, got " .. type(tbl), 2)
    end
    for idx, val in pairs(tbl) do
        if val == value then
            return idx
        end
    end
    return nil
end
table["find"] = find

local function compare(tbl, tbl2)
    if type(tbl) ~= "table" then
        error("First argument expected table, got " .. type(tbl), 2)
    elseif type(tbl2) ~= "table" then
        error("Second argument expected table, got " .. type(tbl2), 2)
    end
    local output = {
        conflicts = {},
        difference = {},
        shared = {}
    }
    local doConflict = function(kvp)
        if tbl2[kvp.key] == tbl[kvp.key] then
            output.shared[kvp.key] = kvp.value
        else
            if output.conflicts[kvp.key] == nil then
                output.conflicts[kvp.key] = {kvp.value}
            else
                table.insert(output.conflicts[kvp.key], kvp.value)
            end
        end
    end
    for idx, val in pairs(tbl) do
        local kvp = {}
        kvp["key"] = idx
        kvp["value"] = tbl[idx]
        if tbl2[idx] then
            doConflict(kvp)
        else
            output.difference[idx] = val
        end
    end
    for idx, val in pairs(tbl2) do
        local kvp = {}
        kvp["key"] = idx
        kvp["value"] = tbl2[idx]
        if tbl[idx] then
            doConflict(kvp)
        else
            output.difference[idx] = val
        end
    end
    return output
end
table["compare"] = compare

local function merge(tbl, tbl2)
    if type(tbl) ~= "table" then
        error("First argument expected table, got " .. type(tbl), 2)
    elseif type(tbl2) ~= "table" then
        error("Second argument expected table, got " .. type(tbl2), 2)
    end
    local comparison = table.compare(tbl, tbl2)
    local appended = {}

    for idx, val in pairs(comparison.difference) do
        appended[idx] = val
    end
    for idx, val in pairs(comparison.shared) do
        appended[idx] = val
    end
    for idx, val in pairs(comparison.conflicts) do
        appended[idx] = val
    end

    return appended, comparison.conflicts
end
table["merge"] = merge

local function reverse(tbl)
    local reversed = {}
    for idx, val in pairs(tbl) do
        reversed[1 + #tbl - idx] = val
    end
    return reversed
end
table["reverse"] = reverse

local function sub(tbl, start, finish)
    finish = finish or #tbl

    local subbed = {}

    for i = start, finish do
        table.insert(subbed, tbl[i])
    end

    return subbed
end
table["sub"] = sub

local function shallowCopy(tbl)
    local t = {}
    for k, v in pairs(tbl) do
        t[k] = v
    end

    return t
end
table["shallowCopy"] = shallowCopy
