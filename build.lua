local root = "./PortOS"
local file = fs.open("./PortOS/out.ete","w")

local function scanFile(path, fil)
	if path == "./PortOS/.git" or path == "./PortOS/LICENSE" or path == "./PortOS/README.md" or path == "./PortOS/.gitignore" or path == "./PortOS/build.lua" or path == "./PortOS/Users" or path == "./PortOS/out.ete" then
		return
	end
	print("Discovered",path)
	if fs.isDir(path) then
		fil.write(path)
		local list = fs.list(path)
		if path == "./PortOS" then
			fil.write("\""..(#list - 7).."\"D")
		else
			fil.write("\""..(#list).."\"D")
		end
		
		for _,p in pairs(list) do
			scanFile(path.."/"..p, fil)
		end
	else
		local op = fs.open(path,"r")
		local data = op.readAll()
		op.close()
		fil.write(path)
		fil.write("\""..(#data).."\"F")
		fil.write(data)
	end
end


scanFile(root, file)
file.close()
