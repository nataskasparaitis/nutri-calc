# frozen_string_literal: true

class CreateItems < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `items` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `photo_url` varchar(2048) COLLATE utf8mb4_bin,
        `name` varchar(191) NOT NULL,
        `calories_per_100g` decimal(7,2) NOT NULL,
        `fat_per_100g` decimal(7,2) NOT NULL,
        `carbohydrate_per_100g` decimal(7,2) NOT NULL,
        `fiber_per_100g` decimal(7,2) NOT NULL,
        `protein_per_100g` decimal(7,2) NOT NULL,
        `salt_per_100g` decimal(7,2) NOT NULL,
        `deleted_at` datetime,
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        `active` tinyint GENERATED ALWAYS AS (IF(`deleted_at` IS NULL, 1, NULL)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE INDEX `idx_name_active` (`name`, `active`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `items`'
  end
end
