local glamour = require(".PortOS.lib.glamour")
local explorer = require(".PortOS.lib.controls.explorer")
local button = require(".PortOS.lib.controls.button")
local textbox = require(".PortOS.lib.controls.textbox")
local label = require(".PortOS.lib.controls.label")
local rectangle = require(".PortOS.lib.controls.rectangle")
local app = require(".PortOS.lib.controls.application")

term.setCursorBlink(false)

local function checkFileOpeners()
    if registry.getFileHandler(".lua") == nil then
        registry.addFileHandler(".lua", "edit")
    end

    registry.save()
end

checkFileOpeners()
local myTextbox = new 'textbox'() {
    ShowBorder = true,
    Text = "/PortOS"
}
myTextbox.bounds {
    Top = 2,
    Height = 3,
    Width = 51
}

local myExplorer = new 'explorer'()
myExplorer.bounds {
    Width = 51,
    Height = 15,
    Top = 5
}

local myButton = new 'button'() {
    Text = "X",
    Background = colors.red,
    Foreground = colors.white
}
myButton.bounds {
    Left = 51,
    Top = 1,
    Width = 1,
    Height = 1
}

local btnBack = new 'button'() {
    Text = " <",
    Background = colors.gray,
    Foreground = colors.black
}
btnBack.bounds {
    Top = 1,
    Width = 2,
    Height = 1,
    Left = 1
}

local btnNext = new 'button'() {
    Text = "> ",
    Background = colors.gray,
    Foreground = colors.black
}
btnNext.bounds {
    Top = 1,
    Width = 2,
    Height = 1,
    Left = 4
}

local lblSep = new 'label'() {
    Text = "|",
    Background = colors.lightGray
}
lblSep.bounds {
    Top = 1,
    Left = 3,
    Width = 1
}

local rctBack = new 'rectangle'() {
    Background = colors.lightGray
}
rctBack.bounds {
    Top = 1,
    Left = 6,
    Width = 46,
    Height = 1
}

local lblTitle = new 'label'() {
    Text = "File Explorer",
    Background = colors.lightGray,
    Foreground = colors.black
}
lblTitle.bounds {
    Top = 1,
    Left = 7
}

local function onChangeDirectory(_, _, _, prev)
    myTextbox.Text = myExplorer.fileLocation
    myTextbox.updateGraphics = true
    btnBack.Background = #myExplorer.history > 0 and colors.lightGray or colors.gray
    btnBack.updateGraphics = true
    btnNext.Background = #myExplorer.future > 0 and colors.lightGray or colors.gray
    btnNext.updateGraphics = true
end
local function close()
    threading:stopThreadProcessor()
    Screen:stop()
end
local function navigate(_, _, key)
    if key == keys.enter then
        myExplorer:navigate(myTextbox.Text)
    end
end
local function back()
    myExplorer:navigateBack()
end
local function nxt()
    myExplorer:navigateNext()
end
local function handleFileOpen(_, _, file)
    myExplorer:openFile(file)
    print("guh")
    sleep(2)
end


events:addHandler(btnBack.Click, back)
events:addHandler(btnNext.Click, nxt)
events:addHandler(myTextbox.KeyPressed, navigate)
events:addHandler(myExplorer.changeDirectory, onChangeDirectory)
events:addHandler(myButton.Click, close)
events:addHandler(myExplorer.selectFile, handleFileOpen)
Screen = new 'app'()
Screen.Background = colors.white

Screen:addControl(myExplorer)
Screen:addControl(myTextbox)
Screen:addControl(btnBack)
Screen:addControl(btnNext)
Screen:addControl(lblSep)
Screen:addControl(rctBack)
Screen:addControl(myButton)

Screen:addControl(lblTitle)

Screen:run()
