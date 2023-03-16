-- local task = require 'task'

local format, sfind = string.format, string.find
local getinfo = debug.getinfo

-- argument errored
local badArg = 'bad argument #%d, for %s (%s expected got %s)'

-- miscellaneous formats
local className  = 'class → %s'
local objectName = 'object [%s]'
local classExists = 'class [%s] already exists and cannot be overwrited'

local attemptAccess = 'cannot access to private value %s.%s'
local attemptOverwrite = 'cannot overwrite protected value %s.%s'
local attemptWritePriv = 'cannot write to private value %s.%s *leak permission'

local classes = { }
local objects = { }

--- Get the number of key-pairs in the table `self`.
---@param self table
---@return number
local function getn(self)
    local type1 = type(self)
    if type1 ~= 'table' then
        return nil, format(badArg, 1, 'getn', 'table', type1)
    end

    local n = 0
    for _ in pairs(self) do
        n = n + 1
    end
    return n
end

--- Clones table `self` in to the optional `table`, if `self` has not items return a new empty new table.
---@param self table
---@param table table?
---@return table
local function clone(self, table)
    local type1, type2 = type(self), type(table)
    if type1 ~= 'table' then
        return nil, format(badArg, 1, 'clone', 'table', type1)
    end

    if getn(self) == 0 then
        return {}
    end

    table = type2 == 'table' and table or { }
    for index, value in pairs(self) do
        table[index] = value
    end

    return table
end

--- Counts the number of `value` that the table `self` has, but if not `value` passed return all the key-paris count.
---@param self table
---@param value any?
---@return number
local function count(self, value)
    local type1, type2 = type(self), type(value)
    if type1 ~= 'table' then
        return nil, format(badArg, 1, 'count', 'table', type1)
    end

    if type2 == 'nil' then
        return getn(self)
    end

    local n = 0
    for _, index in pairs(self) do
        n = ((index == value) and n + 1) or n
    end

    return n
end

--- Basic find of the value `prop` in to table `self`, compares `both key` and `pairs values`. <br>
--- If `value` is passed then tries to index `prop` on the `pairs`; this field is compared with the `value`. <br>
--- Returns the `index` at the possition of found and the corresponding `value`.
---@param self table
---@param prop any
---@param value any?
---@return any, any
local function find(self, prop, value)
    local type1, type2 = type(self), type(prop)
	if type1 ~= 'table' then
		return nil, format(badArg, 1, 'find', 'table', type1)
	elseif type2 == 'nil' then
		return nil, format(badArg, 2, 'find', 'any'  , type2)
	end

	for index, content in pairs(self) do
		if index == prop or content == prop then
            return index, content
		end

		if value then
			if type(content) == 'table' and content[prop] == value then
				return index, content
			elseif index == value and content == value then
				return index, content
			end
		end
	end

	return nil, nil
end


-- ::provitional::
local function isClass(object, strict)
    if not object then
        return nil -- not object provided
    end

    local class = classes[object]
    if strict == true or class then
        return class == true
    end

    local _, value = find(classes, object)
    return value == true
end

local function isObject(class)
    return class and objects[class] == true
end

local function scored(key)
    local type1 = type(key)
    if type1 ~= 'string' then
        return error(format(badArg, 1, 'scored', 'string', type1))
    end

    return sfind(key, '__', 1, true) == 1
end

local function associated(self, lvl)
    local fn = getinfo(lvl or 2, 'f').func

    return find(self, fn)
end

local function classAssociate(class, value)
    if not isClass(class) then
        return nil -- not a class provided
    end

    return (class:find(value) or associated(class, 3)) and true
end


--? reference
local function inherit()

end

local none = 'None'
local values = {
	Name = 'string',
	Value = 'number',
	RawType = 'string'
}

local enums = { }

local function enumClass()
	local pool = { }

    local function __pairs(_, index)
        local key, value = next(pool, index)
        if key and type(value) == 'function' then
            return __pairs(nil, key)
        end

        return key, value
    end

	function pool.Iter()
		return __pairs
	end

	return setmetatable({}, {
		__index = function(self, key)
			return pool[key]
		end,
		__newindex = function(self, key, value)
			local hash = self[key]
			if hash and tostring(hash) ~= none then
				return error('cannot overwrite enum value', 2)
			end

			local type1 = type(value)
			if hash and type1 ~= (values[key] or type1) then
				return error(format('bad type for enum \'%s\' (%s expected got type %s)', key, values[key], type1), 2)
			end

			pool[key] = value
		end,
		__tostring = function(self)
			return pool.Name or none
		end,
	})
end

local function enum(name, parent)
	if name and type(name) ~= 'string' then
		return nil
	end

	local enum = enumClass()
    enums[enum] = true

    function enum:IsParent(object)
        if not self.Parent then
            return nil
        end

        if self.Parent == object then
            return true
        end

        return enums[self.Parent] and self.Parent:IsParent(object)
    end

	function enum:IsEqualTo(value)
		if rawequal(self, value) then
			return true
		end

		for _, prop in self.Iter() do
			if prop == value then
				return true
			end
		end

		return false
	end

	for name in pairs(values) do
		enum[name] = enum[name] or enumClass()
	end

	enum.Name = name or none
	return enum
end

local setted = enum 'Setted'
setted.Value = 0
setted.RawType = 'SettedEnumValue'

local getted = enum 'Getted'
getted.Value = 1
getted.RawType = 'GettedEnumValue'

local classTypes = {
    enum 'Public',
    enum 'Private',
    enum 'Protected'
}

local function mixEnum(enum, types)
    local name = enum.Name
    name = (name:sub(1, 1):upper() .. name:sub(2))
    for _, rawEnum in pairs(types) do
        rawEnum.Value = enum.Value + 01
        rawEnum.Parent = enum
        enum[rawEnum.Name .. name] = rawEnum
    end

    return enum
end

local enumResponses = {
    setted = mixEnum(setted, classTypes),
    getted = mixEnum(getted, classTypes)
}

local onGet = enum 'OnGet'
local onSet = enum 'OnSet'
local onCall = enum 'OnCall'

local events = {
    get = onGet,
    set = onSet,
    call = onCall,
}

local n = 1
for _, enum in pairs(events) do
    enum.Value = n
    enum.RawType = enum.Name .. 'EnumValue'

    n = n + 1
end

return setmetatable({
    enum = enum, -- to create comparable enum's
    isEnum = function(obj) return enums[obj] == true end,
    enumClass = enumClass, -- the base to create an enumerated value.

    enums = enumResponses,
    events = events,

    find = find,
    getn = getn,
    clone = clone,
    count = count,

    isClass = isClass,
    isObject = isObject,
    classAssociate = classAssociate,
    getnOfClasses = function()
        return count(classes, true)
    end
}, {
    __metatable = {}, -- protected metamethods.

    __call = function(self, name, ...)
        local type1 = type(name)
        if type1 ~= 'string' then
            return error(format(badArg, 1, 'class', 'string', type1), 2)
        elseif #name == 0 then
            return error('provide a name with a length more than 0', 2)
        end

        if self.isClass(name) then
            return error(format(classExists, name), 2)
        end

        local roll = {}
        local dish = setmetatable({
            __name = name,
            __metatable = roll -- or meta
        }, {
            __index = self
        })

        local new = getinfo(1, 'f').func
        function dish.__new(name, ...)
            return new(self, name, ...)
        end

        -- function pool:__product(name)
        --     return self.__new(name, self)
        -- end

        local meta = {}
        meta.__metatable = roll

        local class = setmetatable({}, meta)
        class.__name = name

        classes[class] = true

        local function isAssociated(level)
            return associated(class, level + 1) or associated(meta, level + 1)
        end

        function meta:__call(...)
            local isInit, callEvent = not self.initialized, self[onCall or onCall.Name]
            if isInit == true and type(callEvent) == 'function' then
                return callEvent(self, ...)
            end

            -- if self.syncInit then
            if type(self.init) == 'function' then
                self:init(...)
            end
            -- end

            local object = setmetatable({}, clone(self, clone(meta)))

            objects[object] = true
            object.initialized = true

            return object
        end

        function meta:__tostring()
            local formatName = classes[self] and className or objects[self] and objectName
            return formatName and format(formatName, dish.__name or self.__name) or 'handle nil*'
        end

        function meta:__pairs()
            return function(_, index)
                return next(self, index)
            end
        end

        function meta:__index(key)
            local getEvent = class[onGet or onGet.Name]

            if not isObject(self) then
                return rawget(self, key)
            end
            -- if not isClass(self) then

            -- end

            -- if type(getEvent) == 'function' then
            --     local enumValue, value = getEvent(self, key)
            --     if enumValue:IsParent(getted) then
            --         if enumValue:IsEqualTo() then
                        
            --         end           
            --     elseif getted:IsEqualTo(enumValue) then
            --         return value
            --     end
            -- end

            local public = roll[key]
            if public then
                
                return public
            end

            local protected = dish[key] or class[key]
            if not protected then
                return nil
            end

            local isPriv = scored(key)
            local isMember = isAssociated(3)

            if isPriv and not isMember then
                ::attempt_access::
                return error(format(attemptAccess, dish.__name, key))
            end

            return protected
        end

        function meta:__newindex(key, value)
            if not isObject(self) then
                return rawset(self, key, value)
            end
            -- if not isClass(self) then

            -- end
            local isPriv = scored(key)

            if self[key] and not isPriv then
                return error(format(attemptOverwrite, tostring(self), key))
            end

            local isMember = isAssociated(3)
            if isPriv and not isMember then
                return error(format(attemptWritePriv, self.__name, key))
            end

            dish[key] = value
        end

        return class
    end
})