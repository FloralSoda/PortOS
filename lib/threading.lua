local threading = {
    processThreads = false,
    threads = {}
}

local function startThread(self, delegate, ...)
    local thread = {}
    thread["coroutine"] = coroutine.create(function()
        delegate(table.unpack(arg))
    end)
    thread["id"] = os.epoch()

    table.insert(self.threads, thread)
    return thread["id"]
end
threading["startThread"] = startThread

local function pauseThread(self, id)
    for idx, thread in pairs(self.threads) do
        if thread.id == id then
            coroutine.yield(thread.coroutine)
            return self.threads.coroutine
        end
    end
end
threading["pauseThread"] = pauseThread
local function resumeThread(self, id)
    for idx, thread in pairs(self.threads) do
        if thread.id == id then
            coroutine.resume(thread.coroutine)
            return self.threads.coroutine
        end
    end
end
threading["resumeThread"] = resumeThread

local function killThread(self, id)
    for idx, thread in pairs(self.threads) do
        if thread.id == id then
            coroutine.yield(thread.coroutine)
            table.remove(self.threads, idx)
            return self.threads.coroutine
        end
    end
    return nil
end
threading["killThread"] = killThread

local function startTimer(self, interval, func, ...)
    return self:startThread(function(...)
        while true do
            func(...)
            sleep(interval)
        end
    end, ...)
end
threading["startTimer"] = startTimer

local function killAllThreads(self)
    for _, thread in pairs(self.threads) do
        coroutine.yield(thread.coroutine)
    end
    self.threads = {}
end
threading["killAllThreads"] = killAllThreads

-- Based on parallel.runUntilLimit
local function startThreadProcessor(self)
    self.processThreads = true

    local filters = {}
    local eventData = {
        n = 0
    }
    while self.processThreads do
        local removed = 0
        for idx, threadData in pairs(self.threads) do
            local thread = threadData.coroutine
            if coroutine.status(thread) == "dead" then
                table.remove(self.threads, idx - removed)
                removed = removed + 1
            end
            if filters[thread] == nil or filters[thread] == eventData[1] or eventData[1] == "terminate" then
                local ok, param = coroutine.resume(thread, table.unpack(eventData, 1, eventData.n))
                if ok then
                    filters[thread] = param
                else
                    error(param, 0)
                end
                if coroutine.status(thread) == "dead" then
                    table.remove(self.threads, idx - removed)
                    removed = removed + 1
                end
            end
        end
        removed = 0
        for idx, threadData in pairs(self.threads) do
            local thread = threadData.coroutine
            if coroutine.status(thread) == "dead" then
                table.remove(self.threads, idx - removed)
            end
        end
        eventData = table.pack(os.pullEventRaw())
    end
end
threading["startThreadProcessor"] = startThreadProcessor

local function stopThreadProcessor(self)
    self.processThreads = false
    sleep(1) -- Holds the thread running this command to ensure the completion of the command. Maybe could be shorter?
end
threading["stopThreadProcessor"] = stopThreadProcessor

local function getThreadStatus(self, index)
    return coroutine.status(self.threads[index])
end

return threading
