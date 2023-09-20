control = require(".PortOS.lib.controls.control")

class 'button' 'control' {
    Text = "Button",
    Background = colors.lightGray,
    Foreground = colors.black,
    PressedColor = colors.gray,

    draw = function(self)
        paintutils.drawFilledBox(self.bounds.Left, self.bounds.Top, self.bounds.Left + self.bounds.Width - 1,
            self.bounds.Top + self.bounds.Height - 1, self.Background)
        term.setTextColor(self.Foreground)
        local toWrite = self.Text
        if #self.Text > self.bounds.Width then
            local difference = #self.Text - self.bounds.Width
            toWrite = self.Text:sub(difference / 2, -(difference / 2))
        end
        term.setCursorPos(math.ceil(self.bounds.Left + ((self.bounds.Width - #self.Text) / 2)),
            math.ceil((self.bounds.Top - 1) + (self.bounds.Height / 2)))
        write(toWrite)
    end,

    new = function(this)
        this.bounds {
            Width = 8,
            Height = 3
        }
    end
}

return button
