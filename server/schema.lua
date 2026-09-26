TwLib = TwLib or {}
local Schema = { ready = false }
TwLib.Schema = Schema

local SUFFIX = ') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci'

local TABLES = {
    [[CREATE TABLE IF NOT EXISTS `tw_lib_ledger` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `resource` VARCHAR(64) NOT NULL,
  `identifier` VARCHAR(50) NOT NULL,
  `kind` VARCHAR(16) NOT NULL,
  `direction` VARCHAR(4) NOT NULL,
  `account` VARCHAR(16) NOT NULL DEFAULT '',
  `item` VARCHAR(64) NULL,
  `amount` BIGINT NOT NULL DEFAULT 0,
  `reason` VARCHAR(32) NOT NULL DEFAULT 'unknown',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_ledger_resource` (`resource`, `created_at`),
  KEY `idx_ledger_player` (`identifier`, `created_at`)]] .. SUFFIX,

    [[CREATE TABLE IF NOT EXISTS `tw_lib_job_history` (
  `id` BIGINT NOT NULL AUTO_INCREMENT,
  `identifier` VARCHAR(50) NOT NULL,
  `job_id` VARCHAR(50) NOT NULL,
  `region_name` VARCHAR(100) NULL,
  `earned_money` BIGINT NOT NULL DEFAULT 0,
  `earned_xp` INT NOT NULL DEFAULT 0,
  `duration_seconds` INT NOT NULL DEFAULT 0,
  `completed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `idx_history_player` (`identifier`, `completed_at` DESC),
  KEY `idx_history_job` (`job_id`, `completed_at`)]] .. SUFFIX,

    [[CREATE TABLE IF NOT EXISTS `tw_lib_ledger_daily` (
  `resource` VARCHAR(64) NOT NULL,
  `day` DATE NOT NULL,
  `kind` VARCHAR(16) NOT NULL,
  `direction` VARCHAR(4) NOT NULL,
  `account` VARCHAR(16) NOT NULL DEFAULT '',
  `total` BIGINT NOT NULL DEFAULT 0,
  `events` INT NOT NULL DEFAULT 0,
  `players` INT NOT NULL DEFAULT 0,
  PRIMARY KEY (`resource`, `day`, `kind`, `direction`, `account`),
  KEY `idx_daily_day` (`day`)]] .. SUFFIX,

    [[CREATE TABLE IF NOT EXISTS `tw_lib_players` (
  `identifier` VARCHAR(50) NOT NULL,
  `name` VARCHAR(100) NULL,
  `fivem_name` VARCHAR(100) NULL,
  `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`identifier`)]] .. SUFFIX,
}

function Schema.ensure()
    if Schema.ready then return end
    for _, sql in ipairs(TABLES) do MySQL.query.await(sql) end
    Schema.ready = true
end
