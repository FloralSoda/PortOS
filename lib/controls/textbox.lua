control = require(".PortOS.lib.controls.control")

class 'textbox' 'control' {
    Text = "",
    CaretPosition = 1,
    PortalPosition = 1,
    Background = colors.white,
    CaretColour = colors.lightBlue,
    Foreground = colors.black,
    BorderColour = colors.lightGray,
    CaretBlinkSpeed = 1,
    ShowBorder = true,
    ShowCaret = false,
    MultiLine = false,
    blinkThreadId = -1,

    draw = function(self)
        if self.Enabled then
            local textX = self.ShowBorder and self.bounds.Left + 1 or self.bounds.Left
            local textY = self.ShowBorder and self.bounds.Top + 1 or self.bounds.Top

            if self.ShowBorder then
                paintutils.drawBox(self.bounds.Left, self.bounds.Top, self.bounds.Left + self.bounds.Width - 1,
                    self.bounds.Top + self.bounds.Height - 1, self.BorderColour)
            end

            paintutils.drawLine(textX, textY, textX + self:getWriteableWidth() - 1, textY, self.Background)

            if self.ShowCaret and (os.epoch() - self[".cursorBlinkTimer"]) >= (1 / self.CaretBlinkSpeed) * 1000 then
                self[".cursorBlinkTimer"] = os.epoch()
                if self[".cursorBlinkShow"] then
                    self[".cursorBlinkShow"] = false
                else
                    self[".cursorBlinkShow"] = true
                end
            end

            if #self.Text > 0 then

                term.setCursorPos(textX, textY)

                local drawableText = self.Text:sub(self.PortalPosition)
                if #drawableText > self:getWriteableWidth() then
                    drawableText = drawableText:sub(1, -(#drawableText - self:getWriteableWidth() + 1))
                end

                term.setTextColour(self.Foreground)
                if self.ShowCaret and self[".cursorBlinkShow"] then
                    if self.CaretPosition > #self.Text then
                        term.setBackgroundColour(self.Background)
                        term.write(drawableText)
                        term.setBackgroundColor(self.CaretColour)
                        term.write(" ")
                    else
                        local pos = (self.CaretPosition - self.PortalPosition) + 1

                        if pos > 1 then
                            term.setBackgroundColour(self.Background)
                            term.write(drawableText:sub(1, pos - 1))
                        end

                        term.setBackgroundColour(self.CaretColour)
                        term.write(drawableText:sub(pos, pos))

                        if pos < #drawableText then
                            term.setBackgroundColour(self.Background)
                            term.write(drawableText:sub(pos + 1))
                        end
                    end
                else
                    write(drawableText)
                end
            else
                if self.ShowCaret and self[".cursorBlinkShow"] then
                    term.setCursorPos(textX, textY)
                    term.setBackgroundColour(self.CaretColour)
                    term.write(" ")
                end
            end
        end
    end,
    unfocus = function(self)
        events:removeHandler("key", self.keyDown)
        events:removeHandler("char", self.charDown)
        self.ShowCaret = false
        self.updateGraphics = true
        threading:killThread(self.blinkThreadId)
    end,
    click = function(self, _, data)
        events:addHandler("key", self.keyDown, self)
        events:addHandler("char", self.charDown, self)
        if not self.ShowCaret then
            self.blinkThreadId = threading:startTimer(0.3 / self.CaretBlinkSpeed, function()
                self.updateGraphics = true
            end)
        end
        self.ShowCaret = true

        local x = data.X
        local y = data.Y
        if self.ShowBorder then
            if y > 1 and y < self.bounds.Height and x > 1 and x < self.bounds.Width then
                if x < #self.Text + 1 then
                    self:setCaretPosition(x + self.PortalPosition - 2)
                else
                    self:setCaretPosition(#self.Text + 1)
                end
            end
        else
            if x < #self.Text + 1 then
                self:setCaretPosition(x + self.PortalPosition - 1)
            else
                self:setCaretPosition(#self.Text + 1)
            end
        end
    end,
    keyDown = function(self, _, key)
        if key == keys.left then
            if self.CaretPosition > 1 then
                self:setCaretPosition(self.CaretPosition - 1)
                self.updateGraphics = true
            end
        elseif key == keys.right then
            if self.CaretPosition < #self.Text + 1 then
                self:setCaretPosition(self.CaretPosition + 1)
                self.updateGraphics = true
            end
        elseif key == keys.backspace then
            if #self.Text > 0 then
                if self.CaretPosition == #self.Text + 1 then
                    if #self.Text == 1 then
                        self.Text = ""
                    else
                        self.Text = self.Text:sub(1, -2)
                    end
                    self:setCaretPosition(self.CaretPosition - 1)
                    self.updateGraphics = true
                elseif self.CaretPosition == 1 then
                    return
                else
                    self.Text = self.Text:sub(1, self.CaretPosition - 2) .. self.Text:sub(self.CaretPosition)
                    self:setCaretPosition(self.CaretPosition - 1)
                    self.updateGraphics = true
                end
            end
        elseif key == keys.delete then
            if self.CaretPosition == #self.Text + 1 then
                return
            elseif self.CaretPosition == 1 then
                self.Text = self.Text:sub(2)
                self.updateGraphics = true
            else
                self.Text = self.Text:sub(1, self.CaretPosition - 1) .. self.Text:sub(self.CaretPosition + 1)
                self.updateGraphics = true
            end
        end
        self.KeyPressed:invoke(self, key)
    end,
    charDown = function(self, _, char)
        self.updateGraphics = true
        if self.CaretPosition == #self.Text + 1 then
            self.Text = self.Text .. char
        elseif self.CaretPosition == 1 then
            self.Text = char .. self.Text
        else
            self.Text = self.Text:sub(1, self.CaretPosition - 1) .. char .. self.Text:sub(self.CaretPosition)
        end

        if self.CaretPosition < #self.Text + 1 then
            self:setCaretPosition(self.CaretPosition + 1)
        end
    end,
    setText = function(self, text)
        self.Text = text
        self:setCaretPosition(1)
    end,
    getWriteableWidth = function(self)
        return self.ShowBorder and (self.bounds.Width - 2) or self.bounds.Width
    end,
    setCaretPosition = function(self, index, snapToLeft)
        if index > #self.Text + 1 then
            error("Index was greater than the length of the Textbox contents (" .. index .. " > " ..
                      tostring(#self.Text + 1) .. ")", 2)
        else
            self.CaretPosition = index
            if snapToLeft then
                if self.CaretPosition > self.PortalPosition + 2 then
                    self.PortalPosition = self.CaretPosition - 2
                end
            else
                if self.CaretPosition >= self.PortalPosition + self:getWriteableWidth() then
                    self.PortalPosition = math.max(index - (self:getWriteableWidth() - 2), 1)
                end
            end

            if self.CaretPosition < self.PortalPosition then
                self.PortalPosition = math.max(index - 2, 1)
            end

        end
    end,
    destroy = function(self)
        control.destroy(self)
        events:removeHandler("key", self.keyDown)
        events:removeHandler("char", self.charDown)
        events:deleteEvent(self.KeyPressed)
        if self.blinkThreadId ~= -1 then
            threading:killThread(self.blinkThreadId)
        end
    end,
    new = function(this)
        this {
            KeyPressed = events:createEvent(),
            [".cursorBlinkTimer"] = 0,
            [".cursorBlinkShow"] = false
        }
        
        this.bounds {
            Top = 1,
            Left = 1,
            Width = 10,
            Height = 3
        }
    end
}

return textbox
