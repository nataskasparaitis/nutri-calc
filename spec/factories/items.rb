FactoryBot.define do
  factory :item do
    image_url { "https://example.com/images/apple.jpg" }
    sequence(:name) { |n| "item#{n}" }
    calories_per_100g { 123.45 }
    fat_per_100g { 0 }
    carbohydrate_per_100g { 12.3 }
    fiber_per_100g { 1.23 }
    protein_per_100g { 0 }
    salt_per_100g { 0.01 }

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
