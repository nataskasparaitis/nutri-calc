class FoodLogEntry < ApplicationRecord
  belongs_to :user
  belongs_to :item, optional: true
  belongs_to :recipe, optional: true
end
