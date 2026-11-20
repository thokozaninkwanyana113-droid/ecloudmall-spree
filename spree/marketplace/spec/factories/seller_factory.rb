FactoryBot.define do
  factory :seller, class: Spree::Seller do
    store { Spree::Store.default || create(:store, default: true) }
    sequence(:name) { |n| "Kasi Business #{n}" }
    sequence(:email) { |n| "seller#{n}@example.co.za" }
    province { 'GP' }
    city { 'Johannesburg' }

    trait :approved do
      status { 'approved' }
      approved_at { Time.current }
    end
  end
end
