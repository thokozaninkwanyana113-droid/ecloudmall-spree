# This migration comes from spree_marketplace (originally 20261118100000)
class CreateSpreeSellers < ActiveRecord::Migration[7.2]
  def change
    create_table :spree_sellers do |t|
      t.references :store, null: false, index: true
      t.string :name, null: false
      t.string :slug, null: false
      t.string :status, null: false
      t.string :tagline
      t.text :description
      t.string :story_headline
      t.text :story

      # Contact
      t.string :contact_name
      t.string :email, null: false
      t.string :phone
      t.string :whatsapp
      t.string :website
      t.string :instagram
      t.string :facebook
      t.string :tiktok

      # Location
      t.string :province
      t.string :city
      t.string :township

      # Business profile
      t.string :business_type
      t.string :size_band
      t.string :registration_number # CIPC
      t.string :vat_number
      t.integer :bbbee_level
      t.boolean :black_owned
      t.boolean :women_owned
      t.boolean :youth_owned
      t.boolean :disability_owned
      t.boolean :township_business
      t.string :primary_category
      t.integer :founded_year
      t.integer :team_size
      t.string :brand_color

      # Fulfilment
      t.boolean :ships_nationwide
      t.boolean :offers_collection
      t.integer :dispatch_days

      # Marketplace
      t.decimal :commission_rate, precision: 5, scale: 2
      t.boolean :featured
      t.boolean :verified
      t.datetime :approved_at
      t.datetime :rejected_at
      t.text :rejection_reason
      t.text :admin_notes

      t.jsonb :public_metadata if t.respond_to?(:jsonb)
      t.jsonb :private_metadata if t.respond_to?(:jsonb)

      t.datetime :deleted_at
      t.timestamps
    end

    add_index :spree_sellers, [:store_id, :slug], unique: true
    add_index :spree_sellers, :status
    add_index :spree_sellers, :province
    add_index :spree_sellers, :deleted_at
    add_index :spree_sellers, :email

    add_reference :spree_products, :seller, index: true
    add_reference :spree_line_items, :seller, index: true
  end
end
