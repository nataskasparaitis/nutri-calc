class Item < ApplicationRecord
  NAME_MAX_LENGTH = 191
  IMAGE_URL_MAX_LENGTH = 2048
  IMAGE_URL_FORMAT = /\A#{URI::DEFAULT_PARSER.make_regexp(%w[http https])}\z/
  MAX_CALORIES_PER_100G = 999.99
  GRAMS_PER_100G = %i[fat_per_100g carbohydrate_per_100g fiber_per_100g protein_per_100g salt_per_100g].freeze

  belongs_to :creator, class_name: "User", optional: true, inverse_of: :created_items

  has_many :recipe_items
  has_many :favorite_items
  has_many :food_log_entries

  scope :active, -> { where(deleted_at: nil) }

  normalizes :name, with: ->(name) { Sanitize::Text.for(name) }
  normalizes :image_url, with: ->(url) { url.strip.presence }

  validates :name,
    presence: true,
    length: { maximum: NAME_MAX_LENGTH },
    uniqueness: { conditions: -> { active } }

  validates :image_url,
    length: { maximum: IMAGE_URL_MAX_LENGTH },
    format: { with: IMAGE_URL_FORMAT, message: "must be an http or https URL" },
    allow_nil: true

  validates :calories_per_100g, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_CALORIES_PER_100G }
  validates(*GRAMS_PER_100G, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 })
end
