local control = require(".PortOS.lib.controls.control")

-- Properties and Class Definition
class 'app' {
    controls = {},
    _oldBounds = {},
    Background = colors.black,
    focusedControl = nil,

    -- Rendering
    getControlsInRect = function(controls, rect)
        local roundRect = rect:truncate()
        local output = {}

        for _, c in pairs(controls) do
            local roundBounds = c.bounds:truncate()
            if roundBounds:intersectsWith(roundRect) then
                table.insert(output, c)
            end
        end

        return output
    end,
    getControlsToConsider = function(controls, idx)
        local toConsider = {
            behind = table.sub(controls, 1, idx - 1),
            before = {}
        }
        local toCheck = table.sub(controls, idx - 1)

        for _, c in pairs(toCheck) do
            if not c.updateGraphics then
                table.insert(toConsider.before, c)
            end
        end

        return toConsider
    end,
    renderControl = function(self, control, idx, force)
        if control.Enabled and (control.updateGraphics or force) then
            control.updateGraphics = false
            if control.draw then
                local predrawn = false
                if self["_oldBounds"][control[".screenuuid"]] then
                    local oldBounds = self["_oldBounds"][control[".screenuuid"]]
                    local dx = oldBounds.Left ~= control.bounds.Left
                    local dy = oldBounds.Top ~= control.bounds.Top
                    local dw = oldBounds.Width ~= control.bounds.Width
                    local dh = oldBounds.Height ~= control.bounds.Height

                    if dx or dy or dw or dh then
                        local toConsider = self.getControlsToConsider(self.controls, idx)
                        local toRedrawBehind = self.getControlsInRect(toConsider.behind, oldBounds)
                        local toRedrawBefore = self.getControlsInRect(toConsider.before, oldBounds)
                        paintutils.drawFilledBox(oldBounds.Left, oldBounds.Top, oldBounds.Left + oldBounds.Width - 1,
                            oldBounds.Top + oldBounds.Height - 1, self.Background)

                        for _, control in pairs(toRedrawBehind) do
                            control:draw()
                        end
                        control:draw()
                        predrawn = true
                        for _, control in pairs(toRedrawBefore) do
                            control:draw()
                        end
                    end
                end

                self["_oldBounds"][control[".screenuuid"]] = {
                    Left = control.bounds.Left,
                    Top = control.bounds.Top,
                    Width = control.bounds.Width,
                    Height = control.bounds.Height
                }

                if not predrawn then
                    local toRedraw = self.getControlsInRect(self.getControlsToConsider(self.controls, idx).before,
                        control.bounds)

                    control:draw()
                    for _, c in pairs(toRedraw) do
                        c:draw()
                    end
                end
            end
        end
    end,
    draw = function(self, force)
        local cursorBlink = term.getCursorBlink()
        term.setCursorBlink(false)

        for idx, control in pairs(self.controls) do
            self.renderControl(self, control, idx, force)
        end

        term.setCursorBlink(cursorBlink)
    end,
    invalidate = function(self, force)
        term.setBackgroundColor(self.Background)
        term.clear()

        self:draw(force)
    end,

    -- Click Handling
    _mouseClickHandler = function(self, event, button, x, y)
        local hitControl = false
        for _, control in pairs(table.reverse(self.controls)) do
            if control.Enabled and control.bounds.Left and control.bounds.Width and 
                control.bounds.Top and control.bounds.Height then

                local inXBounds = control.bounds.Left <= x and control.bounds.Left + control.bounds.Width - 1 >= x
                local inYBounds = control.bounds.Top <= y and control.bounds.Top + control.bounds.Height - 1 >= y

                if inXBounds and inYBounds then
                    if self.focusedControl then
                        if self.focusedControl.unfocus then
                            self.focusedControl:unfocus(control)
                        end
                    end
                    local data = {
                        scroll = event == "mouse_scroll",
                        button = button,
                        X = 1 + x - control.bounds.Left,
                        Y = 1 + y - control.bounds.Top
                    }

                    self.mouseclick:invoke(control, data)
                    self.focusedControl = control
                    hitControl = true
                    break
                end
            end
        end
        if not hitControl then
            if self.focusedControl then
                if self.focusedControl.unfocus then
                    self.focusedControl:unfocus(control)
                end
            end
            self.focusedControl = nil

            local data = {
                scroll = event == "mouse_scroll",
                button = button,
                X = x,
                Y = y
            }
            self.mouseclick:invoke(nil, data)
        end
    end,
    handleMouse = function(self)
        events:addHandler("mouse_click", self._mouseClickHandler, self)
        events:addHandler("mouse_scroll", self._mouseClickHandler, self)
    end,
    unhandleMouse = function(self)
        events:removeHandler("mouse_click", self._mouseClickHandler)
        events:removeHandler("mouse_scroll", self._mouseClickHandler)
    end,

    -- Elements
    addControl = function(self, ctrl)
        if ctrl.extends == nil or not ctrl:extends(control) then
            error("Expected type extending Control, got "..typeof(ctrl), 2)
        end
        ctrl[".screenuuid"] = os.epoch("utc") - #self.controls
        table.insert(self.controls, ctrl)
        ctrl:bind(self)
    end,
    removeControl = function(self, control)
        if control.extends == nil or not control:extends(control) then
            error("Expected type extending Control, got "..typeof(control), 2)
        end
        local loc = -1
        for idx, con in pairs(self.controls) do
            if con[".screenuuid"] == control[".screenuuid"] then
                loc = idx
                break
            end
        end
        if loc == -1 then
            return false
        else
            if self.controls[loc].destroy then
                if type(self.controls[loc].destroy) == "table" then
                    for _, func in pairs(self.controls[loc].destroy) do
                        func(self.controls[loc])
                    end
                else
                    self.controls[loc]:destroy()
                end
            end
            table.remove(self.controls, loc)
            return true
        end
    end,
    containsControl = function(self, control)
        if control.extends == nil or not control:extends(control) then
            error("Expected type extending Control, got "..typeof(control), 2)
        end
        if control[".screenuuid"] then
            for _, con in pairs(self.controls) do
                if con[".screenuuid"] == control[".screenuuid"] then
                    return true
                end
            end
        end

        return false
    end,
    clear = function(self)
        for _, control in pairs(self.controls) do
            self:removeControl(control)
        end
        self._oldBounds = {}
        self.focusedControl = nil
    end,
    bringToFront = function(self, control)
        if control.extends == nil or not control:extends(control) then
            error("Expected type extending Control, got "..typeof(control), 2)
        end
        for idx, c in pairs(self.controls) do
            if c[".screenuuid"] == control[".screenuuid"] then
                table.remove(self.controls, idx)
                break
            end
        end
        table.insert(self.controls, control)
    end,
    pushToBack = function(self, control)
        if control.extends == nil or not control:extends(control) then
            error("Expected type extending Control, got "..typeof(control), 2)
        end
        for idx, c in pairs(self.controls) do
            if c[".screenuuid"] == control[".screenuuid"] then
                table.remove(self.controls, idx)
                break
            end
        end
        table.insert(self.controls, 1, control)
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
