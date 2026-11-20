# frozen_string_literal: true

class CreateRecipeItems < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `recipe_items` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `recipe_id` bigint NOT NULL,
        `item_id` bigint NOT NULL,
        `grams` int NOT NULL,
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE INDEX `idx_recipe_id_item_id` (`recipe_id`, `item_id`),
        INDEX `idx_item_id` (`item_id`),
        CONSTRAINT `fk_recipe_items_recipe_id` FOREIGN KEY (`recipe_id`) REFERENCES `recipes` (`id`) ON DELETE CASCADE,
        CONSTRAINT `fk_recipe_items_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `recipe_items`'
  end
end
