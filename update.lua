--The installer is currently found at https://pastebin.com/tKT0MVub

--The branch to get from. Defaults to main. Use dev for nightly build
local branch = "main"

local args = { ... }
if #args >= 1 and (args[1]:lower() == "dev" or args[1]:lower() == "nightly" or args[1]:lower() == "beta") then
	branch = "dev"
end

-- Confirm required functions exist
if http == nil then
    print("HTTP is not enabled. Please edit the config, or contact your server admin if you wish to install!")
    return
end

local path = "https://raw.githubusercontent.com/FloralSoda/PortOS/"..branch.."/.out/update_packages/list.dat"
print("Downloading modules from github..")
local request = http.get(path)
if request == nil then
    print("Failed to get package data. Cannot install :(")
	print("Have you tried using the nightly build? (Run this with \"dev\" after it)")
	return
end
local list = request.readAll()
request.close()
print("Data retrieved")

local function makeDir(dir)
	local currentDir = ""
    for str in string.gmatch(dir, "([^" .. "/" .. "]+)") do
        currentDir = currentDir .. str
		fs.makeDir(currentDir)
    end
end

local function unpackETE(data)
	local pathFlag = true
	local fileLengthFlag = false
	local fileDataFlag = false
	local token = {}

	local path = ""
	local fileLength = 0
	local charactersRead = 0

	local typ = 0

	local file

	local len = #data
	for i = 1,len do
		local symbol = data:sub(i,i)
		if pathFlag then
			if symbol == "\"" then
				print(table.concat(token))
				path = table.concat(token, "")
				token = {}
				pathFlag = false
				fileLengthFlag = true
			else
				table.insert(token, symbol)
			end
		elseif fileLengthFlag then
			if symbol == "\"" then
                fileLength = tonumber(table.concat(token, "")) or -1
				if fileLength == -1 then
					error("ete file is corrupted or in a format the updater can't read. Please make sure you have the latest version of this file")
				end
				token = {}
				fileLengthFlag = false
				fileDataFlag = true
				typ = 0
			else
				table.insert(token, symbol)
			end
		elseif fileDataFlag then
			if typ == 0 then
				if symbol == "F" then
					typ = 1
					charactersRead = 0
                    print("Unpacking ", path)
					local fileCutoff = string.find(path, "/[^/]*$")
					makeDir(path:sub(1,fileCutoff))
					file = fs.open(path, "w")
				else
					print("Creating directory at", path)
					fs.makeDir(path)
					fileDataFlag = false
					pathFlag = true
				end
			elseif charactersRead == fileLength then
				file.close()
				fileDataFlag = false
				pathFlag = true
			else
				file.write(symbol)
				charactersRead = charactersRead + 1
			end
		end
	end
end

print("Getting package info")
local pkg_list = textutils.unserialise(list)
local pkgs = {}

for _, pkg in pairs(pkg_list) do
    local dlpath = "https://raw.githubusercontent.com/FloralSoda/PortOS/"..branch.."/.out/update_packages/" .. pkg .. ".pkg"
    print("Downloading info for:", pkg)
    local request = http.get(dlpath)
    local list = request.readAll()
    request.close()
    table.insert(pkgs, textutils.unserialise(list))
end
print("Successfully downloaded list")

local function menu(items, startY)
    local sidx = 1
    local windowOffset = 0

	local tx, ty = term.getSize()
	ty = ty - (startY - 1)

    local drawItem = function(item, number, selected, offset)
        local y = (number - offset) + startY
        if y < 1 or y > (ty + startY) then
            return --It's offscreen, no need to draw
        end

        term.setCursorPos(1, y)
        if selected then
            write("[ " .. item .. " ]")
        else
            write("  " .. item .. "  ")
        end
		local length = #item + 4
		write(string.rep(" ", tx - length))
    end
    local redraw = function()

    	for i = 1, #items do
        	drawItem(items[i], i, sidx == i, windowOffset)
    	end
	end

	redraw()

	while true do
        local _, key = os.pullEvent("key")

		local previous = sidx

        if key == keys.up then
            if sidx > 1 then
                sidx = sidx - 1
            end

            if sidx == windowOffset then
                windowOffset = windowOffset - 1
                redraw()
            end
        elseif key == keys.down then
            if sidx < #items then
                sidx = sidx + 1
            end

            if sidx > windowOffset + ty then
                windowOffset = windowOffset + 1
                redraw()
            end
        elseif key == keys.pageUp then
            windowOffset = math.max(windowOffset - ty, 0)
            redraw()
        elseif key == keys.pageDown then
            windowOffset = math.min(windowOffset + ty, #items)
            redraw()
        elseif key == keys.enter then
            return sidx, items[sidx]
        end
		
		drawItem(items[previous], previous, sidx == previous, windowOffset)
		drawItem(items[sidx], sidx, true, windowOffset)
	end
end

local function installPackage(pkg)
    term.clear()
	term.setCursorPos(1,1)
	for _,dep in pairs(pkg.files) do
		local dlpath = "https://raw.githubusercontent.com/FloralSoda/PortOS/"..branch.."/.out/bin/" .. dep .. ".ete"
    	print("Downloading data for:", pkg)
    	local request = http.get(dlpath)
        local ete = request.readAll()
		unpackETE(ete)
	end
end

local function compatMode()
	local choosePackage = function(pkg)
		term.clear()
		term.setCursorPos(1,1)
        print("Compatibility mode\n")
        print("Package Details:")
        print("Name:"..pkg.name)
        print("Requirements:")
        for _, dep in pairs(pkg.files) do
            print(" "..dep)
        end
        print("\n"..pkg.description)
        print("\nInstall?")

        local _, y = term.getCursorPos()
        local choice = menu({ "Yes", "No" }, y)
		
		return choice == 1
	end

	local listPackages = function(set, title)
        local names = {"Back"}
        for _, pkg in pairs(set) do
            table.insert(names, pkg.name)
        end

		while true do
        	term.clear()
			term.setCursorPos(1,1)
        	print("Compatibility mode\n")

            print("Select", title)
			print("---------------------\n")
		
            local sidx = menu(names, 3)
            if sidx == 1 then --User chose "Back"
                return false
            end
			
			local pkg = set[sidx - 1]
			if choosePackage(pkg) then
                installPackage(pkg)
				return pkg
			end
		end
	end

    local presets = function()
		local presets = {}
        for _, pkg in pairs(pkgs) do
            if pkg.preset then
                table.insert(presets, pkg)
            end
        end

		return listPackages(presets, "preset")
	end
	local custom = function()
        return listPackages(pkgs, "package")
	end

	while true do
        term.clear()
		term.setCursorPos(1,1)
    	print("Compatibility mode")

    	print("Select install")
    	print("---------------------\n")
    	local sidx = menu({
        	"Presets",
            "Custom",
			"Exit"
    	}, 3)

        if sidx == 1 then
			local pkg = presets()
            if pkg then
				installPackage(pkg)
                break
            end
        elseif sidx == 2 then
			local pkg = custom()
            if pkg then
				installPackage(pkg)
                break
            end
        elseif sidx == 3 then
			break
		end
	end
end
term.setTextColor(colors.white)
compatMode()

-- print("Loading UI")
-- local grayscaleConversion = {
-- 	[colors.white] = colors.white,
-- 	[colors.yellow] = colors.white,
-- 	[colors.lime] = colors.white,
-- 	[colors.lightBlue] = colors.lightGray,
-- 	[colors.orange] = colors.lightGray,
-- 	[colors.brown] = colors.gray,
-- 	[colors.green] = colors.gray,
-- 	[colors.red] = colors.gray,
-- 	[colors.black] = colors.black,
-- 	[colors.blue] = colors.gray,
-- 	[colors.purple] = colors.gray,
-- 	[colors.cyan] = colors.lightGray,
-- 	[colors.lightGray] = colors.lightGray,
-- 	[colors.gray] = colors.gray,
-- 	[colors.pink] = colors.lightGray,
-- 	[colors.magenta] = colors.gray,
-- }
-- local function toGrayscale(color)
-- 	return grayscaleConversion[color]
-- end
-- local function drawPixel(x,y,color)
-- 	if term.isColor() then
--         term.setCursorPos(x, y)
--         term.setBackgroundColor(color)
--         print(" ")
--     else
--         term.setCursorPos(x, y)
--         term.setBackgroundColor(toGrayscale(color))
-- 		print(" ")
-- 	end
-- end
-- local function drawBox(color)
	
-- end
