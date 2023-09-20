local events = {
    handleEvents = false,
    threads = {}
}

local function addHandler(self, event, delegate, ...)
    if type(delegate) ~= "function" then
        error("Delegate expects function, received " .. type(delegate), 2)
    end
    if type(event) == "table" then
        event = event.id
    elseif type(event) ~= "string" then
        error("Event expected to be a table or a string. Found "..type(event), 2)
    end
    if type(self[event]) ~= "table" then
        self[event] = {}
    end
    local delegateData = {
        delegate = delegate,
        args = {...}
    }
    table.insert(self[event], delegateData)
end
events["addHandler"] = addHandler

local function removeHandler(self, event, delegate)
    if type(event) == "table" then
        event = event.id
    end
    if type(self[event]) ~= "table" then
        return false
    else
        for idx, del in pairs(self[event]) do
            if del.delegate == delegate then
                table.remove(self[event], idx)
                return true
            end
        end

        return false
    end
end
events["removeHandler"] = removeHandler

local function raiseEvent(self, ...)
    os.queueEvent(self.id, ...)
end

local function createEvent(self)
    local base = os.epoch("utc")
    while self[tostring(base)] do
        base = base + math.random(1000)
    end

    local newEvent = {
        invoke = raiseEvent,
        id = tostring(base)
    }
    self[tostring(base)] = {}
    return newEvent
end
events["createEvent"] = createEvent

local function deleteEvent(self, event)
    if type(event) ~= "table" then
        error("Event was not a custom event", 2)
    elseif event.id == nil then
        error("Event was not a custom event", 2)
    elseif self[event.id] == nil then
        error("Event was already removed", 2)
    else
        self[event.id] = nil
    end
end
events["deleteEvent"] = deleteEvent

local function processEvent(self, event, eventData)
    if type(self[event]) == "table" then
        for _, del in pairs(self[event]) do
            local success, errorMsg = pcall(function()
                if #del.args > 0 then
                    del.delegate(table.unpack(del.args), table.unpack(eventData))
                else
                    del.delegate(table.unpack(eventData))
                end
            end)
            if not success then
                error(errorMsg, 0)
            end
        end
    end
end
local function acceptEvents(self)
    self.handleEvents = true
    while self.handleEvents do
        local eventData = {os.pullEvent()}
        local event = eventData[1]

        if event == ".portOS_cancelEvent" then
            self.handleEvents = false
            break
        else
            if self[event] then
                threading:startThread(processEvent, self, event, eventData)
            end
        end
    end
end
events["acceptEvents"] = acceptEvents

local function stopEvents()
    os.queueEvent(".portOS_cancelEvent")
end
events["stopEvents"] = stopEvents

return events
