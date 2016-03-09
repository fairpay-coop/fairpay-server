namespace :fairpay do

  desc "import the latest binbase data from source csv file (ask joseph for data file)"
  task :import_binbase => :environment do
    #todo: support command line params - for now assumes default locations
    Binbase.purge_imported
    Binbase.import_data
  end



end
