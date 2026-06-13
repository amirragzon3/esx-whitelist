CREATE TABLE IF NOT EXISTS `whitelist_accounts` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `username` VARCHAR(50) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL,
    `synthetic_steam` VARCHAR(32) NOT NULL UNIQUE,
    `license` VARCHAR(255) DEFAULT NULL,
    `last_login` TIMESTAMP NULL DEFAULT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `is_active` TINYINT(1) DEFAULT 1,
    INDEX `idx_username` (`username`),
    INDEX `idx_steam` (`synthetic_steam`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- مهاجرت از نسخه قبلی:
-- ALTER TABLE whitelist_accounts MODIFY license VARCHAR(255) NULL;
-- ALTER TABLE whitelist_accounts MODIFY synthetic_steam VARCHAR(32) NOT NULL;
-- UPDATE whitelist_accounts SET synthetic_steam = CONCAT('steam:1100001', LPAD(id, 9, '0')) WHERE synthetic_steam IS NULL OR synthetic_steam = '';
