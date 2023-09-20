local control = require(".PortOS.lib.controls.control")

class 'rectangle' 'control' {
    Background = colors.lightGray,
    draw = function(self)
        paintutils.drawFilledBox(self.bounds.Left, self.bounds.Top, self.bounds.Left + self.bounds.Width - 1,
            self.bounds.Top + self.bounds.Height - 1, self.Background)
    end,
    new = function(this)
        this.bounds {
            Width = 8,
            Height = 3
        }

        return output
    end
}

return rectangle
