# frozen_string_literal: true

class CreateSessions < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `sessions` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `user_id` bigint NOT NULL,
        `ip_address` varchar(45),
        `user_agent` varchar(255),
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        PRIMARY KEY (`id`),
        INDEX `idx_user_id` (`user_id`),
        CONSTRAINT `fk_sessions_user_id` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `sessions`'
  end
end
