FactoryBot.define do
  factory :partner, class: Spree::Partner do
    store { Spree::Store.default || create(:store, default: true) }
    sequence(:name) { |n| "Pickup Network #{n}" }
    sequence(:code) { |n| "PN#{n}" }
    status { 'active' }
    parcel_cost { 45 }
    referral_commission_rate { 5 }
    referral_gmv_share_rate { 1 }
    referral_months { 6 }
  end
end
