local control = require(".PortOS.lib.controls.control")
local container = require ".PortOS.lib.controls.container"
-- Properties and Class Definition
class 'app' 'container' {
    controls = {},
    _oldBounds = {},
    Background = colors.black,
    focusedControl = nil,

    -- Click Handling
    handleMouse = function(self)
        events:addHandler("mouse_click", self._mouseClickHandler, self)
        events:addHandler("mouse_scroll", self._mouseClickHandler, self)
    end,
    unhandleMouse = function(self)
        events:removeHandler("mouse_click", self._mouseClickHandler)
        events:removeHandler("mouse_scroll", self._mouseClickHandler)
    end,

    -- Control
    new = function(this)
        this {
            mouseclick = events:createEvent()
        }
    end,
    run = function(self)
        if self.threadId then
            error("Application was already running! Create a copy if you want two", 2)
        end

        self:handleMouse()
        self:invalidate()

        self["threadId"] = threading:startTimer(0, self.draw, self)
    end,
    stop = function(self)
        if self.threadId then
            self:unhandleMouse()
            threading:killThread(self["threadId"])
            self:clear()
            self.threadId = nil
        end
    end,
    destroy = function(self)
        for _, ctrl in pairs(self.controls) do
            if ctrl.destroy then
                ctrl:destroy(self)
            end
        end
        self = nil
    end,
    pause = function(self)
        if self.threadId and not self.paused then
            self:unhandleMouse()
            self.paused = true

            threading:pauseThread(self.threadId)
        end
    end,
    resume = function(self)
        if self.threadId and self.paused then
            self:handleMouse()
            self:invalidate()

            threading:resumeThread(self.threadId)
            self.paused = false
        else
        end
    end
}
---@diagnostic disable-next-line: undefined-global
return app
