require "google_drive"

class GoogleImport

  attr_accessor :campaign
  attr_accessor :document_key

  def initialize(config: "config/google-config.json", document_key: nil, campaign: nil, profile: nil)
    @session = GoogleDrive.saved_session(config)
    @document_key = document_key || ENV["GOOGLE_IMPORT_DOCUMENT_KEY"]
    @campaign = campaign
    unless campaign
      campaign_ident = ENV["GOOGLE_IMPORT_CAMPAIGN_IDENTIFIER"]
      @campaign = Campaign.resolve(campaign_ident) if campaign_ident.present?
    end
    @profile = profile
    unless profile
      profile_id = ENV["GOOGLE_IMPORT_PROFILE_ID"]
      @profile = Profile.find(profile_id) if profile_id.present?
    end
    @worksheet = @session.spreadsheet_by_key(@document_key).worksheets[0]
  end

  def import_offers(header_row: 2, last_row: nil)
    first_row = header_row +1
    last_row = @worksheet.num_rows unless last_row.present?
    read_field_map(row: header_row)
    (first_row..last_row).each do |row|
      import_offer_row(row)
    end
  end

  def read_field_map(row: 2)
    @field_map = {}
    (1..@worksheet.num_cols).each do |col|
      name = @worksheet[row,col]
      puts "#{col} -> #{name}"
      @field_map[col] = name
    end
  end

  def import_offer_row(row)
    data = {campaign: @campaign, profile: @profile}
    @field_map.each do |col, field_name|
      value = @worksheet[row, col]
      data[field_name] = value
      puts "#{field_name} -> #{value}"
    end
    Offer.create!(data)
  end

end