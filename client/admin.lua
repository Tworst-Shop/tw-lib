print('[tw-lib] client loaded — type twlib in F8 or /twlib in chat')

local open = false

local function ask(payload)
    TriggerServerEvent('tw-lib:server:menu', payload or { tab = 'overview' })
end

RegisterCommand('twlib', function()
    print('[tw-lib] /twlib pressed, asking the server')
    ask({ tab = 'overview' })
end, false)

pcall(RegisterKeyMapping, 'twlib', 'tw-lib ekonomi menusu', 'keyboard', '')

RegisterNetEvent('tw-lib:client:menu', function(data)
    if not open then
        open = true
        SetNuiFocus(true, true)
    end
    SendNuiMessage(json.encode({ action = 'twlib:menu', data = data }))
end)

RegisterNUICallback('twlib:menu:close', function(_, cb)
    open = false
    SetNuiFocus(false, false)
    SendNuiMessage(json.encode({ action = 'twlib:menu:close' }))
    cb('ok')
end)

RegisterNUICallback('twlib:menu:query', function(payload, cb)
    ask(payload)
    cb('ok')
end)

RegisterNUICallback('twlib:menu:setting', function(payload, cb)
    TriggerServerEvent('tw-lib:server:setting', payload)
    cb('ok')
end)

RegisterNUICallback('twlib:menu:action', function(payload, cb)
    TriggerServerEvent('tw-lib:server:action', payload)
    cb('ok')
end)

AddEventHandler('onClientResourceStop', function(res)
    if res == GetCurrentResourceName() and open then SetNuiFocus(false, false) end
end)
