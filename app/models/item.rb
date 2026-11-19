class Item < ApplicationRecord
  belongs_to :creator, class_name: "User", optional: true, inverse_of: :created_items

  has_many :recipe_items
  has_many :favorite_items
  has_many :food_log_entries
end
