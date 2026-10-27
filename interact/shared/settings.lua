local BackEngineVehicles = {
    [`ninef`] = true,
    [`adder`] = true,
    [`vagner`] = true,
    [`t20`] = true,
    [`infernus`] = true,
    [`zentorno`] = true,
    [`reaper`] = true,
    [`comet2`] = true,
    [`comet3`] = true,
    [`jester`] = true,
    [`jester2`] = true,
    [`cheetah`] = true,
    [`cheetah2`] = true,
    [`prototipo`] = true,
    [`turismor`] = true,
    [`pfister811`] = true,
    [`ardent`] = true,
    [`nero`] = true,
    [`nero2`] = true,
    [`tempesta`] = true,
    [`vacca`] = true,
    [`bullet`] = true,
    [`osiris`] = true,
    [`entityxf`] = true,
    [`turismo2`] = true,
    [`fmj`] = true,
    [`re7b`] = true,
    [`tyrus`] = true,
    [`italigtb`] = true,
    [`penetrator`] = true,
    [`monroe`] = true,
    [`ninef2`] = true,
    [`stingergt`] = true,
    [`surfer`] = true,
    [`surfer2`] = true,
    [`gp1`] = true,
    [`autarch`] = true,
    [`tyrant`] = true
    }

    local function ToggleDoor(vehicle, door)
        if GetVehicleDoorLockStatus(vehicle) < 2 then
            if GetVehicleDoorAngleRatio(vehicle, door) > 0.0 then
                SetVehicleDoorShut(vehicle, door, false)
            else
                SetVehicleDoorOpen(vehicle, door, false)
            end
        end
    end

return {
    Debug = GetConvar('debug', 'false') == 'true' and true or false,
    Textures = {
        point = 'point',
        key = 'key',
        cap = 'cap',
        px = 'px',
        crosshair = 'crosshair',
        font = 'font',
    },
    Prompt = {
        key = 'E',
        uppercase = false,
        accent = { 255, 255, 255, 255 },
        textHeight = 0.0120,
        otherScale = 0.86,
        keySize = 0.0185,
        keyTextHeight = 0.0090,
        keyGap = 0.0070,
        pillPad = 0.0028,
        pillPadRight = 0.0055,
        pillRadius = 0.25,
        pillColor = { 255, 255, 255, 240 },
        keyColor = { 20, 22, 26, 255 },
        keyTextColor = { 255, 255, 255, 255 },
        selTextColor = { 20, 22, 26, 255 },
        textColor = { 255, 255, 255, 255 },
        dimmedAlpha = 230,
        outlineAlpha = 150,
        dotSize = 0.0105,
        crosshairSize = 0.0060,
        crosshair = true,
        hoverRadius = 0.06,
        rowSpacing = 0.0245,
    },
    Disable = {
        onDeath = true,
        onNuiFocus = true,
        onVehicle = true,
        onHandCuff = true,
    },

    nearbyObjectDistance = 20.0,
    nearbyVehicleDistance = 4.0,

    vehicleBoneDefaults = {
        enabled = false,
        bones = {
            ['boot']= {
                distance = 3.0,
                interactDst = 1.5,
                offset = vec3(0.0, 1.0, 0.0),
                options = {
                    {
                        name = 'interact:trunk',
                        label = 'Trunk',
                        action = function(entity)
                            ToggleDoor(entity, BackEngineVehicles[GetEntityModel(entity)] and 4 or 5)
                        end,
                    }
                },
            }
        }
    },
}
