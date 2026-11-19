require 'spree_core'
require 'spree_api'
require 'spree_admin'
require 'spree/marketplace/engine'

module Spree
  module Marketplace
    # The nine provinces of South Africa (ISO 3166-2:ZA codes)
    PROVINCES = {
      'EC' => 'Eastern Cape',
      'FS' => 'Free State',
      'GP' => 'Gauteng',
      'KZN' => 'KwaZulu-Natal',
      'LP' => 'Limpopo',
      'MP' => 'Mpumalanga',
      'NC' => 'Northern Cape',
      'NW' => 'North West',
      'WC' => 'Western Cape'
    }.freeze

    BUSINESS_TYPES = {
      'sole_proprietor' => 'Sole Proprietor',
      'pty_ltd' => 'Private Company (Pty) Ltd',
      'cooperative' => 'Co-operative',
      'partnership' => 'Partnership',
      'npc' => 'Non-Profit Company (NPC)',
      'informal' => 'Informal / not yet registered'
    }.freeze

    # Turnover-based SMME size bands (simplified from the National Small Enterprise Act schedule)
    SIZE_BANDS = {
      'micro' => 'Micro (under R1m turnover)',
      'very_small' => 'Very small',
      'small' => 'Small',
      'medium' => 'Medium'
    }.freeze

    DEFAULT_COMMISSION_RATE = 7.5
  end
end
