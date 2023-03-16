local class = require 'class'
local enums = class.enums

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

local eclass = class 'VirtualReality'
eclass.__m = ''
eclass.name = eclass.__name

function eclass:set(t, v)
    self[t] = v
end

p(eclass)
print(eclass)

-- eclass.__tostring = {}
p(eclass.__tostring)

local obj = eclass()
-- obj.__private_value = 'able'
p(obj.__p)
obj:set('__p', 'able')
p(obj.__p)

p(obj)
print(obj)

p(getmetatable(obj))
--obj.soup = {}

-- p(obj.__m) --→ privated
p(obj.name)

local e = 01