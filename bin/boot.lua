term.clear()
term.setCursorPos(1, 1)
print("Loading libraries..")
shell.run("PortOS/bin/setup.lua")

print("Checking for updates")

print("Starting OS..")
threading:killAllThreads()

local function runShell()
    term.clear()
    term.setCursorPos(1, 1)
    shell.run("shell")
    events:stopEvents()
    threading:stopThreadProcessor()
    threading:killAllThreads()
end

threading:startThread(events.acceptEvents, events)
threading:startThread(shell.run, "./PortOS/bin/ux/explorer")
-- threading:startThread(runShell)

threading:startThreadProcessor()

print("Goodbye!")
sleep(1)
os.shutdown()
