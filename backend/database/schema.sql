-- =========================================================================
-- BASE DE DONNÉES PRONOSTICS SPORTIFS - LARAVEL 12 & CINETPAY
-- DDL complet pour MySQL 8.0+ / MariaDB 10.11+
-- =========================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- -------------------------------------------------------------------------
-- 1. Table users
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `last_name` varchar(100) NOT NULL,
  `first_name` varchar(100) NOT NULL,
  `phone` varchar(30) NOT NULL UNIQUE,
  `email` varchar(150) NOT NULL UNIQUE,
  `password` varchar(255) NOT NULL,
  `is_admin` tinyint(1) NOT NULL DEFAULT '0',
  `subscription_status` enum('FREE_TRIAL','ACTIVE','EXPIRED','NONE') NOT NULL DEFAULT 'FREE_TRIAL',
  `subscription_expires_at` timestamp NULL DEFAULT NULL,
  `free_trial_expires_at` timestamp NULL DEFAULT NULL,
  `referral_code` varchar(20) NULL UNIQUE,
  `referred_by_id` bigint unsigned NULL,
  `fcm_token` varchar(255) NULL,
  `remember_token` varchar(100) NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_users_email` (`email`),
  INDEX `idx_users_phone` (`phone`),
  INDEX `idx_users_status` (`subscription_status`),
  CONSTRAINT `fk_users_referred_by` FOREIGN KEY (`referred_by_id`) REFERENCES `users` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 2. Table subscription_plans
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `subscription_plans`;
CREATE TABLE `subscription_plans` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(50) NOT NULL UNIQUE,
  `name` varchar(100) NOT NULL,
  `price` int unsigned NOT NULL DEFAULT '2000',
  `duration_days` int unsigned NOT NULL DEFAULT '30',
  `description` text NULL,
  `features_json` json NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 3. Table user_subscriptions
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `user_subscriptions`;
CREATE TABLE `user_subscriptions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `subscription_plan_id` bigint unsigned NOT NULL,
  `status` enum('ACTIVE','EXPIRED','CANCELLED') NOT NULL DEFAULT 'ACTIVE',
  `starts_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `expires_at` timestamp NOT NULL,
  `auto_renew` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_sub_user_id` (`user_id`),
  INDEX `idx_sub_plan_id` (`subscription_plan_id`),
  INDEX `idx_sub_status` (`status`),
  CONSTRAINT `fk_sub_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sub_plan` FOREIGN KEY (`subscription_plan_id`) REFERENCES `subscription_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 4. Table predictions
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `predictions`;
CREATE TABLE `predictions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `title` varchar(200) NOT NULL,
  `competition` varchar(150) NOT NULL,
  `country` varchar(100) NOT NULL,
  `championship` varchar(150) NOT NULL,
  `match_date` date NOT NULL,
  `match_time` varchar(10) NOT NULL,
  `home_team` varchar(150) NOT NULL,
  `away_team` varchar(150) NOT NULL,
  `type` enum('MONTANTE','COTE_5','COTE_10','COTE_50') NOT NULL,
  `odds` decimal(6,2) NOT NULL,
  `selections_json` json NULL COMMENT 'Tableau des matchs du combiné (match, championnat, pari, cote)',
  `confidence` tinyint unsigned NOT NULL DEFAULT '4',
  `analysis` text NULL,
  `status` enum('PENDING','WON','LOST','VOID') NOT NULL DEFAULT 'PENDING',
  `image_url` varchar(255) NULL,
  `is_published` tinyint(1) NOT NULL DEFAULT '1',
  `is_archived` tinyint(1) NOT NULL DEFAULT '0',
  `scheduled_at` timestamp NULL DEFAULT NULL,
  `published_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_pred_type` (`type`),
  INDEX `idx_pred_status` (`status`),
  INDEX `idx_pred_match_date` (`match_date`),
  INDEX `idx_pred_championship` (`championship`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 5. Table payments
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `payments`;
CREATE TABLE `payments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `user_id` bigint unsigned NOT NULL,
  `subscription_plan_id` bigint unsigned NOT NULL,
  `transaction_id` varchar(100) NOT NULL UNIQUE,
  `cinetpay_token` varchar(255) NULL,
  `amount` int unsigned NOT NULL,
  `currency` varchar(10) NOT NULL DEFAULT 'XOF',
  `status` enum('PENDING','ACCEPTED','FAILED','REFUNDED') NOT NULL DEFAULT 'PENDING',
  `payment_method` varchar(50) NOT NULL DEFAULT 'MOBILE_MONEY',
  `operator_id` varchar(100) NULL,
  `raw_response` json NULL,
  `paid_at` timestamp NULL DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  INDEX `idx_pay_user_id` (`user_id`),
  INDEX `idx_pay_tx_id` (`transaction_id`),
  INDEX `idx_pay_status` (`status`),
  CONSTRAINT `fk_pay_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pay_plan` FOREIGN KEY (`subscription_plan_id`) REFERENCES `subscription_plans` (`id`) ON DELETE RESTRICT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 6. Table promo_codes
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `promo_codes`;
CREATE TABLE `promo_codes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `code` varchar(30) NOT NULL UNIQUE,
  `discount_percent` int unsigned NOT NULL DEFAULT '10',
  `max_uses` int unsigned NOT NULL DEFAULT '100',
  `used_count` int unsigned NOT NULL DEFAULT '0',
  `expires_at` timestamp NULL DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- -------------------------------------------------------------------------
-- 7. Table faqs
-- -------------------------------------------------------------------------
DROP TABLE IF EXISTS `faqs`;
CREATE TABLE `faqs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `question` varchar(255) NOT NULL,
  `answer` text NOT NULL,
  `category` varchar(50) NOT NULL DEFAULT 'GENERAL',
  `display_order` int unsigned NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;
