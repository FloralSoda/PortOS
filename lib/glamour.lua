local stringbuilder = require(".PortOS.lib.data.stringbuilder")

class 'glamour' {
    formatTable = function(tbl, depth, tabchar, tab, history)
        if type(depth) ~= "number" then
            error("Depth expects number, received " .. type(depth), 2)
        elseif tab and type(tab) ~= "number" then
            error("Tab expects number, received " .. type(tab), 2)
        end

        tabchar = tabchar or "\t"
        if type(tbl) == "table" and depth > 0 then
            if next(tbl) == nil then
                return "{}"
            end
            local tab = tab or 1
            local sb = new 'stringbuilder'("{\n")
            for key, value in pairs(tbl) do
                local line = string.rep(tabchar, tab)
                line = line .. tostring(key) .. ": " .. glamour.formatTable(value, depth - 1, tabchar, tab + 2)
                sb:appendLine(line)
            end
            sb:append(string.rep(tabchar, tab - 2) .. "}")

            return sb:build()
        elseif type(tbl) == "table" then
            return "{" .. #tbl .. " entries}"
        elseif type(tbl) == "function" then
            local info = debug.getinfo(tbl, "S")
            return info.linedefined .. info.source
        elseif type(tbl) == "string" then
            return "\"" .. tbl:gsub('"', '\\"') .. "\""
        else
            return tostring(tbl)
        end
    end
}

return glamour
