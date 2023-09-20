local path = "https://raw.githubusercontent.com/FloralSoda/PortOS/main/out.ete"
print("Downloading from github..")
local ete = http.get(path)
print("Data retrieved")

function readETE(data)
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
				fileLength = tonumber(table.concat(token, ""))
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

print("Unpacking ETE file")
readETE(ete)
print("Successfully unpacked. Run PortOS/bin/boot.lua to execute")
