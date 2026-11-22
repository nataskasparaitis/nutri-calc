class ChangeItemsNutrientPrecision < ActiveRecord::Migration[8.1]
  def up
  execute <<~SQL
    ALTER TABLE `items`
      MODIFY `calories_per_100g` decimal(5,2) NOT NULL,
      MODIFY `fat_per_100g` decimal(5,2) NOT NULL,
      MODIFY `carbohydrate_per_100g` decimal(5,2) NOT NULL,
      MODIFY `fiber_per_100g` decimal(5,2) NOT NULL,
      MODIFY `protein_per_100g` decimal(5,2) NOT NULL,
      MODIFY `salt_per_100g` decimal(5,2) NOT NULL
  SQL
  end

  def down
  execute <<~SQL
    ALTER TABLE `items`
      MODIFY `calories_per_100g` decimal(7,2) NOT NULL,
      MODIFY `fat_per_100g` decimal(7,2) NOT NULL,
      MODIFY `carbohydrate_per_100g` decimal(7,2) NOT NULL,
      MODIFY `fiber_per_100g` decimal(7,2) NOT NULL,
      MODIFY `protein_per_100g` decimal(7,2) NOT NULL,
      MODIFY `salt_per_100g` decimal(7,2) NOT NULL
  SQL
  end
end
