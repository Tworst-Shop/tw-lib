local Merge, Store, ConfigFile = TwLib.Merge, TwLib.Store, TwLib.ConfigFile
local Import = {}
TwLib.Import = Import

local LOCALE_CODES = { 'en', 'tr', 'ar', 'de', 'fr', 'pt', 'ru', 'es', 'it', 'nl', 'pl' }

local function metadataList(res, key)
    local out = {}
    for i = 0, GetNumResourceMetadata(res, key) - 1 do out[#out + 1] = GetResourceMetadata(res, key, i) end
    return out
end

local function localeFiles(dir)
    if dir:match('%.lua$') then return { dir } end
    local out = {}
    for i, code in ipairs(LOCALE_CODES) do out[i] = dir .. '/' .. code .. '.lua' end
    return out
end

local function concat(a, b)
    local out = { table.unpack(a) }
    for _, v in ipairs(b) do out[#out + 1] = v end
    return out
end

local function sandbox(res, files, vars, read)
    local env = setmetatable(vars or {}, { __index = _G })
    for _, path in ipairs(files) do
        local src
        if read then src = read(path) else src = ConfigFile.pristine(LoadResourceFile(res, path)) end
        if src then
            local chunk, err = load(src, ('@@%s/%s'):format(res, path), 't', env)
            if not chunk then return nil, err end
            local ok, runErr = pcall(chunk)
            if not ok then return nil, runErr end
        end
    end
    return env
end

local SEED = 20260916
local function seeded(res, files, vars, read)
    math.randomseed(SEED)
    local env, err = sandbox(res, files, vars, read)
    math.randomseed(os.time())
    return env, err
end

local function valueAt(root, path)
    local node = root
    for _, key in ipairs(path) do
        if type(node) ~= 'table' then return nil end
        node = node[key]
    end
    return node
end

local function isListOfTables(v)
    return Merge.isList(v) and type(v[1]) == 'table'
end

local function entryId(entry)
    if type(entry) ~= 'table' then return nil end
    local id = entry.regionID
    if id == nil then id = entry.regionName end
    if id == nil then id = entry.name end
    if type(id) == 'number' or (type(id) == 'string' and id ~= '') then return type(id) .. ':' .. tostring(id) end
end

local function idsOf(root, path)
    local chain
    for depth = 2, #path do
        if type(path[depth]) == 'number' then
            local list = valueAt(root, { table.unpack(path, 1, depth - 1) })
            local id = isListOfTables(list) and entryId(list[path[depth]])
            if id then
                chain = chain or {}
                chain[tostring(depth)] = id
            end
        end
    end
    return chain
end

function Import.follow(res)
    local defaults = Import.loadDefaults(res)
    if not defaults then return nil end
    local root = { Config = defaults.Config, Locales = defaults.Locales, Server = defaults.Server }
    local known = Store.get(res, { '_meta', 'ids' })
    known = type(known) == 'table' and known or {}
    local plan = { moves = {}, drops = {}, ids = {} }
    for _, row in ipairs(Store.overrides(res)) do
        if row.path[1] ~= '_meta' then
            local chain = known[Merge.pathKey(row.path)]
            local path, lost = { table.unpack(row.path) }, false
            for depth = 2, #path do
                local want = type(chain) == 'table' and chain[tostring(depth)]
                if want then
                    local list = valueAt(root, { table.unpack(path, 1, depth - 1) })
                    list = isListOfTables(list) and list or {}
                    if entryId(list[path[depth]]) ~= want then
                        local found
                        for i, entry in ipairs(list) do
                            if entryId(entry) == want then found = i break end
                        end
                        if not found then lost = true break end
                        path[depth] = found
                    end
                end
            end
            if lost then
                plan.drops[#plan.drops + 1] = row
            else
                if Merge.pathKey(path) ~= Merge.pathKey(row.path) then
                    plan.moves[#plan.moves + 1] = { from = row.path, to = path, value = row.value }
                end
                plan.ids[Merge.pathKey(path)] = idsOf(root, path)
            end
        end
    end
    if #plan.moves == 0 and #plan.drops == 0 and Merge.equal(plan.ids, known) then return nil end
    return plan
end

function Import.applyFollow(res, plan)
    for _, row in ipairs(plan.drops) do
        Store.remove(res, row.path)
        print(('^3[tw-lib]^7 %s: the update removed the entry of %s; that saved value is removed too'):format(res, Merge.pathKey(row.path)))
    end
    for _, move in ipairs(plan.moves) do Store.remove(res, move.from) end
    for _, move in ipairs(plan.moves) do
        Store.set(res, move.to, move.value)
        print(('^3[tw-lib]^7 %s: %s moved to %s with its entry'):format(res, Merge.pathKey(move.from), Merge.pathKey(move.to)))
    end
    Store.set(res, { '_meta', 'ids' }, plan.ids)
end

function Import.loadDefaults(res)
    local files = metadataList(res, 'tw_lib_config')
    if #files == 0 then return nil end
    local localeDir = GetResourceMetadata(res, 'tw_lib_locales', 0) or 'defaults/locales'
    local env, err = sandbox(res, concat(localeFiles(localeDir), files))
    if not env or type(env.Config) ~= 'table' then
        print(('^1[tw-lib]^7 %s: shipped defaults could not be read: %s'):format(res, tostring(err)))
        return nil
    end
    return env
end

function Import.edits(res)
    local files = metadataList(res, 'tw_lib_config')
    if #files == 0 then return {} end
    local all = concat(localeFiles(GetResourceMetadata(res, 'tw_lib_locales', 0) or 'defaults/locales'), files)
    local function shippedFile(path)
        return LoadResourceFile(res, path .. '.shipped') or ConfigFile.pristine(LoadResourceFile(res, path))
    end
    local raw, err1 = seeded(res, all, nil, function(path) return LoadResourceFile(res, path) end)
    local shipped, err2 = seeded(res, all, nil, shippedFile)
    if not (raw and shipped and type(raw.Config) == 'table' and type(shipped.Config) == 'table') then
        print(('^1[tw-lib]^7 %s: config file could not be read, hand edits not saved: %s'):format(res, tostring(err1 or err2)))
        return {}
    end
    if raw.Config.Locale ~= shipped.Config.Locale then
        local localized = seeded(res, all, { TwLibLocale = raw.Config.Locale }, shippedFile)
        if localized and type(localized.Config) == 'table' then
            localized.Config.Locale = shipped.Config.Locale
            shipped = localized
        end
    end
    local function roots(env) return { Config = env.Config, Server = type(env.Server) == 'table' and env.Server or nil } end
    local out = {}
    for _, row in ipairs(Merge.diff(roots(shipped), roots(raw))) do
        local saved = Store.get(res, row.path)
        if saved == nil or not Merge.equal(saved, row.value) then out[#out + 1] = row end
    end
    local marked = {}
    for _, path in ipairs(files) do
        for key in pairs(ConfigFile.marked(LoadResourceFile(res, path))) do marked[key] = true end
    end
    for _, row in ipairs(Store.overrides(res)) do
        local ship = valueAt(shipped, row.path)
        if marked[Merge.pathKey(row.path)] and Merge.equal(valueAt(raw, row.path), ship) and not Merge.equal(row.value, ship) then
            out[#out + 1] = { path = row.path }
        end
    end
    return out
end

function Import.needs(res)
    return GetNumResourceMetadata(res, 'tw_lib_legacy') > 0 and Store.get(res, { '_meta', 'imported' }) == nil
end

function Import.run(res)
    if not Import.needs(res) then return 0 end
    local defaultsConfig = metadataList(res, 'tw_lib_config')
    local newLocales = localeFiles(GetResourceMetadata(res, 'tw_lib_locales', 0) or 'defaults/locales')
    local oldLocales = localeFiles(GetResourceMetadata(res, 'tw_lib_legacy_locales', 0) or 'locales')

    local oldText, err1 = sandbox(res, oldLocales)
    local old, err2 = seeded(res, concat(newLocales, metadataList(res, 'tw_lib_legacy')))
    if not oldText or not old then
        print(('^1[tw-lib]^7 %s: old settings files could not be read, nothing imported: %s'):format(res, tostring(err1 or err2)))
        return 0
    end
    local done = os.date('%Y-%m-%d %H:%M:%S')
    if type(old.Config) ~= 'table' then
        Store.set(res, { '_meta', 'imported' }, done)
        return 0
    end

    local shipped, err3 = sandbox(res, concat(newLocales, defaultsConfig))
    local new, err4 = sandbox(res, concat(newLocales, defaultsConfig), { TwLibLocale = old.Config.Locale })
    if not (shipped and new and type(shipped.Config) == 'table' and type(new.Config) == 'table') then
        print(('^1[tw-lib]^7 %s: shipped defaults could not be read, nothing imported: %s'):format(res, tostring(err3 or err4)))
        return 0
    end
    new.Config.Locale = shipped.Config.Locale

    local rows = Merge.diff(
        { Config = new.Config, Locales = shipped.Locales or {} },
        { Config = old.Config, Locales = oldText.Locales or {} })

    local shippedFiles = metadataList(res, 'tw_lib_legacy_shipped')
    if #shippedFiles > 0 then
        local base, err5 = seeded(res, concat(newLocales, shippedFiles))
        local baseText, err6 = sandbox(res, localeFiles(GetResourceMetadata(res, 'tw_lib_legacy_shipped_locales', 0) or 'legacy/locales'))
        if not (base and baseText and type(base.Config) == 'table') then
            print(('^1[tw-lib]^7 %s: the old release files could not be read, nothing imported: %s'):format(res, tostring(err5 or err6)))
            return 0
        end
        local baseline = { Config = base.Config, Locales = baseText.Locales or {} }
        local changed = {}
        for _, row in ipairs(rows) do
            if not Merge.equal(valueAt(baseline, row.path), row.value) then changed[#changed + 1] = row end
        end
        rows = changed
    end

    for lang, texts in pairs(oldText.Locales or {}) do
        if type(texts) == 'table' and type(shipped.Locales) == 'table' and shipped.Locales[lang] == nil then
            rows[#rows + 1] = { path = { 'Locales', lang }, value = texts }
        end
    end
    local failed = {}
    for _, row in ipairs(rows) do
        local ok, err = pcall(Store.set, res, row.path, row.value)
        if not ok then failed[#failed + 1] = ('%s (%s)'):format(Merge.pathKey(row.path), tostring(err)) end
    end
    Store.set(res, { '_meta', 'imported' }, done)
    print(('^2[tw-lib]^7 %s: imported %d settings from the old config files'):format(res, #rows - #failed))
    if #failed > 0 then
        print(('^1[tw-lib]^7 %s: %d old settings could not be saved: %s'):format(res, #failed, table.concat(failed, ', ')))
    end
    return #rows - #failed
end
