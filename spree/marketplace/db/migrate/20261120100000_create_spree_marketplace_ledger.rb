class CreateSpreeMarketplaceLedger < ActiveRecord::Migration[7.2]
  def change
    json_type = connection.adapter_name.downcase.include?('postg') ? :jsonb : :json

    create_table :spree_ledger_entries do |t|
      t.references :store, null: false, index: true
      t.references :payee, polymorphic: true, null: false, index: true
      t.string :kind, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.datetime :available_at, null: false
      t.references :order, index: true
      t.references :source, polymorphic: true, index: true
      t.string :description
      t.string :idempotency_key, null: false
      t.column :metadata, json_type
      t.timestamps
    end
    add_index :spree_ledger_entries, :idempotency_key, unique: true
    add_index :spree_ledger_entries, [:payee_type, :payee_id, :available_at], name: 'index_spree_ledger_entries_on_payee_and_available_at'

    create_table :spree_bank_accounts do |t|
      t.references :owner, polymorphic: true, null: false, index: { unique: true }
      t.string :account_holder, null: false
      t.string :bank_name, null: false
      t.string :branch_code, null: false
      t.string :account_number, null: false
      t.string :account_number_last4, null: false
      t.string :account_type, null: false
      t.datetime :verified_at
      t.timestamps
    end

    create_table :spree_payout_batches do |t|
      t.references :store, null: false, index: true
      t.string :number, null: false
      t.string :status, null: false
      t.string :currency, null: false
      t.datetime :period_end, null: false
      t.decimal :total, precision: 14, scale: 2
      t.integer :payouts_count
      t.datetime :approved_at
      t.datetime :exported_at
      t.datetime :paid_at
      t.text :notes
      t.timestamps
    end
    add_index :spree_payout_batches, :number, unique: true

    create_table :spree_payouts do |t|
      t.references :payout_batch, null: false, index: true
      t.references :payee, polymorphic: true, null: false, index: true
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.string :currency, null: false
      t.string :status, null: false
      t.string :reference, null: false
      t.string :bank_account_holder
      t.string :bank_name
      t.string :bank_branch_code
      t.string :bank_account_number
      t.string :bank_account_last4
      t.string :bank_account_type
      t.datetime :paid_at
      t.string :failure_reason
      t.timestamps
    end
    add_index :spree_payouts, :reference, unique: true
  end
end
