local control = require(".PortOS.lib.controls.control")

class 'label' 'control' {
    Text = "Label",
    Background = colors.white,
    Foreground = colors.black,
    draw = function(self)
        paintutils.drawFilledBox(self.bounds.Left, self.bounds.Top, self.bounds.Left + self.bounds.Width - 1,
            self.bounds.Top + self.bounds.Height - 1, self.Background)

        term.setCursorPos(self.bounds.Left, self.bounds.Top)
        term.setTextColor(self.Foreground)
        write(self.Text)
    end,
    new = function(this, text)
        this {
            Text = text or this.Text
        }
        this.bounds {
            Width = #this.Text
        }
    end
}

return label
