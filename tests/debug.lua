local i = debug.getinfo

local get = coroutine.running

local function f()
    local t = get()
    return function()
        return i(t, 2, 'n'), function()
            return i(t, 2, 'n'), i(t,1,'n')
        end
    end
end

local f2 = f()

local info, f3 = f2()

p(info, f3())