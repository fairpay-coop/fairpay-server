class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper  # needed to support format_amount in views - but doesnt' work!!!

  default from: ENV['MAILER_DEFAULT_FROM']
  layout 'mailer'
end
