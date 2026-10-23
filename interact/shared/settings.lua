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
    Debug = GetConvar('debug', 'false') == 'true' and true or false, -- Enable / Disable debug mode
    -- Runtime TXD 'twlib_interact' (tw-lib/client/interact_txd.lua yaratir, bu kaynak cizer). Dosyalar assets/prompt.
    Textures = {
        point = 'point',          -- etkilesim noktasi: kucuk dolu beyaz nokta (halka yok)
        key = 'key',              -- yuvarlatilmis kare tus rozeti
        cap = 'cap',              -- secili satir kapsulunun yuvarlak koseli ucu (sag uc 180 derece dondurulur)
        px = 'px',                -- duz blok: kapsul ortasi
        crosshair = 'crosshair',  -- ekran ortasi: kucuk elmas
        font = 'font',            -- Gilroy SemiBold atlasi (tools/interact_font.py)
    },
    -- TWORST GORUNUMU (Yusuf 2026-10-06, secenek B): secili satir BEYAZ kapsul icinde koyu tus rozeti + koyu yazi;
    -- digerleri zeminsiz, kucuk beyaz yazi, koyu kenar (her zeminde okunur). Gilroy, normal yazim. Mantik / tuslar
    -- ilv-interact ile ayni. Boyutlar ekran yuksekliginin kesri (1080p px / 1080).
    Prompt = {
        key = 'E',                -- rozetteki harf (kontrol INPUT_PICKUP / 38)
        uppercase = false,        -- true: Turkce harfler de buyur (utils.lua upper)
        accent = { 255, 255, 255, 255 },     -- nokta rengi
        textHeight = 0.0120,      -- secili etiket buyuk harf yuksekligi (~13 px)
        otherScale = 0.86,        -- secili olmayan satirlarin yazi olcegi
        keySize = 0.0185,         -- tus rozeti (~20 px)
        keyTextHeight = 0.0090,
        keyGap = 0.0070,          -- rozet ile etiket arasi
        pillPad = 0.0028,         -- kapsul ic boslugu, dikey (rozetin cevresi)
        pillPadRight = 0.0055,    -- yazidan sonra sag bosluk
        pillRadius = 0.25,        -- kapsul kose yaricapi / kapsul yuksekligi (0.5 = tam yuvarlak)
        pillColor = { 255, 255, 255, 240 },  -- secili satir kapsulu
        keyColor = { 20, 22, 26, 255 },      -- rozet
        keyTextColor = { 255, 255, 255, 255 },
        selTextColor = { 20, 22, 26, 255 },  -- secili etiket (beyaz kapsul ustunde)
        textColor = { 255, 255, 255, 255 },  -- diger etiketler
        dimmedAlpha = 230,        -- diger etiketlerin opakligi
        outlineAlpha = 150,       -- diger etiketlerin koyu kenari (4 yon, 1 px); 0 = yok
        dotSize = 0.0105,         -- nokta (~11 px)
        crosshairSize = 0.0060,
        crosshair = true,
        hoverRadius = 0.06,       -- nokta secimi icin ekran ortasina yakinlik
        rowSpacing = 0.0245,
    },
    Disable = {
        onDeath = true, -- Disable interactions on death
        onNuiFocus = true, -- Disable interactions while NUI is focused
        onVehicle = true, -- Disable interactions while in a vehicle
        onHandCuff = true, -- Disable interactions while handcuffed
    },

    -- Nearby object distance check.
    nearbyObjectDistance = 20.0, -- Keep it at 15.0 at minimum.
    nearbyVehicleDistance = 4.0,

    -- KAPALI. Acikken yakindaki HER aracin bagajina "Trunk"
    -- istemi ekliyordu (burger isiyle ilgisi yok, ayri interact kaynagiyla cakisir).
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
