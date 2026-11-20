# frozen_string_literal: true

class CreateRecipes < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `recipes` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `user_id` bigint NOT NULL,
        `name` varchar(191) NOT NULL,
        `deleted_at` datetime,
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        `active` tinyint GENERATED ALWAYS AS (IF(`deleted_at` IS NULL, 1, NULL)) VIRTUAL,
        PRIMARY KEY (`id`),
        UNIQUE INDEX `idx_user_id_name_active` (`user_id`, `name`, `active`),
        CONSTRAINT `fk_recipes_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `recipes`'
  end
end
