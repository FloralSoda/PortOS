local control = require ".PortOS.lib.controls.control"
class 'container' 'control' {
	ctrls = {},
    _oldBounds = {},
    Background = colors.black,

	-- Rendering
	getctrlsInRect = function(ctrls, rect)
		local roundRect = rect:truncate()
		local output = {}

		for _, c in pairs(ctrls) do
			local roundBounds = c.bounds:truncate()
			if roundBounds:intersectsWith(roundRect) then
				table.insert(output, c)
			end
		end

		return output
	end,
	getctrlsToConsider = function(ctrls, idx)
		local toConsider = {
			behind = table.sub(ctrls, 1, idx - 1),
			before = {}
		}
		local toCheck = table.sub(ctrls, idx - 1)

		for _, c in pairs(toCheck) do
			if not c.updateGraphics then
				table.insert(toConsider.before, c)
			end
		end

		return toConsider
	end,
	renderctrl = function(self, ctrl, idx, force)
		if ctrl.Enabled and (ctrl.updateGraphics or force) then
			ctrl.updateGraphics = false
			if ctrl.draw then
				local predrawn = false
				if self["_oldBounds"][ctrl[".screenuuid"]] then
					local oldBounds = self["_oldBounds"][ctrl[".screenuuid"]]
					local dx = oldBounds.Left ~= ctrl.bounds.Left
					local dy = oldBounds.Top ~= ctrl.bounds.Top
					local dw = oldBounds.Width ~= ctrl.bounds.Width
					local dh = oldBounds.Height ~= ctrl.bounds.Height

					if dx or dy or dw or dh then
						local toConsider = self.getctrlsToConsider(self.ctrls, idx)
						local toRedrawBehind = self.getctrlsInRect(toConsider.behind, oldBounds)
						local toRedrawBefore = self.getctrlsInRect(toConsider.before, oldBounds)
						paintutils.drawFilledBox(oldBounds.Left, oldBounds.Top, oldBounds.Left + oldBounds.Width - 1,
							oldBounds.Top + oldBounds.Height - 1, self.Background)

						for _, ctrl in pairs(toRedrawBehind) do
							ctrl:draw()
						end
						ctrl:draw()
						predrawn = true
						for _, ctrl in pairs(toRedrawBefore) do
							ctrl:draw()
						end
					end
				end

				self["_oldBounds"][ctrl[".screenuuid"]] = {
					Left = ctrl.bounds.Left,
					Top = ctrl.bounds.Top,
					Width = ctrl.bounds.Width,
					Height = ctrl.bounds.Height
				}

				if not predrawn then
					local toRedraw = self.getctrlsInRect(self.getctrlsToConsider(self.ctrls, idx).before,
						ctrl.bounds)

					ctrl:draw()
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

		for idx, ctrl in pairs(self.ctrls) do
			self.renderctrl(self, ctrl, idx, force)
		end

		term.setCursorBlink(cursorBlink)
    end,
	invalidate = function(self, force)
        term.setBackgroundColor(self.Background)
        term.clear()

        self:draw(force)
    end,

	-- Elements
    addControl = function(self, ctrl)
        if ctrl.extends == nil or not ctrl:extends(control) then
            error("Expected type extending ctrl, got "..typeof(ctrl), 2)
        end
        ctrl[".screenuuid"] = os.epoch("utc") - #self.ctrls
        table.insert(self.ctrls, ctrl)
        ctrl:bind(self)
    end,
    removeControl = function(self, ctrl)
        if ctrl.extends == nil or not ctrl:extends(control) then
            error("Expected type extending ctrl, got "..typeof(ctrl), 2)
        end
        local loc = -1
        for idx, con in pairs(self.ctrls) do
            if con[".screenuuid"] == ctrl[".screenuuid"] then
                loc = idx
                break
            end
        end
        if loc == -1 then
            return false
        else
            if self.ctrls[loc].destroy then
                if type(self.ctrls[loc].destroy) == "table" then
                    for _, func in pairs(self.ctrls[loc].destroy) do
                        func(self.ctrls[loc])
                    end
                else
                    self.ctrls[loc]:destroy()
                end
            end
            table.remove(self.ctrls, loc)
            return true
        end
    end,
    containsControl = function(self, ctrl)
        if ctrl.extends == nil or not ctrl:extends(control) then
            error("Expected type extending ctrl, got "..typeof(ctrl), 2)
        end
        if ctrl[".screenuuid"] then
            for _, con in pairs(self.ctrls) do
                if con[".screenuuid"] == ctrl[".screenuuid"] then
                    return true
                end
            end
        end

        return false
    end,
    clear = function(self)
        for _, ctrl in pairs(self.ctrls) do
            self:removectrl(ctrl)
        end
        self._oldBounds = {}
        self.focusedctrl = nil
    end,
    bringToFront = function(self, ctrl)
        if ctrl.extends == nil or not ctrl:extends(control) then
            error("Expected type extending ctrl, got "..typeof(ctrl), 2)
        end
        for idx, c in pairs(self.ctrls) do
            if c[".screenuuid"] == ctrl[".screenuuid"] then
                table.remove(self.ctrls, idx)
                break
            end
        end
        table.insert(self.ctrls, ctrl)
    end,
    pushToBack = function(self, ctrl)
        if ctrl.extends == nil or not ctrl:extends(control) then
            error("Expected type extending ctrl, got "..typeof(ctrl), 2)
        end
        for idx, c in pairs(self.ctrls) do
            if c[".screenuuid"] == ctrl[".screenuuid"] then
                table.remove(self.ctrls, idx)
                break
            end
        end
        table.insert(self.ctrls, 1, ctrl)
    end,

    _mouseClickHandler = function(self, event, button, x, y)
        local hitControl = false
        for _, ctrl in pairs(table.reverse(self.ctrls)) do
            if ctrl.Enabled and ctrl.bounds.Left and ctrl.bounds.Width and 
                ctrl.bounds.Top and ctrl.bounds.Height then

                local inXBounds = ctrl.bounds.Left <= x and ctrl.bounds.Left + ctrl.bounds.Width - 1 >= x
                local inYBounds = ctrl.bounds.Top <= y and ctrl.bounds.Top + ctrl.bounds.Height - 1 >= y

                if inXBounds and inYBounds then
                    if self.focusedctrl then
                        if self.focusedctrl.unfocus then
                            self.focusedctrl:unfocus(ctrl)
                        end
                    end
                    local data = {
                        scroll = event == "mouse_scroll",
                        button = button,
                        X = 1 + x - ctrl.bounds.Left,
                        Y = 1 + y - ctrl.bounds.Top
                    }

                    self.mouseclick:invoke(ctrl, data)
                    self.focusedctrl = ctrl
                    hitctrl = true
                    break
                end
            end
        end
        if not hitctrl then
            if self.focusedctrl then
                if self.focusedctrl.unfocus then
                    self.focusedctrl:unfocus(self.focusedctrl)
                end
            end
            self.focusedctrl = nil

            local data = {
                scroll = event == "mouse_scroll",
                button = button,
                X = x,
                Y = y
            }
            self.mouseclick:invoke(nil, data)
        end
    end,

	new = function(this)
        events:addHandler(this.Click, this._mouseClickHandler, this)
	end
}

---@diagnostic disable-next-line: undefined-global
return container;
