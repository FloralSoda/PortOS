--This must not rely on PortOS systems as this is the fallback in case anything breaks.
local args = {...}

if #args > 1 then
	
end

--Not using actual root for the root directory. This is to keep PortOS
--self contained, in case users don't want the OS taking over the whole PC
local root = "./PortOS/root"

local running = true
local insert = false
local caretPosition = 1
local currentToken = {}
local posix = false

local function split_string(str)
	local output = {}
	for idx,char in pairs(str) do
		output[idx] = char
	end

	return output
end

local function parseArguments(arguments)
	local aliases = {
		["--dump-strings"] = "-d",
		["--verbose"] = "-v",
		["--init-file"] = "--rcfile"
	}

	local expect_args = {}
	local printHelp = false
	local dump_strings = false
	local options = true

	for _,arg in pairs(arguments) do
		if options then
			local current = aliases[arg] or arg
			local islong = current:sub(2,2) == "-"
			current = (islong and current:sub(3) or current:sub(1)):lower()
			if current == "help" then
				printHelp = true
			elseif current == "d" then
				dump_strings = true
			elseif current == "rcfile" then
				table.insert(expect_args, "rcfile")
			elseif not islong then
				for _,c in pairs(split_string(current)) do
					table.insert(arguments, "-"..c)
				end
			else --It's long and not a recognised argument above
				write("Unknown symbol \"--", current, "\"")
			end
		end
	end
end

local function parseCommand(command)
	command = command or currentToken

	for _,ch in pairs(command) do
		if ch == "#" then
			break
		end
	end
end

local function listenForInput()
	while running do
		local data = {os.pullEvent("key")}

		if data[2] == keys.enter or data[2] == keys.numPadEnter then
			parseCommand()
		elseif data[2] == keys.home then
			caretPosition = 1
		elseif data[2] == keys["end"] then
			caretPosition = #currentToken
		elseif data[2] == keys.insert then
			insert = not insert
		elseif data[2] == keys.delete and caretPosition < #currentToken then
			table.remove(currentToken, caretPosition + 1)
		elseif data[2] == keys.backspace and caretPosition > 1 then
			table.remove(currentToken, caretPosition)
			caretPosition = caretPosition - 1
		elseif data[2] == keys.left and caretPosition > 1 then
			caretPosition = caretPosition - 1
		elseif data[2] == keys.right and caretPosition < #currentToken then
			caretPosition = caretPosition + 1
		else
			local toAdd = keys.getName(data[2])
			if #toAdd == 1 then
				if insert then
					currentToken[caretPosition] = toAdd
				else
					table.insert(currentToken, toAdd, caretPosition)
				end
				caretPosition = caretPosition + 1
			end
		end
	end
end
