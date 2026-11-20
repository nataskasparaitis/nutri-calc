FactoryBot.define do
  factory :food_log_entry do
    user
    item
    grams { 500 }
    eaten_on { Date.current }

    trait :for_recipe do
      item { nil }
      recipe { association :recipe, user: user }
    end
  end
end
