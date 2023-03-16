local test = {
    'test',
    'test',
    test0 = 0,
    test2 = 2,
}

local task = require 'task'

do
    ::continue::
    for i, v in pairs(test) do
        if type(i) == 'string' and i == 'test0' then
            -- goto continue
        end
        -- p(i, v)
    end
end


do
    for i, v in pairs(test) do
        if type(i) == 'string' and i == 'test0' then
            goto continue
        end
        p(i, v)

        ::continue::
    end
end

-- local function wrap(fn)
--     local ryield
--     local yield = function()
--         ryield()
--     end
--     local t = coroutine.create(function()
--         ryield = function()
--             coroutine.yield()
--         end

--         return fn()
--     end)

--     return t, yield
-- end

-- local function c(e)
--     local function continue(self, yield)
--         return function()
--             yield()
--             self.index = pairs()
--         end
--     end
--     local self = setmetatable({}, {
--         __call = function(self, fn)
--             local t, yield = wrap(fn)
--             setfenv(fn, {
--                 pairs = function(t)
--                     return function()
--                         local i, v = next(t, self.index)
--                         self.index = i
--                         p(i,v)
--                         return i,v
--                     end
--                 end,
--                 continue = continue(self, yield)
--             })

--             local s, d = coroutine.resume(t)
--             return s, d
--         end
--     })

--     return self
-- end


--     local t =c(test)
--     p(t(function()
--         for i,v in pairs(test) do
--             if i~= 'test0' then
--                 continue()
--             end

--             p(i,v, '---')
--         end
--     end))

local able = coroutine.isyieldable
local wrap, yield, running, status = coroutine.wrap, coroutine.yield, coroutine.running, coroutine.status
local function wrapContinue(fn, ...)
    local base = {...}
    local thread = running()

    local tab, continueIndex, currentIndex
    local env = {}

    env.pairs = function(table)
        tab = table
        return wrap(function(t, index)
            index = continueIndex or index
            continueIndex = nil

            local key, value = next(table, index)
            currentIndex = key
            yield( key, value )
        end), table, nil
    end

    local value
    env.continue = function()
        continueIndex = env.pairs(tab)(nil, currentIndex)
        task.delay(10, function(...)
            value = { fn(...) }

            if status(thread) == 'suspended' then
                local success, d = coroutine.resume(thread)
                if not success then
                    return error(debug.traceback(thread, d), 2)
                end
            end
        end, unpack(base))

        -- da error porque
        if able() == true then
            yield()
        end
    end

    setfenv(fn, setmetatable(env, { __index = _G }))

    value = value or { fn(...) }

    return value
end

local value = wrapContinue(function()
    for i, v in pairs(test) do
        if i ~= 'test0' then
            print('continuing', i)
            continue()
        end

        p(i)
        return i, v
    end
end)

p(value)