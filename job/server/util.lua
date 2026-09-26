function ExecuteSql(query, parameters)
    return MySQL.query.await(query, parameters or {})
end

function waitFor(cb, errMessage, timeout)
    local value = cb()
    if value ~= nil then return value end

    if timeout or timeout == nil then
        if type(timeout) ~= 'number' then timeout = 1000 end
    end

    local startTime = timeout and os.time()
    local elapsed = 0

    while value == nil do
        Citizen.Wait(100)

        if timeout then
            elapsed = os.time() - startTime
            if elapsed * 1000 > timeout then
                return error(('%s (waited %.1fms)'):format(errMessage or 'failed to resolve callback', elapsed * 1000), 2)
            end
        end

        value = cb()
    end

    return value
end

function JobHook(fn, ...)
    if type(fn) ~= 'function' then return true end
    local ok, result = pcall(fn, ...)
    if ok then return result end
    print(('^1[%s]^7 config hook failed: %s'):format(GetCurrentResourceName(), tostring(result)))
    return false
end
