FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:nickname) { |n| "user#{n}" }
    password { "top-secret-password" }

    trait :admin do
      admin { true }
    end
  end
end
