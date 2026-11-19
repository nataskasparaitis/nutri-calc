class User < ApplicationRecord
  has_secure_password

  has_many :recipes
  has_many :favorite_items
  has_many :food_log_entries
  has_many :created_items, class_name: "Item", foreign_key: :creator_id, inverse_of: :creator
end
