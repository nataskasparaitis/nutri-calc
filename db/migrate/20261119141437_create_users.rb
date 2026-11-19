# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE TABLE `users` (
        `id` bigint NOT NULL AUTO_INCREMENT,
        `nickname` varchar(191) NOT NULL,
        `password_digest` varchar(191) COLLATE utf8mb4_bin NOT NULL,
        `admin` boolean NOT NULL DEFAULT false,
        `created_at` datetime NOT NULL,
        `updated_at` datetime NOT NULL,
        PRIMARY KEY (`id`),
        UNIQUE INDEX `idx_nickname` (`nickname`)
      ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    SQL
  end

  def down
    execute 'DROP TABLE IF EXISTS `users`'
  end
end
