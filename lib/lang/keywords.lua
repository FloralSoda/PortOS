-- if classA:extends(classB) then..
--- Returns boolean indicating if the class contains the defined base class
---@param self table
---@param classB table
local extends = function(self, classB)
    if not type(classB) or not classB[".className"] then
        error("Second argument expected a class, got " .. type(classB), 2)
    end
    if table.find(self[".classBases"], classB[".className"]) then
        return true
    else
        return false
    end
end

local instanceMetatable = {
    __call = function(this, tbl)
        if type(tbl) ~= "table" or tbl[".className"] then
            error("Can only pull properties from tables", 2)
        else
            for k, v in pairs(tbl) do
                this[k] = v
            end
        end

        return this
    end
}

local function resolveConflicts(out, conflicts, source)
    local output = out
    for k, _ in pairs(conflicts) do
        output[k] = source[k]
    end

    return output
end
local function reinstanceTables(instance)
    for k, v in pairs(instance) do
        if type(v) == "table" and v[".PORTOS-STATIC_TBL"] == nil then
            instance[k] = table.shallowCopy(v)
            setmetatable(instance[k], getmetatable(v))
        end
    end
end
local function ctor(cl, env, ...)
    local instance = {}
    if cl[".classBases"] then
        for i, b in pairs(cl[".classBases"]) do
            local success, bInst = pcall(function()
                return new(b, env)()
            end)
            if not success then
                error("Error while constructing class " .. cl[".className"] .. ": Base Class " .. i .. " (" .. typeof(b) .. ") was invalid", 0)
            end
            local out, conflicts = table.merge(instance, bInst) -- Copy inheritance over, overriding previous values
            instance = resolveConflicts(out, conflicts, bInst)
        end
    end
    local n = cl[".new"](instance, cl, ...) -- Make new instance of this class, overriding inherited values

    return n
end

local buildClass = function(name, classDefinition, env)
    if classDefinition[".ctor"] or classDefinition[".className"] then
        error("Error while defining class " .. name .. ": Cannot stack class definitions", 0)
    end
    classDefinition[".className"] = name
    classDefinition[".ctor"] = function(cl, ...)
        return ctor(cl, env, ...)
    end
    classDefinition[".new"] = function(inheritance, cl, ...)
        local instance = table.shallowCopy(cl)
        instance[".ctor"] = nil
        instance[".new"] = nil
        instance["new"] = nil
        instance[".sourceClass"] = cl
        instance[".className"] = cl[".className"]
        instance["extends"] = extends
        instance[".instance"] = true

        local out, conflicts = table.merge(instance, inheritance)
        instance = resolveConflicts(out, conflicts, instance)
        
        
        local metatable = getmetatable(instance)
        if metatable then
            out, conflicts = table.merge(metatable, instanceMetatable)
            metatable = resolveConflicts(out, conflicts, metatable)
        else
            metatable = table.shallowCopy(instanceMetatable)
        end
        setmetatable(instance, metatable)

        reinstanceTables(instance)
        cl.new(instance, ...)

        return instance
    end

    env[name] = classDefinition
    return classDefinition
end

classDef = function(name, classDefinition, inheritance, env)
    inheritance = inheritance or {}

    if type(classDefinition) == "string" then
        return function(cl)
            table.insert(inheritance, classDefinition)
            return classDef(name, cl, inheritance, env)
        end
    elseif type(classDefinition) == "table" then
        if not classDefinition[".classBases"] then
            classDefinition[".classBases"] = {}
        end
        for _, v in pairs(inheritance) do
            table.insert(classDefinition[".classBases"], v)
        end
        return buildClass(name, classDefinition, env)
    else
        error("Error while defining class " .. name .. ": Expected string or table, received " .. type(classDefinition),
            0)
    end
end

-- class 'myClass' 'yourClass'.. { ... }
---Defines a class with a c#-like syntax
---@param name string
_G["class"] = function(name, env)
    local env = type(env) == "table" and env or getfenv(2)
    if env[name] then
        error(string.format("Class with name %q already exists", name), 2)
    end

    return function(cl)
        return classDef(name, cl, {}, env)
    end
end

--- Generates a new instance of the class
---@param cl string|table
---@param env? table
_G["new"] = function(cl, env)
    if type(cl) == "string" then
        env = env or getfenv(2)
        if type(env[cl]) == "table" and type(env[cl][".ctor"]) == "function" then
            def = env[cl]
            if type(env[cl].new) ~= "function" then
                error("Cannot instance a static class (no \"new\" function)", 2)
            end
            return function(...)
                return def[".ctor"](def,...)
            end
        else
            error(string.format("Object was not a class (received %s)", typeof(cl)), 2)
        end
    elseif type(cl) == "table" and type(cl[".ctor"]) == "function" then
        if type(cl.new) ~= "function" then
            error("Cannot instance a static class (no \"new\" function)", 2)
        end
        return function(...)
            return cl[".ctor"](cl,...)
        end
    else
        error(string.format("Object was not a class (received %s)", typeof(cl)), 2)
    end
end

--- Gets the type of the object
_G["typeof"] = function(a)
    if a and type(a) == "table" and type(a[".className"]) == "string" then
        if a[".instance"] then
            return a[".className"]
        else
            return "class"
        end
    end
    return type(a)
end

--- Marks a table to not be recreated when instancing a new object
_G["static"] = function(tbl)
    if type(tbl) == "table" then
        tbl[".PORTOS-STATIC_TBL"] = true
    else
        error("Static only runs on objects. Primitive types do not need to be marked static", 2)
    end
    return tbl
end

-- local r = require "cc.require"
-- local env = setmetatable({}, {
--     __index = _ENV
-- })
-- _G["import"] = r.make(env, "/")
