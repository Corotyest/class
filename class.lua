-- local task = require 'task'

local format, sfind = string.format, string.find
local getinfo = debug.getinfo

-- argument errored
local badArg = 'bad argument #%d, for %s (%s expected got %s)'

-- miscellaneous formats
local className  = 'class → %s'
local objectName = 'object [%s]'
local classExists = 'class [%s] already exists and cannot be overwrited'
local unavailableName = 'handle nil*'

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

--- Clones table `self` in to the optional `table`, if `self` has not items return a new empty table.
---@param self table
---@param table? table
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
---@param value? any
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
---@param value? any
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

--- Searches for the `object` if it is in the registered `classes`, and return boolean. <br>
--- If you specify the second `strict` argument, it'll only search on the classes by the index.
---@param object any
---@param strict? boolean
---@return boolean | nil
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

--- Searches fo the `class` if it is in the registered `objects` and return boolean.
---@param class any
---@return boolean
local function isObject(class)
    return class and objects[class] == true
end

--- Verify if the string `key` starts by underscores that could be a `method` or `private propertie`.
---@param key string
---@return true | nil
local function scored(key)
    local type1 = type(key)
    if type1 ~= 'string' then
        return error(format(badArg, 1, 'scored', 'string', type1))
    end

    return sfind(key, '__', 1, true) == 1 or nil
end

--- If the current `lvl`; level function is a associate of the table `self`.
---@param self table
---@param lvl? number
---@return any
local function associated(self, lvl)
    local fn = getinfo(lvl or 2, 'f')

    return fn and find(self, fn.func)
end

--- If the givened argument `value` or the current function is a member of the `class`; return true.
---@param class Class
---@param value any
---@return true | nil
local function classAssociate(class, value)
    if not isClass(class) then
        return nil -- not a class provided
    end

    return (class:find(value) or associated(class, 3)) and true
end


--? reference
local function inherit()

end

---*→ These variables are for the construction of Enumerated Values ←---

---@alias None 'None'
local none = 'None'
local values = {
	Name = 'string',
	Value = 'number',
	RawType = 'string',
    Parent = 'table',
}

---@class EnumClass
---@field Iter fun(): fun(self, index: any?): any, any
---@field Name string | None
---@field Value number | None
---@field Parent Enum | None
---@field RawType string | None

--- This is the allocation of the Enumerated Values
local enums = { }

--- This functions creates a new very simple super-class that manage an Enumerated Value or `EnumClass`.
---@return EnumClass
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
        __eq = function(self, value)
            for name, rawtype in pairs(values) do
                if type(value) ~= rawtype then
                    goto continue
                end

                if self[name] == value then
                    return true
                end

                ::continue::
            end

            return false
        end,
		__index = function(self, key)
			return pool[key]
		end,
		__newindex = function(self, key, value)
			local hash = self[key]
			if hash and tostring(hash) ~= none then
                if hash == value then
                    return nil
                end
				return error('cannot overwrite enum value', 2)
            elseif value == none then
                return nil
			end

			local type1 = type(value)
			if hash and type1 ~= (values[key] or type1) then
				return error(format('bad type for propertie \'%s\' (%s expected got type %s)', key, values[key], type1), 2)
			end

			pool[key] = value
		end,
		__tostring = function(self)
			return pool.Name or none
		end,
	})
end


---@class Enum: EnumClass
---@field SubEnums fun(self: Enum): fun(self: Enum, index: any?), Enum, nil
---@field IsParent fun(self: Enum, object: any): true | nil
---@field IsEqualTo fun(self: Enum, value: any): boolean


--- This function constructs over the super-class of Enumerated Value's that the `classEnum` returns. <br>
--- Adds the `Name` to the `Enum` value, various helper functions and return the `Enum`.
---@param name string
---@param parent? Enum
---@return Enum
local function enum(name, parent)
	if name and type(name) ~= 'string' then
		return nil
	end

    local Class = enumClass()

    ---@type Enum
    local Enum = setmetatable({}, getmetatable(Class))
    Enum.Parent = parent or none
    enums[Enum] = true

    local function subenums(self, index)
        local key, value = self.Iter()(nil, index)
        if key and not isEnum(value) then
            return subenums(self, key)
        end

        return key, value
    end

    function Enum:SubEnums()
        return subenums, self, nil
    end

    function Enum:IsParent(object)
        local parent = self.Parent
        if not parent then
            return nil
        end

        if parent == object then
            return true
        end

        return isEnum(parent) and parent:IsParent(object)
    end

	function Enum:IsEqualTo(value)
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
		Enum[name] = Enum[name] or none -- enumClass()
	end

	Enum.Name = name or none
	return Enum
end

--- Searches for the `enum` value in the registered `enums` table, returns boolean.
---@param enum any
---@return boolean
function isEnum(enum)
    return type(enum) == 'table' and enums[enum] == true
end


local setted = enum 'Setted'
setted.Value = 0
setted.RawType = 'SettedEnumValue'

local getted = enum 'Getted'
getted.Value = 1
getted.RawType = 'GettedEnumValue'

local responseType = {
    Public = {
        Value = 2,
        RawType = 'Public: %s'
    },
    Private = {
        Value = 3,
        RawType = 'Private: %s'
    },
    Protected = {
        Value = 4,
        RawType = 'Protected: %s'
    }
}

local enumResponses = {
    setted = setted,
    getted = getted
}

do -- configurate raturn types
    for _, enumres in pairs(enumResponses) do
        for rawType, options in pairs(responseType) do
            local raw = options.RawType
            options.RawType = format(raw, enumres.Name)

            local enumType = enum(rawType, enumres)
            enumres[rawType] = enumType
        end
    end
end


local get = enum 'OnGet'
local set = enum 'OnSet'
local call = enum 'OnCall'

set.Value = 10
get.Value = 20
call.Value = 30

local events = {
    get = get,
    set = set,
    call = call,
}

return setmetatable({
    enum = enum, -- to create comparable enum's
    isEnum = isEnum,
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
            local isInit, callEvent = self.initialized, self[call]
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
            return formatName and format(formatName, dish.__name or self.__name) or unavailableName
        end

        function meta:__pairs()
            return function(_, index)
                return next(self, index)
            end
        end

        function meta:__index(key)
            local getEvent = class[get]

            if not isObject(self) then
                return rawget(self, key)
            end
            -- if not isClass(self) then

            -- end

            if type(getEvent) == 'function' then
                local enum, value = getEvent(self, key)
                if not isEnum(enum) then
                    return nil
                end

                ---@type Enum
                enum = enum
                if enum:IsEqualTo(getted) then
                    return value
                elseif enum:IsParent(getted) then
                    -- redirect to the attempt_access label, so it will throw the error directly.
                    if enum:IsEqualTo(getted.Private) then
                        isPriv = true
                        goto attempt_access
                        -- elseif enum:IsEqualTo(setted.Public) then
                        -- elseif enum:IsEqualTo(setted.Protected) then
                    end
                end
            end

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

            ::attempt_access::
            if isPriv and not isMember then
                return error(format(attemptAccess, dish.__name, key))
            end

            return protected
        end

        function meta:__newindex(key, value)
            local setEvent = self[set]

            if not isObject(self) then
                return rawset(self, key, value)
            end
            -- if not isClass(self) then

            -- end

            if type(setEvent) == 'function' then
                local enum, value = setEvent(self, key)
                if not isEnum(enum) then
                    return nil
                end

                ---@type Enum
                enum = enum
                if enum:IsEqualTo(setted) then
                    return value
                elseif enum:IsParent(setted) then
                    -- redirect to the attempt_access label, so it will throw the error directly.
                    if enum:IsEqualTo(setted.Private) then
                        isPriv = true
                        goto attempt_access
                    -- elseif enum:IsEqualTo(setted.Public) then
                    -- elseif enum:IsEqualTo(setted.Protected) then
                    end
                end
            end

            local isPriv = scored(key)

            if self[key] and not isPriv then
                return error(format(attemptOverwrite, tostring(self), key))
            end

            local isMember = isAssociated(3)

            ::attempt_access::
            if isPriv and not isMember then
                return error(format(attemptWritePriv, self.__name, key))
            end

            dish[key] = value
        end

        local iterOptions = {
            meta = meta,
            public = roll,
            protected = dish,
        }

        function class:__iter(options)
            local type1, type2 = type(self), type(options)
            if type1 ~= 'table' then
                return error(format(badArg, 'self', '__iter', 'table', type1), 2)
            end


            local pool = clone(self)

            if type2 == 'table' then
                for name in next, options do
                    local option = iterOptions[name]
                    if option then
                        clone(option, pool)
                    end
                end
            elseif options == 'string' then
                local option = iterOptions[options]
                if options then
                    clone(option, pool)
                end
            elseif options == 'boolean' and options == true then
                clone(iterOptions.protected, pool)
            end

            return function(_, index)
                return next(pool, index)
            end
        end

        return class
    end
})