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
        local grabbed_dirs = {}
        local star = false

        for dpath, data in pairs(dir["dir"]) do
            --Fill out subdirectories
            local path = path .. "/" .. dpath
            if fs.isDir(path) then
                grabbed_dirs[dpath] = true
                createETEInternal(path, data, fil)
            elseif dpath == "*" then
                --Take all subdirectories from this directory
                star = true
                break --No need to process any more, since it's already asking for everything
            else
                print("Directory \"", path, "\" was not found")
            end
        end
        
        if star then
            local dirs = fs.list(path)
            for _, dpath in pairs(dirs) do
                if not grabbed_dirs[dpath] and fs.isDir(path .. "/" .. dpath) then
                    local synth_data = {
                        ["dir"] =  { "*" },
                        ["files"] = { "*" }
                    }
                    createETEInternal(path .. "/" .. dpath, synth_data, fil)
                end
            end
        end
	end

    if dir["files"] then
        local add_file = function(path, fil)
            local stream = fs.open(path, "r")
            local data = stream.readAll()
            stream.close()
            fil.write(path)
            fil.write("\"" .. (#data) .. "\"F")
            fil.write(data)
        end
        
        local grabbed_files = {}
        local star = false

        for _, fpath in pairs(dir["files"]) do
            --Fill out files
            local path = path .. "/" .. fpath
            if fs.exists(path) and not fs.isDir(path) then
                grabbed_files[fpath] = true
                add_file(path, fil)
            elseif fpath == "*" then
                --Take all files from this directory
                star = true
                break --No need to process any more, since it's already asking for everythings
            else
                print("Path \"", path, "\" was not found")
            end
        end
        
        if star then
            local files = fs.list(path)
            for _, fpath in pairs(files) do
                if not grabbed_files[fpath] and not fs.isDir(path .. "/" .. fpath) then
                    add_file(path .. "/" .. fpath, fil)
                end
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
