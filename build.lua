local root = "./PortOS"

local function loadConfigs()
    local files = fs.list(root .. "/.build_configs")
	
	local configs = {}

	local json_load_options = {
		["parse_empty_array"] = false
	}

    for _, name in pairs(files) do
		print("Discovered", name)
        local stream = fs.open(root .. "/.build_configs/" .. name, "r")
        local data = stream.readAll()
        stream.close()
        configs[name:sub(1,-6)] = textutils.unserialiseJSON(data, json_load_options)
    end
	
	return configs
end

local function createPackage(name, config)
    local package = {
        ["preset"] = config.preset or false,
        ["name"] = config.name,
        ["description"] = config.description,
        ["files"] = config.dependencies
    }
	table.insert(package.files, name)
    local data = textutils.serialise(package)
    local file = fs.open(root .. "/.out/update_packages/" .. name .. ".pkg", "w")
    file.write(data)
    file.close()
	print("Produced package data")
end

local function createETEInternal(path, dir, fil)
    --Fill out directory data

    local count = 0
    if dir["dir"] then
        count = count + #dir["dir"]
    end
    if dir["files"] then
        count = count + #dir["files"]
    end

    fil.write(path)                   --Name
    fil.write("\"" .. count .. "\"D") --Length and type

	if dir["dir"] then
 	    for dpath, data in pairs(dir["dir"]) do
            --Fill out subdirectories
			local path = path .. "/" .. dpath
			if fs.isDir(path) then
	        	createETEInternal(path, data, fil)
			else
				print("Directory \"",path,"\" was not found")
			end
	    end
	end

	if dir["files"] then
    	for _, fpath in pairs(dir["files"]) do
            --Fill out files
            local path = path .. "/" .. fpath
			if fs.exists(path) then
    	    	local op = fs.open(path, "r")
	        	local data = op.readAll()
	        	op.close()
        		fil.write(path)
        		fil.write("\"" .. (#data) .. "\"F")
                fil.write(data)
            else
				print("Path \"",path,"\" was not found")
			end
        end
	end
end
local function createETE(name, config)
	local file = fs.open(root.."/.out/bin/"..name..".ete", "w")
    createETEInternal(root, config.files, file)
    file.close()
	print("Produced ETE")
end

local pkgs = fs.list("PortOS/.out/update_packages")
for _,p in pairs(pkgs) do
	fs.delete("PortOS/.out/update_packages/"..p..".pkg")
end
local bins = fs.list("PortOS/.out/bin")
for _,p in pairs(bins) do
	fs.delete("PortOS/.out/bin"..p..".ete")
end

local configs = loadConfigs()
local names = {}

for name, data in pairs(configs) do
	print("\n-= Packaging",name,"=-")
    createPackage(name, data)
    createETE(name, data)
	
	table.insert(names, name)
end

local file = fs.open("PortOS/.out/update_packages/list.dat", "w")
file.write(textutils.serialise(names))
file.close()
