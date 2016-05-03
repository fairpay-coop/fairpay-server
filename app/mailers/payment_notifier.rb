class PaymentNotifier < ApplicationMailer
  include ApplicationHelper

  # send a signup email to the user, pass in the user object that   contains the user's email address
  def receipt(transaction)
    @transaction = transaction
    @data = hashify( transaction.step2_data )
    handler = transaction.theme_handler
    @from = handler.email_from
    subject = handler.payor_receipt_subject
    # subject = "Payment Receipt - #{@transaction.payee.name}"
    mail( to: @transaction.payor.email, subject: subject,
          template_path: template_path('receipt', transaction.embed) )
  end

  def receipt_merchant(transaction)
    @transaction = transaction
    @data = hashify( transaction.step2_data )
    handler = transaction.theme_handler
    @from = handler.email_from
    subject = handler.payee_receipt_subject
    # subject = "Payment Received - #{@transaction.payor.name}"
    mail( to: @transaction.payee.email, subject: subject,
    template_path: template_path('receipt', transaction.embed) )
  end

  def dwolla_info(transaction)
    @transaction = transaction
    @data = hashify( transaction.step2_data )
    handler = transaction.theme_handler
    @from = handler.email_from
    subject = handler.dwolla_info_subject
    # subject = "More about Dwolla"
    mail( to: @transaction.payor.email, subject: subject,
          template_path: template_path('receipt', transaction.embed) )
  end

  def template_path(action, embed)
    full_path = view_path(action, embed, subpath: 'mailer')
    result = full_path.split_by_last('/')[0]
    puts "template path: #{result}"
    result
  end

  def themed_render(action, embed)
    render view_path(action, embed, subpath: 'mailer')
  end

end

