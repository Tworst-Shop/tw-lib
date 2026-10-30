local settings = require '@tw-lib.interact.shared.settings'
local textures = settings.Textures

local SetDrawOrigin = SetDrawOrigin
local DrawSprite = DrawSprite
local ClearDrawOrigin = ClearDrawOrigin
local DoesEntityExist = DoesEntityExist
local GetEntityBonePosition_2 = GetEntityBonePosition_2
local GetEntityBoneIndexByName = GetEntityBoneIndexByName
local GetOffsetFromEntityInWorldCoords = GetOffsetFromEntityInWorldCoords
local IsEntityAPed = IsEntityAPed
local GetEntityCoords = GetEntityCoords

local utils = {}

function utils.getNet(entity)
    return NetworkGetNetworkIdFromEntity(entity)
end

function utils.getEntity(netID)
    return NetworkGetEntityFromNetworkId(netID)
end

function utils.getTrunkOffset(entity)
    local min, _ = GetModelDimensions(GetEntityModel(entity))
    return GetOffsetFromEntityInWorldCoords(entity, 0.0, min.y - 0.5, 0.0)
end

function utils.getCoordsFromInteract(interaction)
    if interaction.entity then
        if DoesEntityExist(interaction.entity) then
            if interaction.bone then
                return GetEntityBonePosition_2(interaction.entity, GetEntityBoneIndexByName(interaction.entity, interaction.bone))
            elseif interaction.model then
                return GetOffsetFromEntityInWorldCoords(interaction.entity, 0.0 + interaction.offset.x, 0.0 + interaction.offset.y, 0.0 + interaction.offset.z)
            else
                if IsEntityAPed(interaction.entity) then
                    if interaction.offset and interaction.offset ~= vec3(0.0, 0.0, 0.0) then
                        return GetOffsetFromEntityInWorldCoords(interaction.entity, 0.0 + interaction.offset.x, 0.0 + interaction.offset.y, 0.0 + interaction.offset.z)
                    end
                    return GetEntityBonePosition_2(interaction.entity, 0)
                else
                    if interaction.offset and interaction.offset ~= vec3(0.0, 0.0, 0.0) then
                        return GetOffsetFromEntityInWorldCoords(interaction.entity, 0.0 + interaction.offset.x, 0.0 + interaction.offset.y, 0.0 + interaction.offset.z)
                    end
                    return GetEntityCoords(interaction.entity)
                end
            end
        end
    end

    return vec3(0.0, 0.0, 0.0)
end

local TXD = 'twlib_interact'
local prompt = settings.Prompt
local font = require '@tw-lib.interact.client.font'
local glyphs = font.glyphs
local GetAspectRatio = GetAspectRatio
local DrawSpriteUv = DrawSpriteUv
local string_upper = string.upper
local utf8_codes, utf8_char = utf8.codes, utf8.char

local DUI_W, DUI_H, ROW, EM = 1536, 768, 48, 32
local DUI_TXD = 'twlib_txt_' .. GetCurrentResourceName()
local dui, slots, nslot, foreign, nforeign = nil, {}, 0, {}, 0

local function wide(cp)
    return (cp >= 0x1100 and cp <= 0x115F) or (cp >= 0x2E80 and cp <= 0xA4CF) or (cp >= 0xAC00 and cp <= 0xD7A3)
        or (cp >= 0xF900 and cp <= 0xFAFF) or (cp >= 0xFE30 and cp <= 0xFE4F) or (cp >= 0xFF00 and cp <= 0xFF60)
        or (cp >= 0xFFE0 and cp <= 0xFFE6) or cp >= 0x20000
end

local function adv(cp)
    local glyph = glyphs[utf8_char(cp)]
    return glyph and glyph.adv or (wide(cp) and font.size or font.size * 0.6)
end

local function isForeign(text)
    local f = foreign[text]
    if f == nil then
        f = false
        for _, cp in utf8_codes(text) do
            if not glyphs[utf8_char(cp)] then f = true break end
        end
        nforeign += 1
        if nforeign > 256 then foreign, nforeign = {}, 1 end
        foreign[text] = f
    end
    return f
end

local function duiSlot(text)
    local s = slots[text]
    if not s then
        if not dui then
            dui = CreateDui('nui://tw-lib/interact/assets/text.html', DUI_W, DUI_H)
            CreateRuntimeTextureFromDuiHandle(CreateRuntimeTxd(DUI_TXD), 'txt', GetDuiHandle(dui))
            AddEventHandler('onClientResourceStop', function(res)
                if res == GetCurrentResourceName() then DestroyDui(dui) end
            end)
        end
        local row
        if nslot < DUI_H // ROW then
            row, nslot = nslot, nslot + 1
        else
            local old
            for t, o in pairs(slots) do if not old or o.used < slots[old].used then old = t end end
            row, slots[old] = slots[old].row, nil
        end
        local w = 0
        for _, cp in utf8_codes(text) do w += adv(cp) end
        s = { row = row, w = w * EM / font.size, used = 0, sent = 0, at = false }
        slots[text] = s
    end
    local now = GetGameTimer()
    s.used = now
    if now >= s.sent then
        if not IsDuiAvailable(dui) then return end
        SendDuiMessage(dui, json.encode({ row = s.row, text = text, w = s.w }))
        s.sent, s.at = now + 500, s.at or now + 100
    end
    return now >= s.at and s or nil
end

local function drawGlyphs(text, x, centerY, capHeight, aspect, r, g, b, a)
    if isForeign(text) then
        local s = duiSlot(text)
        if not s then return 0 end
        local em = font.size * capHeight / font.capHeight
        local w, v = s.w / EM * em / aspect, s.row * ROW / DUI_H
        DrawSpriteUv(DUI_TXD, 'txt', x + w * 0.5, centerY, w, em * ROW / EM, 0.0, v, s.w / DUI_W, v + ROW / DUI_H,
            0.0, r, g, b, a)
        return w
    end
    local k = capHeight / font.capHeight
    local h = font.lineHeight * k
    local cy = centerY + capHeight * 0.5 - font.ascent * k + h * 0.5
    local kx = k / aspect
    local vh = font.lineHeight / font.height
    local pen = x

    for _, cp in utf8_codes(text) do
        local glyph = glyphs[utf8_char(cp)] or glyphs['?']
        if glyph.w > 0 then
            local u, v = glyph.x / font.width, glyph.y / font.height
            DrawSpriteUv(TXD, textures.font, pen + (glyph.xoff + glyph.w * 0.5) * kx, cy, glyph.w * kx, h,
                u, v, u + glyph.w / font.width, v + vh, 0.0, r, g, b, a)
        end
        pen += glyph.adv * kx
    end

    return pen - x
end

local function measureText(text, capHeight, aspect)
    local kx = capHeight / font.capHeight / aspect
    local width = 0
    for _, cp in utf8_codes(text) do
        width += adv(cp) * kx
    end
    return width
end

local function drawText(text, x, centerY, capHeight, aspect, color, alpha)
    local oa = prompt.outlineAlpha or 0
    if oa > 0 then
        local px, a = 1.0 / 1080.0, math.floor(oa * alpha / 255)
        local pxx = px / aspect
        drawGlyphs(text, x - pxx, centerY, capHeight, aspect, 0, 0, 0, a)
        drawGlyphs(text, x + pxx, centerY, capHeight, aspect, 0, 0, 0, a)
        drawGlyphs(text, x, centerY - px, capHeight, aspect, 0, 0, 0, a)
        drawGlyphs(text, x, centerY + px, capHeight, aspect, 0, 0, 0, a)
    end
    drawGlyphs(text, x, centerY, capHeight, aspect, color[1], color[2], color[3], alpha)
end

local function drawPill(x0, x1, y, h, aspect, c)
    if not c or c[4] <= 0 then return end
    local capW = h * (prompt.pillRadius or 0.5) / aspect
    local mid = x1 - x0 - capW * 2.0
    DrawSprite(TXD, textures.cap, x0 + capW * 0.5, y, capW, h, 0.0, c[1], c[2], c[3], c[4])
    if mid > 0 then DrawSprite(TXD, textures.px, x0 + capW + mid * 0.5, y, mid, h, 0.0, c[1], c[2], c[3], c[4]) end
    DrawSprite(TXD, textures.cap, x1 - capW * 0.5, y, capW, h, 180.0, c[1], c[2], c[3], c[4])
end

local UPPER = { ['ç'] = 'Ç', ['ğ'] = 'Ğ', ['ı'] = 'I', ['ö'] = 'Ö', ['ş'] = 'Ş', ['ü'] = 'Ü', ['â'] = 'Â', ['î'] = 'Î',
                ['û'] = 'Û', ['é'] = 'É', ['è'] = 'È', ['à'] = 'À', ['á'] = 'Á', ['í'] = 'Í', ['ó'] = 'Ó', ['ú'] = 'Ú',
                ['ñ'] = 'Ñ', ['ä'] = 'Ä' }

local function label(opt)
    local text = tostring(opt.label or '')
    if not utf8.len(text) then text = text:gsub('[\128-\255]', '?') end
    if not prompt.uppercase then return text end
    return (string_upper(text):gsub(utf8.charpattern, UPPER))
end

function utils.drawDot(coords)
    local size, c = prompt.dotSize, prompt.accent
    SetDrawOrigin(coords.x, coords.y, coords.z, 0)
    DrawSprite(TXD, textures.point, 0.0, 0.0, size / GetAspectRatio(false), size, 0.0, c[1], c[2], c[3], c[4])
    ClearDrawOrigin()
end

function utils.drawCrosshair()
    local size = prompt.crosshairSize
    DrawSprite(TXD, textures.crosshair, 0.5, 0.5, size / GetAspectRatio(false), size, 0.0, 255, 255, 255, 230)
end

function utils.drawPrompt(coords, options, selection)
    local aspect = GetAspectRatio(false)
    local keyH = prompt.keySize
    local keyW = keyH / aspect
    local pad = prompt.pillPad
    local padX = pad / aspect
    local labelX = keyW * 0.5 + prompt.keyGap / aspect
    local keyTextX = -measureText(prompt.key, prompt.keyTextHeight, aspect) * 0.5
    local otherH = prompt.textHeight * (prompt.otherScale or 1.0)
    local keyColor, keyTextColor = prompt.keyColor, prompt.keyTextColor

    SetDrawOrigin(coords.x, coords.y, coords.z, 0)

    for i = 1, #options do
        local y = (i - selection) * prompt.rowSpacing
        local text = label(options[i])

        if i == selection then
            local x1 = labelX + measureText(text, prompt.textHeight, aspect) + (prompt.pillPadRight or pad * 2.5) / aspect
            drawPill(-keyW * 0.5 - padX, x1, y, keyH + pad * 2.0, aspect, prompt.pillColor)
            DrawSprite(TXD, textures.key, 0.0, y, keyW, keyH, 0.0, keyColor[1], keyColor[2], keyColor[3], keyColor[4])
            drawGlyphs(prompt.key, keyTextX, y, prompt.keyTextHeight, aspect, keyTextColor[1], keyTextColor[2], keyTextColor[3], keyTextColor[4])
            local c = prompt.selTextColor
            drawGlyphs(text, labelX, y, prompt.textHeight, aspect, c[1], c[2], c[3], c[4])
        else
            drawText(text, labelX, y, otherH, aspect, prompt.textColor, prompt.dimmedAlpha)
        end
    end

    ClearDrawOrigin()
end

return utils