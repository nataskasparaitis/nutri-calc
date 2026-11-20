# frozen_string_literal: true

class CreateFoodLogEntries < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `food_log_entries` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `user_id` bigint NOT NULL,
        `item_id` bigint,
        `recipe_id` bigint,
        `grams` int NOT NULL,
        `eaten_on` date NOT NULL,
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        PRIMARY KEY (`id`),
        INDEX `idx_user_id_eaten_on` (`user_id`, `eaten_on`),
        INDEX `idx_item_id` (`item_id`),
        INDEX `idx_recipe_id` (`recipe_id`),
        CONSTRAINT `fk_food_log_entries_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
        CONSTRAINT `fk_food_log_entries_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`),
        CONSTRAINT `fk_food_log_entries_recipe_id` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `food_log_entries`'
  end
end
