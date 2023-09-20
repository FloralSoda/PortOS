local registry = {
	data = {
		fileHandlers = {}
	},
	defaultLocation = "/PortOS/bin/data/default.reg"
}

function registry.addFileHandler(type, programPath, force)
	if registry.data.fileHandlers[type] == nil or force then
		registry.data.fileHandlers[type] = programPath
		return true
	else
		return false
	end
end

function registry.getFileHandler(type)
	if registry.data.fileHandlers then
		return registry.data.fileHandlers[type]
	else
		return nil
	end
end

function registry.save()
	local file = fs.open(registry.defaultLocation, "w")
	file.write(textutils.serialise(registry.data))
	file.close()
end

function registry.load()
	if fs.exists(registry.defaultLocation) then
		local file = fs.open(registry.defaultLocation, "r")
		registry.data = textutils.unserialise(file.readAll())
		file.close()
	end
end

return registry