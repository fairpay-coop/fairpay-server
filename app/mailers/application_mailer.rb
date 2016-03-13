class ApplicationMailer < ActionMailer::Base
  include ApplicationHelper  # needed to support format_amount in views - but doesnt' work!!!

  default from: "system@fairpay.coop"
  layout 'mailer'
end
