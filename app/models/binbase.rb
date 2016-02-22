class Binbase < ActiveRecord::Base

  # create_table :binbases do |t|
  #   t.string :bin, index: true
  #   t.string :card_brand
  #   t.string :card_type
  #   t.string :card_category
  #   t.string :country_iso
  #   t.string :org_website
  #   t.string :org_phone
  #   t.references :binbase_org
  #   t.timestamps null: false

  belongs_to :binbase_org


  def is_regulated
    binbase_org.present? && binbase_org.is_regulated
  end

  def issuing_org
    binbase_org&.name
  end

  # def self.estimate_fee(data)
  #   binbase =
  # end

  def self.fee_range(amount)
    low = apply_fee_rate(amount, 0.22, 0.05)
    high = apply_fee_rate(amount, 0.30, 3.5)
    [low, high]
  end


  # right now, this is just the interchange fee calculation
  ## todo: add in merchant processor (i.e. dharma merchant services) fee
  def self.estimate_fee(bin, amount)
    binbase = Binbase.find_by(bin: bin)
    puts "binbase: #{binbase}"
    base = 0.30
    percent = 2.9
    message = nil

    amount = BigDecimal(amount)

    # return {error: 'BIN not found'} unless binbase
    unless binbase
      # placeholder default fee calculation
      fee = apply_fee_rate(amount, 0.22, 2.5)
      return {estimated_fee: fee}
    end

    if binbase.card_brand == 'AMEX'
      base = 0.30
      percent = 3.5
      message = "Tip: AMEX has the highest fees!"
    end

    if binbase.card_brand == 'VISA' || binbase.card_brand == 'MASTERCARD'
      if binbase.card_type == 'DEBIT'
        base = 0.22
        if binbase.is_regulated
          percent = 0.05
          message = "Good choice, Debit Cards have the lowest fees!"
        else
          percent = 0.80
          message = "Good choice, Debit Cards have lower fees."
        end
      else
        base = 0.12
        message = "Tip: Debit Cards generally have lower fees than Credit Cards"
        if binbase.card_category == 'PLATINUM' || binbase.card_category == 'BUSINESS'
          percent = 2.9
          message += ", and Rewards Cards have the highest fees."
        elsif binbase.card_category == 'GOLD'
          percent = 2.2
          message += ", and Rewards Cards have higher fees."
        else
          percent = 1.8
        end
      end
    end
    if amount < 20
      message = ""
    end

    fee = apply_fee_rate(amount, base, percent)
    puts "calcfee - #{bin}, base: #{base}, %: #{percent} = #{fee} - tip: #{message}"
    {estimated_fee: fee, fee_tip: message, card_brand: binbase.card_brand, issuing_org: binbase.issuing_org,
     card_type: binbase.card_type, card_category: binbase.card_category, is_regulated: binbase.is_regulated}
  end

  def self.apply_fee_rate(amount, base, percent)
    fee = base + amount * percent/100
    fee = (fee * 100).ceil / 100.0
  end

  DEFAULT_DATA_FILE = '../binbase/bins_iso_8_9.csv'
  DEFAULT_BIGBANKS_FILE = '../binbase/bigbanks.txt'

  def self.purge_imported
    Binbase.destroy_all
    BinbaseOrg.destroy_all
  end

  def self.import_data(data_file: DEFAULT_DATA_FILE, bigbanks_file: DEFAULT_BIGBANKS_FILE)

    big_banks = CSV.readlines(bigbanks_file, col_sep: '|').flatten

    CSV.foreach(data_file, col_sep: ';') do |row|
      data = row_to_hash(row)
      org_name = data.delete(:issuing_org)
      org = BinbaseOrg.find_by(name: org_name)
      if org_name && ! org
        is_regulated = big_banks.include?(org_name)
        org_data = {name: org_name, country_iso: data[:country_iso], website: data[:org_website], phone: data[:org_phone], is_regulated: is_regulated}
        puts "new org data: #{org_data}"
        org = BinbaseOrg.create!(org_data)
      end
      data[:binbase_org_id] = org.id  if org
      Binbase.create!(data)
    end

  end

  def self.row_to_hash(r)
    {bin: r[0], card_brand: r[1], issuing_org: r[2], card_type: r[3], card_category: r[4], country_iso: r[6], org_website: r[9], org_phone: r[10]}
  end

end
