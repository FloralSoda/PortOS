--The installer is currently found at https://pastebin.com/tKT0MVub

-- Confirm required functions exist
if http == nil then
    print("HTTP is not enabled. Please edit the config, or contact your server admin if you wish to install!")
    return
end

local path = "https://raw.githubusercontent.com/FloralSoda/PortOS/main/.out/update_packages/list.dat"
print("Downloading modules from github..")
local request = http.get(path)
local list = request.readAll()
request.close()
print("Data retrieved")

local function recursivelyMakeDir(dir)
    local cutoff = string.find(path, "/[^/]*$")
    if cutoff ~= nil then
        recursivelyMakeDir(dir:sub(1,cutoff))
    elseif fs.isDir(cutoff) then
		return
    end
	fs.makeDir(cutoff)
end

local function readETE(data)
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
					recursivelyMakeDir(path:sub(1,fileCutoff))
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
    local dlpath = "https://raw.githubusercontent.com/FloralSoda/PortOS/main/.out/update_packages/" .. pkg .. ".pkg"
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
        if y < 1 or y > ty then
            return --It's offscreen, no need to draw
        end

        term.setCursorPos(1, y)
        if selected then
            term.write("[ " .. item .. " ]")
        else
            term.write("  " .. item .. "  ")
        end
    end
    local redraw = function()
		term.clear()
    	for i = 1, #items do
        	drawItem(items[i], i, sidx == i, windowOffset)
    	end
	end

	redraw()

	while true do
        local event, key = os.pullEvent("key")

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
	end
end

local function installPackage(pkg)

end

local function compatMode()
	local choosePackage = function(pkg)
		term.clear()
		term.setCursorPos(1,1)
        print("Compatibility mode\n")
        print("Package Details:")
        print("Name:", pkg.name)
        print("Requirements:")
        for _, dep in pairs(pkg.files) do
            print(" ", dep)
        end
        print("\n", pkg.description)
        print("\nInstall?")

        local _, y = term.getCursorPos()
        local choice = menu({ "Yes, No" }, y)
		
		return choice == 1
	end

	local listPackages = function(set)
        local names = {"Back"}
        for _, pkg in pairs(set) do
            table.insert(names, pkg.name)
        end

		while true do
        	term.clear()
			term.setCursorPos(1,1)
        	print("Compatibility mode")

			print("Select preset")
		
            local sidx = menu(names, 3)
            if sidx == 1 then --User chose "Back"
                return false
            end
			
			local pkg = set[sidx - 1]
			if choosePackage(pkg) then
                installPackage(pkg)
				return true
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

		return listPackages(presets)
	end
	local custom = function()
        return listPackages(pkgs)
	end
	
	while true do
        term.clear()
		term.setCursorPos(1,1)
    	print("Compatibility mode")

    	print("Select install")
    	print("---------------------")
    	local sidx = menu({
        	"Presets",
			"Custom"
    	}, 3)

		if sidx == 1 then
            if presets() then
                break
            end
        elseif sidx == 2 then
			if custom() then
				break
			end
		end
	end
end

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
--         term.write(" ")
--     else
--         term.setCursorPos(x, y)
--         term.setBackgroundColor(toGrayscale(color))
-- 		term.write(" ")
-- 	end
-- end
-- local function drawBox(color)
	
-- end
