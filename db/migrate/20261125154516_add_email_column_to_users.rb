# frozen_string_literal: true

class AddEmailColumnToUsers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      ALTER TABLE `users`
        ADD COLUMN `email` varchar(254) NOT NULL AFTER `id`,
        ADD UNIQUE INDEX `idx_email` (`email`)
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE `users`
        DROP INDEX `idx_email`,
        DROP COLUMN `email`
    SQL
  end
end
