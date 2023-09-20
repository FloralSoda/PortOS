local network = {
    adapter = nil,
    maxChannels = 128,
    openChannels = 0,
    maxChannel = 65535,
    address = nil
}

local function scanOpenChannels(self)
    local openChannels = {}
    for i = 0, self.maxChannel do
        if self.adapter.isOpen(i) then
            table.insert(openChannels, i)
        end
    end
    self.openChannels = #openChannels
    return openChannels
end
network["scanOpenChannels"] = scanOpenChannels

local function bindAdapter(self, name)
    if type(name) == "string" then
        local success, result = pcall(peripheral.getType, name)
        if success then
            if result == "modem" then
                self.adapter = peripheral.wrap(name)
            else
                error("The provided peripheral was not a modem", 2)
            end
        else
            error("The provided peripheral was not found on the network", 2)
        end
    elseif type(name) == "table" then
        local success, result = pcall(peripheral.getType, name)
        if success then
            if result == "modem" then
                self.adapter = name
            else
                error("The provided peripheral was not a modem", 2)
            end
        else
            error("The provided table was not a peripheral", 2)    
        end
    else
        error("Argument expected string or peripheral, got "..type(name), 2)
    end
    self:scanOpenChannels()
end
network["bindAdapter"] = bindAdapter

local function openChannel(self, channel)
    if type(channel) ~= "number" then
        error("Argument expected number, got "..type(channel), 2)
    elseif math.floor(channel) ~= channel then
        error("Argument expected integer, got real ("..tostring(channel)..")", 2)
    elseif channel < 0 or channel > self.maxChannel then
        error("Channel must be in range 0-"..tostring(self.maxChannel)..", was "..tostring(channel), 2)
    elseif self.openChannels == self.maxChannel then
        error("Maximum open channels is "..tostring(self.maxChannels), 2)
    elseif not self.adapter.isOpen(channel) then
        self.openChannels = self.openChannels + 1
        self.adapter.open(channel)
    end
end
network["openChannel"] = openChannel
local function closeChannel(self, channel)
    if type(channel) ~= "number" then
        error("Argument expected number, got "..type(channel), 2)
    elseif math.floor(channel) ~= channel then
        error("Argument expected integer, got real ("..tostring(channel)..")", 2)
    elseif channel < 0 or channel > self.maxChannel then
        error("Channel must be in range 0-"..tostring(self.maxChannel)..", was "..tostring(channel), 2)
    elseif self.adapter.isOpen(channel) then
        self.openChannels = self.openChannels - 1
        self.adapter.close(channel)
    end
end
network["closeChannel"] = closeChannel

local function receive(self)
    return os.pullEvent("modem_message")
end
network["receive"] = receive

local function receiveAsync(self, callback, ...)
    CallbackWrapper = function(...)
        events:removeHandler("modem_message", CallbackWrapper)
        callback(...)
    end
    events:addHandler("modem_message", CallbackWrapper, ...)
end
network["receiveAsync"] = receiveAsync

local function receiveChannel(self, channel)
    if type(channel) ~= "number" then
        error("Argument expected number, got "..type(channel), 2)
    elseif math.floor(channel) ~= channel then
        error("Argument expected integer, got real ("..tostring(channel)..")", 2)
    elseif channel < 0 or channel > self.maxChannel then
        error("Channel must be in range 0-"..tostring(self.maxChannel)..", was "..tostring(channel), 2)
    end
    local disable = not self.adapter.isOpen(channel)
    if disable and self.openChannels == self.maxChannels then
        error("Too many channels open (Max "..tostring(self.maxChannels)..")", 2)
    else
        self:openChannel(channel)
        while true do
            local event, modem, rchannel, reply, message, distance = self:receive()
            if channel == rchannel then
                return event, modem, channel, reply, message, distance
            end
        end
        if disable then
            self:closeChannel(channel)
        end
    end
end
network["receiveChannel"] = receiveChannel

local function receiveChannelAsync(self, channel, callback, ...)
    if type(channel) ~= "number" then
        error("Argument expected number, got "..type(channel), 2)
    elseif math.floor(channel) ~= channel then
        error("Argument expected integer, got real ("..(channel)..")", 2)
    elseif channel < 0 or channel > self.maxChannel then
        error("Argument must be in range 0-"..(self.maxChannel)..", was "..(channel), 2)
    else
        local disable = not self.adapter.isOpen(channel)
        if disable and self.openChannels == self.maxChannels then
            error("Too many channels open (Max "..(self.maxChannels)..")", 2)
        else
            self:openChannel(channel)
            CallbackWrapper = function(...)
                local args = {...}
                if args[3] == channel then
                    events:removeHandler("modem_message", CallbackWrapper)
                    if disable then
                        self:closeChannel(channel)
                    end
                    callback(...)
                end
            end
            events:addHandler("modem_message", CallbackWrapper, ...)
        end
    end
end
network["receiveChannelAsync"] = receiveChannelAsync

local function buildPacket(sender, destination, contents, protocol, timetolive)
    local header = {
        protocol = protocol,
        sender = sender,
        destination = destination,
        size = #contents,
        timetolive = timetolive or 100
    }
    local body = contents
    
    local packet = {
        header = header,
        body = body
    }
    
    return packet
end
network["buildPacket"] = buildPacket

local function getFreeChannel(self)
    local packet = self.buildPacket(os.getComputerID(), "router", 0, "")
    
    --TODO
end
network["getFreeChannel"] = getFreeChannel

local function sendHandshake(self, channel, protocol, message)
    self.adapter.transmit(channel, channel)
    --TODO
end
