class 'stringbuilder' {
    ---Stores the string entries of a stringbuilder
    [".entries"] = {},
    --- Appends a string to the stringbuilder
    ---@param self table
    ---@param val string
    append = function(self, val)
        table.insert(self[".entries"], val)
        return self
    end,
    ---Appends a string to the stringbuilder with a new line
    ---@param self table
    ---@param val string
    appendLine = function(self, val)
        self:append(val)
        self:append("\n")
        return self
    end,
    insert = function(self, val, idx)
        idx = idx - 1
        local count = 0
        local remainder = 0
        for key, value in pairs(self[".entries"]) do
            if count + #value >= idx then
                remainder = idx - count

                local sideA = ""
                if idx > 0 then
                    sideA = value:sub(1, remainder)
                end
                local sideB = value:sub(remainder + 1)
                local newValue = sideA .. val .. sideB

                self[".entries"][key] = newValue
                break
            end
            count = count + #value
        end
        return self
    end,
    replace = function(self, find, replace)
        for key, value in pairs(self[".entries"]) do
            self[".entries"][key] = value:replace(find, replace)
        end
        return self
    end,
    length = function(self)
        local count = 0
        for _, value in pairs(self[".entries"]) do
            count = count + #value
        end
        return count
    end,
    remove = function(self, from, to)
        if from < 0 then
            from = self:length() + from
        end
        if to == nil then
            to = self:length()
        end
        if to < 0 then
            to = self:length() + to
        end

        local count = 0
        local remainder = 0
        local removing = false
        for key, value in pairs(self[".entries"]) do
            if removing then
                if count + #value > to then
                    remainder = to - count
                    self[".entries"][key] = value:sub(remainder + 1)
                    break
                else
                    count = count + #value
                    self[".entries"][key] = ""
                end
            else
                if count + #value >= from then
                    remainder = from - count
                    removing = true

                    if count + #value >= to then
                        local sideA = value:sub(1, remainder - 1)
                        local sideB = value:sub(1 + to - count)
                        self[".entries"][key] = sideA .. sideB
                        break
                    else
                        self[".entries"][key] = value:sub(1, remainder - 1)
                    end
                end
                count = count + #value
            end
        end

        return self
    end,
    clean = function(self, build)
        if build then
            self[".entries"] = {self:build()}
        else
            local newEntries = {}
            for _, value in pairs(self[".entries"]) do
                if value and #value > 0 then
                    table.insert(newEntries, value)
                end
            end
            self[".entries"] = newEntries
        end
        return self
    end,
    clear = function(self)
        self[".entries"] = {}
        return self
    end,
    build = function(self)
        return table.concat(self[".entries"], '')
    end,
    new = function(this, init)
        if init ~= nil then
            this:append(init)
        end
    end
}

---@diagnostic disable-next-line: undefined-global
return stringbuilder
