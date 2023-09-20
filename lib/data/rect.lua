class 'rect' {
    Left = 0,
    Top = 0,
    Width = 0,
    Height = 0,

    truncate = function(self)
        return new 'rect'(math.floor(self.Left), math.floor(self.Top), math.floor(self.Width), math.floor(self.Height))
    end,
    truncateMut = function(self)
        self.Left = math.floor(self.Left)
        self.Top = math.floor(self.Top)
        self.Width = math.floor(self.Width)
        self.Height = math.floor(self.Height)
    end,
    intersectsWith = function(self, rect)
        local l1x = self.Left
        local l1y = self.Top
        local r1x = self.Left + self.Width - 1
        local r1y = self.Top + self.Height - 1

        local l2x = rect.Left
        local l2y = rect.Top
        local r2x = rect.Left + rect.Width - 1
        local r2y = rect.Top + rect.Height - 1

        -- return (not (l1x > r2x or l2x > r1x)) and (not (r1y < l2y or r2y < l1y))
        return l1x <= r2x and l2x <= r1x and r1y >= l2y and r2y >= l1y
    end,

    new = function(this, Left, Top, Width, Height)
        if type(this) ~= "table" or this[".className"] ~= "rect" then
            error('Incorrect calling of constructor! Please use the syntax "new \'rect\'(left,top,width,height)', 2)
        end
        this {
            Left = Left or 0,
            Top = Top or 0,
            Width = Width or 0,
            Height = Height or 0
        }
    end
}

return rect
