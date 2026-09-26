local Merge = TwLib.Merge
local Store = { rows = {}, ready = false }
TwLib.Store = Store

Store.schema = [[
CREATE TABLE IF NOT EXISTS `tw_lib_settings` (
  `resource` VARCHAR(64) NOT NULL,
  `path` VARCHAR(512) NOT NULL,
  `value` LONGTEXT NOT NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`resource`, `path`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]]

local function put(resource, path, value)
    local list = Store.rows[resource] or {}
    Store.rows[resource] = list
    local key = Merge.pathKey(path)
    for i, row in ipairs(list) do
        if Merge.pathKey(row.path) == key then
            list[i] = { path = path, value = value }
            return
        end
    end
    list[#list + 1] = { path = path, value = value }
end

function Store.load()
    MySQL.query.await(Store.schema)
    local charset = MySQL.query.await("SELECT `TABLE_COLLATION` AS c FROM information_schema.TABLES WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'tw_lib_settings'")
    local collation = charset and charset[1] and charset[1].c
    if type(collation) == 'string' and not collation:find('^utf8mb4') then
        local ok, err = pcall(MySQL.query.await, 'ALTER TABLE `tw_lib_settings` CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci')
        print(ok and '^2[tw-lib]^7 settings table converted to utf8mb4'
            or ('^1[tw-lib]^7 settings table stays %s, texts outside it may not save: %s'):format(collation, tostring(err)))
    end
    Store.rows = {}
    for _, r in ipairs(MySQL.query.await('SELECT `resource`, `path`, `value` FROM `tw_lib_settings`') or {}) do
        local okPath, path = pcall(json.decode, r.path)
        local okValue, value = pcall(json.decode, r.value)
        if okValue and value ~= nil then okValue, value = pcall(Merge.decode, value) end
        if okPath and okValue and type(path) == 'table' and value ~= nil then
            put(r.resource, path, value)
        else
            print(('^1[tw-lib]^7 unreadable settings row skipped: %s %s'):format(tostring(r.resource), tostring(r.path)))
        end
    end
    Store.ready = true
end

function Store.overrides(resource)
    return Store.rows[resource] or {}
end

function Store.get(resource, path)
    local key = Merge.pathKey(path)
    for _, row in ipairs(Store.rows[resource] or {}) do
        if Merge.pathKey(row.path) == key then return row.value end
    end
    return nil
end

function Store.set(resource, path, value)
    MySQL.query.await(
        'INSERT INTO `tw_lib_settings` (`resource`, `path`, `value`) VALUES (?, ?, ?) ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)',
        { resource, json.encode(path), json.encode(Merge.encode(value)) })
    put(resource, path, Merge.copy(value))
end

function Store.remove(resource, path)
    MySQL.query.await('DELETE FROM `tw_lib_settings` WHERE `resource` = ? AND `path` = ?', { resource, json.encode(path) })
    local key, list = Merge.pathKey(path), Store.rows[resource] or {}
    for i = #list, 1, -1 do
        if Merge.pathKey(list[i].path) == key then table.remove(list, i) end
    end
end
