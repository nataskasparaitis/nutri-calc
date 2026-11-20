FactoryBot.define do
  factory :recipe do
    user
    sequence(:name) { |n| "recipe#{n}" }

    trait :deleted do
      deleted_at { Time.current }
    end
  end
end
