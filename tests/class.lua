local class = require 'class'
local enums = class.enums
local events = class.events

-- p(enums.getted.Public)

-- local t = { 1, 1 , 1 ,2 }
-- local fn = function(i, n)
--     p(i, n)
--     return next(t, i)
-- end

-- for i, v in fn do
--     p(i,v)
-- end

-- local i = 0
-- for name, ind_enum in enums.setted.Iter() do
--     p(name)
--     i = i + 1
--     if i == 10 then
--         os.exit()
--     end
-- end

-- local n, n1 = 0, 2
-- for name, enum in pairs(class.enums) do
--     for index, subenum in enum:SubEnums() do
--         -- if n == n1 then
--         --     break
--         -- end
--         p(name, index, subenum)

--         n=n+1
--     end
-- end

-- p(class)
-- p(class.getnOfClasses())

-- local m = {}
-- print(class.clone(m), m)

-- m.m = m
-- local c = class.clone(m)
-- print(c, m.m, m)

-- print(class.count(m), class.count(m, m.m), class.count(m, true)) -- 1, 1, 0

-- print(class.find(m))
-- print(class.find(m, m))
-- print(class.find(m, 'm', m))

-- local eclass = class 'VirtualReality'
-- eclass.__m = ''
-- eclass.name = eclass.__name

-- function eclass:set(t, v)
--     self[t] = v
-- end

-- p(eclass)
-- print(eclass)

class 't-class'; -- class 't-class' overloaded

-- -- eclass.__tostring = {}
-- p(eclass.__tostring)

-- local obj = eclass()
-- -- obj.__private_value = 'able'
-- p(obj.__p)
-- obj:set('__p', 'able')
-- p(obj.__p)

-- p(obj)
-- print(obj)

-- p(getmetatable(obj))
-- --obj.soup = {}

-- -- p(obj.__m) --→ privated
-- p(obj.name)

-- local e = 01

local new = class 'new'
local getters = {}
local setters = {}

function getters.normal(self)
    return self.__normal
end

-- those wont fail 'cause come from `events.set`
function setters.normal(self, v)
    self.__normal = v
    p(self.__normal, '-')
end

function setters.embeddable(self, v)
    self.__embeddable = v == true
    p(self.__embeddable)
end

function new:init(...)
    p('[init]', ...)
end

new[events.get] = function(self, k)
    if getters[k] then
        return enums.getted, getters[k](self)
    end
end

new[events.set] = function(self, k, v)
    if setters[k] then
        return enums.setted, setters[k](self, v)
    end
end

new[events.call] = function(self, ...)
    p(...)

    local b = {...}
    p(b[1] == 'parent')
    if b[1] == 'parent' then
        self.__parent = b[2]
        self.parent 'parent'
    end
end

local obj = new 'first call'
obj 'last called'
obj 'one more time called'

local getParent = obj.parent
p(getParent(), getParent '', '---')

obj('parent', 1)

p(getParent())

p '------'
obj.normal = 'ENUM_NORMAL'
p(obj.normal, new.__normal)

obj.embeddable = true

for k, v in obj:__iter {--[[  meta = true, roll = true, ]] protected = true } do
    p(k,v)
end

p(obj:find(true, { protected = true }, 'parent'))

local prod = obj:__product 'product'

local prod_obj = prod 'init product'
p(prod_obj.parent()) -- nil

p(prod, prod_obj)

p(prod_obj.normal)
