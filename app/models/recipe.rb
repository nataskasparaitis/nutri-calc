class Recipe < ApplicationRecord
  NAME_MAX_LENGTH = 191

  belongs_to :user

  has_many :recipe_items
  has_many :items, through: :recipe_items
  has_many :food_log_entries

  scope :active, -> { where(deleted_at: nil) }

  normalizes :name, with: ->(name) { Sanitize::Text.for(name) }

  validates :name,
    presence: true,
    length: { maximum: NAME_MAX_LENGTH },
    uniqueness: {
      scope: :user_id, conditions: -> { active }
    }
end
