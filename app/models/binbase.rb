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


  # ask joseph for copy of latest import data file
  # DEFAULT_DATA_FILE = '../binbase/bins_iso_9_5.csv'
  DEFAULT_DATA_FILE = 'db/bins.csv'
  DEFAULT_BIGBANKS_FILE = 'db/bigbanks.txt'

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
