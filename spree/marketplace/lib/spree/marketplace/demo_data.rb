module Spree
  module Marketplace
    # Fictional South African SMMEs used to demo the marketplace — one per province.
    # Any resemblance to real businesses is coincidental.
    module DemoData
      CATEGORIES = {
        'Fashion & Accessories' => %w[Dresses Headwear Bags],
        'Beauty & Wellness' => %w[Skincare Haircare Bodycare],
        'Home & Décor' => %w[Ceramics Candles Baskets],
        'Food & Pantry' => %w[Snacks Sauces Beverages],
        'Tech & Load-shedding' => %w[Power Lighting Accessories],
        'Kids & Baby' => %w[Clothing Toys Nursery],
        'Leather Goods' => %w[Wallets Footwear Sleeves]
      }.freeze

      SELLERS = [
        {
          name: 'Ubuntu Threads', province: 'GP', city: 'Johannesburg', township: 'Soweto', brand_color: '#E4572E',
          tagline: 'Shweshwe, reimagined for the city.', primary_category: 'Fashion & Accessories',
          description: 'Contemporary womenswear cut from authentic shweshwe and hand-finished by a team of six seamstresses in Orlando West.',
          story_headline: 'From a single sewing machine in Orlando West',
          story: 'Lerato started Ubuntu Threads in 2019 sewing for neighbours on her gogo’s Singer. Today the studio employs six women from the community and ships to every province.',
          business_type: 'pty_ltd', size_band: 'micro', bbbee_level: 1, black_owned: true, women_owned: true, youth_owned: true, township_business: true,
          founded_year: 2019, team_size: 6, featured: true, verified: true, instagram: 'ubuntuthreads.za',
          products: [
            { name: 'Shweshwe Wrap Dress', price: 899, compare: 1099, taxon: 'Dresses', stock: 25, description: 'Indigo shweshwe wrap dress with a flattering tie waist and deep pockets. 100% cotton, made in Soweto.' },
            { name: 'Shweshwe Bucket Hat', price: 349, taxon: 'Headwear', stock: 60, description: 'Reversible bucket hat — shweshwe on one side, plain denim on the other.' },
            { name: 'Printed Kimono Jacket', price: 749, taxon: 'Dresses', stock: 18, description: 'Lightweight kimono with a bold geometric print, perfect over a summer dress.' }
          ]
        },
        {
          name: 'Kasi Glow Naturals', province: 'KZN', city: 'Durban', township: 'Umlazi', brand_color: '#C9A227',
          tagline: 'Indigenous botanicals for melanin-rich skin.', primary_category: 'Beauty & Wellness',
          description: 'Small-batch skincare made with marula, baobab and rooibos sourced from rural women-led co-ops.',
          story_headline: 'Kitchen-table chemistry that went viral',
          story: 'Nomvula’s marula serum started as a home remedy. After a TikTok video hit a million views, she moved production to a certified facility in Durban.',
          business_type: 'pty_ltd', size_band: 'very_small', bbbee_level: 1, black_owned: true, women_owned: true, township_business: true,
          founded_year: 2020, team_size: 9, featured: true, verified: true, tiktok: 'kasiglow',
          products: [
            { name: 'Marula Oil Face Serum', price: 289, taxon: 'Skincare', stock: 120, description: 'Cold-pressed marula oil with vitamin E. Lightweight, fast-absorbing, for all skin types. 30ml.' },
            { name: 'Rooibos & Honey Body Butter', price: 189, taxon: 'Bodycare', stock: 90, description: 'Whipped shea body butter infused with rooibos extract and raw honey. 200ml.' },
            { name: 'Baobab Hair Growth Oil', price: 219, compare: 259, taxon: 'Haircare', stock: 75, description: 'A blend of baobab, castor and rosemary oils for strong, healthy edges. 100ml.' }
          ]
        },
        {
          name: 'Karoo Pantry Co.', province: 'EC', city: 'Graaff-Reinet', brand_color: '#8C5E3C',
          tagline: 'Slow food from the big sky country.', primary_category: 'Food & Pantry',
          description: 'Family recipes from the Karoo — air-dried biltong, relishes and rooibos blends.',
          story_headline: 'Three generations of Karoo recipes',
          story: 'Run by the Mthembu-van Wyk family, Karoo Pantry buys directly from small-scale Karoo farmers and pays above market rates.',
          business_type: 'cooperative', size_band: 'micro', bbbee_level: 2, black_owned: true,
          founded_year: 2016, team_size: 4, verified: true,
          products: [
            { name: 'Karoo Beef Biltong 250g', price: 159, taxon: 'Snacks', stock: 200, description: 'Traditional air-dried beef biltong spiced with coriander and black pepper.' },
            { name: 'Gogo’s Chakalaka Relish', price: 65, taxon: 'Sauces', stock: 150, description: 'Medium-hot chakalaka with carrots, peppers and beans. 400g jar.' },
            { name: 'Rooibos Chai Loose Leaf', price: 89, taxon: 'Beverages', stock: 140, description: 'Organic Cederberg rooibos with cinnamon, cardamom and ginger. 100g.' }
          ]
        },
        {
          name: 'Mzansi Clay Studio', province: 'WC', city: 'Cape Town', township: 'Khayelitsha', brand_color: '#2A9D8F',
          tagline: 'Hand-thrown ceramics with a township soul.', primary_category: 'Home & Décor',
          description: 'Functional stoneware made on the wheel in Khayelitsha. Every piece is one-of-a-kind.',
          story_headline: 'A pottery studio that trains young makers',
          story: 'Mzansi Clay runs a free 12-week ceramics programme for unemployed youth — half of the current team are graduates.',
          business_type: 'pty_ltd', size_band: 'micro', bbbee_level: 1, black_owned: true, youth_owned: true, township_business: true,
          founded_year: 2021, team_size: 7, featured: true, verified: true, instagram: 'mzansiclay',
          products: [
            { name: 'Speckled Stoneware Mug', price: 229, taxon: 'Ceramics', stock: 40, description: 'Hand-thrown 350ml mug with a speckled oat glaze. Dishwasher safe.' },
            { name: 'Ndebele Pattern Serving Bowl', price: 549, taxon: 'Ceramics', stock: 15, description: 'Large serving bowl hand-painted with Ndebele-inspired geometry.' },
            { name: 'Terracotta Succulent Planter', price: 349, taxon: 'Ceramics', stock: 30, description: 'Unglazed terracotta planter with drainage hole and saucer.' }
          ]
        },
        {
          name: 'Vhembe Weavers Collective', province: 'LP', city: 'Thohoyandou', brand_color: '#6A994E',
          tagline: 'Ilala palm baskets woven by 40 rural women.', primary_category: 'Home & Décor',
          description: 'A co-operative of rural weavers keeping Venda and Tsonga basketry traditions alive.',
          story_headline: '40 weavers, one co-operative',
          story: 'Every basket is signed by its weaver, and 70% of every sale goes directly to the woman who made it.',
          business_type: 'cooperative', size_band: 'micro', black_owned: true, women_owned: true,
          founded_year: 2012, team_size: 40, verified: true,
          products: [
            { name: 'Ilala Palm Market Basket', price: 459, taxon: 'Baskets', stock: 22, description: 'Sturdy hand-woven ilala palm basket with leather handles.' },
            { name: 'Woven Placemat Set of 4', price: 329, taxon: 'Baskets', stock: 35, description: 'Round woven placemats in natural and indigo dyed palm.' },
            { name: 'Wall Basket Trio', price: 899, compare: 1050, taxon: 'Baskets', stock: 10, description: 'Set of three decorative wall baskets in graduated sizes.' }
          ]
        },
        {
          name: 'Jozi Circuit Labs', province: 'GP', city: 'Johannesburg', township: 'Braamfontein', brand_color: '#3A86FF',
          tagline: 'Beat load-shedding with locally designed power gear.', primary_category: 'Tech & Load-shedding',
          description: 'Engineers from Wits building affordable backup power and lighting for South African homes.',
          story_headline: 'Built for Stage 6',
          story: 'Founded by three engineering grads during the 2022 energy crisis, Jozi Circuit Labs designs and assembles products in Johannesburg.',
          business_type: 'pty_ltd', size_band: 'small', bbbee_level: 2, black_owned: true, youth_owned: true,
          founded_year: 2022, team_size: 14, featured: true, verified: true,
          products: [
            { name: 'Solar Power Bank 20 000mAh', price: 649, compare: 799, taxon: 'Power', stock: 80, description: 'Rugged solar power bank with 2x USB-A, USB-C PD and a built-in torch.' },
            { name: 'Rechargeable LED Lantern', price: 399, taxon: 'Lighting', stock: 110, description: '12-hour rechargeable lantern with dimmer — keeps the lights on during load-shedding.' },
            { name: 'Wi-Fi Router UPS', price: 749, taxon: 'Power', stock: 45, description: 'Mini DC UPS that keeps your fibre router online for up to 6 hours.' }
          ]
        },
        {
          name: 'Little Baobab Kids', province: 'MP', city: 'Mbombela', brand_color: '#F4A261',
          tagline: 'Organic, African-inspired essentials for little ones.', primary_category: 'Kids & Baby',
          description: 'Babywear and toys made from organic cotton and sustainably sourced wood.',
          story_headline: 'A mom-made brand from the Lowveld',
          story: 'Thandi couldn’t find baby clothes that reflected her heritage, so she made them. Little Baobab now supplies boutiques across Mpumalanga.',
          business_type: 'sole_proprietor', size_band: 'micro', bbbee_level: 1, black_owned: true, women_owned: true,
          founded_year: 2021, team_size: 3, verified: false,
          products: [
            { name: 'Organic Cotton Onesie', price: 199, taxon: 'Clothing', stock: 70, description: 'Super-soft organic cotton onesie with a playful Big Five print.' },
            { name: 'Wooden Big Five Puzzle', price: 279, taxon: 'Toys', stock: 40, description: 'Chunky wooden puzzle featuring lion, leopard, rhino, elephant and buffalo.' },
            { name: 'Shweshwe Baby Blanket', price: 429, taxon: 'Nursery', stock: 25, description: 'Cotton-lined shweshwe blanket, 100 x 80cm.' }
          ]
        },
        {
          name: 'Highveld Leatherworks', province: 'FS', city: 'Bloemfontein', brand_color: '#7F4F24',
          tagline: 'Full-grain leather, built to outlast you.', primary_category: 'Leather Goods',
          description: 'Hand-stitched leather goods using hides tanned in South Africa.',
          story_headline: 'Saddle-stitched in the Free State',
          story: 'Former apprentice saddler Kagiso turned a backyard workshop into a brand that now trains five young artisans.',
          business_type: 'pty_ltd', size_band: 'micro', bbbee_level: 1, black_owned: true,
          founded_year: 2018, team_size: 6, verified: true,
          products: [
            { name: 'Full-grain Leather Wallet', price: 499, taxon: 'Wallets', stock: 50, description: 'Bifold wallet with six card slots, hand-stitched with waxed thread.' },
            { name: 'Classic Vellie Desert Boot', price: 1299, compare: 1499, taxon: 'Footwear', stock: 20, description: 'The iconic South African vellie in suede with a crepe sole.' },
            { name: 'Leather Laptop Sleeve 14"', price: 899, taxon: 'Sleeves', stock: 24, description: 'Padded laptop sleeve in tan leather with a magnetic closure.' }
          ]
        },
        {
          name: 'Bojanala Candle Co.', province: 'NW', city: 'Rustenburg', brand_color: '#9B5DE5',
          tagline: 'Soy candles that smell like home.', primary_category: 'Home & Décor',
          description: 'Hand-poured soy candles scented with fynbos, rooibos and wild buchu.',
          story_headline: 'Lighting up the North West',
          story: 'What began as a lockdown hobby is now a youth-owned business supplying lodges in the Pilanesberg.',
          business_type: 'sole_proprietor', size_band: 'micro', black_owned: true, youth_owned: true, women_owned: true,
          founded_year: 2020, team_size: 2, verified: false,
          products: [
            { name: 'Fynbos Soy Candle', price: 189, taxon: 'Candles', stock: 65, description: 'Hand-poured soy wax candle with a cotton wick. 40-hour burn time.' },
            { name: 'Wild Rooibos Reed Diffuser', price: 259, taxon: 'Candles', stock: 40, description: 'Long-lasting reed diffuser with a warm rooibos and vanilla scent.' }
          ]
        },
        {
          name: 'Kalahari Roasters', province: 'NC', city: 'Upington', brand_color: '#D62828',
          tagline: 'Desert-roasted African coffee.', primary_category: 'Food & Pantry',
          description: 'Specialty coffee from Ethiopia, Rwanda and Uganda, roasted to order on the edge of the Kalahari.',
          story_headline: 'Small-batch roasting in the Green Kalahari',
          story: 'Kalahari Roasters works directly with East African farmer co-ops and roasts every order within 48 hours.',
          business_type: 'pty_ltd', size_band: 'micro', bbbee_level: 3,
          founded_year: 2017, team_size: 5, verified: true,
          products: [
            { name: 'Rwanda Single Origin Beans 250g', price: 179, taxon: 'Beverages', stock: 90, description: 'Notes of red berries and caramel. Medium roast, whole bean.' },
            { name: 'Kalahari Espresso Blend 1kg', price: 489, compare: 549, taxon: 'Beverages', stock: 40, description: 'Chocolatey, full-bodied blend for espresso and moka pot.' }
          ]
        }
      ].freeze
    end
  end
end
