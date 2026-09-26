# tw-lib

Free shared library for the Tworst FiveM jobs (tw-diving, tw-electrician, tw-fashion, tw-garbagev2, tw-gardenerv2,
tw-plumber, tw-scrapyard, tw-transportv2). Every 3.x job needs it.

## Install

1. Download **`tw-lib-<version>.zip` from [Releases](https://github.com/Tworst-Shop/tw-lib/releases/latest)**.
   Do not use "Code → Download ZIP": that folder is named `tw-lib-main` and the jobs will not find it.
2. Extract it into your resources. The folder must be named `tw-lib`.
3. In `server.cfg`, start it after your framework and `oxmysql`, before the jobs:

   ```cfg
   ensure oxmysql
   ensure qb-core        # or qbx_core / es_extended / ...
   ensure tw-lib
   ensure tw-plumber     # your Tworst jobs
   ```

That is all. Framework, inventory, vehicle keys, fuel and clothing scripts are detected on their own; the console
shows what was found on start:

```
[tw-lib] 1.0.0 | framework=qb | inventory=ox_inventory | keys=qs-vehiclekeys | fuel=LegacyFuel | clothing=illenium-appearance
```

## Updating

Replace the `tw-lib` folder with the new one. Your job settings live in the database (`tw_lib_settings`), so an update
never resets your economy, language or settings. On start tw-lib checks tworst.com and tells the console when tw-lib or a
job has an update.

## Settings (`tw-lib/config.lua`)

```lua
Config.Locale = 'en' -- /twlib menu language: en, tr, de, fr, es, pt, ru, nl, sv, hu, ro, ja, ar

Config.Admin = {
    ace = 'tw-lib.admin',   -- players with this ACE open /twlib
    frameworkAdmins = true, -- QBCore / QBox admins (god, admin) and ESX admins (admin, superadmin) open it too
    identifiers = '',       -- anyone else, comma separated: 'license:..., discord:..., fivem:..., steam:..., ABC12345'
}
```

Who may open the `/twlib` admin menu: players with the ACE (`add_ace group.admin tw-lib.admin allow` in `server.cfg`),
framework admins, or anyone listed in `identifiers` (a license, Discord, FiveM or Steam id, or a citizenid).
Edit the file and restart tw-lib. Your values are saved in the database, so a tw-lib update keeps them. You can also set
them from the server console, e.g. `twlib set tw-lib Config.Admin.identifiers "license:abc, discord:123"`.

## Supported scripts

| | |
|---|---|
| Framework | qbx_core, qb-core, es_extended, TMC, vRP, standalone |
| Inventory | ox_inventory, qs-inventory, qs-inventory-pro, codem-inventory, codem-inventoryv2, tgiann-inventory, origen_inventory, ak47_qb_inventory, ak47_inventory, core_inventory, jaksam_inventory, one_inventory, and the framework's own inventory (qb-inventory, ps-inventory, esx) |
| Vehicle keys | qbx_vehiclekeys, qb-vehiclekeys, qs-vehiclekeys, wasabi_carlock, MrNewbVehicleKeys, jc_vehiclekeys, Renewed-Vehiclekeys, vehicles_keys (Jaksam), tgiann-hotwire, 0r-vehiclekeys, LifeSaver_KeySystem, ak47_qb_vehiclekeys, ak47_vehiclekeys, filo_vehiclekey, ic3d_vehiclekeys, is_vehiclekeys, mk_vehiclekeys, mm_carkeys, p_carkeys, rd_vehiclekeys, t1ger_keys, mx_carkeys, cd_garage, okokGarage, mVehicle |
| Fuel | LegacyFuel, ox_fuel, cdn-fuel, ps-fuel, x-fuel, lc_fuel, qb-fuel, Renewed-Fuel, myFuel, okokGasStation, qs-fuelstations, BigDaddy-Fuel, esx-sna-fuel, lj-fuel, hyon_gas_station, nd_fuel, rcore_fuel, ti_fuel |
| Clothing | illenium-appearance, fivem-appearance, qb-clothing, esx_skin, rcore_clothing, codem-clothing, codem-appearance, qs-appearance, 4bit_appearance, qf_skinmenu, crm-appearance, tgiann-clothing, 0r-clothing |

Something else? Pick it by hand (`twlib set tw-lib bridge.keys <name>`) or plug your own script in with
`exports['tw-lib']:RegisterBridge(kind, impl)` from your own resource.

## Console

- `twlib`: status, detected scripts and saved settings
- `twlib set <resource> <Config.Path> <value>` / `twlib unset <resource> <Config.Path>`: change a job setting
- `twlib stats`: money paid and jobs done today and in the last 7 days

## Support

Discord: https://discord.gg/tworst · Store: https://tworst.com
