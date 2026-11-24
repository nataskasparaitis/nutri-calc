class FoodLogEntry < ApplicationRecord
  MAX_GRAMS = 99999.99

  belongs_to :user
  belongs_to :item, optional: true
  belongs_to :recipe, optional: true

  validates :grams, numericality: { greater_than: 0, less_than_or_equal_to: MAX_GRAMS }
  validates :eaten_on, presence: true
  validates :item, presence: { message: "must exist" }, if: -> { item_id.present? }
  validates :recipe, presence: { message: "must exist" }, if: -> { recipe_id.present? }

  validate :item_or_recipe_but_not_both
  validate :item_not_deleted, if: :will_save_change_to_item_id?
  validate :recipe_not_deleted, if: :will_save_change_to_recipe_id?
  validate :recipe_belongs_to_user, if: :will_save_change_to_recipe_id?

  private

  def item_or_recipe_but_not_both
    if item.nil? && recipe.nil?
      errors.add(:base, :item_or_recipe_missing, message: "Choose an item or a recipe")
    elsif item && recipe
      errors.add(:base, :item_and_recipe, message: "Choose an item or a recipe, not both")
    end
  end

  def item_not_deleted
    errors.add(:item, :deleted, message: "has been deleted") if item&.deleted_at?
  end

  def recipe_not_deleted
    errors.add(:recipe, :deleted, message: "has been deleted") if recipe&.deleted_at?
  end

  def recipe_belongs_to_user
    errors.add(:recipe, :not_owned, message: "must be one of your recipes") if recipe && recipe.user_id != user_id
  end
end
