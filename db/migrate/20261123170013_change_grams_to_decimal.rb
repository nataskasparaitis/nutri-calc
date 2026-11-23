# frozen_string_literal: true

class ChangeGramsToDecimal < ActiveRecord::Migration[8.1]
  def up
    execute "ALTER TABLE `recipe_items` MODIFY `grams` decimal(7,2) NOT NULL"
    execute "ALTER TABLE `food_log_entries` MODIFY `grams` decimal(7,2) NOT NULL"
  end

  def down
    execute "ALTER TABLE `recipe_items` MODIFY `grams` int NOT NULL"
    execute "ALTER TABLE `food_log_entries` MODIFY `grams` int NOT NULL"
  end
end
