-- Optional: the resource creates these tables automatically on start.

-- One row per advent door a character has spun.
CREATE TABLE IF NOT EXISTS `bdev_christmas_claims` (
    `identifier` VARCHAR(64) NOT NULL,
    `year` SMALLINT UNSIGNED NOT NULL,
    `day` TINYINT UNSIGNED NOT NULL,
    `status` VARCHAR(10) NOT NULL DEFAULT 'claimed', -- 'pending' = rolled but not collected yet
    `segment` TINYINT UNSIGNED NULL,                  -- wheel segment the spin landed on
    `reward` LONGTEXT NULL,                           -- JSON of the rolled reward
    `claimed_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`identifier`, `year`, `day`)
);

-- One row per present unwrapped. Powers the unclaimed gifts list, the
-- ornament collection, the recent unwraps feed and the leaderboard.
CREATE TABLE IF NOT EXISTS `bdev_christmas_unwraps` (
    `id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
    `identifier` VARCHAR(64) NOT NULL,
    `year` SMALLINT UNSIGNED NOT NULL,
    `charname` VARCHAR(100) NULL,
    `present` VARCHAR(64) NOT NULL,
    `item` VARCHAR(64) NULL,                          -- NULL for cash
    `reward` LONGTEXT NOT NULL,                       -- JSON of the rolled reward
    `rarity` VARCHAR(12) NOT NULL DEFAULT 'common',
    `status` VARCHAR(10) NOT NULL DEFAULT 'pending',  -- 'pending' until handed over
    `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `player` (`identifier`, `year`),
    KEY `feed` (`year`, `status`, `rarity`)
);
