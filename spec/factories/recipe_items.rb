FactoryBot.define do
  factory :recipe_item do
    recipe
    item
    grams { 400 }
  end
end
