class RecipeItem < ApplicationRecord
  MAX_GRAMS = 99999.99

  belongs_to :recipe
  belongs_to :item

  validates :grams, numericality: { greater_than: 0, less_than_or_equal_to: MAX_GRAMS }
  validates :item_id, uniqueness: { scope: :recipe_id, message: "is already in this recipe" }

  validate :item_not_deleted, if: :will_save_change_to_item_id?
  validate :recipe_not_deleted, if: :will_save_change_to_recipe_id?

  private

  def item_not_deleted
    errors.add(:item, :deleted, message: "has been deleted") if item&.deleted_at?
  end

  def recipe_not_deleted
    errors.add(:recipe, :deleted, message: "has been deleted") if recipe&.deleted_at?
  end
end
