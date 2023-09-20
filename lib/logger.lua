local stringbuilder = require(".PortOS.lib.data.stringbuilder")

local Log = {
    Entries = {},
    Levels = {
        "Trace",
        "Info ",
        "Warn ",
        "Error",
        "Fatal"
    }
}

local function createEntry(self, level, message)
    local msg = {
        Level = level,
        Message = message,
        Time = os.epoch("utc")
    }
    table.insert(self.Entries, msg)
end

local function Write(self, level, message, location)
    if location then
        local msg = "@"..tostring(location).." | "..tostring(message)
        createEntry(self, level, msg)
    else
        createEntry(self, level, tostring(message))
    end
end
Log["Write"] = Write

local function Info(self, message, location)
    self:Write(1, message, location)
end
Log["Info"] = Info

local function Trace(self, message, location)
    self:Write(0, message, location)
end
Log["Trace"] = Trace

local function Warn(self, message, location)
    self:Write(2, message, location)
end
Log["Warn"] = Warn

local function Error(self, message, location)
    self:Write(3, message, location)
end
Log["Error"] = Error

local function Fatal(self, message, location)
    self:Write(4, message, location)
end
Log["Fatal"] = Fatal

local function makeString(self)
    local builder = stringbuilder.new()
    for _,entry in pairs(self.Entries) do
        local line = "["..(self.Levels[entry.Level]).."]"
        local time = entry.Time / 1000
        local time_table = os.date("*t", time)
        local date = textutils.serialise(time_table)
        line = " ["..(date.year).."/"..(date.month).."/"..(date.day).." "..(date.hour)..":"..(date.min)..":"..(date.sec).."] "..line
        line = line..entry.Message
        builder:appendLine("line")
    end
    
    return builder.build()
end
Log["__tostring"] = makeString

local function Save(self, location)
    local isLogFile = location:sub(-3) == "log"
    if (fs.exists(location) and not isLogFile) or isLogFile then
        error("Location is not a valid log save location", 2)
    else
        local file = fs.open(location, "a")
        file.write(self:__tostring())
        file.close()
    end
end
Log["Save"] = Save

return Log
