class CreateSpreePartners < ActiveRecord::Migration[7.2]
  def change
    # jsonb on PostgreSQL: plain json has no equality operator, which breaks SELECT DISTINCT
    json_type = connection.adapter_name.downcase.include?('postg') ? :jsonb : :json

    create_table :spree_partners do |t|
      t.references :store, null: false, index: true
      t.string :name, null: false
      t.string :code, null: false          # short code, also the seller referral code (e.g. PAXI)
      t.string :status, null: false        # prospect, in_talks, pilot, active, paused
      t.string :website
      t.text :description

      # Roles in the partnership
      t.boolean :carrier
      t.boolean :investor
      t.boolean :referral

      # Carrier terms
      t.decimal :parcel_cost, precision: 10, scale: 2            # negotiated base cost per parcel (ZAR, incl. VAT)
      t.column :volume_tiers, json_type                                        # [{ "min_parcels": 1000, "parcel_cost": 42.0 }]

      # Seller referral programme (sellers onboarded through partner counters)
      t.decimal :referral_commission_rate, precision: 5, scale: 2 # reduced EcloudMall commission for referred sellers
      t.decimal :referral_gmv_share_rate, precision: 5, scale: 2  # % of referred sellers' paid GMV paid to partner
      t.integer :referral_months

      # Investment terms
      t.decimal :investment_amount, precision: 14, scale: 2
      t.decimal :equity_percent, precision: 5, scale: 2
      t.decimal :logistics_credit, precision: 14, scale: 2       # in-kind investment as prepaid parcels (ZAR)

      t.string :contact_name
      t.string :contact_email
      t.string :contact_phone
      t.text :notes
      t.datetime :signed_at

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :spree_partners, [:store_id, :code], unique: true
    add_index :spree_partners, :deleted_at

    add_reference :spree_shipping_methods, :partner, index: true
    add_column :spree_shipping_methods, :pickup_point_provider, :string

    add_column :spree_shipments, :pickup_point_data, json_type

    add_reference :spree_sellers, :referred_by_partner, index: true
    add_column :spree_sellers, :referral_expires_at, :datetime
  end
end
