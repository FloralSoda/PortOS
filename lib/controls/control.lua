local rect = require ".PortOS.lib.data.rect"
class 'control' {
    bounds = new 'rect'(1, 1, 1, 1),
    Enabled = true,
    updateGraphics = true,
    Click = events:createEvent(),

    clickHandler = function(self, _, control, data)
        if control and control[".screenuuid"] == self[".screenuuid"] then
            print(typeof(control))
            self.Click:invoke(data)
        end
    end,
    destroy = function(self)
        events:removeHandler(self[".parentScreen"].mouseclick, self.clickHandler)
    end,
    bind = function(self, screen)
        self[".parentScreen"] = screen
        events:addHandler(self[".parentScreen"].mouseclick, self.clickHandler, self)
    end,
    new = function(this)
    end
}

return control
