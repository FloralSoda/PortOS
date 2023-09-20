control = require(".PortOS.lib.controls.control")
class 'explorer' 'control' {
    NoFilesMessage = "There aren't any files here",
    selectedColor = colors.lightBlue,
    folderColor = colors.yellow,
    fileColor = colors.blue,
    background = colors.cyan,
    textColor = colors.black,
    border = colors.gray,
    scroll = 1,
    selected = -1,
    timetravel = false,

    sortDirectory = function(parent, fileList)
        if type(parent) ~= "string" then
            error("Parameter 1 'parent' expected type string, got "..typeof(parent), 2)
        elseif typeof(fileList) ~= "table" then
            error("Parameter 2 'fileList' expected type table, got "..typeof(fileList), 2)
        end

        local folders = {}
        local files = {}
        for _, file in pairs(fileList) do
            local name = parent .. "/" .. file
            if fs.isDir(name) then
                table.insert(folders, file)
            else
                table.insert(files, file)
            end
        end

        local output = {}
        for _, folder in pairs(folders) do
            table.insert(output, folder)
        end
        for _, file in pairs(files) do
            table.insert(output, file)
        end

        return output
    end,
    draw = function(self)
        if self.bounds.Width < 10 then
            self.bounds.Width = 10
        end
        if self.bounds.Height < 5 then
            self.bounds.Height = 5
        end

        paintutils.drawBox(self.bounds.Left, self.bounds.Top, self.bounds.Left + self.bounds.Width - 1,
            self.bounds.Top + self.bounds.Height - 1, self.border)
        paintutils.drawFilledBox(self.bounds.Left + 1, self.bounds.Top + 1, self.bounds.Left + self.bounds.Width - 2,
            self.bounds.Top + self.bounds.Height - 2, self.background)

        term.setTextColor(self.textColor)

        if fs.exists(self.fileLocation) and fs.isDir(self.fileLocation) then
            local files = explorer.sortDirectory(self.fileLocation, fs.list(self.fileLocation))

            local upper = math.min(self.scroll + self.bounds.Height - 3, #files)
            for idx = self.scroll, upper do
                local file = files[idx]
                local fileLoc = self.fileLocation .. "/" .. file

                paintutils.drawLine(self.bounds.Left + 1, self.bounds.Top + idx - (self.scroll - 1),
                    self.bounds.Left + self.bounds.Width - 2, self.bounds.Top + idx - (self.scroll - 1),
                    self.selected == idx and self.selectedColor or self.background)

                term.setCursorPos(self.bounds.Left + 1, self.bounds.Top + idx - (self.scroll - 1))
                local icon = fs.isDir(fileLoc) and "#" or "O"
                local iconColor = fs.isDir(fileLoc) and self.folderColor or self.fileColor

                write("-")
                term.setTextColor(iconColor)
                write(icon .. " ")
                term.setTextColor(self.textColor)
                if #file > self.bounds.Width - 6 then
                    write(file:sub(1, self.bounds.Width - 7) .. "..")
                else
                    write(file)
                end
            end
        else
            local noFiles = self.NoFilesMessage
            local lines = string.wrap(noFiles, self.bounds.Width - 2)
            for idx, line in pairs(lines) do
                term.setCursorPos(self.bounds.Left + 1, self.bounds.Top + idx)
                write(string.pad(line, self.bounds.Width - 2))
            end
        end
    end,
    navigate = function(self, location)
        if type(location) ~= "string" then
            error("Parameter 2 'location' expected type string, got "..typeof(location), 2)
        end

        if location and fs.exists(location) then
            if location == self.fileLocation then
                return false, "The explorer is already at this location"
            end
            if fs.isDir(location) then
                if self.timetravel then
                    self.timetravel = false
                else
                    table.insert(self.history, self.fileLocation)
                    self.future = {}
                end

                self.changeDirectory:invoke(self, location, self.fileLocation)
                self.fileLocation = location
                self.selected = -1
            else
                self.selectFile:invoke(self, location)
            end
            self.updateGraphics = true

            return true
        else
            return false, "The location could not be found"
        end
    end,
    navigateBack = function(self)
        if #self.history > 0 then
            self.timetravel = true
            local togo = self.history[#self.history]
            self.history[#self.history] = nil
            table.insert(self.future, self.fileLocation)
            return self:navigate(togo)
        end
    end,
    navigateNext = function(self)
        if #self.future > 0 then
            self.timetravel = true
            local togo = self.future[#self.future]
            self.future[#self.future] = nil
            table.insert(self.history, self.fileLocation)
            return self:navigate(togo)
        end
    end,
    click = function(self, _, data)
        local files = self.sortDirectory(self.fileLocation, fs.list(self.fileLocation))
        self.updateGraphics = true
        if data.scroll then
            if self.scroll + data.button > 0 and self.scroll + data.button < (#files - (self.bounds.Height - 4)) then
                self.scroll = self.scroll + data.button
            end
        elseif data.button == 1 then
            if data.Y == 1 or (2 + #files - self.scroll < data.Y) then
                self.selected = -1
                return
            elseif self.selected == self.scroll + data.Y - 2 then
                self:navigate(self.fileLocation .. (self.fileLocation[-1] == "/" and "" or "/") .. files[self.selected])
            else
                self.selected = self.scroll + data.Y - 2
            end
        end
    end,
    openFile = function(path)
        if path and fs.exists(path) then
            shell.run(registry.getFileHandler(path:sub(-4)), path)
            return true
        else
            return false, "Path could not be found"
        end
    end,
    new = function(this, default)

        this {
            fileLocation = default or "/PortOS",
            changeDirectory = events:createEvent(),
            selectFile = events:createEvent(),
            history = {},
            future = {},
            openFile = explorer.openFile
        }
        this.bounds {
            Top = 1,
            Left = 1,
            Width = 7,
            Height = 5
        }

        events:addHandler(this.Click, this.click, this)
    end
}

return explorer
