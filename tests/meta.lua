local tab = {}

local meta = {}

function meta:__call(...)
    p(...)
end

setmetatable(tab, meta)

tab 'h'