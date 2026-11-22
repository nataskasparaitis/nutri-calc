class User < ApplicationRecord
  has_secure_password

  has_many :recipes
  has_many :favorite_items
  has_many :food_log_entries
  has_many :created_items, class_name: "Item", foreign_key: :creator_id, inverse_of: :creator

  normalizes :nickname, with: ->(nickname) { Sanitize::Text.for(nickname) }

  validates :nickname,
    presence: true,
    length: { in: 3..20 },
    uniqueness: true,
    format: {
      with: /\A[a-zA-Z0-9_.-]+\z/,
      message: "can only contain letters, numbers, dots, dashes and underscores"
    }

  validates :password, length: { minimum: 12 }, allow_nil: true
end
