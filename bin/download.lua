local args = {...}

fs.makeDir("PortOS/Users/Global")
fs.makeDir("PortOS/Users/Global/Downloads")

local url = args[1]
if url then
    if http.checkURL(url) then
        local request = http.get(url)
        local data = request.readAll()
        request.close()
        local slash = url:reverse():find("%/")
        local name = url:sub(1-slash)
        local file = fs.open("PortOS/Users/Global/Downloads/"..name, "w")
        file.write(data)
        file.close()
    else
        error("Invalid URL")
    end
else
    error("Usage: download <URL>")
end
