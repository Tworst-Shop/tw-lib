SQLChecker = false

local COLUMNS = {
    { name = 'identifier', type = 'char(50)' },
    { name = 'profiledata', type = 'longtext' },
    { name = 'dailymission', type = 'longtext' },
    { name = 'tutorial', type = 'longtext' },
    { name = 'history', type = 'longtext' },
    { name = 'uisettings', type = 'longtext' },
}
local COLLATION = 'utf8mb4_unicode_ci'

local function describe(tableName, column)
    local rows = MySQL.query.await(('SHOW FULL COLUMNS FROM `%s` LIKE ?'):format(tableName), { column })
    return rows and rows[1] or nil
end

local function ensureColumn(tableName, column)
    local row = describe(tableName, column.name)
    if not row then
        MySQL.query.await(('ALTER TABLE `%s` ADD COLUMN `%s` %s DEFAULT NULL;'):format(tableName, column.name, column.type))
        return
    end
    if row.Type and row.Type:lower() ~= column.type then
        MySQL.query.await(('ALTER TABLE `%s` MODIFY `%s` %s DEFAULT NULL;'):format(tableName, column.name, column.type))
        row = describe(tableName, column.name) or row
    end
    if row.Collation and row.Collation ~= COLLATION then
        MySQL.query.await(('ALTER TABLE `%s` MODIFY `%s` %s COLLATE %s;'):format(tableName, column.name, row.Type, COLLATION))
    end
end

Citizen.CreateThread(function()
    local name = base.SQLName
    local ok, err = pcall(function()
        MySQL.query.await(([[
            CREATE TABLE IF NOT EXISTS `%s` (
                `identifier` char(50) DEFAULT NULL,
                `profiledata` longtext DEFAULT NULL,
                `dailymission` longtext DEFAULT NULL,
                `tutorial` longtext DEFAULT NULL,
                `history` longtext DEFAULT NULL,
                `uisettings` longtext DEFAULT NULL,
                UNIQUE KEY `identifier` (`identifier`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
        ]]):format(name))
        for _, column in ipairs(COLUMNS) do
            ensureColumn(name, column)
        end
        for _, column in ipairs(base.profileColumns or {}) do
            ensureColumn(name, { name = column, type = 'longtext' })
        end
        for _, createQuery in pairs(base.sqlTables or {}) do
            MySQL.query.await(createQuery)
        end
    end)
    if not ok then
        print(('^1[%s]^7 database check failed: %s'):format(GetCurrentResourceName(), tostring(err)))
    end
    SQLChecker = true
end)
