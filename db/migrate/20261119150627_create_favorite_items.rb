# frozen_string_literal: true

class CreateFavoriteItems < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `favorite_items` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `user_id` bigint NOT NULL,
        `item_id` bigint NOT NULL,
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE INDEX `idx_user_id_item_id` (`user_id`, `item_id`),
        INDEX `idx_item_id` (`item_id`),
        CONSTRAINT `fk_favorite_items_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE,
        CONSTRAINT `fk_favorite_items_item_id` FOREIGN KEY (`item_id`) REFERENCES `items` (`id`) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `favorite_items`'
  end
end
