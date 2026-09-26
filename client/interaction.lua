TwLib = TwLib or {}
local Interaction = { shown = false }
TwLib.Interaction = Interaction

local lastSig

local function stripTokens(text)
    if type(text) ~= 'string' then return text end
    text = text:gsub('~[%w_]+~[^~]+~[%w_]+~', '')
    text = text:gsub('~[^~]+~', '')
    return (text:gsub('%s+', ' '):gsub('^%s+', ''):gsub('%s+$', ''))
end

local function toCards(textOrCards)
    if type(textOrCards) == 'table' then
        local out = {}
        for i, card in ipairs(textOrCards) do
            out[i] = { key = card.key, text = stripTokens(card.text) }
        end
        return out
    end
    local text = tostring(textOrCards)
    local key, rest = text:match('^%[(%w+)%]%s*(.+)$')
    if key then return { { key = key, text = stripTokens(rest) } } end
    return { { key = 'E', text = stripTokens(text) } }
end

local function sig(cards, position, color)
    local parts = { position, color or '' }
    for _, card in ipairs(cards) do
        parts[#parts + 1] = (card.key or '?') .. ':' .. (card.text or '')
    end
    return table.concat(parts, '|')
end

function Interaction.Show(textOrCards, position, color)
    position = position or 'right-center'
    local cards = toCards(textOrCards)
    local current = sig(cards, position, color)
    if Interaction.shown and lastSig == current then return end
    Interaction.shown, lastSig = true, current
    SendNuiMessage(json.encode({ action = 'twlib:show', cards = cards, position = position, color = color }))
end

function Interaction.Hide()
    if not Interaction.shown then return end
    Interaction.shown, lastSig = false, nil
    SendNuiMessage(json.encode({ action = 'twlib:hide' }))
end

local shownBy
local colorByResource = {}

exports('SetPromptColor', function(color)
    local resource = GetInvokingResource()
    if resource then colorByResource[resource] = color end
end)

exports('ShowDrawText', function(textOrCards, position, color)
    local resource = GetInvokingResource()
    shownBy = resource or shownBy
    Interaction.Show(textOrCards, position, color or colorByResource[resource or ''])
end)
exports('HideDrawText', function() Interaction.Hide() end)

AddEventHandler('onClientResourceStop', function(resource)
    colorByResource[resource] = nil
    if resource ~= shownBy then return end
    shownBy = nil
    Interaction.Hide()
end)
