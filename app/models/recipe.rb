class Recipe < ApplicationRecord
  belongs_to :user

  has_many :recipe_items
  has_many :items, through: :recipe_items
end
